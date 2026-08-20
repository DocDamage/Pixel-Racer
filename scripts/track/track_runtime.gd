extends Node2D
class_name TrackRuntime

var track = null
var object_root: Node2D
var _builder_catalog := BuilderAssetCatalog.new()
var _runtime_catalog := RuntimeAssetCatalog.new()

func _ready() -> void:
	object_root = Node2D.new()
	object_root.name = "TrackObjects"
	add_child(object_root)

func set_track(source_track) -> void:
	track = source_track
	refresh_objects()

func refresh_objects() -> void:
	if object_root == null:
		return
	for child in object_root.get_children():
		child.queue_free()
	if track == null:
		return
	for item in track.objects:
		_spawn_object(item)

func _spawn_object(item: Dictionary) -> void:
	var type := str(item.get("type", "barrier"))
	if EnvironmentCatalog.ITEMS.has(type):
		_spawn_legacy_object(item, type)
		return
	var catalog_entry := _builder_catalog.entry(type)
	if catalog_entry.is_empty():
		push_warning("Unknown track object asset: %s" % type)
		return
	var asset_id := str(catalog_entry.get("asset_id", type))
	var runtime_definition := _runtime_catalog.asset(asset_id)
	if runtime_definition.is_empty():
		push_warning("Track object has no runtime asset: %s" % asset_id)
		return
	var body := _create_catalog_body(catalog_entry, runtime_definition)
	if body == null:
		return
	body.name = _safe_node_name(type)
	_apply_transform(body, item)
	if bool(catalog_entry.get("animated", false)):
		var actor := SpriteStripActor.new()
		if actor.setup(asset_id):
			body.add_child(actor)
	else:
		var sprite := AssetSpriteFactory.create_sprite(asset_id)
		if sprite != null:
			body.add_child(sprite)
	object_root.add_child(body)

func _spawn_legacy_object(item: Dictionary, type: String) -> void:
	var definition := EnvironmentCatalog.get_item(type)
	var body: Node2D
	if bool(definition.get("dynamic", false)):
		var dynamic_body := RigidBody2D.new()
		dynamic_body.mass = 0.45
		dynamic_body.linear_damp = 2.8
		dynamic_body.angular_damp = 3.5
		body = dynamic_body
	else:
		body = StaticBody2D.new()
	body.name = "%s_%s" % [type, str(item.get("id", ""))]
	_apply_transform(body, item)
	if body is CollisionObject2D:
		(body as CollisionObject2D).collision_layer = 1
		(body as CollisionObject2D).collision_mask = 1
	if bool(definition.get("collision", false)):
		_add_collision(body, Vector2(definition.get("size", Vector2(32, 32))) * 0.92)
	var sprite := Sprite2D.new()
	sprite.texture = load(str(definition.get("texture", ""))) as Texture2D
	body.add_child(sprite)
	object_root.add_child(body)

func _create_catalog_body(entry: Dictionary, runtime_definition: Dictionary) -> Node2D:
	var collision_profile := str(entry.get("collision", "none"))
	var collision_size := _collision_size(collision_profile, runtime_definition)
	if bool(entry.get("hazard", false)) or collision_profile == "trigger":
		var hazard := TrackHazardArea.new()
		hazard.setup("oil", collision_size if collision_size != Vector2.ZERO else Vector2(34, 16))
		return hazard
	var body: Node2D
	if bool(entry.get("dynamic", false)) or collision_profile.ends_with("_dynamic"):
		var dynamic_body := RigidBody2D.new()
		dynamic_body.mass = 0.55
		dynamic_body.linear_damp = 2.8
		dynamic_body.angular_damp = 3.5
		body = dynamic_body
	elif collision_size != Vector2.ZERO:
		body = StaticBody2D.new()
	else:
		body = Node2D.new()
	if body is CollisionObject2D:
		(body as CollisionObject2D).collision_layer = 1
		(body as CollisionObject2D).collision_mask = 1
	if collision_size != Vector2.ZERO:
		_add_collision(body, collision_size)
	return body

func _collision_size(profile: String, runtime_definition: Dictionary) -> Vector2:
	match profile:
		"tree_trunk_small": return Vector2(12, 16)
		"rock_small": return Vector2(30, 14)
		"building_medium": return Vector2(64, 50)
		"pavilion": return Vector2(72, 36)
		"barrel_dynamic": return Vector2(16, 18)
		"tire_dynamic": return Vector2(14, 14)
		"trigger": return Vector2(34, 16)
		"none": return Vector2.ZERO
	var region: Rect2i = runtime_definition.get("region", Rect2i())
	if region.size.x <= 0 or region.size.y <= 0:
		return Vector2.ZERO
	return Vector2(region.size) * 0.72

func _add_collision(body: Node2D, size: Vector2) -> void:
	if not body is CollisionObject2D or size == Vector2.ZERO:
		return
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)

func _apply_transform(body: Node2D, item: Dictionary) -> void:
	body.position = track.cell_to_world(Vector2i(int(item.get("x", 0)), int(item.get("y", 0))))
	body.rotation = float(int(item.get("rotation_steps", 0))) * PI * 0.5

func _safe_node_name(value: String) -> String:
	return value.replace(".", "_").replace("-", "_").replace("/", "_")
