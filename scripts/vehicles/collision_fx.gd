extends Node2D
class_name CollisionFX

const MAX_PARTICLES := 160
const SPARK_COLOR := Color(1.0, 0.78, 0.22, 1.0)
const HOT_COLOR := Color(1.0, 0.38, 0.12, 1.0)
const DEBRIS_COLOR := Color(0.44, 0.42, 0.46, 1.0)

var particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = 7
	add_to_group("collision_fx")

func emit_impact(world_position: Vector2, normal: Vector2, intensity: float) -> void:
	var strength := clampf(intensity, 0.0, 1.0)
	if strength <= 0.01:
		return
	var flash_scale: float = clampf(float(SettingsManager.get_value("flash_intensity", 1.0)), 0.0, 1.0)
	var away := normal.normalized() if normal.length_squared() > 0.001 else Vector2.UP
	if flash_scale > 0.02:
		var spark_count := clampi(1 + roundi(strength * flash_scale * 10.0), 1, 12)
		for _i in range(spark_count):
			_spawn_spark(world_position, away, strength, flash_scale)
	var debris_count := clampi(roundi(strength * 5.0), 1, 5)
	for _i in range(debris_count):
		_spawn_debris(world_position, away, strength)
	_trim_pool()
	queue_redraw()

func particle_count() -> int:
	return particles.size()

func _process(delta: float) -> void:
	if particles.is_empty():
		return
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		particle["life"] = float(particle.get("life", 0.0)) - delta
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
			continue
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		if str(particle.get("kind", "spark")) == "debris":
			velocity.y += 220.0 * delta
			velocity *= pow(0.82, delta)
		else:
			velocity *= pow(0.18, delta)
		particle["velocity"] = velocity
		particle["position"] = Vector2(particle.get("position", Vector2.ZERO)) + velocity * delta
		particles[index] = particle
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		var life := float(particle.get("life", 0.0))
		var max_life := maxf(0.001, float(particle.get("max_life", 0.2)))
		var alpha := clampf(life / max_life, 0.0, 1.0)
		if str(particle.get("kind", "spark")) == "debris":
			var size := float(particle.get("size", 2.0))
			draw_rect(Rect2(position - Vector2.ONE * size * 0.5, Vector2.ONE * size), Color(DEBRIS_COLOR, alpha), true)
		else:
			alpha *= clampf(float(particle.get("flash_scale", 1.0)), 0.0, 1.0)
			var tail := velocity.normalized() * float(particle.get("length", 5.0))
			var color := HOT_COLOR.lerp(SPARK_COLOR, alpha)
			color.a = alpha
			draw_line(position, position - tail, color, maxf(1.0, float(particle.get("width", 1.0))))

func _spawn_spark(origin: Vector2, away: Vector2, strength: float, flash_scale: float) -> void:
	var direction := away.rotated(randf_range(-1.25, 1.25)).normalized()
	var speed := randf_range(85.0, 175.0 + 135.0 * strength)
	var life := randf_range(0.14, 0.28 + 0.12 * strength)
	particles.append({
		"kind": "spark",
		"position": origin + direction * randf_range(0.0, 5.0),
		"velocity": direction * speed,
		"life": life,
		"max_life": life,
		"length": randf_range(3.0, 7.0 + strength * 5.0),
		"width": 1.0 if strength < 0.65 else 2.0,
		"flash_scale": flash_scale
	})

func _spawn_debris(origin: Vector2, away: Vector2, strength: float) -> void:
	var direction := away.rotated(randf_range(-1.45, 1.45)).normalized()
	var speed := randf_range(35.0, 70.0 + 90.0 * strength)
	var life := randf_range(0.28, 0.52 + 0.18 * strength)
	particles.append({
		"kind": "debris",
		"position": origin + direction * randf_range(0.0, 4.0),
		"velocity": direction * speed,
		"life": life,
		"max_life": life,
		"size": randf_range(1.5, 3.0)
	})

func _trim_pool() -> void:
	while particles.size() > MAX_PARTICLES:
		particles.pop_front()
