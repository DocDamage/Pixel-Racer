extends RefCounted
class_name TrackGraph

var track: TrackData = null
var adjacency: Dictionary = {}
var active_route_id := ""

func build(source_track: TrackData, route_id: String = "") -> void:
	track = source_track
	active_route_id = route_id
	adjacency.clear()
	if track == null:
		return
	var allowed: Dictionary = {}
	for cell: Vector2i in track.road_cells():
		if route_id.is_empty() or track.get_route_id(cell) == route_id:
			allowed[_key(cell)] = cell
	for key in allowed:
		var cell: Vector2i = allowed[key]
		var neighbors: Array[Vector2i] = []
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate: Vector2i = cell + direction
			if allowed.has(_key(candidate)):
				neighbors.append(candidate)
		adjacency[key] = neighbors

func degree(cell: Vector2i) -> int:
	return Array(adjacency.get(_key(cell), [])).size()

func contains(cell: Vector2i) -> bool:
	return adjacency.has(_key(cell))

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
		for next_cell: Vector2i in adjacency.get(key, []):
			if not visited.has(_key(next_cell)):
				queue.append(next_cell)
	return visited.size()

func all_connected() -> bool:
	if adjacency.is_empty():
		return false
	var first: Vector2i = _cell_from_key(str(adjacency.keys()[0]))
	return connected_count(first) == adjacency.size()

func is_single_loop(start: Vector2i) -> bool:
	if adjacency.is_empty() or not adjacency.has(_key(start)):
		return false
	if connected_count(start) != adjacency.size():
		return false
	for key in adjacency:
		if Array(adjacency[key]).size() != 2:
			return false
	return true

func is_simple_path() -> bool:
	if adjacency.size() < 2 or not all_connected():
		return false
	var endpoints := 0
	for key in adjacency:
		var edge_count := Array(adjacency[key]).size()
		if edge_count == 1:
			endpoints += 1
		elif edge_count != 2:
			return false
	return endpoints == 2

func path_endpoints() -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	for key in adjacency:
		if Array(adjacency[key]).size() == 1:
			output.append(_cell_from_key(str(key)))
	return output

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

func find_path_order(start: Vector2i = Vector2i(-999999, -999999)) -> Array[Vector2i]:
	var ordered: Array[Vector2i] = []
	if not is_simple_path():
		return ordered
	var endpoints := path_endpoints()
	var current: Vector2i = endpoints[0] if not contains(start) else start
	if degree(current) != 1:
		current = endpoints[0]
	var previous := Vector2i(999999, 999999)
	var safety := adjacency.size() + 2
	while safety > 0:
		ordered.append(current)
		var candidates: Array = adjacency.get(_key(current), [])
		var next_cell := Vector2i(-999999, -999999)
		for candidate: Vector2i in candidates:
			if candidate != previous:
				next_cell = candidate
				break
		if next_cell.x < -900000:
			break
		previous = current
		current = next_cell
		if degree(current) == 1:
			ordered.append(current)
			break
		safety -= 1
	if ordered.size() != adjacency.size():
		ordered.clear()
	return ordered

func route_interfaces(route_id: String, parent_route_id: String = "main") -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if track == null:
		return output
	var seen: Dictionary = {}
	for cell: Vector2i in track.get_route_cells(route_id):
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if not track.has_road(neighbor) or track.get_route_id(neighbor) != parent_route_id:
				continue
			var pair_key := "%s>%s" % [_key(cell), _key(neighbor)]
			if seen.has(pair_key):
				continue
			seen[pair_key] = true
			output.append({"route_cell": cell, "parent_cell": neighbor})
	return output

func estimate_length(start: Vector2i) -> float:
	var order := find_loop_order(start)
	if order.is_empty() or track == null:
		return 0.0
	return float(order.size()) * float(track.cell_size)

func corner_count() -> int:
	if track == null:
		return 0
	var count := 0
	for key in adjacency:
		var cell := _cell_from_key(str(key))
		var neighbors: Array = adjacency[key]
		if neighbors.size() != 2:
			continue
		var a: Vector2i = neighbors[0] - cell
		var b: Vector2i = neighbors[1] - cell
		if a + b != Vector2i.ZERO:
			count += 1
	return count

func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _cell_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
