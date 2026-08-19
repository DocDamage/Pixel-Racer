extends SceneTree

var failures := 0

func _init() -> void:
	_test_release_report_is_explicit()
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
	_expect(not bool(report.get("production_ready", true)), "current incomplete manual/character state cannot report production-ready")
	_expect(Array(report.get("pending_manual_checks", [])).size() == ReleaseReadiness.MANUAL_CHECKS.size(), "all manual QA checks begin pending")
	for action in ReleaseReadiness.ESSENTIAL_INPUT_ACTIONS:
		_expect(InputMap.has_action(action), "essential input action exists: %s" % String(action))

func _test_manual_check_ids_are_stable() -> void:
	var seen: Dictionary = {}
	for check in ReleaseReadiness.MANUAL_CHECKS:
		var id: String = str(check.get("id", ""))
		_expect(not id.is_empty(), "manual release check has a stable ID")
		_expect(not seen.has(id), "manual release check ID is unique: %s" % id)
		seen[id] = true

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
