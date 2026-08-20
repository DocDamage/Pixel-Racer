extends RefCounted
class_name TeamCatalog

const CATALOG_PATH := "res://data/teams/team_definitions.json"

var _loaded := false
var _teams: Dictionary = {}

func has_team(team_id: String) -> bool:
	_ensure_loaded()
	return _teams.has(team_id)

func team(team_id: String) -> Dictionary:
	_ensure_loaded()
	return Dictionary(_teams.get(team_id, {})).duplicate(true)

func ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	for team_id in _teams:
		result.append(str(team_id))
	result.sort()
	return result

func count() -> int:
	_ensure_loaded()
	return _teams.size()

func available_for_tier(tier: int) -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for team_id in _teams:
		var definition: Dictionary = _teams[team_id]
		if int(definition.get("career_unlock_tier", 1)) <= tier:
			result.append(definition.duplicate(true))
	return result

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Team catalog missing: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	for raw_team in (parsed as Dictionary).get("teams", []):
		if raw_team is Dictionary:
			var definition: Dictionary = (raw_team as Dictionary).duplicate(true)
			var team_id := str(definition.get("team_id", ""))
			if not team_id.is_empty():
				_teams[team_id] = definition
