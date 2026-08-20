extends Node
class_name UIAudioController

const MIX_RATE := 22050.0
const BUFFER_LENGTH := 0.10

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var envelope := 0.0
var frequency := 520.0
var tone_decay := 9.0
var _last_hovered: Control

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	player = AudioStreamPlayer.new()
	player.name = "UIAudio"
	player.stream = generator
	player.bus = &"Master"
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	_fill_buffer()

func _process(delta: float) -> void:
	envelope = move_toward(envelope, 0.0, delta * tone_decay)
	_fill_buffer()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			var hovered := get_viewport().gui_get_hovered_control()
			if hovered is BaseButton:
				play_confirm()
	elif event.is_action_pressed("ui_accept"):
		var focus := get_viewport().gui_get_focus_owner()
		if focus is BaseButton:
			play_confirm()
	elif event.is_action_pressed("ui_cancel"):
		play_cancel()

func play_focus() -> void:
	_trigger(610.0, 0.16, 11.0)

func play_confirm() -> void:
	_trigger(790.0, 0.26, 8.5)

func play_cancel() -> void:
	_trigger(310.0, 0.20, 10.0)

func play_error() -> void:
	_trigger(185.0, 0.34, 6.5)

func _on_focus_changed(control: Control) -> void:
	if control == null or control == _last_hovered:
		return
	_last_hovered = control
	if control is BaseButton or control is OptionButton or control is Slider:
		play_focus()

func _trigger(hz: float, strength: float, decay: float) -> void:
	frequency = hz
	envelope = maxf(envelope, strength)
	tone_decay = decay
	_fill_buffer()

func _fill_buffer() -> void:
	if playback == null:
		return
	var available := playback.get_frames_available()
	if available <= 0:
		return
	var ui_volume := clampf(float(SettingsManager.get_value("sfx_volume", 0.9)), 0.0, 1.0)
	var master_volume := clampf(float(SettingsManager.get_value("master_volume", 1.0)), 0.0, 1.0)
	var increment := frequency / MIX_RATE
	for _index in range(available):
		var sample := sin(phase * TAU) * envelope
		sample += sin(phase * TAU * 2.01) * envelope * 0.18
		sample = clampf(sample * ui_volume * master_volume, -0.36, 0.36)
		playback.push_frame(Vector2(sample, sample))
		phase = fposmod(phase + increment, 1.0)
