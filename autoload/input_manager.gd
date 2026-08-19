extends Node

const BINDINGS_PATH := "user://input_bindings.json"
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
	install_defaults()
	load_bindings()

func install_defaults() -> void:
	for action in ACTIONS:
		_ensure_action(action)
		InputMap.action_erase_events(action)
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

func reset_defaults() -> void:
	install_defaults()
	if FileAccess.file_exists(BINDINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BINDINGS_PATH))

func remap_key(action: String, keycode: int, append: bool = false) -> bool:
	if not InputMap.has_action(action):
		return false
	if not append:
		InputMap.action_erase_events(action)
	_add_key(action, keycode)
	save_bindings()
	return true

func remap_joy_button(action: String, button: int, append: bool = false) -> bool:
	if not InputMap.has_action(action):
		return false
	if not append:
		InputMap.action_erase_events(action)
	_add_joy_button(action, button)
	save_bindings()
	return true

func remap_joy_axis(action: String, axis: int, axis_value: float, append: bool = false) -> bool:
	if not InputMap.has_action(action):
		return false
	if not append:
		InputMap.action_erase_events(action)
	_add_joy_axis(action, axis, axis_value)
	save_bindings()
	return true

func binding_descriptions(action: String) -> Array[String]:
	var output: Array[String] = []
	if not InputMap.has_action(action):
		return output
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			output.append(OS.get_keycode_string(event.physical_keycode))
		elif event is InputEventJoypadButton:
			output.append("Pad Button %d" % event.button_index)
		elif event is InputEventJoypadMotion:
			output.append("Pad Axis %d %s" % [event.axis, "+" if event.axis_value > 0.0 else "-"])
	return output

func save_bindings() -> bool:
	var payload := {}
	for action in ACTIONS:
		var serialized: Array[Dictionary] = []
		for event in InputMap.action_get_events(action):
			var item := _serialize_event(event)
			if not item.is_empty():
				serialized.append(item)
		payload[action] = serialized
	var file := FileAccess.open(BINDINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true

func load_bindings() -> void:
	if not FileAccess.file_exists(BINDINGS_PATH):
		return
	var file := FileAccess.open(BINDINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	for action in parsed:
		if not InputMap.has_action(str(action)) or not parsed[action] is Array:
			continue
		InputMap.action_erase_events(str(action))
		for raw in parsed[action]:
			if raw is Dictionary:
				var event := _deserialize_event(raw)
				if event != null:
					InputMap.action_add_event(str(action), event)

func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "physical_keycode": event.physical_keycode}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "joy_axis", "axis": event.axis, "value": event.axis_value}
	return {}

func _deserialize_event(data: Dictionary):
	match str(data.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(data.get("physical_keycode", 0))
			return key
		"joy_button":
			var button := InputEventJoypadButton.new()
			button.button_index = int(data.get("button", 0))
			return button
		"joy_axis":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(data.get("axis", 0))
			motion.axis_value = float(data.get("value", 1.0))
			return motion
	return null

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)

func _add_key(action: String, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_joy_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_joy_axis(action: String, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
