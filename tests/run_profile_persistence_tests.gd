extends SceneTree

var failures := 0

func _init() -> void:
	_test_atomic_profile_recovery()
	_test_garage_persistence_and_signals()
	_test_career_persistence_and_signals()
	if failures == 0:
		print("Pixel Track Works profile persistence tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works profile persistence tests: %d failure(s)" % failures)
		quit(1)

func _test_atomic_profile_recovery() -> void:
	var store := AtomicJsonStore.new()
	var path := "user://qa_atomic_profile.json"
	store.remove(path)
	_expect(store.save(path, {"version": 1, "credits": 100}), "atomic profile initial save succeeds")
	_expect(store.save(path, {"version": 2, "credits": 250}), "atomic profile replacement succeeds")
	_expect(FileAccess.file_exists("%s.bak" % path), "atomic profile replacement keeps a backup")
	_write_text(path, "{broken-profile")
	var recovered: Dictionary = store.load_result(path)
	_expect(str(recovered.get("recovered_from", "")) == "backup", "corrupt profile falls back to backup")
	var recovered_data: Dictionary = recovered.get("data", {})
	_expect(int(recovered_data.get("version", -1)) == 1, "profile backup is last-known-good data")
	_expect(store.save(path, {"version": 3, "credits": 400}), "recovered profile can repair primary safely")
	var repaired: Dictionary = store.load_result(path)
	_expect(str(repaired.get("recovered_from", "")) == "", "repaired profile loads from primary")
	_expect(int(Dictionary(repaired.get("data", {})).get("version", -1)) == 3, "repaired profile keeps new data")
	store.remove(path)

func _test_garage_persistence_and_signals() -> void:
	var store := AtomicJsonStore.new()
	store.remove(GarageManager.SAVE_PATH)
	var garage := GarageManager.new()
	garage.load_state()
	garage.state["owned"] = []
	garage.state["selected"] = ""
	var purchase_count := 0
	var upgrade_count := 0
	garage.vehicle_purchased.connect(func(_vehicle_id: String, _cost: int): purchase_count += 1)
	garage.upgrade_purchased.connect(func(_vehicle_id: String, _group: String, _level: int, _cost: int): upgrade_count += 1)
	var purchase: Dictionary = garage.purchase_vehicle("Hachiroku_Drifter", 100000)
	_expect(bool(purchase.get("success", false)), "garage purchase succeeds with sufficient credits")
	_expect(purchase_count == 1, "successful garage purchase emits exactly one progression signal")
	var upgrade: Dictionary = garage.purchase_upgrade("Hachiroku_Drifter", "engine", 100000)
	_expect(bool(upgrade.get("success", false)), "garage upgrade succeeds")
	_expect(upgrade_count == 1, "successful garage upgrade emits exactly one progression signal")
	var restored := GarageManager.new()
	restored.load_state()
	_expect(restored.is_owned("Hachiroku_Drifter"), "garage ownership survives manager reload")
	_expect(restored.upgrade_level("Hachiroku_Drifter", "engine") == 1, "garage upgrade survives manager reload")
	store.remove(GarageManager.SAVE_PATH)

func _test_career_persistence_and_signals() -> void:
	var store := AtomicJsonStore.new()
	store.remove(CareerManager.PROFILE_PATH)
	var career := CareerManager.new()
	var tier_events := 0
	var championship_events := 0
	career.tier_changed.connect(func(_previous: int, _current: int): tier_events += 1)
	career.championship_completed.connect(func(_id: String, _credits: int, _reputation: int): championship_events += 1)
	career.profile["reputation"] = 79
	career.profile["tier"] = 1
	career.add_race_reward(1, "circuit")
	_expect(tier_events == 1, "career tier promotion emits exactly one unlock signal")
	_expect(int(career.profile.get("tier", 0)) >= 2, "career reward promotes profile when threshold is crossed")
	var championship: Dictionary = career.complete_championship("backyard_cup", 1)
	_expect(bool(championship.get("success", false)), "eligible championship completion succeeds")
	_expect(championship_events == 1, "championship completion emits exactly one progression signal")
	var restored := CareerManager.new()
	_expect("backyard_cup" in Array(restored.profile.get("completed_championships", [])), "championship completion survives manager reload")
	_expect(int(restored.profile.get("reputation", 0)) == int(career.profile.get("reputation", -1)), "career reputation survives manager reload")
	store.remove(CareerManager.PROFILE_PATH)

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
