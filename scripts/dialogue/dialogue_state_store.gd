extends RefCounted
class_name DialogueStateStore

const DEFAULT_PATH := "user://dialogue_state.json"
const SCHEMA_VERSION := 1

var path: String = DEFAULT_PATH

func load_state() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"seen_once": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"seen_once": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"seen_once": []}
	var root: Dictionary = parsed as Dictionary
	var raw_seen: Variant = root.get("seen_once", [])
	return {"seen_once": (raw_seen as Array).duplicate(true) if raw_seen is Array else []}

func save_state(state: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"seen_once": Array(state.get("seen_once", [])).duplicate(true)
	}
	file.store_string(JSON.stringify(payload, "\t"))
	return true
