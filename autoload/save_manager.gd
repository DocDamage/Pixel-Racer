extends Node

const TrackDataScript = preload("res://scripts/track/track_data.gd")
const TRACK_ROOT := "user://tracks"
const EXPORT_ROOT := "user://track_exports"
const BACKUP_SUFFIX := ".bak"
const TEMP_SUFFIX := ".tmp"

func _ready() -> void:
	_ensure_directory(TRACK_ROOT)
	_ensure_directory(EXPORT_ROOT)

func save_track(track) -> bool:
	if track == null:
		return false
	var track_dir := "%s/%s" % [TRACK_ROOT, track.track_id]
	_ensure_directory(track_dir)
	var final_path := "%s/track.json" % track_dir
	var temp_path := "%s%s" % [final_path, TEMP_SUFFIX]
	var backup_path := "%s%s" % [final_path, BACKUP_SUFFIX]
	track.metadata["updated_at"] = Time.get_datetime_string_from_system(true)
	if not track.metadata.has("created_at") or str(track.metadata["created_at"]).is_empty():
		track.metadata["created_at"] = track.metadata["updated_at"]
	var payload: String = JSON.stringify(track.to_dict(), "\t")
	if not _write_text(temp_path, payload):
		return false
	if _parse_track_path(temp_path) == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	if FileAccess.file_exists(final_path):
		if not _replace_backup(final_path, backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return false
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(final_path)) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return false
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(final_path))
	if error == OK:
		track.dirty = false
		return true
	_restore_backup_if_needed(final_path, backup_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	return false

func load_track(track_id: String):
	return load_track_path("%s/%s/track.json" % [TRACK_ROOT, track_id])

func load_track_path(path: String):
	var track = _parse_track_path(path)
	if track != null:
		return track
	if not path.ends_with("/track.json"):
		return null
	var temp_path := "%s%s" % [path, TEMP_SUFFIX]
	var backup_path := "%s%s" % [path, BACKUP_SUFFIX]
	track = _parse_track_path(temp_path)
	if track != null:
		track.metadata["recovered_from"] = "temporary_save"
		track.metadata["recovered_at"] = Time.get_datetime_string_from_system(true)
		track.dirty = true
		return track
	track = _parse_track_path(backup_path)
	if track != null:
		track.metadata["recovered_from"] = "backup"
		track.metadata["recovered_at"] = Time.get_datetime_string_from_system(true)
		track.dirty = true
		return track
	return null

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
				results.append({"track_id": track.track_id, "name": track.name, "metadata": track.metadata.duplicate(true)})
		name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0)
	return results

func delete_track(track_id: String) -> bool:
	if track_id.is_empty():
		return false
	var path := "%s/%s" % [TRACK_ROOT, track_id]
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return false
	return _remove_tree(path)

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
	var track = _parse_track_path(path)
	if track == null:
		return null
	if not track.track_id.is_empty() and load_track(track.track_id) != null:
		track.track_id = _new_id()
	track.metadata["imported_at"] = Time.get_datetime_string_from_system(true)
	if save_track(track):
		return track
	return null

func _parse_track_path(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return null
	var payload: Dictionary = parsed as Dictionary
	var schema_version: int = int(payload.get("schema_version", 1))
	if schema_version < 1 or schema_version > TrackDataScript.SCHEMA_VERSION:
		return null
	var track = TrackDataScript.new()
	track.from_dict(payload)
	return track

func _replace_backup(final_path: String, backup_path: String) -> bool:
	if _parse_track_path(final_path) == null:
		return true
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		if DirAccess.remove_absolute(absolute_backup) != OK:
			return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(final_path), absolute_backup) == OK

func _restore_backup_if_needed(final_path: String, backup_path: String) -> void:
	if FileAccess.file_exists(final_path) or not FileAccess.file_exists(backup_path):
		return
	DirAccess.copy_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(final_path))

func _write_text(path: String, payload: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	file.close()
	return true

func _remove_tree(path: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	var dir := DirAccess.open(absolute)
	if dir == null:
		return false
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child := path.path_join(name)
			if dir.current_is_dir():
				if not _remove_tree(child):
					dir.list_dir_end()
					return false
			else:
				if DirAccess.remove_absolute(ProjectSettings.globalize_path(child)) != OK:
					dir.list_dir_end()
					return false
		name = dir.get_next()
	dir.list_dir_end()
	return DirAccess.remove_absolute(absolute) == OK

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
