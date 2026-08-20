extends RefCounted
class_name TrackRating

func calculate(track: TrackData) -> Dictionary:
	var roads := track.road_cells()
	if roads.is_empty():
		return _empty()
	var graph := TrackGraph.new()
	graph.build(track)
	var start := track.get_start_object()
	var start_cell := roads[0]
	if not start.is_empty():
		start_cell = Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var length := graph.estimate_length(start_cell)
	if length <= 0.0:
		length = roads.size() * track.cell_size
	var corners := graph.corner_count()
	var loose := 0
	var narrow := 0
	var danger := 0
	for cell in roads:
		if track.get_surface_at(cell) in ["dirt", "sand", "gravel"]:
			loose += 1
		if str(track.get_road(cell).get("width", "standard")) == "narrow":
			narrow += 1
		if graph.degree(cell) != 2:
			danger += 1
	var loose_ratio := float(loose) / float(roads.size())
	var corner_ratio := float(corners) / float(roads.size())
	var narrow_ratio := float(narrow) / float(roads.size())
	var speed_rating := clampi(5 - roundi(corner_ratio * 10.0 + loose_ratio * 2.0), 1, 5)
	var technical := clampi(1 + roundi(corner_ratio * 12.0 + loose_ratio * 2.0 + narrow_ratio * 2.0), 1, 5)
	var danger_rating := clampi(1 + roundi(narrow_ratio * 3.0 + float(danger) / float(roads.size()) * 6.0), 1, 5)
	var difficulty := clampi(roundi((technical + danger_rating + (6 - speed_rating)) / 3.0), 1, 5)
	return {
		"length": length,
		"corners": corners,
		"difficulty": difficulty,
		"speed": speed_rating,
		"technical": technical,
		"danger": danger_rating,
		"offroad_percent": roundi(loose_ratio * 100.0)
	}

func _empty() -> Dictionary:
	return {"length": 0.0, "corners": 0, "difficulty": 1, "speed": 1, "technical": 1, "danger": 1, "offroad_percent": 0}
