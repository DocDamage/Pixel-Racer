extends Node2D

const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const PANEL := Color("#151922")
const PANEL_2 := Color("#222735")
const TEXT := Color("#f4f7fb")

var track: TrackData
var renderer: TrackRenderer
var runtime: TrackRuntime
var builder: BuilderController
var camera: Camera2D
var player: ArcadeVehicle
var race_controller: RaceController
var ai_nodes: Array[Node] = []
var ai_vehicles: Array[ArcadeVehicle] = []
var ghost := GhostRecorder.new()
var validator := TrackValidator.new()
var career := CareerManager.new()

var canvas: CanvasLayer
var menu_layer: Control
var builder_hud: Control
var race_hud: Control
var modal_layer: Control
var track_name_label: Label
var tool_label: Label
var validation_label: Label
var status_label: Label
var speed_label: Label
var lap_label: Label
var timer_label: Label
var nitro_bar: ProgressBar
var countdown_label: Label
var saved_camera_position := Vector2.ZERO
var saved_camera_zoom := Vector2.ONE
var _validation_result: Dictionary = {}
var _selected_vehicle_label: Label

func _ready() -> void:
	career.load_profile()
	_create_world()
	_create_ui()
	var generator := ProceduralTrackGenerator.new()
	_set_track(generator.create_demo_track(), true)
	_show_menu()

func _process(delta: float) -> void:
	if player != null and is_instance_valid(player):
		if GameState.current_mode in [GameState.MODE_TEST, GameState.MODE_RACE]:
			var lookahead := player.velocity * 0.18
			camera.position = camera.position.lerp(player.global_position + lookahead, clampf(delta * 6.0, 0.0, 1.0))
			_update_race_hud()
			ghost.capture(delta, player)
	if GameState.current_mode == GameState.MODE_TEST:
		if Input.is_action_just_pressed("toggle_test") or Input.is_action_just_pressed("ui_cancel"):
			_return_to_builder()
	elif GameState.current_mode == GameState.MODE_RACE and Input.is_action_just_pressed("ui_cancel"):
		_show_menu()

func _create_world() -> void:
	renderer = TrackRenderer.new()
	renderer.name = "TrackRenderer"
	add_child(renderer)
	runtime = TrackRuntime.new()
	runtime.name = "TrackRuntime"
	add_child(runtime)
	camera = Camera2D.new()
	camera.name = "CameraRig"
	camera.position = Vector2(640, 500)
	camera.zoom = Vector2.ONE * 0.7
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	builder = BuilderController.new()
	builder.name = "BuilderController"
	add_child(builder)
	builder.track_replaced.connect(_on_track_replaced)
	builder.track_changed.connect(_on_track_changed)
	builder.test_requested.connect(_enter_test_drive)
	builder.save_requested.connect(_save_current_track)
	builder.load_requested.connect(_open_track_library)
	builder.tool_changed.connect(_on_tool_changed)

func _create_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(menu_layer)
	builder_hud = Control.new()
	builder_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(builder_hud)
	race_hud = Control.new()
	race_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(race_hud)
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(modal_layer)
	_build_main_menu()
	_build_builder_hud()
	_build_race_hud()

func _build_main_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("#0b0e14")
	menu_layer.add_child(backdrop)
	var title := Label.new()
	title.text = "PIXEL TRACK WORKS"
	title.position = Vector2(48, 32)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ACCENT)
	menu_layer.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BUILD IT  •  TEST IT  •  RACE IT"
	subtitle.position = Vector2(50, 72)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#a9b2c5"))
	menu_layer.add_child(subtitle)
	var box := VBoxContainer.new()
	box.position = Vector2(48, 112)
	box.size = Vector2(230, 210)
	box.add_theme_constant_override("separation", 8)
	menu_layer.add_child(box)
	box.add_child(_make_button("CONTINUE CAREER", _open_career, MAGENTA))
	box.add_child(_make_button("FREE BUILD", _enter_builder, ACCENT))
	box.add_child(_make_button("QUICK RACE", _start_quick_race, ACCENT))
	box.add_child(_make_button("RANDOM TRACK", _random_track, ACCENT))
	box.add_child(_make_button("TRACK LIBRARY", _open_track_library, Color("#ffd166")))
	box.add_child(_make_button("GARAGE", _open_garage, Color("#ffd166")))
	box.add_child(_make_button("SETTINGS", _open_settings, Color("#aab2c7")))
	var feature := Label.new()
	feature.text = "SMART ROAD CONNECTIONS\nINSTANT TEST DRIVE\nSURFACE PHYSICS\nDRIFT + NITRO\nAI CIRCUIT RACING"
	feature.position = Vector2(360, 124)
	feature.size = Vector2(230, 150)
	feature.add_theme_font_size_override("font_size", 13)
	feature.add_theme_color_override("font_color", TEXT)
	feature.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_layer.add_child(feature)
	_selected_vehicle_label = Label.new()
	_selected_vehicle_label.position = Vector2(360, 276)
	_selected_vehicle_label.size = Vector2(240, 40)
	_selected_vehicle_label.add_theme_color_override("font_color", ACCENT)
	menu_layer.add_child(_selected_vehicle_label)
	_update_selected_vehicle_text()

