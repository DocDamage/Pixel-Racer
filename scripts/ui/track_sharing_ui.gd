extends CanvasLayer
class_name TrackSharingUI

const PANEL := Color("#151922")
const PANEL_2 := Color("#222735")
const ACCENT := Color("#37d9ff")
const MAGENTA := Color("#ff4fa3")
const GOLD := Color("#ffd166")
const GOOD := Color("#61e294")
const BAD := Color("#ff6b6b")
const TEXT := Color("#f4f7fb")
const MUTED := Color("#a9b2c5")
const EXPORT_ROOT := "user://track_exports"

var game: Node = null
var package_manager := TrackPackageManager.new()
var launch_button: Button
var shade: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var author_edit: LineEdit
var description_edit: LineEdit
var tags_edit: LineEdit
var status_label: Label
var import_preview: TextureRect
var import_info: Label
var confirm_import_button: Button
var _pending_import_path: String = ""

func _ready() -> void:
	game = get_parent()
	layer = 26
	_build()
	_refresh_visibility()

func _process(_delta: float) -> void:
	_refresh_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if panel != null and panel.visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _refresh_visibility() -> void:
	if launch_button == null or panel == null:
		return
	var menu_mode: bool = GameState.current_mode == GameState.MODE_MENU
	launch_button.visible = menu_mode and not panel.visible
	if not menu_mode and panel.visible:
		_close()

func _open() -> void:
	var track: TrackData = GameState.current_track as TrackData
	if track == null:
		return
	author_edit.text = track.author
	description_edit.text = str(track.metadata.get("description", ""))
	var tags: Array = Array(track.metadata.get("tags", []))
	tags_edit.text = ", ".join(tags.map(func(value: Variant) -> String: return str(value)))
	_pending_import_path = ""
	status_label.text = "Current track: %s" % track.name
	status_label.add_theme_color_override("font_color", MUTED)
	_clear_import_preview()
	shade.visible = true
	panel.visible = true
	launch_button.visible = false
	author_edit.grab_focus()

func _close() -> void:
	_pending_import_path = ""
	shade.visible = false
	panel.visible = false
	launch_button.visible = GameState.current_mode == GameState.MODE_MENU

func _export_current() -> void:
	var track: TrackData = GameState.current_track as TrackData
	if track == null:
		_set_status("No track is loaded.", BAD)
		return
	track.author = author_edit.text.strip_edges() if not author_edit.text.strip_edges().is_empty() else "Player"
	track.metadata["description"] = description_edit.text.strip_edges()
	track.metadata["tags"] = _parse_tags(tags_edit.text)
	track.dirty = true
	var preview_path := "user://tracks/%s/preview.png" % track.track_id
	if not TrackPreviewGenerator.new().save(track, preview_path):
		preview_path = ""
	var package_path: String = package_manager.export_single_file(track, EXPORT_ROOT, preview_path)
	if package_path.is_empty():
		_set_status("Export failed. Track data was not changed.", BAD)
		return
	_set_status("Exported %s" % package_path, GOOD)
	_play_sfx("play_save")

