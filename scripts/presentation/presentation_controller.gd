extends Node
class_name PresentationController

var dialogue_manager: DialogueManager
var portrait_atlas: PortraitAtlas
var dialogue_presenter: DialoguePresenter
var race_radio: RaceRadioController
var dialogue_catalog := DialogueCatalog.new()
var character_catalog := CharacterCatalog.new()
var dialogue_state_store := DialogueStateStore.new()

var _game_root: Node = null
var _race_controller: RaceController = null
var _last_mode: String = ""
var _last_validation_key: String = ""
var _builder_hint_cooldown_msec: int = 0

func _ready() -> void:
	dialogue_manager = DialogueManager.new()
	dialogue_manager.name = "DialogueManager"
	add_child(dialogue_manager)
	dialogue_manager.load_state(dialogue_state_store.load_state())
	if not dialogue_manager.dialogue_finished.is_connected(_persist_dialogue_state):
		dialogue_manager.dialogue_finished.connect(_persist_dialogue_state)
	character_catalog.load_manifest()
	portrait_atlas = PortraitAtlas.new()
	if not character_catalog.portrait_manifest.is_empty():
		portrait_atlas.load_manifest(character_catalog.portrait_manifest)
	dialogue_presenter = DialoguePresenter.new()
	dialogue_presenter.name = "DialoguePresenter"
	add_child(dialogue_presenter)
	dialogue_presenter.setup(dialogue_manager, portrait_atlas)
	if dialogue_catalog.load_characters():
		for speaker_id in dialogue_catalog.character_ids():
			dialogue_presenter.set_speaker_name(speaker_id, dialogue_catalog.display_name(speaker_id))
	else:
		_register_fallback_speaker_names()
	race_radio = RaceRadioController.new()
	race_radio.name = "RaceRadioController"
	add_child(race_radio)
	race_radio.setup(dialogue_manager)
	call_deferred("_bind_game_root")

func _process(_delta: float) -> void:
	if _game_root == null or not is_instance_valid(_game_root):
		_bind_game_root()
		return
	var current_mode: String = str(GameState.current_mode)
	if current_mode != _last_mode:
		_on_mode_changed(_last_mode, current_mode)
		_last_mode = current_mode
	if current_mode == GameState.MODE_RACE:
		_bind_race_controller()
		var state: Dictionary = _race_state()
		if not state.is_empty():
			race_radio.update_state(state)
	elif current_mode == GameState.MODE_BUILDER:
		_check_builder_validation()

func character_assets_ready() -> bool:
	return character_catalog.is_runtime_ready()

func character_asset_issues() -> Array[String]:
	return character_catalog.validation_issues()

func _bind_game_root() -> void:
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.has_method("race_state"):
		_game_root = parent_node
	else:
		var current_scene: Node = get_tree().current_scene
		if current_scene != null and current_scene.has_method("race_state"):
			_game_root = current_scene
	if _game_root != null:
		_last_mode = str(GameState.current_mode)

func _bind_race_controller() -> void:
	if _game_root == null:
		return
	var candidate: RaceController = _game_root.get("race_controller") as RaceController
	if candidate == _race_controller:
		return
	_disconnect_race_controller()
	_race_controller = candidate
	if _race_controller == null:
		return
	if not _race_controller.countdown_changed.is_connected(_on_countdown_changed):
		_race_controller.countdown_changed.connect(_on_countdown_changed)
	if not _race_controller.lap_completed.is_connected(_on_lap_completed):
		_race_controller.lap_completed.connect(_on_lap_completed)
	if not _race_controller.race_finished.is_connected(_on_race_finished):
		_race_controller.race_finished.connect(_on_race_finished)
	if not _race_controller.event_failed.is_connected(_on_event_failed):
		_race_controller.event_failed.connect(_on_event_failed)

func _disconnect_race_controller() -> void:
	if _race_controller == null or not is_instance_valid(_race_controller):
		_race_controller = null
		return
	if _race_controller.countdown_changed.is_connected(_on_countdown_changed):
		_race_controller.countdown_changed.disconnect(_on_countdown_changed)
	if _race_controller.lap_completed.is_connected(_on_lap_completed):
		_race_controller.lap_completed.disconnect(_on_lap_completed)
	if _race_controller.race_finished.is_connected(_on_race_finished):
		_race_controller.race_finished.disconnect(_on_race_finished)
	if _race_controller.event_failed.is_connected(_on_event_failed):
		_race_controller.event_failed.disconnect(_on_event_failed)
	_race_controller = null

func _on_mode_changed(_previous_mode: String, current_mode: String) -> void:
	if current_mode == GameState.MODE_RACE:
		dialogue_presenter.set_race_mode(true)
		var race_mode: String = _root_string("active_race_mode", "circuit")
		race_radio.begin_race(race_mode)
		_queue_pre_race_line(race_mode)
	elif current_mode == GameState.MODE_BUILDER:
		race_radio.end_race()
		dialogue_presenter.set_race_mode(false)
		_queue_builder_welcome()
	else:
		race_radio.end_race()
		dialogue_presenter.set_race_mode(false)
		_disconnect_race_controller()

func _on_countdown_changed(value: int) -> void:
	if value == 0:
		race_radio.on_go()

