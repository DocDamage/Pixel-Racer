extends RefCounted
class_name CharacterDefinition

var id: String = ""
var display_name: String = ""
var body_idle_sheet: String = ""
var body_run_sheet: String = ""
var head_idle_sheet: String = ""
var head_run_sheet: String = ""
var body_row: int = 0
var head_row: int = 0
var body_cell_size: Vector2i = Vector2i.ZERO
var head_cell_size: Vector2i = Vector2i.ZERO
var idle_frames: int = 1
var run_frames: int = 1
var walk_speed: float = 72.0
var portrait_id: String = ""
var dialogue_profile: String = "default"

static func from_dict(data: Dictionary) -> CharacterDefinition:
	var definition := CharacterDefinition.new()
	definition.id = str(data.get("id", ""))
	definition.display_name = str(data.get("display_name", definition.id))
	definition.body_idle_sheet = str(data.get("body_idle_sheet", ""))
	definition.body_run_sheet = str(data.get("body_run_sheet", ""))
	definition.head_idle_sheet = str(data.get("head_idle_sheet", ""))
	definition.head_run_sheet = str(data.get("head_run_sheet", ""))
	definition.body_row = int(data.get("body_row", 0))
	definition.head_row = int(data.get("head_row", 0))
	definition.body_cell_size = _vector2i_from_value(data.get("body_cell_size", Vector2i.ZERO))
	definition.head_cell_size = _vector2i_from_value(data.get("head_cell_size", Vector2i.ZERO))
	definition.idle_frames = maxi(1, int(data.get("idle_frames", 1)))
	definition.run_frames = maxi(1, int(data.get("run_frames", 1)))
	definition.walk_speed = maxf(1.0, float(data.get("walk_speed", 72.0)))
	definition.portrait_id = str(data.get("portrait_id", definition.id))
	definition.dialogue_profile = str(data.get("dialogue_profile", "default"))
	return definition

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"body_idle_sheet": body_idle_sheet,
		"body_run_sheet": body_run_sheet,
		"head_idle_sheet": head_idle_sheet,
		"head_run_sheet": head_run_sheet,
		"body_row": body_row,
		"head_row": head_row,
		"body_cell_size": [body_cell_size.x, body_cell_size.y],
		"head_cell_size": [head_cell_size.x, head_cell_size.y],
		"idle_frames": idle_frames,
		"run_frames": run_frames,
		"walk_speed": walk_speed,
		"portrait_id": portrait_id,
		"dialogue_profile": dialogue_profile
	}

func atlas_is_measured() -> bool:
	return body_cell_size.x > 0 and body_cell_size.y > 0 and head_cell_size.x > 0 and head_cell_size.y > 0

func sheets_are_available() -> bool:
	return _resource_exists(body_idle_sheet) and _resource_exists(body_run_sheet) and _resource_exists(head_idle_sheet) and _resource_exists(head_run_sheet)

static func _vector2i_from_value(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is Vector2:
		var vector := value as Vector2
		return Vector2i(roundi(vector.x), roundi(vector.y))
	if value is Array:
		var array_value: Array = value as Array
		if array_value.size() >= 2:
			return Vector2i(int(array_value[0]), int(array_value[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value as Dictionary
		return Vector2i(int(dict_value.get("x", 0)), int(dict_value.get("y", 0)))
	return Vector2i.ZERO

static func _resource_exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)
