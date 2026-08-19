extends RefCounted
class_name EnvironmentCatalog

const ITEMS := {
	"barrier": {"name": "Red Barrier", "texture": "res://Enviroment/barrier_red.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"barrier_red": {"name": "Red Barrier", "texture": "res://Enviroment/barrier_red.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"barrier_green": {"name": "Green Barrier", "texture": "res://Enviroment/barrier_green.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"barrier_white": {"name": "White Barrier", "texture": "res://Enviroment/barrier_white.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"barrier_yellow": {"name": "Yellow Barrier", "texture": "res://Enviroment/barrier_yellow.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"barrier_black": {"name": "Black Barrier", "texture": "res://Enviroment/barrier_black.png", "size": Vector2(144, 16), "collision": true, "dynamic": false},
	"tire": {"name": "Loose Tire", "texture": "res://Enviroment/tire.png", "size": Vector2(16, 16), "collision": true, "dynamic": true}
}

static func ids() -> Array[String]:
	var output: Array[String] = []
	for id in ITEMS:
		if id != "barrier":
			output.append(str(id))
	return output

static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, ITEMS["barrier"]).duplicate(true)
