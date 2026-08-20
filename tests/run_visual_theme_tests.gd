extends SceneTree

const RendererScript = preload("res://scripts/track/catalog_track_renderer.gd")
const TrackDataScript = preload("res://scripts/track/track_data.gd")

var failures := 0

func _init() -> void:
	_test_theme_resolution_and_persistence()
	_finish()

func _test_theme_resolution_and_persistence() -> void:
	var track: TrackData = TrackDataScript.new()
	var renderer: CatalogTrackRenderer = RendererScript.new()
	renderer.set_track(track)
	_expect(renderer.visual_theme_id() == "native", "catalog renderer defaults to native theme")
	_expect(renderer.set_visual_theme("craftpix_01"), "catalog renderer accepts registered converted theme")
	_expect(str(track.metadata.get("visual_theme", "")) == "craftpix_01", "theme selection persists in TrackData metadata")
	_expect(track.dirty, "theme selection marks track dirty for save")
	_expect(renderer.visual_theme_name() == "Club Circuit", "theme exposes player-facing display name")
	var grass: Dictionary = renderer.resolved_theme_entry("terrain", "grass")
	_expect(str(grass.get("texture", "")) == "res://assets/atlases/craftpix_runtime_atlas.png", "converted theme resolves atlas-backed terrain")
	_expect(Array(grass.get("region", [])).size() == 4, "converted terrain retains explicit atlas region")
	var straight: Dictionary = renderer.resolved_theme_entry("roads", "straight")
	_expect(Array(straight.get("region", [])).size() == 4, "converted theme resolves unambiguous straight-road region")
	track.metadata["visual_theme"] = "missing_theme"
	_expect(renderer.visual_theme_id() == "native", "unknown saved theme falls back safely to native")
	_expect(renderer.resolved_theme_entry("roads", "straight").is_empty(), "native fallback does not invent converted road art")
	renderer.free()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works visual theme tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works visual theme tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
