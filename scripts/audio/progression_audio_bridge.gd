extends Node
class_name ProgressionAudioBridge

var garage: GarageManager = null
var career: CareerManager = null
var sfx: GameSFXController = null

func _ready() -> void:
	call_deferred("_bind_runtime")

func _process(_delta: float) -> void:
	if sfx == null or not is_instance_valid(sfx) or garage == null or career == null:
		_bind_runtime()

func _bind_runtime() -> void:
	var sfx_node: Node = get_tree().get_first_node_in_group("game_sfx")
	if sfx_node is GameSFXController:
		sfx = sfx_node as GameSFXController
	var root: Node = get_parent()
	if root == null:
		return
	var garage_candidate: Variant = root.get("garage")
	if garage_candidate is GarageManager:
		_bind_garage(garage_candidate as GarageManager)
	var career_candidate: Variant = root.get("career")
	if career_candidate is CareerManager:
		_bind_career(career_candidate as CareerManager)

func _bind_garage(candidate: GarageManager) -> void:
	garage = candidate
	if not garage.vehicle_purchased.is_connected(_on_vehicle_purchased):
		garage.vehicle_purchased.connect(_on_vehicle_purchased)
	if not garage.upgrade_purchased.is_connected(_on_upgrade_purchased):
		garage.upgrade_purchased.connect(_on_upgrade_purchased)

func _bind_career(candidate: CareerManager) -> void:
	career = candidate
	if not career.contract_claimed.is_connected(_on_contract_claimed):
		career.contract_claimed.connect(_on_contract_claimed)
	if not career.championship_completed.is_connected(_on_championship_completed):
		career.championship_completed.connect(_on_championship_completed)
	if not career.tier_changed.is_connected(_on_tier_changed):
		career.tier_changed.connect(_on_tier_changed)

func _on_vehicle_purchased(_vehicle_id: String, _cost: int) -> void:
	if sfx != null:
		sfx.play_purchase()

func _on_upgrade_purchased(_vehicle_id: String, _group: String, _level: int, _cost: int) -> void:
	if sfx != null:
		sfx.play_upgrade()

func _on_contract_claimed(_contract_id: String, _credits: int, _reputation: int) -> void:
	if sfx != null:
		sfx.play_unlock()

func _on_championship_completed(_championship_id: String, _credits: int, _reputation: int) -> void:
	if sfx != null:
		sfx.play_unlock()

func _on_tier_changed(_previous_tier: int, _current_tier: int) -> void:
	if sfx != null:
		sfx.play_unlock()
