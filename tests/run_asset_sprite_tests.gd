extends SceneTree

const RuntimeCatalogScript = preload("res://scripts/assets/runtime_asset_catalog.gd")
const SpriteFactoryScript = preload("res://scripts/assets/asset_sprite_factory.gd")
const SpriteStripActorScript = preload("res://scripts/assets/sprite_strip_actor.gd")

var failures := 0

func _init() -> void:
	_test_static_sprite()
	_test_animated_sprite()
	_finish()

func _test_static_sprite() -> void:
	var sprite: Sprite2D = SpriteFactoryScript.create_sprite("prop.tree.craftpix_01")
	_expect(sprite != null, "asset sprite factory creates atlas-backed sprite")
	if sprite == null:
		return
	_expect(sprite.texture != null, "atlas-backed sprite resolves imported texture")
	_expect(sprite.region_enabled, "atlas-backed sprite uses explicit region")
	_expect(Vector2i(sprite.region_rect.size) == Vector2i(48, 48), "atlas region retains approved tree dimensions")
	sprite.free()

func _test_animated_sprite() -> void:
	var catalog = RuntimeCatalogScript.new()
	var definition: Dictionary = catalog.asset("crowd.v2.east.blue")
	_expect(int(definition.get("frames", 0)) == 4, "animated crowd definition exposes four frames")
	var actor = SpriteStripActorScript.new()
	var ok: bool = actor.setup("crowd.v2.east.blue")
	_expect(ok, "sprite strip actor configures animated crowd")
	if ok:
		_expect(actor.sprite != null and actor.sprite.texture != null, "animated crowd resolves atlas texture")
		_expect(Vector2i(actor.sprite.region_rect.size) == Vector2i(16, 16), "animated crowd uses approved frame size")
	actor.free()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works asset sprite tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works asset sprite tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
