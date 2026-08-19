extends SceneTree

var failures := 0

func _init() -> void:
	_test_single_file_round_trip()
	_test_directory_package_backwards_compatibility()
	if failures == 0:
		print("Pixel Track Works sharing tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works sharing tests: %d failure(s)" % failures)
		quit(1)

func _test_single_file_round_trip() -> void:
	var track: TrackData = ProceduralTrackGenerator.new().generate(551122, 40, "mixed", 0.65, "wide", 0.6)
	track.name = "Single File Round Trip"
	track.author = "QA"
	track.metadata["description"] = "Portable package regression"
	track.metadata["tags"] = ["mixed", "qa"]
	var preview_path := "user://sharing_test_preview.png"
	var preview_saved: bool = TrackPreviewGenerator.new().save(track, preview_path)
	_expect(preview_saved, "sharing test preview can be generated")
	var manager := TrackPackageManager.new()
	var package_path: String = manager.export_single_file(track, "user://test_track_exports", preview_path)
	_expect(not package_path.is_empty(), "single-file package exports")
	_expect(package_path.ends_with(".pixeltrack"), "single-file package uses .pixeltrack extension")
	_expect(FileAccess.file_exists(package_path), "single-file package exists on disk")
	var inspection: Dictionary = manager.inspect_single_file(package_path)
	_expect(bool(inspection.get("valid", false)), "single-file package validates")
	var metadata: Dictionary = inspection.get("metadata", {})
	_expect(str(metadata.get("name", "")) == track.name, "single-file metadata keeps track name")
	_expect(int(metadata.get("track_schema", -1)) == TrackData.SCHEMA_VERSION, "single-file metadata declares track schema")
	var imported: TrackData = manager.import_single_file(package_path) as TrackData
	_expect(imported != null, "single-file package imports")
	if imported != null:
		_expect(imported.name == track.name, "imported single-file track keeps name")
		_expect(imported.road_tiles.size() == track.road_tiles.size(), "imported single-file track keeps roads")
		_expect(FileAccess.file_exists("user://tracks/%s/preview.png" % imported.track_id), "single-file import restores preview")
	var duplicate: TrackData = manager.import_single_file(package_path) as TrackData
	_expect(duplicate != null, "duplicate single-file package can import")
	if duplicate != null and imported != null:
		_expect(duplicate.track_id != imported.track_id, "duplicate package import receives a new track ID")

func _test_directory_package_backwards_compatibility() -> void:
	var track: TrackData = ProceduralTrackGenerator.new().generate(77119, 36, "oval", 0.0, "standard", 0.0)
	track.name = "Directory Compatibility"
	var manager := TrackPackageManager.new()
	var package_dir: String = manager.export_package(track, "user://test_track_exports")
	_expect(not package_dir.is_empty(), "legacy directory package still exports")
	var inspection: Dictionary = manager.validate_package(package_dir)
	_expect(bool(inspection.get("valid", false)), "legacy directory package still validates")
	var imported: TrackData = manager.import_package(package_dir) as TrackData
	_expect(imported != null, "legacy directory package still imports")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