func _build_builder_hud() -> void:
	var top := PanelContainer.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 40)
	top.add_theme_stylebox_override("panel", _panel_style(PANEL, 0))
	builder_hud.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	top.add_child(row)
	track_name_label = Label.new()
	track_name_label.custom_minimum_size = Vector2(130, 34)
	track_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	track_name_label.add_theme_color_override("font_color", TEXT)
	row.add_child(track_name_label)
	validation_label = Label.new()
	validation_label.custom_minimum_size = Vector2(115, 34)
	validation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(validation_label)
	row.add_child(_make_button("UNDO", builder.undo, Color("#aab2c7"), Vector2(52, 30)))
	row.add_child(_make_button("REDO", builder.redo, Color("#aab2c7"), Vector2(52, 30)))
	row.add_child(_make_button("SAVE", _save_current_track, Color("#ffd166"), Vector2(52, 30)))
	row.add_child(_make_button("LOAD", _open_track_library, Color("#ffd166"), Vector2(52, 30)))
	row.add_child(_make_button("TEST", _enter_test_drive, MAGENTA, Vector2(70, 30)))
	row.add_child(_make_button("MENU", _show_menu, Color("#aab2c7"), Vector2(58, 30)))
	var tools := PanelContainer.new()
	tools.position = Vector2(0, 48)
	tools.size = Vector2(108, 282)
	tools.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.08, 0.11, 0.94), 6))
	builder_hud.add_child(tools)
	var tool_box := VBoxContainer.new()
	tool_box.add_theme_constant_override("separation", 3)
	tools.add_child(tool_box)
	tool_label = Label.new()
	tool_label.text = "BUILD TOOLS"
	tool_label.add_theme_color_override("font_color", ACCENT)
	tool_box.add_child(tool_label)
	var tool_names := {
		"road": "1  ROAD",
		"sand": "2  SAND",
		"dirt": "3  DIRT",
		"grass": "4  GRASS",
		"start_finish": "5  START",
		"checkpoint": "6  CHECK",
		"barrier": "7  BARRIER",
		"erase": "8  ERASE"
	}
	for tool in BuilderController.TOOLS:
		tool_box.add_child(_make_button(tool_names[tool], func(): builder.set_tool(tool), PANEL_2, Vector2(96, 25)))
	status_label = Label.new()
	status_label.position = Vector2(118, 330)
	status_label.size = Vector2(510, 24)
	status_label.add_theme_color_override("font_color", Color("#d7ddeb"))
	status_label.add_theme_font_size_override("font_size", 11)
	builder_hud.add_child(status_label)

