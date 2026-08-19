extends CanvasLayer
class_name GameUI

const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const GOLD := Color("#ffd166")
const GOOD := Color("#61e294")
const BAD := Color("#ff6b6b")
const PANEL := Color("#151922")
const PANEL_2 := Color("#222735")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#a9b2c5")

var game = null
var menu_layer: Control
var builder_hud: Control
var race_hud: Control
var modal_layer: Control
var status_banner: Label
var track_name_label: Label
var validation_label: Label
var tool_label: Label
var builder_status: Label
var race_title: Label
var race_status_label: Label
var lap_label: Label
var timer_label: Label
var speed_label: Label
var nitro_bar: ProgressBar
var countdown_label: Label
var current_vehicle_label: Label
var _countdown_generation := 0
var _rebind_action := ""
var _rebind_label := ""

func setup(game_root) -> void:
	game = game_root
	layer = 20
	_create_layers()
	_build_main_menu()
	_build_builder_hud()
	_build_race_hud()
	_build_status_banner()
	if not SettingsManager.setting_changed.is_connected(_on_setting_changed):
		SettingsManager.setting_changed.connect(_on_setting_changed)
	if not SettingsManager.settings_reset.is_connected(_apply_accessibility_visuals):
		SettingsManager.settings_reset.connect(_apply_accessibility_visuals)
	_apply_accessibility_visuals()

func show_menu() -> void:
	_clear_modal()
	menu_layer.visible = true
	builder_hud.visible = false
	race_hud.visible = false
	_update_vehicle_label()

func show_builder() -> void:
	_clear_modal()
	menu_layer.visible = false
	builder_hud.visible = true
	race_hud.visible = false
	refresh_builder()

func show_race(title: String) -> void:
	_clear_modal()
	menu_layer.visible = false
	builder_hud.visible = false
	race_hud.visible = true
	race_title.text = title

func refresh_builder() -> void:
	if game == null or game.track == null or track_name_label == null:
		return
	var track: TrackData = game.track
	track_name_label.text = "%s%s" % [track.name, " *" if track.dirty else ""]
	tool_label.text = "TOOL: %s" % game.builder.current_tool().to_upper()
	var result: Dictionary = game.validation_result
	var errors: Array = result.get("errors", [])
	var warnings: Array = result.get("warnings", [])
	if errors.is_empty():
		validation_label.text = "✓ VALID" if warnings.is_empty() else "! %d WARN" % warnings.size()
		validation_label.add_theme_color_override("font_color", GOOD if warnings.is_empty() else GOLD)
	else:
		validation_label.text = "✕ %d ERROR" % errors.size()
		validation_label.add_theme_color_override("font_color", BAD)
	if not errors.is_empty():
		builder_status.text = "%s @ %s" % [str(errors[0].get("message", "Invalid track")), str(errors[0].get("cell", Vector2i.ZERO))]
	else:
		builder_status.text = "Shift-drag select • Ctrl+1 main / 2 pit / 3 alt • Ctrl+C/X/V • R/M • X eyedrop • F5 test"

