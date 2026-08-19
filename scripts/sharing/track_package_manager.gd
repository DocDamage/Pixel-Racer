extends RefCounted
class_name TrackPackageManager

const PACKAGE_SCHEMA := 1
const SaveManagerScript = preload("res://autoload/save_manager.gd")

func export_package(track: TrackData, destination_root: String, preview_path: String = "") -> String:
	if track == null:
		return ""
	var package_name := "%s_%s" % [_safe_name(track.name), track.track_id]
	var package_dir := destination_root.path_join(package_name)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(package_dir)) != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(package_dir)):
		return ""
	if not _write_json(package_dir.path_join("track.json"), track.to_dict()):
		return ""
	var rating := TrackRating.new().calculate(track)
	var metadata := {"package_schema": PACKAGE_SCHEMA, "track_schema": track.schema_version, "track_id": track.track_id, "name": track.name, "author": track.author, "rating": rating, "exported_at": Time.get_datetime_string_from_system(true), "preview": "preview.png" if not preview_path.is_empty() else ""}
	if not _write_json(package_dir.path_join("metadata.json"), metadata):
		return ""
	if not preview_path.is_empty() and FileAccess.file_exists(preview_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(preview_path), ProjectSettings.globalize_path(package_dir.path_join("preview.png")))
	return package_dir

func validate_package(package_dir: String) -> Dictionary:
	var track_path := package_dir.path_join("track.json")
	var metadata_path := package_dir.path_join("metadata.json")
	var errors: Array[String] = []
	if not FileAccess.file_exists(track_path): errors.append("Missing track.json")
	if not FileAccess.file_exists(metadata_path): errors.append("Missing metadata.json")
	var metadata := _read_json(metadata_path)
	if not metadata.is_empty() and int(metadata.get("package_schema", -1)) != PACKAGE_SCHEMA:
		errors.append("Unsupported package schema")
	return {"valid": errors.is_empty(), "errors": errors, "metadata": metadata}

func import_package(package_dir: String):
	var result := validate_package(package_dir)
	if not bool(result.get("valid", false)):
		return null
	var save_manager = SaveManagerScript.new()
	var track = save_manager.load_track_path(package_dir.path_join("track.json"))
	if track == null:
		return null
	if save_manager.load_track(track.track_id) != null:
		track.track_id = "%s-%s" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]
	track.metadata["imported_at"] = Time.get_datetime_string_from_system(true)
	if not save_manager.save_track(track):
		return null
	var source_preview := package_dir.path_join("preview.png")
	if FileAccess.file_exists(source_preview):
		var destination := "user://tracks/%s/preview.png" % track.track_id
		DirAccess.copy_absolute(ProjectSettings.globalize_path(source_preview), ProjectSettings.globalize_path(destination))
	return track

func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _safe_name(value: String) -> String:
	var output := value.strip_edges().to_lower().replace(" ", "_")
	for char in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(char, "")
	return output if not output.is_empty() else "track"
