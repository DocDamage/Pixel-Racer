extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.json"
const DEFAULTS := {
	"ui_scale": 1.0,
	"camera_shake": 0.65,
	"flash_intensity": 1.0,
	"steering_sensitivity": 1.0,
	"auto_accelerate": false,
	"traction_assist": true,
	"recovery_assist": true,
	"large_text": false,
	"colorblind_indicators": false
}

var values: Dictionary = DEFAULTS.duplicate(true)

func _ready() -> void:
	load_settings()

func get_value(key: String, fallback = null):
	return values.get(key, DEFAULTS.get(key, fallback))

func set_value(key: String, value) -> void:
	values[key] = value
	save_settings()
	settings_changed.emit()

func reset_defaults() -> void:
	values = DEFAULTS.duplicate(true)
	save_settings()
	settings_changed.emit()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in DEFAULTS:
			if parsed.has(key):
				values[key] = parsed[key]

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(values, "\t"))
