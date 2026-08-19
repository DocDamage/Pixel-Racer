extends RefCounted
class_name RouteOps

func assign_route(track: TrackData, cells: Array[Vector2i], route_id: String, preferred: bool = true) -> int:
	var changed := 0
	for cell in cells:
		if track.has_road(cell):
			var road := track.get_road(cell)
			road["route_id"] = route_id
			road["route_preferred"] = preferred
			changed += 1
	if changed > 0:
		track.dirty = true
	return changed

func mark_pit_lane(track: TrackData, cells: Array[Vector2i], speed_limit: float = 120.0) -> int:
	var changed := assign_route(track, cells, "pit", false)
	for cell in cells:
		if track.has_road(cell):
			var road := track.get_road(cell)
			road["is_pit"] = true
			road["pit_speed_limit"] = speed_limit
	track.dirty = track.dirty or changed > 0
	return changed

func route_cells(track: TrackData, route_id: String) -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	for cell in track.road_cells():
		if str(track.get_road(cell).get("route_id", "main")) == route_id:
			output.append(cell)
	return output
