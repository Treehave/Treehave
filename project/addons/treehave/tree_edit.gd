@tool
class_name TreehaveTreeEdit
extends GraphEdit


const X_SPACING := 20.0
const Y_SPACING := 20.0

var root: TreehaveTreeNode : set = set_root
var nodes: Array[TreehaveTreeNode] = []


func _ready():
	var arrange_button: Button = get_zoom_hbox().get_child(7)

	for connection in arrange_button.pressed.get_connections():
		arrange_button.pressed.disconnect(connection.callable)

	arrange_button.pressed.connect(arrange_tree.bind())

	


func _process(_delta):
	queue_redraw()


func _draw():
	var from_node: TreehaveTreeNode
	var to_node: TreehaveTreeNode

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


func clear_tree() -> void:
	for node in nodes:
		node.queue_free()

	nodes.clear()


func set_root(new_root: TreehaveTreeNode) -> void:
	if new_root == null:
		return

	clear_tree()
	root = new_root

	arrange_tree()


func get_tree_node(node: Node) -> TreehaveTreeNode:
	if node == null:
		return null

	for tree_node in nodes:
		if tree_node == node or node is Decorator and tree_node.has_decorator(node):
			return tree_node

	return null


func get_tree_node_by_name(name: String) -> TreehaveTreeNode:
	for tree_node in nodes:
		if tree_node.name == name:
			return tree_node

	return null


func add_node(node: TreehaveTreeNode) -> void:
	if node == null or nodes.has(node):
		return

	nodes.append(node)
	node.owner = self
	add_child(node)


func remove_node(node: TreehaveTreeNode) -> Array[TreehaveTreeNode]:
	if node == null or !nodes.has(node):
		return []

	var removed_nodes: Array[TreehaveTreeNode] = []

	for child in node.children:
		removed_nodes.append_array(remove_node(child))

	remove_all_connections(node)
	nodes.erase(node)
	removed_nodes.append(node)
	remove_child(node)

	return removed_nodes


func remove_all_connections(tree_node: TreehaveTreeNode) -> void:
	var connections := get_connection_list()

	for connection in connections:
		if connection.from == tree_node.name or connection.to == tree_node.name:
			disconnect_node(connection.from, connection.from_port, connection.to, connection.to_port)


func arrange_tree() -> void:
	_arrange_tree_node(root)


func _arrange_tree_node(tree_node: TreehaveTreeNode) -> void:
	if tree_node == null:
		return

	var queue: Array[TreehaveTreeNode] = []
	queue.append(tree_node)

	while queue.size() > 0:
		var current_node: TreehaveTreeNode = queue.pop_front()

		_set_tree_node_position(current_node)

		for child in current_node.children:
			queue.append(child)


func _set_tree_node_position(tree_node: TreehaveTreeNode) -> void:
	var parent_tree_node := tree_node.parent

	if parent_tree_node == null:
		tree_node.set_position_offset(Vector2.ZERO)
		return

	var siblings := parent_tree_node.children
	var sibling_index := siblings.find(tree_node)

	var x_offset: float
	var y_offset: float

	if sibling_index == 0:
		x_offset = parent_tree_node.get_position_offset().x - _get_width(siblings, X_SPACING) / 2 + tree_node.get_size().x / 2
		y_offset = parent_tree_node.get_position_offset().y + parent_tree_node.get_size().y + Y_SPACING
	else:
		x_offset = siblings[sibling_index - 1].get_position_offset().x + siblings[sibling_index - 1].get_size().x + X_SPACING
		y_offset = siblings[0].get_position_offset().y

	tree_node.set_position_offset(Vector2(x_offset, y_offset))


func _get_width(siblings: Array[TreehaveTreeNode], gap := 0.0) -> float:
	var width := 0

	for sibling in siblings:
		width += sibling.get_size().x

	return width + (siblings.size() - 1) * gap


func _calculate_center_position(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO

	return control.position + (control.size / 2 * zoom)
