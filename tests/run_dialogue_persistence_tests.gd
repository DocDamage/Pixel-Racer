extends SceneTree

var failures := 0

func _init() -> void:
	_test_once_only_state_survives_restart_style_reload()
	_test_dialogue_state_recovers_from_backup()
	if failures == 0:
		print("Pixel Track Works dialogue persistence tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works dialogue persistence tests: %d failure(s)" % failures)
		quit(1)

func _test_once_only_state_survives_restart_style_reload() -> void:
	var store := DialogueStateStore.new()
	store.clear_state()
	var state := {"once_seen": ["builder_first_entry", "story_intro"]}
	_expect(store.save_state(state), "dialogue once-only state saves atomically")
	var restored := DialogueStateStore.new().load_state()
	_expect(Array(restored.get("once_seen", [])).has("builder_first_entry"), "dialogue once-only state survives a new store instance")
	_expect(Array(restored.get("once_seen", [])).has("story_intro"), "multiple once-only flags survive reload")
	store.clear_state()

func _test_dialogue_state_recovers_from_backup() -> void:
	var store := DialogueStateStore.new()
	store.clear_state()
	_expect(store.save_state({"once_seen": ["first"]}), "dialogue backup test initial state saves")
	_expect(store.save_state({"once_seen": ["first", "second"]}), "dialogue backup test replacement saves")
	_expect(FileAccess.file_exists("%s.bak" % DialogueStateStore.SAVE_PATH), "dialogue replacement keeps last-known-good backup")
	var file := FileAccess.open(DialogueStateStore.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "dialogue primary can be opened for corruption test")
		return
	file.store_string("{broken-dialogue-state")
	file.flush()
	file.close()
	var recovered := DialogueStateStore.new().load_state()
	_expect(Array(recovered.get("once_seen", [])).has("first"), "corrupt dialogue primary recovers previous valid state")
	_expect(not Array(recovered.get("once_seen", [])).has("second"), "dialogue backup recovery returns the last-known-good version")
	var repaired := DialogueStateStore.new().load_state()
	_expect(Array(repaired.get("once_seen", [])).has("first"), "recovered dialogue state is promoted back to a valid primary")
	store.clear_state()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
