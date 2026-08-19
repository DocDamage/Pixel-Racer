extends Node2D
class_name TrackRenderer

const COLOR_GRASS := Color("#286a32")
const COLOR_GRASS_ALT := Color("#2e7638")
const COLOR_ASPHALT := Color("#403949")
const COLOR_DIRT := Color("#8b5a2b")
const COLOR_SAND := Color("#d4a359")
const COLOR_GRAVEL := Color("#766d66")
const COLOR_CURB_RED := Color("#e94b45")
const COLOR_CURB_WHITE := Color("#f4eadf")
const COLOR_PIT := Color("#37d9ff")
const COLOR_ALTERNATE := Color("#ffd166")
const WIDTH_SCALE := {"narrow": 0.52, "standard": 0.68, "wide": 0.80, "extra_wide": 0.92}

var track = null
var cursor_cell := Vector2i.ZERO
var cursor_visible := false
var cursor_color := Color(0.2, 0.9, 1.0, 0.7)
var validation_issues: Array[Dictionary] = []
var show_grid := true
var selection_active := false
var selection_rect := Rect2i()

func set_track(source_track) -> void:
	track = source_track
	queue_redraw()

func set_cursor(cell: Vector2i, visible: bool = true) -> void:
	cursor_cell = cell
	cursor_visible = visible
	queue_redraw()

func set_validation_issues(issues: Array[Dictionary]) -> void:
	validation_issues = issues
	queue_redraw()

func set_selection(rect: Rect2i, active: bool) -> void:
	selection_rect = rect
	selection_active = active
	queue_redraw()

func _draw() -> void:
	if track == null:
		return
	var size := float(track.cell_size)
	var world_rect := Rect2(Vector2.ZERO, Vector2(track.width * track.cell_size, track.height * track.cell_size))
	draw_rect(world_rect, COLOR_GRASS)
	_draw_background_pattern(size)
	_draw_terrain(size)
	_draw_roads(size)
	_draw_race_objects(size)
	_draw_issue_markers(size)
	if show_grid:
		_draw_grid(size)
	if selection_active:
		var world_selection := Rect2(Vector2(selection_rect.position) * size, Vector2(selection_rect.size) * size)
		draw_rect(world_selection, Color(0.2, 0.85, 1.0, 0.12), true)
		draw_rect(world_selection, Color(0.2, 0.85, 1.0, 0.95), false, 3.0)
	if cursor_visible and track.in_bounds(cursor_cell):
		draw_rect(Rect2(Vector2(cursor_cell) * size, Vector2.ONE * size), cursor_color, false, 2.0)

func _draw_background_pattern(size: float) -> void:
	for y in range(track.height):
		for x in range(track.width):
			if (x + y) % 2 == 0:
				draw_rect(Rect2(Vector2(x, y) * size, Vector2.ONE * size), COLOR_GRASS_ALT, true)

func _draw_terrain(size: float) -> void:
	for key in track.terrain:
		var item: Dictionary = track.terrain[key]
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var type := str(item.get("type", "grass"))
		draw_rect(Rect2(Vector2(cell) * size, Vector2.ONE * size), _surface_color(type), true)

func _draw_roads(size: float) -> void:
	for cell in track.road_cells():
		var road: Dictionary = track.get_road(cell)
		var center := track.cell_to_world(cell)
		var mask: int = track.get_road_mask(cell)
		var surface := track.get_surface_at(cell)
		var road_color := _surface_color(surface)
		var road_width := size * float(WIDTH_SCALE.get(str(road.get("width", "standard")), WIDTH_SCALE["standard"]))
		var half := road_width * 0.5
		draw_rect(Rect2(center - Vector2(half, half), Vector2(road_width, road_width)), road_color, true)
		if (mask & TrackData.NORTH) != 0:
			draw_rect(Rect2(Vector2(center.x - half, cell.y * size), Vector2(road_width, size * 0.5)), road_color, true)
		if (mask & TrackData.SOUTH) != 0:
			draw_rect(Rect2(Vector2(center.x - half, center.y), Vector2(road_width, size * 0.5)), road_color, true)
		if (mask & TrackData.WEST) != 0:
			draw_rect(Rect2(Vector2(cell.x * size, center.y - half), Vector2(size * 0.5, road_width)), road_color, true)
		if (mask & TrackData.EAST) != 0:
			draw_rect(Rect2(Vector2(center.x, center.y - half), Vector2(size * 0.5, road_width)), road_color, true)
		_draw_curb_hints(center, mask, size, half)
		var route_id := track.get_route_id(cell)
		if route_id == "pit":
			_draw_route_hint(center, mask, size, COLOR_PIT, 3.0)
		elif route_id != "main" and not route_id.is_empty():
			_draw_route_hint(center, mask, size, COLOR_ALTERNATE, 2.5)

