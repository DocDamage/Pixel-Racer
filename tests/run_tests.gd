extends SceneTree

const SaveManagerScript = preload("res://autoload/save_manager.gd")
const SettingsManagerScript = preload("res://autoload/settings_manager.gd")
const InputManagerScript = preload("res://autoload/input_manager.gd")

var failures := 0

func _init() -> void:
	_test_smart_road_masks()
	_test_surface_painting()
	_test_serialization_round_trip()
	_test_validation()
	_test_route_semantics()
	_test_builder_clipboard()
	_test_draw_track_tool()
	_test_rating_and_preview()
	_test_environment_catalog()
	_test_garage_model()
	_test_career_model()
	_test_record_model()
	_test_track_package()
	_test_save_delete()
	_test_race_mode_catalog()
	_test_procedural_generator()
	_test_accessibility_model()
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

func _test_surface_painting() -> void:
	var track := TrackData.new()
	var cell := Vector2i(5, 5)
	track.set_road(cell, "asphalt", "wide")
	track.set_road_metadata(cell, {"route_id": "pit", "is_pit": true})
	track.set_terrain(cell, "dirt")
	_expect(track.get_surface_at(cell) == "dirt", "surface brush converts driveable road surface")
	_expect(str(track.get_road(cell).get("width", "")) == "wide", "surface painting preserves width")
	_expect(str(track.get_road(cell).get("route_id", "")) == "pit", "surface painting preserves route metadata")

func _test_serialization_round_trip() -> void:
	var source := ProceduralTrackGenerator.new().create_demo_track()
	var encoded := source.to_dict()
	var loaded := TrackData.new()
	loaded.from_dict(encoded)
	_expect(loaded.name == source.name, "track name survives round-trip")
	_expect(loaded.road_tiles.size() == source.road_tiles.size(), "roads survive round-trip")
	_expect(loaded.get_checkpoints_sorted().size() == 3, "checkpoints survive round-trip")
	_expect(loaded.route_ids().has("main"), "route metadata survives migration")

func _test_validation() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	var result := TrackValidator.new().validate(track)
	_expect(bool(result["raceable"]), "demo track is raceable")
	track.remove_road(Vector2i(6, 8))
	result = TrackValidator.new().validate(track)
	_expect(not bool(result["raceable"]), "broken loop is rejected")

func _test_route_semantics() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	var pit_cells: Array[Vector2i] = [
		Vector2i(10, 19), Vector2i(10, 18), Vector2i(11, 18), Vector2i(12, 18),
		Vector2i(13, 18), Vector2i(14, 18), Vector2i(15, 18), Vector2i(15, 19)
	]
	for cell in pit_cells:
		track.set_road(cell, "asphalt", "narrow")
	var route_ops := RouteOps.new()
	_expect(route_ops.mark_pit_lane(track, pit_cells, 90.0) == pit_cells.size(), "pit tool assigns all bypass cells")
	var summary := route_ops.route_summary(track, "pit")
	_expect(bool(summary.get("simple_path", false)), "pit bypass is a simple route path")
	_expect(Array(summary.get("interfaces", [])).size() == 2, "pit bypass has exactly two main-route interfaces")
	var result := TrackValidator.new().validate(track)
	_expect(bool(result["raceable"]), "well-formed pit bypass keeps official circuit valid")
	var start := track.get_start_object()
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var main_graph := TrackGraph.new()
	main_graph.build(track, "main")
	_expect(main_graph.is_single_loop(start_cell), "AI/main graph ignores optional bypass branches")
	var encoded := track.to_dict()
	var loaded := TrackData.new()
	loaded.from_dict(encoded)
	_expect(str(loaded.route_definition("pit").get("type", "")) == "pit", "pit route definition survives serialization")
	_expect(float(loaded.route_definition("pit").get("speed_limit", 0.0)) == 90.0, "pit speed limit survives serialization")
	track.remove_road(Vector2i(12, 18))
	result = TrackValidator.new().validate(track)
	_expect(not bool(result["raceable"]), "broken optional bypass is rejected")

func _test_builder_clipboard() -> void:
	var track := TrackData.new()
	track.set_road(Vector2i(2, 2))
	track.set_road(Vector2i(3, 2))
	track.set_terrain(Vector2i(2, 3), "sand")
	track.add_object("barrier_red", Vector2i(3, 3), 1)
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

func _test_environment_catalog() -> void:
	_expect(EnvironmentCatalog.ids().size() >= 6, "environment catalog exposes bundled barriers and tire")
	_expect(str(EnvironmentCatalog.get_item("barrier_green").get("texture", "")).ends_with("barrier_green.png"), "environment catalog resolves bundled texture")
	_expect(bool(EnvironmentCatalog.get_item("tire").get("dynamic", false)), "loose tire is configured as dynamic")

