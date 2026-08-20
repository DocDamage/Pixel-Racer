extends SceneTree

const MainScene = preload("res://scenes/main/main.tscn")

var failures := 0

func _init() -> void:
	_test_main_audio_wiring()
	_finish()

func _test_main_audio_wiring() -> void:
	var root: Node = MainScene.instantiate()
	_expect(root != null, "main scene instantiates for audio integration audit")
	if root == null:
		return
	_expect(root.get_node_or_null("UIAudio") is UIAudioController, "main scene includes procedural UI audio")
	_expect(root.get_node_or_null("MusicController") is MusicController, "main scene includes adaptive procedural music")
	_expect(root.get_node_or_null("GameSFX") is GameSFXController, "main scene includes gameplay SFX generator")
	_expect(root.get_node_or_null("AmbienceController") is AmbienceController, "main scene includes procedural crowd/environment ambience")
	_expect(root.get_node_or_null("ProgressionAudioBridge") is ProgressionAudioBridge, "main scene wires progression purchase/upgrade/unlock SFX bridge")
	_expect(root.get_node_or_null("PresentationController") is PresentationController, "main scene wires race event presentation/SFX bridge")
	root.free()

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
