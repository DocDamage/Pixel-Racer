extends RefCounted
class_name DialogueCharacter

var id: String = ""
var display_name: String = ""
var portrait_id: String = ""
var role: String = ""
var voice_profile: String = "default"
var radio_enabled: bool = true
var metadata: Dictionary = {}

static func from_dict(data: Dictionary) -> DialogueCharacter:
	var character := DialogueCharacter.new()
	character.id = str(data.get("id", ""))
	character.display_name = str(data.get("display_name", character.id.replace("_", " ").capitalize()))
	character.portrait_id = str(data.get("portrait_id", character.id))
	character.role = str(data.get("role", ""))
	character.voice_profile = str(data.get("voice_profile", "default"))
	character.radio_enabled = bool(data.get("radio_enabled", true))
	var raw_metadata: Variant = data.get("metadata", {})
	character.metadata = (raw_metadata as Dictionary).duplicate(true) if raw_metadata is Dictionary else {}
	return character

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"portrait_id": portrait_id,
		"role": role,
		"voice_profile": voice_profile,
		"radio_enabled": radio_enabled,
		"metadata": metadata.duplicate(true)
	}
