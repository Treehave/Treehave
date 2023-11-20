@tool
class_name TreehaveTreeNode
extends GraphNode


signal remove_decorator_requested(decorator)

var node: Node
var parent: TreehaveTreeNode : set = _set_parent
var children: Array[TreehaveTreeNode] = []
var root: TreehaveTreeNode
var is_decorated: bool : get = _get_is_decorated
var is_root: bool : get = _get_is_root

var _decorators := {}


func _init(from: Node, decorators: Array[Decorator] = [], tree_root: TreehaveTreeNode = null) -> void:
	node = from
	title = from.name
	root = tree_root if tree_root else self

	# goes through decorators in reverse order so that they display correctly
	decorators.reverse()
	for decorator in decorators:
		decorate(decorator)

	close_request.connect(delete)

	set_slot(0, true, 0, Color(0.0, 0.0, 0.0, 0.0), true, 0, Color(0.0, 0.0, 0.0, 0.0))
	show_close = true
	add_texture_rect(_get_node_script_icon(from))
	add_label("\n".join(from._get_configuration_warnings()))


func delete() -> void:
	for child in children:
		child.delete()

	if parent:
		parent.remove_tree_node_child(self)

	if node:
		node.queue_free()


func _set_parent(new_parent: TreehaveTreeNode) -> void:
	print("parent set to " + str(new_parent))
	if parent == new_parent:
		return

	parent = new_parent

	if parent:
		parent.add_tree_node_child(self)


func add_tree_node_child(child: TreehaveTreeNode) -> void:
	if child == null or child in children:
		return

	# Go to root of decorator tree
	var child_root := child.node
	while child_root.get_parent() is Decorator:
		child_root = child_root.get_parent()

	# Update node in scene tree
	child_root.get_parent().remove_child(child_root)
	node.add_child(child_root)
	_update_node_owner(child_root)

	children.append(child)
	child.parent = self


func remove_tree_node_child(child: TreehaveTreeNode) -> void:
	if not child in children:
		return

	children.erase(child)
	child.parent = null
	node.remove_child(child.node)


func decorate(decorator: Decorator) -> void:
	var hbox_container := HBoxContainer.new()
	add_texture_rect(_get_node_script_icon(decorator), hbox_container)
	add_label(decorator.name, hbox_container)
	add_button(_on_remove_decorator_button_pressed.bind(decorator), "close", hbox_container)
	var panel_container := PanelContainer.new()
	panel_container.add_child(hbox_container)
	panel_container.add_theme_stylebox_override("panel", preload("res://addons/treehave/decorator_stylebox.tres"))
	add_child(panel_container)
	move_child(panel_container, 0)

	_decorators[decorator] = panel_container


func has_decorator(decorator: Decorator) -> bool:
	return decorator in _decorators.keys()


func remove_decorator(decorator: Decorator = null) -> void:
	if decorator == null:
		decorator = _decorators.keys()[0]

	if not has_decorator(decorator):
		return

	# Remove decorator in scene tree
	var parent := decorator.get_parent()
	var child := decorator.get_child(0)
	var index := decorator.get_index()

	parent.remove_child(decorator)
	parent.add_child(child)
	parent.move_child(child, index)
	child.set_owner(parent)

	# Remove decorator from graph view
	_decorators[decorator].queue_free()
	_decorators.erase(decorator)

	# Free decorator
	decorator.queue_free()


func add_texture_rect(texture: Texture2D, to: Node = self, icon_size := 32) -> void:
	var texture_rect := TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.texture = texture
	texture_rect.custom_minimum_size = Vector2.ONE * icon_size
	to.add_child(texture_rect)


func add_label(text: String, to: Node = self) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	to.add_child(label)


func add_button(bind: Callable, texture_name: String, to: Node = self) -> void:
	var button := TextureButton.new()
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = load("res://addons/treehave/textures/" + texture_name + "_normal.png")
	button.texture_pressed = load("res://addons/treehave/textures/" + texture_name + "_pressed.png")
	button.pressed.connect(bind)
	to.add_child(button)


func _get_is_decorated() -> bool:
	return _decorators.size() > 0


func _get_is_root() -> bool:
	return root == self


func _update_node_owner(node: Node) -> void:
	node.owner = root.node

	for child in node.get_children():
		_update_node_owner(child)


func _get_node_script_icon(node: Node) -> ImageTexture:
	var script := node.get_script()
	var script_map := ProjectSettings.get_global_class_list()
	var icon_path: String = ""

	while icon_path == "" and script != null:
		for i in range(0, script_map.size()):
			if script_map[i].path == script.get_path():
				icon_path = script_map[i].icon
				break

		script = script.get_base_script()

	if icon_path == "":
		return null

	return load(icon_path)


func _on_remove_decorator_button_pressed(decorator: Decorator) -> void:
	remove_decorator(decorator)
