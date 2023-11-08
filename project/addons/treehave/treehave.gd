@tool
extends PanelContainer

enum Actions {ADD_NODE, ADD_DECORATOR, REMOVE_DECORATOR}

signal selection_updated(new_selection)

const X_SPACING := 240.0
const Y_SPACING := 160.0
const BEEHAVE_NODES_TO_EXCLUDE := [
	"res://addons/beehave/nodes/leaves/action.gd",
	"res://addons/beehave/nodes/leaves/condition.gd",
	"res://addons/beehave/nodes/leaves/leaf.gd",
	"res://addons/beehave/nodes/decorators/decorator.gd",
	"res://addons/beehave/nodes/composites/composite.gd",
	"res://addons/beehave/nodes/beehave_node.gd",
]

var editor_interface: EditorInterface
var selected_tree_node: Node
var _current_behavior_tree: BeehaveTree
var _node_graph_node_map: Dictionary = {}
var _is_treehave_panel_hovered := false
var _previous_action_array: Array[Dictionary] = []
var _popup_manager := TreehavePopupManager.new()
var _open_menu_button: MouseButton = MOUSE_BUTTON_RIGHT

@onready var _graph_edit: GraphEdit = %GraphEdit


func _input(event: InputEvent) -> void:
	if not _is_treehave_panel_hovered:
		return

	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == _open_menu_button:
			_popup_graph_node_menu()


func _popup_graph_node_menu() -> void:
	if selected_tree_node == null:
		return

	var menu := _popup_manager.create_popup_menu(get_global_mouse_position())
	
	for action in _get_possible_actions(selected_tree_node):
		_popup_manager.add_item_to_menu(_get_action_string(action), action)

	menu.index_pressed.connect(_on_graph_node_menu_index_pressed.bind(menu))
	add_child(menu)


func _get_action_string(action: Actions) -> String:
	return Actions.keys()[action].capitalize()


func _get_possible_actions(node: Node) -> Array[Actions]:
	var actions: Array[Actions] = []

	actions.append(Actions.ADD_DECORATOR)

	if not node is Leaf:
		actions.append(Actions.ADD_NODE)

	if get_graph_node(node).is_decorated:
		actions.append(Actions.REMOVE_DECORATOR)

	actions.sort()
	return actions


func _popup_add_node_menu(action: Actions) -> void:
	var menu := _popup_manager.create_popup_menu(get_global_mouse_position())
	
	for file_path in _get_gd_files_in_directory(editor_interface.get_resource_filesystem().get_filesystem()):
		editor_interface.get_resource_filesystem()
		var instance = load(file_path).new()
		if instance is BeehaveNode and not BEEHAVE_NODES_TO_EXCLUDE.has(file_path):
			if (action == Actions.ADD_NODE and not instance is Decorator) or (action == Actions.ADD_DECORATOR and instance is Decorator):
				_popup_manager.add_item_to_menu(_get_name_from_path(file_path), file_path)

	menu.index_pressed.connect(_on_add_node_menu_index_pressed.bind(menu))
	add_child(menu)


func _get_gd_files_in_directory(directory:EditorFileSystemDirectory) -> Array[String]:
	var paths: Array[String] = []

	for file_index in directory.get_file_count():
		if directory.get_file_type(file_index) == "GDScript":
			paths.append(directory.get_file_path(file_index))

	for dir_index in directory.get_subdir_count():
		paths.append_array(_get_gd_files_in_directory(directory.get_subdir(dir_index)))

	return paths


func _on_graph_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	match menu.get_item_metadata(index):
		Actions.ADD_NODE:
			_popup_add_node_menu(Actions.ADD_NODE)
		Actions.ADD_DECORATOR:
			_popup_add_node_menu(Actions.ADD_DECORATOR)
		Actions.REMOVE_DECORATOR:
			_remove_decorator()
	menu.queue_free()


func _remove_decorator(node: Node = selected_tree_node) -> void:
	while not node is Decorator:
		node = node.get_parent()
		if node is BeehaveTree:
			return

	var decorator: Decorator = node
	var root := decorator.get_parent()
	var branch := decorator.get_child(0)
	var current_index := decorator.get_index()
	branch.reparent(root)
	root.move_child(branch, current_index)
	_set_node_owner(branch)
	decorator.queue_free()

	get_graph_node(branch).remove_decorator(decorator)


func _on_add_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	var node_path: String = menu.get_item_metadata(index)

	var new_tree_node: BeehaveNode = load(node_path).new()
	new_tree_node.name = _get_name_from_path(node_path)

	if new_tree_node is Decorator:
		var current_index := selected_tree_node.get_index()
		var parent_node := selected_tree_node.get_parent()
		parent_node.add_child(new_tree_node)
		parent_node.move_child(new_tree_node, current_index)
		selected_tree_node.reparent(new_tree_node)
		_set_node_owner(parent_node)
	else:
		selected_tree_node.add_child(new_tree_node)
	new_tree_node.owner = _current_behavior_tree

	_build_graph_node(new_tree_node)

	set_tree(_current_behavior_tree)

	menu.queue_free()


