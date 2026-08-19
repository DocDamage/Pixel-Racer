extends Node2D

var track: TrackData
var renderer: TrackRenderer
var runtime: TrackRuntime
var builder: BuilderController
var camera: Camera2D
var player: ArcadeVehicle
var race_controller: RaceController
var elimination_manager: EliminationManager
var ai_nodes: Array[AIDriver] = []
var ai_vehicles: Array[ArcadeVehicle] = []
var ghost := GhostRecorder.new()
var validator := TrackValidator.new()
var career := CareerManager.new()
var garage := GarageManager.new()
var ui: GameUI
var validation_result: Dictionary = {}
var saved_camera_position := Vector2.ZERO
var saved_camera_zoom := Vector2.ONE
var active_race_mode := "circuit"

func _ready() -> void:
	career.load_profile()
	_create_world()
	ui = GameUI.new()
	ui.name = "GameUI"
	add_child(ui)
	ui.setup(self)
	set_track(ProceduralTrackGenerator.new().create_demo_track(), true)
	show_menu()

func _process(delta: float) -> void:
	if player != null and is_instance_valid(player) and GameState.current_mode in [GameState.MODE_TEST, GameState.MODE_RACE]:
		var lookahead := player.velocity * 0.18
		camera.position = camera.position.lerp(player.global_position + lookahead, clampf(delta * 6.0, 0.0, 1.0))
		ghost.capture(delta, player)
		if ui != null:
			ui.update_race_hud(race_state())
	if GameState.current_mode == GameState.MODE_TEST:
		if Input.is_action_just_pressed("toggle_test") or Input.is_action_just_pressed("ui_cancel"):
			return_to_builder()
	elif GameState.current_mode == GameState.MODE_RACE and Input.is_action_just_pressed("ui_cancel"):
		show_menu()

func _create_world() -> void:
	renderer = TrackRenderer.new()
	renderer.name = "TrackRenderer"
	add_child(renderer)
	runtime = TrackRuntime.new()
	runtime.name = "TrackRuntime"
	add_child(runtime)
	camera = Camera2D.new()
	camera.name = "CameraRig"
	camera.position = Vector2(640, 500)
	camera.zoom = Vector2.ONE * 0.7
	add_child(camera)
	camera.make_current()
	builder = BuilderController.new()
	builder.name = "BuilderController"
	add_child(builder)
	builder.track_replaced.connect(_on_track_replaced)
	builder.track_changed.connect(_on_track_changed)
	builder.test_requested.connect(enter_test_drive)
	builder.save_requested.connect(save_current_track)
	builder.load_requested.connect(_on_builder_load_requested)
	builder.tool_changed.connect(_on_tool_changed)

func set_track(new_track: TrackData, reset_history: bool = true) -> void:
	if new_track == null:
		return
	track = new_track
	GameState.current_track = track
	renderer.set_track(track)
	runtime.set_track(track)
	if reset_history or builder.track == null:
		builder.setup(track, renderer, runtime, camera)
	else:
		builder.track = track
	validate_track()
	if ui != null:
		ui.refresh_builder()

func show_menu() -> void:
	_cleanup_race()
	builder.set_enabled(false)
	GameState.set_mode(GameState.MODE_MENU)
	camera.position = _builder_focus_position()
	camera.zoom = Vector2.ONE * 0.55
	if ui != null:
		ui.show_menu()

func enter_builder() -> void:
	_cleanup_race()
	GameState.set_mode(GameState.MODE_BUILDER)
	builder.set_enabled(true)
	camera.position = _builder_focus_position()
	camera.zoom = Vector2.ONE * 0.58
	if ui != null:
		ui.show_builder()
		ui.refresh_builder()

func enter_test_drive() -> void:
	if GameState.current_mode != GameState.MODE_BUILDER or track == null or track.road_tiles.is_empty():
		return
	saved_camera_position = camera.position
	saved_camera_zoom = camera.zoom
	builder.set_enabled(false)
	GameState.set_mode(GameState.MODE_TEST)
	_spawn_player(true)
	ghost.start()
	if bool(validation_result.get("raceable", false)):
		_create_race_controller(3, "circuit", false)
		if race_controller != null:
			race_controller.start_race()
	if ui != null:
		ui.show_race("TEST DRIVE")
		ui.show_countdown("TEST")

