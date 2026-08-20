extends GameUI
class_name CatalogGameUI

func setup(game_root) -> void:
	super.setup(game_root)
	var legacy_hint := _find_label_by_text(race_hud, "ESC: MENU  •  R: RESET")
	if legacy_hint != null:
		legacy_hint.visible = false

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

func open_settings() -> void:
	_rebind_action = ""
	_clear_modal()
	var panel := _modal_panel("SETTINGS + ACCESSIBILITY", Vector2(45, 18), Vector2(550, 324))
	var outer := panel.get_node("Content") as VBoxContainer
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 246)
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(490, 0)
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)
	_add_section_label(box, "ACCESSIBILITY + ASSISTS")
	for pair in [["Traction Assist", "traction_assist"], ["Auto Accelerate", "auto_accelerate"], ["Auto Brake", "auto_brake"], ["Recovery Assist", "recovery_assist"], ["Track Edge Assist", "track_edge_assist"], ["Large Text", "large_text"], ["Colorblind Indicators", "colorblind_indicators"], ["Controller Vibration", "controller_vibration"]]:
		_add_setting_toggle(box, str(pair[0]), str(pair[1]))
	_add_setting_slider(box, "UI Scale", "ui_scale", 0.75, 1.75, 0.05)
	_add_setting_slider(box, "Camera Shake", "camera_shake", 0.0, 1.0, 0.05)
	_add_setting_slider(box, "Flash Intensity", "flash_intensity", 0.0, 1.0, 0.05)
	_add_setting_slider(box, "Steering Sensitivity", "steering_sensitivity", 0.5, 1.75, 0.05)
	_add_setting_slider(box, "Drift Assist", "drift_assist", 0.0, 1.0, 0.05)
	_add_setting_slider(box, "Vibration Strength", "vibration_strength", 0.0, 1.0, 0.05)
	_add_section_label(box, "AUDIO + DISPLAY")
	_add_setting_slider(box, "Master Volume", "master_volume", 0.0, 1.0, 0.05)
	_add_setting_slider(box, "Music Volume", "music_volume", 0.0, 1.0, 0.05)
	_add_setting_slider(box, "SFX Volume", "sfx_volume", 0.0, 1.0, 0.05)
	var window_row := HBoxContainer.new()
	var window_label := Label.new()
	window_label.text = "Window Mode"
	window_label.custom_minimum_size = Vector2(190, 24)
	window_row.add_child(window_label)
	var window_select := OptionButton.new()
	for mode in ["windowed", "fullscreen", "borderless"]:
		window_select.add_item(mode.to_upper())
		window_select.set_item_metadata(window_select.item_count - 1, mode)
		if str(SettingsManager.get_value("window_mode", "windowed")) == mode:
			window_select.select(window_select.item_count - 1)
	window_select.custom_minimum_size = Vector2(210, 24)
	window_select.item_selected.connect(func(index: int): SettingsManager.set_value("window_mode", str(window_select.get_item_metadata(index))))
	window_row.add_child(window_select)
	box.add_child(window_row)
	_add_section_label(box, "DRIVING CONTROLS • CLICK REBIND, THEN PRESS INPUT")
	for action in ["accelerate", "brake", "steer_left", "steer_right", "handbrake", "boost", "reset_vehicle", "pause"]:
		_add_binding_row(box, action)
	_add_section_label(box, "BUILDER CONTROLS")
	for action in ["toggle_test", "builder_test", "builder_place", "builder_erase", "builder_eyedropper", "builder_next_tool", "builder_prev_tool"]:
		_add_binding_row(box, action)
	outer.add_child(_make_button("RESET SETTINGS + CONTROLS", func(): SettingsManager.reset_defaults(); InputManager.reset_defaults(); open_settings(), GOLD, Vector2(510, 26)))
	outer.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(510, 26)))
	_apply_accessibility_visuals()

func _open_modern_sharing() -> void:
	_clear_modal()
	if game != null and game.has_method("open_track_sharing"):
		if bool(game.call("open_track_sharing")):
			return
	show_status("Track sharing is unavailable.")

func _find_label_by_text(node: Node, text_value: String) -> Label:
	if node is Label and (node as Label).text == text_value:
		return node as Label
	for child in node.get_children():
		var found := _find_label_by_text(child, text_value)
		if found != null:
			return found
	return null
