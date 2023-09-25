@tool
extends EditorPlugin


# A class member to hold the dock during the plugin life cycle.
var dock


func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/treehave/editor_dock.tscn").instantiate()

	# Add the loaded scene to the docks.
	add_control_to_bottom_panel(dock, "Treehave")
	# Note that LEFT_UL means the left of the editor, upper-left dock.


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_bottom_panel(dock)
	# Erase the control from the memory.
	dock.free()
