extends RefCounted
class_name GarageManager

signal vehicle_purchased(vehicle_id: String, cost: int)
signal upgrade_purchased(vehicle_id: String, group: String, level: int, cost: int)

const GARAGE_PATH := "user://garage.json"
const SAVE_PATH := GARAGE_PATH
const DEFAULT_VEHICLE_ID := "Hachiroku_Drifter"
const UPGRADE_GROUPS := ["engine", "transmission", "tires", "brakes", "suspension", "weight", "nitro"]
const TIER_NAMES := ["Stock", "Street", "Sport", "Race"]

var data: Dictionary = {}
var _save_path := GARAGE_PATH
var _store := AtomicJsonStore.new()

func _init(save_path: String = GARAGE_PATH) -> void:
	_save_path = GARAGE_PATH if save_path.is_empty() else save_path
	data = _default_data()
	load_data()

func storage_path() -> String:
	return _save_path

func load_data() -> void:
	data = _default_data()
	var result: Dictionary = _store.load_result(_save_path)
	var loaded_value: Variant = result.get("data", {})
	if loaded_value is Dictionary:
		var loaded: Dictionary = loaded_value
		_merge_loaded_data(loaded)
	_normalize_data()
	if not str(result.get("recovered_from", "")).is_empty():
		save_data()

func save_data() -> bool:
	var payload: Dictionary = data.duplicate(true)
	return _store.save(_save_path, payload)

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
	if vehicle_id.is_empty():
		return {"success": false, "cost": 0, "reason": "invalid_vehicle"}
	if is_owned(vehicle_id):
		return {"success": true, "cost": 0, "reason": "already_owned"}
	var price := vehicle_price(vehicle_id)
	if available_credits < price:
		return {"success": false, "cost": price, "reason": "insufficient_credits"}
	var previous: Dictionary = data.duplicate(true)
	data["owned_vehicles"].append(vehicle_id)
	data["selected_colors"][vehicle_id] = "default"
	_ensure_vehicle(vehicle_id)
	if not save_data():
		data = previous
		return {"success": false, "cost": price, "reason": "save_failed"}
	vehicle_purchased.emit(vehicle_id, price)
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
	var previous: Dictionary = data.duplicate(true)
	var current := upgrade_level(vehicle_id, group)
	if current >= 3:
		data = previous
		return {"success": false, "cost": 0, "reason": "max_tier"}
	var next_level := current + 1
	var weight := UPGRADE_GROUPS.find(group) + 1
	var cost := 250 * next_level + weight * 65
	if available_credits < cost:
		data = previous
		return {"success": false, "cost": cost, "reason": "insufficient_credits"}
	data["upgrades"][vehicle_id][group] = next_level
	if not save_data():
		data = previous
		return {"success": false, "cost": cost, "reason": "save_failed"}
	upgrade_purchased.emit(vehicle_id, group, next_level, cost)
	return {"success": true, "cost": cost, "reason": "upgraded", "level": next_level}

func tier_name(vehicle_id: String, group: String) -> String:
	return TIER_NAMES[clampi(upgrade_level(vehicle_id, group), 0, TIER_NAMES.size() - 1)]

func set_color(vehicle_id: String, color: String) -> bool:
	var definition := VehicleCatalog.new().get_vehicle(vehicle_id)
	if color not in definition.get("colors", ["default"]):
		return false
	var previous: Dictionary = data.duplicate(true)
	data["selected_colors"][vehicle_id] = color
	if not save_data():
		data = previous
		return false
	return true

func selected_color(vehicle_id: String) -> String:
	return str(data["selected_colors"].get(vehicle_id, "default"))

func set_tuning(vehicle_id: String, key: String, value: float) -> void:
	var allowed := {
		"steering": Vector2(0.75, 1.25),
		"grip_bias": Vector2(0.85, 1.15),
		"drift_assist": Vector2(0.0, 1.0),
		"brake_bias": Vector2(0.8, 1.2),
		"final_drive": Vector2(0.85, 1.15)
	}
	if not allowed.has(key):
		return
	var previous: Dictionary = data.duplicate(true)
	_ensure_vehicle(vehicle_id)
	var range: Vector2 = allowed[key]
	data["tuning"][vehicle_id][key] = clampf(value, range.x, range.y)
	if not save_data():
		data = previous

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

func _default_data() -> Dictionary:
	return {
		"owned_vehicles": [DEFAULT_VEHICLE_ID],
		"selected_colors": {DEFAULT_VEHICLE_ID: "default"},
		"upgrades": {},
		"tuning": {}
	}

func _merge_loaded_data(loaded: Dictionary) -> void:
	for key in data:
		if not loaded.has(key):
			continue
		var value: Variant = loaded[key]
		data[key] = value.duplicate(true) if value is Array or value is Dictionary else value

func _normalize_data() -> void:
	if not data.get("owned_vehicles", []) is Array:
		data["owned_vehicles"] = [DEFAULT_VEHICLE_ID]
	if not data.get("selected_colors", {}) is Dictionary:
		data["selected_colors"] = {DEFAULT_VEHICLE_ID: "default"}
	if not data.get("upgrades", {}) is Dictionary:
		data["upgrades"] = {}
	if not data.get("tuning", {}) is Dictionary:
		data["tuning"] = {}

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
