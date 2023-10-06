@tool
extends GraphEdit


func _process(_delta):
	queue_redraw()


func _draw():
	draw_line(_calculate_center_position(%GraphNode), _calculate_center_position(%GraphNode3), Color.RED, 5, true)
	draw_line(_calculate_center_position(%GraphNode2), _calculate_center_position(%GraphNode3), Color.GREEN, 5, true)
	draw_line(_calculate_center_position(%GraphNode), _calculate_center_position(%GraphNode2), Color.BLUE, 5, true)


func _calculate_center_position(control: Control) -> Vector2:
	return control.position + (control.size / 2 * zoom)
