extends Node
class_name MusicController

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.24

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var current_profile: String = "menu"
var bpm: float = 118.0
var bass_root: float = 55.0
var energy: float = 0.55
var sample_cursor: int = 0
var bass_phase: float = 0.0
var pad_phase: float = 0.0
var lead_phase: float = 0.0
var _last_game_mode: String = ""

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	player = AudioStreamPlayer.new()
	player.name = "ProceduralMusic"
	player.stream = generator
	player.bus = &"Master"
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	_set_profile_for_game_mode(str(GameState.current_mode))
	_fill_buffer()

func _process(_delta: float) -> void:
	var game_mode: String = str(GameState.current_mode)
	if game_mode != _last_game_mode:
		_set_profile_for_game_mode(game_mode)
	_fill_buffer()

func set_profile(profile: String) -> void:
	if profile == current_profile:
		return
	current_profile = profile
	match profile:
		"builder":
			bpm = 106.0
			bass_root = 55.0
			energy = 0.42
		"race":
			bpm = 154.0
			bass_root = 55.0
			energy = 0.86
		"championship":
			bpm = 146.0
			bass_root = 65.41
			energy = 0.94
		"results":
			bpm = 112.0
			bass_root = 65.41
			energy = 0.58
		"garage":
			bpm = 100.0
			bass_root = 49.0
			energy = 0.38
		_:
			bpm = 118.0
			bass_root = 55.0
			energy = 0.55

func _set_profile_for_game_mode(game_mode: String) -> void:
	_last_game_mode = game_mode
	if game_mode == GameState.MODE_BUILDER:
		set_profile("builder")
	elif game_mode in [GameState.MODE_RACE, GameState.MODE_TEST]:
		set_profile("race")
	else:
		set_profile("menu")

func _fill_buffer() -> void:
	if playback == null:
		return
	var available: int = playback.get_frames_available()
	if available <= 0:
		return
	var music_volume: float = clampf(float(SettingsManager.get_value("music_volume", 0.65)), 0.0, 1.0)
	var master_volume: float = clampf(float(SettingsManager.get_value("master_volume", 1.0)), 0.0, 1.0)
	var output_gain: float = music_volume * master_volume
	for _index in range(available):
		var time_seconds: float = float(sample_cursor) / MIX_RATE
		var beat: float = time_seconds * bpm / 60.0
		var beat_index: int = floori(beat)
		var beat_phase: float = fposmod(beat, 1.0)
		var half_phase: float = fposmod(beat * 2.0, 1.0)
		var bar_step: int = posmod(beat_index, 8)
		var kick_env: float = exp(-beat_phase * 18.0) if bar_step in [0, 2, 4, 6] else 0.0
		var snare_env: float = exp(-beat_phase * 24.0) if bar_step in [2, 6] else 0.0
		var hat_env: float = exp(-half_phase * 34.0)
		var kick: float = sin(TAU * (48.0 + 28.0 * kick_env) * time_seconds) * kick_env * 0.22 * energy
		var snare: float = randf_range(-1.0, 1.0) * snare_env * 0.10 * energy
		var hat: float = randf_range(-1.0, 1.0) * hat_env * 0.025 * energy
		var bass_frequency: float = _bass_frequency(bar_step)
		bass_phase = fposmod(bass_phase + bass_frequency / MIX_RATE, 1.0)
		var bass_gate: float = 0.55 + 0.45 * exp(-beat_phase * 4.0)
		var bass: float = (sin(bass_phase * TAU) + 0.22 * sin(bass_phase * TAU * 2.0)) * 0.075 * bass_gate * energy
		var pad_frequency: float = bass_root * 2.0
		pad_phase = fposmod(pad_phase + pad_frequency / MIX_RATE, 1.0)
		var pad: float = sin(pad_phase * TAU) * 0.022 * (1.0 - energy * 0.25)
		var lead: float = 0.0
		if current_profile in ["race", "championship"] and bar_step in [1, 3, 5, 7]:
			var lead_frequency: float = bass_root * (4.0 if bar_step in [1, 5] else 4.5)
			lead_phase = fposmod(lead_phase + lead_frequency / MIX_RATE, 1.0)
			lead = sin(lead_phase * TAU) * exp(-beat_phase * 5.0) * 0.022 * energy
		var sample: float = clampf((kick + snare + hat + bass + pad + lead) * output_gain, -0.38, 0.38)
		playback.push_frame(Vector2(sample, sample))
		sample_cursor += 1

func _bass_frequency(step: int) -> float:
	var ratio: float = 1.0
	match step:
		2, 3:
			ratio = 1.189207
		4:
			ratio = 1.33484
		5:
			ratio = 1.498307
		6, 7:
			ratio = 1.189207
	return bass_root * ratio
