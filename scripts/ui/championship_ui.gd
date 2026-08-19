extends CanvasLayer
class_name ChampionshipUI

const PANEL := Color("#151922")
const PANEL_2 := Color("#222735")
const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const GOLD := Color("#ffd166")
const GOOD := Color("#61e294")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#a9b2c5")

var game = null
var launch_button: Button
var shade: ColorRect
var panel: PanelContainer
var list_box: VBoxContainer
var header: Label

func _ready() -> void:
	if game == null:
		setup(get_parent())

func setup(game_root) -> void:
	if launch_button != null:
		return
	game = game_root
	layer = 25
	_build()

func _process(_delta: float) -> void:
	if game == null or launch_button == null:
		return
	var menu_mode := GameState.current_mode == GameState.MODE_MENU
	launch_button.visible = menu_mode and not game.career.available_championships().is_empty() and not panel.visible
	if not menu_mode and panel.visible:
		_close()

func _build() -> void:
	launch_button = _button("CHAMPIONSHIPS", _open, MAGENTA, Vector2(255, 28))
	launch_button.position = Vector2(340, 320)
	add_child(launch_button)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.66)
	shade.visible = false
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(70, 24)
	panel.size = Vector2(500, 312)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 10))
	panel.visible = false
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 5)
	panel.add_child(outer)
	header = Label.new()
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", ACCENT)
	outer.add_child(header)
	var description := Label.new()
	description.text = "Win tier championships to earn credits, reputation, sponsor streak, and venue progression."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 10)
	description.add_theme_color_override("font_color", MUTED)
	outer.add_child(description)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 205)
	outer.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(450, 0)
	list_box.add_theme_constant_override("separation", 4)
	scroll.add_child(list_box)
	outer.add_child(_button("CLOSE", _close, MUTED, Vector2(470, 26)))

func _open() -> void:
	if game == null:
		return
	_refresh()
	shade.visible = true
	panel.visible = true
	launch_button.visible = false

func _close() -> void:
	shade.visible = false
	panel.visible = false
	launch_button.visible = GameState.current_mode == GameState.MODE_MENU

func _refresh() -> void:
	for child in list_box.get_children():
		child.queue_free()
	var tier := int(game.career.profile.get("tier", 1))
	var tier_info: Dictionary = game.career.tier_info(tier)
	var completed: Array = game.career.profile.get("completed_championships", [])
	header.text = "TIER %d • %s" % [tier, str(tier_info.get("name", "Career"))]
	for championship in game.career.available_championships():
		var id := str(championship.get("id", ""))
		var done := id in completed
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel_style(PANEL_2, 6))
		list_box.add_child(row)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 5)
		row.add_child(content)
		var info := Label.new()
		info.custom_minimum_size = Vector2(330, 48)
		info.text = "%s%s\nTier %d • %d cr • %d rep" % ["✓ " if done else "", str(championship.get("name", id)), int(championship.get("tier", 1)), int(championship.get("reward", 0)), int(championship.get("rep", 0))]
		info.add_theme_font_size_override("font_size", 11)
		info.add_theme_color_override("font_color", GOOD if done else TEXT)
		content.add_child(info)
		var action_text := "REPLAY" if done else "RACE"
		content.add_child(_button(action_text, func():
			_close()
			game.start_championship(id)
		, ACCENT if done else MAGENTA, Vector2(90, 30)))

func _button(text_value: String, callback: Callable, accent: Color, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(accent.darkened(0.55), 5))
	button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.28), 5))
	button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.12), 5))
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
