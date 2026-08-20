extends SceneTree

const AssignmentScript = preload("res://scripts/race/race_team_assignment.gd")
const VehicleScript = preload("res://scripts/vehicles/arcade_vehicle.gd")

var failures := 0

func _init() -> void:
	_test_deterministic_team_assignment()
	_finish()

func _test_deterministic_team_assignment() -> void:
	var allocator: RaceTeamAssignment = AssignmentScript.new()
	var first: Dictionary = allocator.assignment_for_index(0)
	var wrapped: Dictionary = allocator.assignment_for_index(4)
	_expect(str(first.get("team_id", "")) == "team_eco", "team field assignment follows deterministic catalog order")
	_expect(str(wrapped.get("team_id", "")) == str(first.get("team_id", "")), "team assignment wraps deterministically across larger fields")
	_expect(not str(first.get("driver_asset_id", "")).is_empty(), "team assignment includes a logical driver presentation asset")
	_expect(not str(first.get("avatar_asset_id", "")).is_empty(), "team assignment includes a logical team avatar asset")
	_expect(not str(first.get("presentation_car_asset_id", "")).is_empty(), "team assignment includes a logical presentation car asset")
	var vehicle: ArcadeVehicle = VehicleScript.new()
	var applied: Dictionary = allocator.apply_to_vehicle(vehicle, 2)
	_expect(str(vehicle.get_meta("team_id", "")) == str(applied.get("team_id", "")), "AI vehicle receives stable team metadata")
	_expect(str(vehicle.get_meta("driver_asset_id", "")) == str(applied.get("driver_asset_id", "")), "AI vehicle receives stable driver presentation metadata")
	_expect(not vehicle.has_meta("team_speed_bonus") and not vehicle.has_meta("team_handling_bonus"), "team identity adds no hidden physics bonuses")
	vehicle.free()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works team presentation tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works team presentation tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