func update_race_hud(state: Dictionary) -> void:
	if state.is_empty() or not race_hud.visible:
		return
	speed_label.text = "%03d" % int(state.get("speed", 0))
	nitro_bar.value = float(state.get("nitro", 0.0))
	var mode := str(state.get("mode", "circuit"))
	if mode == "drift":
		lap_label.text = "DRIFT %.0f" % float(state.get("drift", 0.0))
		timer_label.text = "%.1fs REMAINING" % float(state.get("remaining", 0.0))
	elif mode == "checkpoint":
		lap_label.text = "GATE %d/%d" % [int(state.get("checkpoint", 0)), int(state.get("checkpoints", 0))]
		timer_label.text = "%.1fs REMAINING" % float(state.get("remaining", 0.0))
	elif mode == "elimination":
		lap_label.text = "%d RACERS LEFT" % int(state.get("racers", 1))
		timer_label.text = "NEXT CUT %.1fs" % float(state.get("remaining", 0.0))
	elif mode == "sprint":
		lap_label.text = "SPRINT • GATE %d/%d" % [int(state.get("checkpoint", 0)), int(state.get("checkpoints", 0))]
		timer_label.text = "%.2f" % float(state.get("time", 0.0))
	else:
		lap_label.text = "LAP %d/%d  •  CP %d/%d" % [int(state.get("lap", 0)), int(state.get("laps", 0)), int(state.get("checkpoint", 0)), int(state.get("checkpoints", 0))]
		var best_value := float(state.get("best", INF))
		timer_label.text = "%.2f  •  BEST %s" % [float(state.get("time", 0.0)), "--" if is_inf(best_value) else "%.2f" % best_value]
	var penalty := float(state.get("penalty", 0.0))
	if bool(state.get("pit", false)):
		race_status_label.text = "PIT • LIMIT %.0f%s" % [float(state.get("pit_limit", 0.0)), " • +%.0fs" % penalty if penalty > 0.0 else ""]
		race_status_label.add_theme_color_override("font_color", GOLD)
	else:
		var route := str(state.get("route", "main"))
		var surface := str(state.get("surface", "asphalt"))
		race_status_label.text = "%s%s" % [route.to_upper() if route != "main" else surface.to_upper(), " • +%.0fs" % penalty if penalty > 0.0 else ""]
		race_status_label.add_theme_color_override("font_color", BAD if penalty > 0.0 else MUTED)

func show_countdown(text: String) -> void:
	_countdown_generation += 1
	var generation := _countdown_generation
	countdown_label.text = text
	get_tree().create_timer(1.0).timeout.connect(func():
		if generation == _countdown_generation and countdown_label != null:
			countdown_label.text = ""
	)

func show_result(title: String, detail: String) -> void:
	var panel := _modal_panel(title, Vector2(150, 100), Vector2(340, 160))
	var box := panel.get_node("Content") as VBoxContainer
	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 16)
	box.add_child(detail_label)
	box.add_child(_make_button("RACE AGAIN", func():
		_clear_modal()
		game.start_event(game.active_race_mode)
	, MAGENTA, Vector2(300, 30)))
	box.add_child(_make_button("BACK TO MENU", game.show_menu, ACCENT, Vector2(300, 30)))

func show_status(message: String) -> void:
	status_banner.text = message
	status_banner.visible = true
	var token := Time.get_ticks_msec()
	status_banner.set_meta("token", token)
	get_tree().create_timer(2.6).timeout.connect(func():
		if status_banner != null and int(status_banner.get_meta("token", 0)) == token:
			status_banner.visible = false
	)

func open_race_setup() -> void:
	_clear_modal()
	var panel := _modal_panel("EVENT SETUP", Vector2(90, 34), Vector2(460, 292))
	var box := panel.get_node("Content") as VBoxContainer
	var mode_select := OptionButton.new()
	var mode_ids := RaceModeCatalog.ids()
	for id in mode_ids:
		mode_select.add_item(str(RaceModeCatalog.get_mode(id).get("name", id)))
		mode_select.set_item_metadata(mode_select.item_count - 1, id)
	box.add_child(mode_select)
	var settings_row := HBoxContainer.new()
	box.add_child(settings_row)
	var laps_select := OptionButton.new()
	for laps in [1, 3, 5, 10]:
		laps_select.add_item("%d LAPS" % laps)
		laps_select.set_item_metadata(laps_select.item_count - 1, laps)
	laps_select.select(1)
	settings_row.add_child(laps_select)
	var ai_select := OptionButton.new()
	for count in [0, 3, 5, 7, 11]:
		ai_select.add_item("%d OPPONENTS" % count)
		ai_select.set_item_metadata(ai_select.item_count - 1, count)
	ai_select.select(1)
	settings_row.add_child(ai_select)
	var description := Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(420, 65)
	box.add_child(description)
	var update_description := func(_index = 0):
		var id := str(mode_select.get_item_metadata(mode_select.selected))
		description.text = str(RaceModeCatalog.get_mode(id).get("description", ""))
	mode_select.item_selected.connect(update_description)
	update_description.call()
	box.add_child(_make_button("START EVENT", func():
		var id := str(mode_select.get_item_metadata(mode_select.selected))
		var laps := int(laps_select.get_item_metadata(laps_select.selected))
		var ai := int(ai_select.get_item_metadata(ai_select.selected))
		_clear_modal()
		game.start_event(id, laps, ai)
	, MAGENTA, Vector2(420, 32)))
	box.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(420, 28)))

