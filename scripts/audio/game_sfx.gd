extends Node
class_name GameSFXController

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.12

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase_a: float = 0.0
var phase_b: float = 0.0
var frequency_a: float = 440.0
var frequency_b: float = 660.0
var envelope: float = 0.0
var decay: float = 10.0
var noise_mix: float = 0.0
var pitch_slide: float = 0.0

func _ready() -> void:
	add_to_group("game_sfx")
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	player = AudioStreamPlayer.new()
	player.name = "GameSFX"
	player.stream = generator
	player.bus = &"Master"
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_buffer()

func _process(delta: float) -> void:
	envelope = move_toward(envelope, 0.0, delta * decay)
	frequency_a = maxf(40.0, frequency_a + pitch_slide * delta)
	frequency_b = maxf(40.0, frequency_b + pitch_slide * 0.65 * delta)
	_fill_buffer()

func play_countdown_tick() -> void:
	_trigger(680.0, 1010.0, 0.18, 14.0, 0.0, 0.0)

func play_go() -> void:
	_trigger(920.0, 1380.0, 0.30, 7.0, 0.0, 260.0)

func play_checkpoint() -> void:
	_trigger(760.0, 1140.0, 0.16, 12.0, 0.0, 120.0)

func play_lap_complete() -> void:
	_trigger(620.0, 930.0, 0.26, 7.5, 0.0, 180.0)

func play_new_record() -> void:
	_trigger(880.0, 1320.0, 0.34, 5.5, 0.0, 320.0)

func play_finish() -> void:
	_trigger(520.0, 780.0, 0.32, 6.0, 0.04, 140.0)

func play_purchase() -> void:
	_trigger(740.0, 1110.0, 0.22, 9.0, 0.0, 80.0)

func play_upgrade() -> void:
	_trigger(640.0, 960.0, 0.28, 7.0, 0.0, 220.0)

func play_unlock() -> void:
	_trigger(840.0, 1260.0, 0.36, 5.0, 0.0, 300.0)

func play_builder_place() -> void:
	_trigger(360.0, 540.0, 0.10, 18.0, 0.03, -40.0)

func play_invalid() -> void:
	_trigger(190.0, 245.0, 0.28, 8.0, 0.08, -50.0)

func play_save() -> void:
	_trigger(480.0, 720.0, 0.20, 9.0, 0.0, 130.0)

func play_nitro_burst() -> void:
	_trigger(260.0, 520.0, 0.24, 8.5, 0.14, 420.0)

func _trigger(hz_a: float, hz_b: float, strength: float, decay_rate: float, noise: float, slide: float) -> void:
	frequency_a = hz_a
	frequency_b = hz_b
	envelope = maxf(envelope, clampf(strength, 0.0, 0.5))
	decay = maxf(0.5, decay_rate)
	noise_mix = clampf(noise, 0.0, 0.5)
	pitch_slide = slide
	_fill_buffer()

func _fill_buffer() -> void:
	if playback == null:
		return
	var available: int = playback.get_frames_available()
	if available <= 0:
		return
	var sfx_volume: float = clampf(float(SettingsManager.get_value("sfx_volume", 0.9)), 0.0, 1.0)
	var master_volume: float = clampf(float(SettingsManager.get_value("master_volume", 1.0)), 0.0, 1.0)
	var gain: float = sfx_volume * master_volume
	var increment_a: float = frequency_a / MIX_RATE
	var increment_b: float = frequency_b / MIX_RATE
	for _index in range(available):
		var tone: float = sin(phase_a * TAU) * 0.72 + sin(phase_b * TAU) * 0.28
		var noise: float = randf_range(-1.0, 1.0) * noise_mix
		var sample: float = clampf((tone + noise) * envelope * gain, -0.42, 0.42)
		playback.push_frame(Vector2(sample, sample))
		phase_a = fposmod(phase_a + increment_a, 1.0)
		phase_b = fposmod(phase_b + increment_b, 1.0)
