extends RefCounted
class_name TrackPackageManager

const PACKAGE_SCHEMA := 2
const SINGLE_FILE_EXTENSION := "pixeltrack"
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
	var metadata: Dictionary = _package_metadata(track, not preview_path.is_empty())
	if not _write_json(package_dir.path_join("metadata.json"), metadata):
		return ""
	if not preview_path.is_empty() and FileAccess.file_exists(preview_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(preview_path), ProjectSettings.globalize_path(package_dir.path_join("preview.png")))
	return package_dir

func export_single_file(track: TrackData, destination_root: String, preview_path: String = "") -> String:
	if track == null:
		return ""
	var absolute_root: String = ProjectSettings.globalize_path(destination_root)
	if DirAccess.make_dir_recursive_absolute(absolute_root) != OK and not DirAccess.dir_exists_absolute(absolute_root):
		return ""
	var package_name := "%s_%s.%s" % [_safe_name(track.name), track.track_id, SINGLE_FILE_EXTENSION]
	var package_path: String = destination_root.path_join(package_name)
	var writer := ZIPPacker.new()
	if writer.open(package_path) != OK:
		return ""
	var success := _zip_write_json(writer, "track.json", track.to_dict())
	if success:
		success = _zip_write_json(writer, "metadata.json", _package_metadata(track, not preview_path.is_empty()))
	if success and not preview_path.is_empty() and FileAccess.file_exists(preview_path):
		var preview_file := FileAccess.open(preview_path, FileAccess.READ)
		if preview_file != null:
			var preview_bytes: PackedByteArray = preview_file.get_buffer(preview_file.get_length())
			preview_file.close()
			success = _zip_write_bytes(writer, "preview.png", preview_bytes)
	writer.close()
	if not success:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(package_path))
		return ""
	return package_path

func validate_package(package_dir: String) -> Dictionary:
	var track_path := package_dir.path_join("track.json")
	var metadata_path := package_dir.path_join("metadata.json")
	var errors: Array[String] = []
	if not FileAccess.file_exists(track_path):
		errors.append("Missing track.json")
	if not FileAccess.file_exists(metadata_path):
		errors.append("Missing metadata.json")
	var metadata := _read_json(metadata_path)
	_validate_metadata(metadata, errors)
	return {"valid": errors.is_empty(), "errors": errors, "metadata": metadata}

func inspect_single_file(package_path: String) -> Dictionary:
	var errors: Array[String] = []
	var metadata: Dictionary = {}
	if not FileAccess.file_exists(package_path):
		return {"valid": false, "errors": ["Package file does not exist"], "metadata": metadata}
	var reader := ZIPReader.new()
	if reader.open(package_path) != OK:
		return {"valid": false, "errors": ["Could not open package archive"], "metadata": metadata}
	if not reader.file_exists("track.json"):
		errors.append("Missing track.json")
	if not reader.file_exists("metadata.json"):
		errors.append("Missing metadata.json")
	if reader.file_exists("metadata.json"):
		metadata = _json_from_bytes(reader.read_file("metadata.json"))
		_validate_metadata(metadata, errors)
	if reader.file_exists("track.json"):
		var track_payload: Dictionary = _json_from_bytes(reader.read_file("track.json"))
		if track_payload.is_empty():
			errors.append("track.json is not valid JSON")
		elif int(track_payload.get("schema_version", -1)) > TrackData.SCHEMA_VERSION:
			errors.append("Track schema is newer than this build supports")
	reader.close()
	return {"valid": errors.is_empty(), "errors": errors, "metadata": metadata}

func import_package(package_dir: String):
	var result := validate_package(package_dir)
	if not bool(result.get("valid", false)):
		return null
	var save_manager = SaveManagerScript.new()
	var track = save_manager.load_track_path(package_dir.path_join("track.json"))
	if track == null:
		return null
	track = _prepare_import_id(track, save_manager)
	track.metadata["imported_at"] = Time.get_datetime_string_from_system(true)
	if not save_manager.save_track(track):
		return null
	var source_preview := package_dir.path_join("preview.png")
	if FileAccess.file_exists(source_preview):
		var destination := "user://tracks/%s/preview.png" % track.track_id
		DirAccess.copy_absolute(ProjectSettings.globalize_path(source_preview), ProjectSettings.globalize_path(destination))
	return track

func import_single_file(package_path: String):
	var inspection := inspect_single_file(package_path)
	if not bool(inspection.get("valid", false)):
		return null
	var reader := ZIPReader.new()
	if reader.open(package_path) != OK:
		return null
	var track_payload: Dictionary = _json_from_bytes(reader.read_file("track.json"))
	if track_payload.is_empty():
		reader.close()
		return null
	var track := TrackData.new()
	track.from_dict(track_payload)
	var save_manager = SaveManagerScript.new()
	track = _prepare_import_id(track, save_manager)
	track.metadata["imported_at"] = Time.get_datetime_string_from_system(true)
	if not save_manager.save_track(track):
		reader.close()
		return null
	if reader.file_exists("preview.png"):
		var destination := "user://tracks/%s/preview.png" % track.track_id
		var preview_file := FileAccess.open(destination, FileAccess.WRITE)
		if preview_file != null:
			preview_file.store_buffer(reader.read_file("preview.png"))
			preview_file.close()
	reader.close()
	return track

func _package_metadata(track: TrackData, has_preview: bool) -> Dictionary:
	return {
		"package_schema": PACKAGE_SCHEMA,
		"track_schema": track.schema_version,
		"compatible_track_schema_max": TrackData.SCHEMA_VERSION,
		"track_id": track.track_id,
		"name": track.name,
		"author": track.author,
		"description": str(track.metadata.get("description", "")),
		"tags": Array(track.metadata.get("tags", [])).duplicate(true),
		"required_asset_version": str(track.metadata.get("required_asset_version", "wheels-in-pixels")),
		"application_version": str(ProjectSettings.get_setting("application/config/version", "development")),
		"rating": TrackRating.new().calculate(track),
		"exported_at": Time.get_datetime_string_from_system(true),
		"preview": "preview.png" if has_preview else ""
	}

func _validate_metadata(metadata: Dictionary, errors: Array[String]) -> void:
	if metadata.is_empty():
		return
	var package_schema: int = int(metadata.get("package_schema", -1))
	if package_schema < 1 or package_schema > PACKAGE_SCHEMA:
		errors.append("Unsupported package schema")
	var track_schema: int = int(metadata.get("track_schema", -1))
	if track_schema > TrackData.SCHEMA_VERSION:
		errors.append("Track schema is newer than this build supports")

func _prepare_import_id(track: TrackData, save_manager) -> TrackData:
	if not track.track_id.is_empty() and save_manager.load_track(track.track_id) != null:
		track.track_id = "%s-%s" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]
	return track

func _zip_write_json(writer: ZIPPacker, path: String, payload: Dictionary) -> bool:
	return _zip_write_bytes(writer, path, JSON.stringify(payload, "\t").to_utf8_buffer())

func _zip_write_bytes(writer: ZIPPacker, path: String, bytes: PackedByteArray) -> bool:
	if writer.start_file(path) != OK:
		return false
	var wrote: bool = writer.write_file(bytes) == OK
	var closed: bool = writer.close_file() == OK
	return wrote and closed

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
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _json_from_bytes(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}

func _safe_name(value: String) -> String:
	var output := value.strip_edges().to_lower().replace(" ", "_")
	for char in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(char, "")
	return output if not output.is_empty() else "track"