func open_track_library() -> void:
	_clear_modal()
	var panel := _modal_panel("TRACK LIBRARY", Vector2(45, 18), Vector2(550, 324))
	var box := panel.get_node("Content") as VBoxContainer
	var controls := HBoxContainer.new()
	box.add_child(controls)
	controls.add_child(_make_button("IMPORT JSON", _open_import_dialog, GOLD, Vector2(120, 26)))
	controls.add_child(_make_button("EXPORT CURRENT", func(): game.export_current_package(), ACCENT, Vector2(135, 26)))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 225)
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

func open_garage() -> void:
	_clear_modal()
	var panel := _modal_panel("GARAGE", Vector2(45, 20), Vector2(550, 320))
	var box := panel.get_node("Content") as VBoxContainer
	var wallet := Label.new()
	wallet.text = "Credits: %d" % int(game.career.profile.get("credits", 0))
	wallet.add_theme_color_override("font_color", GOLD)
	box.add_child(wallet)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(515, 230)
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(495, 0)
	scroll.add_child(grid)
	var catalog := VehicleCatalog.new()
	for id in catalog.ids():
		var definition := catalog.get_vehicle(id)
		var owned := game.garage.is_owned(id)
		var label := str(definition.get("name", id))
		if not owned:
			label += "  •  %d cr" % game.garage.vehicle_price(id)
		grid.add_child(_make_button(label, Callable(self, "_open_vehicle_detail").bind(id), ACCENT if owned else PANEL_2, Vector2(240, 29)))
	box.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(515, 26)))

func open_career() -> void:
	_clear_modal()
	var panel := _modal_panel("DOC'S MOTOR PARK • CAREER", Vector2(65, 25), Vector2(510, 310))
	var box := panel.get_node("Content") as VBoxContainer
	var profile := Label.new()
	profile.text = "Credits %d  •  Reputation %d  •  Tier %d" % [int(game.career.profile.get("credits", 0)), int(game.career.profile.get("reputation", 0)), int(game.career.profile.get("tier", 1))]
	profile.add_theme_color_override("font_color", MAGENTA)
	box.add_child(profile)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 205)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(450, 0)
	scroll.add_child(list)
	for contract in game.career.contracts:
		var evaluation := game.career.evaluate_contract(contract, game.track)
		var line := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(330, 48)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var req := ""
		for requirement in evaluation["requirements"]:
			req += "%s %s  " % ["✓" if bool(requirement["met"]) else "•", str(requirement["label"])]
		label.text = "%s  +%d cr / +%d rep\n%s" % [str(contract["name"]), int(contract["reward"]), int(contract["rep"]), req]
		line.add_child(label)
		var id := str(contract["id"])
		line.add_child(_make_button("CLAIM", func():
			if game.claim_contract(id): open_career()
		, GOOD if bool(evaluation["complete"]) else PANEL_2, Vector2(90, 28)))
		list.add_child(line)
	box.add_child(_make_button("BUILD", func(): _clear_modal(); game.enter_builder(), ACCENT, Vector2(470, 28)))
	box.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(470, 26)))

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
	_add_section_label(box, "CONTROLS • CLICK REBIND, THEN PRESS A KEY/BUTTON")
	for action in ["accelerate", "brake", "steer_left", "steer_right", "handbrake", "boost", "reset_vehicle", "toggle_test", "builder_place", "builder_erase", "builder_eyedropper", "builder_next_tool", "builder_prev_tool"]:
		_add_binding_row(box, action)
	outer.add_child(_make_button("RESET SETTINGS + CONTROLS", func(): SettingsManager.reset_defaults(); InputManager.reset_defaults(); open_settings(), GOLD, Vector2(510, 26)))
	outer.add_child(_make_button("CLOSE", _clear_modal, MUTED, Vector2(510, 26)))
	_apply_accessibility_visuals()