func return_to_builder() -> void:
	ghost.stop()
	_cleanup_race()
	GameState.set_mode(GameState.MODE_BUILDER)
	builder.set_enabled(true)
	camera.position = saved_camera_position
	camera.zoom = saved_camera_zoom
	validate_track()
	if ui != null:
		ui.show_builder()
		ui.refresh_builder()

func start_random_track() -> void:
	set_track(ProceduralTrackGenerator.new().generate(), true)
	enter_builder()
	if ui != null:
		ui.show_status("Generated a valid editable circuit.")

func start_event(mode: String = "circuit", laps_override: int = 0, ai_override: int = -1) -> bool:
	validate_track()
	if not bool(validation_result.get("raceable", false)):
		if ui != null:
			ui.show_status("Track is not raceable. Fix the highlighted validation error first.")
		return false
	var preset := RaceModeCatalog.get_mode(mode)
	var laps := int(preset.get("laps", 3)) if laps_override <= 0 else laps_override
	var ai_count := int(preset.get("ai_count", 0)) if ai_override < 0 else ai_override
	if mode in ["time_trial", "sprint", "checkpoint", "drift"]:
		ai_count = 0
	_cleanup_race()
	builder.set_enabled(false)
	GameState.set_mode(GameState.MODE_RACE)
	active_race_mode = mode
	_spawn_player(false)
	_spawn_ai(ai_count)
	_create_race_controller(laps, mode, true)
	if mode == "elimination":
		_create_elimination_manager(float(preset.get("elimination_interval", 20.0)))
	ghost.start()
	if ui != null:
		ui.show_race(str(preset.get("name", mode.to_upper())))
	return true

func save_current_track() -> bool:
	if track == null:
		return false
	var saved := SaveManager.save_track(track)
	if saved:
		track.dirty = false
		var preview_path := "user://tracks/%s/preview.png" % track.track_id
		TrackPreviewGenerator.new().save(track, preview_path)
	if ui != null:
		ui.show_status("Saved %s" % track.name if saved else "Save failed.")
		ui.refresh_builder()
	return saved

func load_track_by_id(track_id: String, open_builder: bool = true) -> bool:
	var loaded = SaveManager.load_track(track_id)
	if loaded == null:
		if ui != null:
			ui.show_status("Could not load track.")
		return false
	set_track(loaded, true)
	if open_builder:
		enter_builder()
	return true

func import_track_file(path: String) -> bool:
	var imported = SaveManager.import_track(path)
	if imported == null:
		if ui != null:
			ui.show_status("Import failed or the file is not a valid track JSON.")
		return false
	set_track(imported, true)
	enter_builder()
	if ui != null:
		ui.show_status("Imported %s" % imported.name)
	return true

func export_current_package() -> String:
	if track == null:
		return ""
	save_current_track()
	var preview := "user://tracks/%s/preview.png" % track.track_id
	var path := TrackPackageManager.new().export_package(track, "user://track_exports", preview)
	if ui != null:
		ui.show_status("Exported to %s" % path if not path.is_empty() else "Export failed.")
	return path

func track_library_entries() -> Array[Dictionary]:
	var entries := SaveManager.list_tracks()
	for entry in entries:
		entry["preview_path"] = "user://tracks/%s/preview.png" % str(entry["track_id"])
		var loaded = SaveManager.load_track(str(entry["track_id"]))
		if loaded != null:
			entry["rating"] = TrackRating.new().calculate(loaded)
	return entries

func select_vehicle(vehicle_id: String) -> bool:
	if not garage.is_owned(vehicle_id):
		return false
	GameState.set_vehicle(vehicle_id)
	return true

func buy_vehicle(vehicle_id: String) -> Dictionary:
	var credits := int(career.profile.get("credits", 0))
	var result := garage.purchase_vehicle(vehicle_id, credits)
	if bool(result.get("success", false)) and int(result.get("cost", 0)) > 0:
		career.profile["credits"] = credits - int(result["cost"])
		career.save_profile()
	return result

func buy_upgrade(vehicle_id: String, group: String) -> Dictionary:
	var credits := int(career.profile.get("credits", 0))
	var result := garage.purchase_upgrade(vehicle_id, group, credits)
	if bool(result.get("success", false)) and int(result.get("cost", 0)) > 0:
		career.profile["credits"] = credits - int(result["cost"])
		career.save_profile()
	return result

func set_vehicle_color(vehicle_id: String, color: String) -> bool:
	return garage.set_color(vehicle_id, color)

