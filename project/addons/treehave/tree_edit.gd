@tool
extends GraphEdit


signal arrange_nodes_requested


func _ready():
	var arrange_button: Button = get_zoom_hbox().get_child(7)

	for connection in arrange_button.pressed.get_connections():
		arrange_button.pressed.disconnect(connection.callable)

	arrange_button.pressed.connect(func(): arrange_nodes_requested.emit())


func _process(_delta):
	queue_redraw()


func _draw():
	var from_node: GraphNode
	var to_node: GraphNode

	for connection in get_connection_list():
		# Search through children for nodes with matching names and assign nodes
		for node in get_children():
			if node.name == connection.get("from"):
				from_node = node

			elif node.name == connection.get("to"):
				to_node = node
		# Draw one line per connection
		draw_line(_calculate_center_position(from_node), 
					_calculate_center_position(to_node), Color.BLUE, 5 * zoom, true)


func _calculate_center_position(control: Control) -> Vector2:
	if control != null:
		return control.position + (control.size / 2 * zoom)

	return Vector2.ZERO
