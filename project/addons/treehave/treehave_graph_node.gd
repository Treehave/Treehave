class_name TreehaveGraphNode
extends GraphNode

signal remove_decorator_requested(decorator)

var is_decorated: bool : get = _get_is_decorated
var _decorators := {}


func _ready()->void:
	set_slot(0, true, 0, Color(0.0, 0.0, 0.0, 0.0), true, 0, Color(0.0, 0.0, 0.0, 0.0))

	# Show close must be true or graph nodes cannot be deleted by the user within
	# the graph view
	show_close = true


func create(from: Node, decorators: Array[Decorator], _get_node_script_icon: Callable) -> void:
	title = _add_spaces_between_words(from.name)
	
	# goes through decorators in reverse order so that they display correctly
	decorators.reverse()
	for decorator in decorators:
		decorate(decorator, _get_node_script_icon.call(decorator))

	add_texture_rect(_get_node_script_icon.call(from))
	add_label("\n".join(from._get_configuration_warnings()))


func _add_spaces_between_words(target:String)->String:
	var return_string := ""
	for char in target:
		if char.to_upper() == char:
			return_string += " "
		return_string += char
	
	return return_string


func decorate(decorator: Decorator, icon: Texture2D) -> void:
	var hbox_container := HBoxContainer.new()
	add_texture_rect(icon, hbox_container)
	add_label(decorator.name, hbox_container)
	add_button(_on_remove_decorator_button_pressed.bind(decorator), "close", hbox_container)
	var panel_container := PanelContainer.new()
	panel_container.add_child(hbox_container)
	panel_container.add_theme_stylebox_override("panel", preload("res://addons/treehave/decorator_stylebox.tres"))
	add_child(panel_container)
	move_child(panel_container, 0)

	_decorators[decorator] = panel_container


func remove_decorator(decorator) -> void:
	_decorators[decorator].queue_free()
	_decorators.erase(decorator)


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


func _on_remove_decorator_button_pressed(decorator: Decorator) -> void:
	remove_decorator_requested.emit(decorator)


func _get_is_decorated() -> bool:
	return _decorators.size() > 0