func set_vehicle_tuning(vehicle_id: String, key: String, value: float) -> void:
	garage.set_tuning(vehicle_id, key, value)

func claim_contract(contract_id: String) -> bool:
	var success := career.claim_contract(contract_id, track)
	if ui != null:
		ui.show_status("Contract complete." if success else "Current track does not meet that contract yet.")
	return success

func validate_track() -> Dictionary:
	if track == null:
		validation_result = {"errors": [], "warnings": [], "raceable": false}
		return validation_result
	validation_result = validator.validate(track)
	var issues: Array[Dictionary] = []
	for issue in validation_result.get("errors", []):
		issues.append(issue)
	for issue in validation_result.get("warnings", []):
		issues.append(issue)
	renderer.set_validation_issues(issues)
	return validation_result

func race_state() -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var state := {
		"mode": active_race_mode,
		"speed": roundi(player.velocity.length() * 0.42),
		"nitro": player.nitro,
		"drift": player.drift_score,
		"surface": player.current_surface,
		"lap": 0,
		"laps": 0,
		"checkpoint": 0,
		"checkpoints": track.get_checkpoints_sorted().size(),
		"time": 0.0,
		"best": INF,
		"remaining": 0.0,
		"racers": 1 + ai_vehicles.size()
	}
	if race_controller != null and is_instance_valid(race_controller):
		state["lap"] = race_controller.current_lap
		state["laps"] = race_controller.laps_required
		state["checkpoint"] = race_controller.current_checkpoint
		state["time"] = race_controller.current_lap_time()
		state["best"] = race_controller.best_lap
		state["remaining"] = race_controller.remaining_time()
	if elimination_manager != null and is_instance_valid(elimination_manager):
		state["remaining"] = elimination_manager.remaining
		state["racers"] = elimination_manager.racers.size()
	return state

func _spawn_player(player_controlled: bool) -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = ArcadeVehicle.new()
	player.name = "PlayerVehicle"
	add_child(player)
	var spawn := _start_position()
	player.global_position = spawn["position"]
	player.heading = float(spawn["heading"])
	player.setup(track, GameState.current_vehicle_id, player_controlled)
	camera.position = player.global_position
	camera.zoom = Vector2.ONE

func _spawn_ai(count: int) -> void:
	if count <= 0:
		return
	var spawn := _start_position()
	var forward := Vector2.UP.rotated(float(spawn["heading"]))
	var right := forward.rotated(PI * 0.5)
	var ids := VehicleCatalog.new().ids()
	for i in range(count):
		var vehicle := ArcadeVehicle.new()
		vehicle.name = "AIVehicle_%d" % i
		add_child(vehicle)
		var id := ids[(i + 3) % ids.size()] if not ids.is_empty() else "Hachiroku_Drifter"
		vehicle.global_position = Vector2(spawn["position"]) - forward * (48.0 + i * 42.0) + right * (-28.0 if i % 2 == 0 else 28.0)
		vehicle.heading = float(spawn["heading"])
		vehicle.setup(track, id, false)
		var ai := AIDriver.new()
		ai.name = "AIDriver_%d" % i
		add_child(ai)
		ai.setup(vehicle, track, {"aggression": 0.42 + minf(0.45, i * 0.09), "consistency": 0.70 + minf(0.25, i * 0.05), "mistake_rate": maxf(0.01, 0.08 - i * 0.01)})
		ai.enabled = false
		ai_vehicles.append(vehicle)
		ai_nodes.append(ai)
	var racer_context: Array[ArcadeVehicle] = [player]
	racer_context.append_array(ai_vehicles)
	for ai in ai_nodes:
		ai.set_racer_context(racer_context)

func _create_race_controller(laps: int, mode: String, countdown: bool) -> void:
	race_controller = RaceController.new()
	race_controller.name = "RaceController"
	add_child(race_controller)
	race_controller.setup(track, player, laps, mode)
	race_controller.countdown_changed.connect(_on_countdown_changed)
	race_controller.lap_completed.connect(_on_lap_completed)
	race_controller.race_finished.connect(_on_race_finished)
	race_controller.event_failed.connect(_on_event_failed)
	if countdown:
		race_controller.start_countdown()

func _create_elimination_manager(interval: float) -> void:
	elimination_manager = EliminationManager.new()
	elimination_manager.name = "EliminationManager"
	add_child(elimination_manager)
	var racers: Array[ArcadeVehicle] = [player]
	racers.append_array(ai_vehicles)
	elimination_manager.setup(track, player, racers, interval)
	elimination_manager.stop()
	elimination_manager.racer_eliminated.connect(_on_racer_eliminated)
	elimination_manager.player_eliminated.connect(_on_player_eliminated)
	elimination_manager.player_won.connect(_on_player_won)

