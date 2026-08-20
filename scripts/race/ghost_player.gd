extends Node2D
class_name GhostPlayer

var recorder := GhostRecorder.new()
var sprite: Sprite2D
var playing := false
var elapsed := 0.0
var frame_width := 46
var frame_height := 54

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.modulate = Color(0.45, 0.9, 1.0, 0.45)
	sprite.z_index = 3
	add_child(sprite)

func setup(vehicle_id: String, ghost_path: String, color: String = "default") -> bool:
	if not recorder.load_from(ghost_path):
		return false
	var catalog := VehicleCatalog.new()
	var definition := catalog.get_vehicle(vehicle_id)
	frame_width = int(definition.get("grid_width", 46))
	frame_height = int(definition.get("grid_height", 54))
	sprite.texture = load(catalog.sprite_path(vehicle_id, color)) as Texture2D
	if sprite.texture == null:
		sprite.texture = load(catalog.sprite_path(vehicle_id, "default")) as Texture2D
	if sprite.texture != null:
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_width, frame_height)
	return not recorder.samples.is_empty()

func play() -> void:
	elapsed = 0.0
	playing = true
	visible = true

func stop() -> void:
	playing = false
	visible = false

func _process(delta: float) -> void:
	if not playing or recorder.samples.is_empty():
		return
	elapsed += delta
	var sample := recorder.sample_at(elapsed)
	if sample.is_empty():
		return
	position = Vector2(float(sample.get("x", 0.0)), float(sample.get("y", 0.0)))
	var heading := float(sample.get("heading", 0.0))
	var frame := posmod(roundi(fposmod(heading, TAU) / TAU * 16.0), 16)
	if sprite.texture != null:
		sprite.region_rect = Rect2(frame * frame_width, 0, frame_width, frame_height)
	var last: Dictionary = recorder.samples.back()
	if elapsed > float(last.get("t", 0.0)):
		stop()
