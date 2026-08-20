extends Node2D
class_name AssetGallery

const PAGE_SIZE := 12
const COLUMNS := 4
const CARD_SIZE := Vector2(152, 84)
const BACKGROUNDS := {
	"grass": Color("#286a32"),
	"asphalt": Color("#403949"),
	"sand": Color("#d4a359"),
	"dark": Color("#11141a")
}

var catalog := RuntimeAssetCatalog.new()
var builder_catalog := BuilderAssetCatalog.new()
var asset_ids: Array[String] = []
var filtered_ids: Array[String] = []
var page := 0
var zoom_level := 2.0
var background_name := "grass"
var type_filter := "all"
var card_root: Node2D
var header: Label
var status: Label

func _ready() -> void:
	asset_ids = catalog.ids()
	filtered_ids = asset_ids.duplicate()
	card_root = Node2D.new()
	card_root.name = "Cards"
	add_child(card_root)
	_create_ui()
	_rebuild_page()
	queue_redraw()

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "GalleryUI"
	add_child(canvas)
	header = Label.new()
	header.position = Vector2(10, 6)
	header.add_theme_font_size_override("font_size", 15)
	canvas.add_child(header)
	status = Label.new()
	status.position = Vector2(10, 26)
	status.add_theme_font_size_override("font_size", 9)
	canvas.add_child(status)
	var help := Label.new()
	help.position = Vector2(10, 342)
	help.text = "←/→ page   1 grass   2 asphalt   3 sand   4 dark   +/- zoom   T filter"
	help.add_theme_font_size_override("font_size", 8)
	canvas.add_child(help)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_LEFT: _set_page(page - 1)
		KEY_RIGHT: _set_page(page + 1)
		KEY_1: _set_background("grass")
		KEY_2: _set_background("asphalt")
		KEY_3: _set_background("sand")
		KEY_4: _set_background("dark")
		KEY_EQUAL: _set_zoom(zoom_level + 1.0)
		KEY_MINUS: _set_zoom(zoom_level - 1.0)
		KEY_T: _cycle_type_filter()
		_: return
	get_viewport().set_input_as_handled()

func _set_page(value: int) -> void:
	var pages := maxi(1, ceili(float(filtered_ids.size()) / float(PAGE_SIZE)))
	page = posmod(value, pages)
	_rebuild_page()

func _set_background(value: String) -> void:
	background_name = value if BACKGROUNDS.has(value) else "grass"
	_update_status()
	queue_redraw()

func _set_zoom(value: float) -> void:
	zoom_level = clampf(value, 1.0, 4.0)
	_rebuild_page()

func _cycle_type_filter() -> void:
	var seen: Dictionary = {}
	for asset_id in asset_ids:
		seen[str(catalog.asset(asset_id).get("type", "unknown"))] = true
	var types: Array[String] = ["all"]
	var sorted_types: Array[String] = []
	for asset_type in seen:
		sorted_types.append(str(asset_type))
	sorted_types.sort()
	types.append_array(sorted_types)
	var index := maxi(0, types.find(type_filter))
	type_filter = types[posmod(index + 1, types.size())]
	filtered_ids.clear()
	for asset_id in asset_ids:
		if type_filter == "all" or str(catalog.asset(asset_id).get("type", "")) == type_filter:
			filtered_ids.append(asset_id)
	page = 0
	_rebuild_page()

func _rebuild_page() -> void:
	for child in card_root.get_children():
		child.queue_free()
	var start := page * PAGE_SIZE
	var end := mini(filtered_ids.size(), start + PAGE_SIZE)
	for index in range(start, end):
		var local_index := index - start
		var column := local_index % COLUMNS
		var row := local_index / COLUMNS
		_create_card(filtered_ids[index], Vector2(4 + column * 159, 46 + row * 96))
	var pages := maxi(1, ceili(float(filtered_ids.size()) / float(PAGE_SIZE)))
	header.text = "PIXEL TRACK WORKS — ASSET GALLERY   %d/%d" % [page + 1, pages]
	_update_status()
	queue_redraw()

func _update_status() -> void:
	status.text = "%d assets • filter %s • %dx • %s" % [filtered_ids.size(), type_filter, int(zoom_level), background_name]

func _create_card(asset_id: String, origin: Vector2) -> void:
	var definition := catalog.asset(asset_id)
	var holder := Node2D.new()
	holder.position = origin + Vector2(CARD_SIZE.x * 0.5, 34)
	card_root.add_child(holder)
	var frames := int(definition.get("frames", 0))
	if frames > 1 and not str(definition.get("atlas_path", "")).is_empty():
		var actor := SpriteStripActor.new()
		if actor.setup(asset_id):
			actor.scale = Vector2.ONE * zoom_level
			holder.add_child(actor)
	else:
		var sprite := AssetSpriteFactory.create_sprite(asset_id)
		if sprite != null:
			sprite.scale = Vector2.ONE * zoom_level
			holder.add_child(sprite)
	var builder_entry := builder_catalog.entry(asset_id)
	if not builder_entry.is_empty():
		_draw_collision_guide(holder, str(builder_entry.get("collision", "none")))
	var label := Label.new()
	label.position = Vector2(-CARD_SIZE.x * 0.5, 34)
	label.size = Vector2(CARD_SIZE.x, 30)
	label.text = "%s\n%s" % [asset_id, str(definition.get("type", ""))]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 7)
	holder.add_child(label)

func _draw_collision_guide(holder: Node2D, profile: String) -> void:
	var size := _collision_size(profile)
	if size == Vector2.ZERO:
		return
	var guide := Polygon2D.new()
	guide.polygon = PackedVector2Array([
		Vector2(-size.x, -size.y) * 0.5,
		Vector2(size.x, -size.y) * 0.5,
		Vector2(size.x, size.y) * 0.5,
		Vector2(-size.x, size.y) * 0.5
	])
	guide.color = Color(1.0, 0.2, 0.2, 0.18)
	holder.add_child(guide)

func _collision_size(profile: String) -> Vector2:
	match profile:
		"tree_trunk_small": return Vector2(12, 16)
		"rock_small": return Vector2(30, 14)
		"building_medium": return Vector2(64, 50)
		"pavilion": return Vector2(72, 36)
		"barrel_dynamic": return Vector2(16, 18)
		"tire_dynamic": return Vector2(14, 14)
		"trigger": return Vector2(34, 16)
	return Vector2.ZERO

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), BACKGROUNDS.get(background_name, BACKGROUNDS["grass"]), true)
	for local_index in range(PAGE_SIZE):
		var column := local_index % COLUMNS
		var row := local_index / COLUMNS
		var rect := Rect2(Vector2(4 + column * 159, 42 + row * 96), CARD_SIZE)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.28), true)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.18), false, 1.0)
		var center := rect.position + Vector2(rect.size.x * 0.5, 34)
		draw_line(center - Vector2(4, 0), center + Vector2(4, 0), Color(0.2, 0.9, 1.0, 0.8), 1.0)
		draw_line(center - Vector2(0, 4), center + Vector2(0, 4), Color(0.2, 0.9, 1.0, 0.8), 1.0)
