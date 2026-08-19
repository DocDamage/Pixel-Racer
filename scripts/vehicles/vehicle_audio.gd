extends Node
class_name VehicleAudio

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.16

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var harmonic_phase := 0.0
var speed_ratio := 0.0
var throttle := 0.0
var drifting := false
var boosting := false
var surface := "asphalt"
var impact_envelope := 0.0
var enabled := false

func start() -> void:
	if enabled:
		return
	enabled = true
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	player = AudioStreamPlayer.new()
	player.name = "ProceduralVehicleAudio"
	player.stream = generator
	player.bus = &"Master"
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_buffer()

func stop() -> void:
	enabled = false
	if player != null:
		player.stop()
	playback = null

func update_state(normalized_speed: float, throttle_input: float, is_drifting: bool, is_boosting: bool, surface_name: String) -> void:
	speed_ratio = clampf(normalized_speed, 0.0, 1.35)
	throttle = clampf(throttle_input, 0.0, 1.0)
	drifting = is_drifting
	boosting = is_boosting
	surface = surface_name
	_fill_buffer()

func trigger_impact(strength: float) -> void:
	impact_envelope = maxf(impact_envelope, clampf(strength, 0.0, 1.0))

func _process(delta: float) -> void:
	if enabled:
		impact_envelope = move_toward(impact_envelope, 0.0, delta * 4.5)
		_fill_buffer()

func _fill_buffer() -> void:
	if not enabled or playback == null:
		return
	var frames_available := playback.get_frames_available()
	if frames_available <= 0:
		return
	var rpm_frequency := lerpf(48.0, 182.0, clampf(speed_ratio, 0.0, 1.0)) + throttle * 18.0
	var harmonic_frequency := rpm_frequency * 2.02
	var base_increment := rpm_frequency / MIX_RATE
	var harmonic_increment := harmonic_frequency / MIX_RATE
	var loose_surface := surface in ["dirt", "sand", "gravel", "grass"]
	var tire_level := 0.0
	if drifting:
		tire_level = 0.12
	elif loose_surface and speed_ratio > 0.18:
		tire_level = 0.045
	var boost_level := 0.09 if boosting else 0.0
	var sfx_volume := clampf(float(SettingsManager.get_value("sfx_volume", 0.9)), 0.0, 1.0)
	var engine_level := lerpf(0.045, 0.095, throttle) * lerpf(0.72, 1.0, clampf(speed_ratio, 0.0, 1.0))
	for _index in range(frames_available):
		var engine_sample := sin(phase * TAU) * engine_level
		engine_sample += sin(harmonic_phase * TAU) * engine_level * 0.34
		var tire_sample := randf_range(-1.0, 1.0) * tire_level
		var boost_sample := sin(harmonic_phase * TAU * 1.91) * boost_level
		var impact_noise := randf_range(-1.0, 1.0) * impact_envelope * 0.26
		var impact_thump := sin(phase * TAU * 0.37) * impact_envelope * 0.16
		var sample := clampf((engine_sample + tire_sample + boost_sample + impact_noise + impact_thump) * sfx_volume, -0.48, 0.48)
		playback.push_frame(Vector2(sample, sample))
		phase = fposmod(phase + base_increment, 1.0)
		harmonic_phase = fposmod(harmonic_phase + harmonic_increment, 1.0)
