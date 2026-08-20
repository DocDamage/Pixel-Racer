extends RefCounted
class_name TrackValidator

func validate(track: TrackData) -> Dictionary:
	var errors: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	if track == null:
		errors.append(_issue("NO_TRACK", "No track data is loaded.", Vector2i.ZERO))
		return {"errors": errors, "warnings": warnings, "raceable": false}
	var roads: Array[Vector2i] = track.road_cells()
	var main_roads: Array[Vector2i] = track.get_route_cells("main")
	if main_roads.size() < 8:
		errors.append(_issue("TRACK_TOO_SHORT", "The main route needs at least 8 connected road cells.", main_roads[0] if not main_roads.is_empty() else Vector2i.ZERO))
	var start: Dictionary = track.get_start_object()
	var main_graph := TrackGraph.new()
	main_graph.build(track, "main")
	if start.is_empty():
		errors.append(_issue("NO_START", "Place a Start/Finish line on the main circuit.", main_roads[0] if not main_roads.is_empty() else Vector2i.ZERO))
	else:
		var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
		if not track.has_road(start_cell):
			errors.append(_issue("START_OFF_TRACK", "Start/Finish must sit on a road cell.", start_cell))
		elif track.get_route_id(start_cell) != "main":
			errors.append(_issue("START_OFF_MAIN", "Start/Finish must sit on the main route, not an optional bypass.", start_cell))
		elif not main_roads.is_empty():
			if main_graph.connected_count(start_cell) != main_roads.size():
				errors.append(_issue("DISCONNECTED_MAIN", "Every main-route road cell must connect to the main circuit.", _find_disconnected_route(track, main_graph, start_cell, "main")))
			elif not main_graph.is_single_loop(start_cell):
				errors.append(_issue("MAIN_NOT_CLOSED_LOOP", "The main race route must be one unbranched closed loop.", start_cell))
			else:
				track.metadata["length"] = main_graph.estimate_length(start_cell)
				track.metadata["corners"] = main_graph.corner_count()
	var checkpoints := track.get_checkpoints_sorted()
	for index in range(checkpoints.size()):
		var checkpoint: Dictionary = checkpoints[index]
		var cell := Vector2i(int(checkpoint.get("x", 0)), int(checkpoint.get("y", 0)))
		if int(checkpoint.get("sequence_index", -1)) != index:
			errors.append(_issue("CHECKPOINT_ORDER", "Checkpoint numbers must be consecutive starting at 0.", cell))
		if not track.has_road(cell):
			errors.append(_issue("CHECKPOINT_OFF_TRACK", "Checkpoint %d is not on a road cell." % (index + 1), cell))
		elif track.get_route_id(cell) != "main":
			errors.append(_issue("CHECKPOINT_OFF_MAIN", "Required checkpoints must stay on the main route so optional bypasses cannot invalidate laps.", cell))
	if checkpoints.size() < 2:
		warnings.append(_issue("FEW_CHECKPOINTS", "Add at least two checkpoints to prevent shortcut laps.", _start_cell_or_zero(start)))
	_validate_optional_routes(track, errors, warnings)
	for cell in main_roads:
		var degree := main_graph.degree(cell)
		if degree == 1:
			warnings.append(_issue("MAIN_ROAD_END", "The main route ends here and cannot form a proper circuit.", cell))
			break
		if degree > 2:
			warnings.append(_issue("MAIN_BRANCH", "Main-route cells may not branch. Mark optional roads as pit or alternate routes.", cell))
			break
	if roads.size() > main_roads.size():
		track.metadata["optional_route_cells"] = roads.size() - main_roads.size()
	else:
		track.metadata["optional_route_cells"] = 0
	track.metadata["route_count"] = track.route_ids().size()
	track.metadata["difficulty"] = _difficulty(track)
	var raceable := errors.is_empty()
	return {"errors": errors, "warnings": warnings, "raceable": raceable}

