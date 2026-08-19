extends Node

signal setting_changed(key: String, value)
signal settings_reset

const SETTINGS_PATH := "user://settings.json"

var defaults: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.9,
	"ui_scale": 1.0,
	"large_text": false,
	"camera_shake": 0.65,
	"flash_intensity": 1.0,
	"colorblind_indicators": false,
	"steering_sensitivity": 1.0,
	"auto_accelerate": false,
	"auto_brake": false,
	"traction_assist": true,
	"drift_assist": 0.5,
	"recovery_assist": true,
	"track_edge_assist": false,
	"hold_to_boost": true,
	"controller_vibration": true,
	"vibration_strength": 0.75,
	"window_mode": "windowed"
}

var values: Dictionary = {}

func _ready() -> void:
	values = defaults.duplicate(true)
	load_settings()
	apply_all_runtime_settings()

func get_value(key: String, fallback = null):
	if values.has(key):
		return values[key]
	if defaults.has(key):
		return defaults[key]
	return fallback

func set_value(key: String, value) -> void:
	values[key] = _sanitize(key, value)
	save_settings()
	apply_runtime_setting(key)
	setting_changed.emit(key, values[key])

func set_many(changes: Dictionary) -> void:
	for key in changes:
		values[key] = _sanitize(str(key), changes[key])
	save_settings()
	for key in changes:
		apply_runtime_setting(str(key))
		setting_changed.emit(str(key), values[key])

func load_settings() -> void:
	values = defaults.duplicate(true)
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed:
			if defaults.has(key):
				values[key] = _sanitize(str(key), parsed[key])

func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(values, "\t"))
	return true

func reset_defaults() -> void:
	values = defaults.duplicate(true)
	save_settings()
	apply_all_runtime_settings()
	settings_reset.emit()
	for key in values:
		setting_changed.emit(str(key), values[key])

func apply_all_runtime_settings() -> void:
	for key in values:
		apply_runtime_setting(str(key))

func apply_runtime_setting(key: String) -> void:
	match key:
		"master_volume":
			_set_audio_bus("Master", float(get_value(key, 1.0)))
		"music_volume":
			_set_audio_bus("Music", float(get_value(key, 0.7)))
		"sfx_volume":
			_set_audio_bus("SFX", float(get_value(key, 0.9)))
		"ui_scale":
			if get_tree() != null and get_tree().root != null:
				get_tree().root.content_scale_factor = float(get_value(key, 1.0))
		"window_mode":
			_apply_window_mode(str(get_value(key, "windowed")))
		_:
			pass

func _set_audio_bus(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var value := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, value <= 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))

func _apply_window_mode(mode: String) -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	match mode:
		"fullscreen":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _sanitize(key: String, value):
	match key:
		"master_volume", "music_volume", "sfx_volume", "flash_intensity":
			return clampf(float(value), 0.0, 1.0)
		"ui_scale":
			return clampf(float(value), 0.75, 1.75)
		"camera_shake", "drift_assist", "vibration_strength":
			return clampf(float(value), 0.0, 1.0)
		"steering_sensitivity":
			return clampf(float(value), 0.5, 1.75)
		"window_mode":
			var mode := str(value)
			return mode if mode in ["windowed", "fullscreen", "borderless"] else "windowed"
	return value
