@tool
extends EditorPlugin


var _dock


func _enter_tree() -> void:
	_dock = preload("./treehave_dock.gd").new()
	add_control_to_bottom_panel(_dock, "Treehave")

	var editor_interface := get_editor_interface()
	var editor_selection := editor_interface.get_selection()
	editor_selection.selection_changed.connect(_dock.update_selection.bind(editor_selection))


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dock)
	_dock.queue_free()
