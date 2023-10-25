class_name TreehaveGraphNode
extends GraphNode

var decorated := false


func _ready()->void:
	set_slot(0, true, 0, Color(0.0, 0.0, 0.0, 0.0), true, 0, Color(0.0, 0.0, 0.0, 0.0))


func decorate(decorator_name: String, icon: Texture2D) -> void:
	if decorated:
		return
	
	var hbox_container := HBoxContainer.new()
	add_texture_rect(icon, hbox_container)
	add_label(decorator_name, hbox_container)
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