func _draw_curb_hints(center: Vector2, mask: int, size: float, half: float) -> void:
	var stripe := 3.0
	if mask in [TrackData.NORTH | TrackData.SOUTH, TrackData.NORTH, TrackData.SOUTH]:
		draw_line(Vector2(center.x - half, center.y - size * 0.5), Vector2(center.x - half, center.y + size * 0.5), COLOR_CURB_RED, stripe)
		draw_line(Vector2(center.x + half, center.y - size * 0.5), Vector2(center.x + half, center.y + size * 0.5), COLOR_CURB_WHITE, stripe)
	elif mask in [TrackData.EAST | TrackData.WEST, TrackData.EAST, TrackData.WEST]:
		draw_line(Vector2(center.x - size * 0.5, center.y - half), Vector2(center.x + size * 0.5, center.y - half), COLOR_CURB_RED, stripe)
		draw_line(Vector2(center.x - size * 0.5, center.y + half), Vector2(center.x + size * 0.5, center.y + half), COLOR_CURB_WHITE, stripe)

func _draw_route_hint(center: Vector2, mask: int, size: float, color: Color, width: float) -> void:
	var arm := size * 0.48
	if (mask & TrackData.NORTH) != 0:
		draw_line(center, center + Vector2(0, -arm), color, width)
	if (mask & TrackData.SOUTH) != 0:
		draw_line(center, center + Vector2(0, arm), color, width)
	if (mask & TrackData.WEST) != 0:
		draw_line(center, center + Vector2(-arm, 0), color, width)
	if (mask & TrackData.EAST) != 0:
		draw_line(center, center + Vector2(arm, 0), color, width)
	draw_circle(center, 3.5, color)

func _draw_race_objects(size: float) -> void:
	for item in track.race_objects:
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var center := track.cell_to_world(cell)
		var type := str(item.get("type", ""))
		if type == "start_finish":
			_draw_start_line(center, cell, size)
		elif type == "checkpoint":
			var rect := Rect2(center - Vector2(size * 0.4, size * 0.08), Vector2(size * 0.8, size * 0.16))
			draw_rect(rect, Color(0.1, 0.9, 1.0, 0.55), true)
			draw_string(ThemeDB.fallback_font, center + Vector2(-5, -8), str(int(item.get("sequence_index", 0)) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _draw_start_line(center: Vector2, cell: Vector2i, size: float) -> void:
	var mask: int = track.get_road_mask(cell)
	var vertical_track := ((mask & TrackData.NORTH) != 0) or ((mask & TrackData.SOUTH) != 0)
	var total := size * 0.68
	var segment := total / 6.0
	for i in range(6):
		var color := Color.WHITE if i % 2 == 0 else Color.BLACK
		if vertical_track:
			draw_rect(Rect2(Vector2(center.x - total * 0.5 + i * segment, center.y - 4), Vector2(segment, 8)), color, true)
		else:
			draw_rect(Rect2(Vector2(center.x - 4, center.y - total * 0.5 + i * segment), Vector2(8, segment)), color, true)

func _draw_issue_markers(size: float) -> void:
	for issue in validation_issues:
		var cell: Vector2i = issue.get("cell", Vector2i.ZERO)
		var rect := Rect2(Vector2(cell) * size + Vector2.ONE * 4.0, Vector2.ONE * (size - 8.0))
		draw_rect(rect, Color(1.0, 0.18, 0.18, 0.9), false, 4.0)

func _draw_grid(size: float) -> void:
	var color := Color(0.0, 0.0, 0.0, 0.08)
	for x in range(track.width + 1):
		draw_line(Vector2(x * size, 0), Vector2(x * size, track.height * size), color, 1.0)
	for y in range(track.height + 1):
		draw_line(Vector2(0, y * size), Vector2(track.width * size, y * size), color, 1.0)

func _surface_color(surface: String) -> Color:
	match surface:
		"dirt": return COLOR_DIRT
		"sand": return COLOR_SAND
		"gravel": return COLOR_GRAVEL
		"grass": return COLOR_GRASS
		_: return COLOR_ASPHALT
