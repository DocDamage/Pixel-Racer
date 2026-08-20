extends RefCounted
class_name TrackEditOps

func capture(track: TrackData, first: Vector2i, second: Vector2i) -> Dictionary:
	var bounds := _bounds(first, second)
	var clip := {
		"size": bounds.size,
		"roads": [],
		"terrain": [],
		"objects": [],
		"race_objects": []
	}
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			var rel := cell - bounds.position
			if track.has_road(cell):
				var road := track.get_road(cell).duplicate(true)
				road["rx"] = rel.x
				road["ry"] = rel.y
				clip["roads"].append(road)
			var terrain_key := "%d,%d" % [cell.x, cell.y]
			if track.terrain.has(terrain_key):
				var terrain: Dictionary = Dictionary(track.terrain[terrain_key]).duplicate(true)
				terrain["rx"] = rel.x
				terrain["ry"] = rel.y
				clip["terrain"].append(terrain)
	for item in track.objects:
		var cell := Vector2i(int(item.get("x", -1)), int(item.get("y", -1)))
		if bounds.has_point(cell):
			var copy := item.duplicate(true)
			copy["rx"] = cell.x - bounds.position.x
			copy["ry"] = cell.y - bounds.position.y
			clip["objects"].append(copy)
	for item in track.race_objects:
		var cell := Vector2i(int(item.get("x", -1)), int(item.get("y", -1)))
		if bounds.has_point(cell):
			var copy := item.duplicate(true)
			copy["rx"] = cell.x - bounds.position.x
			copy["ry"] = cell.y - bounds.position.y
			clip["race_objects"].append(copy)
	return clip

func erase_region(track: TrackData, first: Vector2i, second: Vector2i) -> void:
	var bounds := _bounds(first, second)
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			track.remove_road(cell)
			track.set_terrain(cell, "grass")
			track.remove_objects_at(cell)
			track.remove_race_objects_at(cell)
	track.dirty = true

func paste(track: TrackData, clip: Dictionary, origin: Vector2i) -> Rect2i:
	if clip.is_empty():
		return Rect2i(origin, Vector2i.ONE)
	var size: Vector2i = clip.get("size", Vector2i.ONE)
	for raw in clip.get("terrain", []):
		var item: Dictionary = raw
		var cell := origin + Vector2i(int(item.get("rx", 0)), int(item.get("ry", 0)))
		if track.in_bounds(cell):
			track.set_terrain(cell, str(item.get("type", "grass")))
	for raw in clip.get("roads", []):
		var item: Dictionary = raw
		var cell := origin + Vector2i(int(item.get("rx", 0)), int(item.get("ry", 0)))
		if track.in_bounds(cell):
			track.set_road(cell, str(item.get("type", "asphalt")), str(item.get("width", "standard")))
	for raw in clip.get("objects", []):
		var item: Dictionary = raw
		var cell := origin + Vector2i(int(item.get("rx", 0)), int(item.get("ry", 0)))
		if track.in_bounds(cell):
			var extra := item.duplicate(true)
			for key in ["id", "x", "y", "rx", "ry", "type", "rotation_steps"]:
				extra.erase(key)
			track.add_object(str(item.get("type", "decor")), cell, int(item.get("rotation_steps", 0)), extra)
	var next_checkpoint := track.get_checkpoints_sorted().size()
	for raw in clip.get("race_objects", []):
		var item: Dictionary = raw
		var cell := origin + Vector2i(int(item.get("rx", 0)), int(item.get("ry", 0)))
		if not track.in_bounds(cell):
			continue
		var type := str(item.get("type", ""))
		if type == "checkpoint":
			track.place_race_object(type, cell, next_checkpoint)
			next_checkpoint += 1
		elif type == "start_finish":
			track.place_race_object(type, cell)
	return Rect2i(origin, size)

func rotate_clockwise(clip: Dictionary) -> Dictionary:
	if clip.is_empty():
		return clip
	var output := clip.duplicate(true)
	var old_size: Vector2i = clip.get("size", Vector2i.ONE)
	var new_size := Vector2i(old_size.y, old_size.x)
	for group in ["roads", "terrain", "objects", "race_objects"]:
		for item in output.get(group, []):
			var old_x := int(item.get("rx", 0))
			var old_y := int(item.get("ry", 0))
			item["rx"] = old_size.y - 1 - old_y
			item["ry"] = old_x
			if group == "objects":
				item["rotation_steps"] = posmod(int(item.get("rotation_steps", 0)) + 1, 4)
	output["size"] = new_size
	return output

func mirror_horizontal(clip: Dictionary) -> Dictionary:
	if clip.is_empty():
		return clip
	var output := clip.duplicate(true)
	var size: Vector2i = clip.get("size", Vector2i.ONE)
	for group in ["roads", "terrain", "objects", "race_objects"]:
		for item in output.get(group, []):
			item["rx"] = size.x - 1 - int(item.get("rx", 0))
			if group == "objects":
				var rotation := int(item.get("rotation_steps", 0))
				item["rotation_steps"] = posmod(4 - rotation, 4)
	return output

func eyedrop(track: TrackData, cell: Vector2i) -> Dictionary:
	for index in range(track.race_objects.size() - 1, -1, -1):
		var race_item: Dictionary = track.race_objects[index]
		if Vector2i(int(race_item.get("x", -1)), int(race_item.get("y", -1))) == cell:
			return {"tool": str(race_item.get("type", ""))}
	for index in range(track.objects.size() - 1, -1, -1):
		var item: Dictionary = track.objects[index]
		if Vector2i(int(item.get("x", -1)), int(item.get("y", -1))) == cell:
			return {"tool": str(item.get("type", "")), "rotation_steps": int(item.get("rotation_steps", 0))}
	if track.has_road(cell):
		return {"tool": "road", "surface": str(track.get_road(cell).get("type", "asphalt"))}
	var terrain_key := "%d,%d" % [cell.x, cell.y]
	if track.terrain.has(terrain_key):
		return {"tool": str(track.terrain[terrain_key].get("type", "grass"))}
	return {"tool": "grass"}

func _bounds(first: Vector2i, second: Vector2i) -> Rect2i:
	var min_cell := Vector2i(mini(first.x, second.x), mini(first.y, second.y))
	var max_cell := Vector2i(maxi(first.x, second.x), maxi(first.y, second.y))
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)
