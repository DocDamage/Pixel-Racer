extends RefCounted
class_name CareerManager

const PROFILE_PATH := "user://career.json"
const TIERS := {
	1: {"name": "Backyard Racer", "min_rep": 0, "construction": ["asphalt", "grass", "sand", "barrier"], "classes": ["Drift", "Sports"]},
	2: {"name": "Club Circuit", "min_rep": 350, "construction": ["curbs", "checkpoints", "tire_walls"], "classes": ["Muscle"]},
	3: {"name": "Street Racer", "min_rep": 900, "construction": ["night_lighting", "urban_props", "drift_zones"], "classes": ["Exotic"]},
	4: {"name": "Rally Park", "min_rep": 1600, "construction": ["dirt", "gravel", "rally_props"], "classes": ["Rally"]},
	5: {"name": "Professional Circuit", "min_rep": 2600, "construction": ["pit_lane", "grandstands", "sponsor_boards"], "classes": ["Formula"]},
	6: {"name": "Extreme Racing", "min_rep": 3900, "construction": ["hazards", "wide_track", "extreme_events"], "classes": ["Utility", "Bike"]},
	7: {"name": "Track Architect", "min_rep": 5500, "construction": ["all_builder_tools", "large_maps", "multi_route"], "classes": ["Novelty"]}
}

var profile: Dictionary = {
	"credits": 1500,
	"reputation": 0,
	"tier": 1,
	"venue_level": 1,
	"owned_vehicles": ["Hachiroku_Drifter"],
	"unlocked_surfaces": ["asphalt", "grass", "sand"],
	"unlocked_construction": ["asphalt", "grass", "sand", "barrier"],
	"unlocked_vehicle_classes": ["Drift", "Sports"],
	"completed_contracts": [],
	"completed_championships": [],
	"sponsor_streak": 0
}

var contracts := [
	{"id": "first_loop", "tier": 1, "name": "Local Club Request", "reward": 750, "rep": 100, "min_corners": 4, "max_tiles": 150},
	{"id": "compact_technical", "tier": 1, "name": "Compact Technical", "reward": 850, "rep": 120, "min_corners": 6, "max_tiles": 130},
	{"id": "club_showcase", "tier": 2, "name": "Club Showcase", "reward": 1200, "rep": 170, "min_corners": 8, "min_length": 1400.0},
	{"id": "speedway", "tier": 2, "name": "Sponsor Speedway", "reward": 1350, "rep": 190, "min_length": 1800.0, "max_corner_ratio": 0.16},
	{"id": "street_technical", "tier": 3, "name": "Street Technical", "reward": 1650, "rep": 220, "min_corners": 10, "max_tiles": 175},
	{"id": "rally_school", "tier": 4, "name": "Rally School", "reward": 2100, "rep": 280, "min_offroad_percent": 25},
	{"id": "mixed_surface", "tier": 4, "name": "Mixed Surface Masters", "reward": 2350, "rep": 310, "min_offroad_percent": 35, "min_corners": 8},
	{"id": "endurance", "tier": 5, "name": "Endurance Venue", "reward": 3000, "rep": 390, "min_length": 2600.0},
	{"id": "pro_technical", "tier": 5, "name": "Professional Technical", "reward": 3300, "rep": 420, "min_corners": 14, "min_length": 2200.0},
	{"id": "architect", "tier": 7, "name": "Track Architect Commission", "reward": 6000, "rep": 700, "min_corners": 18, "min_length": 3600.0, "min_offroad_percent": 15}
]

var championships := [
	{"id": "backyard_cup", "tier": 1, "name": "Backyard Cup", "reward": 1500, "rep": 250},
	{"id": "club_championship", "tier": 2, "name": "Club Championship", "reward": 2500, "rep": 400},
	{"id": "street_series", "tier": 3, "name": "Street Series", "reward": 3500, "rep": 550},
	{"id": "rally_park_series", "tier": 4, "name": "Rally Park Series", "reward": 4500, "rep": 700},
	{"id": "pro_circuit_cup", "tier": 5, "name": "Pro Circuit Cup", "reward": 6500, "rep": 950},
	{"id": "extreme_cup", "tier": 6, "name": "Extreme Cup", "reward": 9000, "rep": 1200},
	{"id": "architect_finale", "tier": 7, "name": "Track Architect Finale", "reward": 15000, "rep": 1800}
]

func _init() -> void:
	load_profile()

func load_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for key in profile:
					if parsed.has(key):
						profile[key] = parsed[key]
	_update_tier_and_unlocks()

func save_profile() -> bool:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile, "\t"))
	return true

func tier_info(tier: int = -1) -> Dictionary:
	var resolved := int(profile.get("tier", 1)) if tier < 0 else tier
	return TIERS.get(clampi(resolved, 1, 7), TIERS[1]).duplicate(true)

