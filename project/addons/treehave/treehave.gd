@tool
extends Control

var _node_spawn_button_preload := preload(
				"res://addons/treehave/graph_node_spawn_button.tscn")
var _graph_node_preset := preload(
				"res://addons/treehave/preset_nodes/graph_node_preset.tscn")
var _current_behavior_tree : BeehaveTree

@onready var _graph_edit: GraphEdit = %GraphEdit
@onready var _file_dialog: FileDialog = %FileDialog
@onready var _panel_vbox: VBoxContainer = %PanelVBox


func set_tree(tree: BeehaveTree):
	_current_behavior_tree = tree
	_clear_current_graph()
	_build_current_tree_graph()


func _clear_current_graph()->void:
	# Delete all children of the GraphEdit.
	for node in _graph_edit.get_children():
		node.queue_free()


func _build_current_tree_graph()->void:
	# Translates the beehave tree represented by _current_behavior_tree into a graph.
	var root_node := _create_graph_node(_current_behavior_tree, 0, 0)
	_add_graph_for_children(_current_behavior_tree, root_node, 1)


func _add_graph_for_children(root:Node, parent_graph:GraphNode, tree_level: int)->void:
	# For each child of root, create a graph node and connect it to parent_graph
	# that last part's not implemented yet
	for child in root.get_children():
		var child_number = child.get_index()

		var graph_node := _create_graph_node(child, tree_level, child_number)
		_graph_edit.connect_node(parent_graph.name, 0, graph_node.name, 0)
		_add_graph_for_children(child, graph_node, tree_level + 1)


func _create_graph_node(from: Node, tree_level: int, child_number: int)->GraphNode:
	# Create a new graph node with the same name and title as "from" and return it
	var graph_node : GraphNode = _graph_node_preset.instantiate()
	graph_node.title = from.name
	graph_node.set_name(from.name)
	_graph_edit.add_child(graph_node)
	graph_node.set_position_offset(Vector2(child_number * 200.0, tree_level * 150.0))
	return graph_node


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.connect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		_graph_edit.get_node(str(node_name)).queue_free()


func _on_graph_edit_gui_input(event) -> void:
	if not event is InputEventMouseButton or not event.button_index == 2 or not event.pressed:
		return


func _on_add_scene_button_pressed() -> void:
	_file_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	var _path_array : Array = path.split("/")
	var _node_name = _path_array[_path_array.size() - 1]

	var _node_spawn_button = _node_spawn_button_preload.instantiate()
	_node_spawn_button.set_text(_node_name)
	_node_spawn_button.node_path = path
	_node_spawn_button.graph_edit = _graph_edit

	_panel_vbox.add_child(_node_spawn_button)


func _on_selection_panel_gui_input(event) -> void:
	pass
