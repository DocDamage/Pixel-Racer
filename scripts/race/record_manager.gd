extends RefCounted
class_name RecordManager

const RECORD_PATH := "user://records.json"
var records: Dictionary = {}

func _init() -> void:
	load_records()

func load_records() -> void:
	records.clear()
	if not FileAccess.file_exists(RECORD_PATH):
		return
	var file := FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		records = parsed

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
	var previous := float(records.get(key, INF))
	if lap_time >= previous:
		return false
	records[key] = lap_time
	save_records()
	return true

func best_lap(track_id: String, vehicle_id: String, mode: String = "time_trial") -> float:
	return float(records.get(_key(track_id, vehicle_id, mode), INF))

func records_for_track(track_id: String) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for key in records:
		var parts := str(key).split("|")
		if parts.size() == 3 and parts[0] == track_id:
			output.append({"track_id": parts[0], "vehicle_id": parts[1], "mode": parts[2], "time": float(records[key])})
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))
	return output

func _key(track_id: String, vehicle_id: String, mode: String) -> String:
	return "%s|%s|%s" % [track_id, vehicle_id, mode]
