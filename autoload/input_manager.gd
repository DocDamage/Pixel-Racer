extends Node

const ACTIONS := {
	"accelerate": [KEY_W, KEY_UP],
	"brake": [KEY_S, KEY_DOWN],
	"steer_left": [KEY_A, KEY_LEFT],
	"steer_right": [KEY_D, KEY_RIGHT],
	"handbrake": [KEY_SPACE],
	"boost": [KEY_SHIFT],
	"reset_vehicle": [KEY_R],
	"toggle_test": [KEY_F5],
	"builder_undo": [KEY_Z],
	"builder_redo": [KEY_Y],
	"builder_save": [KEY_F2],
	"builder_load": [KEY_F3],
	"builder_next_tool": [KEY_E],
	"builder_prev_tool": [KEY_Q],
	"builder_place": [KEY_ENTER],
	"builder_erase": [KEY_BACKSPACE],
	"builder_eyedropper": [KEY_X]
}

func _ready() -> void:
	for action in ACTIONS:
		_ensure_action(action)
		for keycode in ACTIONS[action]:
			_add_key(action, keycode)
	_add_joy_button("accelerate", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("brake", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_axis("accelerate", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_axis("brake", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_joy_axis("steer_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("steer_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button("handbrake", JOY_BUTTON_B)
	_add_joy_button("boost", JOY_BUTTON_A)
	_add_joy_button("reset_vehicle", JOY_BUTTON_Y)
	_add_joy_button("toggle_test", JOY_BUTTON_START)
	_add_joy_button("builder_place", JOY_BUTTON_A)
	_add_joy_button("builder_erase", JOY_BUTTON_B)
	_add_joy_button("builder_eyedropper", JOY_BUTTON_X)
	_add_joy_button("builder_prev_tool", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button("builder_next_tool", JOY_BUTTON_RIGHT_SHOULDER)

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)

func _add_key(action: String, keycode: int) -> void:
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_joy_button(action: String, button: int) -> void:
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_joy_axis(action: String, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
