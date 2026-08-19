extends Node2D
class_name VehicleVFX

const SMOKE_FRAME := Vector2i(32, 32)
const SMOKE_COLUMNS := 6
const SMOKE_FRAMES := 60
const NITRO_FRAME := Vector2i(64, 64)
const NITRO_COLUMNS := 7
const NITRO_FRAMES := 56

var smoke_left: Sprite2D
var smoke_right: Sprite2D
var nitro_sprite: Sprite2D
var _smoke_time := 0.0
var _nitro_time := 0.0

func _ready() -> void:
	z_index = -1
	smoke_left = _make_sheet_sprite("res://VFX/Smoke/Smoke-Sheet.png", SMOKE_FRAME)
	smoke_right = _make_sheet_sprite("res://VFX/Smoke/Smoke-Sheet.png", SMOKE_FRAME)
	nitro_sprite = _make_sheet_sprite("res://VFX/Nitro/nitroVFX-Sheet.png", NITRO_FRAME)
	smoke_left.scale = Vector2.ONE * 0.72
	smoke_right.scale = Vector2.ONE * 0.72
	nitro_sprite.scale = Vector2(0.55, 0.72)
	smoke_left.visible = false
	smoke_right.visible = false
	nitro_sprite.visible = false

func update_state(delta: float, heading: float, drifting: bool, boosting: bool, speed: float) -> void:
	var forward := Vector2.UP.rotated(heading)
	var right := forward.rotated(PI * 0.5)
	var rear := -forward * 18.0
	smoke_left.position = rear - right * 8.0
	smoke_right.position = rear + right * 8.0
	nitro_sprite.position = rear - forward * 7.0
	nitro_sprite.rotation = heading
	_smoke_time += delta * clampf(speed / 70.0, 1.0, 4.0)
	_nitro_time += delta * 18.0
	smoke_left.visible = drifting
	smoke_right.visible = drifting
	nitro_sprite.visible = boosting
	if drifting:
		_set_frame(smoke_left, int(_smoke_time * 14.0) % SMOKE_FRAMES, SMOKE_COLUMNS, SMOKE_FRAME)
		_set_frame(smoke_right, (int(_smoke_time * 14.0) + 5) % SMOKE_FRAMES, SMOKE_COLUMNS, SMOKE_FRAME)
	if boosting:
		_set_frame(nitro_sprite, int(_nitro_time) % NITRO_FRAMES, NITRO_COLUMNS, NITRO_FRAME)

func _make_sheet_sprite(path: String, frame_size: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame_size))
	add_child(sprite)
	return sprite

func _set_frame(sprite: Sprite2D, frame: int, columns: int, frame_size: Vector2i) -> void:
	if sprite == null or sprite.texture == null:
		return
	var column := frame % columns
	var row := frame / columns
	sprite.region_rect = Rect2(Vector2(column * frame_size.x, row * frame_size.y), Vector2(frame_size))
