extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_gamepad_action_coverage()
	await _test_runtime_focusability()
	if failures == 0:
		print("Pixel Track Works controller audit tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works controller audit tests: %d failure(s)" % failures)
		quit(1)

func _test_gamepad_action_coverage() -> void:
	var required: Array[StringName] = [
		&"accelerate",
		&"brake",
		&"steer_left",
		&"steer_right",
		&"handbrake",
		&"boost",
		&"reset_vehicle",
		&"pause"
	]
	for action in required:
		_expect(InputMap.has_action(action), "required action exists: %s" % String(action))
		if not InputMap.has_action(action):
			continue
		var has_gamepad := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_gamepad = true
				break
		_expect(has_gamepad, "required action has gamepad binding: %s" % String(action))
	for action in [&"ui_accept", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		_expect(InputMap.has_action(action), "core UI navigation action exists: %s" % String(action))

func _test_runtime_focusability() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(scene != null, "main runtime scene loads for focus audit")
	if scene == null:
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	_audit_focus(instance)
	instance.queue_free()
	await process_frame

func _audit_focus(node: Node) -> void:
	if node is Button or node is OptionButton or node is SpinBox or node is HSlider or node is VSlider or node is LineEdit or node is CheckBox:
		var control := node as Control
		_expect(control.focus_mode != Control.FOCUS_NONE, "interactive control is focusable: %s" % String(control.get_path()))
	for child in node.get_children():
		_audit_focus(child)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
