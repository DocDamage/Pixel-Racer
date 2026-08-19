extends RefCounted
class_name TrackData

const SCHEMA_VERSION := 1
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8
const DIRECTIONS := {NORTH: Vector2i.UP, EAST: Vector2i.RIGHT, SOUTH: Vector2i.DOWN, WEST: Vector2i.LEFT}
const DRIVEABLE_SURFACES := ["asphalt", "dirt", "sand", "gravel"]

var schema_version: int = SCHEMA_VERSION
var track_id: String = ""
var name: String = "Untitled Track"
var author: String = "Player"
var width: int = 64
var height: int = 64
var cell_size: int = 64
var terrain: Dictionary = {}
var road_tiles: Dictionary = {}
var objects: Array[Dictionary] = []
var race_objects: Array[Dictionary] = []
var event_presets: Array[Dictionary] = []
var metadata: Dictionary = {"length": 0.0, "difficulty": 1, "created_at": "", "updated_at": ""}
var dirty: bool = false

func _init() -> void:
	if track_id.is_empty():
		track_id = _new_id()

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func has_road(cell: Vector2i) -> bool:
	return road_tiles.has(_key(cell))

func get_road(cell: Vector2i) -> Dictionary:
	return road_tiles.get(_key(cell), {})

func get_road_mask(cell: Vector2i) -> int:
	return int(get_road(cell).get("connection_mask", 0))

func set_road(cell: Vector2i, surface: String = "asphalt", road_width: String = "standard") -> bool:
	if not in_bounds(cell):
		return false
	var key := _key(cell)
	var previous: Dictionary = road_tiles.get(key, {})
	var item := previous.duplicate(true)
	item["x"] = cell.x
	item["y"] = cell.y
	item["type"] = surface if surface in DRIVEABLE_SURFACES else "asphalt"
	item["connection_mask"] = int(previous.get("connection_mask", 0))
	item["variant"] = int(previous.get("variant", 0))
	item["width"] = road_width
	if not item.has("route_id"):
		item["route_id"] = "main"
	road_tiles[key] = item
	_recalculate_around(cell)
	dirty = true
	return true

func set_road_surface(cell: Vector2i, surface: String) -> bool:
	if not has_road(cell) or surface not in DRIVEABLE_SURFACES:
		return false
	road_tiles[_key(cell)]["type"] = surface
	dirty = true
	return true

func set_road_width(cell: Vector2i, road_width: String) -> bool:
	if not has_road(cell) or road_width not in ["narrow", "standard", "wide", "extra_wide"]:
		return false
	road_tiles[_key(cell)]["width"] = road_width
	dirty = true
	return true

func set_road_metadata(cell: Vector2i, values: Dictionary) -> bool:
	if not has_road(cell):
		return false
	for key in values:
		if key not in ["x", "y", "connection_mask"]:
			road_tiles[_key(cell)][key] = values[key]
	dirty = true
	return true

func remove_road(cell: Vector2i) -> bool:
	var key := _key(cell)
	if not road_tiles.has(key):
		return false
	road_tiles.erase(key)
	_recalculate_around(cell)
	dirty = true
	return true

func set_terrain(cell: Vector2i, surface: String) -> bool:
	if not in_bounds(cell):
		return false
	if has_road(cell) and surface in ["dirt", "sand", "gravel"]:
		return set_road_surface(cell, surface)
	var key := _key(cell)
	if surface == "grass":
		terrain.erase(key)
	else:
		terrain[key] = {"x": cell.x, "y": cell.y, "type": surface}
	dirty = true
	return true

func get_surface_at(cell: Vector2i) -> String:
	if has_road(cell):
		return str(get_road(cell).get("type", "asphalt"))
	return str(terrain.get(_key(cell), {}).get("type", "grass"))

func add_object(type: String, cell: Vector2i, rotation_steps: int = 0, extra: Dictionary = {}) -> Dictionary:
	var item := {"id": _new_id(), "type": type, "x": cell.x, "y": cell.y, "rotation_steps": posmod(rotation_steps, 4)}
	item.merge(extra, true)
	objects.append(item)
	dirty = true
	return item

func remove_objects_at(cell: Vector2i) -> int:
	var removed := 0
	for index in range(objects.size() - 1, -1, -1):
		var item: Dictionary = objects[index]
		if Vector2i(int(item.get("x", -1)), int(item.get("y", -1))) == cell:
			objects.remove_at(index)
			removed += 1
	if removed > 0:
		dirty = true
	return removed

func place_race_object(type: String, cell: Vector2i, sequence_index: int = -1) -> Dictionary:
	if type == "start_finish":
		for index in range(race_objects.size() - 1, -1, -1):
			if str(race_objects[index].get("type", "")) == "start_finish":
				race_objects.remove_at(index)
	var item := {"id": _new_id(), "type": type, "x": cell.x, "y": cell.y, "sequence_index": sequence_index}
	race_objects.append(item)
	dirty = true
	return item

