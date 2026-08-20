extends SceneTree

var failures := 0

func _init() -> void:
	_test_clean_drift_scores()
	_test_off_track_and_low_speed_do_not_score()
	_test_collision_breaks_combo()
	_test_closed_donut_is_rejected()
	if failures == 0:
		print("Pixel Track Works drift scoring tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works drift scoring tests: %d failure(s)" % failures)
		quit(1)

func _test_clean_drift_scores() -> void:
	var scoring := DriftScoring.new()
	var heading := 0.0
	var position := Vector2.ZERO
	scoring.update(0.1, position, heading, 150.0, 45.0, true)
	for index in range(24):
		heading += 0.035
		position += Vector2(15.0, 1.4)
		scoring.update(0.1, position, heading, 150.0, 45.0, true)
	_expect(scoring.total_score > 0.0, "clean moving drift earns score")
	_expect(scoring.active, "clean moving drift keeps combo active")
	_expect(scoring.multiplier > 1.0, "sustained drift increases combo multiplier")

func _test_off_track_and_low_speed_do_not_score() -> void:
	var scoring := DriftScoring.new()
	scoring.update(0.1, Vector2.ZERO, 0.0, 160.0, 50.0, true)
	var off_track: Dictionary = scoring.update(0.1, Vector2(16, 0), 0.1, 160.0, 50.0, false)
	_expect(is_zero_approx(float(off_track.get("gain", -1.0))), "off-track sliding earns no drift score")
	var low_speed: Dictionary = scoring.update(0.1, Vector2(18, 0), 0.12, 40.0, 35.0, true)
	_expect(is_zero_approx(float(low_speed.get("gain", -1.0))), "low-speed sliding earns no drift score")

func _test_collision_breaks_combo() -> void:
	var scoring := DriftScoring.new()
	scoring.update(0.1, Vector2.ZERO, 0.0, 150.0, 50.0, true)
	for index in range(8):
		scoring.update(0.1, Vector2(float(index + 1) * 15.0, 0), 0.04 * float(index + 1), 150.0, 50.0, true)
	_expect(scoring.active and scoring.combo_score > 0.0, "drift combo is active before collision")
	scoring.register_collision()
	_expect(not scoring.active, "collision immediately breaks drift combo")
	var locked: Dictionary = scoring.update(0.1, Vector2(145, 2), 0.45, 150.0, 50.0, true)
	_expect(is_zero_approx(float(locked.get("gain", -1.0))), "collision lock prevents immediate wall-riding score")

func _test_closed_donut_is_rejected() -> void:
	var scoring := DriftScoring.new()
	var radius := 30.0
	var position := Vector2(radius, 0)
	var heading := PI * 0.5
	scoring.update(0.1, position, heading, 150.0, 60.0, true)
	var saw_loop_rejection := false
	for index in range(1, 81):
		var angle := float(index) * TAU / 40.0
		position = Vector2(cos(angle), sin(angle)) * radius
		heading = angle + PI * 0.5
		var result: Dictionary = scoring.update(0.1, position, heading, 150.0, 60.0, true)
		if str(result.get("reason", "")) == "loop_rejected":
			saw_loop_rejection = true
			break
	_expect(saw_loop_rejection, "closed donut loop is detected and rejected")
	_expect(not scoring.active, "donut rejection breaks the active combo")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
