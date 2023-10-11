@tool
extends GraphEdit


func _process(_delta):
	queue_redraw()


func _draw():
	var first_node: GraphNode
	var second_node: GraphNode

	for connection in get_connection_list():
		# Search through children for nodes with matching names and assign indexes
		for node in get_children():
			if node.name == connection.get("from"):
				first_node = node

			elif node.name == connection.get("to"):
				second_node = node
		# Draw one line per connection
		draw_line(_calculate_center_position(first_node), 
					_calculate_center_position(second_node), Color.BLUE, 5, true)


func _calculate_center_position(control: Control) -> Vector2:
	return control.position + (control.size / 2 * zoom)
