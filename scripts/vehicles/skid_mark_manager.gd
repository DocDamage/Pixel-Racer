extends Node2D
class_name SkidMarkManager

var max_segments := 700
var lifetime := 18.0
var min_spacing := 5.0
var segments: Array[Dictionary] = []
var _last_points: Dictionary = {}

func _ready() -> void:
	add_to_group("skid_mark_manager")
	z_index = -2

func record_vehicle(source_id: int, center: Vector2, heading: float, half_track: float, intensity: float = 1.0) -> void:
	var forward := Vector2.UP.rotated(heading)
	var right := forward.rotated(PI * 0.5)
	var rear_center := center - forward * 15.0
	_record_tire(source_id * 2, rear_center - right * half_track, intensity)
	_record_tire(source_id * 2 + 1, rear_center + right * half_track, intensity)
	while segments.size() > max_segments:
		segments.pop_front()
	queue_redraw()

func clear_marks() -> void:
	segments.clear()
	_last_points.clear()
	queue_redraw()

func _process(delta: float) -> void:
	var changed := false
	for index in range(segments.size() - 1, -1, -1):
		segments[index]["age"] = float(segments[index].get("age", 0.0)) + delta
		if float(segments[index]["age"]) >= lifetime:
			segments.remove_at(index)
			changed = true
	if changed or not segments.is_empty():
		queue_redraw()

func _draw() -> void:
	for segment in segments:
		var age := float(segment.get("age", 0.0))
		var alpha := clampf(1.0 - age / lifetime, 0.0, 1.0) * float(segment.get("intensity", 1.0)) * 0.5
		draw_line(segment["from"], segment["to"], Color(0.08, 0.08, 0.09, alpha), 2.0, true)

func _record_tire(key: int, point: Vector2, intensity: float) -> void:
	if not _last_points.has(key):
		_last_points[key] = point
		return
	var previous: Vector2 = _last_points[key]
	if previous.distance_to(point) < min_spacing:
		return
	segments.append({"from": previous, "to": point, "age": 0.0, "intensity": clampf(intensity, 0.2, 1.0)})
	_last_points[key] = point