func _test_garage_model() -> void:
	var garage := GarageManager.new()
	_expect(garage.vehicle_price("Hachiroku_Drifter") > 0, "garage derives vehicle prices")
	var definition := garage.effective_definition("Hachiroku_Drifter")
	_expect(definition.has("stats") and definition.has("tuning"), "garage produces effective tuned definition")
	_expect(garage.tier_name("Hachiroku_Drifter", "engine") in GarageManager.TIER_NAMES, "garage exposes upgrade tier names")

func _test_career_model() -> void:
	var career := CareerManager.new()
	_expect(CareerManager.TIERS.size() == 7, "career defines seven progression tiers")
	_expect(str(career.tier_info(7).get("name", "")) == "Track Architect", "career ends at Track Architect")
	_expect(career.contracts.size() >= 10, "career includes broad builder contracts")
	_expect(career.championships.size() == 7, "career has one championship definition per tier")

func _test_record_model() -> void:
	var records := RecordManager.new()
	var test_id := "ci-test-%s" % Time.get_ticks_msec()
	_expect(records.record_lap(test_id, "Hachiroku_Drifter", "time_trial", 42.5), "record manager accepts first lap")
	_expect(not records.record_lap(test_id, "Hachiroku_Drifter", "time_trial", 45.0), "record manager rejects slower lap")
	_expect(records.record_score(test_id, "Hachiroku_Drifter", "drift", 1000.0), "record manager accepts drift score")
	_expect(not records.record_score(test_id, "Hachiroku_Drifter", "drift", 900.0), "record manager rejects lower drift score")

func _test_track_package() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	track.track_id = "ci-package-track-%s" % Time.get_ticks_msec()
	var root := "user://ci_packages"
	var manager := TrackPackageManager.new()
	var package_dir := manager.export_package(track, root)
	_expect(not package_dir.is_empty(), "track package exports")
	var result := manager.validate_package(package_dir)
	_expect(bool(result.get("valid", false)), "exported track package validates")
	var imported = manager.import_package(package_dir)
	_expect(imported != null, "track package imports")
	if imported != null:
		var save_manager = SaveManagerScript.new()
		save_manager.delete_track(imported.track_id)

func _test_save_delete() -> void:
	var save_manager = SaveManagerScript.new()
	var track := ProceduralTrackGenerator.new().create_demo_track()
	track.track_id = "ci-delete-%s" % Time.get_ticks_msec()
	_expect(save_manager.save_track(track), "save manager writes track")
	_expect(save_manager.load_track(track.track_id) != null, "saved track loads")
	_expect(save_manager.delete_track(track.track_id), "save manager deletes track folder")
	_expect(save_manager.load_track(track.track_id) == null, "deleted track no longer loads")

func _test_race_mode_catalog() -> void:
	for mode in ["circuit", "time_trial", "sprint", "checkpoint", "drift", "elimination"]:
		_expect(RaceModeCatalog.MODES.has(mode), "race mode %s is registered" % mode)
	_expect(int(RaceModeCatalog.get_mode("circuit").get("laps", 0)) == 3, "circuit preset carries lap count")
	_expect(float(RaceModeCatalog.get_mode("checkpoint").get("checkpoint_bonus", 0.0)) > 0.0, "checkpoint mode adds time")
	_expect(int(RaceModeCatalog.get_mode("elimination").get("ai_count", 0)) >= 5, "elimination preset supplies a race field")

func _test_procedural_generator() -> void:
	for seed_value in [1, 2, 3, 99, 2026]:
		var track := ProceduralTrackGenerator.new().generate(seed_value, 40)
		var result := TrackValidator.new().validate(track)
		_expect(bool(result["raceable"]), "generated seed %d is raceable" % seed_value)
		_expect(str(track.metadata.get("generator_style", "")) == "circuit", "generated seed %d records its style" % seed_value)
	var rally := ProceduralTrackGenerator.new().generate(77, 44, "rally")
	var rally_result := TrackValidator.new().validate(rally)
	var rally_rating := TrackRating.new().calculate(rally)
	_expect(bool(rally_result["raceable"]), "generated rally track is raceable")
	_expect(int(rally_rating.get("offroad_percent", 0)) >= 25, "rally generator applies loose road surfaces")

func _test_accessibility_model() -> void:
	var settings_manager = SettingsManagerScript.new()
	var input_manager = InputManagerScript.new()
	_expect(settings_manager.defaults.has("ui_scale"), "settings include UI scale")
	_expect(settings_manager.defaults.has("controller_vibration"), "settings include vibration control")
	_expect(settings_manager.defaults.has("flash_intensity"), "settings include flash reduction")
	_expect(input_manager.ACTIONS.has("accelerate"), "input manager exposes remappable driving actions")
	_expect(input_manager.ACTIONS.has("builder_place"), "input manager exposes remappable builder actions")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
