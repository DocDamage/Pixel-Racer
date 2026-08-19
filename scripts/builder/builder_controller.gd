extends Node
class_name BuilderController

signal track_replaced(track)
signal track_changed
signal test_requested
signal save_requested
signal load_requested
signal tool_changed(tool_name: String)
signal selection_changed(rect: Rect2i, active: bool)
signal clipboard_changed(has_content: bool)

const TOOLS := ["road", "sand", "dirt", "grass", "start_finish", "checkpoint", "barrier", "erase"]

var track = null
var renderer: TrackRenderer = null
var runtime: TrackRuntime = null
var undo_stack := TrackUndoStack.new()
var edit_ops := TrackEditOps.new()
var current_tool_index := 0
var cursor_cell := Vector2i(6, 6)
var enabled := false
var checkpoint_sequence := 0
var barrier_rotation := 0
var camera: Camera2D = null
var paint_held := false
var selection_drag := false
var selection_active := false
var selection_start := Vector2i.ZERO
var selection_end := Vector2i.ZERO
var clipboard: Dictionary = {}
var _last_painted := Vector2i(-9999, -9999)

func setup(source_track, source_renderer: TrackRenderer, source_runtime: TrackRuntime, source_camera: Camera2D) -> void:
	track = source_track
	renderer = source_renderer
	runtime = source_runtime
	camera = source_camera
	undo_stack.clear()
	clear_selection()
	_recalculate_checkpoint_sequence()
	_update_cursor()

func set_enabled(value: bool) -> void:
	enabled = value
	if renderer != null:
		renderer.cursor_visible = value
		renderer.queue_redraw()

func set_track(source_track) -> void:
	track = source_track
	undo_stack.clear()
	clear_selection()
	_recalculate_checkpoint_sequence()
	track_replaced.emit(track)
	_update_cursor()

func current_tool() -> String:
	return TOOLS[current_tool_index]

func set_tool(tool_name: String) -> void:
	var index := TOOLS.find(tool_name)
	if index < 0:
		return
	current_tool_index = index
	tool_changed.emit(current_tool())

func cycle_tool(direction: int) -> void:
	current_tool_index = posmod(current_tool_index + direction, TOOLS.size())
	tool_changed.emit(current_tool())

func rotate_barrier() -> void:
	barrier_rotation = posmod(barrier_rotation + 1, 4)
	track_changed.emit()

func undo() -> void:
	if not undo_stack.can_undo():
		return
	track = undo_stack.undo(track)
	clear_selection()
	track_replaced.emit(track)
	track_changed.emit()

func redo() -> void:
	if not undo_stack.can_redo():
		return
	track = undo_stack.redo(track)
	clear_selection()
	track_replaced.emit(track)
	track_changed.emit()

func clear_selection() -> void:
	selection_active = false
	selection_drag = false
	if renderer != null:
		renderer.set_selection(Rect2i(), false)
	selection_changed.emit(Rect2i(), false)

func selection_rect() -> Rect2i:
	var min_cell := Vector2i(mini(selection_start.x, selection_end.x), mini(selection_start.y, selection_end.y))
	var max_cell := Vector2i(maxi(selection_start.x, selection_end.x), maxi(selection_start.y, selection_end.y))
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)

func copy_selection() -> void:
	if not selection_active or track == null:
		return
	clipboard = edit_ops.capture(track, selection_start, selection_end)
	clipboard_changed.emit(not clipboard.is_empty())

func cut_selection() -> void:
	if not selection_active or track == null:
		return
	copy_selection()
	undo_stack.record_before(track)
	edit_ops.erase_region(track, selection_start, selection_end)
	clear_selection()
	_after_edit()

func paste_clipboard() -> void:
	if clipboard.is_empty() or track == null or not track.in_bounds(cursor_cell):
		return
	undo_stack.record_before(track)
	var pasted := edit_ops.paste(track, clipboard, cursor_cell)
	selection_start = pasted.position
	selection_end = pasted.end - Vector2i.ONE
	selection_active = true
	_update_selection_overlay()
	_recalculate_checkpoint_sequence()
	_after_edit()

func rotate_clipboard() -> void:
	if clipboard.is_empty():
		rotate_barrier()
		return
	clipboard = edit_ops.rotate_clockwise(clipboard)
	clipboard_changed.emit(true)

func mirror_clipboard() -> void:
	if clipboard.is_empty():
		return
	clipboard = edit_ops.mirror_horizontal(clipboard)
	clipboard_changed.emit(true)

func delete_selection() -> void:
	if not selection_active or track == null:
		return
	undo_stack.record_before(track)
	edit_ops.erase_region(track, selection_start, selection_end)
	clear_selection()
	_after_edit()

func eyedropper() -> void:
	if track == null or not track.in_bounds(cursor_cell):
		return
	var sample := edit_ops.eyedrop(track, cursor_cell)
	var tool := str(sample.get("tool", ""))
	if tool == "barrier":
		barrier_rotation = int(sample.get("rotation_steps", 0))
	if tool in TOOLS:
		set_tool(tool)

