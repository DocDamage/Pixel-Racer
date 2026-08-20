extends SceneTree

const DIALOGUE_TEST_PATH := "user://qa_dialogue_state.json"

var failures := 0

func _init() -> void:
	_test_once_only_state_survives_restart_style_reload()
	_test_dialogue_state_recovers_from_backup()
	DialogueStateStore.new(DIALOGUE_TEST_PATH).clear_state()
	if failures == 0:
		print("Pixel Track Works dialogue persistence tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works dialogue persistence tests: %d failure(s)" % failures)
		quit(1)

func _test_once_only_state_survives_restart_style_reload() -> void:
	var store := DialogueStateStore.new(DIALOGUE_TEST_PATH)
	store.clear_state()
	var state := {"seen_once": ["builder_first_entry", "story_intro"]}
	_expect(store.save_state(state), "dialogue once-only state saves atomically")
	var restored := DialogueStateStore.new(DIALOGUE_TEST_PATH).load_state()
	_expect(Array(restored.get("seen_once", [])).has("builder_first_entry"), "dialogue once-only state survives a new store instance")
	_expect(Array(restored.get("seen_once", [])).has("story_intro"), "multiple once-only flags survive reload")
	store.clear_state()

func _test_dialogue_state_recovers_from_backup() -> void:
	var store := DialogueStateStore.new(DIALOGUE_TEST_PATH)
	store.clear_state()
	_expect(store.save_state({"seen_once": ["first"]}), "dialogue backup test initial state saves")
	_expect(store.save_state({"seen_once": ["first", "second"]}), "dialogue backup test replacement saves")
	_expect(FileAccess.file_exists("%s.bak" % DIALOGUE_TEST_PATH), "dialogue replacement keeps last-known-good backup")
	var file := FileAccess.open(DIALOGUE_TEST_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "dialogue primary can be opened for corruption test")
		return
	file.store_string("{broken-dialogue-state")
	file.flush()
	file.close()
	var recovered := DialogueStateStore.new(DIALOGUE_TEST_PATH).load_state()
	_expect(Array(recovered.get("seen_once", [])).has("first"), "corrupt dialogue primary recovers previous valid state")
	_expect(not Array(recovered.get("seen_once", [])).has("second"), "dialogue backup recovery returns the last-known-good version")
	var repaired := DialogueStateStore.new(DIALOGUE_TEST_PATH).load_state()
	_expect(Array(repaired.get("seen_once", [])).has("first"), "recovered dialogue state is promoted back to a valid primary")
	_expect(not Array(repaired.get("seen_once", [])).has("second"), "promoted dialogue primary preserves recovered state")
	store.clear_state()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
