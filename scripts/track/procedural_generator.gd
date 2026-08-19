extends RefCounted
class_name ProceduralTrackGenerator

func generate(seed_value: int = 0, map_size: int = 48) -> TrackData:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	var track := TrackData.new()
	track.name = "Generated Ring %04d" % rng.randi_range(0, 9999)
	track.width = clampi(map_size, 24, 96)
	track.height = track.width
	var left := rng.randi_range(5, 9)
	var top := rng.randi_range(5, 9)
	var right := track.width - rng.randi_range(6, 10)
	var bottom := track.height - rng.randi_range(6, 10)
	_draw_rect_loop(track, left, top, right, bottom)
	_add_surface_variation(track, rng, left, top, right, bottom)
	var start := Vector2i((left + right) / 2, bottom)
	track.place_race_object("start_finish", start)
	track.place_race_object("checkpoint", Vector2i(right, (top + bottom) / 2), 0)
	track.place_race_object("checkpoint", Vector2i((left + right) / 2, top), 1)
	track.place_race_object("checkpoint", Vector2i(left, (top + bottom) / 2), 2)
	track.metadata["generator_seed"] = rng.seed
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
	track.add_object("barrier", Vector2i(23, 21), 0)
	track.add_object("barrier", Vector2i(24, 21), 0)
	track.dirty = false
	return track

func _draw_rect_loop(track: TrackData, left: int, top: int, right: int, bottom: int) -> void:
	for x in range(left, right + 1):
		track.set_road(Vector2i(x, top))
		track.set_road(Vector2i(x, bottom))
	for y in range(top + 1, bottom):
		track.set_road(Vector2i(left, y))
		track.set_road(Vector2i(right, y))

func _add_surface_variation(track: TrackData, rng: RandomNumberGenerator, left: int, top: int, right: int, bottom: int) -> void:
	var patch_count := rng.randi_range(2, 5)
	for _patch in range(patch_count):
		var center := Vector2i(rng.randi_range(left + 1, right - 1), rng.randi_range(top + 1, bottom - 1))
		var surface := ["sand", "dirt"][rng.randi_range(0, 1)]
		for y in range(center.y - 1, center.y + 2):
			for x in range(center.x - 1, center.x + 2):
				if track.in_bounds(Vector2i(x, y)) and not track.has_road(Vector2i(x, y)):
					track.set_terrain(Vector2i(x, y), surface)
