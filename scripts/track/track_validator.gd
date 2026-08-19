extends RefCounted
class_name TrackValidator

func validate(track) -> Dictionary:
	var errors: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	if track == null:
		errors.append(_issue("NO_TRACK", "No track data is loaded.", Vector2i.ZERO))
		return {"errors": errors, "warnings": warnings, "raceable": false}
	var roads: Array[Vector2i] = track.road_cells()
	if roads.size() < 8:
		errors.append(_issue("TRACK_TOO_SHORT", "Add at least 8 connected road cells.", roads[0] if not roads.is_empty() else Vector2i.ZERO))
	var start: Dictionary = track.get_start_object()
	if start.is_empty():
		errors.append(_issue("NO_START", "Place a Start/Finish line on the circuit.", roads[0] if not roads.is_empty() else Vector2i.ZERO))
	else:
		var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
		if not track.has_road(start_cell):
			errors.append(_issue("START_OFF_TRACK", "Start/Finish must sit on a road cell.", start_cell))
		elif not roads.is_empty():
			var graph := TrackGraph.new()
			graph.build(track)
			if graph.connected_count(start_cell) != roads.size():
				errors.append(_issue("DISCONNECTED_ROAD", "Every road cell must connect to the main circuit.", _find_disconnected(track, graph, start_cell)))
			elif not graph.is_single_loop(start_cell):
				errors.append(_issue("NOT_CLOSED_LOOP", "V0.1 circuit races require one unbranched closed loop.", start_cell))
			else:
				track.metadata["length"] = graph.estimate_length(start_cell)
				track.metadata["corners"] = graph.corner_count()
	var checkpoints := track.get_checkpoints_sorted()
	for index in range(checkpoints.size()):
		var checkpoint: Dictionary = checkpoints[index]
		var cell := Vector2i(int(checkpoint.get("x", 0)), int(checkpoint.get("y", 0)))
		if int(checkpoint.get("sequence_index", -1)) != index:
			errors.append(_issue("CHECKPOINT_ORDER", "Checkpoint numbers must be consecutive starting at 0.", cell))
		if not track.has_road(cell):
			errors.append(_issue("CHECKPOINT_OFF_TRACK", "Checkpoint %d is not on a road cell." % (index + 1), cell))
	if checkpoints.size() < 2:
		warnings.append(_issue("FEW_CHECKPOINTS", "Add at least two checkpoints to prevent shortcut laps.", _start_cell_or_zero(start)))
	for cell in roads:
		var mask: int = track.get_road_mask(cell)
		var degree := _bit_count(mask)
		if degree == 1:
			warnings.append(_issue("ROAD_END", "This road ends and may break the racing route.", cell))
			break
		if degree > 2:
			warnings.append(_issue("BRANCH", "Branches require advanced route logic; official V0.1 races use one loop.", cell))
			break
	var raceable := errors.is_empty()
	track.metadata["difficulty"] = _difficulty(track)
	return {"errors": errors, "warnings": warnings, "raceable": raceable}

func _difficulty(track) -> int:
	var roads: Array[Vector2i] = track.road_cells()
	if roads.is_empty():
		return 1
	var corners := 0
	var loose := 0
	for cell in roads:
		var mask: int = track.get_road_mask(cell)
		if _bit_count(mask) == 2 and mask not in [TrackData.NORTH | TrackData.SOUTH, TrackData.EAST | TrackData.WEST]:
			corners += 1
		if track.get_surface_at(cell) in ["dirt", "sand", "gravel"]:
			loose += 1
	var ratio := float(corners) / float(maxi(1, roads.size()))
	var loose_ratio := float(loose) / float(maxi(1, roads.size()))
	return clampi(1 + roundi(ratio * 8.0 + loose_ratio * 2.0), 1, 5)

func _find_disconnected(track, graph: TrackGraph, start: Vector2i) -> Vector2i:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var key := "%d,%d" % [current.x, current.y]
		if visited.has(key):
			continue
		visited[key] = true
		for next_cell in graph.adjacency.get(key, []):
			queue.append(next_cell)
	for cell in track.road_cells():
		if not visited.has("%d,%d" % [cell.x, cell.y]):
			return cell
	return start

func _bit_count(value: int) -> int:
	var count := 0
	for bit in [TrackData.NORTH, TrackData.EAST, TrackData.SOUTH, TrackData.WEST]:
		if (value & bit) != 0:
			count += 1
	return count

func _start_cell_or_zero(start: Dictionary) -> Vector2i:
	if start.is_empty():
		return Vector2i.ZERO
	return Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))

func _issue(code: String, message: String, cell: Vector2i) -> Dictionary:
	return {"code": code, "message": message, "cell": cell}