func _build_race_hud() -> void:
	var top := PanelContainer.new()
	top.position = Vector2(10, 10)
	top.size = Vector2(230, 70)
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.08, 0.86), 8))
	race_hud.add_child(top)
	var box := VBoxContainer.new()
	top.add_child(box)
	lap_label = Label.new()
	lap_label.add_theme_color_override("font_color", TEXT)
	box.add_child(lap_label)
	timer_label = Label.new()
	timer_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(timer_label)
	speed_label = Label.new()
	speed_label.position = Vector2(500, 300)
	speed_label.size = Vector2(130, 30)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_label.add_theme_font_size_override("font_size", 20)
	speed_label.add_theme_color_override("font_color", TEXT)
	race_hud.add_child(speed_label)
	nitro_bar = ProgressBar.new()
	nitro_bar.position = Vector2(475, 334)
	nitro_bar.size = Vector2(155, 12)
	nitro_bar.min_value = 0
	nitro_bar.max_value = 100
	nitro_bar.show_percentage = false
	race_hud.add_child(nitro_bar)
	countdown_label = Label.new()
	countdown_label.position = Vector2(250, 120)
	countdown_label.size = Vector2(140, 110)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 52)
	countdown_label.add_theme_color_override("font_color", MAGENTA)
	race_hud.add_child(countdown_label)
	var return_hint := Label.new()
	return_hint.position = Vector2(12, 330)
	return_hint.text = "F5 / ESC: RETURN"
	return_hint.add_theme_font_size_override("font_size", 10)
	return_hint.add_theme_color_override("font_color", Color("#b5bed0"))
	race_hud.add_child(return_hint)

func _set_track(new_track: TrackData, reset_history: bool) -> void:
	track = new_track
	GameState.current_track = track
	renderer.set_track(track)
	runtime.set_track(track)
	if reset_history or builder.track == null:
		builder.setup(track, renderer, runtime, camera)
	else:
		builder.track = track
	_validate_track()
	_update_builder_text()

func _enter_builder() -> void:
	_clear_modal()
	_cleanup_race()
	menu_layer.visible = false
	builder_hud.visible = true
	race_hud.visible = false
	GameState.set_mode(GameState.MODE_BUILDER)
	builder.set_enabled(true)
	camera.position = _builder_focus_position()
	camera.zoom = Vector2.ONE * 0.58
	_update_builder_text()

func _enter_test_drive() -> void:
	if GameState.current_mode != GameState.MODE_BUILDER or track == null or track.road_tiles.is_empty():
		return
	saved_camera_position = camera.position
	saved_camera_zoom = camera.zoom
	builder.set_enabled(false)
	builder_hud.visible = false
	race_hud.visible = true
	GameState.set_mode(GameState.MODE_TEST)
	_spawn_player(true)
	ghost.start()
	if bool(_validation_result.get("raceable", false)):
		_create_race_controller(3, false)
		if race_controller != null:
			race_controller.start_race()
	countdown_label.text = "TEST"
	get_tree().create_timer(0.8).timeout.connect(func():
		if countdown_label != null and GameState.current_mode == GameState.MODE_TEST:
			countdown_label.text = ""
	)

func _return_to_builder() -> void:
	ghost.stop()
	_cleanup_race()
	GameState.set_mode(GameState.MODE_BUILDER)
	builder.set_enabled(true)
	builder_hud.visible = true
	race_hud.visible = false
	camera.position = saved_camera_position
	camera.zoom = saved_camera_zoom
	_validate_track()

func _start_quick_race() -> void:
	_clear_modal()
	_cleanup_race()
	var demo := ProceduralTrackGenerator.new().create_demo_track()
	_set_track(demo, true)
	menu_layer.visible = false
	builder_hud.visible = false
	race_hud.visible = true
	builder.set_enabled(false)
	GameState.set_mode(GameState.MODE_RACE)
	_spawn_player(true)
	player.input_enabled = false
	_spawn_ai(3)
	_create_race_controller(3, true)
	ghost.start()

func _random_track() -> void:
	var generated := ProceduralTrackGenerator.new().generate()
	_set_track(generated, true)
	_enter_builder()
	status_label.text = "Generated valid loop. Edit anything, then TEST instantly."

func _spawn_player(player_controlled: bool) -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = ArcadeVehicle.new()
	player.name = "PlayerVehicle"
	add_child(player)
	var spawn := _start_position()
	player.global_position = spawn["position"]
	player.heading = float(spawn["heading"])
	player.setup(track, GameState.current_vehicle_id, player_controlled)
	player.nitro_changed.connect(func(value: float):
		if nitro_bar != null: nitro_bar.value = value
	)
	camera.position = player.global_position
	camera.zoom = Vector2.ONE * 1.0

