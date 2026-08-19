extends RefCounted
class_name GarageManager

const GARAGE_PATH := "user://garage.json"
const UPGRADE_GROUPS := ["engine", "transmission", "tires", "brakes", "suspension", "weight", "nitro"]
const TIER_NAMES := ["Stock", "Street", "Sport", "Race"]

var data: Dictionary = {
	"owned_vehicles": ["Hachiroku_Drifter"],
	"selected_colors": {"Hachiroku_Drifter": "default"},
	"upgrades": {},
	"tuning": {}
}

func _init() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(GARAGE_PATH):
		return
	var file := FileAccess.open(GARAGE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in data:
			if parsed.has(key):
				data[key] = parsed[key]

func save_data() -> bool:
	var file := FileAccess.open(GARAGE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true

func is_owned(vehicle_id: String) -> bool:
	return vehicle_id in data["owned_vehicles"]

func vehicle_price(vehicle_id: String) -> int:
	var definition := VehicleCatalog.new().get_vehicle(vehicle_id)
	var stats: Dictionary = definition.get("stats", {})
	var performance := 0.0
	for key in ["speed", "accel", "handling", "drift", "boost"]:
		performance += float(stats.get(key, 75))
	return 900 + roundi(performance * 7.0)

func purchase_vehicle(vehicle_id: String, available_credits: int) -> Dictionary:
	if is_owned(vehicle_id):
		return {"success": true, "cost": 0, "reason": "already_owned"}
	var price := vehicle_price(vehicle_id)
	if available_credits < price:
		return {"success": false, "cost": price, "reason": "insufficient_credits"}
	data["owned_vehicles"].append(vehicle_id)
	data["selected_colors"][vehicle_id] = "default"
	_ensure_vehicle(vehicle_id)
	save_data()
	return {"success": true, "cost": price, "reason": "purchased"}

func upgrade_level(vehicle_id: String, group: String) -> int:
	_ensure_vehicle(vehicle_id)
	return int(data["upgrades"][vehicle_id].get(group, 0))

func upgrade_cost(vehicle_id: String, group: String) -> int:
	if group not in UPGRADE_GROUPS:
		return 0
	var next_level := upgrade_level(vehicle_id, group) + 1
	if next_level > 3:
		return 0
	var weight := UPGRADE_GROUPS.find(group) + 1
	return 250 * next_level + weight * 65

func purchase_upgrade(vehicle_id: String, group: String, available_credits: int) -> Dictionary:
	if not is_owned(vehicle_id):
		return {"success": false, "cost": 0, "reason": "vehicle_not_owned"}
	if group not in UPGRADE_GROUPS:
		return {"success": false, "cost": 0, "reason": "invalid_group"}
	var current := upgrade_level(vehicle_id, group)
	if current >= 3:
		return {"success": false, "cost": 0, "reason": "max_tier"}
	var cost := upgrade_cost(vehicle_id, group)
	if available_credits < cost:
		return {"success": false, "cost": cost, "reason": "insufficient_credits"}
	data["upgrades"][vehicle_id][group] = current + 1
	save_data()
	return {"success": true, "cost": cost, "reason": "upgraded", "level": current + 1}

func tier_name(vehicle_id: String, group: String) -> String:
	return TIER_NAMES[clampi(upgrade_level(vehicle_id, group), 0, TIER_NAMES.size() - 1)]

func set_color(vehicle_id: String, color: String) -> bool:
	var definition := VehicleCatalog.new().get_vehicle(vehicle_id)
	if color not in definition.get("colors", ["default"]):
		return false
	data["selected_colors"][vehicle_id] = color
	save_data()
	return true

func selected_color(vehicle_id: String) -> String:
	return str(data["selected_colors"].get(vehicle_id, "default"))

func set_tuning(vehicle_id: String, key: String, value: float) -> void:
	_ensure_vehicle(vehicle_id)
	var allowed := {
		"steering": Vector2(0.75, 1.25),
		"grip_bias": Vector2(0.85, 1.15),
		"drift_assist": Vector2(0.0, 1.0),
		"brake_bias": Vector2(0.8, 1.2),
		"final_drive": Vector2(0.85, 1.15)
	}
	if not allowed.has(key):
		return
	var range: Vector2 = allowed[key]
	data["tuning"][vehicle_id][key] = clampf(value, range.x, range.y)
	save_data()

func tuning(vehicle_id: String) -> Dictionary:
	_ensure_vehicle(vehicle_id)
	return data["tuning"][vehicle_id].duplicate(true)

func effective_definition(vehicle_id: String) -> Dictionary:
	var definition := VehicleCatalog.new().get_vehicle(vehicle_id).duplicate(true)
	var stats: Dictionary = definition.get("stats", {}).duplicate(true)
	_ensure_vehicle(vehicle_id)
	var levels: Dictionary = data["upgrades"][vehicle_id]
	_apply_stat(stats, "speed", float(levels.get("engine", 0)) * 2.0)
	_apply_stat(stats, "accel", float(levels.get("engine", 0)) * 2.8)
	_apply_stat(stats, "speed", float(levels.get("transmission", 0)) * 1.6)
	_apply_stat(stats, "accel", float(levels.get("transmission", 0)) * 1.8)
	_apply_stat(stats, "handling", float(levels.get("tires", 0)) * 2.8)
	_apply_stat(stats, "handling", float(levels.get("brakes", 0)) * 1.8)
	_apply_stat(stats, "handling", float(levels.get("suspension", 0)) * 2.2)
	_apply_stat(stats, "drift", float(levels.get("suspension", 0)) * 1.6)
	_apply_stat(stats, "accel", float(levels.get("weight", 0)) * 1.4)
	_apply_stat(stats, "handling", float(levels.get("weight", 0)) * 1.1)
	stats["weight"] = clampf(float(stats.get("weight", 70)) - float(levels.get("weight", 0)) * 4.0, 20.0, 100.0)
	_apply_stat(stats, "boost", float(levels.get("nitro", 0)) * 4.0)
	definition["stats"] = stats
	definition["selected_color"] = selected_color(vehicle_id)
	definition["tuning"] = tuning(vehicle_id)
	return definition

func _ensure_vehicle(vehicle_id: String) -> void:
	if not data["upgrades"].has(vehicle_id):
		var blank := {}
		for group in UPGRADE_GROUPS:
			blank[group] = 0
		data["upgrades"][vehicle_id] = blank
	if not data["tuning"].has(vehicle_id):
		data["tuning"][vehicle_id] = {
			"steering": 1.0,
			"grip_bias": 1.0,
			"drift_assist": 0.5,
			"brake_bias": 1.0,
			"final_drive": 1.0
		}

func _apply_stat(stats: Dictionary, key: String, amount: float) -> void:
	stats[key] = clampf(float(stats.get(key, 75.0)) + amount, 0.0, 100.0)
