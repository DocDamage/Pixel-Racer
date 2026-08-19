extends RefCounted
class_name GhostRecorder

var samples: Array[Dictionary] = []
var sample_interval := 0.1
var _accumulator := 0.0
var _start_msec := 0
var recording := false

func start() -> void:
	samples.clear()
	_accumulator = 0.0
	_start_msec = Time.get_ticks_msec()
	recording = true

func stop() -> Array[Dictionary]:
	recording = false
	return samples.duplicate(true)

func capture(delta: float, vehicle: ArcadeVehicle) -> void:
	if not recording or vehicle == null:
		return
	_accumulator += delta
	if _accumulator < sample_interval:
		return
	_accumulator = fmod(_accumulator, sample_interval)
	samples.append({
		"t": float(Time.get_ticks_msec() - _start_msec) / 1000.0,
		"x": vehicle.global_position.x,
		"y": vehicle.global_position.y,
		"heading": vehicle.heading,
		"speed": vehicle.velocity.length()
	})

func save(path: String, metadata: Dictionary = {}) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema_version": 1, "metadata": metadata, "samples": samples}, "\t"))
	return true

func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("samples"):
		return false
	samples.clear()
	for item in parsed["samples"]:
		if item is Dictionary:
			samples.append(item.duplicate(true))
	return true

func sample_at(time_seconds: float) -> Dictionary:
	if samples.is_empty():
		return {}
	if time_seconds <= float(samples[0].get("t", 0.0)):
		return samples[0]
	for index in range(1, samples.size()):
		var b: Dictionary = samples[index]
		if float(b.get("t", 0.0)) >= time_seconds:
			var a: Dictionary = samples[index - 1]
			var span := maxf(0.0001, float(b.get("t", 0.0)) - float(a.get("t", 0.0)))
			var alpha := clampf((time_seconds - float(a.get("t", 0.0))) / span, 0.0, 1.0)
			return {
				"x": lerpf(float(a.get("x", 0.0)), float(b.get("x", 0.0)), alpha),
				"y": lerpf(float(a.get("y", 0.0)), float(b.get("y", 0.0)), alpha),
				"heading": lerp_angle(float(a.get("heading", 0.0)), float(b.get("heading", 0.0)), alpha),
				"speed": lerpf(float(a.get("speed", 0.0)), float(b.get("speed", 0.0)), alpha)
			}
	return samples.back()
