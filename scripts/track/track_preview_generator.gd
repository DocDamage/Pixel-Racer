extends RefCounted
class_name TrackPreviewGenerator

const COLORS := {
	"grass": Color("#2d682a"),
	"asphalt": Color("#3b3f46"),
	"dirt": Color("#8b5a2b"),
	"sand": Color("#d4a359"),
	"gravel": Color("#766d66")
}

func render(track: TrackData, target_size: Vector2i = Vector2i(256, 144)) -> Image:
	var image := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	image.fill(COLORS["grass"])
	if track == null:
		return image
	var sx := float(target_size.x) / float(maxi(1, track.width))
	var sy := float(target_size.y) / float(maxi(1, track.height))
	for key in track.terrain:
		var item: Dictionary = track.terrain[key]
		_fill_cell(image, Vector2i(int(item.get("x", 0)), int(item.get("y", 0))), sx, sy, COLORS.get(str(item.get("type", "grass")), COLORS["grass"]))
	for cell in track.road_cells():
		_fill_cell(image, cell, sx, sy, COLORS.get(track.get_surface_at(cell), COLORS["asphalt"]))
	for item in track.race_objects:
		if str(item.get("type", "")) == "start_finish":
			_fill_cell(image, Vector2i(int(item.get("x", 0)), int(item.get("y", 0))), sx, sy, Color.WHITE)
	return image

func save(track: TrackData, path: String, target_size: Vector2i = Vector2i(256, 144)) -> bool:
	var image := render(track, target_size)
	return image.save_png(path) == OK

func _fill_cell(image: Image, cell: Vector2i, sx: float, sy: float, color: Color) -> void:
	var left := clampi(floori(cell.x * sx), 0, image.get_width() - 1)
	var top := clampi(floori(cell.y * sy), 0, image.get_height() - 1)
	var right := clampi(ceili((cell.x + 1) * sx), left + 1, image.get_width())
	var bottom := clampi(ceili((cell.y + 1) * sy), top + 1, image.get_height())
	image.fill_rect(Rect2i(left, top, right - left, bottom - top), color)
