extends RefCounted
class_name VehicleCatalog

const SOURCE_PATH := "res://js/config/vehicleData.js"

var vehicles: Dictionary = {}

func _init() -> void:
	_load_from_existing_catalog()

func ids() -> Array[String]:
	var result: Array[String] = []
	for id in vehicles:
		result.append(str(id))
	result.sort()
	return result

func get_vehicle(id: String) -> Dictionary:
	if vehicles.has(id):
		return vehicles[id]
	if vehicles.has("Hachiroku_Drifter"):
		return vehicles["Hachiroku_Drifter"]
	return _fallback_vehicle(id)

func sprite_path(id: String, color: String = "default") -> String:
	var definition := get_vehicle(id)
	var folder := str(definition.get("folder", "Cars/Hachiroku_Drifter"))
	var suffix := "" if color == "default" else "_%s" % color
	return "res://%s/%s%s.png" % [folder, str(definition.get("id", id)), suffix]

func _load_from_existing_catalog() -> void:
	if not FileAccess.file_exists(SOURCE_PATH):
		vehicles["Hachiroku_Drifter"] = _fallback_vehicle("Hachiroku_Drifter")
		return
	var file := FileAccess.open(SOURCE_PATH, FileAccess.READ)
	if file == null:
		return
	var lines := file.get_as_text().split("\n")
	var block: Array[String] = []
	var current_id := ""
	for raw_line in lines:
		var line := str(raw_line)
		if current_id.is_empty():
			var stripped := line.strip_edges()
			if stripped.ends_with(": {") and not stripped.begins_with("//"):
				var candidate := stripped.trim_suffix(": {")
				if candidate.is_valid_identifier():
					current_id = candidate
					block = [line]
		else:
			block.append(line)
			if line.begins_with("    },") or line == "    }":
				vehicles[current_id] = _parse_block(current_id, block)
				current_id = ""
				block.clear()
	if vehicles.is_empty():
		vehicles["Hachiroku_Drifter"] = _fallback_vehicle("Hachiroku_Drifter")

func _parse_block(id: String, block: Array[String]) -> Dictionary:
	var output := _fallback_vehicle(id)
	for line in block:
		var stripped := line.strip_edges()
		if stripped.begins_with("name:"):
			output["name"] = _quoted_value(stripped)
		elif stripped.begins_with("category:"):
			output["category"] = _quoted_value(stripped)
		elif stripped.begins_with("type:"):
			output["type"] = _quoted_value(stripped)
		elif stripped.begins_with("folder:"):
			output["folder"] = _quoted_value(stripped)
		elif stripped.begins_with("gridWidth:"):
			output["grid_width"] = _number_after_colon(stripped)
		elif stripped.begins_with("gridHeight:"):
			output["grid_height"] = _number_after_colon(stripped)
		elif stripped.begins_with("stats:"):
			output["stats"] = _parse_stats(stripped)
		elif stripped.begins_with("colors:"):
			output["colors"] = _parse_colors(stripped)
	return output

func _parse_stats(line: String) -> Dictionary:
	var defaults := {"speed": 80, "accel": 80, "handling": 80, "drift": 80, "boost": 80, "weight": 70}
	var body := line.trim_prefix("stats:").strip_edges().trim_prefix("{").trim_suffix(",").trim_suffix("}")
	for pair in body.split(","):
		var parts := str(pair).split(":")
		if parts.size() == 2:
			var key := str(parts[0]).strip_edges()
			if defaults.has(key):
				defaults[key] = int(str(parts[1]).strip_edges())
	return defaults

func _parse_colors(line: String) -> Array[String]:
	var result: Array[String] = []
	var start := line.find("[")
	var end := line.rfind("]")
	if start < 0 or end <= start:
		return ["default"]
	for raw in line.substr(start + 1, end - start - 1).split(","):
		var value := str(raw).strip_edges().trim_prefix("'").trim_suffix("'").trim_prefix("\"").trim_suffix("\"")
		if not value.is_empty():
			result.append(value)
	return result

func _quoted_value(line: String) -> String:
	var colon := line.find(":")
	if colon < 0:
		return ""
	return line.substr(colon + 1).strip_edges().trim_suffix(",").trim_prefix("'").trim_suffix("'").trim_prefix("\"").trim_suffix("\"")

func _number_after_colon(line: String) -> int:
	var colon := line.find(":")
	return int(line.substr(colon + 1).strip_edges().trim_suffix(",")) if colon >= 0 else 46

func _fallback_vehicle(id: String) -> Dictionary:
	return {
		"id": id,
		"name": id.replace("_", " "),
		"category": "Arcade",
		"type": "car",
		"folder": "Cars/%s" % id,
		"grid_width": 46,
		"grid_height": 54,
		"stats": {"speed": 80, "accel": 80, "handling": 80, "drift": 80, "boost": 80, "weight": 70},
		"colors": ["default"]
	}
