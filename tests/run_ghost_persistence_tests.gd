extends SceneTree

var failures := 0

func _init() -> void:
	_test_best_ghost_survives_restart_style_reload()
	_test_corrupt_primary_recovers_backup()
	_test_interrupted_temp_recovers()
	if failures == 0:
		print("Pixel Track Works ghost persistence tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works ghost persistence tests: %d failure(s)" % failures)
		quit(1)

func _test_best_ghost_survives_restart_style_reload() -> void:
	var manager := GhostManager.new()
	var track_id := "qa-ghost-restart"
	var vehicle_id := "Hachiroku_Drifter"
	manager.delete_best(track_id, vehicle_id)
	var first_samples: Array[Dictionary] = _samples(0.0)
	_expect(manager.save_if_best(track_id, vehicle_id, "time_trial", 62.50, first_samples), "first best ghost saves")
	var reloaded_manager := GhostManager.new()
	_expect(is_equal_approx(reloaded_manager.best_ghost_time(track_id, vehicle_id), 62.50), "new manager instance reloads persisted best ghost")
	var recorder: GhostRecorder = reloaded_manager.load_recorder(track_id, vehicle_id)
	_expect(recorder != null and recorder.samples.size() == first_samples.size(), "persisted ghost recreates playback recorder")
	_expect(not reloaded_manager.save_if_best(track_id, vehicle_id, "time_trial", 63.00, _samples(5.0)), "slower lap cannot replace best ghost")
	_expect(reloaded_manager.save_if_best(track_id, vehicle_id, "time_trial", 59.25, _samples(10.0)), "faster completed lap replaces best ghost")
	var after_replace := GhostManager.new()
	_expect(is_equal_approx(after_replace.best_ghost_time(track_id, vehicle_id), 59.25), "replacement best survives another reload")
	manager.delete_best(track_id, vehicle_id)

func _test_corrupt_primary_recovers_backup() -> void:
	var manager := GhostManager.new()
	var track_id := "qa-ghost-backup"
	var vehicle_id := "Hachiroku_Drifter"
	manager.delete_best(track_id, vehicle_id)
	_expect(manager.save_if_best(track_id, vehicle_id, "time_trial", 70.0, _samples(0.0)), "backup test initial ghost saves")
	_expect(manager.save_if_best(track_id, vehicle_id, "time_trial", 68.0, _samples(2.0)), "backup test faster ghost saves and keeps prior backup")
	var path: String = manager.best_ghost_path(track_id, vehicle_id)
	_expect(FileAccess.file_exists("%s.bak" % path), "ghost save keeps last-known-good backup")
	_write_text(path, "{broken-ghost")
	var recovered: Dictionary = manager.load_payload(path)
	_expect(not recovered.is_empty(), "corrupt ghost primary falls back to backup")
	var metadata: Dictionary = recovered.get("metadata", {})
	_expect(is_equal_approx(float(metadata.get("lap_time", INF)), 70.0), "ghost backup returns previous best time")
	_expect(str(metadata.get("recovered_from", "")) == "backup", "ghost backup recovery is identified")
	manager.delete_best(track_id, vehicle_id)

func _test_interrupted_temp_recovers() -> void:
	var manager := GhostManager.new()
	var track_id := "qa-ghost-temp"
	var vehicle_id := "Hachiroku_Drifter"
	manager.delete_best(track_id, vehicle_id)
	var path: String = manager.best_ghost_path(track_id, vehicle_id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var payload := {
		"schema_version": GhostManager.GHOST_SCHEMA,
		"metadata": {
			"track_id": track_id,
			"vehicle_id": vehicle_id,
			"mode": "time_trial",
			"lap_time": 57.75,
			"sample_count": 3
		},
		"samples": _samples(4.0)
	}
	_write_text("%s.tmp" % path, JSON.stringify(payload, "\t"))
	var recovered: Dictionary = manager.load_payload(path)
	_expect(not recovered.is_empty(), "valid interrupted ghost temp file is recoverable")
	var metadata: Dictionary = recovered.get("metadata", {})
	_expect(str(metadata.get("recovered_from", "")) == "temporary_save", "ghost temp recovery is identified")
	manager.delete_best(track_id, vehicle_id)

func _samples(offset: float) -> Array[Dictionary]:
	return [
		{"t": 0.0, "x": offset, "y": 0.0, "heading": 0.0, "speed": 120.0},
		{"t": 0.1, "x": offset + 12.0, "y": 1.0, "heading": 0.05, "speed": 125.0},
		{"t": 0.2, "x": offset + 25.0, "y": 2.0, "heading": 0.08, "speed": 130.0}
	]

func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
		push_error("FAIL: could not write %s" % path)
		return
	file.store_string(value)
	file.flush()
	file.close()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
