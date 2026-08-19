extends Node
class_name CharacterSequenceController

signal sequence_started(sequence_id: String)
signal step_started(sequence_id: String, step_index: int, step: Dictionary)
signal sequence_finished(sequence_id: String)
signal sequence_skipped(sequence_id: String)

var actor: CharacterActor = null
var venue: VenueController = null
var dialogue: DialogueManager = null
var input_locked: bool = false
var speed_multiplier: float = 1.0

var _sequence_id: String = ""
var _steps: Array[Dictionary] = []
var _step_index: int = -1
var _waiting_for_arrival: bool = false
var _waiting_until_msec: int = 0
var _active: bool = false

func setup(character_actor: CharacterActor, venue_controller: VenueController, dialogue_manager: DialogueManager = null) -> void:
	actor = character_actor
	venue = venue_controller
	dialogue = dialogue_manager
	if actor != null and not actor.destination_reached.is_connected(_on_actor_destination_reached):
		actor.destination_reached.connect(_on_actor_destination_reached)

func _process(_delta: float) -> void:
	if not _active or _waiting_for_arrival:
		return
	if _waiting_until_msec > 0:
		if Time.get_ticks_msec() < _waiting_until_msec:
			return
		_waiting_until_msec = 0
		_advance_step()

func play(sequence_id: String, steps: Array[Dictionary], lock_input: bool = true) -> bool:
	if actor == null or venue == null or steps.is_empty():
		return false
	cancel(false)
	_sequence_id = sequence_id
	_steps = steps.duplicate(true)
	_step_index = -1
	_waiting_for_arrival = false
	_waiting_until_msec = 0
	_active = true
	input_locked = lock_input
	sequence_started.emit(_sequence_id)
	_advance_step()
	return true

func play_named_route(sequence_id: String, anchor_names: Array[StringName], lock_input: bool = true) -> bool:
	var steps: Array[Dictionary] = []
	for anchor_name in anchor_names:
		steps.append({"type": "walk", "anchor": str(anchor_name)})
	return play(sequence_id, steps, lock_input)

func skip() -> void:
	if not _active:
		return
	var skipped_id: String = _sequence_id
	if actor != null:
		for index in range(_step_index + 1, _steps.size()):
			var step: Dictionary = _steps[index]
			if str(step.get("type", "")) != "walk":
				continue
			var anchor_name := StringName(str(step.get("anchor", "")))
			if venue != null and venue.has_anchor(anchor_name):
				actor.teleport_to(venue.anchor_position(anchor_name))
		actor.stop()
	_finish_sequence()
	sequence_skipped.emit(skipped_id)

func cancel(stop_actor: bool = true) -> void:
	if stop_actor and actor != null:
		actor.stop()
	_sequence_id = ""
	_steps.clear()
	_step_index = -1
	_waiting_for_arrival = false
	_waiting_until_msec = 0
	_active = false
	input_locked = false

func is_playing() -> bool:
	return _active

func current_sequence_id() -> String:
	return _sequence_id

func _advance_step() -> void:
	if not _active:
		return
	_step_index += 1
	if _step_index >= _steps.size():
		_finish_sequence()
		return
	var step: Dictionary = _steps[_step_index]
	step_started.emit(_sequence_id, _step_index, step)
	var step_type: String = str(step.get("type", ""))
	match step_type:
		"walk":
			_run_walk_step(step)
		"face":
			_run_face_step(step)
		"wait":
			_run_wait_step(step)
		"dialogue":
			_run_dialogue_step(step)
		"hide":
			if actor != null:
				actor.visible = false
			_advance_step()
		"show":
			if actor != null:
				actor.visible = true
			_advance_step()
		_:
			_advance_step()

func _run_walk_step(step: Dictionary) -> void:
	if actor == null or venue == null:
		_advance_step()
		return
	var anchor_name := StringName(str(step.get("anchor", "")))
	if not venue.has_anchor(anchor_name):
		_advance_step()
		return
	var old_speed: float = actor.definition.walk_speed if actor.definition != null else 72.0
	var step_speed_scale: float = maxf(0.1, float(step.get("speed_scale", 1.0)))
	if actor.definition != null:
		actor.definition.walk_speed = old_speed * speed_multiplier * step_speed_scale
	_waiting_for_arrival = true
	actor.walk_to(venue.anchor_position(anchor_name))

func _run_face_step(step: Dictionary) -> void:
	if actor != null and venue != null:
		var anchor_name := StringName(str(step.get("anchor", "")))
		if venue.has_anchor(anchor_name):
			actor.face_toward(venue.anchor_position(anchor_name))
	_advance_step()

func _run_wait_step(step: Dictionary) -> void:
	var duration: float = maxf(0.0, float(step.get("duration", 0.0)))
	if duration <= 0.0:
		_advance_step()
		return
	_waiting_until_msec = Time.get_ticks_msec() + roundi(duration * 1000.0)

func _run_dialogue_step(step: Dictionary) -> void:
	if dialogue != null:
		var entry_data: Dictionary = {}
		var raw_entry: Variant = step.get("entry", {})
		if raw_entry is Dictionary:
			entry_data = (raw_entry as Dictionary).duplicate(true)
		elif step.has("text"):
			entry_data = {
				"speaker_id": str(step.get("speaker_id", "")),
				"portrait_id": str(step.get("portrait_id", "")),
				"text": str(step.get("text", "")),
				"blocking": bool(step.get("blocking", false)),
				"duration": float(step.get("duration", 3.0)),
				"priority": int(step.get("priority", 0))
			}
		if not entry_data.is_empty():
			dialogue.queue_dict(entry_data)
	_advance_step()

func _on_actor_destination_reached(_destination: Vector2) -> void:
	if not _active or not _waiting_for_arrival:
		return
	_waiting_for_arrival = false
	_advance_step()

func _finish_sequence() -> void:
	var completed_id: String = _sequence_id
	_sequence_id = ""
	_steps.clear()
	_step_index = -1
	_waiting_for_arrival = false
	_waiting_until_msec = 0
	_active = false
	input_locked = false
	sequence_finished.emit(completed_id)
