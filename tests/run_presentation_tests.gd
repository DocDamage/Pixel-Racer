extends SceneTree

var failures := 0

func _init() -> void:
	_test_dialogue_entry_contract()
	_test_dialogue_priority_and_once_state()
	_test_dialogue_conditions_and_cooldown()
	_test_unmeasured_character_manifest_stays_disabled()
	_test_collision_fx_is_globally_bounded()
	if failures == 0:
		print("Pixel Track Works presentation tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works presentation tests: %d failure(s)" % failures)
		quit(1)

func _test_dialogue_entry_contract() -> void:
	var entry := DialogueEntry.from_dict({
		"id": "contract",
		"speaker_id": "crew_chief",
		"portrait_id": "crew",
		"text": "Keep it clean.",
		"event": "test",
		"priority": 7,
		"duration": 2.5,
		"blocking": true,
		"condition": "race_ready",
		"once_only": true,
		"cooldown": 10.0
	})
	_expect(entry.id == "contract", "dialogue entry keeps stable ID")
	_expect(entry.speaker_id == "crew_chief", "dialogue entry keeps speaker")
	_expect(entry.portrait_id == "crew", "dialogue entry keeps portrait ID")
	_expect(entry.priority == 7 and entry.blocking and entry.once_only, "dialogue entry keeps queue semantics")
	_expect(is_equal_approx(entry.duration, 2.5) and is_equal_approx(entry.cooldown, 10.0), "dialogue entry keeps timing semantics")

func _test_dialogue_priority_and_once_state() -> void:
	var manager := DialogueManager.new()
	root.add_child(manager)
	manager.queue_dict({"id": "hold", "speaker_id": "host", "text": "Hold", "blocking": true})
	manager.queue_dict({"id": "low", "speaker_id": "host", "text": "Low", "blocking": true, "priority": 1})
	manager.queue_dict({"id": "high", "speaker_id": "host", "text": "High", "blocking": true, "priority": 20, "once_only": true})
	manager.advance()
	_expect(manager.active_entry() != null and manager.active_entry().id == "high", "queued dialogue resolves highest priority first")
	manager.advance()
	_expect(manager.active_entry() != null and manager.active_entry().id == "low", "lower-priority dialogue remains queued")
	var state: Dictionary = manager.serialize_state()
	manager.queue_free()

	var restored := DialogueManager.new()
	root.add_child(restored)
	restored.load_state(state)
	var accepted: bool = restored.queue_dict({"id": "high", "speaker_id": "host", "text": "High again", "blocking": true, "once_only": true})
	_expect(not accepted, "once-only dialogue survives state serialization")
	restored.queue_free()

func _test_dialogue_conditions_and_cooldown() -> void:
	var manager := DialogueManager.new()
	root.add_child(manager)
	manager.set_condition("race_ready", false)
	var blocked: bool = manager.queue_dict({"id": "condition", "speaker_id": "host", "text": "No", "condition": "race_ready", "blocking": true})
	_expect(not blocked, "false dialogue condition blocks enqueue")
	manager.set_condition("race_ready", true)
	var allowed: bool = manager.queue_dict({"id": "cooldown", "speaker_id": "host", "text": "Yes", "condition": "race_ready", "blocking": true, "cooldown": 30.0})
	_expect(allowed, "true dialogue condition allows enqueue")
	manager.advance()
	var repeated: bool = manager.queue_dict({"id": "cooldown", "speaker_id": "host", "text": "Again", "blocking": true, "cooldown": 30.0})
	_expect(not repeated, "dialogue cooldown prevents immediate spam")
	manager.queue_free()

func _test_unmeasured_character_manifest_stays_disabled() -> void:
	var catalog := CharacterCatalog.new()
	catalog.load_manifest()
	_expect(not catalog.measured, "character manifest remains explicitly unmeasured")
	_expect(not catalog.is_runtime_ready(), "unmeasured character assets cannot silently activate")
	var issues: Array[String] = catalog.validation_issues()
	_expect(not issues.is_empty(), "unmeasured character assets report actionable validation issues")

func _test_collision_fx_is_globally_bounded() -> void:
	var fx := CollisionFX.new()
	root.add_child(fx)
	for index in range(40):
		fx.emit_impact(Vector2(index, index), Vector2.UP, 1.0)
	_expect(fx.particle_count() <= CollisionFX.MAX_PARTICLES, "collision FX particle pool remains bounded")
	fx.queue_free()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
