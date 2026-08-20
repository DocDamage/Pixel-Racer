extends RefCounted
class_name RaceProgressTracker

var track: TrackData = null
var racers: Array[ArcadeVehicle] = []
var path: Array[Vector2] = []
var state: Dictionary = {}
var laps_required := 3
var start_msec := 0
var running := false
var finish_order: Array[int] = []

func setup(source_track: TrackData, all_racers: Array[ArcadeVehicle], required_laps: int = 3) -> bool:
	track = source_track
	racers = all_racers.duplicate()
	laps_required = maxi(1, required_laps)
	path = _build_main_path()
	state.clear()
	finish_order.clear()
	for racer in racers:
		if not is_instance_valid(racer):
			continue
		var index := _nearest_index(racer.global_position)
		state[racer.get_instance_id()] = {
			"index": index,
			"lap": -1 if path.size() > 4 and index > int(path.size() * 0.75) else 0,
			"finished": false,
			"finish_time": INF,
			"finish_place": 0
		}
	running = not path.is_empty() and not racers.is_empty()
	start_msec = Time.get_ticks_msec()
	return running

func start() -> void:
	start_msec = Time.get_ticks_msec()
	running = not path.is_empty() and not racers.is_empty()

func stop() -> void:
	running = false

func update() -> void:
	if not running or path.is_empty():
		return
	var count := path.size()
	for racer in racers:
		if not is_instance_valid(racer):
			continue
		var id := racer.get_instance_id()
		var current := _nearest_index(racer.global_position)
		var racer_state: Dictionary = state.get(id, {"index": current, "lap": 0, "finished": false, "finish_time": INF, "finish_place": 0})
		if bool(racer_state.get("finished", false)):
			continue
		var previous := int(racer_state.get("index", current))
		var lap := int(racer_state.get("lap", 0))
		if previous > int(count * 0.75) and current < int(count * 0.25):
			lap += 1
		elif previous < int(count * 0.25) and current > int(count * 0.75):
			lap -= 1
		racer_state["index"] = current
		racer_state["lap"] = lap
		if lap >= laps_required:
			_mark_finished_state(id, racer_state)
		state[id] = racer_state

func force_finish(racer: ArcadeVehicle) -> void:
	if racer == null or not is_instance_valid(racer):
		return
	var id := racer.get_instance_id()
	var racer_state: Dictionary = state.get(id, {"index": 0, "lap": laps_required, "finished": false, "finish_time": INF, "finish_place": 0})
	if bool(racer_state.get("finished", false)):
		return
	racer_state["lap"] = maxi(laps_required, int(racer_state.get("lap", 0)))
	_mark_finished_state(id, racer_state)
	state[id] = racer_state

func standings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for racer in racers:
		if not is_instance_valid(racer):
			continue
		var racer_state: Dictionary = state.get(racer.get_instance_id(), {})
		result.append({
			"vehicle": racer,
			"vehicle_id": racer.vehicle_id,
			"progress": progress_value(racer),
			"lap": int(racer_state.get("lap", 0)),
			"index": int(racer_state.get("index", 0)),
			"finished": bool(racer_state.get("finished", false)),
			"finish_time": float(racer_state.get("finish_time", INF)),
			"finish_place": int(racer_state.get("finish_place", 0))
		})
	result.sort_custom(_sort_standing)
	return result

func position_of(racer: ArcadeVehicle) -> int:
	var order := standings()
	for index in range(order.size()):
		if order[index].get("vehicle") == racer:
			return index + 1
	return 0

func progress_value(racer: ArcadeVehicle) -> float:
	if racer == null or path.is_empty():
		return -INF
	var racer_state: Dictionary = state.get(racer.get_instance_id(), {"index": 0, "lap": 0})
	if bool(racer_state.get("finished", false)):
		return float((laps_required + 1) * path.size()) - float(int(racer_state.get("finish_place", 0))) * 0.001
	return float(int(racer_state.get("lap", 0)) * path.size() + int(racer_state.get("index", 0)))

func current_lap(racer: ArcadeVehicle) -> int:
	if racer == null:
		return 0
	var racer_state: Dictionary = state.get(racer.get_instance_id(), {})
	return clampi(int(racer_state.get("lap", 0)) + 1, 0, laps_required)

func finished_count() -> int:
	return finish_order.size()

func elapsed_time() -> float:
	if start_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - start_msec) / 1000.0

func _mark_finished_state(id: int, racer_state: Dictionary) -> void:
	if bool(racer_state.get("finished", false)):
		return
	finish_order.append(id)
	racer_state["finished"] = true
	racer_state["finish_place"] = finish_order.size()
	racer_state["finish_time"] = elapsed_time()

func _sort_standing(a: Dictionary, b: Dictionary) -> bool:
	var a_finished := bool(a.get("finished", false))
	var b_finished := bool(b.get("finished", false))
	if a_finished and b_finished:
		return int(a.get("finish_place", 9999)) < int(b.get("finish_place", 9999))
	if a_finished != b_finished:
		return a_finished
	return float(a.get("progress", -INF)) > float(b.get("progress", -INF))

func _build_main_path() -> Array[Vector2]:
	var output: Array[Vector2] = []
	if track == null:
		return output
	var start := track.get_start_object()
	if start.is_empty():
		return output
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track, "main")
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
