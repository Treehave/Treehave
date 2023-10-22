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
	dock.find_child("GraphEdit").connect("node_selected", self._on_graph_node_selected)
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

	if selected_object is BeehaveTree:
		dock.set_tree(selected_object)
		_current_behavior_tree = selected_object

	if selected_object is BeehaveNode:
		var tree := selected_object.get_parent()

		while not tree is BeehaveTree:
			tree = tree.get_parent()

		dock.set_tree(tree)
		dock.set_selected(selected_object)
		_current_behavior_tree = tree


func _on_graph_node_selected(node: GraphNode)->void:
	if is_selected_in_editor:
		is_selected_in_editor = false
		return

	print(node.name)

	is_selected_in_graph_edit = true

	var editor_selection: EditorSelection = _editor_interface.get_selection()
	editor_selection.clear()

	var node_path_from_name = node.name.replace("_", "/")

	if node_path_from_name == "/":
		editor_selection.add_node(_current_behavior_tree)
		return
	
	editor_selection.add_node(_current_behavior_tree.get_node(
								NodePath(node.name.replace("_", "/"))))


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_bottom_panel(dock)
	# Erase the control from the memory.
	dock.free()
