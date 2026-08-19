extends Control
class_name DialogueOverlay

signal advance_requested

var portrait: TextureRect
var fallback_portrait: Label
var speaker_label: Label
var message_label: Label
var continue_label: Label
var panel: PanelContainer
var current_entry: DialogueEntry = null

func _ready() -> void:
	set_process_unhandled_input(true)
	_build()
	hide_entry()

func show_entry(entry: DialogueEntry, atlas: PortraitAtlas = null, speaker_name: String = "") -> void:
	if entry == null:
		return
	_ensure_built()
	current_entry = entry
	var resolved_name: String = speaker_name if not speaker_name.is_empty() else entry.speaker_id.replace("_", " ").capitalize()
	speaker_label.text = resolved_name
	message_label.text = entry.text
	continue_label.visible = entry.blocking
	var portrait_texture: Texture2D = atlas.texture_for(entry.portrait_id) if atlas != null else null
	portrait.texture = portrait_texture
	portrait.visible = portrait_texture != null
	fallback_portrait.visible = portrait_texture == null
	fallback_portrait.text = _initials(resolved_name)
	mouse_filter = Control.MOUSE_FILTER_STOP if entry.blocking else Control.MOUSE_FILTER_IGNORE
	visible = true

func hide_entry() -> void:
	current_entry = null
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if portrait != null:
		portrait.texture = null

func _unhandled_input(event: InputEvent) -> void:
	if not visible or current_entry == null or not current_entry.blocking:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		advance_requested.emit()
		get_viewport().set_input_as_handled()

func _build() -> void:
	if panel != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.position = Vector2(62, 246)
	panel.size = Vector2(516, 98)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.075, 0.96)
	style.border_width_top = 2
	style.border_color = Color("#ff4fa3")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	panel.add_child(row)
	var portrait_stack := Control.new()
	portrait_stack.custom_minimum_size = Vector2(76, 76)
	row.add_child(portrait_stack)
	portrait = TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stack.add_child(portrait)
	fallback_portrait = Label.new()
	fallback_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fallback_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_portrait.add_theme_font_size_override("font_size", 22)
	fallback_portrait.add_theme_color_override("font_color", Color("#37d9ff"))
	fallback_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stack.add_child(fallback_portrait)
	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(405, 76)
	row.add_child(text_box)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 11)
	speaker_label.add_theme_color_override("font_color", Color("#ff4fa3"))
	text_box.add_child(speaker_label)
	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(405, 42)
	message_label.add_theme_font_size_override("font_size", 11)
	message_label.add_theme_color_override("font_color", Color("#f4f7fb"))
	text_box.add_child(message_label)
	continue_label = Label.new()
	continue_label.text = "A / ENTER • CONTINUE"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.add_theme_font_size_override("font_size", 9)
	continue_label.add_theme_color_override("font_color", Color("#a9b2c5"))
	text_box.add_child(continue_label)

func _ensure_built() -> void:
	if panel == null:
		_build()

func _initials(name_value: String) -> String:
	var words: PackedStringArray = name_value.split(" ", false)
	var output: String = ""
	for word in words:
		if word.length() > 0:
			output += word.substr(0, 1).to_upper()
		if output.length() >= 2:
			break
	return output if not output.is_empty() else "?"