func _create_layers() -> void:
	menu_layer = Control.new()
	menu_layer.name = "MenuLayer"
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)
	builder_hud = Control.new()
	builder_hud.name = "BuilderHUD"
	builder_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(builder_hud)
	race_hud = Control.new()
	race_hud.name = "RaceHUD"
	race_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(race_hud)
	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)

func _build_main_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("#0b0e14")
	menu_layer.add_child(backdrop)
	var title := Label.new()
	title.text = "PIXEL TRACK WORKS"
	title.position = Vector2(42, 26)
	title.add_theme_font_size_override("font_size", 27)
	menu_layer.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BUILD IT • TEST IT • RACE IT"
	subtitle.position = Vector2(44, 65)
	subtitle.add_theme_color_override("font_color", MUTED)
	menu_layer.add_child(subtitle)
	var box := VBoxContainer.new()
	box.position = Vector2(42, 100)
	box.size = Vector2(220, 245)
	box.add_theme_constant_override("separation", 5)
	menu_layer.add_child(box)
	box.add_child(_make_button("CONTINUE CAREER", open_career, MAGENTA))
	box.add_child(_make_button("FREE BUILD", game.enter_builder, ACCENT))
	box.add_child(_make_button("EVENT SETUP", open_race_setup, ACCENT))
	box.add_child(_make_button("QUICK RACE", func(): game.start_event("circuit"), ACCENT))
	box.add_child(_make_button("RANDOM TRACK", game.start_random_track, ACCENT))
	box.add_child(_make_button("TRACK LIBRARY", open_track_library, GOLD))
	box.add_child(_make_button("GARAGE", open_garage, GOLD))
	box.add_child(_make_button("SETTINGS", open_settings, MUTED))
	var feature := Label.new()
	feature.position = Vector2(340, 112)
	feature.size = Vector2(255, 140)
	feature.text = "SMART TRACK BUILDER\nINSTANT TEST DRIVE\n6 EVENT RULE SETS\nAI OVERTAKING + DRAFTING\nDRIFT • NITRO • BEST GHOSTS\nCAREER + GARAGE"
	feature.add_theme_font_size_override("font_size", 13)
	feature.add_theme_color_override("font_color", TEXT)
	feature.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_layer.add_child(feature)
	current_vehicle_label = Label.new()
	current_vehicle_label.position = Vector2(340, 272)
	current_vehicle_label.size = Vector2(260, 45)
	current_vehicle_label.add_theme_color_override("font_color", ACCENT)
	menu_layer.add_child(current_vehicle_label)

