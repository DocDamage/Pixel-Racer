extends SceneTree

const RuntimeCatalogScript = preload("res://scripts/assets/runtime_asset_catalog.gd")
const BuilderCatalogScript = preload("res://scripts/assets/builder_asset_catalog.gd")
const ThemeCatalogScript = preload("res://scripts/assets/visual_theme_catalog.gd")
const TeamCatalogScript = preload("res://scripts/assets/team_catalog.gd")
const SpriteFactoryScript = preload("res://scripts/assets/asset_sprite_factory.gd")

var failures := 0

func _init() -> void:
	_test_runtime_catalog()
	_test_builder_catalog()
	_test_themes_and_teams()
	_test_atlas_sprite_factory()
	if failures == 0:
		print("Pixel Track Works asset catalog tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works asset catalog tests: %d failure(s)" % failures)
		quit(1)

func _test_runtime_catalog() -> void:
	var catalog = RuntimeCatalogScript.new()
	_expect(catalog.count() == 83, "runtime catalog exposes 83 approved assets")
	var preview: Dictionary = catalog.asset("vehicle.craftpix.car01.preview")
	_expect(not preview.is_empty(), "CraftPix preview car is cataloged")
	_expect(not bool(preview.get("gameplay_directional_complete", true)), "CraftPix preview car cannot silently enter gameplay roster")
	var crowd: Dictionary = catalog.asset("crowd.v2.east.blue")
	_expect(int(crowd.get("frames", 0)) == 4, "V2 crowd retains animation frame count")
	_expect(int(crowd.get("fps", 0)) == 6, "V2 crowd retains animation timing")

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
	_expect((nitro.get("driver_pool", []) as Array).size() == 5, "team exposes five driver presentation variants")

func _test_atlas_sprite_factory() -> void:
	var sprite: Sprite2D = SpriteFactoryScript.create_sprite("prop.tree.craftpix_01")
	_expect(sprite != null, "asset sprite factory creates atlas-backed sprite")
	if sprite != null:
		_expect(sprite.texture != null, "atlas-backed sprite resolves imported texture")
		_expect(sprite.region_enabled, "atlas-backed sprite uses explicit region")
		_expect(Vector2i(sprite.region_rect.size) == Vector2i(48, 48), "atlas region retains approved runtime dimensions")
		sprite.free()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
