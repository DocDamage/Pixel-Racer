extends Node
class_name BuilderAutosaveController

const DEFAULT_INTERVAL := 25.0

var game = null
var interval_seconds := DEFAULT_INTERVAL
var elapsed_dirty := 0.0
var previous_mode := -1
var last_save_msec := 0

func _ready() -> void:
	call_deferred("_bind_game")

func _bind_game() -> void:
	game = get_parent()
	previous_mode = GameState.current_mode

func _process(delta: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	var current_mode := GameState.current_mode
	var track = game.track
	if previous_mode == GameState.MODE_BUILDER and current_mode != GameState.MODE_BUILDER:
		_save_dirty_track()
	if current_mode == GameState.MODE_BUILDER and track != null and bool(track.dirty):
		elapsed_dirty += delta
		if elapsed_dirty >= interval_seconds:
			_save_dirty_track()
	else:
		elapsed_dirty = 0.0
	previous_mode = current_mode

func force_save() -> bool:
	return _save_dirty_track()

func seconds_since_last_save() -> float:
	if last_save_msec <= 0:
		return INF
	return float(Time.get_ticks_msec() - last_save_msec) / 1000.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_dirty_track()

func _save_dirty_track() -> bool:
	if game == null or not is_instance_valid(game) or game.track == null:
		return false
	var track = game.track
	if not bool(track.dirty):
		return true
	if not SaveManager.save_track(track):
		return false
	track.dirty = false
	last_save_msec = Time.get_ticks_msec()
	elapsed_dirty = 0.0
	var preview_path := "user://tracks/%s/preview.png" % str(track.track_id)
	TrackPreviewGenerator.new().save(track, preview_path)
	if game.ui != null:
		game.ui.refresh_builder()
	return true
