extends TrackRenderer
class_name CatalogTrackRenderer

var visual_theme_catalog := VisualThemeCatalog.new()
var _theme_texture_cache: Dictionary = {}

func visual_theme_id() -> String:
	var fallback := visual_theme_catalog.default_theme()
	if track == null:
		return fallback
	var requested := str(track.metadata.get("visual_theme", fallback))
	return requested if visual_theme_catalog.has_theme(requested) else fallback

func visual_theme_name() -> String:
	var definition := visual_theme_catalog.theme(visual_theme_id())
	return str(definition.get("display_name", visual_theme_id()))

func set_visual_theme(theme_id: String) -> bool:
	if track == null or not visual_theme_catalog.has_theme(theme_id):
		return false
	track.metadata["visual_theme"] = theme_id
	track.dirty = true
	queue_redraw()
	return true

func resolved_theme_entry(group: String, key: String) -> Dictionary:
	var definition := visual_theme_catalog.theme(visual_theme_id())
	var group_value: Variant = definition.get(group, {})
	if not group_value is Dictionary:
		return {}
	var entry_value: Variant = (group_value as Dictionary).get(key, {})
	return Dictionary(entry_value).duplicate(true) if entry_value is Dictionary else {}

func _draw_background_pattern(size: float) -> void:
	var grass := resolved_theme_entry("terrain", "grass")
	if grass.is_empty():
		super._draw_background_pattern(size)
		return
	for y in range(track.height):
		for x in range(track.width):
			_draw_theme_region(grass, Rect2(Vector2(x, y) * size, Vector2.ONE * size))

func _draw_terrain_texture(cell: Vector2i, size: float, surface: String) -> void:
	var entry := resolved_theme_entry("terrain", surface)
	if not entry.is_empty() and _draw_theme_region(entry, Rect2(Vector2(cell) * size, Vector2.ONE * size)):
		return
	super._draw_terrain_texture(cell, size, surface)

func _draw_road_texture(center: Vector2, mask: int, size: float, road_width: float, surface: String, width_name: String, route_id: String) -> bool:
	if surface == "asphalt" and width_name == "standard" and mask in [TrackData.EAST | TrackData.WEST, TrackData.NORTH | TrackData.SOUTH]:
		var straight := resolved_theme_entry("roads", "straight")
		if not straight.is_empty():
			var rotation := PI * 0.5 if mask == (TrackData.NORTH | TrackData.SOUTH) else 0.0
			if _draw_theme_region_rotated(straight, center, size, rotation):
				return true
	return super._draw_road_texture(center, mask, size, road_width, surface, width_name, route_id)

func _draw_theme_region(entry: Dictionary, destination: Rect2, modulate: Color = Color.WHITE) -> bool:
	var texture := _theme_texture(entry)
	var source := _theme_source_rect(entry)
	if texture == null or source.size.x <= 0.0 or source.size.y <= 0.0:
		return false
	draw_texture_rect_region(texture, destination, source, modulate)
	return true

func _draw_theme_region_rotated(entry: Dictionary, center: Vector2, size: float, rotation: float) -> bool:
	var texture := _theme_texture(entry)
	var source := _theme_source_rect(entry)
	if texture == null or source.size.x <= 0.0 or source.size.y <= 0.0:
		return false
	draw_set_transform(center, rotation, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(Vector2.ONE * (-size * 0.5), Vector2.ONE * size), source, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func _theme_texture(entry: Dictionary) -> Texture2D:
	var path := str(entry.get("texture", ""))
	if path.is_empty():
		return null
	if _theme_texture_cache.has(path):
		return _theme_texture_cache[path] as Texture2D
	var texture := load(path) as Texture2D
	if texture != null:
		_theme_texture_cache[path] = texture
	return texture

func _theme_source_rect(entry: Dictionary) -> Rect2:
	var raw_region: Variant = entry.get("region", [])
	if not raw_region is Array or (raw_region as Array).size() < 4:
		return Rect2()
	var region := raw_region as Array
	return Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
