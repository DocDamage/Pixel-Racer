extends Node2D
class_name TrackRuntime

var track = null
var object_root: Node2D

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
	body.position = track.cell_to_world(Vector2i(int(item.get("x", 0)), int(item.get("y", 0))))
	body.rotation = float(int(item.get("rotation_steps", 0))) * PI * 0.5
	if body is CollisionObject2D:
		body.collision_layer = 1
		body.collision_mask = 1
	if bool(definition.get("collision", false)):
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(definition.get("size", Vector2(32, 32))) * 0.92
		shape_node.shape = shape
		body.add_child(shape_node)
	var sprite := Sprite2D.new()
	sprite.texture = load(str(definition.get("texture", ""))) as Texture2D
	body.add_child(sprite)
	object_root.add_child(body)
