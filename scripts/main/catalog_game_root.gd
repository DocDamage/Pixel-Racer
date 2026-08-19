extends "res://scripts/main/game_root.gd"

func _create_world() -> void:
	renderer = TrackRenderer.new()
	renderer.name = "TrackRenderer"
	add_child(renderer)
	runtime = TrackRuntime.new()
	runtime.name = "TrackRuntime"
	add_child(runtime)
	camera = Camera2D.new()
	camera.name = "CameraRig"
	camera.position = Vector2(640, 500)
	camera.zoom = Vector2.ONE * 0.7
	add_child(camera)
	camera.make_current()
	builder = CatalogBuilderController.new()
	builder.name = "BuilderController"
	add_child(builder)
	builder.track_replaced.connect(_on_track_replaced)
	builder.track_changed.connect(_on_track_changed)
	builder.test_requested.connect(enter_test_drive)
	builder.save_requested.connect(save_current_track)
	builder.load_requested.connect(_on_builder_load_requested)
	builder.tool_changed.connect(_on_tool_changed)
