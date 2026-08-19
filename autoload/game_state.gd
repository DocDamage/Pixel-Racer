extends Node

signal mode_changed(mode: String)
signal vehicle_changed(vehicle_id: String)

const MODE_MENU := "menu"
const MODE_BUILDER := "builder"
const MODE_TEST := "test"
const MODE_RACE := "race"

var current_mode: String = MODE_MENU
var current_track = null
var current_vehicle_id: String = "Hachiroku_Drifter"
var career_profile: Dictionary = {}

func set_mode(mode: String) -> void:
	if current_mode == mode:
		return
	current_mode = mode
	mode_changed.emit(mode)

func set_vehicle(vehicle_id: String) -> void:
	if vehicle_id.is_empty() or current_vehicle_id == vehicle_id:
		return
	current_vehicle_id = vehicle_id
	vehicle_changed.emit(vehicle_id)
