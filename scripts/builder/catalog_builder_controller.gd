extends BuilderController
class_name CatalogBuilderController

signal catalog_asset_changed(asset_id: String, display_name: String)
signal theme_cycle_requested(direction: int)

var asset_catalog := BuilderAssetCatalog.new()
var selected_catalog_asset := ""
var _catalog_ids: Array[String] = []
var _catalog_index := -1

func _ready() -> void:
	_catalog_ids = asset_catalog.ids()

func current_tool() -> String:
	if not selected_catalog_asset.is_empty():
		var definition := asset_catalog.entry(selected_catalog_asset)
		return str(definition.get("name", selected_catalog_asset))
	return super.current_tool()

func selected_asset_definition() -> Dictionary:
	return asset_catalog.entry(selected_catalog_asset) if not selected_catalog_asset.is_empty() else {}

func select_catalog_asset(asset_id: String) -> bool:
	if not asset_catalog.has_entry(asset_id):
		return false
	selected_catalog_asset = asset_id
	if _catalog_ids.is_empty():
		_catalog_ids = asset_catalog.ids()
	_catalog_index = _catalog_ids.find(asset_id)
	super.set_tool("barrier")
	var definition := asset_catalog.entry(asset_id)
	var display_name := str(definition.get("name", asset_id))
	catalog_asset_changed.emit(asset_id, display_name)
	tool_changed.emit(display_name)
	return true

func cycle_catalog_asset(direction: int = 1) -> void:
	if _catalog_ids.is_empty():
		_catalog_ids = asset_catalog.ids()
	if _catalog_ids.is_empty():
		return
	if _catalog_index < 0:
		_catalog_index = 0 if direction >= 0 else _catalog_ids.size() - 1
	else:
		_catalog_index = posmod(_catalog_index + direction, _catalog_ids.size())
	select_catalog_asset(_catalog_ids[_catalog_index])

func clear_catalog_asset() -> void:
	if selected_catalog_asset.is_empty():
		return
	selected_catalog_asset = ""
	_catalog_index = -1
	catalog_asset_changed.emit("", "")

func set_tool(tool_name: String) -> void:
	clear_catalog_asset()
	super.set_tool(tool_name)

func cycle_tool(direction: int) -> void:
	clear_catalog_asset()
	super.cycle_tool(direction)

func eyedropper() -> void:
	if track == null or not track.in_bounds(cursor_cell):
		return
	var sample := edit_ops.eyedrop(track, cursor_cell)
	var sampled_type := str(sample.get("tool", ""))
	if asset_catalog.has_entry(sampled_type):
		barrier_rotation = int(sample.get("rotation_steps", 0))
		select_catalog_asset(sampled_type)
		return
	clear_catalog_asset()
	super.eyedropper()

func _place_current() -> void:
	if selected_catalog_asset.is_empty():
		super._place_current()
		return
	if track == null or not track.in_bounds(cursor_cell):
		return
	undo_stack.record_before(track)
	track.add_object(selected_catalog_asset, cursor_cell, barrier_rotation)
	_last_painted = cursor_cell
	_after_edit()

func _unhandled_input(event: InputEvent) -> void:
	if enabled:
		if event is InputEventKey:
			var key := event as InputEventKey
			if key.pressed and not key.echo and not key.ctrl_pressed:
				if key.physical_keycode == KEY_C:
					cycle_catalog_asset(-1 if key.shift_pressed else 1)
					get_viewport().set_input_as_handled()
					return
				if key.physical_keycode == KEY_V:
					theme_cycle_requested.emit(-1 if key.shift_pressed else 1)
					get_viewport().set_input_as_handled()
					return
		elif event is InputEventJoypadButton:
			var button := event as InputEventJoypadButton
			if button.pressed and button.button_index == JOY_BUTTON_Y:
				cycle_catalog_asset(1)
				get_viewport().set_input_as_handled()
				return
			if button.pressed and button.button_index == JOY_BUTTON_BACK:
				theme_cycle_requested.emit(1)
				get_viewport().set_input_as_handled()
				return
	super._unhandled_input(event)
