extends CharacterBody2D
class_name ArcadeVehicle

signal nitro_changed(value: float)
signal drift_score_changed(value: float)
signal surface_changed(surface: String)

const SURFACES := {
	"asphalt": {"grip": 1.0, "resistance": 0.04, "speed": 1.0},
	"grass": {"grip": 0.48, "resistance": 0.36, "speed": 0.58},
	"sand": {"grip": 0.62, "resistance": 0.48, "speed": 0.70},
	"dirt": {"grip": 0.76, "resistance": 0.20, "speed": 0.86},
	"gravel": {"grip": 0.70, "resistance": 0.27, "speed": 0.82}
}

var track = null
var vehicle_id := "Hachiroku_Drifter"
var definition: Dictionary = {}
var input_enabled := true
var heading := 0.0
var nitro := 100.0
var drift_score := 0.0
var last_valid_position := Vector2.ZERO
var current_surface := "asphalt"
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var vfx: VehicleVFX
var is_drifting := false
var is_boosting := false
var frame_width := 46
var frame_height := 54
var _ai_controls := {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "handbrake": false, "boost": false}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	sprite = Sprite2D.new()
	sprite.name = "VehicleSprite"
	add_child(sprite)
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	add_child(collision_shape)
	vfx = VehicleVFX.new()
	vfx.name = "VehicleVFX"
	add_child(vfx)

func setup(source_track, id: String, player_controlled: bool = true, color: String = "default") -> void:
	track = source_track
	vehicle_id = id
	input_enabled = player_controlled
	var catalog := VehicleCatalog.new()
	definition = catalog.get_vehicle(vehicle_id)
	frame_width = int(definition.get("grid_width", 46))
	frame_height = int(definition.get("grid_height", 54))
	var texture := load(catalog.sprite_path(vehicle_id, color)) as Texture2D
	if texture == null and color != "default":
		texture = load(catalog.sprite_path(vehicle_id, "default")) as Texture2D
	if texture != null:
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_width, frame_height)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(frame_width * 0.56, frame_height * 0.56)
	collision_shape.shape = shape
	last_valid_position = global_position
	_update_sprite_frame()

func set_ai_controls(throttle: float, brake: float, steer: float, handbrake: bool = false, boost: bool = false) -> void:
	_ai_controls = {
		"throttle": clampf(throttle, 0.0, 1.0),
		"brake": clampf(brake, 0.0, 1.0),
		"steer": clampf(steer, -1.0, 1.0),
		"handbrake": handbrake,
		"boost": boost
	}

func reset_to_last_valid() -> void:
	global_position = last_valid_position
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	get_tree().create_timer(0.6).timeout.connect(func(): set_collision_layer_value(1, true))

