extends Node

var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_gamepad_action_coverage()
	await _test_runtime_focusability()
	if failures == 0:
		print("Pixel Track Works controller audit tests: PASS")
		get_tree().quit(0)
	else:
		push_error("Pixel Track Works controller audit tests: %d failure(s)" % failures)
		get_tree().quit(1)

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
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var runtime_ui := instance.get("ui") as GameUI
	_expect(runtime_ui is CatalogGameUI, "catalog runtime uses the modern library UI")
	if runtime_ui != null:
		runtime_ui.open_track_library()
		await get_tree().process_frame
		var modern_share := _find_button_by_text(runtime_ui, "SHARE / IMPORT .PIXELTRACK")
		_expect(modern_share != null, "track library routes sharing through the portable package workflow")
		_expect(_find_button_by_text(runtime_ui, "IMPORT JSON") == null, "legacy JSON import button is absent")
		_expect(_find_button_by_text(runtime_ui, "EXPORT CURRENT") == null, "legacy direct-export button is absent")
		if modern_share != null:
			modern_share.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
	var sharing := instance.get_node_or_null("TrackSharingUI")
	_expect(sharing != null, "main runtime includes the track sharing panel")
	if sharing != null:
		_expect(sharing.has_method("is_panel_open"), "track sharing panel exposes a stable open-state contract")
		if sharing.has_method("is_panel_open"):
			_expect(bool(sharing.call("is_panel_open")), "modern track sharing panel opens from Track Library")
	_audit_focus(instance)
	if sharing != null and sharing.has_method("close_panel"):
		sharing.call("close_panel")
	var pause_controller := instance.get_node_or_null("PauseController")
	_expect(pause_controller != null, "main runtime includes the pause controller")
	if pause_controller != null:
		GameState.set_mode(GameState.MODE_RACE)
		_expect(bool(pause_controller.call("pause_game")), "pause controller pauses from a driving mode")
		_expect(get_tree().paused, "scene tree is paused during the pause menu")
		_expect(bool(pause_controller.call("is_pause_visible")), "pause menu is visible while paused")
		_expect(bool(pause_controller.call("resume_game", false)), "pause controller resumes gameplay")
		_expect(not get_tree().paused, "scene tree resumes after closing the pause menu")
		GameState.set_mode(GameState.MODE_MENU)
	if get_tree().paused:
		get_tree().paused = false
	instance.queue_free()
	await get_tree().process_frame

func _find_button_by_text(node: Node, text_value: String) -> Button:
	if node is Button and (node as Button).text == text_value:
		return node as Button
	for child in node.get_children():
		var found := _find_button_by_text(child, text_value)
		if found != null:
			return found
	return null

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
