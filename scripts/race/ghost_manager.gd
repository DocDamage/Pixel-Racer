extends RefCounted
class_name GhostManager

const GHOST_ROOT := "user://ghosts"
const GHOST_SCHEMA := 1

func best_ghost_path(track_id: String, vehicle_id: String, mode: String = "time_trial") -> String:
	return GHOST_ROOT.path_join(_safe(track_id)).path_join("%s_%s.json" % [_safe(vehicle_id), _safe(mode)])

func best_ghost_exists(track_id: String, vehicle_id: String, mode: String = "time_trial") -> bool:
	return FileAccess.file_exists(best_ghost_path(track_id, vehicle_id, mode))

func best_ghost_time(track_id: String, vehicle_id: String, mode: String = "time_trial") -> float:
	var payload := load_payload(best_ghost_path(track_id, vehicle_id, mode))
	if payload.is_empty():
		return INF
	var metadata = payload.get("metadata", {})
	if not metadata is Dictionary:
		return INF
	return float(metadata.get("lap_time", INF))

func save_if_best(track_id: String, vehicle_id: String, mode: String, lap_time: float, samples: Array[Dictionary], extra_metadata: Dictionary = {}) -> bool:
	if track_id.is_empty() or vehicle_id.is_empty() or lap_time <= 0.0 or samples.size() < 2:
		return false
	var path := best_ghost_path(track_id, vehicle_id, mode)
	var previous := best_ghost_time(track_id, vehicle_id, mode)
	if lap_time >= previous:
		return false
	var dir_path := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path)) != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		return false
	var metadata := {
		"track_id": track_id,
		"vehicle_id": vehicle_id,
		"mode": mode,
		"lap_time": lap_time,
		"saved_at": Time.get_datetime_string_from_system(true),
		"sample_count": samples.size()
	}
	metadata.merge(extra_metadata, true)
	var payload := {
		"schema_version": GHOST_SCHEMA,
		"metadata": metadata,
		"samples": samples.duplicate(true)
	}
	return _atomic_write_json(path, payload)

func load_recorder(track_id: String, vehicle_id: String, mode: String = "time_trial") -> GhostRecorder:
	var recorder := GhostRecorder.new()
	if not recorder.load_from(best_ghost_path(track_id, vehicle_id, mode)):
		return null
	return recorder

func load_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	if int(parsed.get("schema_version", -1)) != GHOST_SCHEMA:
		return {}
	if not parsed.get("samples", []) is Array:
		return {}
	return parsed

func delete_best(track_id: String, vehicle_id: String, mode: String = "time_trial") -> bool:
	var path := best_ghost_path(track_id, vehicle_id, mode)
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

func records_for_track(track_id: String) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var track_dir := GHOST_ROOT.path_join(_safe(track_id))
	var dir := DirAccess.open(track_dir)
	if dir == null:
		return output
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var payload := load_payload(track_dir.path_join(file_name))
			var metadata = payload.get("metadata", {})
			if metadata is Dictionary:
				output.append(Dictionary(metadata).duplicate(true))
		file_name = dir.get_next()
	dir.list_dir_end()
	output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("lap_time", INF)) < float(b.get("lap_time", INF))
	)
	return output

func _atomic_write_json(path: String, payload: Dictionary) -> bool:
	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK

func _safe(value: String) -> String:
	var output := value.strip_edges().to_lower().replace(" ", "_")
	for char in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", "."]:
		output = output.replace(char, "")
	return output if not output.is_empty() else "unknown"
