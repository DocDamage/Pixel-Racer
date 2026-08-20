extends SceneTree

const RuntimeCatalogScript = preload("res://scripts/assets/runtime_asset_catalog.gd")
const BuilderCatalogScript = preload("res://scripts/assets/builder_asset_catalog.gd")
const ThemeCatalogScript = preload("res://scripts/assets/visual_theme_catalog.gd")
const TeamCatalogScript = preload("res://scripts/assets/team_catalog.gd")

var failures := 0

func _init() -> void:
	_test_compact_schema_width()
	_test_runtime_catalog()
	_test_builder_catalog()
	_test_themes_and_teams()
	_finish()

func _test_compact_schema_width() -> void:
	var file := FileAccess.open("res://data/assets/runtime_catalog.json", FileAccess.READ)
	_expect(file != null, "runtime catalog JSON exists")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_expect(parsed is Dictionary, "runtime catalog JSON parses")
	if not parsed is Dictionary:
		return
	var data := parsed as Dictionary
	var columns: Array = data.get("columns", [])
	var rows: Array = data.get("assets", [])
	_expect(columns.size() == 12, "runtime catalog schema has twelve columns")
	_expect(rows.size() == 83, "runtime catalog table has 83 rows")
	for index in range(rows.size()):
		var row: Variant = rows[index]
		_expect(row is Array and (row as Array).size() == columns.size(), "runtime catalog row %d matches schema width" % index)

func _test_runtime_catalog() -> void:
	var catalog = RuntimeCatalogScript.new()
	_expect(catalog.count() == 83, "runtime catalog exposes 83 approved assets")
	var preview: Dictionary = catalog.asset("vehicle.craftpix.car01.preview")
	_expect(not preview.is_empty(), "CraftPix preview car is cataloged")
	_expect(not bool(preview.get("gameplay_directional_complete", true)), "CraftPix preview car cannot silently enter gameplay roster")
	var crowd: Dictionary = catalog.asset("crowd.v2.east.blue")
	_expect(int(crowd.get("frames", 0)) == 4, "V2 crowd retains animation frame count")
	_expect(int(crowd.get("fps", 0)) == 6, "V2 crowd retains animation timing")
	var pit: Dictionary = catalog.asset("pit_crew.v2.tire_change.north")
	_expect(int(pit.get("frames", 0)) == 8, "north pit crew retains all eight frames")
	_expect(int(pit.get("fps", 0)) == 8, "north pit crew retains animation timing")

func _test_builder_catalog() -> void:
	var catalog = BuilderCatalogScript.new()
	_expect(catalog.count() == 31, "builder catalog exposes 31 approved placeables")
	var oil: Dictionary = catalog.entry("hazard.oil.craftpix_01")
	_expect(bool(oil.get("hazard", false)), "oil slick is a gameplay hazard")
	_expect(str(oil.get("asset_id", "")) == "hazard.oil.craftpix_01", "logical builder ID resolves to runtime asset ID")
	var tree: Dictionary = catalog.entry("prop.tree.craftpix_01")
	_expect(str(tree.get("collision", "")) == "tree_trunk_small", "tree uses data-defined collision profile")
	_expect(catalog.categories().has("CROWD"), "builder categories include crowd content")

func _test_themes_and_teams() -> void:
	var themes = ThemeCatalogScript.new()
	_expect(themes.has_theme("native"), "native visual theme is retained")
	_expect(themes.has_theme("craftpix_01"), "converted Club Circuit theme is registered")
	_expect(themes.has_theme("craftpix_02"), "converted Pro Circuit theme is registered")
	var teams = TeamCatalogScript.new()
	_expect(teams.count() == 4, "Racing Asset V2 exposes four data-driven teams")
	var nitro: Dictionary = teams.team("team_nitro")
	_expect(str(nitro.get("avatar_asset_id", "")) == "team_avatar.v2.nitro", "team references logical avatar asset ID")
	var drivers: Array = nitro.get("driver_pool", [])
	_expect(drivers.size() == 5, "team exposes five driver presentation variants")

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works asset data tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works asset data tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
