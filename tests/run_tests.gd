extends SceneTree

var failures := 0

func _init() -> void:
	_test_smart_road_masks()
	_test_serialization_round_trip()
	_test_validation()
	_test_builder_clipboard()
	_test_draw_track_tool()
	_test_rating_and_preview()
	_test_garage_model()
	_test_record_model()
	_test_track_package()
	_test_race_mode_catalog()
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

func _test_builder_clipboard() -> void:
	var track := TrackData.new()
	track.set_road(Vector2i(2, 2))
	track.set_road(Vector2i(3, 2))
	track.set_terrain(Vector2i(2, 3), "sand")
	track.add_object("barrier", Vector2i(3, 3), 1)
	var ops := TrackEditOps.new()
	var clip := ops.capture(track, Vector2i(2, 2), Vector2i(3, 3))
	_expect(Array(clip["roads"]).size() == 2, "clipboard captures road cells")
	var rotated := ops.rotate_clockwise(clip)
	_expect(Vector2i(rotated["size"]) == Vector2i(2, 2), "clipboard rotation preserves square bounds")
	ops.paste(track, rotated, Vector2i(8, 8))
	_expect(track.has_road(Vector2i(8, 8)) or track.has_road(Vector2i(9, 8)), "clipboard paste creates roads")
	_expect(track.objects.size() == 2, "clipboard paste duplicates objects")

func _test_draw_track_tool() -> void:
	var track := TrackData.new()
	var tool := DrawTrackTool.new()
	var samples: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, 7), Vector2i(8, 7)]
	var placed := tool.draw_cells(track, samples, "asphalt", "wide")
	_expect(placed >= 11, "draw-a-track rasterizes connected cells")
	_expect(track.has_road(Vector2i(2, 5)) and track.has_road(Vector2i(6, 7)), "draw-a-track fills both segments")
	_expect(str(track.get_road(Vector2i(2, 5)).get("width", "")) == "wide", "draw-a-track stores discrete width")

func _test_rating_and_preview() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	var rating := TrackRating.new().calculate(track)
	_expect(float(rating.get("length", 0.0)) > 0.0, "track rating calculates length")
	_expect(int(rating.get("corners", 0)) >= 4, "track rating counts corners")
	var image := TrackPreviewGenerator.new().render(track, Vector2i(96, 54))
	_expect(image.get_width() == 96 and image.get_height() == 54, "preview generator returns requested size")

func _test_garage_model() -> void:
	var garage := GarageManager.new()
	_expect(garage.vehicle_price("Hachiroku_Drifter") > 0, "garage derives vehicle prices")
	var definition := garage.effective_definition("Hachiroku_Drifter")
	_expect(definition.has("stats") and definition.has("tuning"), "garage produces effective tuned definition")
	_expect(garage.tier_name("Hachiroku_Drifter", "engine") in GarageManager.TIER_NAMES, "garage exposes upgrade tier names")

func _test_record_model() -> void:
	var records := RecordManager.new()
	var test_id := "ci-test-%s" % Time.get_ticks_msec()
	_expect(records.record_lap(test_id, "Hachiroku_Drifter", "time_trial", 42.5), "record manager accepts first lap")
	_expect(not records.record_lap(test_id, "Hachiroku_Drifter", "time_trial", 45.0), "record manager rejects slower lap")
	_expect(records.record_score(test_id, "Hachiroku_Drifter", "drift", 1000.0), "record manager accepts drift score")
	_expect(not records.record_score(test_id, "Hachiroku_Drifter", "drift", 900.0), "record manager rejects lower drift score")

func _test_track_package() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	track.track_id = "ci-package-track"
	var root := "user://ci_packages"
	var package_dir := TrackPackageManager.new().export_package(track, root)
	_expect(not package_dir.is_empty(), "track package exports")
	var result := TrackPackageManager.new().validate_package(package_dir)
	_expect(bool(result.get("valid", false)), "exported track package validates")

func _test_race_mode_catalog() -> void:
	for mode in ["circuit", "time_trial", "sprint", "checkpoint", "drift"]:
		_expect(RaceModeCatalog.MODES.has(mode), "race mode %s is registered" % mode)
	_expect(int(RaceModeCatalog.get_mode("circuit").get("laps", 0)) == 3, "circuit preset carries lap count")
	_expect(float(RaceModeCatalog.get_mode("checkpoint").get("checkpoint_bonus", 0.0)) > 0.0, "checkpoint mode adds time")

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
