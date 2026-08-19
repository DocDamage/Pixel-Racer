extends CharacterBody2D
class_name CharacterActor

signal destination_reached(destination: Vector2)
signal movement_started(destination: Vector2)

const ARRIVAL_DISTANCE := 2.0
const IDLE_FPS := 4.0
const RUN_FPS := 8.0

var definition: CharacterDefinition = null
var body_sprite: Sprite2D
var head_sprite: Sprite2D
var facing_left: bool = false
var _target: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _animation_time: float = 0.0
var _frame_index: int = 0
var _moving: bool = false

func _ready() -> void:
	_ensure_sprites()

func setup(character_definition: CharacterDefinition) -> void:
	definition = character_definition
	_ensure_sprites()
	_load_animation_textures(false)
	_frame_index = 0
	_animation_time = 0.0
	_apply_frame()

func walk_to(destination: Vector2) -> void:
	_target = destination
	_has_target = true
	_moving = true
	movement_started.emit(destination)

func stop() -> void:
	_has_target = false
	_moving = false
	velocity = Vector2.ZERO
	_frame_index = 0
	_animation_time = 0.0
	_load_animation_textures(false)
	_apply_frame()

func teleport_to(destination: Vector2) -> void:
	global_position = destination
	_target = destination
	stop()
	destination_reached.emit(destination)

func face_toward(destination: Vector2) -> void:
	var delta_x: float = destination.x - global_position.x
	if absf(delta_x) > 0.01:
		_set_facing_left(delta_x < 0.0)

func is_walking() -> bool:
	return _has_target

func _physics_process(delta: float) -> void:
	if definition == null:
		velocity = Vector2.ZERO
		return
	if _has_target:
		var offset: Vector2 = _target - global_position
		if offset.length_squared() <= ARRIVAL_DISTANCE * ARRIVAL_DISTANCE:
			global_position = _target
			var reached: Vector2 = _target
			stop()
			destination_reached.emit(reached)
			return
		_set_facing_left(offset.x < -0.01 if absf(offset.x) > 0.01 else facing_left)
		velocity = offset.normalized() * definition.walk_speed
		move_and_slide()
		_update_animation(delta, true)
	else:
		velocity = Vector2.ZERO
		_update_animation(delta, false)

func _update_animation(delta: float, moving: bool) -> void:
	if moving != _moving:
		_moving = moving
		_frame_index = 0
		_animation_time = 0.0
		_load_animation_textures(moving)
	var fps: float = RUN_FPS if moving else IDLE_FPS
	var frame_count: int = definition.run_frames if moving else definition.idle_frames
	_animation_time += delta
	var frame_duration: float = 1.0 / fps
	while _animation_time >= frame_duration:
		_animation_time -= frame_duration
		_frame_index = (_frame_index + 1) % maxi(1, frame_count)
		_apply_frame()

func _load_animation_textures(moving: bool) -> void:
	if definition == null:
		return
	var body_path: String = definition.body_run_sheet if moving else definition.body_idle_sheet
	var head_path: String = definition.head_run_sheet if moving else definition.head_idle_sheet
	body_sprite.texture = _load_texture(body_path)
	head_sprite.texture = _load_texture(head_path)
	var atlas_ready: bool = definition.atlas_is_measured()
	body_sprite.visible = body_sprite.texture != null and atlas_ready
	head_sprite.visible = head_sprite.texture != null and atlas_ready

func _apply_frame() -> void:
	if definition == null or not definition.atlas_is_measured():
		return
	_apply_sprite_region(body_sprite, definition.body_cell_size, definition.body_row, _frame_index)
	_apply_sprite_region(head_sprite, definition.head_cell_size, definition.head_row, _frame_index)

func _apply_sprite_region(sprite: Sprite2D, cell_size: Vector2i, row: int, frame: int) -> void:
	if sprite == null or sprite.texture == null or cell_size.x <= 0 or cell_size.y <= 0:
		return
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		float(frame * cell_size.x),
		float(row * cell_size.y),
		float(cell_size.x),
		float(cell_size.y)
	)
	sprite.centered = true
	sprite.flip_h = facing_left

func _set_facing_left(value: bool) -> void:
	if facing_left == value:
		return
	facing_left = value
	body_sprite.flip_h = value
	head_sprite.flip_h = value

func _ensure_sprites() -> void:
	if body_sprite == null:
		body_sprite = Sprite2D.new()
		body_sprite.name = "Body"
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(body_sprite)
	if head_sprite == null:
		head_sprite = Sprite2D.new()
		head_sprite.name = "Head"
		head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		head_sprite.z_index = 1
		add_child(head_sprite)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource: Resource = ResourceLoader.load(path)
	if resource is Texture2D:
		return resource as Texture2D
	return null
