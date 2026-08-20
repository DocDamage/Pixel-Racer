extends RefCounted
class_name VisualThemeCatalog

const CATALOG_PATH := "res://data/assets/visual_themes.json"

var _loaded := false
var _default_theme := "native"
var _themes: Dictionary = {}

func default_theme() -> String:
	_ensure_loaded()
	return _default_theme

func has_theme(theme_id: String) -> bool:
	_ensure_loaded()
	return _themes.has(theme_id)

func theme(theme_id: String) -> Dictionary:
	_ensure_loaded()
	var resolved := theme_id if _themes.has(theme_id) else _default_theme
	return Dictionary(_themes.get(resolved, {})).duplicate(true)

func ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	for theme_id in _themes:
		result.append(str(theme_id))
	result.sort()
	return result

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Visual theme catalog missing: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	_default_theme = str(data.get("default_theme", "native"))
	var themes_value: Variant = data.get("themes", {})
	if themes_value is Dictionary:
		_themes = (themes_value as Dictionary).duplicate(true)
