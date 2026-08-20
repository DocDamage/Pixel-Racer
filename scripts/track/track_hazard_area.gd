extends Area2D
class_name TrackHazardArea

var hazard_id := "oil"
var duration := 1.35
var _shape: CollisionShape2D

func setup(source_hazard_id: String, size: Vector2) -> void:
	hazard_id = source_hazard_id
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	add_child(_shape)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body != null and body.has_method("apply_hazard"):
		body.call("apply_hazard", hazard_id, duration)
