extends CanvasLayer
class_name PauseController

const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const GOLD := Color("#ffd166")
const PANEL := Color("#151922")
const PANEL_2 := Color("#222735")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#a9b2c5")

var game_root: Node = null
var overlay: Control
var hint_panel: PanelContainer
var title_label: Label
var mode_label: Label
var resume_button: Button
var restart_button: Button
var builder_button: Button
var _resume_queued := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 96
	game_root = get_parent()
	_build_hint()
	_build_overlay()
	if not GameState.mode_changed.is_connected(_on_mode_changed):
		GameState.mode_changed.connect(_on_mode_changed)
	_sync_mode_visibility()

func _input(event: InputEvent) -> void:
	if not _is_driving_mode() or not event.is_action_pressed("pause"):
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	get_viewport().set_input_as_handled()
	if get_tree().paused:
		resume_game(true)
	else:
		pause_game()

func pause_game() -> bool:
	if get_tree().paused or not _is_driving_mode():
		return false
	_configure_for_mode()
	overlay.visible = true
	hint_panel.visible = false
	get_tree().paused = true
	resume_button.call_deferred("grab_focus")
	return true

func resume_game(defer_until_idle: bool = false) -> bool:
	if not get_tree().paused and not overlay.visible:
		return false
	overlay.visible = false
	if defer_until_idle:
		if not _resume_queued:
			_resume_queued = true
			call_deferred("_finish_deferred_resume")
	else:
		_finish_resume()
	return true

func is_pause_visible() -> bool:
	return overlay != null and overlay.visible

func _finish_deferred_resume() -> void:
	_finish_resume()

func _finish_resume() -> void:
	_resume_queued = false
	get_tree().paused = false
	_sync_mode_visibility()

func _restart_event() -> void:
	resume_game(false)
	if game_root != null and game_root.has_method("restart_current_event"):
		game_root.call("restart_current_event")

func _return_to_builder() -> void:
	resume_game(false)
	if game_root != null and game_root.has_method("return_to_builder"):
		game_root.call("return_to_builder")

func _return_to_menu() -> void:
	resume_game(false)
	if game_root != null and game_root.has_method("show_menu"):
		game_root.call("show_menu")

func _on_mode_changed(_mode: String) -> void:
	if not _is_driving_mode():
		overlay.visible = false
		if get_tree().paused:
			_finish_resume()
	_sync_mode_visibility()

func _is_driving_mode() -> bool:
	return GameState.current_mode in [GameState.MODE_TEST, GameState.MODE_RACE]

func _configure_for_mode() -> void:
	var is_race := GameState.current_mode == GameState.MODE_RACE
	title_label.text = "RACE PAUSED" if is_race else "TEST DRIVE PAUSED"
	mode_label.text = "The race world is frozen." if is_race else "Review the run or return to editing."
	restart_button.visible = is_race
	builder_button.visible = not is_race

func _sync_mode_visibility() -> void:
	if hint_panel == null or overlay == null:
		return
	var driving := _is_driving_mode()
	if not driving:
		overlay.visible = false
	hint_panel.visible = driving and not get_tree().paused and not overlay.visible

func _build_hint() -> void:
	hint_panel = PanelContainer.new()
	hint_panel.name = "PauseHint"
	hint_panel.position = Vector2(8, 326)
	hint_panel.size = Vector2(284, 28)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.04, 0.07, 0.96), 5))
	add_child(hint_panel)
	var hint := Label.new()
	hint.text = "ESC / START: PAUSE  •  R / Y: RESET"
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	hint_panel.add_child(hint)

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.025, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(165, 55)
	panel.size = Vector2(310, 250)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 10))
	overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(title_label)

	mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 11)
	mode_label.add_theme_color_override("font_color", MUTED)
	box.add_child(mode_label)

	resume_button = _make_button("RESUME", func(): resume_game(false), MAGENTA)
	box.add_child(resume_button)

	restart_button = _make_button("RESTART EVENT", _restart_event, ACCENT)
	box.add_child(restart_button)

	builder_button = _make_button("RETURN TO BUILDER", _return_to_builder, ACCENT)
	box.add_child(builder_button)

	box.add_child(_make_button("BACK TO MAIN MENU", _return_to_menu, GOLD))

	var hint := Label.new()
	hint.text = "Press ESC / START again to resume."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", MUTED)
	box.add_child(hint)

	overlay.visible = false

func _make_button(text_value: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(278, 32)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(accent.darkened(0.55), 5))
	button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.30), 5))
	button.add_theme_stylebox_override("focus", _panel_style(accent.darkened(0.24), 5))
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
