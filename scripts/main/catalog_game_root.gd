extends "res://scripts/main/game_root.gd"

var visual_themes := VisualThemeCatalog.new()

func _create_world() -> void:
	renderer = CatalogTrackRenderer.new()
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

func current_visual_theme_id() -> String:
	var themed_renderer := renderer as CatalogTrackRenderer
	return themed_renderer.visual_theme_id() if themed_renderer != null else visual_themes.default_theme()

func current_visual_theme_name() -> String:
	var themed_renderer := renderer as CatalogTrackRenderer
	if themed_renderer != null:
		return themed_renderer.visual_theme_name()
	var definition := visual_themes.theme(visual_themes.default_theme())
	return str(definition.get("display_name", visual_themes.default_theme()))

func set_visual_theme(theme_id: String) -> bool:
	var themed_renderer := renderer as CatalogTrackRenderer
	if themed_renderer == null or not themed_renderer.set_visual_theme(theme_id):
		return false
	if ui != null:
		ui.refresh_builder()
		ui.show_status("Theme: %s" % themed_renderer.visual_theme_name())
	return true

func cycle_visual_theme(direction: int = 1) -> void:
	var ids := visual_themes.ids()
	if ids.is_empty():
		return
	var index := ids.find(current_visual_theme_id())
	if index < 0:
		index = 0
	set_visual_theme(ids[posmod(index + direction, ids.size())])
