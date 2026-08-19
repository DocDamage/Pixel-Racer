extends Node
class_name RaceRadioController

var dialogue: DialogueManager = null
var active: bool = false
var mode: String = "circuit"

var _last_position: int = 1
var _last_lap: int = 0
var _last_pit: bool = false
var _last_penalty: float = 0.0
var _low_nitro_announced: bool = false
var _next_drift_callout: float = 2500.0
var _elimination_warning_sent: bool = false

func setup(dialogue_manager: DialogueManager) -> void:
	dialogue = dialogue_manager

func begin_race(race_mode: String) -> void:
	mode = race_mode
	active = true
	_last_position = 1
	_last_lap = 0
	_last_pit = false
	_last_penalty = 0.0
	_low_nitro_announced = false
	_next_drift_callout = 2500.0
	_elimination_warning_sent = false

func end_race() -> void:
	active = false

func on_go() -> void:
	_queue_radio({
		"id": "race_go_%s" % mode,
		"speaker_id": "crew_chief",
		"portrait_id": "crew_chief",
		"text": _go_line(),
		"event": "countdown_complete",
		"priority": 50,
		"duration": 2.2,
		"cooldown": 8.0
	})

func update_state(state: Dictionary) -> void:
	if not active or dialogue == null or state.is_empty():
		return
	var position: int = int(state.get("position", 1))
	var lap: int = int(state.get("lap", 0))
	var laps: int = int(state.get("laps", 0))
	var in_pit: bool = bool(state.get("pit", false))
	var penalty: float = float(state.get("penalty", 0.0))
	var nitro: float = float(state.get("nitro", 0.0))
	var drift_score: float = float(state.get("drift", 0.0))
	var racers: int = int(state.get("racers", 1))

	if position == 1 and _last_position > 1:
		_queue_radio({
			"id": "gained_p1",
			"speaker_id": "crew_chief",
			"text": "P1. Keep it clean and make them chase you.",
			"event": "gained_p1",
			"priority": 70,
			"duration": 2.7,
			"cooldown": 12.0
		})
	elif position > 1 and _last_position == 1:
		_queue_radio({
			"id": "lost_p1",
			"speaker_id": "crew_chief",
			"text": "We lost the lead. Stay composed—get it back on track.",
			"event": "lost_p1",
			"priority": 75,
			"duration": 2.8,
			"cooldown": 12.0
		})

	if laps > 1 and lap >= laps and _last_lap < laps:
		_queue_radio({
			"id": "final_lap",
			"speaker_id": "crew_chief",
			"text": "Final lap. No saving anything now.",
			"event": "final_lap",
			"priority": 85,
			"duration": 2.5,
			"once_only": true
		})

	if in_pit and not _last_pit:
		_queue_radio({
			"id": "pit_entry",
			"speaker_id": "crew_chief",
			"text": "Pit lane. Watch the limiter.",
			"event": "entering_pit",
			"priority": 80,
			"duration": 2.2,
			"cooldown": 10.0
		})

	if penalty > _last_penalty + 0.01 and in_pit:
		_queue_radio({
			"id": "pit_speeding",
			"speaker_id": "crew_chief",
			"text": "Too fast in pit lane. Penalty added.",
			"event": "pit_speeding",
			"priority": 100,
			"duration": 2.4,
			"cooldown": 5.0
		})

	if nitro <= 12.0 and not _low_nitro_announced:
		_low_nitro_announced = true
		_queue_radio({
			"id": "low_nitro",
			"speaker_id": "crew_chief",
			"text": "Boost is almost dry. Build it back with clean drifts.",
			"event": "low_nitro",
			"priority": 35,
			"duration": 2.7,
			"cooldown": 20.0
		})
	elif nitro >= 35.0:
		_low_nitro_announced = false

	if drift_score >= _next_drift_callout:
		_queue_radio({
			"id": "drift_%d" % roundi(_next_drift_callout),
			"speaker_id": "spotter",
			"text": "That line is alive. Keep the drift linked.",
			"event": "high_drift_combo",
			"priority": 25,
			"duration": 2.2,
			"cooldown": 8.0
		})
		_next_drift_callout += 2500.0

	if mode == "elimination" and racers <= 3 and racers > 1 and not _elimination_warning_sent:
		_elimination_warning_sent = true
		_queue_radio({
			"id": "elimination_warning",
			"speaker_id": "spotter",
			"text": "%d cars left. Do not be the next cut." % racers,
			"event": "elimination_warning",
			"priority": 90,
			"duration": 2.6,
			"once_only": true
		})

	_last_position = position
	_last_lap = lap
	_last_pit = in_pit
	_last_penalty = penalty

func on_new_best_lap(lap_time: float) -> void:
	_queue_radio({
		"id": "new_best_lap",
		"speaker_id": "crew_chief",
		"text": "New best: %.2f. That is the pace." % lap_time,
		"event": "new_best_lap",
		"priority": 65,
		"duration": 2.8,
		"cooldown": 10.0
	})

func on_finish(position: int, field_size: int) -> void:
	if position <= 1:
		_queue_radio({
			"id": "race_win",
			"speaker_id": "crew_chief",
			"text": "P1 out of %d. Bring it home." % field_size,
			"event": "race_finished",
			"priority": 110,
			"duration": 3.0,
			"cooldown": 5.0
		})
	else:
		_queue_radio({
			"id": "race_finish_%d" % position,
			"speaker_id": "crew_chief",
			"text": "P%d of %d. We know where the time is next run." % [position, field_size],
			"event": "race_finished",
			"priority": 95,
			"duration": 3.0,
			"cooldown": 5.0
		})

func on_rival_nearby(rival_name: String) -> void:
	_queue_radio({
		"id": "rival_nearby_%s" % rival_name.to_lower().replace(" ", "_"),
		"speaker_id": "rival",
		"portrait_id": "rival",
		"text": "%s is right on you. Make them earn the pass." % rival_name,
		"event": "rival_nearby",
		"priority": 45,
		"duration": 2.6,
		"cooldown": 18.0
	})

func _queue_radio(data: Dictionary) -> void:
	if dialogue == null:
		return
	data["blocking"] = false
	dialogue.queue_dict(data)

func _go_line() -> String:
	match mode:
		"drift": return "Green. Build angle, keep speed, stay off the walls."
		"checkpoint": return "Green. Hit every gate and keep the clock alive."
		"elimination": return "Green. Stay out of last place."
		"time_trial": return "Green. This lap is all yours."
		"sprint": return "Green. One run to the finish."
		_: return "Green. Find your line and go."