func _spawn_ai(count: int) -> void:
	var spawn := _start_position()
	var forward := Vector2.UP.rotated(float(spawn["heading"]))
	var right := forward.rotated(PI * 0.5)
	var catalog := VehicleCatalog.new()
	var ids := catalog.ids()
	for i in range(count):
		var vehicle := ArcadeVehicle.new()
		vehicle.name = "AIVehicle_%d" % i
		add_child(vehicle)
		var id := ids[(i + 3) % ids.size()] if not ids.is_empty() else "Hachiroku_Drifter"
		var spawn_position: Vector2 = spawn["position"]
		vehicle.global_position = spawn_position - forward * (48.0 + i * 42.0) + right * (-28.0 if i % 2 == 0 else 28.0)
		vehicle.heading = float(spawn["heading"])
		vehicle.setup(track, id, false)
		var ai := AIDriver.new()
		ai.name = "AIDriver_%d" % i
		add_child(ai)
		ai.setup(vehicle, track, {
			"aggression": 0.45 + i * 0.15,
			"consistency": 0.72 + i * 0.08,
			"mistake_rate": 0.08 - i * 0.015
		})
		ai.enabled = false
		ai_vehicles.append(vehicle)
		ai_nodes.append(ai)

func _create_race_controller(laps: int, countdown: bool) -> void:
	if race_controller != null and is_instance_valid(race_controller):
		race_controller.queue_free()
	race_controller = RaceController.new()
	race_controller.name = "RaceController"
	add_child(race_controller)
	race_controller.setup(track, player, laps)
	race_controller.countdown_changed.connect(_on_countdown_changed)
	race_controller.lap_completed.connect(_on_lap_completed)
	race_controller.race_finished.connect(_on_race_finished)
	if countdown:
		race_controller.start_countdown()

func _on_countdown_changed(value: int) -> void:
	countdown_label.text = "GO!" if value == 0 else str(value)
	if value == 0:
		if player != null:
			player.input_enabled = true
		for ai in ai_nodes:
			if ai is AIDriver:
				ai.enabled = true
		get_tree().create_timer(0.8).timeout.connect(func():
			if countdown_label != null: countdown_label.text = ""
		)

func _on_lap_completed(lap_number: int, lap_time: float) -> void:
	countdown_label.text = "LAP %d\n%.2f" % [lap_number, lap_time]
	get_tree().create_timer(1.2).timeout.connect(func():
		if countdown_label != null and not (race_controller != null and race_controller.finished): countdown_label.text = ""
	)

func _on_race_finished(total_time: float) -> void:
	ghost.stop()
	countdown_label.text = "FINISH\n%.2f" % total_time

func _cleanup_race() -> void:
	if race_controller != null and is_instance_valid(race_controller):
		race_controller.stop()
		race_controller.queue_free()
		race_controller = null
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	for ai in ai_nodes:
		if is_instance_valid(ai): ai.queue_free()
	for vehicle in ai_vehicles:
		if is_instance_valid(vehicle): vehicle.queue_free()
	ai_nodes.clear()
	ai_vehicles.clear()

func _show_menu() -> void:
	_clear_modal()
	_cleanup_race()
	builder.set_enabled(false)
	GameState.set_mode(GameState.MODE_MENU)
	menu_layer.visible = true
	builder_hud.visible = false
	race_hud.visible = false
	camera.position = _builder_focus_position()
	camera.zoom = Vector2.ONE * 0.55
	_update_selected_vehicle_text()

func _save_current_track() -> void:
	if track == null:
		return
	if SaveManager.save_track(track):
		track.dirty = false
		status_label.text = "Saved %s" % track.name
	else:
		status_label.text = "Save failed. Check the Godot user data directory."

func _open_track_library() -> void:
	_clear_modal()
	var panel := _modal_panel("TRACK LIBRARY", Vector2(120, 45), Vector2(400, 275))
	var box := panel.get_node("Content") as VBoxContainer
	var tracks := SaveManager.list_tracks()
	if tracks.is_empty():
		var empty := Label.new()
		empty.text = "No saved tracks yet. Save from Free Build with F2 or SAVE."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
	else:
		for entry in tracks:
			var id := str(entry["track_id"])
			var button := _make_button(str(entry["name"]), Callable(self, "_load_track_from_library").bind(id), ACCENT, Vector2(360, 30))
			box.add_child(button)
	box.add_child(_make_button("CLOSE", _clear_modal, Color("#aab2c7"), Vector2(360, 28)))

