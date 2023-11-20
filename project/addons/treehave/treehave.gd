@tool
extends PanelContainer

signal selection_updated(new_selection)

enum Actions {ADD_NODE, ADD_DECORATOR, REMOVE_DECORATOR}

const BEEHAVE_NODES_TO_EXCLUDE := [
	"res://addons/beehave/nodes/leaves/action.gd",
	"res://addons/beehave/nodes/leaves/condition.gd",
	"res://addons/beehave/nodes/leaves/leaf.gd",
	"res://addons/beehave/nodes/decorators/decorator.gd",
	"res://addons/beehave/nodes/composites/composite.gd",
	"res://addons/beehave/nodes/beehave_node.gd",
]

var editor_interface: EditorInterface
var selected_tree_node: TreehaveTreeNode
var _tree_root: TreehaveTreeNode
var _is_treehave_panel_hovered := false
var _previous_action_array: Array[Dictionary] = []
var _popup_manager := TreehavePopupManager.new()
var _open_menu_button: MouseButton = MOUSE_BUTTON_RIGHT

@onready var _tree_edit: TreehaveTreeEdit = %TreeEdit


func _input(event: InputEvent) -> void:
	if not _is_treehave_panel_hovered:
		return

	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == _open_menu_button:
			_popup_tree_node_menu()


func _popup_tree_node_menu() -> void:
	if selected_tree_node == null:
		return

	var menu := _popup_manager.create_popup_menu(get_global_mouse_position())

	for action in _get_possible_actions(selected_tree_node):
		_popup_manager.add_item_to_menu(_get_action_string(action), action)

	menu.index_pressed.connect(_on_tree_node_menu_index_pressed.bind(menu))
	add_child(menu)


func _get_action_string(action: Actions) -> String:
	return Actions.keys()[action].capitalize()


func _get_possible_actions(tree_node: TreehaveTreeNode) -> Array[Actions]:
	var actions: Array[Actions] = []

	actions.append(Actions.ADD_DECORATOR)

	if not tree_node.node is Leaf:
		actions.append(Actions.ADD_NODE)

	if tree_node.is_decorated:
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


func _on_tree_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	match menu.get_item_metadata(index):
		Actions.ADD_NODE:
			_popup_add_node_menu(Actions.ADD_NODE)
		Actions.ADD_DECORATOR:
			_popup_add_node_menu(Actions.ADD_DECORATOR)
		Actions.REMOVE_DECORATOR:
			selected_tree_node.remove_decorator()
	menu.queue_free()


func _on_add_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	var node_path: String = menu.get_item_metadata(index)

	var new_scene_node: BeehaveNode = load(node_path).new()
	new_scene_node.name = _get_name_from_path(node_path)

	if new_scene_node is Decorator:
		var current_index := selected_tree_node.node.get_index()
		var parent := selected_tree_node.parent
		parent.node.add_child(new_scene_node)
		parent.node.move_child(new_scene_node, current_index)
		selected_tree_node.node.reparent(new_scene_node)
		_set_node_owner(parent.node)
	else:
		selected_tree_node.node.add_child(new_scene_node)
	new_scene_node.owner = _tree_root.node

	_build_tree_node(new_scene_node, selected_tree_node)

	set_tree(_tree_root.node)

	menu.queue_free()


func _set_node_owner(node: Node) -> void:
	node.owner = _tree_root.node
	for child in node.get_children():
		_set_node_owner(child)


func _get_name_from_path(path: String) -> String:
	return path.get_basename().get_file().capitalize()


func set_tree(tree: BeehaveTree) -> void:
	if tree == null:
		return

	_tree_root = _create_tree_node(tree)
	_clear_current_graph()
	_tree_edit.set_root(_tree_root)
	_build_current_tree_graph()


func set_selected(node: Node) -> void:
	if node == null:
		return

	var tree_node := get_tree_node(node)

	if tree_node == null:
		return

	tree_node.selected = true
	selected_tree_node = tree_node


func _clear_current_graph() -> void:
	_tree_edit.clear_tree()
	_tree_edit.clear_connections()


func get_tree_node(node: Node) -> TreehaveTreeNode:
	return _tree_edit.get_tree_node(node)


func _build_current_tree_graph() -> void:
	# Translates the beehave tree represented by _current_behavior_tree into a graph.
	_build_tree_node(_tree_root.node.get_child(0))


func _build_tree_node(node: Node, parent_tree_node: TreehaveTreeNode = null) -> void:
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

	var tree_node := _create_tree_node(node, decorators)

	tree_node.parent = parent_tree_node

	if not parent_tree_node == null:
		_tree_edit.connect_node(parent_tree_node.name, 0, tree_node.name, 0)

	for child in node.get_children():
		_build_tree_node(child, tree_node)


func _create_tree_node(from: Node, decorators: Array[Decorator] = []) -> TreehaveTreeNode:
	# Create a new graph node with the same name and title as "from,"
	# store a reference to the node it's being created from, and return it
	var tree_node := TreehaveTreeNode.new(from, decorators)

	tree_node.dragged.connect(_on_tree_node_dragged.bind(tree_node))
	_tree_edit.add_node(tree_node)

	return tree_node


func _delete_node(node: Node) -> Array:
	if node is BeehaveTree:
		return []

	var tree_node := get_tree_node(node)
	var parent := tree_node.parent
	var removed_nodes := _tree_edit.remove_node(tree_node)

	# Do not queue free the node. Nodes need to be saved for undo actions.
	parent.node.remove_child(node)
	parent.remove_tree_node_child(tree_node)

	return removed_nodes


func _reorder_nodes(parent: TreehaveTreeNode) -> void:
	var child_order := parent.node.get_children()
	child_order.sort_custom(
		func (a: Node, b: Node):
			return get_tree_node(a).position_offset.x < get_tree_node(b).position_offset.x
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
	_tree_edit.arrange_tree()


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
		node.owner = _tree_root.node


# Works, but graph doesn't immediately update????
func _restore_node_order(reorder_data: Array) -> void:
	var parent: Node = reorder_data[0]
	var old_child_order: Array[Node] = reorder_data[1]

	# Remove all children and add them in their old order
	for node in old_child_order:
		parent.remove_child(node)
		parent.add_child(node)
		_set_node_owner(node)


func _on_tree_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	var nodes_removed := []

	for node_name in nodes:
		nodes_removed.append_array(_delete_node(_tree_edit.get_tree_node_by_name(node_name)))

	_store_last_graph_action("delete_nodes", nodes_removed)


func _on_tree_node_dragged(_from: Vector2, _to: Vector2, tree_node: TreehaveTreeNode) -> void:
	var parent := tree_node.parent
	var old_child_order := parent.children

	_reorder_nodes(parent)

	_store_last_graph_action("reorder_nodes", [parent, old_child_order])
	_reorder_nodes(parent)
	selection_updated.emit(tree_node)


func _on_tree_edit_mouse_entered() -> void:
	_is_treehave_panel_hovered = true


func _on_tree_edit_mouse_exited() -> void:
	_is_treehave_panel_hovered = false


func _on_undo_button_pressed():
	_undo_last_graph_action()


func _on_tree_edit_node_selected(node: TreehaveTreeNode) -> void:
	selection_updated.emit(node)
