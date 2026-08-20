extends Node2D
class_name VenueController

signal anchor_registered(anchor_name: StringName)

var anchors: Dictionary = {}

func _ready() -> void:
	rebuild_anchor_index()

func rebuild_anchor_index() -> void:
	anchors.clear()
	_index_markers(self)

func register_anchor(anchor_name: StringName, node: Node2D) -> void:
	if anchor_name.is_empty() or node == null:
		return
	anchors[anchor_name] = node
	anchor_registered.emit(anchor_name)

func unregister_anchor(anchor_name: StringName) -> void:
	anchors.erase(anchor_name)

func has_anchor(anchor_name: StringName) -> bool:
	var node: Node2D = anchors.get(anchor_name) as Node2D
	return node != null and is_instance_valid(node)

func anchor_position(anchor_name: StringName) -> Vector2:
	var node: Node2D = anchors.get(anchor_name) as Node2D
	if node == null or not is_instance_valid(node):
		return global_position
	return node.global_position

func anchor_node(anchor_name: StringName) -> Node2D:
	var node: Node2D = anchors.get(anchor_name) as Node2D
	return node if node != null and is_instance_valid(node) else null

func available_anchor_names() -> Array[StringName]:
	var output: Array[StringName] = []
	for key in anchors.keys():
		var anchor_name := StringName(str(key))
		if has_anchor(anchor_name):
			output.append(anchor_name)
	output.sort()
	return output

func _index_markers(root: Node) -> void:
	for child in root.get_children():
		if child is Marker2D:
			var marker := child as Marker2D
			register_anchor(StringName(marker.name), marker)
		_index_markers(child)
