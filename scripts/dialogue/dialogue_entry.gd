extends RefCounted
class_name DialogueEntry

var id: String = ""
var speaker_id: String = ""
var portrait_id: String = ""
var text: String = ""
var event: String = ""
var priority: int = 0
var duration: float = 3.0
var blocking: bool = false
var condition: String = ""
var once_only: bool = false
var cooldown: float = 0.0
var metadata: Dictionary = {}

static func from_dict(data: Dictionary) -> DialogueEntry:
	var entry := DialogueEntry.new()
	entry.id = str(data.get("id", ""))
	entry.speaker_id = str(data.get("speaker_id", ""))
	entry.portrait_id = str(data.get("portrait_id", entry.speaker_id))
	entry.text = str(data.get("text", ""))
	entry.event = str(data.get("event", ""))
	entry.priority = int(data.get("priority", 0))
	entry.duration = maxf(0.25, float(data.get("duration", 3.0)))
	entry.blocking = bool(data.get("blocking", false))
	entry.condition = str(data.get("condition", ""))
	entry.once_only = bool(data.get("once_only", false))
	entry.cooldown = maxf(0.0, float(data.get("cooldown", 0.0)))
	var raw_metadata: Variant = data.get("metadata", {})
	entry.metadata = raw_metadata.duplicate(true) if raw_metadata is Dictionary else {}
	return entry

func to_dict() -> Dictionary:
	return {
		"id": id,
		"speaker_id": speaker_id,
		"portrait_id": portrait_id,
		"text": text,
		"event": event,
		"priority": priority,
		"duration": duration,
		"blocking": blocking,
		"condition": condition,
		"once_only": once_only,
		"cooldown": cooldown,
		"metadata": metadata.duplicate(true)
	}
