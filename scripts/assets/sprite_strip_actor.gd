extends Node2D
class_name SpriteStripActor

var asset_id := ""
var definition: Dictionary = {}
var sprite: Sprite2D
var _frame := 0
var _elapsed := 0.0

func setup(source_asset_id: String) -> bool:
	asset_id = source_asset_id
	var catalog := RuntimeAssetCatalog.new()
	definition = catalog.asset(asset_id)
	if definition.is_empty():
		return false
	sprite = AssetSpriteFactory.create_sprite(asset_id)
	if sprite == null:
		return false
	add_child(sprite)
	_apply_frame()
	set_process(int(definition.get("frames", 0)) > 1)
	return true

func _process(delta: float) -> void:
	var frames := int(definition.get("frames", 0))
	var fps := int(definition.get("fps", 0))
	if frames <= 1 or fps <= 0 or sprite == null:
		return
	_elapsed += delta
	var frame_duration := 1.0 / float(fps)
	while _elapsed >= frame_duration:
		_elapsed -= frame_duration
		_frame = (_frame + 1) % frames
		_apply_frame()

func _apply_frame() -> void:
	if sprite == null:
		return
	var region: Rect2i = definition.get("region", Rect2i())
	var frame_size: Vector2i = definition.get("frame_size", Vector2i.ZERO)
	if frame_size.x <= 0 or frame_size.y <= 0:
		frame_size = region.size
	var offset := Vector2i(_frame * frame_size.x, 0)
	sprite.region_rect = Rect2(Vector2(region.position + offset), Vector2(frame_size))
