extends SceneTree

const CatalogBuilderScript = preload("res://scripts/builder/catalog_builder_controller.gd")
const TrackDataScript = preload("res://scripts/track/track_data.gd")

var failures := 0

func _init() -> void:
	_test_logical_catalog_placement_round_trip()
	_finish()

func _test_logical_catalog_placement_round_trip() -> void:
	var track: TrackData = TrackDataScript.new()
	track.width = 16
	track.height = 16
	var builder: CatalogBuilderController = CatalogBuilderScript.new()
	builder.track = track
	builder.cursor_cell = Vector2i(4, 5)
	_expect(builder.select_catalog_asset("prop.tree.craftpix_01"), "builder selects logical catalog asset")
	builder._place_current()
	_expect(track.objects.size() == 1, "builder places catalog object into TrackData")
	if track.objects.size() == 1:
		_expect(str(track.objects[0].get("type", "")) == "prop.tree.craftpix_01", "TrackData stores logical asset ID instead of atlas/source filename")
	builder.clear_catalog_asset()
	builder.eyedropper()
	_expect(builder.selected_catalog_asset == "prop.tree.craftpix_01", "eyedropper restores exact logical catalog asset")
	var payload: Dictionary = track.to_dict()
	var restored: TrackData = TrackDataScript.new()
	restored.from_dict(payload)
	_expect(restored.objects.size() == 1, "catalog object survives track serialization")
	if restored.objects.size() == 1:
		_expect(str(restored.objects[0].get("type", "")) == "prop.tree.craftpix_01", "logical asset ID survives track round-trip")
	builder.free()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works builder catalog tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works builder catalog tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