func _validate_optional_routes(track: TrackData, errors: Array[Dictionary], warnings: Array[Dictionary]) -> void:
	for route_id in track.route_ids():
		if route_id == "main":
			continue
		var cells: Array[Vector2i] = track.get_route_cells(route_id)
		var definition: Dictionary = track.route_definition(route_id)
		if cells.is_empty():
			warnings.append(_issue("EMPTY_ROUTE", "Route '%s' is defined but has no road cells." % route_id, Vector2i.ZERO))
			continue
		var route_type := str(definition.get("type", "alternate"))
		var parent_route := str(definition.get("parent", "main"))
		if parent_route.is_empty() or parent_route == route_id:
			errors.append(_issue("ROUTE_PARENT", "Route '%s' needs a different parent route." % route_id, cells[0]))
			continue
		if track.get_route_cells(parent_route).is_empty():
			errors.append(_issue("ROUTE_PARENT_MISSING", "Route '%s' references missing parent route '%s'." % [route_id, parent_route], cells[0]))
			continue
		var graph := TrackGraph.new()
		graph.build(track, route_id)
		if cells.size() < 2:
			errors.append(_issue("ROUTE_TOO_SHORT", "Optional route '%s' needs at least two cells." % route_id, cells[0]))
			continue
		if not graph.is_simple_path():
			errors.append(_issue("ROUTE_NOT_PATH", "Optional route '%s' must be one connected, unbranched path." % route_id, cells[0]))
			continue
		var interfaces: Array[Dictionary] = graph.route_interfaces(route_id, parent_route)
		if interfaces.size() != 2:
			errors.append(_issue("ROUTE_INTERFACES", "Optional route '%s' must connect to '%s' at exactly two places." % [route_id, parent_route], cells[0]))
			continue
		var endpoints := graph.path_endpoints()
		var endpoint_lookup: Dictionary = {}
		for endpoint in endpoints:
			endpoint_lookup[_cell_key(endpoint)] = true
		var parent_lookup: Dictionary = {}
		for interface in interfaces:
			var route_cell: Vector2i = interface.get("route_cell", Vector2i.ZERO)
			var parent_cell: Vector2i = interface.get("parent_cell", Vector2i.ZERO)
			parent_lookup[_cell_key(parent_cell)] = true
			if not endpoint_lookup.has(_cell_key(route_cell)):
				errors.append(_issue("ROUTE_MIDDLE_JOIN", "Route '%s' may only join its parent at its two endpoints." % route_id, route_cell))
		if parent_lookup.size() != 2:
			errors.append(_issue("ROUTE_SAME_INTERFACE", "Route '%s' must leave and rejoin at two different parent-route cells." % route_id, cells[0]))
		if route_type == "pit":
			var speed_limit := float(definition.get("speed_limit", 0.0))
			if speed_limit <= 0.0:
				errors.append(_issue("PIT_SPEED_LIMIT", "Pit lanes need a positive speed limit.", cells[0]))
			for cell in cells:
				if not bool(track.get_road(cell).get("is_pit", false)):
					warnings.append(_issue("PIT_METADATA", "This pit-route cell is missing its pit-lane flag.", cell))
					break
		elif route_type == "alternate" and bool(definition.get("preferred", false)):
			warnings.append(_issue("PREFERRED_ALTERNATE", "Preferred alternate routes are valid, but AI currently stays on the main line.", cells[0]))

func _difficulty(track: TrackData) -> int:
	var roads: Array[Vector2i] = track.get_route_cells("main")
	if roads.is_empty():
		return 1
	var corners := 0
	var loose := 0
	var narrow := 0
	var graph := TrackGraph.new()
	graph.build(track, "main")
	corners = graph.corner_count()
	for cell in roads:
		if track.get_surface_at(cell) in ["dirt", "sand", "gravel"]:
			loose += 1
		if str(track.get_road(cell).get("width", "standard")) == "narrow":
			narrow += 1
	var ratio := float(corners) / float(maxi(1, roads.size()))
	var loose_ratio := float(loose) / float(maxi(1, roads.size()))
	var narrow_ratio := float(narrow) / float(maxi(1, roads.size()))
	return clampi(1 + roundi(ratio * 8.0 + loose_ratio * 2.0 + narrow_ratio * 2.0), 1, 5)

func _find_disconnected_route(track: TrackData, graph: TrackGraph, start: Vector2i, route_id: String) -> Vector2i:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var key := _cell_key(current)
		if visited.has(key):
			continue
		visited[key] = true
		for next_cell in graph.adjacency.get(key, []):
			queue.append(next_cell)
	for cell in track.get_route_cells(route_id):
		if not visited.has(_cell_key(cell)):
			return cell
	return start

func _start_cell_or_zero(start: Dictionary) -> Vector2i:
	if start.is_empty():
		return Vector2i.ZERO
	return Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _issue(code: String, message: String, cell: Vector2i) -> Dictionary:
	return {"code": code, "message": message, "cell": cell}