func _on_lap_completed(_lap_number: int, lap_time: float) -> void:
	if _race_controller == null:
		return
	if is_equal_approx(lap_time, _race_controller.best_lap):
		race_radio.on_new_best_lap(lap_time)

func _on_race_finished(_total_time: float) -> void:
	var state: Dictionary = _race_state()
	var position: int = int(state.get("position", 1))
	var field_size: int = int(state.get("racers", 1))
	race_radio.on_finish(position, field_size)
	var championship_id: String = _root_string("active_championship_id", "")
	var post_text: String = "P%d of %d. Debrief while the tires are still hot." % [position, field_size]
	if position == 1:
		post_text = "That is a win. P1 of %d." % field_size
	if not championship_id.is_empty() and position == 1:
		post_text = "Championship result: P1. That one moves the whole program forward."
	dialogue_manager.queue_dict({
		"id": "post_race_%s_%d" % [_root_string("active_race_mode", "race"), position],
		"speaker_id": "crew_chief",
		"portrait_id": "crew_chief",
		"text": post_text,
		"event": "post_race",
		"priority": 120,
		"duration": 3.5,
		"blocking": false,
		"cooldown": 5.0,
		"metadata": {"force_full": true}
	})

func _on_event_failed(reason: String) -> void:
	dialogue_manager.queue_dict({
		"id": "event_failed_%s" % reason.to_lower().replace(" ", "_"),
		"speaker_id": "crew_chief",
		"text": "%s. Reset, learn the route, and take another shot." % reason,
		"event": "event_failed",
		"priority": 120,
		"duration": 3.2,
		"blocking": false,
		"metadata": {"force_full": true}
	})

func _queue_pre_race_line(race_mode: String) -> void:
	var text: String = "Cars are staged. Keep the first corner clean and build the race from there."
	match race_mode:
		"time_trial": text = "Clear track. One clean lap is worth more than three desperate ones."
		"drift": text = "Judges are live. Angle, speed, control—walls do not score points."
		"checkpoint": text = "Every gate matters. Miss one and the whole run disappears."
		"elimination": text = "Do not sit at the back. The clock is hunting last place."
		"sprint": text = "No laps to recover. Make the launch count."
	dialogue_manager.queue_dict({
		"id": "pre_race_%s" % race_mode,
		"speaker_id": "event_host",
		"text": text,
		"event": "pre_race",
		"priority": 40,
		"duration": 2.8,
		"blocking": false,
		"cooldown": 12.0
	})

func _queue_builder_welcome() -> void:
	dialogue_manager.queue_dict({
		"id": "builder_first_entry",
		"speaker_id": "builder",
		"text": "Build fast, test fast. If a corner feels wrong, drive it and fix it immediately.",
		"event": "builder_entered",
		"priority": 10,
		"duration": 3.6,
		"blocking": false,
		"once_only": true
	})

func _check_builder_validation() -> void:
	if _game_root == null:
		return
	var raw_validation: Variant = _game_root.get("validation_result")
	if not raw_validation is Dictionary:
		return
	var validation: Dictionary = raw_validation as Dictionary
	var raw_errors: Variant = validation.get("errors", [])
	if not raw_errors is Array:
		return
	var errors: Array = raw_errors as Array
	if errors.is_empty():
		_last_validation_key = ""
		return
	var first_error_raw: Variant = errors[0]
	if not first_error_raw is Dictionary:
		return
	var first_error: Dictionary = first_error_raw as Dictionary
	var message: String = str(first_error.get("message", "Track validation failed."))
	var key: String = "%s:%s" % [message, str(first_error.get("cell", Vector2i.ZERO))]
	var now_msec: int = Time.get_ticks_msec()
	if key == _last_validation_key or now_msec < _builder_hint_cooldown_msec:
		return
	_last_validation_key = key
	_builder_hint_cooldown_msec = now_msec + 12000
	dialogue_manager.queue_dict({
		"id": "builder_validation_%s" % str(key.hash()),
		"speaker_id": "builder",
		"text": "%s Check the highlighted cell before you make this an official event." % message,
		"event": "invalid_track_hint",
		"priority": 30,
		"duration": 3.8,
		"blocking": false,
		"cooldown": 12.0
	})

func _persist_dialogue_state(entry: DialogueEntry) -> void:
	if entry == null or not entry.once_only:
		return
	dialogue_state_store.save_state(dialogue_manager.serialize_state())

func _register_fallback_speaker_names() -> void:
	dialogue_presenter.set_speaker_name("crew_chief", "Crew Chief")
	dialogue_presenter.set_speaker_name("spotter", "Spotter")
	dialogue_presenter.set_speaker_name("rival", "Rival")
	dialogue_presenter.set_speaker_name("mechanic", "Mechanic")
	dialogue_presenter.set_speaker_name("builder", "Track Builder")
	dialogue_presenter.set_speaker_name("event_host", "Event Control")

func _race_state() -> Dictionary:
	if _game_root == null or not _game_root.has_method("race_state"):
		return {}
	var raw_state: Variant = _game_root.call("race_state")
	return (raw_state as Dictionary).duplicate(true) if raw_state is Dictionary else {}

func _root_string(property_name: String, fallback: String) -> String:
	if _game_root == null:
		return fallback
	var value: Variant = _game_root.get(property_name)
	return fallback if value == null else str(value)