func _build_builder_hud() -> void:
	var top := PanelContainer.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 40)
	top.add_theme_stylebox_override("panel", _panel_style(PANEL, 0))
	builder_hud.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	top.add_child(row)
	track_name_label = Label.new()
	track_name_label.custom_minimum_size = Vector2(135, 34)
	track_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(track_name_label)
	validation_label = Label.new()
	validation_label.custom_minimum_size = Vector2(92, 34)
	validation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(validation_label)
	row.add_child(_make_button("UNDO", game.builder.undo, MUTED, Vector2(50, 29)))
	row.add_child(_make_button("REDO", game.builder.redo, MUTED, Vector2(50, 29)))
	row.add_child(_make_button("SAVE", game.save_current_track, GOLD, Vector2(50, 29)))
	row.add_child(_make_button("LOAD", open_track_library, GOLD, Vector2(50, 29)))
	row.add_child(_make_button("TEST", game.enter_test_drive, MAGENTA, Vector2(58, 29)))
	row.add_child(_make_button("EVENT", open_race_setup, ACCENT, Vector2(58, 29)))
	row.add_child(_make_button("MENU", game.show_menu, MUTED, Vector2(52, 29)))
	var tools := PanelContainer.new()
	tools.position = Vector2(0, 48)
	tools.size = Vector2(108, 246)
	tools.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.08, 0.11, 0.94), 6))
	builder_hud.add_child(tools)
	var tool_box := VBoxContainer.new()
	tool_box.add_theme_constant_override("separation", 1)
	tools.add_child(tool_box)
	tool_label = Label.new()
	tool_label.text = "BUILD TOOLS"
	tool_label.add_theme_color_override("font_color", ACCENT)
	tool_box.add_child(tool_label)
	var names := {"road":"1 ROAD", "draw_road":"2 DRAW", "pit":"3 PIT", "alternate":"B ALT", "sand":"4 SAND", "dirt":"5 DIRT", "grass":"6 GRASS", "start_finish":"7 START", "checkpoint":"8 CHECK", "barrier":"9 BARRIER", "erase":"0 ERASE"}
	for tool in BuilderController.TOOLS:
		var tool_id := tool
		tool_box.add_child(_make_button(str(names.get(tool, tool.to_upper())), func(): game.builder.set_tool(tool_id), PANEL_2, Vector2(96, 20)))
	var actions := HBoxContainer.new()
	actions.position = Vector2(116, 302)
	actions.add_theme_constant_override("separation", 3)
	builder_hud.add_child(actions)
	actions.add_child(_make_button("COPY", game.builder.copy_selection, PANEL_2, Vector2(52, 24)))
	actions.add_child(_make_button("CUT", game.builder.cut_selection, PANEL_2, Vector2(48, 24)))
	actions.add_child(_make_button("PASTE", game.builder.paste_clipboard, PANEL_2, Vector2(55, 24)))
	actions.add_child(_make_button("ROTATE", game.builder.rotate_clipboard, PANEL_2, Vector2(60, 24)))
	actions.add_child(_make_button("MIRROR", game.builder.mirror_clipboard, PANEL_2, Vector2(60, 24)))
	actions.add_child(_make_button("DELETE", game.builder.delete_selection, BAD, Vector2(60, 24)))
	builder_status = Label.new()
	builder_status.position = Vector2(116, 332)
	builder_status.size = Vector2(510, 22)
	builder_status.add_theme_font_size_override("font_size", 10)
	builder_status.add_theme_color_override("font_color", Color("#d7ddeb"))
	builder_hud.add_child(builder_status)

func _build_race_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(285, 103)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.08, 0.88), 8))
	race_hud.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	race_title = Label.new()
	race_title.add_theme_color_override("font_color", MAGENTA)
	box.add_child(race_title)
	lap_label = Label.new()
	box.add_child(lap_label)
	timer_label = Label.new()
	timer_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(timer_label)
	race_status_label = Label.new()
	race_status_label.add_theme_font_size_override("font_size", 10)
	race_status_label.add_theme_color_override("font_color", MUTED)
	box.add_child(race_status_label)
	speed_label = Label.new()
	speed_label.position = Vector2(500, 300)
	speed_label.size = Vector2(130, 30)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_label.add_theme_font_size_override("font_size", 20)
	race_hud.add_child(speed_label)
	nitro_bar = ProgressBar.new()
	nitro_bar.position = Vector2(475, 334)
	nitro_bar.size = Vector2(155, 12)
	nitro_bar.max_value = 100
	nitro_bar.show_percentage = false
	race_hud.add_child(nitro_bar)
	countdown_label = Label.new()
	countdown_label.position = Vector2(225, 112)
	countdown_label.size = Vector2(190, 125)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 45)
	countdown_label.add_theme_color_override("font_color", MAGENTA)
	race_hud.add_child(countdown_label)
	var hint := Label.new()
	hint.position = Vector2(12, 334)
	hint.text = "ESC: MENU  •  R: RESET"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	race_hud.add_child(hint)