func _on_countdown_changed(value: int) -> void:
	if ui != null:
		ui.show_countdown("GO!" if value == 0 else str(value))
	if value == 0:
		if player != null:
			player.input_enabled = true
		for ai in ai_nodes:
			ai.enabled = true
		if elimination_manager != null and is_instance_valid(elimination_manager):
			elimination_manager.start()

func _on_lap_completed(lap_number: int, lap_time: float) -> void:
	if ui != null:
		ui.show_countdown("LAP %d\n%.2f" % [lap_number, lap_time])

func _on_race_finished(total_time: float) -> void:
	ghost.stop()
	if active_race_mode != "elimination" and ui != null:
		ui.show_result("FINISH", "%.2f seconds" % total_time)

func _on_event_failed(reason: String) -> void:
	ghost.stop()
	if ui != null:
		ui.show_result("EVENT FAILED", reason)

func _on_racer_eliminated(vehicle: ArcadeVehicle) -> void:
	if vehicle == player:
		return
	var index := ai_vehicles.find(vehicle)
	if index >= 0:
		if index < ai_nodes.size() and is_instance_valid(ai_nodes[index]):
			ai_nodes[index].queue_free()
		ai_nodes.remove_at(index)
		ai_vehicles.remove_at(index)
	if is_instance_valid(vehicle):
		vehicle.queue_free()
	if ui != null:
		ui.show_countdown("ELIMINATED")

func _on_player_eliminated() -> void:
	if race_controller != null:
		race_controller.stop()
	if player != null:
		player.input_enabled = false
	if ui != null:
		ui.show_result("ELIMINATED", "You were last when the timer expired.")

func _on_player_won() -> void:
	if race_controller != null:
		race_controller.stop()
	if ui != null:
		ui.show_result("WINNER", "Last racer standing.")

func _cleanup_race() -> void:
	if race_controller != null and is_instance_valid(race_controller):
		race_controller.stop()
		race_controller.queue_free()
	race_controller = null
	if elimination_manager != null and is_instance_valid(elimination_manager):
		elimination_manager.stop()
		elimination_manager.queue_free()
	elimination_manager = null
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	for ai in ai_nodes:
		if is_instance_valid(ai): ai.queue_free()
	for vehicle in ai_vehicles:
		if is_instance_valid(vehicle): vehicle.queue_free()
	ai_nodes.clear()
	ai_vehicles.clear()

func _on_track_changed() -> void:
	validate_track()
	if ui != null:
		ui.refresh_builder()

func _on_track_replaced(new_track) -> void:
	track = new_track
	GameState.current_track = track
	builder.track = track
	renderer.set_track(track)
	runtime.set_track(track)
	validate_track()
	if ui != null:
		ui.refresh_builder()

func _on_tool_changed(_tool_name: String) -> void:
	if ui != null:
		ui.refresh_builder()

func _on_builder_load_requested() -> void:
	if ui != null:
		ui.open_track_library()

func _start_position() -> Dictionary:
	var start := track.get_start_object()
	var cell := Vector2i.ZERO
	if not start.is_empty():
		cell = Vector2i(int(start.get("x", 0)), int(start.get("y", 0)))
	else:
		cell = track.nearest_road_cell(track.world_to_cell(camera.position))
	if cell.x < 0:
		var roads := track.road_cells()
		cell = roads[0] if not roads.is_empty() else Vector2i(1, 1)
	var heading := 0.0
	var graph := TrackGraph.new()
	graph.build(track)
	var order := graph.find_loop_order(cell)
	if order.size() > 1:
		var direction := track.cell_to_world(order[1]) - track.cell_to_world(order[0])
		heading = Vector2.UP.angle_to(direction.normalized())
	return {"position": track.cell_to_world(cell), "heading": heading}

func _builder_focus_position() -> Vector2:
	if track == null:
		return Vector2(640, 500)
	var start := track.get_start_object()
	if not start.is_empty():
		return track.cell_to_world(Vector2i(int(start.get("x", 0)), int(start.get("y", 0))))
	var roads := track.road_cells()
	return track.cell_to_world(roads[0]) if not roads.is_empty() else Vector2(640, 500)
