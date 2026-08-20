extends Node
class_name EliminationManager

signal racer_eliminated(vehicle: ArcadeVehicle)
signal player_eliminated
signal player_won
signal countdown_changed(seconds: float)

var track: TrackData
var player: ArcadeVehicle
var racers: Array[ArcadeVehicle] = []
var progress: RaceProgressTracker = null
var interval := 20.0
var remaining := 20.0
var running := false

func setup(source_track: TrackData, player_vehicle: ArcadeVehicle, all_racers: Array[ArcadeVehicle], elimination_interval: float = 20.0, shared_progress: RaceProgressTracker = null) -> bool:
	track = source_track
	player = player_vehicle
	racers = all_racers.duplicate()
	interval = maxf(5.0, elimination_interval)
	remaining = interval
	progress = shared_progress
	if progress == null:
		progress = RaceProgressTracker.new()
		progress.setup(track, racers, 999999)
	else:
		progress.racers = racers.duplicate()
	running = progress != null and not progress.path.is_empty() and racers.size() >= 2
	return running

func start() -> void:
	remaining = interval
	if progress != null and not progress.running:
		progress.start()
	running = progress != null and not progress.path.is_empty() and racers.size() >= 2

func stop() -> void:
	running = false

func _process(delta: float) -> void:
	if not running or progress == null:
		return
	progress.update()
	remaining -= delta
	countdown_changed.emit(maxf(0.0, remaining))
	if remaining <= 0.0:
		remaining += interval
		_eliminate_last()

func standings() -> Array[Dictionary]:
	if progress == null:
		return []
	progress.racers = racers.duplicate()
	return progress.standings()

func _eliminate_last() -> void:
	var order := standings()
	if order.size() <= 1:
		return
	var eliminated: ArcadeVehicle = order.back().get("vehicle") as ArcadeVehicle
	if eliminated == null:
		return
	racers.erase(eliminated)
	if progress != null:
		progress.racers = racers.duplicate()
	racer_eliminated.emit(eliminated)
	if eliminated == player:
		running = false
		player_eliminated.emit()
		return
	if racers.size() == 1 and racers[0] == player:
		running = false
		player_won.emit()
