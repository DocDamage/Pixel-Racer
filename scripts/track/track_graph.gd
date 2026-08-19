extends RefCounted
class_name TrackGraph

var track = null
var adjacency: Dictionary = {}

func build(source_track) -> void:
	track = source_track
	adjacency.clear()
	if track == null:
		return
	for cell in track.road_cells():
		var neighbors: Array[Vector2i] = []
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate := cell + direction
			if track.has_road(candidate):
				neighbors.append(candidate)
		adjacency[_key(cell)] = neighbors

func degree(cell: Vector2i) -> int:
	return Array(adjacency.get(_key(cell), [])).size()

func connected_count(start: Vector2i) -> int:
	if not adjacency.has(_key(start)):
		return 0
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var key := _key(current)
		if visited.has(key):
			continue
		visited[key] = true
		for next_cell in adjacency.get(key, []):
			if not visited.has(_key(next_cell)):
				queue.append(next_cell)
	return visited.size()

func is_single_loop(start: Vector2i) -> bool:
	if adjacency.is_empty() or not adjacency.has(_key(start)):
		return false
	if connected_count(start) != adjacency.size():
		return false
	for key in adjacency:
		if Array(adjacency[key]).size() != 2:
			return false
	return true

func find_loop_order(start: Vector2i) -> Array[Vector2i]:
	var ordered: Array[Vector2i] = []
	if not is_single_loop(start):
		return ordered
	var previous := Vector2i(999999, 999999)
	var current := start
	var safety := adjacency.size() + 2
	while safety > 0:
		ordered.append(current)
		var candidates: Array = adjacency.get(_key(current), [])
		var next_cell: Vector2i = candidates[0]
		if next_cell == previous:
			next_cell = candidates[1]
		previous = current
		current = next_cell
		if current == start:
			break
		safety -= 1
	if current != start:
		ordered.clear()
	return ordered

func estimate_length(start: Vector2i) -> float:
	var order := find_loop_order(start)
	if order.is_empty() or track == null:
		return 0.0
	return float(order.size()) * float(track.cell_size)

func corner_count() -> int:
	if track == null:
		return 0
	var count := 0
	for cell in track.road_cells():
		var mask: int = track.get_road_mask(cell)
		if mask in [TrackData.NORTH | TrackData.EAST, TrackData.EAST | TrackData.SOUTH, TrackData.SOUTH | TrackData.WEST, TrackData.WEST | TrackData.NORTH]:
			count += 1
	return count

func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
