extends RaceStandingsUI
class_name CatalogRaceStandingsUI

var team_catalog := TeamCatalog.new()

func _process(_delta: float) -> void:
	if game == null or panel == null:
		return
	var should_show := GameState.current_mode == GameState.MODE_RACE and game.player != null and is_instance_valid(game.player)
	panel.visible = should_show
	if not should_show:
		return
	if game.race_progress == null or game.race_progress.path.is_empty():
		super._process(_delta)
		return
	var order: Array[Dictionary] = game.race_progress.standings()
	var player_position := maxi(1, game.race_progress.position_of(game.player))
	position_label.text = "P%d / %d" % [player_position, order.size()]
	position_label.add_theme_color_override("font_color", ACCENT if player_position <= 3 else TEXT)
	var lines: Array[String] = []
	for index in range(mini(5, order.size())):
		var standing: Dictionary = order[index]
		var racer: ArcadeVehicle = standing.get("vehicle") as ArcadeVehicle
		if racer == null:
			continue
		var definition := catalog.get_vehicle(racer.vehicle_id)
		var display_name := str(definition.get("name", racer.vehicle_id))
		if display_name.length() > 12:
			display_name = display_name.left(12)
		var is_player := racer == game.player
		var team_tag := "YOU" if is_player else _team_tag(racer)
		var prefix := ">" if is_player else " "
		var suffix := " FIN" if bool(standing.get("finished", false)) else " L%d" % maxi(0, int(standing.get("lap", 0)) + 1)
		lines.append("%s%d [%s] %s%s" % [prefix, index + 1, team_tag, display_name, suffix])
	list_label.text = "\n".join(lines)

func _team_tag(vehicle: ArcadeVehicle) -> String:
	var team_id := str(vehicle.get_meta("team_id", ""))
	if team_id.is_empty():
		return "RIVAL"
	var definition := team_catalog.team(team_id)
	var display_name := str(definition.get("display_name", team_id)).to_upper()
	return display_name.left(5) if display_name.length() > 5 else display_name
