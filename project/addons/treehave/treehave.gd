@tool
extends Control


const X_SPACING := 240.0
const Y_SPACING := 160.0

var _graph_node_preset := preload(
				"res://addons/treehave/preset_nodes/graph_node_preset.tscn")
var _current_behavior_tree: BeehaveTree

var _node_to_graph_node_map: Dictionary = {}

@onready var _graph_edit: GraphEdit = %GraphEdit

func set_tree(tree: BeehaveTree) -> void:
	_current_behavior_tree = tree
	_clear_current_graph()
	_build_current_tree_graph()
	_arrange_current_tree_graph()


func _clear_current_graph() -> void:
	_node_to_graph_node_map.clear()
	_graph_edit.clear_connections()
	# Delete all children of the GraphEdit.
	for node in _graph_edit.get_children():
		node.queue_free()


func _get_graph_node(node: Node) -> GraphNode:
	return _node_to_graph_node_map[node]


func _build_current_tree_graph() -> void:
	# Translates the beehave tree represented by _current_behavior_tree into a graph.
	_create_graph_node(_current_behavior_tree)
	_build_graph_node(_current_behavior_tree.get_child(0))


func _build_graph_node(node: Node) -> void:
	if node == null:
		return

	var parent_graph_node := _get_graph_node(node.get_parent())
	var graph_node := _create_graph_node(node)

	_graph_edit.connect_node(parent_graph_node.name, 0, graph_node.name, 0)

	for child in node.get_children():
		_build_graph_node(child)


func _create_graph_node(from: Node) -> GraphNode:
	# Create a new graph node with the same name and title as "from" and return it
	var graph_node := _graph_node_preset.instantiate()
	graph_node.title = from.name
	graph_node.set_name(from.name)
	_graph_edit.add_child(graph_node)
	_node_to_graph_node_map[from] = graph_node

	return graph_node


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
	var graph_node := _get_graph_node(node)
	var parent_graph_node := _get_graph_node(parent_node)
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


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		_graph_edit.get_node(str(node_name)).queue_free()


func _on_graph_edit_gui_input(event) -> void:
	if not event is InputEventMouseButton or not event.button_index == 2 or not event.pressed:
		return
