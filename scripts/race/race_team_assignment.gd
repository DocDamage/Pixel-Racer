extends RefCounted
class_name RaceTeamAssignment

var catalog := TeamCatalog.new()

func assignment_for_index(index: int) -> Dictionary:
	var ids: Array[String] = catalog.ids()
	if ids.is_empty():
		return {}
	var team_id: String = ids[posmod(index, ids.size())]
	var team: Dictionary = catalog.team(team_id)
	var drivers: Array = team.get("driver_pool", [])
	var driver_id: String = ""
	if not drivers.is_empty():
		driver_id = str(drivers[posmod(index, drivers.size())])
	return {
		"team_id": team_id,
		"display_name": str(team.get("display_name", team_id)),
		"avatar_asset_id": str(team.get("avatar_asset_id", "")),
		"presentation_car_asset_id": str(team.get("presentation_car_asset_id", "")),
		"driver_asset_id": driver_id
	}

func apply_to_vehicle(vehicle: ArcadeVehicle, index: int) -> Dictionary:
	var assignment: Dictionary = assignment_for_index(index)
	if vehicle == null or assignment.is_empty():
		return assignment
	for raw_key in ["team_id", "team_display_name", "team_avatar_asset_id", "team_car_asset_id", "driver_asset_id"]:
		var key: String = str(raw_key)
		var source_key: String = key
		match key:
			"team_display_name": source_key = "display_name"
			"team_avatar_asset_id": source_key = "avatar_asset_id"
			"team_car_asset_id": source_key = "presentation_car_asset_id"
		vehicle.set_meta(key, assignment.get(source_key, ""))
	return assignment
