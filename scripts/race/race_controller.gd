extends Node
class_name RaceController

signal countdown_changed(value: int)
signal lap_completed(lap_number: int, lap_time: float)
signal race_finished(total_time: float)
signal checkpoint_changed(index: int, total: int)
signal event_failed(reason: String)
signal status_changed(text: String)

var track = null
var vehicle: ArcadeVehicle = null
var mode := "circuit"
var laps_required := 3
var current_lap := 0
var current_checkpoint := 0
var lap_start_msec := 0
var race_start_msec := 0
var best_lap := INF
var last_lap := 0.0
var running := false
var finished := false
var failed := false
var event_limit := 0.0
var checkpoint_bonus := 0.0
var checkpoint_deadline_msec := 0
var _start_armed := false
var _countdown_token := 0

func setup(source_track, player_vehicle: ArcadeVehicle, laps: int = 3, event_mode: String = "circuit") -> void:
	track = source_track
	vehicle = player_vehicle
	mode = event_mode if RaceModeCatalog.MODES.has(event_mode) else "circuit"
	var preset := RaceModeCatalog.get_mode(mode)
	laps_required = maxi(1, int(preset.get("laps", laps)))
	if mode == "circuit":
		laps_required = maxi(1, laps)
	event_limit = float(preset.get("time_limit", 0.0))
	checkpoint_bonus = float(preset.get("checkpoint_bonus", 0.0))
	current_lap = 0
	current_checkpoint = 0
	best_lap = INF
	last_lap = 0.0
	running = false
	finished = false
	failed = false
	_start_armed = false

func start_countdown() -> void:
	_countdown_token += 1
	var token := _countdown_token
	for value in [3, 2, 1]:
		if token != _countdown_token:
			return
		countdown_changed.emit(value)
		await get_tree().create_timer(0.7).timeout
	if token != _countdown_token:
		return
	countdown_changed.emit(0)
	start_race()

func start_race() -> void:
	if track == null or vehicle == null:
		return
	running = true
	finished = false
	failed = false
	current_lap = 1
	current_checkpoint = 0
	race_start_msec = Time.get_ticks_msec()
	lap_start_msec = race_start_msec
	_start_armed = false
	if mode == "checkpoint":
		var preset := RaceModeCatalog.get_mode(mode)
		checkpoint_deadline_msec = race_start_msec + int(float(preset.get("starting_time", 22.0)) * 1000.0)
	checkpoint_changed.emit(current_checkpoint, track.get_checkpoints_sorted().size())
	status_changed.emit(_status_text())

func stop() -> void:
	_countdown_token += 1
	running = false

func current_lap_time() -> float:
	if not running:
		return last_lap
	return float(Time.get_ticks_msec() - lap_start_msec) / 1000.0

func total_time() -> float:
	if race_start_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - race_start_msec) / 1000.0

func remaining_time() -> float:
	if mode == "drift":
		return maxf(0.0, event_limit - total_time())
	if mode == "checkpoint":
		return maxf(0.0, float(checkpoint_deadline_msec - Time.get_ticks_msec()) / 1000.0)
	return 0.0

func _process(_delta: float) -> void:
	if not running or finished or failed or track == null or vehicle == null:
		return
	if mode == "drift":
		if total_time() >= event_limit:
			_finish_event()
		else:
			status_changed.emit(_status_text())
		return
	if mode == "checkpoint" and Time.get_ticks_msec() >= checkpoint_deadline_msec:
		_fail_event("TIME UP")
		return
	var checkpoints := track.get_checkpoints_sorted()
	if current_checkpoint < checkpoints.size():
		var checkpoint: Dictionary = checkpoints[current_checkpoint]
		var cell := Vector2i(int(checkpoint.get("x", 0)), int(checkpoint.get("y", 0)))
		if vehicle.global_position.distance_to(track.cell_to_world(cell)) <= track.cell_size * 0.48:
			current_checkpoint += 1
			if mode == "checkpoint":
				checkpoint_deadline_msec += int(checkpoint_bonus * 1000.0)
			checkpoint_changed.emit(current_checkpoint, checkpoints.size())
			status_changed.emit(_status_text())
			if current_checkpoint >= checkpoints.size() and mode in ["sprint", "checkpoint"]:
				_finish_event()
				return
	var start := track.get_start_object()
	if start.is_empty():
		return
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var distance := vehicle.global_position.distance_to(track.cell_to_world(start_cell))
	if distance > track.cell_size * 0.9:
		_start_armed = true
	elif _start_armed and distance <= track.cell_size * 0.45 and current_checkpoint >= checkpoints.size():
		_complete_lap()

func _complete_lap() -> void:
	_start_armed = false
	last_lap = current_lap_time()
	best_lap = minf(best_lap, last_lap)
	if track != null and vehicle != null:
		RecordManager.new().record_lap(track.track_id, vehicle.vehicle_id, mode, last_lap)
	lap_completed.emit(current_lap, last_lap)
	if current_lap >= laps_required:
		_finish_event()
		return
	current_lap += 1
	current_checkpoint = 0
	lap_start_msec = Time.get_ticks_msec()
	checkpoint_changed.emit(current_checkpoint, track.get_checkpoints_sorted().size())
	status_changed.emit(_status_text())

func _finish_event() -> void:
	last_lap = current_lap_time()
	if mode == "drift" and track != null and vehicle != null:
		RecordManager.new().record_score(track.track_id, vehicle.vehicle_id, mode, vehicle.drift_score)
	finished = true
	running = false
	race_finished.emit(total_time())
	status_changed.emit(_status_text())

func _fail_event(reason: String) -> void:
	failed = true
	running = false
	event_failed.emit(reason)
	status_changed.emit(reason)

func _status_text() -> String:
	match mode:
		"drift": return "DRIFT %.0f  •  %.1fs" % [vehicle.drift_score if vehicle != null else 0.0, remaining_time()]
		"checkpoint": return "CHECKPOINT %d/%d  •  %.1fs" % [current_checkpoint, track.get_checkpoints_sorted().size() if track != null else 0, remaining_time()]
		"sprint": return "SPRINT  •  GATE %d/%d" % [current_checkpoint, track.get_checkpoints_sorted().size() if track != null else 0]
		"time_trial": return "TIME TRIAL  •  %.2f" % current_lap_time()
		_: return "LAP %d/%d" % [current_lap, laps_required]
