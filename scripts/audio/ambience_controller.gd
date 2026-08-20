extends Node
class_name AmbienceController

const MIX_RATE := 11025.0
const BUFFER_LENGTH := 0.28

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var crowd_phase: float = 0.0
var air_phase: float = 0.0
var current_level: float = 0.0
var target_level: float = 0.0
var _last_mode: String = ""

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	player = AudioStreamPlayer.new()
	player.name = "ProceduralAmbience"
	player.stream = generator
	player.bus = &"Master"
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	_update_mode(str(GameState.current_mode))
	_fill_buffer()

func _process(delta: float) -> void:
	var mode: String = str(GameState.current_mode)
	if mode != _last_mode:
		_update_mode(mode)
	current_level = move_toward(current_level, target_level, delta * 0.35)
	_fill_buffer()

func _update_mode(mode: String) -> void:
	_last_mode = mode
	if mode in [GameState.MODE_RACE, GameState.MODE_TEST]:
		target_level = 0.085
	elif mode == GameState.MODE_BUILDER:
		target_level = 0.035
	else:
		target_level = 0.022

func _fill_buffer() -> void:
	if playback == null:
		return
	var available: int = playback.get_frames_available()
	if available <= 0:
		return
	var sfx_volume: float = clampf(float(SettingsManager.get_value("sfx_volume", 0.9)), 0.0, 1.0)
	var master_volume: float = clampf(float(SettingsManager.get_value("master_volume", 1.0)), 0.0, 1.0)
	var gain: float = current_level * sfx_volume * master_volume
	for _index in range(available):
		crowd_phase = fposmod(crowd_phase + 1.35 / MIX_RATE, 1.0)
		air_phase = fposmod(air_phase + 0.18 / MIX_RATE, 1.0)
		var crowd_motion: float = 0.55 + sin(crowd_phase * TAU) * 0.16 + sin(crowd_phase * TAU * 2.73) * 0.08
		var wind_motion: float = 0.55 + sin(air_phase * TAU) * 0.22
		var noise: float = randf_range(-1.0, 1.0)
		var low_noise: float = noise * crowd_motion * 0.42
		var air_noise: float = randf_range(-1.0, 1.0) * wind_motion * 0.18
		var sample: float = clampf((low_noise + air_noise) * gain, -0.12, 0.12)
		playback.push_frame(Vector2(sample * 0.92, sample))
