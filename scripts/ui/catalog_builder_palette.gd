extends CanvasLayer
class_name CatalogBuilderPalette

const PANEL := Color("#151922")
const ACCENT := Color("#37d9ff")
const GOLD := Color("#ffd166")
const TEXT := Color("#f4f7fb")

var game = null
var controls: HBoxContainer
var asset_button: Button
var theme_button: Button

func setup(game_root) -> void:
	game = game_root
	layer = 22
	controls = HBoxContainer.new()
	controls.position = Vector2(470, 302)
	controls.add_theme_constant_override("separation", 4)
	add_child(controls)
	asset_button = _make_button("ASSET ›", ACCENT)
	asset_button.tooltip_text = "Cycle approved track props and hazards (C / gamepad Y)"
	asset_button.pressed.connect(_cycle_asset)
	controls.add_child(asset_button)
	theme_button = _make_button("THEME ›", GOLD)
	theme_button.tooltip_text = "Cycle track visual theme (V / gamepad Back)"
	theme_button.pressed.connect(_cycle_theme)
	controls.add_child(theme_button)
	_refresh_tooltips()
	controls.visible = false

func _process(_delta: float) -> void:
	if controls != null:
		controls.visible = GameState.current_mode == GameState.MODE_BUILDER

func _cycle_asset() -> void:
	if game == null or game.builder == null or not game.builder.has_method("cycle_catalog_asset"):
		return
	game.builder.cycle_catalog_asset(1)
	if game.ui != null:
		game.ui.refresh_builder()
		var definition: Dictionary = game.builder.selected_asset_definition()
		game.ui.show_status("Asset: %s" % str(definition.get("name", game.builder.selected_catalog_asset)))
	_refresh_tooltips()

func _cycle_theme() -> void:
	if game == null or not game.has_method("cycle_visual_theme"):
		return
	game.cycle_visual_theme(1)
	_refresh_tooltips()

func _refresh_tooltips() -> void:
	if theme_button != null and game != null and game.has_method("current_visual_theme_name"):
		theme_button.tooltip_text = "Current: %s • click to cycle (V / gamepad Back)" % game.current_visual_theme_name()
	if asset_button != null and game != null and game.builder != null and game.builder.has_method("selected_asset_definition"):
		var definition: Dictionary = game.builder.selected_asset_definition()
		asset_button.tooltip_text = "Cycle approved track props and hazards (C / gamepad Y)" if definition.is_empty() else "Current: %s • click to cycle" % str(definition.get("name", "Asset"))

func _make_button(text_value: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(76, 24)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _style(PANEL, 5))
	button.add_theme_stylebox_override("hover", _style(accent.darkened(0.45), 5))
	button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.25), 5))
	button.add_theme_stylebox_override("focus", _style(accent.darkened(0.35), 5))
	return button

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.16)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
