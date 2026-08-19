extends RefCounted
class_name DriftScoring

const MIN_FORWARD_SPEED := 90.0
const MIN_SLIP_SPEED := 18.0
const MIN_ANGLE_DEGREES := 7.5
const MAX_SCORE_ANGLE_DEGREES := 52.0
const COMBO_STEP_SECONDS := 1.6
const MAX_MULTIPLIER := 3.0
const LOOP_TRAVEL_THRESHOLD := 170.0
const LOOP_MIN_PROGRESS_RATIO := 0.24
const LOOP_ROTATION_LIMIT := TAU * 0.92
const COLLISION_LOCK_SECONDS := 0.55

var total_score := 0.0
var combo_score := 0.0
var combo_time := 0.0
var multiplier := 1.0
var collision_lock := 0.0
var combo_origin := Vector2.ZERO
var combo_travel := 0.0
var combo_rotation := 0.0
var last_position := Vector2.ZERO
var last_heading := 0.0
var initialized := false
var active := false

func reset() -> void:
	total_score = 0.0
	combo_score = 0.0
	combo_time = 0.0
	multiplier = 1.0
	collision_lock = 0.0
	combo_origin = Vector2.ZERO
	combo_travel = 0.0
	combo_rotation = 0.0
	last_position = Vector2.ZERO
	last_heading = 0.0
	initialized = false
	active = false

func register_collision() -> void:
	collision_lock = COLLISION_LOCK_SECONDS
	_break_combo()

func update(delta: float, position: Vector2, heading: float, forward_speed: float, lateral_speed: float, on_track: bool) -> Dictionary:
	if not initialized:
		initialized = true
		last_position = position
		last_heading = heading
		combo_origin = position
		return _result(0.0, false, "initializing")

	var travel: float = position.distance_to(last_position)
	var rotation_delta: float = absf(angle_difference(last_heading, heading))
	last_position = position
	last_heading = heading
	collision_lock = maxf(0.0, collision_lock - delta)

	var forward_abs := absf(forward_speed)
	var slip_abs := absf(lateral_speed)
	var angle_degrees := rad_to_deg(atan2(slip_abs, maxf(1.0, forward_abs)))
	var eligible := on_track and collision_lock <= 0.0 and forward_abs >= MIN_FORWARD_SPEED and slip_abs >= MIN_SLIP_SPEED and angle_degrees >= MIN_ANGLE_DEGREES
	if not eligible:
		_break_combo()
		return _result(0.0, false, "not_eligible")

	if not active:
		active = true
		combo_origin = position
		combo_travel = 0.0
		combo_rotation = 0.0
		combo_time = 0.0
		combo_score = 0.0
		multiplier = 1.0

	combo_travel += travel
	combo_rotation += rotation_delta
	combo_time += delta
	var net_progress: float = position.distance_to(combo_origin)
	var progress_ratio: float = net_progress / maxf(1.0, combo_travel)
	if combo_travel >= LOOP_TRAVEL_THRESHOLD and progress_ratio < LOOP_MIN_PROGRESS_RATIO and combo_rotation >= LOOP_ROTATION_LIMIT:
		_break_combo()
		return _result(0.0, false, "loop_rejected")

	multiplier = minf(MAX_MULTIPLIER, 1.0 + floorf(combo_time / COMBO_STEP_SECONDS) * 0.25)
	var angle_factor := clampf((angle_degrees - MIN_ANGLE_DEGREES) / maxf(1.0, MAX_SCORE_ANGLE_DEGREES - MIN_ANGLE_DEGREES), 0.10, 1.0)
	var speed_factor := clampf((forward_abs - MIN_FORWARD_SPEED) / 230.0, 0.18, 1.0)
	var movement_factor := clampf(travel / maxf(1.0, forward_abs * delta), 0.0, 1.15)
	var gain := (18.0 + 72.0 * angle_factor) * speed_factor * movement_factor * multiplier * delta
	combo_score += gain
	total_score += gain
	return _result(gain, true, "scoring")

func _break_combo() -> void:
	active = false
	combo_score = 0.0
	combo_time = 0.0
	multiplier = 1.0
	combo_travel = 0.0
	combo_rotation = 0.0
	combo_origin = last_position

func _result(gain: float, is_active: bool, reason: String) -> Dictionary:
	return {
		"gain": gain,
		"total": total_score,
		"combo": combo_score,
		"multiplier": multiplier,
		"active": is_active,
		"reason": reason
	}