func _set_node_owner(node: Node) -> void:
	node.owner = _current_behavior_tree
	for child in node.get_children():
		_set_node_owner(child)


func _get_name_from_path(path: String) -> String:
	return path.get_basename().get_file().capitalize()


func set_tree(tree: BeehaveTree) -> void:
	_current_behavior_tree = tree
	_clear_current_graph()
	_build_current_tree_graph()
	_arrange_current_tree_graph()


func set_selected(node: Node) -> void:
	if node == null:
		return

	get_graph_node(node).selected = true


func _clear_current_graph() -> void:
	_node_graph_node_map.clear()
	_graph_edit.clear_connections()
	# Delete all children of the GraphEdit.
	for node in _graph_edit.get_children():
		node.queue_free()


func get_graph_node(node: Node) -> GraphNode:
	if node is Decorator and node.get_child_count() > 0:
		node = node.get_child(0)

	return _node_graph_node_map.get(node)


func get_tree_node(graph_node: GraphNode) -> Node:
	return _node_graph_node_map.find_key(graph_node)


func _build_current_tree_graph() -> void:
	# Translates the beehave tree represented by _current_behavior_tree into a graph.
	_create_graph_node(_current_behavior_tree)
	_build_graph_node(_current_behavior_tree.get_child(0))


func _build_graph_node(node: Node) -> void:
	if node == null:
		return

	var decorators: Array[Decorator] = []
	var parent_node := node.get_parent()

	while parent_node is Decorator:
		parent_node = parent_node.get_parent()

	while node is Decorator:
		decorators.append(node)
		if node.get_child_count() == 0:
			return

		node = node.get_child(0)

	var graph_node := _create_graph_node(node, decorators)
	var parent_graph_node := get_graph_node(parent_node)

	_graph_edit.connect_node(parent_graph_node.name, 0, graph_node.name, 0)

	for child in node.get_children():
		_build_graph_node(child)


func _create_graph_node(from: Node, decorators: Array[Decorator] = []) -> GraphNode:
	# Create a new graph node with the same name and title as "from,"
	# store a reference to the node it's being created from, and return it
	var graph_node := TreehaveGraphNode.new()
	# is passing a function around like this really dumb or just kinda dumb?
	graph_node.create(from, decorators, _get_node_script_icon)
	
	_graph_edit.add_child(graph_node)
	_node_graph_node_map[from] = graph_node

	graph_node.close_request.connect(_on_graph_node_delete_request.bind(graph_node))
	graph_node.dragged.connect(_on_graph_node_dragged.bind(graph_node))
	graph_node.remove_decorator_requested.connect(_remove_decorator)

	return graph_node


func _delete_graph_node(graph_node: GraphNode) -> Array:
	var nodes_removed := []
	var node = get_tree_node(graph_node)

	if node is BeehaveTree:
		return []

	for child in node.get_children():
		# Append nodes removed from children
		nodes_removed.append_array(_delete_graph_node(get_graph_node(child)))

	_node_graph_node_map.erase(node)
	_node_graph_node_map.erase(graph_node)

	_remove_all_connections(graph_node)

	var node_parent := node.get_parent()

	# Do not queue free the node. Nodes need to be saved for undo actions.
	node_parent.remove_child(node)
	graph_node.queue_free()

	# Include parent node and node in dictionary so we can reconstruct the tree
	# if action needs to be undone
	nodes_removed.append({"parent_node": node_parent, "node": node})

	return nodes_removed


func _remove_all_connections(graph_node: GraphNode) -> void:
	var connections := _graph_edit.get_connection_list()
	for connection in connections:
		if connection.from == graph_node.name or connection.to == graph_node.name:
			_graph_edit.disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)


func _arrange_current_tree_graph() -> void:
	# Arranges the graph nodes in the GraphEdit.
	var node := _current_behavior_tree.get_child(0)
	_arrange_graph_node(node)


func _arrange_graph_node(node: Node) -> void:
	if node == null:
		return

	var queue := []
	queue.append(node)

	while queue.size() > 0:
		var current_node := queue.pop_front()

		while current_node is Decorator:
			if current_node.get_child_count() == 0:
				return

			current_node = current_node.get_child(0)

		_set_graph_node_position(current_node)

		for child in current_node.get_children():
			queue.append(child)


