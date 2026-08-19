extends RefCounted
class_name ProceduralTrackGenerator

func generate(seed_value: int = 0, map_size: int = 48, style: String = "circuit") -> TrackData:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	var track := TrackData.new()
	track.name = "Generated %s %04d" % [style.capitalize(), rng.randi_range(0, 9999)]
	track.width = clampi(map_size, 24, 96)
	track.height = track.width
	var left := rng.randi_range(5, 8)
	var top := rng.randi_range(5, 8)
	var right := track.width - rng.randi_range(6, 9)
	var bottom := track.height - rng.randi_range(6, 9)
	_draw_rect_loop(track, left, top, right, bottom)
	_add_safe_detours(track, rng, left, top, right, bottom, rng.randi_range(2, 4))
	var start := track.nearest_road_cell(Vector2i((left + right) / 2, bottom), 8)
	if start.x < 0:
		start = track.road_cells()[0]
	track.place_race_object("start_finish", start)
	var checkpoint_candidates := [
		Vector2i(right, (top + bottom) / 2),
		Vector2i((left + right) / 2, top),
		Vector2i(left, (top + bottom) / 2)
	]
	for index in range(checkpoint_candidates.size()):
		var cell := track.nearest_road_cell(checkpoint_candidates[index], 8)
		if cell.x >= 0:
			track.place_race_object("checkpoint", cell, index)
	_apply_road_surface_style(track, rng, style)
	_add_terrain_variation(track, rng, left, top, right, bottom)
	track.metadata["generator_seed"] = rng.seed
	track.metadata["generator_style"] = style
	track.metadata.merge(TrackRating.new().calculate(track), true)
	track.dirty = true
	return track

func create_demo_track() -> TrackData:
	var track := TrackData.new()
	track.name = "Builder Test Ring"
	track.width = 36
	track.height = 26
	_draw_rect_loop(track, 6, 5, 29, 20)
	for x in range(20, 26):
		track.set_terrain(Vector2i(x, 4), "sand")
		track.set_terrain(Vector2i(x, 5), "sand")
	track.place_race_object("start_finish", Vector2i(17, 20))
	track.place_race_object("checkpoint", Vector2i(29, 12), 0)
	track.place_race_object("checkpoint", Vector2i(17, 5), 1)
	track.place_race_object("checkpoint", Vector2i(6, 12), 2)
	track.add_object("barrier_red", Vector2i(23, 21), 0)
	track.add_object("barrier_white", Vector2i(24, 21), 0)
	track.add_object("tire", Vector2i(25, 21), 0)
	track.metadata.merge(TrackRating.new().calculate(track), true)
	track.dirty = false
	return track

func _draw_rect_loop(track: TrackData, left: int, top: int, right: int, bottom: int) -> void:
	for x in range(left, right + 1):
		track.set_road(Vector2i(x, top))
		track.set_road(Vector2i(x, bottom))
	for y in range(top + 1, bottom):
		track.set_road(Vector2i(left, y))
		track.set_road(Vector2i(right, y))

func _add_safe_detours(track: TrackData, rng: RandomNumberGenerator, left: int, top: int, right: int, bottom: int, target_count: int) -> void:
	var used: Dictionary = {}
	var added := 0
	var attempts := 0
	while added < target_count and attempts < 12:
		attempts += 1
		var side := rng.randi_range(0, 3)
		if used.has(side):
			continue
		var snapshot := track.to_dict()
		_add_side_detour(track, rng, side, left, top, right, bottom)
		if _is_single_loop(track):
			used[side] = true
			added += 1
		else:
			track.from_dict(snapshot)

func _add_side_detour(track: TrackData, rng: RandomNumberGenerator, side: int, left: int, top: int, right: int, bottom: int) -> void:
	var depth := rng.randi_range(2, 4)
	if side in [0, 2]:
		var available := right - left - 10
		if available < 5:
			return
		var start_x := rng.randi_range(left + 4, right - 7)
		var end_x := mini(right - 3, start_x + rng.randi_range(4, 7))
		var base_y := top if side == 0 else bottom
		var detour_y := top + depth if side == 0 else bottom - depth
		for x in range(start_x + 1, end_x):
			track.remove_road(Vector2i(x, base_y))
		for y in range(mini(base_y, detour_y), maxi(base_y, detour_y) + 1):
			track.set_road(Vector2i(start_x, y))
			track.set_road(Vector2i(end_x, y))
		for x in range(start_x, end_x + 1):
			track.set_road(Vector2i(x, detour_y))
	else:
		var available := bottom - top - 10
		if available < 5:
			return
		var start_y := rng.randi_range(top + 4, bottom - 7)
		var end_y := mini(bottom - 3, start_y + rng.randi_range(4, 7))
		var base_x := right if side == 1 else left
		var detour_x := right - depth if side == 1 else left + depth
		for y in range(start_y + 1, end_y):
			track.remove_road(Vector2i(base_x, y))
		for x in range(mini(base_x, detour_x), maxi(base_x, detour_x) + 1):
			track.set_road(Vector2i(x, start_y))
			track.set_road(Vector2i(x, end_y))
		for y in range(start_y, end_y + 1):
			track.set_road(Vector2i(detour_x, y))

func _is_single_loop(track: TrackData) -> bool:
	var roads := track.road_cells()
	if roads.is_empty():
		return false
	var graph := TrackGraph.new()
	graph.build(track)
	return graph.is_single_loop(roads[0])

func _apply_road_surface_style(track: TrackData, rng: RandomNumberGenerator, style: String) -> void:
	var roads := track.road_cells()
	if roads.is_empty():
		return
	var graph := TrackGraph.new()
	graph.build(track)
	var order := graph.find_loop_order(roads[0])
	if order.is_empty():
		return
	var percentage := 0.0
	match style:
		"rally": percentage = 0.42
		"mixed": percentage = 0.18
		_: percentage = 0.0
	if percentage <= 0.0:
		return
	var count := maxi(3, roundi(order.size() * percentage))
	var offset := rng.randi_range(0, maxi(0, order.size() - 1))
	for index in range(count):
		var cell: Vector2i = order[(offset + index) % order.size()]
		track.set_road(cell, "dirt" if index % 5 != 0 else "gravel", str(track.get_road(cell).get("width", "standard")))

func _add_terrain_variation(track: TrackData, rng: RandomNumberGenerator, left: int, top: int, right: int, bottom: int) -> void:
	var patch_count := rng.randi_range(3, 7)
	for _patch in range(patch_count):
		var center := Vector2i(rng.randi_range(left + 1, right - 1), rng.randi_range(top + 1, bottom - 1))
		var surface := ["sand", "dirt", "gravel"][rng.randi_range(0, 2)]
		var radius := rng.randi_range(1, 2)
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var cell := Vector2i(x, y)
				if track.in_bounds(cell) and not track.has_road(cell):
					track.set_terrain(cell, surface)
