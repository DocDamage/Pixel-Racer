extends Control
class_name RaceRadioOverlay

var portrait: TextureRect
var fallback_portrait: Label
var speaker_label: Label
var message_label: Label
var panel: PanelContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_build()
	hide_entry()

func show_entry(entry: DialogueEntry, atlas: PortraitAtlas = null, speaker_name: String = "") -> void:
	if entry == null:
		return
	_ensure_built()
	var resolved_name: String = speaker_name if not speaker_name.is_empty() else entry.speaker_id.replace("_", " ").capitalize()
	speaker_label.text = resolved_name
	message_label.text = entry.text
	var portrait_texture: Texture2D = atlas.texture_for(entry.portrait_id) if atlas != null else null
	portrait.texture = portrait_texture
	portrait.visible = portrait_texture != null
	fallback_portrait.visible = portrait_texture == null
	fallback_portrait.text = _initials(resolved_name)
	visible = true

func hide_entry() -> void:
	visible = false
	if portrait != null:
		portrait.texture = null

func _build() -> void:
	if panel != null:
		return
	panel = PanelContainer.new()
	panel.position = Vector2(304, 18)
	panel.size = Vector2(326, 82)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.075, 0.93)
	style.border_width_left = 2
	style.border_color = Color("#37d9ff")
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 6
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	var portrait_stack := Control.new()
	portrait_stack.custom_minimum_size = Vector2(62, 62)
	portrait_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	fallback_portrait.add_theme_font_size_override("font_size", 18)
	fallback_portrait.add_theme_color_override("font_color", Color("#37d9ff"))
	fallback_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_stack.add_child(fallback_portrait)
	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(242, 62)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 10)
	speaker_label.add_theme_color_override("font_color", Color("#ff4fa3"))
	speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(speaker_label)
	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.max_lines_visible = 2
	message_label.add_theme_font_size_override("font_size", 10)
	message_label.add_theme_color_override("font_color", Color("#f4f7fb"))
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(message_label)

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
