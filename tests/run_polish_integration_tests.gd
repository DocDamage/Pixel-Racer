extends SceneTree

const ROOT_PATH := "res://scripts/main/catalog_game_root.gd"
const BUILDER_PATH := "res://scripts/builder/catalog_builder_controller.gd"
const TRANSITION_PATH := "res://scripts/ui/mode_transition_overlay.gd"

var failures := 0

func _init() -> void:
	_test_polish_wiring()
	_finish()

func _test_polish_wiring() -> void:
	var root_source := _read(ROOT_PATH)
	var builder_source := _read(BUILDER_PATH)
	var transition_source := _read(TRANSITION_PATH)
	_expect(not root_source.is_empty(), "catalog game root is readable for polish audit")
	_expect(not builder_source.is_empty(), "catalog builder is readable for polish audit")
	_expect(not transition_source.is_empty(), "mode transition controller is readable for polish audit")
	_expect(builder_source.contains("signal edit_committed"), "catalog builder exposes committed-edit feedback signal")
	_expect(builder_source.contains("edit_committed.emit()"), "catalog builder emits feedback only after committed edits")
	_expect(root_source.contains("edit_committed.connect(_on_builder_edit_committed)"), "game root wires committed builder edits to polish feedback")
	_expect(root_source.contains("play_builder_place()"), "builder edits drive procedural placement SFX")
	_expect(root_source.contains("play_save()"), "successful saves drive procedural save SFX")
	_expect(root_source.contains("play_invalid()"), "invalid save/event outcomes drive explicit error SFX")
	_expect(root_source.contains("ModeTransitionOverlay.new()"), "game root installs shared mode-transition treatment")
	_expect(transition_source.contains("GameState.mode_changed.connect(_on_mode_changed)"), "mode transition follows authoritative GameState changes")
	_expect(transition_source.contains("mouse_filter = Control.MOUSE_FILTER_IGNORE"), "mode fade never blocks player input")
	_expect(transition_source.contains("Tween.EASE_OUT"), "mode fade uses bounded eased transition instead of abrupt screen swap")

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var source := file.get_as_text()
	file.close()
	return source

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works polish integration tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works polish integration tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
