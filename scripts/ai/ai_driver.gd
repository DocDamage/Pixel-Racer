extends Node
class_name AIDriver

var vehicle: ArcadeVehicle = null
var track = null
var path: Array[Vector2] = []
var target_index := 0
var lookahead := 4
var aggression := 0.5
var consistency := 0.8
var mistake_rate := 0.04
var enabled := true

func setup(source_vehicle: ArcadeVehicle, source_track, personality: Dictionary = {}) -> bool:
	vehicle = source_vehicle
	track = source_track
	aggression = float(personality.get("aggression", aggression))
	consistency = float(personality.get("consistency", consistency))
	mistake_rate = float(personality.get("mistake_rate", mistake_rate))
	path = _build_path()
	if path.is_empty():
		enabled = false
		return false
	target_index = _nearest_index(vehicle.global_position)
	return true

func _physics_process(_delta: float) -> void:
	if not enabled or vehicle == null or path.is_empty():
		return
	var speed := vehicle.velocity.length()
	lookahead = clampi(2 + floori(speed / 90.0), 2, 7)
	var target := path[(target_index + lookahead) % path.size()]
	while vehicle.global_position.distance_to(path[target_index]) < track.cell_size * 0.65:
		target_index = (target_index + 1) % path.size()
		target = path[(target_index + lookahead) % path.size()]
	var desired := (target - vehicle.global_position).normalized()
	var forward := Vector2.UP.rotated(vehicle.heading)
	var angle_error := forward.angle_to(desired)
	var steer := clampf(angle_error / 0.8, -1.0, 1.0)
	var turn_severity := absf(angle_error)
	var throttle := 1.0
	var brake := 0.0
	if turn_severity > 0.75:
		throttle = lerpf(0.35, 0.62, aggression)
		brake = lerpf(0.35, 0.12, aggression)
	elif turn_severity > 0.4:
		throttle = 0.72
	if randf() < mistake_rate * (1.0 - consistency) * 0.02:
		steer += randf_range(-0.45, 0.45)
	vehicle.set_ai_controls(throttle, brake, steer, false, aggression > 0.7 and turn_severity < 0.18)

func _build_path() -> Array[Vector2]:
	var result: Array[Vector2] = []
	if track == null:
		return result
	var start := track.get_start_object()
	if start.is_empty():
		return result
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track)
	var order := graph.find_loop_order(start_cell)
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
