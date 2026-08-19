extends Node

const TrackDataScript = preload("res://scripts/track/track_data.gd")
const TRACK_ROOT := "user://tracks"
const EXPORT_ROOT := "user://track_exports"

func _ready() -> void:
	_ensure_directory(TRACK_ROOT)
	_ensure_directory(EXPORT_ROOT)

func save_track(track) -> bool:
	if track == null:
		return false
	var track_dir := "%s/%s" % [TRACK_ROOT, track.track_id]
	_ensure_directory(track_dir)
	var final_path := "%s/track.json" % track_dir
	var temp_path := "%s.tmp" % final_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	track.metadata["updated_at"] = Time.get_datetime_string_from_system(true)
	if not track.metadata.has("created_at") or str(track.metadata["created_at"]).is_empty():
		track.metadata["created_at"] = track.metadata["updated_at"]
	file.store_string(JSON.stringify(track.to_dict(), "\t"))
	file.close()
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(final_path))
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(final_path)
	)
	return error == OK

func load_track(track_id: String):
	return load_track_path("%s/%s/track.json" % [TRACK_ROOT, track_id])

func load_track_path(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	var track = TrackDataScript.new()
	track.from_dict(parsed)
	return track

func list_tracks() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir := DirAccess.open(TRACK_ROOT)
	if dir == null:
		return results
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if dir.current_is_dir() and not name.begins_with("."):
			var track = load_track(name)
			if track != null:
				results.append({
					"track_id": track.track_id,
					"name": track.name,
					"metadata": track.metadata.duplicate(true)
				})
		name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0
	)
	return results

func export_track(track) -> String:
	if track == null:
		return ""
	_ensure_directory(EXPORT_ROOT)
	var safe_name := _safe_filename(track.name)
	var path := "%s/%s_%s.json" % [EXPORT_ROOT, safe_name, track.track_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(track.to_dict(), "\t"))
	file.close()
	return path

func import_track(path: String):
	var track = load_track_path(path)
	if track == null:
		return null
	if not track.track_id.is_empty() and load_track(track.track_id) != null:
		track.track_id = _new_id()
	track.metadata["imported_at"] = Time.get_datetime_string_from_system(true)
	if save_track(track):
		return track
	return null

func _ensure_directory(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		DirAccess.make_dir_recursive_absolute(absolute)

func _safe_filename(value: String) -> String:
	var output := value.strip_edges().to_lower().replace(" ", "_")
	for char in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(char, "")
	return output if not output.is_empty() else "track"

func _new_id() -> String:
	return "%s-%s" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]
