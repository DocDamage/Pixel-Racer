extends Node
class_name ReleaseSelfTest

const FLAG := "--release-self-test"
const TEST_TRACK_ID := "ptw-packaged-self-test"
const TEST_VEHICLE_ID := "Hachiroku_Drifter"
const TEST_PROFILE_PATH := "user://ptw_release_self_test_profile.json"
const TEST_EXPORT_ROOT := "user://ptw_release_self_test_exports"

var failures: Array[String] = []

func _ready() -> void:
	if FLAG not in OS.get_cmdline_user_args():
		return
	call_deferred("_run")

func _run() -> void:
	print("PACKAGED SELF TEST: START")
	_test_track_round_trip()
	_test_ghost_round_trip()
	_test_atomic_recovery()
	_test_package_round_trip()
	_cleanup()
	if failures.is_empty():
		print("PACKAGED SELF TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error("PACKAGED SELF TEST: %s" % failure)
	print("PACKAGED SELF TEST: FAIL (%d)" % failures.size())
	get_tree().quit(1)

func _test_track_round_trip() -> void:
	SaveManager.delete_track(TEST_TRACK_ID)
	var track: TrackData = ProceduralTrackGenerator.new().generate(260819, 40, "mixed", 0.62, "standard", 0.25)
	track.track_id = TEST_TRACK_ID
	track.name = "Packaged Self Test"
	if not SaveManager.save_track(track):
		_fail("track save failed")
		return
	var loaded: TrackData = SaveManager.load_track(TEST_TRACK_ID) as TrackData
	if loaded == null:
		_fail("track reload failed")
		return
	if loaded.road_tiles.size() != track.road_tiles.size():
		_fail("track reload changed road count")
	var validation: Dictionary = TrackValidator.new().validate(loaded)
	if not bool(validation.get("raceable", false)):
		_fail("reloaded generated track is not raceable")

func _test_ghost_round_trip() -> void:
	var manager := GhostManager.new()
	manager.delete_best(TEST_TRACK_ID, TEST_VEHICLE_ID, "time_trial")
	var samples: Array[Dictionary] = [
		{"t": 0.0, "x": 10.0, "y": 10.0, "heading": 0.0, "speed": 120.0},
		{"t": 0.1, "x": 22.0, "y": 10.5, "heading": 0.03, "speed": 125.0},
		{"t": 0.2, "x": 35.0, "y": 11.5, "heading": 0.05, "speed": 130.0}
	]
	if not manager.save_if_best(TEST_TRACK_ID, TEST_VEHICLE_ID, "time_trial", 61.25, samples):
		_fail("ghost save failed")
		return
	var fresh_manager := GhostManager.new()
	if not is_equal_approx(fresh_manager.best_ghost_time(TEST_TRACK_ID, TEST_VEHICLE_ID, "time_trial"), 61.25):
		_fail("ghost reload time mismatch")
	var recorder: GhostRecorder = fresh_manager.load_recorder(TEST_TRACK_ID, TEST_VEHICLE_ID, "time_trial")
	if recorder == null or recorder.samples.size() != samples.size():
		_fail("ghost recorder reload failed")

func _test_atomic_recovery() -> void:
	var store := AtomicJsonStore.new()
	store.remove(TEST_PROFILE_PATH)
	if not store.save(TEST_PROFILE_PATH, {"version": 1, "credits": 100}):
		_fail("atomic profile first save failed")
		return
	if not store.save(TEST_PROFILE_PATH, {"version": 2, "credits": 250}):
		_fail("atomic profile replacement failed")
		return
	var file := FileAccess.open(TEST_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		_fail("could not open atomic profile for recovery test")
		return
	file.store_string("{broken-packaged-profile")
	file.flush()
	file.close()
	var recovered: Dictionary = store.load_result(TEST_PROFILE_PATH)
	if str(recovered.get("recovered_from", "")) != "backup":
		_fail("atomic profile did not recover from backup")
		return
	var data: Dictionary = recovered.get("data", {})
	if int(data.get("version", -1)) != 1:
		_fail("atomic profile backup payload mismatch")

func _test_package_round_trip() -> void:
	var track: TrackData = SaveManager.load_track(TEST_TRACK_ID) as TrackData
	if track == null:
		_fail("sharing test could not reload source track")
		return
	var preview_path := "user://tracks/%s/preview.png" % TEST_TRACK_ID
	if not TrackPreviewGenerator.new().save(track, preview_path):
		_fail("sharing preview save failed")
		return
	var manager := TrackPackageManager.new()
	var package_path: String = manager.export_single_file(track, TEST_EXPORT_ROOT, preview_path)
	if package_path.is_empty() or not FileAccess.file_exists(package_path):
		_fail(".pixeltrack export failed")
		return
	var inspection: Dictionary = manager.inspect_single_file(package_path)
	if not bool(inspection.get("valid", false)):
		_fail(".pixeltrack inspection failed")
		return
	var imported: TrackData = manager.import_single_file(package_path) as TrackData
	if imported == null:
		_fail(".pixeltrack import failed")
		return
	if imported.track_id == TEST_TRACK_ID:
		_fail("duplicate .pixeltrack import did not receive a new ID")
	SaveManager.delete_track(imported.track_id)

func _cleanup() -> void:
	SaveManager.delete_track(TEST_TRACK_ID)
	GhostManager.new().delete_best(TEST_TRACK_ID, TEST_VEHICLE_ID, "time_trial")
	AtomicJsonStore.new().remove(TEST_PROFILE_PATH)
	_remove_tree(TEST_EXPORT_ROOT)

func _remove_tree(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child: String = path.path_join(name)
			if dir.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(child))
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute)

func _fail(message: String) -> void:
	failures.append(message)
