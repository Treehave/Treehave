@tool
extends Button


var node_path
var graph_edit : GraphEdit


func _on_pressed():
	var _new_graph_node : GraphNode = load(node_path).instantiate()
	graph_edit.add_child(_new_graph_node)
