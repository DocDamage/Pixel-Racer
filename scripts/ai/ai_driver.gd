extends Node
class_name AIDriver

var vehicle: ArcadeVehicle = null
var track: TrackData = null
var path: Array[Vector2] = []
var target_index := 0
var lookahead := 4
var aggression := 0.5
var consistency := 0.8
var mistake_rate := 0.04
var corner_skill := 0.75
var braking_skill := 0.75
var overtake_bias := 0.5
var line_bias := 0.0
var racing_route_id := "main"
var enabled := true
var nearby_racers: Array[ArcadeVehicle] = []
var _stuck_time := 0.0
var _last_position := Vector2.ZERO

func setup(source_vehicle: ArcadeVehicle, source_track: TrackData, personality: Dictionary = {}) -> bool:
	vehicle = source_vehicle
	track = source_track
	aggression = clampf(float(personality.get("aggression", aggression)), 0.0, 1.0)
	consistency = clampf(float(personality.get("consistency", consistency)), 0.0, 1.0)
	mistake_rate = clampf(float(personality.get("mistake_rate", mistake_rate)), 0.0, 1.0)
	corner_skill = clampf(float(personality.get("corner_skill", corner_skill)), 0.0, 1.0)
	braking_skill = clampf(float(personality.get("braking_skill", braking_skill)), 0.0, 1.0)
	overtake_bias = clampf(float(personality.get("overtake_bias", overtake_bias)), 0.0, 1.0)
	line_bias = clampf(float(personality.get("line_bias", randf_range(-0.65, 0.65))), -1.0, 1.0)
	racing_route_id = str(personality.get("route_id", "main"))
	path = _build_path()
	if path.is_empty():
		enabled = false
		return false
	target_index = _nearest_index(vehicle.global_position)
	_last_position = vehicle.global_position
	_stuck_time = 0.0
	return true

func set_racer_context(racers: Array[ArcadeVehicle]) -> void:
	nearby_racers = racers

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(vehicle) or path.is_empty() or track == null:
		return
	var speed := vehicle.velocity.length()
	lookahead = clampi(2 + floori(speed / 85.0), 2, 8)
	if vehicle.global_position.distance_to(path[target_index]) > track.cell_size * 3.5:
		target_index = _nearest_index(vehicle.global_position)
	while vehicle.global_position.distance_to(path[target_index]) < track.cell_size * 0.62:
		target_index = (target_index + 1) % path.size()
	var target_path_index := (target_index + lookahead) % path.size()
	var target := _biased_path_point(target_path_index)
	var desired := (target - vehicle.global_position).normalized()
	var forward := Vector2.UP.rotated(vehicle.heading)
	var angle_error := forward.angle_to(desired)
	var steer := clampf(angle_error / lerpf(0.95, 0.62, corner_skill), -1.0, 1.0)
	var curvature := _upcoming_curvature(target_index, clampi(lookahead + 2, 4, 10))
	var throttle := 1.0
	var brake := 0.0
	if curvature > 0.72:
		throttle = lerpf(0.28, 0.55, aggression) * lerpf(0.85, 1.05, corner_skill)
		brake = lerpf(0.55, 0.18, aggression) * lerpf(1.18, 0.72, braking_skill)
	elif curvature > 0.42:
		throttle = lerpf(0.55, 0.78, aggression)
		brake = lerpf(0.18, 0.02, braking_skill)
	elif absf(angle_error) > 0.72:
		throttle = lerpf(0.4, 0.65, aggression)
		brake = lerpf(0.28, 0.08, braking_skill)
	var avoidance := _avoidance_offset(forward)
	steer = clampf(steer + avoidance, -1.0, 1.0)
	if absf(avoidance) > 0.32:
		throttle *= lerpf(0.72, 0.9, aggression)
	if randf() < mistake_rate * (1.0 - consistency) * delta:
		steer = clampf(steer + randf_range(-0.5, 0.5), -1.0, 1.0)
		throttle *= randf_range(0.55, 0.9)
	var drafting := _has_draft_target(forward)
	var use_boost := (aggression > 0.68 or drafting) and curvature < 0.20 and absf(angle_error) < 0.24
	vehicle.set_ai_controls(throttle, brake, steer, false, use_boost)
	_update_recovery(delta, throttle)

func _avoidance_offset(forward: Vector2) -> float:
	var right := forward.rotated(PI * 0.5)
	var correction := 0.0
	for other in nearby_racers:
		if not is_instance_valid(other) or other == vehicle:
			continue
		var offset := other.global_position - vehicle.global_position
		var ahead := offset.dot(forward)
		var lateral := offset.dot(right)
		if ahead > -8.0 and ahead < 82.0 and absf(lateral) < 36.0:
			var preferred_side := -1.0 if line_bias <= 0.0 else 1.0
			if absf(lateral) > 5.0:
				preferred_side = -1.0 if lateral > 0.0 else 1.0
			correction += preferred_side * lerpf(0.38, 0.7, overtake_bias)
	return clampf(correction, -0.72, 0.72)

func _has_draft_target(forward: Vector2) -> bool:
	var right := forward.rotated(PI * 0.5)
	for other in nearby_racers:
		if not is_instance_valid(other) or other == vehicle:
			continue
		var offset := other.global_position - vehicle.global_position
		var ahead := offset.dot(forward)
		if ahead > 40.0 and ahead < 165.0 and absf(offset.dot(right)) < 24.0:
			return true
	return false

func _biased_path_point(index: int) -> Vector2:
	var center := path[index]
	if path.size() < 3 or is_zero_approx(line_bias):
		return center
	var previous := path[posmod(index - 1, path.size())]
	var next := path[(index + 1) % path.size()]
	var tangent := (next - previous).normalized()
	var right := tangent.rotated(PI * 0.5)
	return center + right * line_bias * track.cell_size * 0.16

func _upcoming_curvature(index: int, samples: int) -> float:
	if path.size() < 3:
		return 0.0
	var worst := 0.0
	for offset in range(samples):
		var i := (index + offset) % path.size()
		var previous := path[posmod(i - 1, path.size())]
		var current := path[i]
		var next := path[(i + 1) % path.size()]
		var incoming := (current - previous).normalized()
		var outgoing := (next - current).normalized()
		if incoming == Vector2.ZERO or outgoing == Vector2.ZERO:
			continue
		worst = maxf(worst, absf(incoming.angle_to(outgoing)) / PI)
	return clampf(worst * 2.0, 0.0, 1.0)

func _update_recovery(delta: float, throttle: float) -> void:
	var moved := vehicle.global_position.distance_to(_last_position)
	_last_position = vehicle.global_position
	if throttle > 0.5 and vehicle.velocity.length() < 18.0 and moved < 1.5:
		_stuck_time += delta
	else:
		_stuck_time = maxf(0.0, _stuck_time - delta * 2.0)
	if _stuck_time >= 2.4:
		vehicle.reset_to_last_valid()
		target_index = _nearest_index(vehicle.global_position)
		_stuck_time = 0.0

func _build_path() -> Array[Vector2]:
	var result: Array[Vector2] = []
	if track == null:
		return result
	var start := track.get_start_object()
	if start.is_empty():
		return result
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track, racing_route_id)
	var order := graph.find_loop_order(start_cell)
	if order.is_empty() and racing_route_id != "main":
		racing_route_id = "main"
		graph.build(track, "main")
		order = graph.find_loop_order(start_cell)
	for cell in order:
		result.append(track.cell_to_world(cell))
	return result

func _nearest_index(position: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for index in range(path.size()):
		var distance := position.distance_squared_to(path[index])
		if distance < best_distance:
			best_distance = distance
			best = index
	return best
