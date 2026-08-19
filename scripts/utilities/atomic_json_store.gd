extends RefCounted
class_name AtomicJsonStore

const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

func save(path: String, payload: Dictionary) -> bool:
	if path.is_empty():
		return false
	var base_dir: String = path.get_base_dir()
	if not base_dir.is_empty():
		var absolute_dir: String = ProjectSettings.globalize_path(base_dir)
		if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK and not DirAccess.dir_exists_absolute(absolute_dir):
			return false
	var temp_path := "%s%s" % [path, TEMP_SUFFIX]
	var backup_path := "%s%s" % [path, BACKUP_SUFFIX]
	if not _write_json(temp_path, payload):
		return false
	if _read_json(temp_path).is_empty() and not payload.is_empty():
		_remove_if_exists(temp_path)
		return false
	if FileAccess.file_exists(path):
		var current: Dictionary = _read_json(path)
		if not current.is_empty():
			if not _replace_backup(path, backup_path):
				_remove_if_exists(temp_path)
				return false
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			_remove_if_exists(temp_path)
			return false
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
	if rename_error == OK:
		return true
	_restore_backup(path, backup_path)
	_remove_if_exists(temp_path)
	return false

func load(path: String) -> Dictionary:
	return Dictionary(load_result(path).get("data", {})).duplicate(true)

func load_result(path: String) -> Dictionary:
	var data: Dictionary = _read_json(path)
	if not data.is_empty():
		return {"data": data, "recovered_from": ""}
	var temp_path := "%s%s" % [path, TEMP_SUFFIX]
	data = _read_json(temp_path)
	if not data.is_empty():
		return {"data": data, "recovered_from": "temporary_save"}
	var backup_path := "%s%s" % [path, BACKUP_SUFFIX]
	data = _read_json(backup_path)
	if not data.is_empty():
		return {"data": data, "recovered_from": "backup"}
	return {"data": {}, "recovered_from": ""}

func remove(path: String) -> bool:
	var removed_any := false
	var success := true
	for candidate in [path, "%s%s" % [path, TEMP_SUFFIX], "%s%s" % [path, BACKUP_SUFFIX]]:
		if not FileAccess.file_exists(candidate):
			continue
		removed_any = true
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) != OK:
			success = false
	return removed_any and success

func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	return true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}

func _replace_backup(path: String, backup_path: String) -> bool:
	if _read_json(path).is_empty():
		return true
	_remove_if_exists(backup_path)
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path)) == OK

func _restore_backup(path: String, backup_path: String) -> void:
	if FileAccess.file_exists(path) or not FileAccess.file_exists(backup_path):
		return
	DirAccess.copy_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path))

func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
