class_name TreehaveGraphNode
extends GraphNode

signal remove_decorator_requested

var decorated := false


func _ready()->void:
	set_slot(0, true, 0, Color(0.0, 0.0, 0.0, 0.0), true, 0, Color(0.0, 0.0, 0.0, 0.0))

	# Show close must be true or graph nodes cannot be deleted by the user within
	# the graph view
	show_close = true


func decorate(decorator_name: String, icon: Texture2D) -> void:
	if decorated:
		return
	
	var hbox_container := HBoxContainer.new()
	add_texture_rect(icon, hbox_container)
	add_label(decorator_name, hbox_container)
	add_button(_on_remove_decorator_button_pressed, "close", hbox_container)
	var panel_container := PanelContainer.new()
	panel_container.add_child(hbox_container)
	panel_container.add_theme_stylebox_override("panel", preload("res://addons/treehave/decorator_stylebox.tres"))
	add_child(panel_container)
	move_child(panel_container, 0)
	decorated = true


func remove_decorator() -> void:
	if not decorated:
		return
	
	get_child(0).queue_free()
	decorated = false


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
	to.add_child(label)


func add_button(bind: Callable, texture_name: String, to: Node = self) -> void:
	var button := TextureButton.new()
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = load("res://addons/treehave/textures/" + texture_name + "_normal.png")
	button.texture_pressed = load("res://addons/treehave/textures/" + texture_name + "_pressed.png")
	button.pressed.connect(bind)
	to.add_child(button)


func _on_remove_decorator_button_pressed() -> void:
	remove_decorator_requested.emit()
