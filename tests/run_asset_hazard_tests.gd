extends SceneTree

const ArcadeVehicleScript = preload("res://scripts/vehicles/arcade_vehicle.gd")
const TrackHazardAreaScript = preload("res://scripts/track/track_hazard_area.gd")

var failures := 0

func _init() -> void:
	_test_oil_hazard_state()
	_test_hazard_area_contract()
	_finish()

func _test_oil_hazard_state() -> void:
	var vehicle = ArcadeVehicleScript.new()
	vehicle.input_enabled = false
	vehicle.heading = 0.0
	vehicle.velocity = Vector2(0.0, -240.0)
	var before := vehicle.velocity
	vehicle.apply_hazard("oil", 1.35)
	var state: Dictionary = vehicle.hazard_state()
	_expect(bool(state.get("active", false)), "oil hazard activates a temporary vehicle state")
	_expect(float(state.get("grip_scale", 1.0)) < 0.5, "oil hazard temporarily reduces grip")
	_expect(vehicle.velocity != before, "oil hazard applies a bounded lateral slip kick")
	vehicle._update_hazard(2.0)
	state = vehicle.hazard_state()
	_expect(not bool(state.get("active", true)), "oil hazard expires without changing TrackData")
	_expect(is_equal_approx(float(state.get("grip_scale", 0.0)), 1.0), "grip is restored after oil hazard expires")
	vehicle.free()

func _test_hazard_area_contract() -> void:
	var area = TrackHazardAreaScript.new()
	area.setup("oil", Vector2(34, 16))
	_expect(area.hazard_id == "oil", "hazard area retains logical hazard ID")
	_expect(area.collision_mask == 1, "hazard area monitors vehicle collision layer")
	_expect(area.get_child_count() == 1 and area.get_child(0) is CollisionShape2D, "hazard area owns explicit trigger collision")
	area.free()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works asset hazard tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works asset hazard tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
