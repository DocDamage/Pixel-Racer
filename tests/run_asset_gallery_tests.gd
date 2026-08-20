extends SceneTree

const GalleryScene = preload("res://scenes/debug/asset_gallery.tscn")

var failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var gallery: AssetGallery = GalleryScene.instantiate() as AssetGallery
	_expect(gallery != null, "asset gallery scene instantiates")
	if gallery != null:
		get_root().add_child(gallery)
		await process_frame
		_expect(gallery.asset_ids.size() == 83, "asset gallery exposes all approved runtime assets")
		_expect(gallery.filtered_ids.size() == 83, "asset gallery starts with the complete unfiltered catalog")
		_expect(gallery.card_root != null and gallery.card_root.get_child_count() == 12, "asset gallery renders a bounded twelve-card page")
		gallery._set_background("asphalt")
		_expect(gallery.background_name == "asphalt", "asset gallery switches verification backgrounds")
		gallery._set_zoom(4.0)
		_expect(is_equal_approx(gallery.zoom_level, 4.0), "asset gallery supports four-times pixel inspection")
		gallery._cycle_type_filter()
		_expect(gallery.type_filter != "all", "asset gallery cycles type filters")
		_expect(gallery.filtered_ids.size() > 0 and gallery.filtered_ids.size() < gallery.asset_ids.size(), "asset gallery type filter narrows the visible catalog")
		gallery.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works asset gallery tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works asset gallery tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
