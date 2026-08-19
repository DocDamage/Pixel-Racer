extends CharacterBody2D
class_name ArcadeVehicle

signal nitro_changed(value: float)
signal drift_score_changed(value: float)
signal surface_changed(surface: String)

const SettingsAccessScript = preload("res://scripts/utilities/settings_access.gd")
const SURFACES := {
	"asphalt": {"grip": 1.0, "resistance": 0.04, "speed": 1.0},
	"grass": {"grip": 0.48, "resistance": 0.36, "speed": 0.58},
	"sand": {"grip": 0.62, "resistance": 0.48, "speed": 0.70},
	"dirt": {"grip": 0.76, "resistance": 0.20, "speed": 0.86},
	"gravel": {"grip": 0.70, "resistance": 0.27, "speed": 0.82}
}

var track: TrackData = null
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
var skid_marks: SkidMarkManager
var collision_fx: CollisionFX
var audio: VehicleAudio
var is_drifting := false
var is_boosting := false
var frame_width := 46
var frame_height := 54
var _ai_controls := {"throttle": 0.0, "brake": 0.0, "steer": 0.0, "handbrake": false, "boost": false}
var _boost_was_active := false
var _drift_was_active := false
var _boost_toggle := false
var _collision_rumble_cooldown := 0.0

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
	_ensure_skid_manager()
	_ensure_collision_fx()

func setup(source_track: TrackData, id: String, player_controlled: bool = true, color: String = "default") -> void:
	track = source_track
	vehicle_id = id
	input_enabled = player_controlled
	var catalog := VehicleCatalog.new()
	if player_controlled:
		var garage := GarageManager.new()
		definition = garage.effective_definition(vehicle_id)
		if color == "default":
			color = garage.selected_color(vehicle_id)
	else:
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
	if player_controlled and audio == null:
		audio = VehicleAudio.new()
		audio.name = "VehicleAudio"
		add_child(audio)
		audio.start()
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
	_boost_toggle = false
	set_collision_layer_value(1, false)
	get_tree().create_timer(0.6).timeout.connect(func(): set_collision_layer_value(1, true))

func _physics_process(delta: float) -> void:
	if track == null:
		return
	_collision_rumble_cooldown = maxf(0.0, _collision_rumble_cooldown - delta)
	var controls := _read_controls()
	var stats: Dictionary = definition.get("stats", {})
	var tuning: Dictionary = definition.get("tuning", {})
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
	var final_drive := float(tuning.get("final_drive", 1.0))
	var max_speed := lerpf(250.0, 520.0, speed_stat) * float(surface_data["speed"]) * final_drive
	var engine_power := lerpf(210.0, 480.0, accel_stat) / maxf(0.85, final_drive)
	var brake_power := lerpf(360.0, 620.0, handling_stat) * float(tuning.get("brake_bias", 1.0))
	var steering_rate := lerpf(1.65, 2.9, handling_stat) * float(SettingsAccessScript.get_value("steering_sensitivity", 1.0)) * float(tuning.get("steering", 1.0))
	if bool(SettingsAccessScript.get_value("auto_accelerate", false)) and float(controls["throttle"]) <= 0.0:
		controls["throttle"] = 1.0
	if input_enabled and bool(SettingsAccessScript.get_value("auto_brake", false)) and absf(float(controls["steer"])) > 0.68 and absf(forward_speed) > max_speed * 0.68:
		controls["brake"] = maxf(float(controls["brake"]), 0.28)
	forward_speed += float(controls["throttle"]) * engine_power * delta
	if float(controls["brake"]) > 0.0:
		if forward_speed > 10.0:
			forward_speed = move_toward(forward_speed, 0.0, brake_power * float(controls["brake"]) * delta)
		else:
			forward_speed -= 180.0 * float(controls["brake"]) * delta
	var resistance := float(surface_data["resistance"])
	forward_speed = move_toward(forward_speed, 0.0, (18.0 + absf(forward_speed) * resistance) * delta)
	var is_handbrake := bool(controls["handbrake"])
	var grip := lerpf(4.4, 9.5, handling_stat) * float(surface_data["grip"]) * float(tuning.get("grip_bias", 1.0))
	if is_handbrake:
		var tuning_drift_assist := float(tuning.get("drift_assist", 0.5))
		var accessibility_drift_assist := float(SettingsAccessScript.get_value("drift_assist", 0.5)) if input_enabled else 0.5
		grip *= lerpf(0.22, 0.52, drift_stat) * lerpf(0.80, 1.14, tuning_drift_assist) * lerpf(0.86, 1.08, accessibility_drift_assist)
	elif bool(SettingsAccessScript.get_value("traction_assist", true)) and input_enabled:
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
	if is_boosting and not _boost_was_active:
		_rumble(0.30, 0.16)
	_boost_was_active = is_boosting
	if nitro <= 0.0:
		_boost_toggle = false
	forward_speed = clampf(forward_speed, -120.0, max_speed)
	velocity = forward * forward_speed + right * lateral_speed
	var pre_collision_speed := velocity.length()
	move_and_slide()
	if get_slide_collision_count() > 0:
		var impact_strength: float = clampf(pre_collision_speed / 420.0, 0.15, 1.0)
		var slide_collision: KinematicCollision2D = get_slide_collision(0)
		velocity *= 0.68
		if _collision_rumble_cooldown <= 0.0:
			if collision_fx != null and slide_collision != null:
				collision_fx.emit_impact(global_position, slide_collision.get_normal(), impact_strength)
			if audio != null:
				audio.trigger_impact(impact_strength)
			_rumble(0.52, 0.22)
			_collision_rumble_cooldown = 0.28
	_update_surface()
	_apply_track_edge_assist(delta)
	_update_drift(delta, forward_speed, lateral_speed)
	if is_drifting and not _drift_was_active:
		_rumble(0.16, 0.10)
	_drift_was_active = is_drifting
	if vfx != null:
		vfx.update_state(delta, heading, is_drifting, is_boosting, velocity.length())
	if audio != null:
		audio.update_state(speed_ratio, float(controls["throttle"]), is_drifting, is_boosting, current_surface)
	if is_drifting and skid_marks != null:
		skid_marks.record_vehicle(get_instance_id(), global_position, heading, frame_width * 0.16, clampf(absf(lateral_speed) / 70.0, 0.35, 1.0))
	_update_sprite_frame()
	if input_enabled and Input.is_action_just_pressed("reset_vehicle"):
		reset_to_last_valid()

