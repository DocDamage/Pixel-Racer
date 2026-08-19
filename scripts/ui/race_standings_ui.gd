extends CanvasLayer
class_name RaceStandingsUI

const PANEL := Color("#10141dcc")
const ACCENT := Color("#37d9ff")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#9da9bc")

var game = null
var panel: PanelContainer
var position_label: Label
var list_label: Label
var catalog := VehicleCatalog.new()

func _ready() -> void:
	if game == null:
		setup(get_parent())

func setup(game_root) -> void:
	if panel != null:
		return
	game = game_root
	layer = 24
	_build()

func _process(_delta: float) -> void:
	if game == null or panel == null:
		return
	var should_show := GameState.current_mode == GameState.MODE_RACE and game.player != null and is_instance_valid(game.player)
	panel.visible = should_show
	if not should_show:
		return
	var state: Dictionary = game.race_state()
	var racers := int(state.get("racers", 1))
	var position := int(state.get("position", 1))
	position_label.text = "P%d / %d" % [position, racers]
	position_label.add_theme_color_override("font_color", ACCENT if position <= 3 else TEXT)
	var lines: Array[String] = []
	for item in state.get("leaderboard", []):
		if not item is Dictionary:
			continue
		var id := str(item.get("vehicle_id", ""))
		var definition := catalog.get_vehicle(id)
		var display_name := str(definition.get("name", id))
		if display_name.length() > 18:
			display_name = display_name.left(18)
		var prefix := ">" if id == game.player.vehicle_id and int(item.get("position", 0)) == position else " "
		var suffix := " FIN" if bool(item.get("finished", false)) else " L%d" % maxi(0, int(item.get("lap", 1)))
		lines.append("%s%d  %s%s" % [prefix, int(item.get("position", 0)), display_name, suffix])
	list_label.text = "\n".join(lines)

func _build() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(438, 10)
	panel.size = Vector2(192, 116)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	position_label = Label.new()
	position_label.add_theme_font_size_override("font_size", 18)
	position_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(position_label)
	list_label = Label.new()
	list_label.add_theme_font_size_override("font_size", 9)
	list_label.add_theme_color_override("font_color", MUTED)
	box.add_child(list_label)
	panel.visible = false
