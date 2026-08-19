extends RefCounted
class_name PortraitAtlas

var atlas_path: String = ""
var regions: Dictionary = {}
var _texture: Texture2D = null

func setup(texture_path: String, measured_regions: Dictionary) -> void:
	atlas_path = texture_path
	regions = measured_regions.duplicate(true)
	_texture = _load_texture(atlas_path)

func load_manifest(manifest: Dictionary) -> void:
	atlas_path = str(manifest.get("atlas_path", ""))
	regions.clear()
	var raw_regions: Variant = manifest.get("regions", {})
	if raw_regions is Dictionary:
		var region_dict: Dictionary = raw_regions
		for key in region_dict.keys():
			var rect: Rect2i = _rect_from_value(region_dict[key])
			if rect.size.x > 0 and rect.size.y > 0:
				regions[str(key)] = rect
	_texture = _load_texture(atlas_path)

func has_portrait(portrait_id: String) -> bool:
	return _texture != null and regions.has(portrait_id)

func region_for(portrait_id: String) -> Rect2i:
	if not regions.has(portrait_id):
		return Rect2i()
	return _rect_from_value(regions[portrait_id])

func texture_for(portrait_id: String) -> Texture2D:
	if not has_portrait(portrait_id):
		return null
	var region: Rect2i = region_for(portrait_id)
	var texture := AtlasTexture.new()
	texture.atlas = _texture
	texture.region = Rect2(float(region.position.x), float(region.position.y), float(region.size.x), float(region.size.y))
	return texture

func validate() -> Array[String]:
	var issues: Array[String] = []
	if atlas_path.is_empty():
		issues.append("Portrait atlas path is empty.")
	elif _texture == null:
		issues.append("Portrait atlas texture is unavailable: %s" % atlas_path)
	if regions.is_empty():
		issues.append("Portrait atlas has no measured regions.")
	return issues

static func _rect_from_value(value: Variant) -> Rect2i:
	if value is Rect2i:
		return value
	if value is Rect2:
		var rect_value: Rect2 = value
		return Rect2i(roundi(rect_value.position.x), roundi(rect_value.position.y), roundi(rect_value.size.x), roundi(rect_value.size.y))
	if value is Array:
		var array_value: Array = value
		if array_value.size() >= 4:
			return Rect2i(int(array_value[0]), int(array_value[1]), int(array_value[2]), int(array_value[3]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		return Rect2i(int(dict_value.get("x", 0)), int(dict_value.get("y", 0)), int(dict_value.get("w", 0)), int(dict_value.get("h", 0)))
	return Rect2i()

static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource: Resource = ResourceLoader.load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null
