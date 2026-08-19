extends RefCounted
class_name RaceModeCatalog

const MODES := {
	"circuit": {
		"name": "Circuit",
		"description": "Three-lap race with ordered checkpoints.",
		"laps": 3,
		"ai_count": 3
	},
	"time_trial": {
		"name": "Time Trial",
		"description": "Solo one-lap run against the clock.",
		"laps": 1,
		"ai_count": 0
	},
	"sprint": {
		"name": "Sprint",
		"description": "Reach every checkpoint once; the final gate ends the event.",
		"laps": 1,
		"ai_count": 0
	},
	"checkpoint": {
		"name": "Checkpoint Rush",
		"description": "Beat the countdown; each checkpoint adds time.",
		"laps": 1,
		"ai_count": 0,
		"starting_time": 22.0,
		"checkpoint_bonus": 8.0
	},
	"drift": {
		"name": "Drift Trial",
		"description": "Score as much drift as possible in 60 seconds.",
		"laps": 1,
		"ai_count": 0,
		"time_limit": 60.0
	}
}

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in MODES:
		result.append(str(id))
	return result

static func get_mode(id: String) -> Dictionary:
	return MODES.get(id, MODES["circuit"]).duplicate(true)
