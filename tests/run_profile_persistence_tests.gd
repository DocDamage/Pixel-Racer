extends SceneTree

const ATOMIC_TEST_PATH := "user://qa_atomic_profile.json"
const GARAGE_TEST_PATH := "user://qa_garage_profile.json"
const CAREER_TEST_PATH := "user://qa_career_profile.json"
const PURCHASE_VEHICLE_ID := "Midnight_Godzilla"

var failures := 0
var garage_purchase_events := 0
var garage_upgrade_events := 0
var career_tier_events := 0
var career_championship_events := 0

func _init() -> void:
	_test_atomic_profile_recovery()
	_test_garage_persistence_and_signals()
	_test_career_persistence_and_signals()
	_cleanup()
	if failures == 0:
		print("Pixel Track Works profile persistence tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works profile persistence tests: %d failure(s)" % failures)
		quit(1)

func _test_atomic_profile_recovery() -> void:
	var store := AtomicJsonStore.new()
	store.remove(ATOMIC_TEST_PATH)
	_expect(store.save(ATOMIC_TEST_PATH, {"version": 1, "credits": 100}), "atomic profile initial save succeeds")
	_expect(store.save(ATOMIC_TEST_PATH, {"version": 2, "credits": 250}), "atomic profile replacement succeeds")
	_expect(FileAccess.file_exists("%s.bak" % ATOMIC_TEST_PATH), "atomic profile replacement keeps a backup")
	_write_text(ATOMIC_TEST_PATH, "{broken-profile")
	var recovered: Dictionary = store.load_result(ATOMIC_TEST_PATH)
	_expect(str(recovered.get("recovered_from", "")) == "backup", "corrupt profile falls back to backup")
	var recovered_data: Dictionary = recovered.get("data", {})
	_expect(int(recovered_data.get("version", -1)) == 1, "profile backup is last-known-good data")
	_expect(store.save(ATOMIC_TEST_PATH, {"version": 3, "credits": 400}), "recovered profile can repair primary safely")
	var repaired: Dictionary = store.load_result(ATOMIC_TEST_PATH)
	_expect(str(repaired.get("recovered_from", "")) == "", "repaired profile loads from primary")
	_expect(int(Dictionary(repaired.get("data", {})).get("version", -1)) == 3, "repaired profile keeps new data")

func _test_garage_persistence_and_signals() -> void:
	var store := AtomicJsonStore.new()
	store.remove(GARAGE_TEST_PATH)
	garage_purchase_events = 0
	garage_upgrade_events = 0
	var garage := GarageManager.new(GARAGE_TEST_PATH)
	garage.vehicle_purchased.connect(_on_vehicle_purchased)
	garage.upgrade_purchased.connect(_on_upgrade_purchased)
	var purchase: Dictionary = garage.purchase_vehicle(PURCHASE_VEHICLE_ID, 100000)
	_expect(bool(purchase.get("success", false)), "garage purchase succeeds with sufficient credits")
	_expect(garage_purchase_events == 1, "successful garage purchase emits exactly one progression signal")
	var upgrade: Dictionary = garage.purchase_upgrade(PURCHASE_VEHICLE_ID, "engine", 100000)
	_expect(bool(upgrade.get("success", false)), "garage upgrade succeeds")
	_expect(garage_upgrade_events == 1, "successful garage upgrade emits exactly one progression signal")
	_expect(FileAccess.file_exists("%s.bak" % GARAGE_TEST_PATH), "garage replacement save keeps an atomic backup")
	var restored := GarageManager.new(GARAGE_TEST_PATH)
	_expect(restored.is_owned(PURCHASE_VEHICLE_ID), "garage ownership survives manager reload")
	_expect(restored.upgrade_level(PURCHASE_VEHICLE_ID, "engine") == 1, "garage upgrade survives manager reload")

func _test_career_persistence_and_signals() -> void:
	var store := AtomicJsonStore.new()
	store.remove(CAREER_TEST_PATH)
	career_tier_events = 0
	career_championship_events = 0
	var career := CareerManager.new(CAREER_TEST_PATH)
	career.tier_changed.connect(_on_tier_changed)
	career.championship_completed.connect(_on_championship_completed)
	career.profile["reputation"] = 349
	career.profile["tier"] = 1
	career.profile["completed_championships"] = []
	_expect(career.save_profile(), "career baseline save succeeds at the promotion boundary")
	var completed := career.complete_championship("backyard_cup", 1)
	_expect(completed, "eligible championship completion succeeds")
	_expect(career_tier_events == 1, "career tier promotion emits exactly one unlock signal")
	_expect(career_championship_events == 1, "championship completion emits exactly one progression signal")
	_expect(int(career.profile.get("tier", 0)) >= 2, "championship reward promotes profile when threshold is crossed")
	_expect(FileAccess.file_exists("%s.bak" % CAREER_TEST_PATH), "career replacement save keeps an atomic backup")
	var restored := CareerManager.new(CAREER_TEST_PATH)
	_expect("backyard_cup" in Array(restored.profile.get("completed_championships", [])), "championship completion survives manager reload")
	_expect(int(restored.profile.get("reputation", 0)) == int(career.profile.get("reputation", -1)), "career reputation survives manager reload")
	_expect(int(restored.profile.get("tier", 0)) == int(career.profile.get("tier", -1)), "career tier survives manager reload")

func _on_vehicle_purchased(_vehicle_id: String, _cost: int) -> void:
	garage_purchase_events += 1

func _on_upgrade_purchased(_vehicle_id: String, _group: String, _level: int, _cost: int) -> void:
	garage_upgrade_events += 1

func _on_tier_changed(_previous: int, _current: int) -> void:
	career_tier_events += 1

func _on_championship_completed(_id: String, _credits: int, _reputation: int) -> void:
	career_championship_events += 1

func _cleanup() -> void:
	var store := AtomicJsonStore.new()
	for path in [ATOMIC_TEST_PATH, GARAGE_TEST_PATH, CAREER_TEST_PATH]:
		store.remove(path)

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