func _open_garage() -> void:
	_clear_modal()
	var panel := _modal_panel("GARAGE", Vector2(95, 35), Vector2(450, 300))
	var box := panel.get_node("Content") as VBoxContainer
	var info := Label.new()
	info.text = "Select a vehicle. Existing asset-pack stats are loaded from js/config/vehicleData.js."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var catalog := VehicleCatalog.new()
	var grid := GridContainer.new()
	grid.columns = 3
	box.add_child(grid)
	for id in catalog.ids():
		var definition := catalog.get_vehicle(id)
		var short_name := str(definition.get("name", id))
		var button := _make_button(short_name, Callable(self, "_select_vehicle").bind(id), PANEL_2, Vector2(130, 28))
		grid.add_child(button)
	box.add_child(_make_button("CLOSE", _clear_modal, Color("#aab2c7"), Vector2(400, 28)))

func _open_settings() -> void:
	_clear_modal()
	var panel := _modal_panel("SETTINGS + ACCESSIBILITY", Vector2(145, 55), Vector2(350, 245))
	var box := panel.get_node("Content") as VBoxContainer
	for pair in [
		["Traction Assist", "traction_assist"],
		["Auto Accelerate", "auto_accelerate"],
		["Recovery Assist", "recovery_assist"],
		["Large Text", "large_text"],
		["Colorblind Indicators", "colorblind_indicators"]
	]:
		var toggle := CheckButton.new()
		toggle.text = str(pair[0])
		toggle.button_pressed = bool(SettingsManager.get_value(str(pair[1]), false))
		var key := str(pair[1])
		toggle.toggled.connect(Callable(self, "_set_boolean_setting").bind(key))
		box.add_child(toggle)
	box.add_child(_make_button("RESET DEFAULTS", SettingsManager.reset_defaults, Color("#ffd166"), Vector2(300, 28)))
	box.add_child(_make_button("CLOSE", _clear_modal, Color("#aab2c7"), Vector2(300, 28)))

func _load_track_from_library(track_id: String) -> void:
	var loaded = SaveManager.load_track(track_id)
	if loaded != null:
		_set_track(loaded, true)
		_enter_builder()
		_clear_modal()

func _select_vehicle(vehicle_id: String) -> void:
	GameState.set_vehicle(vehicle_id)
	_update_selected_vehicle_text()
	_clear_modal()

func _set_boolean_setting(value: bool, key: String) -> void:
	SettingsManager.set_value(key, value)

func _open_career() -> void:
	_clear_modal()
	var panel := _modal_panel("DOC'S MOTOR PARK • CAREER", Vector2(105, 40), Vector2(430, 295))
	var box := panel.get_node("Content") as VBoxContainer
	var profile := Label.new()
	profile.text = "Credits: %d    Reputation: %d    Tier: %d" % [int(career.profile["credits"]), int(career.profile["reputation"]), int(career.profile["tier"])]
	profile.add_theme_color_override("font_color", MAGENTA)
	box.add_child(profile)
	for contract in career.contracts:
		var evaluation := career.evaluate_contract(contract, track)
		var requirements := ""
		for requirement in evaluation["requirements"]:
			requirements += "%s %s   " % ["✓" if bool(requirement["met"]) else "•", str(requirement["label"])]
		var label := Label.new()
		label.text = "%s  +%d cr / +%d rep\n%s" % [str(contract["name"]), int(contract["reward"]), int(contract["rep"]), requirements]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	box.add_child(_make_button("BUILD FOR CONTRACTS", _enter_builder, MAGENTA, Vector2(380, 30)))
	box.add_child(_make_button("CLOSE", _clear_modal, Color("#aab2c7"), Vector2(380, 28)))

func _modal_panel(title_text: String, position_value: Vector2, size_value: Vector2) -> PanelContainer:
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.56)
	modal_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "Modal"
	panel.position = position_value
	panel.size = size_value
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 10))
	modal_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ACCENT)
	box.add_child(title)
	return panel

func _clear_modal() -> void:
	for child in modal_layer.get_children():
		child.queue_free()
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _validate_track() -> void:
	if track == null:
		return
	_validation_result = validator.validate(track)
	var issues: Array[Dictionary] = []
	for issue in _validation_result.get("errors", []): issues.append(issue)
	for issue in _validation_result.get("warnings", []): issues.append(issue)
	renderer.set_validation_issues(issues)
	_update_builder_text()

