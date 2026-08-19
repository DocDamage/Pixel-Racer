extends SceneTree

var failures := 0

func _init() -> void:
	_test_smart_road_masks()
	_test_serialization_round_trip()
	_test_validation()
	_test_procedural_generator()
	if failures == 0:
		print("Pixel Track Works tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works tests: %d failure(s)" % failures)
		quit(1)

func _test_smart_road_masks() -> void:
	var track := TrackData.new()
	track.set_road(Vector2i(3, 3))
	track.set_road(Vector2i(4, 3))
	track.set_road(Vector2i(4, 4))
	_expect(track.get_road_mask(Vector2i(3, 3)) == TrackData.EAST, "road A connects east")
	_expect(track.get_road_mask(Vector2i(4, 3)) == (TrackData.WEST | TrackData.SOUTH), "corner resolves west+south")
	_expect(track.get_road_mask(Vector2i(4, 4)) == TrackData.NORTH, "road C connects north")

func _test_serialization_round_trip() -> void:
	var source := ProceduralTrackGenerator.new().create_demo_track()
	var encoded := source.to_dict()
	var loaded := TrackData.new()
	loaded.from_dict(encoded)
	_expect(loaded.name == source.name, "track name survives round-trip")
	_expect(loaded.road_tiles.size() == source.road_tiles.size(), "roads survive round-trip")
	_expect(loaded.get_checkpoints_sorted().size() == 3, "checkpoints survive round-trip")

func _test_validation() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	var result := TrackValidator.new().validate(track)
	_expect(bool(result["raceable"]), "demo track is raceable")
	track.remove_road(Vector2i(6, 8))
	result = TrackValidator.new().validate(track)
	_expect(not bool(result["raceable"]), "broken loop is rejected")

func _test_procedural_generator() -> void:
	for seed_value in [1, 2, 3, 99, 2026]:
		var track := ProceduralTrackGenerator.new().generate(seed_value, 40)
		var result := TrackValidator.new().validate(track)
		_expect(bool(result["raceable"]), "generated seed %d is raceable" % seed_value)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
