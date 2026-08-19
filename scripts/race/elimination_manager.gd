extends Node
class_name EliminationManager

signal racer_eliminated(vehicle: ArcadeVehicle)
signal player_eliminated
signal player_won
signal countdown_changed(seconds: float)

var track: TrackData
var player: ArcadeVehicle
var racers: Array[ArcadeVehicle] = []
var path: Array[Vector2] = []
var progress_state: Dictionary = {}
var interval := 20.0
var remaining := 20.0
var running := false

func setup(source_track: TrackData, player_vehicle: ArcadeVehicle, all_racers: Array[ArcadeVehicle], elimination_interval: float = 20.0) -> bool:
	track = source_track
	player = player_vehicle
	racers = all_racers.duplicate()
	interval = maxf(5.0, elimination_interval)
	remaining = interval
	path = _build_path()
	progress_state.clear()
	for racer in racers:
		if is_instance_valid(racer):
			progress_state[racer.get_instance_id()] = {"index": _nearest_index(racer.global_position), "lap": 0}
	running = not path.is_empty() and racers.size() >= 2
	return running

func start() -> void:
	remaining = interval
	running = not path.is_empty() and racers.size() >= 2

func stop() -> void:
	running = false

func _process(delta: float) -> void:
	if not running:
		return
	_update_progress()
	remaining -= delta
	countdown_changed.emit(maxf(0.0, remaining))
	if remaining <= 0.0:
		remaining += interval
		_eliminate_last()

func standings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for racer in racers:
		if not is_instance_valid(racer):
			continue
		result.append({"vehicle": racer, "progress": _progress_value(racer)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["progress"]) > float(b["progress"]))
	return result

func _eliminate_last() -> void:
	var order := standings()
	if order.size() <= 1:
		return
	var eliminated: ArcadeVehicle = order.back()["vehicle"]
	racers.erase(eliminated)
	progress_state.erase(eliminated.get_instance_id())
	racer_eliminated.emit(eliminated)
	if eliminated == player:
		running = false
		player_eliminated.emit()
		return
	if racers.size() == 1 and racers[0] == player:
		running = false
		player_won.emit()

func _update_progress() -> void:
	var count := path.size()
	for racer in racers:
		if not is_instance_valid(racer):
			continue
		var id := racer.get_instance_id()
		var current := _nearest_index(racer.global_position)
		var state: Dictionary = progress_state.get(id, {"index": current, "lap": 0})
		var previous := int(state.get("index", current))
		var lap := int(state.get("lap", 0))
		if previous > int(count * 0.75) and current < int(count * 0.25):
			lap += 1
		elif previous < int(count * 0.25) and current > int(count * 0.75):
			lap = maxi(0, lap - 1)
		state["index"] = current
		state["lap"] = lap
		progress_state[id] = state

func _progress_value(racer: ArcadeVehicle) -> float:
	var state: Dictionary = progress_state.get(racer.get_instance_id(), {"index": 0, "lap": 0})
	return float(int(state.get("lap", 0)) * path.size() + int(state.get("index", 0)))

func _build_path() -> Array[Vector2]:
	var output: Array[Vector2] = []
	if track == null:
		return output
	var start := track.get_start_object()
	if start.is_empty():
		return output
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track)
	for cell in graph.find_loop_order(start_cell):
		output.append(track.cell_to_world(cell))
	return output

func _nearest_index(position: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for index in range(path.size()):
		var distance := position.distance_squared_to(path[index])
		if distance < best_distance:
			best_distance = distance
			best = index
	return best
