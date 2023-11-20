@tool
extends GraphEdit

var _current_behavior_tree: BeehaveTree
var _tree_nodes: Array[TreehaveTreeNode] = []


func update_selection(editor_selection: EditorSelection) -> void:
	var selected_nodes := editor_selection.get_selected_nodes()

	if not selected_nodes.size() == 1:
		return

	var selected_node := selected_nodes[0]

	if selected_node is BeehaveTree:
		set_tree(selected_node)
	elif selected_node is BeehaveNode:
		set_selected_beehave_node(selected_node)


func set_tree(new_tree: BeehaveTree) -> void:
#	if _current_behavior_tree == new_tree:
#		return

#	_clear()
	_current_behavior_tree = new_tree
	_build()
#	_arrange()


func get_tree_node(beehave_node: BeehaveNode) -> TreehaveTreeNode:
	if beehave_node is Decorator and not beehave_node.get_children().is_empty():
		beehave_node = beehave_node.get_child(0)

	for tree_node in _tree_nodes:
		if tree_node.scene_node == beehave_node:
			return tree_node

	return null

func set_selected_beehave_node(beehave_node: BeehaveNode) -> void:
	var tree := beehave_node.get_parent()

	while not tree is BeehaveTree:
		tree = tree.get_parent()

	set_tree(tree)

#	get_tree_node(beehave_node).select()


func _build() -> void:
	var root := GraphNode.new()
	root.title = _current_behavior_tree.name
	add_child(root)

	for child in _current_behavior_tree.get_children():
		_build_tree_node(child)


func _build_tree_node(beehave_node: BeehaveNode) -> void:
	if not beehave_node is Decorator:
		var tree_node := TreehaveTreeNode.new(beehave_node)

		_tree_nodes.append(tree_node)
		add_child(tree_node)

	for child in beehave_node.get_children():
		_build_tree_node(child)
