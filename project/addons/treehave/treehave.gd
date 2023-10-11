@tool
extends Control

var _node_spawn_button_preload : PackedScene = preload(
				"res://addons/treehave/graph_node_spawn_button.tscn")
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
	var root_node := _create_graph_node(_current_behavior_tree)
	_add_graph_for_children(_current_behavior_tree, root_node)


func _add_graph_for_children(root:Node, parent_graph:GraphNode)->void:
	# For each child of root, create a graph node and connect it to parent_graph
	# that last part's not implemented yet
	for child in root.get_children():
		var graph_node := _create_graph_node(child)
		# connect the graph_node to parent_graph here
		_add_graph_for_children(child, graph_node)


func _create_graph_node(from:Node)->GraphNode:
	# Create a new graph node with the same name as "from" and return it
	var graph_node := GraphNode.new()
	graph_node.title = from.name
	_graph_edit.add_child(graph_node)
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
	print(path)
	var _path_array : Array = path.split("/")
	var _node_name = _path_array[_path_array.size() - 1]

	var _node_spawn_button = _node_spawn_button_preload.instantiate()
	_node_spawn_button.set_text(_node_name)
	_node_spawn_button.node_path = path
	_node_spawn_button.graph_edit = _graph_edit

	_panel_vbox.add_child(_node_spawn_button)


func _on_selection_panel_gui_input(event) -> void:
	pass