func remove_race_objects_at(cell: Vector2i) -> int:
	var removed := 0
	for index in range(race_objects.size() - 1, -1, -1):
		var item: Dictionary = race_objects[index]
		if Vector2i(int(item.get("x", -1)), int(item.get("y", -1))) == cell:
			race_objects.remove_at(index)
			removed += 1
	if removed > 0:
		dirty = true
	return removed

func erase_at(cell: Vector2i) -> void:
	remove_road(cell)
	remove_objects_at(cell)
	remove_race_objects_at(cell)

func get_start_object() -> Dictionary:
	for item in race_objects:
		if str(item.get("type", "")) == "start_finish":
			return item
	return {}

func get_checkpoints_sorted() -> Array[Dictionary]:
	var checkpoints: Array[Dictionary] = []
	for item in race_objects:
		if str(item.get("type", "")) == "checkpoint":
			checkpoints.append(item)
	checkpoints.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sequence_index", 0)) < int(b.get("sequence_index", 0)))
	return checkpoints

func road_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for key in road_tiles:
		cells.append(_cell_from_key(str(key)))
	return cells

func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / float(cell_size)), floori(world_position.y / float(cell_size)))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)

func nearest_road_cell(cell: Vector2i, max_radius: int = 12) -> Vector2i:
	if has_road(cell):
		return cell
	for radius in range(1, max_radius + 1):
		for y in range(cell.y - radius, cell.y + radius + 1):
			for x in range(cell.x - radius, cell.x + radius + 1):
				var candidate := Vector2i(x, y)
				if in_bounds(candidate) and has_road(candidate):
					return candidate
	return Vector2i(-1, -1)

func to_dict() -> Dictionary:
	var terrain_array: Array = []
	for key in terrain:
		terrain_array.append(terrain[key].duplicate(true))
	var road_array: Array = []
	for key in road_tiles:
		road_array.append(road_tiles[key].duplicate(true))
	return {"schema_version": schema_version, "track_id": track_id, "name": name, "author": author, "width": width, "height": height, "cell_size": cell_size, "terrain": terrain_array, "road_tiles": road_array, "objects": objects.duplicate(true), "race_objects": race_objects.duplicate(true), "event_presets": event_presets.duplicate(true), "metadata": metadata.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	track_id = str(data.get("track_id", _new_id()))
	name = str(data.get("name", "Untitled Track"))
	author = str(data.get("author", "Player"))
	width = maxi(8, int(data.get("width", 64)))
	height = maxi(8, int(data.get("height", 64)))
	cell_size = maxi(16, int(data.get("cell_size", 64)))
	terrain.clear()
	for raw in data.get("terrain", []):
		if raw is Dictionary:
			var cell := Vector2i(int(raw.get("x", 0)), int(raw.get("y", 0)))
			terrain[_key(cell)] = raw.duplicate(true)
	road_tiles.clear()
	for raw in data.get("road_tiles", []):
		if raw is Dictionary:
			var cell := Vector2i(int(raw.get("x", 0)), int(raw.get("y", 0)))
			var road: Dictionary = raw.duplicate(true)
			if not road.has("width"):
				road["width"] = "standard"
			if not road.has("route_id"):
				road["route_id"] = "main"
			road_tiles[_key(cell)] = road
	objects = _typed_dictionary_array(data.get("objects", []))
	race_objects = _typed_dictionary_array(data.get("race_objects", []))
	event_presets = _typed_dictionary_array(data.get("event_presets", []))
	var raw_metadata = data.get("metadata", {})
	metadata = raw_metadata.duplicate(true) if raw_metadata is Dictionary else {}
	for cell in road_cells():
		_recalculate_mask(cell)
	dirty = false

func clone():
	var copy := TrackData.new()
	copy.from_dict(to_dict())
	copy.dirty = dirty
	return copy

func _recalculate_around(cell: Vector2i) -> void:
	_recalculate_mask(cell)
	for direction in DIRECTIONS.values():
		_recalculate_mask(cell + direction)

func _recalculate_mask(cell: Vector2i) -> void:
	var key := _key(cell)
	if not road_tiles.has(key):
		return
	var mask := 0
	for bit in DIRECTIONS:
		if has_road(cell + DIRECTIONS[bit]):
			mask |= int(bit)
	road_tiles[key]["connection_mask"] = mask

func _typed_dictionary_array(raw_value) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if raw_value is Array:
		for item in raw_value:
			if item is Dictionary:
				output.append(item.duplicate(true))
	return output

func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _cell_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func _new_id() -> String:
	return "%s-%s" % [Time.get_unix_time_from_system(), randi_range(100000, 999999)]