func _on_track_changed() -> void:
	_validate_track()
	_update_builder_text()

func _on_track_replaced(new_track) -> void:
	track = new_track
	GameState.current_track = track
	builder.track = track
	renderer.set_track(track)
	runtime.set_track(track)
	_validate_track()

func _on_tool_changed(tool_name: String) -> void:
	tool_label.text = "TOOL: %s" % tool_name.to_upper()

func _update_builder_text() -> void:
	if track_name_label == null or track == null:
		return
	track_name_label.text = "%s%s" % [track.name, " *" if track.dirty else ""]
	var errors: Array = _validation_result.get("errors", [])
	var warnings: Array = _validation_result.get("warnings", [])
	if errors.is_empty():
		validation_label.text = "✓ VALID" if warnings.is_empty() else "! %d WARNING" % warnings.size()
		validation_label.add_theme_color_override("font_color", Color("#61e294") if warnings.is_empty() else Color("#ffd166"))
	else:
		validation_label.text = "✕ %d ERROR" % errors.size()
		validation_label.add_theme_color_override("font_color", Color("#ff6b6b"))
	if status_label != null:
		if not errors.is_empty():
			status_label.text = "%s @ %s" % [str(errors[0]["message"]), str(errors[0]["cell"])]
		else:
			status_label.text = "LMB place • RMB erase • wheel zoom • arrows pan • Q/E tools • X rotate barrier • F5 test"

func _update_race_hud() -> void:
	if player == null:
		return
	speed_label.text = "%03d" % roundi(player.velocity.length() * 0.42)
	nitro_bar.value = player.nitro
	if race_controller != null:
		lap_label.text = "LAP %d/%d   CP %d/%d" % [race_controller.current_lap, race_controller.laps_required, race_controller.current_checkpoint, track.get_checkpoints_sorted().size()]
		timer_label.text = "%.2f   BEST %s" % [race_controller.current_lap_time(), "--" if is_inf(race_controller.best_lap) else "%.2f" % race_controller.best_lap]
	else:
		lap_label.text = "TEST DRIVE   %s" % player.current_surface.to_upper()
		timer_label.text = "DRIFT %.0f" % player.drift_score

func _start_position() -> Dictionary:
	var start := track.get_start_object()
	var cell := Vector2i.ZERO
	if not start.is_empty():
		cell = Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	else:
		cell = track.nearest_road_cell(track.world_to_cell(camera.position))
	if cell.x < 0:
		cell = track.road_cells()[0] if not track.road_cells().is_empty() else Vector2i(1, 1)
	var heading := 0.0
	var graph := TrackGraph.new()
	graph.build(track)
	var order := graph.find_loop_order(cell)
	if order.size() > 1:
		var direction := track.cell_to_world(order[1]) - track.cell_to_world(order[0])
		heading = Vector2.UP.angle_to(direction.normalized())
	return {"position": track.cell_to_world(cell), "heading": heading}

func _builder_focus_position() -> Vector2:
	if track == null:
		return Vector2(640, 500)
	var start := track.get_start_object()
	if not start.is_empty():
		return track.cell_to_world(Vector2i(int(start.get("x", 0)), int(start.get("y", 0))))
	var roads := track.road_cells()
	return track.cell_to_world(roads[0]) if not roads.is_empty() else Vector2(640, 500)

func _update_selected_vehicle_text() -> void:
	if _selected_vehicle_label == null:
		return
	var definition := VehicleCatalog.new().get_vehicle(GameState.current_vehicle_id)
	_selected_vehicle_label.text = "CURRENT RIDE\n%s  •  %s" % [str(definition.get("name", GameState.current_vehicle_id)), str(definition.get("category", "Arcade"))]

func _make_button(text_value: String, callback: Callable, accent, min_size: Vector2 = Vector2(210, 32)) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", TEXT)
	var color: Color = accent if typeof(accent) == TYPE_COLOR else PANEL_2
	var normal_color := color.darkened(0.55) if color != PANEL_2 else PANEL_2
	button.add_theme_stylebox_override("normal", _panel_style(normal_color, 5))
	button.add_theme_stylebox_override("hover", _panel_style(color.darkened(0.30), 5))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.15), 5))
	button.pressed.connect(callback)
	return button

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