func _build_status_banner() -> void:
	status_banner = Label.new()
	status_banner.position = Vector2(120, 8)
	status_banner.size = Vector2(400, 28)
	status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_banner.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.03, 0.05, 0.92), 6))
	status_banner.add_theme_color_override("font_color", TEXT)
	status_banner.visible = false
	add_child(status_banner)

func _track_card(entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(485, 78)
	card.add_theme_stylebox_override("panel", _panel_style(PANEL_2, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var preview_path := str(entry.get("preview_path", ""))
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(88, 58)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not preview_path.is_empty() and FileAccess.file_exists(preview_path):
		var image := Image.new()
		if image.load(preview_path) == OK:
			preview.texture = ImageTexture.create_from_image(image)
	row.add_child(preview)
	var info := Label.new()
	info.custom_minimum_size = Vector2(280, 60)
	var rating: Dictionary = entry.get("rating", {})
	var best_time := INF
	var best_score := 0.0
	for record in entry.get("records", []):
		if not record is Dictionary:
			continue
		if str(record.get("kind", "")) == "time":
			best_time = minf(best_time, float(record.get("value", INF)))
		elif str(record.get("kind", "")) == "score":
			best_score = maxf(best_score, float(record.get("value", 0.0)))
	var record_text := "NO RECORD"
	if not is_inf(best_time):
		record_text = "BEST %.2fs" % best_time
	if best_score > 0.0:
		record_text += " • DRIFT %.0f" % best_score
	var ghost_count := Array(entry.get("ghosts", [])).size()
	if ghost_count > 0:
		record_text += " • GHOST"
	info.text = "%s\n%.0f length • %d corners • difficulty %d/5 • off-road %d%%\n%s" % [str(entry.get("name", "Track")), float(rating.get("length", 0.0)), int(rating.get("corners", 0)), int(rating.get("difficulty", 1)), int(rating.get("offroad_percent", 0)), record_text]
	info.add_theme_font_size_override("font_size", 10)
	row.add_child(info)
	var id := str(entry.get("track_id", ""))
	var buttons := VBoxContainer.new()
	row.add_child(buttons)
	buttons.add_child(_make_button("EDIT", func(): _clear_modal(); game.load_track_by_id(id, true), ACCENT, Vector2(82, 20)))
	buttons.add_child(_make_button("RACE", func(): _clear_modal(); if game.load_track_by_id(id, false): game.start_event("circuit"), MAGENTA, Vector2(82, 20)))
	buttons.add_child(_make_button("DELETE", func():
		if SaveManager.delete_track(id):
			show_status("Track deleted.")
			open_track_library()
	, BAD, Vector2(82, 20)))
	return card

func _open_vehicle_detail(vehicle_id: String) -> void:
	_clear_modal()
	var definition := VehicleCatalog.new().get_vehicle(vehicle_id)
	var owned := game.garage.is_owned(vehicle_id)
	var panel := _modal_panel(str(definition.get("name", vehicle_id)), Vector2(65, 20), Vector2(510, 320))
	var box := panel.get_node("Content") as VBoxContainer
	var stats: Dictionary = game.garage.effective_definition(vehicle_id).get("stats", definition.get("stats", {}))
	var stat_label := Label.new()
	stat_label.text = "SPD %d  ACC %d  HAND %d  DRIFT %d  BOOST %d" % [int(stats.get("speed", 0)), int(stats.get("accel", 0)), int(stats.get("handling", 0)), int(stats.get("drift", 0)), int(stats.get("boost", 0))]
	stat_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(stat_label)
	if not owned:
		var price := game.garage.vehicle_price(vehicle_id)
		box.add_child(_make_button("BUY • %d CREDITS" % price, func():
			var result: Dictionary = game.buy_vehicle(vehicle_id)
			if bool(result.get("success", false)):
				show_status("Vehicle purchased.")
				_open_vehicle_detail(vehicle_id)
			else:
				show_status("Not enough credits.")
		, GOLD, Vector2(460, 30)))
	else:
		box.add_child(_make_button("SELECT VEHICLE", func(): game.select_vehicle(vehicle_id); _update_vehicle_label(); show_status("Vehicle selected."), MAGENTA, Vector2(460, 28)))
		var color_row := HBoxContainer.new()
		box.add_child(color_row)
		for color in definition.get("colors", ["default"]):
			var color_id := str(color)
			color_row.add_child(_make_button(color_id.to_upper(), func(): game.set_vehicle_color(vehicle_id, color_id), PANEL_2, Vector2(54, 22)))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(460, 125)
		box.add_child(scroll)
		var upgrade_box := VBoxContainer.new()
		upgrade_box.custom_minimum_size = Vector2(440, 0)
		scroll.add_child(upgrade_box)
		for group in GarageManager.UPGRADE_GROUPS:
			var group_id := str(group)
			var level := game.garage.upgrade_level(vehicle_id, group_id)
			var cost := game.garage.upgrade_cost(vehicle_id, group_id)
			var text := "%s • %s" % [group_id.to_upper(), game.garage.tier_name(vehicle_id, group_id)]
			if level < 3:
				text += " • %d cr" % cost
			upgrade_box.add_child(_make_button(text, func():
				var result: Dictionary = game.buy_upgrade(vehicle_id, group_id)
				if bool(result.get("success", false)):
					_open_vehicle_detail(vehicle_id)
				else:
					show_status(str(result.get("reason", "Upgrade failed")))
			, GOOD if level < 3 else PANEL_2, Vector2(430, 24)))
	box.add_child(_make_button("BACK TO GARAGE", open_garage, MUTED, Vector2(460, 26)))

func _open_import_dialog() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Pixel Track JSON"])
	dialog.size = Vector2i(560, 320)
	dialog.file_selected.connect(func(path: String):
		_clear_modal()
		game.import_track_file(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()

func _begin_rebind(action: String) -> void:
	_rebind_action = action
	_rebind_label = action.replace("_", " ").to_upper()
	var panel := _modal_panel("REBIND %s" % _rebind_label, Vector2(150, 110), Vector2(340, 140))
	var box := panel.get_node("Content") as VBoxContainer
	var message := Label.new()
	message.text = "Press a keyboard key, gamepad button, or move a gamepad axis.\nESC cancels."
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.custom_minimum_size = Vector2(300, 50)
	box.add_child(message)
	box.add_child(_make_button("CANCEL", func(): _rebind_action = ""; open_settings(), MUTED, Vector2(300, 28)))

func _input(event: InputEvent) -> void:
	if _rebind_action.is_empty():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.physical_keycode == KEY_ESCAPE:
			_rebind_action = ""
			open_settings()
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode != 0 and InputManager.remap_key(_rebind_action, key_event.physical_keycode):
			_finish_rebind(OS.get_keycode_string(key_event.physical_keycode))
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed and InputManager.remap_joy_button(_rebind_action, button_event.button_index):
			_finish_rebind("Pad Button %d" % button_event.button_index)
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) >= 0.75 and InputManager.remap_joy_axis(_rebind_action, motion_event.axis, signf(motion_event.axis_value)):
			_finish_rebind("Pad Axis %d" % motion_event.axis)

func _finish_rebind(description: String) -> void:
	var label := _rebind_label
	_rebind_action = ""
	_rebind_label = ""
	get_viewport().set_input_as_handled()
	show_status("%s → %s" % [label, description])
	open_settings()

func _add_binding_row(parent: VBoxContainer, action: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = action.replace("_", " ").capitalize()
	label.custom_minimum_size = Vector2(170, 24)
	row.add_child(label)
	var bindings := InputManager.binding_descriptions(action)
	var current := Label.new()
	current.text = ", ".join(bindings.slice(0, mini(2, bindings.size()))) if not bindings.is_empty() else "UNBOUND"
	current.custom_minimum_size = Vector2(190, 24)
	current.clip_text = true
	current.add_theme_font_size_override("font_size", 10)
	row.add_child(current)
	row.add_child(_make_button("REBIND", Callable(self, "_begin_rebind").bind(action), ACCENT, Vector2(82, 22)))
	parent.add_child(row)

func _add_setting_toggle(parent: VBoxContainer, label_text: String, key: String) -> void:
	var toggle := CheckButton.new()
	toggle.text = label_text
	toggle.button_pressed = bool(SettingsManager.get_value(key, false))
	toggle.toggled.connect(func(value: bool): SettingsManager.set_value(key, value))
	parent.add_child(toggle)

func _add_setting_slider(parent: VBoxContainer, label_text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 24)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = float(SettingsManager.get_value(key, min_value))
	slider.custom_minimum_size = Vector2(185, 24)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(55, 24)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = "%.2f" % slider.value
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float):
		value_label.text = "%.2f" % value
		SettingsManager.set_value(key, value)
	)
	parent.add_child(row)

func _add_section_label(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", ACCENT)
	label.add_theme_font_size_override("font_size", 11)
	parent.add_child(label)

func _on_setting_changed(key: String, _value) -> void:
	if key in ["large_text", "ui_scale"]:
		_apply_accessibility_visuals()

func _apply_accessibility_visuals() -> void:
	var large := bool(SettingsManager.get_value("large_text", false))
	for root_node in [menu_layer, builder_hud, race_hud, modal_layer]:
		if root_node != null:
			_apply_font_recursive(root_node, large)

func _apply_font_recursive(node: Node, large: bool) -> void:
	if node is Control:
		var control := node as Control
		if not control.has_meta("ptw_base_font_size"):
			control.set_meta("ptw_base_font_size", control.get_theme_font_size("font_size"))
		var base_size := int(control.get_meta("ptw_base_font_size", 12))
		control.add_theme_font_size_override("font_size", base_size + (2 if large else 0))
	for child in node.get_children():
		_apply_font_recursive(child, large)

func _update_vehicle_label() -> void:
	if current_vehicle_label == null:
		return
	var definition := VehicleCatalog.new().get_vehicle(GameState.current_vehicle_id)
	current_vehicle_label.text = "CURRENT RIDE\n%s • %s" % [str(definition.get("name", GameState.current_vehicle_id)), str(definition.get("category", "Arcade"))]

func _modal_panel(title_text: String, position_value: Vector2, size_value: Vector2) -> PanelContainer:
	_clear_modal()
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.58)
	modal_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 10))
	modal_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ACCENT)
	box.add_child(title)
	return panel

func _clear_modal() -> void:
	if modal_layer == null:
		return
	for child in modal_layer.get_children():
		child.queue_free()
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _make_button(text_value: String, callback: Callable, accent: Color, min_size: Vector2 = Vector2(210, 30)) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("ptw_base_font_size", 10)
	button.add_theme_font_size_override("font_size", 12 if bool(SettingsManager.get_value("large_text", false)) else 10)
	button.add_theme_color_override("font_color", TEXT)
	var normal := accent.darkened(0.55) if accent != PANEL_2 else PANEL_2
	button.add_theme_stylebox_override("normal", _panel_style(normal, 5))
	button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.30), 5))
	button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.15), 5))
	button.pressed.connect(callback)
	return button

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
