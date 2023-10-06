@tool
extends GraphEdit


func _process(_delta):
	queue_redraw()


func _draw():
	draw_line(_calculate_center_position(%GraphNode), _calculate_center_position(%GraphNode3), Color.RED, 5, true)
	draw_line(_calculate_center_position(%GraphNode2), _calculate_center_position(%GraphNode3), Color.GREEN, 5, true)
	draw_line(_calculate_center_position(%GraphNode), _calculate_center_position(%GraphNode2), Color.BLUE, 5, true)


func _calculate_center_position(control: Control) -> Vector2:
	var x_center_posiiton = control.position.x + (control.size.x / 2 * zoom)
	var y_center_position = control.position.y + (control.size.y / 2 * zoom)

	return Vector2(x_center_posiiton, y_center_position)
