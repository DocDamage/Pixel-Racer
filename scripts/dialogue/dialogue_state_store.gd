extends RefCounted
class_name DialogueStateStore

const DEFAULT_PATH := "user://dialogue_state.json"
const SAVE_PATH := DEFAULT_PATH
const SCHEMA_VERSION := 1

var path: String
var _store := AtomicJsonStore.new()

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = DEFAULT_PATH if save_path.is_empty() else save_path

func storage_path() -> String:
	return path

func load_state() -> Dictionary:
	var result: Dictionary = _store.load_result(path)
	var normalized := {"seen_once": []}
	var raw_value: Variant = result.get("data", {})
	if raw_value is Dictionary:
		var root: Dictionary = raw_value
		var schema_version := int(root.get("schema_version", SCHEMA_VERSION))
		if schema_version <= SCHEMA_VERSION:
			var raw_seen: Variant = root.get("seen_once", [])
			if raw_seen is Array:
				normalized["seen_once"] = raw_seen.duplicate(true)
	if not str(result.get("recovered_from", "")).is_empty():
		save_state(normalized)
	return normalized

func save_state(state: Dictionary) -> bool:
	var raw_seen: Variant = state.get("seen_once", [])
	var seen: Array = raw_seen.duplicate(true) if raw_seen is Array else []
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"seen_once": seen
	}
	return _store.save(path, payload)

func clear_state() -> bool:
	return _store.remove(path)
