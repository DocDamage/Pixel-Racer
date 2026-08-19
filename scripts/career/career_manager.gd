extends RefCounted
class_name CareerManager

const PROFILE_PATH := "user://career.json"

var profile := {
	"credits": 1500,
	"reputation": 0,
	"tier": 1,
	"owned_vehicles": ["Hachiroku_Drifter"],
	"unlocked_surfaces": ["asphalt", "grass", "sand"],
	"completed_contracts": []
}

var contracts := [
	{"id": "first_loop", "name": "Local Club Request", "reward": 750, "rep": 100, "min_corners": 4, "max_tiles": 150},
	{"id": "technical", "name": "Technical Challenge", "reward": 1000, "rep": 140, "min_corners": 6, "max_tiles": 120},
	{"id": "long_course", "name": "Endurance Venue", "reward": 1600, "rep": 200, "min_length": 1800.0}
]

func load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in profile:
			if parsed.has(key):
				profile[key] = parsed[key]

func save_profile() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile, "\t"))

func evaluate_contract(contract: Dictionary, track: TrackData) -> Dictionary:
	var validator := TrackValidator.new()
	var result := validator.validate(track)
	var requirements: Array[Dictionary] = []
	requirements.append({"label": "Closed Circuit", "met": bool(result["raceable"])})
	if contract.has("min_corners"):
		requirements.append({"label": "%d+ Corners" % int(contract["min_corners"]), "met": int(track.metadata.get("corners", 0)) >= int(contract["min_corners"])})
	if contract.has("max_tiles"):
		requirements.append({"label": "Under %d Road Tiles" % int(contract["max_tiles"]), "met": track.road_tiles.size() <= int(contract["max_tiles"])})
	if contract.has("min_length"):
		requirements.append({"label": "Length %.0f+" % float(contract["min_length"]), "met": float(track.metadata.get("length", 0.0)) >= float(contract["min_length"])})
	var complete := true
	for requirement in requirements:
		if not bool(requirement["met"]):
			complete = false
	return {"complete": complete, "requirements": requirements}

func claim_contract(contract_id: String, track: TrackData) -> bool:
	if contract_id in profile["completed_contracts"]:
		return false
	for contract in contracts:
		if str(contract["id"]) == contract_id:
			var evaluation := evaluate_contract(contract, track)
			if not bool(evaluation["complete"]):
				return false
			profile["credits"] = int(profile["credits"]) + int(contract.get("reward", 0))
			profile["reputation"] = int(profile["reputation"]) + int(contract.get("rep", 0))
			profile["completed_contracts"].append(contract_id)
			_update_tier()
			save_profile()
			return true
	return false

func _update_tier() -> void:
	var rep := int(profile["reputation"])
	profile["tier"] = clampi(1 + rep / 500, 1, 7)
