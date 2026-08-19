extends RefCounted
class_name SceneryGenerator

const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const BARRIER_TYPES: Array[String] = ["barrier_red", "barrier_white", "barrier_yellow", "barrier_black", "barrier_green"]

func decorate(track: TrackData, rng: RandomNumberGenerator, density: float = 0.45) -> int:
	if track == null or rng == null:
		return 0
	var resolved_density: float = clampf(density, 0.0, 1.0)
	if resolved_density <= 0.0:
		return 0
	var road_cells: Array[Vector2i] = track.road_cells()
	road_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	var occupied: Dictionary = {}
	for item in track.objects:
		var cell := Vector2i(int(item.get("x", -1)), int(item.get("y", -1)))
		occupied[cell] = true
	var placed := 0
	var target := clampi(roundi(float(road_cells.size()) * resolved_density * 0.12), 4, 42)
	for road_cell in road_cells:
		if placed >= target:
			break
		if rng.randf() > resolved_density:
			continue
		var mask: int = track.get_road_mask(road_cell)
		var degree: int = _connection_count(mask)
		var is_corner: bool = degree == 2 and mask not in [TrackData.NORTH | TrackData.SOUTH, TrackData.EAST | TrackData.WEST]
		var chance: float = 0.78 if is_corner else 0.20
		if rng.randf() > chance:
			continue
		var directions: Array[Vector2i] = CARDINALS.duplicate()
		_shuffle_directions(directions, rng)
		for direction in directions:
			var tire_cell: Vector2i = road_cell + direction
			if _safe_cell(track, tire_cell, occupied, 0):
				track.add_object("tire", tire_cell, 0, {"generated": true})
				occupied[tire_cell] = true
				placed += 1
				break
			var barrier_cell: Vector2i = road_cell + direction * 2
			if _safe_cell(track, barrier_cell, occupied, 1):
				var barrier_type: String = BARRIER_TYPES[rng.randi_range(0, BARRIER_TYPES.size() - 1)]
				var rotation_steps: int = 0 if direction.x != 0 else 1
				track.add_object(barrier_type, barrier_cell, rotation_steps, {"generated": true})
				occupied[barrier_cell] = true
				placed += 1
				break
	track.metadata["generated_scenery_count"] = placed
	return placed

func clear_generated(track: TrackData) -> int:
	if track == null:
		return 0
	var removed := 0
	for index in range(track.objects.size() - 1, -1, -1):
		var item: Dictionary = track.objects[index]
		if bool(item.get("generated", false)):
			track.objects.remove_at(index)
			removed += 1
	if removed > 0:
		track.dirty = true
		track.metadata["generated_scenery_count"] = 0
	return removed

func _safe_cell(track: TrackData, cell: Vector2i, occupied: Dictionary, road_clearance: int) -> bool:
	if not track.in_bounds(cell) or track.has_road(cell) or occupied.has(cell):
		return false
	for race_object in track.race_objects:
		var race_cell := Vector2i(int(race_object.get("x", -1)), int(race_object.get("y", -1)))
		if race_cell == cell:
			return false
	if road_clearance > 0:
		var nearest: Vector2i = track.nearest_road_cell(cell, road_clearance)
		if nearest.x >= 0:
			return false
	return true

func _connection_count(mask: int) -> int:
	var count := 0
	for bit in [TrackData.NORTH, TrackData.EAST, TrackData.SOUTH, TrackData.WEST]:
		if (mask & bit) != 0:
			count += 1
	return count

func _shuffle_directions(values: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: Vector2i = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temp