func _process(delta: float) -> void:
	if not enabled or track == null:
		return
	_handle_camera(delta)
	if Input.is_action_just_pressed("builder_next_tool"):
		cycle_tool(1)
	if Input.is_action_just_pressed("builder_prev_tool"):
		cycle_tool(-1)
	if Input.is_action_just_pressed("builder_undo"):
		undo()
	if Input.is_action_just_pressed("builder_redo"):
		redo()
	if Input.is_action_just_pressed("builder_save"):
		save_requested.emit()
	if Input.is_action_just_pressed("builder_load"):
		load_requested.emit()
	if Input.is_action_just_pressed("toggle_test"):
		test_requested.emit()
	if Input.is_action_just_pressed("builder_place"):
		_place_current()
	if Input.is_action_just_pressed("builder_erase"):
		_erase_current()
	if InputMap.has_action("builder_eyedropper") and Input.is_action_just_pressed("builder_eyedropper"):
		eyedropper()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or track == null:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		cursor_cell = track.world_to_cell(_mouse_world_position(motion.position))
		_update_cursor()
		if selection_drag:
			selection_end = _clamp_cell(cursor_cell)
			_update_selection_overlay()
		elif paint_held and cursor_cell != _last_painted and current_tool() in ["road", "sand", "dirt", "grass", "erase"]:
			_place_current()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			cursor_cell = track.world_to_cell(_mouse_world_position(mouse.position))
			_update_cursor()
			if mouse.shift_pressed:
				if mouse.pressed:
					paint_held = false
					selection_drag = true
					selection_active = true
					selection_start = _clamp_cell(cursor_cell)
					selection_end = selection_start
					_update_selection_overlay()
				else:
					selection_drag = false
			else:
				paint_held = mouse.pressed
				if mouse.pressed:
					_place_current()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			cursor_cell = track.world_to_cell(_mouse_world_position(mouse.position))
			_erase_current()
		elif mouse.button_index == MOUSE_BUTTON_MIDDLE and mouse.pressed:
			cursor_cell = track.world_to_cell(_mouse_world_position(mouse.position))
			eyedropper()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_zoom_camera(1.12)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_zoom_camera(0.89)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.ctrl_pressed:
			match key.physical_keycode:
				KEY_C: copy_selection()
				KEY_X: cut_selection()
				KEY_V: paste_clipboard()
				_: pass
			return
		match key.physical_keycode:
			KEY_1: set_tool("road")
			KEY_2: set_tool("sand")
			KEY_3: set_tool("dirt")
			KEY_4: set_tool("grass")
			KEY_5: set_tool("start_finish")
			KEY_6: set_tool("checkpoint")
			KEY_7: set_tool("barrier")
			KEY_8: set_tool("erase")
			KEY_X: eyedropper()
			KEY_R: rotate_clipboard()
			KEY_M: mirror_clipboard()
			KEY_DELETE: delete_selection()
			KEY_ESCAPE: clear_selection()
			_: pass

func _place_current() -> void:
	if not track.in_bounds(cursor_cell):
		return
	undo_stack.record_before(track)
	match current_tool():
		"road": track.set_road(cursor_cell, "asphalt")
		"sand": track.set_terrain(cursor_cell, "sand")
		"dirt": track.set_terrain(cursor_cell, "dirt")
		"grass": track.set_terrain(cursor_cell, "grass")
		"start_finish":
			if track.has_road(cursor_cell):
				track.place_race_object("start_finish", cursor_cell)
		"checkpoint":
			if track.has_road(cursor_cell):
				track.place_race_object("checkpoint", cursor_cell, checkpoint_sequence)
				checkpoint_sequence += 1
		"barrier": track.add_object("barrier", cursor_cell, barrier_rotation)
		"erase": track.erase_at(cursor_cell)
	_last_painted = cursor_cell
	_after_edit()

func _erase_current() -> void:
	if not track.in_bounds(cursor_cell):
		return
	undo_stack.record_before(track)
	track.erase_at(cursor_cell)
	_after_edit()

func _after_edit() -> void:
	if renderer != null:
		renderer.queue_redraw()
	if runtime != null:
		runtime.refresh_objects()
	track_changed.emit()

func _recalculate_checkpoint_sequence() -> void:
	checkpoint_sequence = 0
	if track == null:
		return
	var checkpoints := track.get_checkpoints_sorted()
	if not checkpoints.is_empty():
		checkpoint_sequence = int(checkpoints.back().get("sequence_index", -1)) + 1

func _update_cursor() -> void:
	if renderer != null:
		renderer.set_cursor(cursor_cell, enabled)

func _update_selection_overlay() -> void:
	if renderer != null:
		renderer.set_selection(selection_rect(), selection_active)
	selection_changed.emit(selection_rect(), selection_active)

func _clamp_cell(cell: Vector2i) -> Vector2i:
	if track == null:
		return cell
	return Vector2i(clampi(cell.x, 0, track.width - 1), clampi(cell.y, 0, track.height - 1))

func _mouse_world_position(viewport_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * viewport_position

func _handle_camera(delta: float) -> void:
	if camera == null:
		return
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	if Input.is_key_pressed(KEY_UP): move.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN): move.y += 1.0
	var joy := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joy.length() > 0.25:
		move = joy
	if move != Vector2.ZERO:
		camera.position += move.normalized() * 420.0 * delta / camera.zoom.x

func _zoom_camera(factor: float) -> void:
	if camera == null:
		return
	var next := clampf(camera.zoom.x * factor, 0.35, 2.5)
	camera.zoom = Vector2.ONE * next