func available_contracts() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for contract in contracts:
		if int(contract.get("tier", 1)) <= int(profile.get("tier", 1)):
			output.append(contract)
	return output

func available_championships() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for championship in championships:
		if int(championship.get("tier", 1)) <= int(profile.get("tier", 1)):
			output.append(championship)
	return output

func evaluate_contract(contract: Dictionary, track: TrackData) -> Dictionary:
	var validator := TrackValidator.new()
	var result := validator.validate(track)
	var rating := TrackRating.new().calculate(track)
	var requirements: Array[Dictionary] = []
	var required_tier := int(contract.get("tier", 1))
	requirements.append({"label": "Tier %d" % required_tier, "met": int(profile.get("tier", 1)) >= required_tier})
	requirements.append({"label": "Closed Circuit", "met": bool(result["raceable"])})
	if contract.has("min_corners"):
		requirements.append({"label": "%d+ Corners" % int(contract["min_corners"]), "met": int(rating.get("corners", 0)) >= int(contract["min_corners"])})
	if contract.has("max_tiles"):
		requirements.append({"label": "Under %d Road Tiles" % int(contract["max_tiles"]), "met": track.road_tiles.size() <= int(contract["max_tiles"])})
	if contract.has("min_length"):
		requirements.append({"label": "Length %.0f+" % float(contract["min_length"]), "met": float(rating.get("length", 0.0)) >= float(contract["min_length"])})
	if contract.has("min_offroad_percent"):
		requirements.append({"label": "%d%%+ Loose Surface" % int(contract["min_offroad_percent"]), "met": int(rating.get("offroad_percent", 0)) >= int(contract["min_offroad_percent"])})
	if contract.has("max_corner_ratio"):
		var ratio := float(rating.get("corners", 0)) / float(maxi(1, track.road_tiles.size()))
		requirements.append({"label": "High-Speed Layout", "met": ratio <= float(contract["max_corner_ratio"])})
	var complete := true
	for requirement in requirements:
		if not bool(requirement["met"]):
			complete = false
	return {"complete": complete, "requirements": requirements, "rating": rating}

func claim_contract(contract_id: String, track: TrackData) -> bool:
	if contract_id in profile["completed_contracts"]:
		return false
	for contract in contracts:
		if str(contract["id"]) != contract_id:
			continue
		var evaluation := evaluate_contract(contract, track)
		if not bool(evaluation["complete"]):
			return false
		profile["credits"] = int(profile["credits"]) + int(contract.get("reward", 0))
		profile["reputation"] = int(profile["reputation"]) + int(contract.get("rep", 0))
		profile["completed_contracts"].append(contract_id)
		profile["venue_level"] = maxi(int(profile.get("venue_level", 1)), int(contract.get("tier", 1)))
		_update_tier_and_unlocks()
		save_profile()
		return true
	return false

func complete_championship(championship_id: String, placement: int) -> bool:
	if placement != 1 or championship_id in profile["completed_championships"]:
		return false
	for championship in championships:
		if str(championship["id"]) != championship_id:
			continue
		if int(championship.get("tier", 1)) > int(profile.get("tier", 1)):
			return false
		profile["credits"] = int(profile["credits"]) + int(championship.get("reward", 0))
		profile["reputation"] = int(profile["reputation"]) + int(championship.get("rep", 0))
		profile["completed_championships"].append(championship_id)
		profile["sponsor_streak"] = int(profile.get("sponsor_streak", 0)) + 1
		_update_tier_and_unlocks()
		save_profile()
		return true
	return false

func spend_credits(amount: int) -> bool:
	if amount < 0 or int(profile.get("credits", 0)) < amount:
		return false
	profile["credits"] = int(profile["credits"]) - amount
	save_profile()
	return true

func grant_credits(amount: int) -> void:
	profile["credits"] = maxi(0, int(profile.get("credits", 0)) + amount)
	save_profile()

func _update_tier_and_unlocks() -> void:
	var rep := int(profile.get("reputation", 0))
	var tier := 1
	for candidate in range(1, 8):
		if rep >= int(TIERS[candidate]["min_rep"]):
			tier = candidate
	profile["tier"] = tier
	var construction: Array = []
	var classes: Array = []
	for candidate in range(1, tier + 1):
		for unlock in TIERS[candidate]["construction"]:
			if unlock not in construction:
				construction.append(unlock)
		for vehicle_class in TIERS[candidate]["classes"]:
			if vehicle_class not in classes:
				classes.append(vehicle_class)
	profile["unlocked_construction"] = construction
	profile["unlocked_vehicle_classes"] = classes
	var surfaces: Array = ["asphalt", "grass", "sand"]
	if tier >= 4:
		surfaces.append("dirt")
		surfaces.append("gravel")
	profile["unlocked_surfaces"] = surfaces
