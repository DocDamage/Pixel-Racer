extends SceneTree

var failures := 0
var generated_tracks := 0
var generated_cells := 0

func _init() -> void:
	_stress_procedural_generation()
	_stress_large_track_graph()
	_stress_twelve_racer_ai_paths()
	_stress_serialization()
	_stress_preview_render()
	if failures == 0:
		print("Pixel Track Works stress tests: PASS (%d tracks, %d road cells)" % [generated_tracks, generated_cells])
		quit(0)
	else:
		push_error("Pixel Track Works stress tests: %d failure(s)" % failures)
		quit(1)

func _stress_procedural_generation() -> void:
	var styles := ["circuit", "mixed", "rally"]
	for style_index in range(styles.size()):
		var style: String = styles[style_index]
		for seed_offset in range(1, 21):
			var map_size := 40 + (seed_offset % 6) * 8
			var seed_value := 10000 + style_index * 1000 + seed_offset
			var track := ProceduralTrackGenerator.new().generate(seed_value, map_size, style)
			generated_tracks += 1
			generated_cells += track.road_tiles.size()
			var validation := TrackValidator.new().validate(track)
			_expect(bool(validation.get("raceable", false)), "generated %s seed %d validates" % [style, seed_value])
			var start := track.get_start_object()
			var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
			var graph := TrackGraph.new()
			graph.build(track, "main")
			_expect(graph.is_single_loop(start_cell), "generated %s seed %d keeps a main loop" % [style, seed_value])

func _stress_large_track_graph() -> void:
	var track := ProceduralTrackGenerator.new().generate(424242, 96, "mixed")
	var start := track.get_start_object()
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var graph := TrackGraph.new()
	graph.build(track, "main")
	var order := graph.find_loop_order(start_cell)
	_expect(not order.is_empty(), "96x96 track produces ordered main path")
	_expect(order.size() == track.get_route_cells("main").size(), "large ordered path visits every main cell exactly once")
	_expect(graph.connected_count(start_cell) == order.size(), "large main graph remains fully connected")
	var rating := TrackRating.new().calculate(track)
	_expect(float(rating.get("length", 0.0)) > 0.0, "large track rating remains computable")

func _stress_twelve_racer_ai_paths() -> void:
	var track := ProceduralTrackGenerator.new().generate(8675309, 80, "circuit")
	var validation := TrackValidator.new().validate(track)
	_expect(bool(validation.get("raceable", false)), "12-racer stress source track is valid")
	var start := track.get_start_object()
	var start_cell := Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	var spawn := track.cell_to_world(start_cell)
	var racers: Array[ArcadeVehicle] = []
	for index in range(12):
		var vehicle := ArcadeVehicle.new()
		vehicle.position = spawn + Vector2(float(index % 2) * 24.0, float(index) * 18.0)
		racers.append(vehicle)
	var ai_nodes: Array[AIDriver] = []
	for index in range(1, racers.size()):
		var ai := AIDriver.new()
		ai.enabled = false
		var skill := float(index) / 11.0
		var setup_ok := ai.setup(racers[index], track, {
			"aggression": lerpf(0.35, 0.9, skill),
			"consistency": lerpf(0.65, 0.96, skill),
			"corner_skill": lerpf(0.55, 0.95, skill),
			"braking_skill": lerpf(0.55, 0.95, skill),
			"overtake_bias": lerpf(0.3, 0.9, skill),
			"route_id": "main"
		})
		_expect(setup_ok, "AI racer %d builds a valid racing path" % index)
		_expect(ai.path.size() == track.get_route_cells("main").size(), "AI racer %d receives full main line" % index)
		ai_nodes.append(ai)
	for ai in ai_nodes:
		ai.set_racer_context(racers)
		_expect(ai.nearby_racers.size() == 12, "AI racer receives 12-car avoidance context")

func _stress_serialization() -> void:
	var source := ProceduralTrackGenerator.new().generate(1337, 88, "rally")
	var expected_roads := source.road_tiles.size()
	var expected_routes := source.route_ids().size()
	var current := source
	for iteration in range(100):
		var payload := current.to_dict()
		var loaded := TrackData.new()
		loaded.from_dict(payload)
		if loaded.road_tiles.size() != expected_roads or loaded.route_ids().size() != expected_routes:
			_fail("serialization iteration %d changed track topology" % iteration)
			return
		current = loaded
	_expect(true, "100 serialization migrations preserve topology")

func _stress_preview_render() -> void:
	var track := ProceduralTrackGenerator.new().generate(9001, 96, "mixed")
	var image := TrackPreviewGenerator.new().render(track, Vector2i(512, 288))
	_expect(image.get_width() == 512 and image.get_height() == 288, "large preview renders at library-card source resolution")
	_expect(not image.is_empty(), "large preview contains image data")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		_fail(label)

func _fail(label: String) -> void:
	failures += 1
	push_error("FAIL: %s" % label)
