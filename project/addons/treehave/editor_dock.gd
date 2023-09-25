@tool
extends Control

@onready var _graph_edit: GraphEdit = %GraphEdit

func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.connect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.disconnect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]):
	for node_name in nodes:
		_graph_edit.get_node(str(node_name)).queue_free()


func _on_graph_edit_gui_input(event):
	if not event is InputEventMouseButton or not event.button_index == 2 or not event.pressed:
		return

	print(event)
