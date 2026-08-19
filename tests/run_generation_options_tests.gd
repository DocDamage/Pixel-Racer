extends SceneTree

var failures := 0

func _init() -> void:
	_test_parameterized_styles()
	_test_generated_scenery_safety()
	_test_scenery_clear_only_removes_generated_items()
	if failures == 0:
		print("Pixel Track Works procedural option tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works procedural option tests: %d failure(s)" % failures)
		quit(1)

func _test_parameterized_styles() -> void:
	var validator := TrackValidator.new()
	for style in ["circuit", "mixed", "rally", "oval", "technical"]:
		var track: TrackData = ProceduralTrackGenerator.new().generate(4400 + style.hash(), 52, style, 0.72, "wide", 0.65)
		var result: Dictionary = validator.validate(track)
		_expect(bool(result.get("raceable", false)), "%s generator remains raceable" % style)
		_expect(str(track.metadata.get("generator_style", "")) == style, "%s style metadata is retained" % style)
		_expect(str(track.metadata.get("generator_road_width", "")) == "wide", "%s width metadata is retained" % style)
		for cell in track.road_cells():
			_expect(str(track.get_road(cell).get("width", "")) == "wide", "%s road cells honor selected width" % style)
			break

func _test_generated_scenery_safety() -> void:
	var track: TrackData = ProceduralTrackGenerator.new().generate(778811, 64, "technical", 1.0, "standard", 1.0)
	var generated_count := 0
	for item in track.objects:
		if not bool(item.get("generated", false)):
			continue
		generated_count += 1
		var cell := Vector2i(int(item.get("x", -1)), int(item.get("y", -1)))
		_expect(track.in_bounds(cell), "generated scenery remains in map bounds")
		_expect(not track.has_road(cell), "generated scenery never occupies authoritative road cells")
	_expect(generated_count > 0, "high-density generation produces scenery")
	_expect(generated_count <= 42, "generated scenery obeys hard object cap")
	_expect(int(track.metadata.get("generated_scenery_count", -1)) == generated_count, "generated scenery metadata matches actual count")

func _test_scenery_clear_only_removes_generated_items() -> void:
	var track: TrackData = ProceduralTrackGenerator.new().generate(99112, 48, "circuit", 0.5, "narrow", 0.8)
	track.add_object("barrier_red", Vector2i(2, 2), 0, {"generated": false})
	var before_manual := _manual_object_count(track)
	var removed: int = SceneryGenerator.new().clear_generated(track)
	_expect(removed > 0, "generated scenery can be cleared")
	_expect(_manual_object_count(track) == before_manual, "clearing generated scenery preserves authored props")

func _manual_object_count(track: TrackData) -> int:
	var count := 0
	for item in track.objects:
		if not bool(item.get("generated", false)):
			count += 1
	return count

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
