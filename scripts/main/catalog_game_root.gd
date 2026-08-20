extends "res://scripts/main/game_root.gd"

var visual_themes := VisualThemeCatalog.new()
var race_team_assignment := RaceTeamAssignment.new()
var catalog_palette: CatalogBuilderPalette = null
var mode_transition: ModeTransitionOverlay = null
var _last_builder_sfx_ms := 0

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
	var catalog_builder := builder as CatalogBuilderController
	if catalog_builder != null:
		catalog_builder.theme_cycle_requested.connect(cycle_visual_theme)
		catalog_builder.edit_committed.connect(_on_builder_edit_committed)
	catalog_palette = CatalogBuilderPalette.new()
	catalog_palette.name = "CatalogBuilderPalette"
	add_child(catalog_palette)
	catalog_palette.setup(self)
	mode_transition = ModeTransitionOverlay.new()
	mode_transition.name = "ModeTransitionOverlay"
	add_child(mode_transition)

func _spawn_ai(count: int) -> void:
	super._spawn_ai(count)
	for index in range(ai_vehicles.size()):
		race_team_assignment.apply_to_vehicle(ai_vehicles[index], index)

func save_current_track() -> bool:
	var saved: bool = super.save_current_track()
	var sfx := get_node_or_null("GameSFX") as GameSFXController
	if sfx != null:
		if saved:
			sfx.play_save()
		else:
			sfx.play_invalid()
	return saved

func start_event(mode: String = "circuit", laps_override: int = 0, ai_override: int = -1, championship_id: String = "") -> bool:
	var started: bool = super.start_event(mode, laps_override, ai_override, championship_id)
	if not started:
		var sfx := get_node_or_null("GameSFX") as GameSFXController
		if sfx != null:
			sfx.play_invalid()
	return started

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

func _on_builder_edit_committed() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_builder_sfx_ms < 85:
		return
	_last_builder_sfx_ms = now_ms
	var sfx := get_node_or_null("GameSFX") as GameSFXController
	if sfx != null:
		sfx.play_builder_place()
