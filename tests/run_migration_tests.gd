extends SceneTree

var failures := 0

func _init() -> void:
	_test_v1_to_v2_migration()
	_test_future_schema_best_effort_normalization()
	if failures == 0:
		print("Pixel Track Works migration tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works migration tests: %d failure(s)" % failures)
		quit(1)

func _test_v1_to_v2_migration() -> void:
	var legacy := {
		"schema_version": 1,
		"track_id": "legacy-v1",
		"name": "Legacy Ring",
		"author": "Player",
		"width": 24,
		"height": 24,
		"cell_size": 64,
		"terrain": [],
		"road_tiles": [{"x": 5, "y": 5, "type": "asphalt", "connection_mask": 0, "variant": 0}],
		"objects": [],
		"race_objects": [],
		"event_presets": [],
		"metadata": {"difficulty": 2}
	}
	var track := TrackData.new()
	track.from_dict(legacy)
	_expect(track.schema_version == TrackData.SCHEMA_VERSION, "legacy track is upgraded to current schema")
	_expect(str(track.get_road(Vector2i(5, 5)).get("width", "")) == "standard", "migration adds road width")
	_expect(track.get_route_id(Vector2i(5, 5)) == "main", "migration adds main route ID")
	_expect(track.route_definition("main").get("type", "") == "main", "migration creates main route definition")
	_expect(int(track.metadata.get("migrated_from_schema", 0)) == 1, "migration records source schema")
	_expect(int(track.to_dict().get("schema_version", 0)) == TrackData.SCHEMA_VERSION, "resaved track emits current schema")

func _test_future_schema_best_effort_normalization() -> void:
	var future := {
		"schema_version": 99,
		"track_id": "future-track",
		"name": "Future Track",
		"width": 24,
		"height": 24,
		"terrain": [],
		"road_tiles": [],
		"objects": [],
		"race_objects": [],
		"event_presets": [],
		"metadata": {}
	}
	var track := TrackData.new()
	track.from_dict(future)
	_expect(track.schema_version == TrackData.SCHEMA_VERSION, "future schema loads into current normalized model")
	_expect(int(track.metadata.get("source_schema_version", 0)) == 99, "future source version is retained for diagnostics")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
