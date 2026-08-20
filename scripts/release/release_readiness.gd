extends RefCounted
class_name ReleaseReadiness

const MANUAL_CHECKS: Array[Dictionary] = [
	{"id": "windows_clean_machine", "label": "Clean Windows machine launch/save/race/relaunch"},
	{"id": "controller_xinput", "label": "Xbox/XInput full-screen navigation and race audit"},
	{"id": "controller_playstation", "label": "PlayStation-style controller full-screen audit"},
	{"id": "controller_directinput", "label": "Generic DirectInput audit where hardware is available"},
	{"id": "ui_scale_matrix", "label": "80/100/120/140% UI scale and large-text matrix"},
	{"id": "resolution_matrix", "label": "720p/1080p/1440p/high-DPI resize audit"},
	{"id": "twelve_car_1080p", "label": "12-car 1080p performance profile at stable 60 FPS target"},
	{"id": "vehicle_feel_roster", "label": "Full car/bike handling and collision-shape playtest"},
	{"id": "drift_exploit", "label": "Drift donut/wall-ride exploit balance audit"},
	{"id": "character_packaged_visual", "label": "Asset-backed character/portrait/venue flow in packaged Windows build"},
	{"id": "audio_mix", "label": "Music/SFX/ambience/vehicle/radio mix and fatigue audit"},
	{"id": "persistence_restart", "label": "Track/ghost/Garage/Career restart and migration manual QA"}
]

const ESSENTIAL_INPUT_ACTIONS: Array[StringName] = [
	&"accelerate",
	&"brake",
	&"steer_left",
	&"steer_right",
	&"handbrake",
	&"boost",
	&"reset_vehicle",
	&"pause"
]

func automated_blockers() -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	var character_catalog := CharacterCatalog.new()
	character_catalog.load_manifest()
	if not character_catalog.is_runtime_ready():
		blockers.append({
			"id": "character_assets",
			"severity": "release_blocker",
			"message": "Character/portrait source sheets are not committed, measured, and runtime-ready.",
			"details": character_catalog.validation_issues()
		})
	for action in ESSENTIAL_INPUT_ACTIONS:
		if not InputMap.has_action(action):
			blockers.append({
				"id": "missing_input_%s" % String(action),
				"severity": "release_blocker",
				"message": "Required input action is missing: %s" % String(action)
			})
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	if version.strip_edges().is_empty():
		blockers.append({
			"id": "application_version",
			"severity": "release_blocker",
			"message": "application/config/version is not set."
		})
	return blockers

func manual_checks() -> Array[Dictionary]:
	return MANUAL_CHECKS.duplicate(true)

func report(manual_results: Dictionary = {}) -> Dictionary:
	var automated: Array[Dictionary] = automated_blockers()
	var pending_manual: Array[Dictionary] = []
	for check in MANUAL_CHECKS:
		var id: String = str(check.get("id", ""))
		if str(manual_results.get(id, "pending")) != "pass":
			var pending: Dictionary = check.duplicate(true)
			pending["state"] = str(manual_results.get(id, "pending"))
			pending_manual.append(pending)
	return {
		"automated_blockers": automated,
		"pending_manual_checks": pending_manual,
		"automated_ready": automated.is_empty(),
		"manual_ready": pending_manual.is_empty(),
		"production_ready": automated.is_empty() and pending_manual.is_empty()
	}

func write_report(path: String, manual_results: Dictionary = {}) -> bool:
	var store := AtomicJsonStore.new()
	return store.save(path, report(manual_results))
