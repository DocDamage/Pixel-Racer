extends RefCounted
class_name AssetSpriteFactory

static func create_sprite(asset_id: String) -> Sprite2D:
	var catalog := RuntimeAssetCatalog.new()
	var definition := catalog.asset(asset_id)
	if definition.is_empty():
		return null
	var atlas_path := str(definition.get("atlas_path", ""))
	if atlas_path.is_empty():
		return null
	var texture := load(atlas_path) as Texture2D
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = _node_name(asset_id)
	sprite.texture = texture
	sprite.region_enabled = true
	var region: Rect2i = definition.get("region", Rect2i())
	var frames := int(definition.get("frames", 0))
	var frame_size: Vector2i = definition.get("frame_size", Vector2i.ZERO)
	if frames > 1 and frame_size.x > 0 and frame_size.y > 0:
		sprite.region_rect = Rect2(Vector2(region.position), Vector2(frame_size))
	else:
		sprite.region_rect = Rect2(Vector2(region.position), Vector2(region.size))
	return sprite

static func _node_name(asset_id: String) -> String:
	var output := asset_id.replace(".", "_").replace("-", "_").replace("/", "_")
	return output if not output.is_empty() else "RuntimeAssetSprite"
