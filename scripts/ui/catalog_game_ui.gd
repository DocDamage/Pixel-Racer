extends GameUI
class_name CatalogGameUI

func open_track_library() -> void:
	_clear_modal()
	var panel := _modal_panel("TRACK LIBRARY", Vector2(45, 18), Vector2(550, 324))
	var box := panel.get_node("Content") as VBoxContainer
	var share_button := _make_button(
		"SHARE / IMPORT .PIXELTRACK",
		_open_modern_sharing,
		GOLD,
		Vector2(250, 26)
	)
	box.add_child(share_button)
	var sharing_help := Label.new()
	sharing_help.text = "Portable packages include track data, metadata, and a preview. Legacy JSON remains import-compatible inside the review flow."
	sharing_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sharing_help.add_theme_font_size_override("font_size", 9)
	sharing_help.add_theme_color_override("font_color", MUTED)
	box.add_child(sharing_help)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 190)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(492, 0)
	scroll.add_child(list)
	var entries: Array[Dictionary] = game.track_library_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "No saved tracks yet. Save from the Builder first."
		list.add_child(empty)
	else:
		for entry in entries:
			list.add_child(_track_card(entry))
	box.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(510, 26)))
	share_button.grab_focus()

func _open_modern_sharing() -> void:
	_clear_modal()
	if game != null and game.has_method("open_track_sharing"):
		if bool(game.call("open_track_sharing")):
			return
	show_status("Track sharing is unavailable.")
