extends RefCounted
class_name RecordManager

const RECORD_PATH := "user://records.json"
var records: Dictionary = {"times": {}, "scores": {}}

func _init() -> void:
	load_records()

func load_records() -> void:
	records = {"times": {}, "scores": {}}
	if not FileAccess.file_exists(RECORD_PATH):
		return
	var file := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	if parsed.has("times") or parsed.has("scores"):
		records["times"] = parsed.get("times", {})
		records["scores"] = parsed.get("scores", {})
	else:
		records["times"] = parsed

func save_records() -> bool:
	var file := FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(records, "\t"))
	return true

func record_lap(track_id: String, vehicle_id: String, mode: String, lap_time: float) -> bool:
	if lap_time <= 0.0:
		return false
	var key := _key(track_id, vehicle_id, mode)
	var previous := float(records["times"].get(key, INF))
	if lap_time >= previous:
		return false
	records["times"][key] = lap_time
	save_records()
	return true

func record_score(track_id: String, vehicle_id: String, mode: String, score: float) -> bool:
	if score < 0.0:
		return false
	var key := _key(track_id, vehicle_id, mode)
	var previous := float(records["scores"].get(key, -INF))
	if score <= previous:
		return false
	records["scores"][key] = score
	save_records()
	return true

func best_lap(track_id: String, vehicle_id: String, mode: String = "time_trial") -> float:
	return float(records["times"].get(_key(track_id, vehicle_id, mode), INF))

func best_score(track_id: String, vehicle_id: String, mode: String = "drift") -> float:
	return float(records["scores"].get(_key(track_id, vehicle_id, mode), 0.0))

func records_for_track(track_id: String) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for key in records["times"]:
		var parts := str(key).split("|")
		if parts.size() == 3 and parts[0] == track_id:
			output.append({"track_id": parts[0], "vehicle_id": parts[1], "mode": parts[2], "value": float(records["times"][key]), "kind": "time"})
	for key in records["scores"]:
		var parts := str(key).split("|")
		if parts.size() == 3 and parts[0] == track_id:
			output.append({"track_id": parts[0], "vehicle_id": parts[1], "mode": parts[2], "value": float(records["scores"][key]), "kind": "score"})
	return output

func _key(track_id: String, vehicle_id: String, mode: String) -> String:
	return "%s|%s|%s" % [track_id, vehicle_id, mode]
