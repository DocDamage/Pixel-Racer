extends RefCounted
class_name RuntimeAssetCatalog

const CATALOG_PATH := "res://data/assets/runtime_catalog.json"

var _loaded := false
var _atlases: Array[String] = []
var _assets: Dictionary = {}

func has_asset(asset_id: String) -> bool:
	_ensure_loaded()
	return _assets.has(asset_id)

func asset(asset_id: String) -> Dictionary:
	_ensure_loaded()
	return Dictionary(_assets.get(asset_id, {})).duplicate(true)

func ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	for asset_id in _assets:
		result.append(str(asset_id))
	result.sort()
	return result

func count() -> int:
	_ensure_loaded()
	return _assets.size()

func assets_by_type(asset_type: String) -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for asset_id in _assets:
		var definition: Dictionary = _assets[asset_id]
		if str(definition.get("type", "")) == asset_type:
			result.append(definition.duplicate(true))
	return result

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Runtime asset catalog missing: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Runtime asset catalog is invalid JSON.")
		return
	var data: Dictionary = parsed as Dictionary
	for raw_path in data.get("atlases", []):
		_atlases.append(str(raw_path))
	for raw_row in data.get("assets", []):
		if not raw_row is Array:
			continue
		var row: Array = raw_row as Array
		if row.size() < 12:
			continue
		var asset_id := str(row[0])
		var atlas_index := int(row[2])
		var atlas_path := _atlases[atlas_index] if atlas_index >= 0 and atlas_index < _atlases.size() else ""
		_assets[asset_id] = {
			"id": asset_id,
			"type": str(row[1]),
			"atlas_path": atlas_path,
			"region": Rect2i(int(row[3]), int(row[4]), int(row[5]), int(row[6])),
			"frames": int(row[7]),
			"frame_size": Vector2i(int(row[8]), int(row[9])),
			"fps": int(row[10]),
			"flags": int(row[11]),
			"gameplay_directional_complete": (int(row[11]) & 1) == 0
		}