func _open_import_dialog() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray([
		"*.pixeltrack ; Pixel Track Works Package",
		"*.json ; Pixel Track JSON"
	])
	dialog.size = Vector2i(600, 360)
	dialog.file_selected.connect(func(path: String):
		_prepare_import(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()

func _prepare_import(path: String) -> void:
	_pending_import_path = path
	_clear_import_preview()
	if path.to_lower().ends_with(".pixeltrack"):
		var inspection: Dictionary = package_manager.inspect_single_file(path)
		if not bool(inspection.get("valid", false)):
			var errors: Array = Array(inspection.get("errors", []))
			_set_status("Package rejected: %s" % "; ".join(errors.map(func(value: Variant) -> String: return str(value))), BAD)
			_pending_import_path = ""
			return
		var metadata: Dictionary = inspection.get("metadata", {})
		import_info.text = _metadata_summary(metadata)
		var image: Image = _read_package_preview(path)
		if image != null and not image.is_empty():
			import_preview.texture = ImageTexture.create_from_image(image)
			import_preview.visible = true
		confirm_import_button.disabled = false
		confirm_import_button.grab_focus()
		_set_status("Package is compatible. Review it, then import.", ACCENT)
		return
	var preview_track: TrackData = SaveManager.load_track_path(path) as TrackData
	if preview_track == null:
		_set_status("JSON track could not be parsed.", BAD)
		_pending_import_path = ""
		return
	import_info.text = "%s\nAuthor: %s • schema %d\nLegacy JSON import" % [preview_track.name, preview_track.author, preview_track.schema_version]
	import_preview.texture = ImageTexture.create_from_image(TrackPreviewGenerator.new().render(preview_track))
	import_preview.visible = true
	confirm_import_button.disabled = false
	confirm_import_button.grab_focus()
	_set_status("JSON track parsed. Review it, then import.", ACCENT)

func _confirm_import() -> void:
	if _pending_import_path.is_empty():
		return
	var imported: TrackData = null
	if _pending_import_path.to_lower().ends_with(".pixeltrack"):
		imported = package_manager.import_single_file(_pending_import_path) as TrackData
	else:
		imported = SaveManager.import_track(_pending_import_path) as TrackData
	if imported == null:
		_set_status("Import failed; no saved track was replaced.", BAD)
		_play_sfx("play_invalid")
		return
	if game != null and game.has_method("set_track"):
		game.call("set_track", imported, true)
	if game != null and game.has_method("enter_builder"):
		_close()
		game.call("enter_builder")
	_play_sfx("play_unlock")

func _metadata_summary(metadata: Dictionary) -> String:
	var tags: Array = Array(metadata.get("tags", []))
	var tag_text: String = ", ".join(tags.map(func(value: Variant) -> String: return str(value)))
	if tag_text.is_empty():
		tag_text = "none"
	return "%s\nAuthor: %s • track schema %d\nTags: %s\n%s" % [
		str(metadata.get("name", "Unnamed Track")),
		str(metadata.get("author", "Unknown")),
		int(metadata.get("track_schema", -1)),
		tag_text,
		str(metadata.get("description", ""))
	]

func _read_package_preview(path: String) -> Image:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return null
	if not reader.file_exists("preview.png"):
		reader.close()
		return null
	var bytes: PackedByteArray = reader.read_file("preview.png")
	reader.close()
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return image

func _clear_import_preview() -> void:
	if import_preview != null:
		import_preview.texture = null
		import_preview.visible = false
	if import_info != null:
		import_info.text = "Choose a .pixeltrack package or legacy track JSON to inspect it before import."
	if confirm_import_button != null:
		confirm_import_button.disabled = true

func _parse_tags(value: String) -> Array[String]:
	var output: Array[String] = []
	for raw_tag in value.split(",", false):
		var tag: String = raw_tag.strip_edges()
		if tag.is_empty() or tag in output:
			continue
		output.append(tag.left(32))
		if output.size() >= 8:
			break
	return output

func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)

func _play_sfx(method_name: String) -> void:
	var node: Node = get_tree().get_first_node_in_group("game_sfx")
	if node != null and node.has_method(method_name):
		node.call(method_name)

func _build() -> void:
	launch_button = _button("SHARE TRACK", _open, GOLD, Vector2(118, 27))
	launch_button.position = Vector2(472, 82)
	add_child(launch_button)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.68)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.visible = false
	add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(48, 18)
	panel.size = Vector2(544, 324)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 10))
	panel.visible = false
	add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	var title := Label.new()
	title.text = "TRACK SHARING"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ACCENT)
	content.add_child(title)
	var details := Label.new()
	details.text = ".pixeltrack packages contain track data, metadata, and a preview image in one portable file."
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 10)
	details.add_theme_color_override("font_color", MUTED)
	content.add_child(details)
	author_edit = LineEdit.new()
	author_edit.placeholder_text = "Author"
	content.add_child(_labeled_row("Author", author_edit))
	description_edit = LineEdit.new()
	description_edit.placeholder_text = "Short description"
	content.add_child(_labeled_row("Description", description_edit))
	tags_edit = LineEdit.new()
	tags_edit.placeholder_text = "rally, technical, drift"
	content.add_child(_labeled_row("Tags", tags_edit))
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 5)
	content.add_child(action_row)
	action_row.add_child(_button("EXPORT .PIXELTRACK", _export_current, MAGENTA, Vector2(180, 28)))
	action_row.add_child(_button("IMPORT", _open_import_dialog, GOLD, Vector2(100, 28)))
	confirm_import_button = _button("IMPORT REVIEWED", _confirm_import, GOOD, Vector2(145, 28))
	confirm_import_button.disabled = true
	action_row.add_child(confirm_import_button)
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 8)
	content.add_child(preview_row)
	import_preview = TextureRect.new()
	import_preview.custom_minimum_size = Vector2(150, 84)
	import_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	import_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	import_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_row.add_child(import_preview)
	import_info = Label.new()
	import_info.custom_minimum_size = Vector2(345, 84)
	import_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	import_info.add_theme_font_size_override("font_size", 10)
	preview_row.add_child(import_info)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", MUTED)
	content.add_child(status_label)
	content.add_child(_button("CLOSE", _close, MUTED, Vector2(510, 25)))

func _labeled_row(label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 24)
	row.add_child(label)
	control.custom_minimum_size = Vector2(400, 24)
	row.add_child(control)
	return row

func _button(text_value: String, callback: Callable, accent: Color, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(accent.darkened(0.55), 5))
	button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.28), 5))
	button.add_theme_stylebox_override("focus", _panel_style(accent.darkened(0.18), 5))
	button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.12), 5))
	button.pressed.connect(callback)
	return button

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
