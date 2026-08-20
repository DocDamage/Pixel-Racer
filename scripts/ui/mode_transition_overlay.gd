extends CanvasLayer
class_name ModeTransitionOverlay

const FADE_DURATION := 0.20
const MODE_ALPHA := {
	GameState.MODE_MENU: 0.22,
	GameState.MODE_BUILDER: 0.16,
	GameState.MODE_TEST: 0.22,
	GameState.MODE_RACE: 0.28
}

var shade: ColorRect
var _fade_tween: Tween = null

func _ready() -> void:
	layer = 90
	shade = ColorRect.new()
	shade.name = "ModeFade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(shade)
	if not GameState.mode_changed.is_connected(_on_mode_changed):
		GameState.mode_changed.connect(_on_mode_changed)

func _exit_tree() -> void:
	if GameState.mode_changed.is_connected(_on_mode_changed):
		GameState.mode_changed.disconnect(_on_mode_changed)

func pulse_for_mode(mode: String) -> void:
	if shade == null:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var alpha: float = float(MODE_ALPHA.get(mode, 0.18))
	shade.color = Color(0.0, 0.0, 0.0, alpha)
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(shade, "color:a", 0.0, FADE_DURATION)

func _on_mode_changed(mode: String) -> void:
	pulse_for_mode(mode)
