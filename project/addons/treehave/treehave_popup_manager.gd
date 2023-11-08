class_name TreehavePopupManager
extends Node

var _menu: PopupMenu = null


func create_popup_menu(position := Vector2.ZERO, items: Array[String] = [], metadata := []) -> PopupMenu:
	# as of right now, this function is never called with the items or metadata parameters,
	# because the add_item_to_menu function is used instead.
	# I left the parameters in because I thought they might be useful in the future.
	
	_menu = PopupMenu.new()

	for i in items.size():
		_menu.add_item(items[i], i)
		if metadata.size() > i:
			_menu.set_item_metadata(i, metadata[i])

	_menu.position = position
	# this will pop up the menu when it's added to the scene tree.
	_menu.ready.connect(_menu.popup)

	return _menu


func add_item_to_menu(item: String, metadata: Variant = null) -> void:
	if not is_instance_valid(_menu):
		return

	var index := _menu.item_count
	_menu.add_item(item, index)

	if metadata != null:
		_menu.set_item_metadata(index, metadata)