func _physics_process(delta: float) -> void:
	if track == null:
		return
	var controls := _read_controls()
	var stats: Dictionary = definition.get("stats", {})
	var surface_data: Dictionary = SURFACES.get(current_surface, SURFACES["asphalt"])
	var forward := Vector2.UP.rotated(heading)
	var right := forward.rotated(PI * 0.5)
	var forward_speed := velocity.dot(forward)
	var lateral_speed := velocity.dot(right)
	var speed_stat := float(stats.get("speed", 80)) / 100.0
	var accel_stat := float(stats.get("accel", 80)) / 100.0
	var handling_stat := float(stats.get("handling", 80)) / 100.0
	var drift_stat := float(stats.get("drift", 80)) / 100.0
	var boost_stat := float(stats.get("boost", 80)) / 100.0
	var max_speed := lerpf(250.0, 520.0, speed_stat) * float(surface_data["speed"])
	var engine_power := lerpf(210.0, 480.0, accel_stat)
	var brake_power := lerpf(360.0, 620.0, handling_stat)
	var steering_rate := lerpf(1.65, 2.9, handling_stat) * float(SettingsManager.get_value("steering_sensitivity", 1.0))
	if bool(SettingsManager.get_value("auto_accelerate", false)) and float(controls["throttle"]) <= 0.0:
		controls["throttle"] = 1.0
	forward_speed += float(controls["throttle"]) * engine_power * delta
	if float(controls["brake"]) > 0.0:
		if forward_speed > 10.0:
			forward_speed = move_toward(forward_speed, 0.0, brake_power * float(controls["brake"]) * delta)
		else:
			forward_speed -= 180.0 * float(controls["brake"]) * delta
	var resistance := float(surface_data["resistance"])
	forward_speed = move_toward(forward_speed, 0.0, (18.0 + absf(forward_speed) * resistance) * delta)
	var is_handbrake := bool(controls["handbrake"])
	var grip := lerpf(4.4, 9.5, handling_stat) * float(surface_data["grip"])
	if is_handbrake:
		grip *= lerpf(0.26, 0.50, drift_stat)
	elif bool(SettingsManager.get_value("traction_assist", true)):
		grip *= 1.12
	lateral_speed = move_toward(lateral_speed, 0.0, absf(lateral_speed) * grip * delta)
	var speed_ratio := clampf(absf(forward_speed) / maxf(1.0, max_speed), 0.0, 1.0)
	var steering_scale := lerpf(0.42, 1.0, clampf(speed_ratio * 2.0, 0.0, 1.0)) * lerpf(1.0, 0.66, maxf(0.0, speed_ratio - 0.75) / 0.25)
	if absf(forward_speed) > 6.0:
		heading += float(controls["steer"]) * steering_rate * steering_scale * delta * signf(forward_speed)
	is_boosting = bool(controls["boost"]) and nitro > 0.0 and forward_speed > 20.0
	if is_boosting:
		forward_speed += lerpf(220.0, 360.0, boost_stat) * delta
		max_speed *= 1.14
		nitro = maxf(0.0, nitro - 28.0 * delta)
		nitro_changed.emit(nitro)
	forward_speed = clampf(forward_speed, -120.0, max_speed)
	velocity = forward * forward_speed + right * lateral_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		velocity *= 0.68
	_update_surface()
	_update_drift(delta, forward_speed, lateral_speed)
	if vfx != null:
		vfx.update_state(delta, heading, is_drifting, is_boosting, velocity.length())
	_update_sprite_frame()
	if input_enabled and Input.is_action_just_pressed("reset_vehicle"):
		reset_to_last_valid()

func _read_controls() -> Dictionary:
	if not input_enabled:
		return _ai_controls.duplicate(true)
	return {
		"throttle": Input.get_action_strength("accelerate"),
		"brake": Input.get_action_strength("brake"),
		"steer": Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"),
		"handbrake": Input.is_action_pressed("handbrake"),
		"boost": Input.is_action_pressed("boost")
	}

func _update_surface() -> void:
	var cell := track.world_to_cell(global_position)
	var next_surface := track.get_surface_at(cell) if track.in_bounds(cell) else "grass"
	if next_surface != current_surface:
		current_surface = next_surface
		surface_changed.emit(current_surface)
	if track.has_road(cell):
		last_valid_position = track.cell_to_world(cell)

func _update_drift(delta: float, forward_speed: float, lateral_speed: float) -> void:
	var slip := absf(lateral_speed)
	is_drifting = absf(forward_speed) > 90.0 and slip > 18.0
	if is_drifting:
		var gain := slip * absf(forward_speed) * delta * 0.002
		drift_score += gain
		nitro = minf(100.0, nitro + gain * 0.12)
		drift_score_changed.emit(drift_score)
		nitro_changed.emit(nitro)

func _update_sprite_frame() -> void:
	if sprite == null or sprite.texture == null:
		return
	var normalized := fposmod(heading, TAU)
	var frame := posmod(roundi(normalized / TAU * 16.0), 16)
	sprite.region_rect = Rect2(frame * frame_width, 0, frame_width, frame_height)
