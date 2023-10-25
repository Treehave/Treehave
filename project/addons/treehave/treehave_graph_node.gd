class_name TreehaveGraphNode
extends GraphNode


func _ready()->void:
	set_slot(0, true, 0, Color(0.0, 0.0, 0.0, 0.0), true, 0, Color(0.0, 0.0, 0.0, 0.0))


func add_texture_rect(texture: Texture2D, to: Node = self, rect_size := Vector2(16, 16)) -> void:
	var texture_rect := TextureRect.new()
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.size = rect_size
	to.add_child(texture_rect)


func add_label(text: String, to: Node = self) -> void:
	var label := Label.new()
	label.text = text
	to.add_child(label)
