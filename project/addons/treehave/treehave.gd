@tool
extends PanelContainer


const X_SPACING := 240.0
const Y_SPACING := 160.0
const GRAPH_MENU_ACTIONS := ["Add Node"]
const BEEHAVE_NODES_TO_EXCLUDE := [
	"res://addons/beehave/nodes/leaves/action.gd",
	"res://addons/beehave/nodes/leaves/condition.gd",
	"res://addons/beehave/nodes/leaves/leaf.gd",
	"res://addons/beehave/nodes/decorators/decorator.gd",
	"res://addons/beehave/nodes/composites/composite.gd",
	"res://addons/beehave/nodes/beehave_node.gd",
]

var editor_interface: EditorInterface
var _graph_node_preset := preload(
				"res://addons/treehave/preset_nodes/graph_node_preset.tscn")
var _current_behavior_tree: BeehaveTree

var _node_graph_node_map: Dictionary = {}
var selected_tree_node: Node
var _is_treehave_panel_hovered := false

@onready var _graph_edit: GraphEdit = %GraphEdit


func _input(event: InputEvent) -> void:
	if not _is_treehave_panel_hovered:
		return

	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
			_popup_graph_node_menu()


func _popup_graph_node_menu() -> void:
	if selected_tree_node == null or selected_tree_node is Leaf or selected_tree_node is Leaf:
		return

	var menu := PopupMenu.new()
	add_child(menu)

	for action in GRAPH_MENU_ACTIONS:
		menu.add_item(action)

	menu.position = get_global_mouse_position()
	menu.popup()

	menu.index_pressed.connect(_on_graph_node_menu_index_pressed.bind(menu))


func _popup_add_node_menu() -> void:
	var menu := PopupMenu.new()
	add_child(menu)

	for file_path in _get_gd_files_in_directory(editor_interface.get_resource_filesystem().get_filesystem()):
		if load(file_path).new() is BeehaveNode and not BEEHAVE_NODES_TO_EXCLUDE.has(file_path):
			var id := menu.item_count
			menu.add_item(_get_name_from_path(file_path), id)
			menu.set_item_metadata(id, file_path)

	menu.popup_centered()

	menu.index_pressed.connect(_on_add_node_menu_index_pressed.bind(menu))


func _get_gd_files_in_directory(directory:EditorFileSystemDirectory) -> Array[String]:
	var paths: Array[String] = []

	for file_index in directory.get_file_count():
		if directory.get_file_type(file_index) == "GDScript":
			paths.append(directory.get_file_path(file_index))

	for dir_index in directory.get_subdir_count():
		paths.append_array(_get_gd_files_in_directory(directory.get_subdir(dir_index)))

	return paths


func _on_graph_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	match menu.get_item_text(index):
		"Add Node":
			_popup_add_node_menu()
	menu.queue_free()


func _on_add_node_menu_index_pressed(index: int, menu: PopupMenu) -> void:
	var node_path: String = menu.get_item_metadata(index)

	var new_tree_node : BeehaveNode = load(node_path).new()
	new_tree_node.name = _get_name_from_path(node_path)
	selected_tree_node.add_child(new_tree_node)
	new_tree_node.owner = _current_behavior_tree

	_build_graph_node(new_tree_node)

	_arrange_current_tree_graph()

	menu.queue_free()


func _get_name_from_path(path: String) -> String:
	return path.get_basename().get_file().capitalize()


func set_tree(tree: BeehaveTree) -> void:
	_current_behavior_tree = tree
	_clear_current_graph()
	_build_current_tree_graph()
	_arrange_current_tree_graph()


func set_selected(node: Node) -> void:
	get_graph_node(node).selected = true


func _clear_current_graph() -> void:
	_node_graph_node_map.clear()
	_graph_edit.clear_connections()
	# Delete all children of the GraphEdit.
	for node in _graph_edit.get_children():
		node.queue_free()


func get_graph_node(node: Node) -> GraphNode:
	return _node_graph_node_map[node]


func get_tree_node(graph_node: GraphNode) -> Node:
	return _node_graph_node_map.find_key(graph_node)


func _build_current_tree_graph() -> void:
	# Translates the beehave tree represented by _current_behavior_tree into a graph.
	_create_graph_node(_current_behavior_tree)
	_build_graph_node(_current_behavior_tree.get_child(0))


func _build_graph_node(node: Node) -> void:
	if node == null:
		return

	var parent_graph_node := get_graph_node(node.get_parent())
	var graph_node := _create_graph_node(node)

	_graph_edit.connect_node(parent_graph_node.name, 0, graph_node.name, 0)

	for child in node.get_children():
		_build_graph_node(child)


func _create_graph_node(from: Node) -> GraphNode:
	# Create a new graph node with the same name and title as "from,"
	# store a reference to the node it's being created from, and return it
	var graph_node := _graph_node_preset.instantiate()
	graph_node.title = from.name
	graph_node.get_node("Icon").texture = _get_node_script_icon(from)
	graph_node.get_node("Label").text = "\n".join(from._get_configuration_warnings())
	_graph_edit.add_child(graph_node)
	_node_graph_node_map[from] = graph_node

	graph_node.close_request.connect(_on_graph_node_delete_request.bind(graph_node))
	graph_node.dragged.connect(_on_graph_node_dragged.bind(graph_node))

	return graph_node


func _delete_graph_node(graph_node: GraphNode) -> void:
	var node = get_tree_node(graph_node)

	if node is BeehaveTree:
		return

	for child in node.get_children():
		_delete_graph_node(get_graph_node(child))

	_node_graph_node_map.erase(node)
	_node_graph_node_map.erase(graph_node)

	_remove_all_connections(graph_node)

	node.queue_free()
	graph_node.queue_free()


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

		_set_graph_node_position(current_node)

		for child in current_node.get_children():
			queue.append(child)


func _set_graph_node_position(node: Node) -> void:
	var parent_node := node.get_parent()
	var graph_node := get_graph_node(node)
	var parent_graph_node := get_graph_node(parent_node)
	var sibling_index := parent_node.get_children().find(node)
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


func _get_node_width(node: Node, depth := -1) -> int:
	if node == null or node.get_child_count() == 0 or depth == 0:
		return 1

	var width := 0

	for child in node.get_children():
		width += _get_node_width(child, depth - 1)

	return width


func _get_node_script_icon(node: Node) -> ImageTexture:
	var script := node.get_script()
	if script == null:
		return null

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

	_arrange_current_tree_graph()


func _reorder_node_siblings(node_array: Array[Node]) -> void:
	for node in node_array:
		var parent := node.get_parent()
		parent.remove_child(node)
		parent.add_child(node)
		node.owner = _current_behavior_tree

		_reorder_node_siblings(node.get_children())


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		_delete_graph_node(_graph_edit.get_node(str(node_name)))


func _on_graph_node_delete_request(graph_node: GraphNode) -> void:
	_delete_graph_node(graph_node)


func _on_graph_node_dragged(_from: Vector2, _to: Vector2, graph_node: GraphNode) -> void:
	_reorder_nodes(get_tree_node(graph_node).get_parent())


func _on_graph_edit_gui_input(event) -> void:
	if not event is InputEventMouseButton or not event.button_index == 2 or not event.pressed:
		return


func _on_graph_edit_mouse_entered() -> void:
	_is_treehave_panel_hovered = true


func _on_graph_edit_mouse_exited() -> void:
	_is_treehave_panel_hovered = false
