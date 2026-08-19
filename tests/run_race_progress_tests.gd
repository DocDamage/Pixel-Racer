extends SceneTree

var failures := 0

func _init() -> void:
	_test_grid_start_order_and_finish_places()
	if failures == 0:
		print("Race progress tests: PASS")
		quit(0)
	else:
		push_error("Race progress tests: %d failure(s)" % failures)
		quit(1)

func _test_grid_start_order_and_finish_places() -> void:
	var track := ProceduralTrackGenerator.new().create_demo_track()
	var start := track.get_start_object()
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track, "main")
	var order := graph.find_loop_order(start_cell)
	_expect(order.size() > 12, "demo circuit provides enough ordered road cells")
	if order.size() <= 12:
		return
	var player := ArcadeVehicle.new()
	var ai_one := ArcadeVehicle.new()
	var ai_two := ArcadeVehicle.new()
	root.add_child(player)
	root.add_child(ai_one)
	root.add_child(ai_two)
	player.position = track.cell_to_world(order[0])
	ai_one.position = track.cell_to_world(order[order.size() - 1])
	ai_two.position = track.cell_to_world(order[order.size() - 2])
	var racers: Array[ArcadeVehicle] = [player, ai_one, ai_two]
	var tracker := RaceProgressTracker.new()
	_expect(tracker.setup(track, racers, 2), "standings tracker accepts the valid main circuit")
	_expect(tracker.position_of(player) == 1, "player on start line ranks ahead of cars staged behind it")
	_expect(tracker.progress_value(ai_one) < tracker.progress_value(player), "last-path grid slot begins on lap minus one")
	tracker.start()
	for index in range(1, order.size()):
		player.position = track.cell_to_world(order[index])
		tracker.update()
	player.position = track.cell_to_world(order[0])
	tracker.update()
	_expect(int(tracker.state[player.get_instance_id()].get("lap", -99)) == 1, "crossing the ordered path increments lap progress")
	tracker.force_finish(ai_one)
	tracker.force_finish(player)
	var standings := tracker.standings()
	_expect(int(tracker.state[ai_one.get_instance_id()].get("finish_place", 0)) == 1, "first forced finisher keeps P1")
	_expect(int(tracker.state[player.get_instance_id()].get("finish_place", 0)) == 2, "second forced finisher keeps P2")
	_expect(standings[0].get("vehicle") == ai_one and standings[1].get("vehicle") == player, "finished racers sort by immutable finish order")
	root.remove_child(player)
	root.remove_child(ai_one)
	root.remove_child(ai_two)
	player.free()
	ai_one.free()
	ai_two.free()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
