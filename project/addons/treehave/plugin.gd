@tool
extends EditorPlugin


# A class member to hold the dock during the plugin life cycle.
var dock
var _current_behavior_tree: BeehaveTree
var _editor_interface: EditorInterface
var is_selected_in_editor := false
var is_selected_in_graph_edit := false


func _enter_tree():
	# Initialization of the plugin goes here.
	_editor_interface = get_editor_interface()
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/treehave/treehave.tscn").instantiate()
	dock.editor_interface = get_editor_interface()
	dock.find_child("GraphEdit").connect("node_selected", _on_graph_node_selected)
	_editor_interface.get_selection().selection_changed.connect(_on_selection_changed)

	# Add the loaded scene to the docks.
	add_control_to_bottom_panel(dock, "Treehave")
	# Note that LEFT_UL means the left of the editor, upper-left dock.


func _on_selection_changed()->void:
	if is_selected_in_graph_edit:
		is_selected_in_graph_edit = false
		return

	is_selected_in_editor = true
	
	var selected_objects := get_editor_interface().get_selection().get_selected_nodes()

	if not selected_objects.size() == 1:
		return

	var selected_object := selected_objects[0]

	if selected_object is BeehaveNode or selected_object is BeehaveTree:
		var tree := selected_object

		while not tree is BeehaveTree:
			tree = tree.get_parent()

		dock.set_tree(tree)
		dock.set_selected(selected_object)
		_current_behavior_tree = tree
	
	dock.selected_tree_node = selected_object


func _on_graph_node_selected(node: GraphNode)->void:
	if is_selected_in_editor:
		is_selected_in_editor = false
		return

	is_selected_in_graph_edit = true

	var editor_selection: EditorSelection = _editor_interface.get_selection()
	editor_selection.clear()

	var selected_node = dock.get_tree_node(node)
	editor_selection.add_node(selected_node)
	dock.selected_tree_node = selected_node


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_bottom_panel(dock)
	# Erase the control from the memory.
	dock.free()
