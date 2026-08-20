extends SceneTree

var failures := 0

func _init() -> void:
	_test_release_report_is_explicit()
	_test_release_metadata_contract()
	_test_manual_check_ids_are_stable()
	if failures == 0:
		print("Pixel Track Works release-readiness tests: PASS")
		quit(0)
	else:
		push_error("Pixel Track Works release-readiness tests: %d failure(s)" % failures)
		quit(1)

func _test_release_report_is_explicit() -> void:
	var readiness := ReleaseReadiness.new()
	var report: Dictionary = readiness.report()
	var blockers: Array = Array(report.get("automated_blockers", []))
	var ids: Array[String] = []
	for blocker in blockers:
		if blocker is Dictionary:
			ids.append(str((blocker as Dictionary).get("id", "")))
	_expect("character_assets" in ids, "missing unmeasured character atlas remains an explicit release blocker")
	_expect("application_version" not in ids, "pre-release application version is explicitly set")
	_expect(ids.size() == 1 and "character_assets" in ids, "character source completion is the sole automated release blocker")
	_expect(not bool(report.get("production_ready", true)), "current incomplete manual/character state cannot report production-ready")
	_expect(Array(report.get("pending_manual_checks", [])).size() == ReleaseReadiness.MANUAL_CHECKS.size(), "all manual QA checks begin pending")
	for action in ReleaseReadiness.ESSENTIAL_INPUT_ACTIONS:
		_expect(InputMap.has_action(action), "essential input action exists: %s" % String(action))

func _test_release_metadata_contract() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	_expect(not version.is_empty(), "project exposes a non-empty release version")
	var export_text := _read_text("res://export_presets.cfg")
	_expect(not export_text.is_empty(), "Windows export preset is readable")
	_expect(_quoted_setting(export_text, "application/product_version") == version, "Windows product version matches project version")
	_expect(_quoted_setting(export_text, "application/file_version") == _windows_file_version(version), "Windows numeric file version matches the semantic project version")
	var scene_text := _read_text("res://scenes/main/main.tscn")
	_expect(scene_text.contains("res://scripts/release/release_self_test.gd"), "main scene wires the packaged release self-test")
	_expect(scene_text.contains("name=\"ReleaseSelfTest\""), "main scene instantiates the packaged release self-test node")
	for path in [
		"res://README.md",
		"res://docs/QUICK_START.md",
		"res://docs/RELEASE_NOTES_1.0.0_RC_DRAFT.md",
		"res://docs/ASSET_ATTRIBUTION.md"
	]:
		_expect(FileAccess.file_exists(path), "release bundle source exists: %s" % path)

func _test_manual_check_ids_are_stable() -> void:
	var seen: Dictionary = {}
	for check in ReleaseReadiness.MANUAL_CHECKS:
		var id: String = str(check.get("id", ""))
		_expect(not id.is_empty(), "manual release check has a stable ID")
		_expect(not seen.has(id), "manual release check ID is unique: %s" % id)
		seen[id] = true

func _windows_file_version(version: String) -> String:
	var without_build := version.split("+", false, 1)[0]
	var core_and_pre := without_build.split("-", false, 1)
	var core := core_and_pre[0].split(".", false)
	var numeric: Array[int] = [0, 0, 0, 0]
	for index in range(mini(3, core.size())):
		numeric[index] = int(core[index])
	if core_and_pre.size() > 1:
		for token in core_and_pre[1].split(".", false):
			if token.is_valid_int():
				numeric[3] = int(token)
	return "%d.%d.%d.%d" % numeric

func _quoted_setting(text: String, key: String) -> String:
	var prefix := "%s=\"" % key
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with(prefix) and line.ends_with("\""):
			return line.substr(prefix.length(), line.length() - prefix.length() - 1)
	return ""

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
