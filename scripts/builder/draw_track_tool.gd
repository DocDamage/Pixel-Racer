extends RefCounted
class_name DrawTrackTool

const WIDTHS := ["narrow", "standard", "wide", "extra_wide"]

func draw_cells(track: TrackData, sampled_cells: Array[Vector2i], surface: String = "asphalt", width: String = "standard") -> int:
	if track == null or sampled_cells.size() < 2:
		return 0
	if width not in WIDTHS:
		width = "standard"
	var simplified := simplify(sampled_cells)
	var placed: Dictionary = {}
	for index in range(simplified.size() - 1):
		for cell in rasterize_line(simplified[index], simplified[index + 1]):
			if track.in_bounds(cell):
				track.set_road(cell, surface, width)
				placed["%d,%d" % [cell.x, cell.y]] = true
	return placed.size()

func simplify(samples: Array[Vector2i]) -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	for cell in samples:
		if output.is_empty() or output.back() != cell:
			output.append(cell)
	if output.size() <= 2:
		return output
	var result: Array[Vector2i] = [output[0]]
	for index in range(1, output.size() - 1):
		var a: Vector2i = result.back()
		var b: Vector2i = output[index]
		var c: Vector2i = output[index + 1]
		var ab := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var bc := Vector2i(signi(c.x - b.x), signi(c.y - b.y))
		if ab != bc:
			result.append(b)
	result.append(output.back())
	return result

func rasterize_line(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x0 := start.x
	var y0 := start.y
	var x1 := finish.x
	var y1 := finish.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var error := dx + dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var twice := 2 * error
		if twice >= dy:
			error += dy
			x0 += sx
		if twice <= dx:
			error += dx
			y0 += sy
	return cells
