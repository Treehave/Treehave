class_name TreehavePopupManager
extends Node

const MAX_ICON_SIZE := Vector2(32, 32)

var _menu: PopupMenu = null


func create_popup_menu(position := Vector2.ZERO) -> PopupMenu:
	_menu = PopupMenu.new()

	_menu.position = position
	# this will pop up the menu when it's added to the scene tree.
	_menu.ready.connect(_menu.popup)

	return _menu


func add_item_to_menu(item: String, metadata: Variant = null, icon: Texture2D = null) -> void:
	if not is_instance_valid(_menu):
		return

	var index := _menu.item_count
	_menu.add_item(item, index)

	if metadata != null:
		_menu.set_item_metadata(index, metadata)
	
	if icon != null:
		if icon.get_size() <= MAX_ICON_SIZE:
			_menu.set_item_icon(index, icon)