func _read_controls() -> Dictionary:
	if not input_enabled:
		return _ai_controls.duplicate(true)
	var boost_requested := Input.is_action_pressed("boost")
	if not bool(SettingsAccessScript.get_value("hold_to_boost", true)):
		if Input.is_action_just_pressed("boost"):
			_boost_toggle = not _boost_toggle
		boost_requested = _boost_toggle
	return {
		"throttle": Input.get_action_strength("accelerate"),
		"brake": Input.get_action_strength("brake"),
		"steer": Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"),
		"handbrake": Input.is_action_pressed("handbrake"),
		"boost": boost_requested
	}

func _update_surface() -> void:
	var cell: Vector2i = track.world_to_cell(global_position)
	var next_surface: String = track.get_surface_at(cell) if track.in_bounds(cell) else "grass"
	if next_surface != current_surface:
		current_surface = next_surface
		surface_changed.emit(current_surface)
	if track.has_road(cell):
		last_valid_position = track.cell_to_world(cell)

func _apply_track_edge_assist(delta: float) -> void:
	if not input_enabled or not bool(SettingsAccessScript.get_value("track_edge_assist", false)) or current_surface != "grass":
		return
	var cell: Vector2i = track.world_to_cell(global_position)
	var nearest: Vector2i = track.nearest_road_cell(cell, 2)
	if nearest.x < 0:
		return
	var target: Vector2 = track.cell_to_world(nearest)
	var correction: Vector2 = target - global_position
	if correction.length() > track.cell_size * 2.25 or correction.length() < 1.0:
		return
	velocity += correction.normalized() * 95.0 * delta

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

func _rumble(strength: float, duration: float) -> void:
	if not input_enabled or not bool(SettingsAccessScript.get_value("controller_vibration", true)):
		return
	var configured := clampf(float(SettingsAccessScript.get_value("vibration_strength", 0.75)), 0.0, 1.0)
	var magnitude := clampf(strength * configured, 0.0, 1.0)
	if magnitude <= 0.01:
		return
	Input.start_joy_vibration(0, magnitude * 0.65, magnitude, maxf(0.02, duration))

func _ensure_skid_manager() -> void:
	var existing := get_tree().get_first_node_in_group("skid_mark_manager")
	if existing is SkidMarkManager:
		skid_marks = existing
		return
	if get_tree().current_scene == null:
		return
	skid_marks = SkidMarkManager.new()
	skid_marks.name = "SkidMarkManager"
	get_tree().current_scene.add_child(skid_marks)

func _ensure_collision_fx() -> void:
	var existing: Node = get_tree().get_first_node_in_group("collision_fx")
	if existing is CollisionFX:
		collision_fx = existing as CollisionFX
		return
	if get_tree().current_scene == null:
		return
	collision_fx = CollisionFX.new()
	collision_fx.name = "CollisionFX"
	get_tree().current_scene.add_child(collision_fx)

func _exit_tree() -> void:
	if audio != null:
		audio.stop()
