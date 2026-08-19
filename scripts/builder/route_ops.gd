extends RefCounted
class_name RouteOps

func assign_route(track: TrackData, cells: Array[Vector2i], route_id: String, preferred: bool = true, route_type: String = "alternate", parent_route: String = "main") -> int:
	if track == null or route_id.is_empty():
		return 0
	track.ensure_route_definition(route_id, {
		"type": "main" if route_id == "main" else route_type,
		"parent": "" if route_id == "main" else parent_route,
		"preferred": preferred,
		"legal": true
	})
	var changed := 0
	for cell in cells:
		if track.has_road(cell) and track.set_road_metadata(cell, {
			"route_id": route_id,
			"route_preferred": preferred,
			"is_pit": route_type == "pit"
		}):
			changed += 1
	return changed

func mark_pit_lane(track: TrackData, cells: Array[Vector2i], speed_limit: float = 120.0) -> int:
	track.ensure_route_definition("pit", {
		"type": "pit",
		"parent": "main",
		"preferred": false,
		"legal": true,
		"speed_limit": maxf(20.0, speed_limit)
	})
	var changed := assign_route(track, cells, "pit", false, "pit", "main")
	for cell in cells:
		if track.has_road(cell):
			track.set_road_metadata(cell, {
				"is_pit": true,
				"pit_speed_limit": maxf(20.0, speed_limit)
			})
	return changed

func mark_alternate_route(track: TrackData, cells: Array[Vector2i], route_id: String = "alternate", preferred: bool = false) -> int:
	var safe_id := route_id.strip_edges().to_lower().replace(" ", "_")
	if safe_id.is_empty() or safe_id in ["main", "pit"]:
		safe_id = "alternate"
	track.ensure_route_definition(safe_id, {
		"type": "alternate",
		"parent": "main",
		"preferred": preferred,
		"legal": true
	})
	return assign_route(track, cells, safe_id, preferred, "alternate", "main")

func restore_main_route(track: TrackData, cells: Array[Vector2i]) -> int:
	var changed := 0
	for cell in cells:
		if not track.has_road(cell):
			continue
		if track.set_road_metadata(cell, {
			"route_id": "main",
			"route_preferred": true,
			"is_pit": false
		}):
			changed += 1
	track.ensure_route_definition("main", {"type": "main", "parent": "", "preferred": true, "legal": true})
	return changed

func route_cells(track: TrackData, route_id: String) -> Array[Vector2i]:
	if track == null:
		return []
	return track.get_route_cells(route_id)

func route_summary(track: TrackData, route_id: String) -> Dictionary:
	if track == null:
		return {}
	var cells := track.get_route_cells(route_id)
	var definition := track.route_definition(route_id)
	var graph := TrackGraph.new()
	graph.build(track, route_id)
	var parent := str(definition.get("parent", "main"))
	return {
		"id": route_id,
		"type": str(definition.get("type", "alternate")),
		"parent": parent,
		"cell_count": cells.size(),
		"connected": graph.is_connected(),
		"simple_path": graph.is_simple_path(),
		"interfaces": graph.route_interfaces(route_id, parent)
	}
