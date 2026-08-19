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
		match str(item.get("type", "")):
			"barrier": _spawn_barrier(item)
			_: pass

func _spawn_barrier(item: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Barrier_%s" % str(item.get("id", ""))
	body.position = track.cell_to_world(Vector2i(int(item.get("x", 0)), int(item.get("y", 0))))
	body.rotation = float(int(item.get("rotation_steps", 0))) * PI * 0.5
	body.collision_layer = 1
	body.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(144, 16)
	shape_node.shape = shape
	body.add_child(shape_node)
	var sprite := Sprite2D.new()
	var texture := load("res://Enviroment/barrier_red.png") as Texture2D
	if texture != null:
		sprite.texture = texture
	body.add_child(sprite)
	object_root.add_child(body)
