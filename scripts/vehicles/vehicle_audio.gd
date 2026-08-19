extends Node
class_name VehicleAudio

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.16

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var harmonic_phase := 0.0
var third_phase := 0.0
var speed_ratio := 0.0
var throttle := 0.0
var drifting := false
var boosting := false
var surface := "asphalt"
var impact_envelope := 0.0
var enabled := false
var profile := "sport"
var base_frequency_min := 48.0
var base_frequency_max := 182.0
var harmonic_ratio := 2.02
var third_ratio := 0.5
var harmonic_gain := 0.34
var third_gain := 0.08
var engine_gain := 1.0
var noise_character := 0.0

func configure(vehicle_definition: Dictionary) -> void:
	var vehicle_id: String = str(vehicle_definition.get("id", "")).to_lower()
	var vehicle_type: String = str(vehicle_definition.get("type", "car")).to_lower()
	var category: String = str(vehicle_definition.get("category", "")).to_lower()
	if vehicle_type == "bike":
		_apply_profile("bike")
	elif "electric" in category or "electric" in vehicle_id or "polygon" in vehicle_id:
		_apply_profile("electric")
	elif "muscle" in category:
		_apply_profile("muscle")
	elif "grand prix" in category or "formula" in vehicle_id:
		_apply_profile("formula")
	elif "rally" in category:
		_apply_profile("rally")
	elif "heavy" in category or "off-road" in category or "utility" in category:
		_apply_profile("heavy")
	else:
		_apply_profile("sport")

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

func _apply_profile(profile_id: String) -> void:
	profile = profile_id
	match profile_id:
		"bike":
			base_frequency_min = 82.0
			base_frequency_max = 315.0
			harmonic_ratio = 2.55
			third_ratio = 3.95
			harmonic_gain = 0.28
			third_gain = 0.12
			engine_gain = 0.86
			noise_character = 0.018
		"electric":
			base_frequency_min = 95.0
			base_frequency_max = 420.0
			harmonic_ratio = 1.51
			third_ratio = 3.02
			harmonic_gain = 0.18
			third_gain = 0.16
			engine_gain = 0.58
			noise_character = 0.005
		"muscle":
			base_frequency_min = 35.0
			base_frequency_max = 132.0
			harmonic_ratio = 1.98
			third_ratio = 0.52
			harmonic_gain = 0.42
			third_gain = 0.16
			engine_gain = 1.12
			noise_character = 0.022
		"formula":
			base_frequency_min = 72.0
			base_frequency_max = 285.0
			harmonic_ratio = 2.91
			third_ratio = 4.83
			harmonic_gain = 0.30
			third_gain = 0.11
			engine_gain = 0.92
			noise_character = 0.012
		"rally":
			base_frequency_min = 52.0
			base_frequency_max = 205.0
			harmonic_ratio = 2.14
			third_ratio = 0.71
			harmonic_gain = 0.38
			third_gain = 0.10
			engine_gain = 1.02
			noise_character = 0.030
		"heavy":
			base_frequency_min = 31.0
			base_frequency_max = 112.0
			harmonic_ratio = 1.49
			third_ratio = 0.48
			harmonic_gain = 0.32
			third_gain = 0.20
			engine_gain = 1.10
			noise_character = 0.025
		_:
			base_frequency_min = 48.0
			base_frequency_max = 182.0
			harmonic_ratio = 2.02
			third_ratio = 0.5
			harmonic_gain = 0.34
			third_gain = 0.08
			engine_gain = 1.0
			noise_character = 0.010

func _fill_buffer() -> void:
	if not enabled or playback == null:
		return
	var frames_available := playback.get_frames_available()
	if frames_available <= 0:
		return
	var rpm_frequency := lerpf(base_frequency_min, base_frequency_max, clampf(speed_ratio, 0.0, 1.0)) + throttle * (28.0 if profile == "electric" else 18.0)
	var harmonic_frequency := rpm_frequency * harmonic_ratio
	var third_frequency := rpm_frequency * third_ratio
	var base_increment := rpm_frequency / MIX_RATE
	var harmonic_increment := harmonic_frequency / MIX_RATE
	var third_increment := third_frequency / MIX_RATE
	var loose_surface := surface in ["dirt", "sand", "gravel", "grass"]
	var tire_level := 0.0
	if drifting:
		tire_level = 0.12
	elif loose_surface and speed_ratio > 0.18:
		tire_level = 0.045
	var boost_level := 0.09 if boosting else 0.0
	if profile == "electric":
		boost_level *= 1.25
	var sfx_volume := clampf(float(SettingsManager.get_value("sfx_volume", 0.9)), 0.0, 1.0)
	var master_volume := clampf(float(SettingsManager.get_value("master_volume", 1.0)), 0.0, 1.0)
	var engine_level := lerpf(0.045, 0.095, throttle) * lerpf(0.72, 1.0, clampf(speed_ratio, 0.0, 1.0)) * engine_gain
	for _index in range(frames_available):
		var engine_sample := sin(phase * TAU) * engine_level
		engine_sample += sin(harmonic_phase * TAU) * engine_level * harmonic_gain
		engine_sample += sin(third_phase * TAU) * engine_level * third_gain
		engine_sample += randf_range(-1.0, 1.0) * noise_character * engine_level
		var tire_sample := randf_range(-1.0, 1.0) * tire_level
		var boost_sample := sin(harmonic_phase * TAU * 1.91) * boost_level
		var impact_noise := randf_range(-1.0, 1.0) * impact_envelope * 0.26
		var impact_thump := sin(phase * TAU * 0.37) * impact_envelope * 0.16
		var sample := clampf((engine_sample + tire_sample + boost_sample + impact_noise + impact_thump) * sfx_volume * master_volume, -0.48, 0.48)
		playback.push_frame(Vector2(sample, sample))
		phase = fposmod(phase + base_increment, 1.0)
		harmonic_phase = fposmod(harmonic_phase + harmonic_increment, 1.0)
		third_phase = fposmod(third_phase + third_increment, 1.0)
