extends SceneTree

var failures := 0

func _init() -> void:
	_test_backup_recovery()
	_test_temp_recovery()
	_test_future_schema_rejection()
	_test_corrupt_import_rejection()
	if failures == 0:
		print("Pixel Track Works save recovery tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works save recovery tests: %d failure(s)" % failures)
		quit(1)

func _test_backup_recovery() -> void:
	var track := ProceduralTrackGenerator.new().generate(20260819, 40, "circuit", 0.45, "standard", 0.2)
	track.track_id = "qa-backup-recovery"
	track.name = "Backup Version One"
	SaveManager.delete_track(track.track_id)
	_expect(SaveManager.save_track(track), "initial track save succeeds")
	track.name = "Backup Version Two"
	track.dirty = true
	_expect(SaveManager.save_track(track), "second track save succeeds and creates backup")
	var final_path := "user://tracks/%s/track.json" % track.track_id
	var backup_path := "%s.bak" % final_path
	_expect(FileAccess.file_exists(backup_path), "second save retains last-known-good backup")
	_write_text(final_path, "{broken-json")
	var recovered: TrackData = SaveManager.load_track(track.track_id) as TrackData
	_expect(recovered != null, "corrupt primary falls back to backup")
	if recovered != null:
		_expect(recovered.name == "Backup Version One", "backup recovery returns last-known-good state")
		_expect(str(recovered.metadata.get("recovered_from", "")) == "backup", "backup recovery is explicitly identified")
		_expect(recovered.dirty, "recovered backup is marked dirty for repair save")
		recovered.name = "Recovered And Repaired"
		_expect(SaveManager.save_track(recovered), "recovered backup can safely repair primary")
		var repaired: TrackData = SaveManager.load_track(track.track_id) as TrackData
		_expect(repaired != null and repaired.name == "Recovered And Repaired", "repaired primary loads normally")
	SaveManager.delete_track(track.track_id)

func _test_temp_recovery() -> void:
	var track := ProceduralTrackGenerator.new().generate(271828, 36, "mixed", 0.55, "narrow", 0.0)
	track.track_id = "qa-temp-recovery"
	track.name = "Temp Recovery"
	SaveManager.delete_track(track.track_id)
	var track_dir := "user://tracks/%s" % track.track_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(track_dir))
	var final_path := "%s/track.json" % track_dir
	var temp_path := "%s.tmp" % final_path
	_write_text(temp_path, JSON.stringify(track.to_dict(), "\t"))
	var recovered: TrackData = SaveManager.load_track(track.track_id) as TrackData
	_expect(recovered != null, "valid interrupted temp save can be recovered")
	if recovered != null:
		_expect(str(recovered.metadata.get("recovered_from", "")) == "temporary_save", "temp recovery is explicitly identified")
		_expect(recovered.dirty, "temp recovery is marked dirty for promotion")
	SaveManager.delete_track(track.track_id)

func _test_future_schema_rejection() -> void:
	var track := ProceduralTrackGenerator.new().generate(314159, 36, "oval", 0.0, "standard", 0.0)
	var payload: Dictionary = track.to_dict()
	payload["schema_version"] = TrackData.SCHEMA_VERSION + 99
	var path := "user://future_schema_track.json"
	_write_text(path, JSON.stringify(payload, "\t"))
	var loaded: TrackData = SaveManager.load_track_path(path) as TrackData
	_expect(loaded == null, "future schema track is rejected instead of guessed")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_corrupt_import_rejection() -> void:
	var path := "user://corrupt_import_track.json"
	_write_text(path, "not-json")
	var imported: TrackData = SaveManager.import_track(path) as TrackData
	_expect(imported == null, "corrupt JSON import is rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
		push_error("FAIL: could not open %s for write" % path)
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
