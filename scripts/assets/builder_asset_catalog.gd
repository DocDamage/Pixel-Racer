extends RefCounted
class_name BuilderAssetCatalog

const CATALOG_PATH := "res://data/assets/builder_catalog.json"

var _loaded := false
var _entries: Dictionary = {}
var _runtime := RuntimeAssetCatalog.new()

func has_entry(entry_id: String) -> bool:
	_ensure_loaded()
	return _entries.has(entry_id)

func entry(entry_id: String) -> Dictionary:
	_ensure_loaded()
	return Dictionary(_entries.get(entry_id, {})).duplicate(true)

func ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	for entry_id in _entries:
		result.append(str(entry_id))
	result.sort()
	return result

func count() -> int:
	_ensure_loaded()
	return _entries.size()

func categories() -> Array[String]:
	_ensure_loaded()
	var seen: Dictionary = {}
	for entry_id in _entries:
		seen[str(_entries[entry_id].get("category", "OTHER"))] = true
	var result: Array[String] = []
	for category in seen:
		result.append(str(category))
	result.sort()
	return result

func entries_for_category(category: String, max_tier: int = 7) -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for entry_id in _entries:
		var definition: Dictionary = _entries[entry_id]
		if str(definition.get("category", "")) == category and int(definition.get("tier", 1)) <= max_tier:
			result.append(definition.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0)
	return result

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Builder asset catalog missing: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Builder asset catalog is invalid JSON.")
		return
	var data: Dictionary = parsed as Dictionary
	for raw_row in data.get("assets", []):
		if not raw_row is Array:
			continue
		var row: Array = raw_row as Array
		if row.size() < 8:
			continue
		var entry_id := str(row[0])
		var asset_id := str(row[3])
		if asset_id.is_empty() and _runtime.has_asset(entry_id):
			asset_id = entry_id
		_entries[entry_id] = {
			"id": entry_id,
			"name": str(row[1]),
			"category": str(row[2]),
			"asset_id": asset_id,
			"collision": str(row[4]),
			"tier": int(row[5]),
			"cost": int(row[6]),
			"flags": int(row[7]),
			"animated": (int(row[7]) & 1) != 0,
			"dynamic": (int(row[7]) & 2) != 0,
			"hazard": (int(row[7]) & 4) != 0
		}