func _set_graph_node_position(node: Node) -> void:
	var parent_node := node.get_parent()
	var child := node

	while parent_node is Decorator:
		child = parent_node
		parent_node = parent_node.get_parent()

	var graph_node := get_graph_node(node)
	var parent_graph_node := get_graph_node(parent_node)
	var sibling_index := child.get_index()

	var sibling_count := parent_node.get_child_count()
	var width := _get_node_width(node)
	var pre_width := 0
	var post_width := 0
	var parent_width := 0

	for i in range(0, sibling_index):
		pre_width += _get_node_width(parent_node.get_child(i))

	for i in range(sibling_index + 1, sibling_count):
		post_width += _get_node_width(parent_node.get_child(i))

	parent_width = pre_width + width + post_width

	var x_offset := 0.0
	var y_offset := Y_SPACING

	var left_most_x_offset := -parent_width * X_SPACING / 2.0

	x_offset = left_most_x_offset + (width * X_SPACING) / 2.0 + (pre_width * X_SPACING)

	var final_x_offset := parent_graph_node.get_position_offset().x + x_offset
	var final_y_offset := parent_graph_node.get_position_offset().y + y_offset
	graph_node.set_position_offset(Vector2(final_x_offset, final_y_offset))


func _get_node_width(node: Node) -> int:
	if node == null or node.get_child_count() == 0:
		return 1

	var width := 0

	for child in node.get_children():
		width += _get_node_width(child)

	return width


func _get_node_script_icon(node: Node) -> ImageTexture:
	var script := node.get_script()
	var script_map := ProjectSettings.get_global_class_list()
	var icon_path: String = ""

	while icon_path == "" and script != null:
		for i in range(0, script_map.size()):
			if script_map[i].path == script.get_path():
				icon_path = script_map[i].icon
				break

		script = script.get_base_script()

	if icon_path == "":
		return null

	return load(icon_path)


func _reorder_nodes(parent: Node) -> void:
	var child_order := parent.get_children()
	child_order.sort_custom(
		func (a: Node, b: Node):
			return get_graph_node(a).position_offset.x < get_graph_node(b).position_offset.x
	)

	_reorder_node_siblings(child_order)


func _reorder_node_siblings(node_array: Array[Node]) -> void:
	for node in node_array:
		var parent := node.get_parent()
		parent.remove_child(node)
		parent.add_child(node)

		_set_node_owner(node)


func _store_last_graph_action(action_name: String, reversal_values: Array) -> void:
	var action_dictionary := {
		"action": action_name,
		"reversal_values": reversal_values,
	}

	_previous_action_array.push_back(action_dictionary)


func _undo_last_graph_action() -> void:
	if _previous_action_array.is_empty():
		return

	var action_dictionary: Dictionary = _previous_action_array.pop_back()
	match action_dictionary["action"]:
		"delete_nodes":
			_reconstruct_tree(action_dictionary["reversal_values"])

		"reorder_nodes":
			_restore_node_order(action_dictionary["reversal_values"])

	_clear_current_graph()
	_build_current_tree_graph()
	_arrange_current_tree_graph()


func _reconstruct_tree(nodes_removed: Array) -> void:
	var nodes := []

	for dictionary in nodes_removed:
		var parent: Node = dictionary["parent_node"]
		var node = dictionary["node"]
		parent.add_child(node)
		nodes.append(node)

	# Second loop is necessary because setting node.owner must be done after all
	# nodes have their parents assigned or some nodes will show up in the graph
	# edit but will not show up properly in the scenetree.
	for node in nodes:
		node.owner = _current_behavior_tree


# Works, but graph doesn't immediately update????
func _restore_node_order(reorder_data: Array) -> void:
	var parent: Node = reorder_data[0]
	var old_child_order: Array[Node] = reorder_data[1]

	# Remove all children and add them in their old order
	for node in old_child_order:
		parent.remove_child(node)
		parent.add_child(node)
		_set_node_owner(node)


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	var nodes_removed := []

	for node_name in nodes:
		nodes_removed.append_array(_delete_graph_node(_graph_edit.get_node(str(node_name))))

	_store_last_graph_action("delete_nodes", nodes_removed)


func _on_graph_node_delete_request(graph_node: GraphNode) -> void:
	var nodes_removed := _delete_graph_node(graph_node)

	_store_last_graph_action("delete_nodes", nodes_removed)


func _on_graph_node_dragged(_from: Vector2, _to: Vector2, graph_node: GraphNode) -> void:
	var parent := get_tree_node(graph_node).get_parent()
	var old_child_order := parent.get_children()

	_reorder_nodes(parent)

	_store_last_graph_action("reorder_nodes", [parent, old_child_order])
	_reorder_nodes(get_tree_node(graph_node).get_parent())
	selection_updated.emit(graph_node)


func _on_graph_edit_mouse_entered() -> void:
	_is_treehave_panel_hovered = true


func _on_graph_edit_mouse_exited() -> void:
	_is_treehave_panel_hovered = false


func _on_undo_button_pressed():
	_undo_last_graph_action()


func _on_graph_edit_node_selected(node: GraphNode) -> void:
	selection_updated.emit(node)
