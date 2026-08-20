extends CanvasLayer
class_name ProceduralTrackUI

const PANEL_COLOR := Color("#151922")
const PANEL_2 := Color("#222735")
const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const GOLD := Color("#ffd166")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#a9b2c5")

var game: Node = null
var root_control: Control
var panel: PanelContainer
var style_select: OptionButton
var size_spin: SpinBox
var complexity_slider: HSlider
var width_select: OptionButton
var scenery_slider: HSlider
var seed_spin: SpinBox
var summary_label: Label
var _suppress_auto_open := false

func _ready() -> void:
	layer = 24
	game = get_parent()
	_build()
	root_control.visible = false
	if not GameState.mode_changed.is_connected(_on_mode_changed):
		GameState.mode_changed.connect(_on_mode_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func open_from_track(track: TrackData = null) -> void:
	if track != null:
		_load_from_track(track)
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	style_select.grab_focus()
	_refresh_summary()

func close() -> void:
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_open() -> bool:
	return root_control.visible

func _on_mode_changed(mode: String) -> void:
	if mode != GameState.MODE_BUILDER or _suppress_auto_open:
		return
	var track: TrackData = GameState.current_track as TrackData
	if track == null or not track.dirty:
		return
	if not track.metadata.has("generator_seed"):
		return
	call_deferred("open_from_track", track)

func _generate() -> void:
	if game == null or not game.has_method("set_track"):
		return
	var style: String = str(style_select.get_item_metadata(style_select.selected))
	var map_size: int = roundi(size_spin.value)
	var complexity: float = complexity_slider.value
	var road_width: String = str(width_select.get_item_metadata(width_select.selected))
	var density: float = scenery_slider.value
	var seed_value: int = roundi(seed_spin.value)
	var track: TrackData = ProceduralTrackGenerator.new().generate(seed_value, map_size, style, complexity, road_width, density)
	_suppress_auto_open = true
	game.call("set_track", track, true)
	_suppress_auto_open = false
	_load_from_track(track)
	_refresh_summary()
	style_select.grab_focus()

func _randomize_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	seed_spin.value = rng.randi_range(1, 2147483000)
	_generate()

func _load_from_track(track: TrackData) -> void:
	if track == null:
		return
	var style: String = str(track.metadata.get("generator_style", "circuit"))
	_select_metadata(style_select, style)
	size_spin.value = track.width
	complexity_slider.value = float(track.metadata.get("generator_complexity", 0.55))
	_select_metadata(width_select, str(track.metadata.get("generator_road_width", "standard")))
	scenery_slider.value = float(track.metadata.get("generator_scenery_density", 0.45))
	seed_spin.value = int(track.metadata.get("generator_seed", 0))

func _refresh_summary(_value: float = 0.0) -> void:
	if summary_label == null:
		return
	var style: String = str(style_select.get_item_metadata(style_select.selected))
	var road_width: String = str(width_select.get_item_metadata(width_select.selected))
	summary_label.text = "%s • %dx%d • %s roads • complexity %d%% • scenery %d%%" % [
		style.capitalize(),
		roundi(size_spin.value),
		roundi(size_spin.value),
		road_width.capitalize(),
		roundi(complexity_slider.value * 100.0),
		roundi(scenery_slider.value * 100.0)
	]

func _build() -> void:
	root_control = Control.new()
	root_control.name = "ProceduralTrackRoot"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.68)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(90, 24)
	panel.size = Vector2(460, 312)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_COLOR, 10))
	root_control.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = "RANDOM TRACK LAB"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", ACCENT)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Generate → Edit → Test → Save"
	subtitle.add_theme_color_override("font_color", MUTED)
	box.add_child(subtitle)
	style_select = OptionButton.new()
	for style in ["circuit", "mixed", "rally", "oval", "technical"]:
		style_select.add_item(style.to_upper())
		style_select.set_item_metadata(style_select.item_count - 1, style)
	style_select.item_selected.connect(func(_index: int): _refresh_summary())
	box.add_child(_labeled_row("Style", style_select))
	size_spin = SpinBox.new()
	size_spin.focus_mode = Control.FOCUS_ALL
	size_spin.min_value = 24
	size_spin.max_value = 96
	size_spin.step = 4
	size_spin.value = 48
	size_spin.value_changed.connect(_refresh_summary)
	box.add_child(_labeled_row("Map size", size_spin))
	complexity_slider = HSlider.new()
	complexity_slider.min_value = 0.0
	complexity_slider.max_value = 1.0
	complexity_slider.step = 0.05
	complexity_slider.value = 0.55
	complexity_slider.value_changed.connect(_refresh_summary)
	box.add_child(_labeled_row("Complexity", complexity_slider))
	width_select = OptionButton.new()
	for width in TrackData.ROAD_WIDTHS:
		var width_id: String = str(width)
		width_select.add_item(width_id.replace("_", " ").to_upper())
		width_select.set_item_metadata(width_select.item_count - 1, width_id)
	width_select.select(1)
	width_select.item_selected.connect(func(_index: int): _refresh_summary())
	box.add_child(_labeled_row("Road width", width_select))
	scenery_slider = HSlider.new()
	scenery_slider.min_value = 0.0
	scenery_slider.max_value = 1.0
	scenery_slider.step = 0.05
	scenery_slider.value = 0.45
	scenery_slider.value_changed.connect(_refresh_summary)
	box.add_child(_labeled_row("Scenery", scenery_slider))
	seed_spin = SpinBox.new()
	seed_spin.focus_mode = Control.FOCUS_ALL
	seed_spin.min_value = 1
	seed_spin.max_value = 2147483000
	seed_spin.step = 1
	seed_spin.value = 44001
	box.add_child(_labeled_row("Seed", seed_spin))
	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.custom_minimum_size = Vector2(420, 28)
	summary_label.add_theme_font_size_override("font_size", 10)
	summary_label.add_theme_color_override("font_color", GOLD)
	box.add_child(summary_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	box.add_child(actions)
	actions.add_child(_button("GENERATE", _generate, MAGENTA, Vector2(150, 30)))
	actions.add_child(_button("NEW SEED", _randomize_seed, GOLD, Vector2(120, 30)))
	actions.add_child(_button("USE TRACK", close, ACCENT, Vector2(120, 30)))
	_refresh_summary()

func _labeled_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 26)
	row.add_child(label)
	control.custom_minimum_size = Vector2(285, 26)
	row.add_child(control)
	return row

func _button(text_value: String, callback: Callable, color: Color, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(color.darkened(0.55), 5))
	button.add_theme_stylebox_override("hover", _panel_style(color.darkened(0.30), 5))
	button.add_theme_stylebox_override("focus", _panel_style(color.darkened(0.20), 5))
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
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _select_metadata(select: OptionButton, value: String) -> void:
	for index in range(select.item_count):
		if str(select.get_item_metadata(index)) == value:
			select.select(index)
			return
