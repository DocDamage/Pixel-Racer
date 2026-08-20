extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main/main.tscn"

var failures := 0

func _init() -> void:
	_test_main_audio_wiring()
	_finish()

func _test_main_audio_wiring() -> void:
	var file := FileAccess.open(MAIN_SCENE_PATH, FileAccess.READ)
	_expect(file != null, "main scene is readable for audio integration audit")
	if file == null:
		return
	var source: String = file.get_as_text()
	file.close()
	_expect(source.contains("res://scripts/audio/ui_audio.gd"), "main scene includes procedural UI audio script")
	_expect(source.contains("res://scripts/audio/music_controller.gd"), "main scene includes adaptive procedural music script")
	_expect(source.contains("res://scripts/audio/game_sfx.gd"), "main scene includes gameplay SFX generator script")
	_expect(source.contains("res://scripts/audio/ambience_controller.gd"), "main scene includes procedural crowd/environment ambience script")
	_expect(source.contains("res://scripts/audio/progression_audio_bridge.gd"), "main scene includes progression purchase/upgrade/unlock SFX bridge script")
	_expect(source.contains("res://scripts/presentation/presentation_controller.gd"), "main scene includes race event presentation/SFX bridge script")
	_expect(source.contains("[node name=\"UIAudio\""), "main scene instantiates UIAudio node")
	_expect(source.contains("[node name=\"MusicController\""), "main scene instantiates MusicController node")
	_expect(source.contains("[node name=\"GameSFX\""), "main scene instantiates GameSFX node")
	_expect(source.contains("[node name=\"AmbienceController\""), "main scene instantiates AmbienceController node")
	_expect(source.contains("[node name=\"ProgressionAudioBridge\""), "main scene instantiates ProgressionAudioBridge node")
	_expect(source.contains("[node name=\"PresentationController\""), "main scene instantiates PresentationController node")

func _finish() -> void:
	if failures == 0:
		print("Pixel Track Works audio integration tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works audio integration tests: %d failure(s)" % failures)
		quit(1)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
