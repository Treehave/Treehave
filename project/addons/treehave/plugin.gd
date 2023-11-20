@tool
extends EditorPlugin


var dock


func _enter_tree():
	dock = preload("./treehave_dock.gd").new()
	add_control_to_bottom_panel(dock, "Treehave")


func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.free()
