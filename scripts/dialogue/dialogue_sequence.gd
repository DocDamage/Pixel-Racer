extends RefCounted
class_name DialogueSequence

var id: String = ""
var event: String = ""
var entries: Array[DialogueEntry] = []
var once_only: bool = false
var metadata: Dictionary = {}

static func from_dict(data: Dictionary) -> DialogueSequence:
	var sequence := DialogueSequence.new()
	sequence.id = str(data.get("id", ""))
	sequence.event = str(data.get("event", ""))
	sequence.once_only = bool(data.get("once_only", false))
	var raw_entries: Variant = data.get("entries", [])
	if raw_entries is Array:
		for raw_entry in raw_entries as Array:
			if raw_entry is Dictionary:
				sequence.entries.append(DialogueEntry.from_dict(raw_entry as Dictionary))
	var raw_metadata: Variant = data.get("metadata", {})
	sequence.metadata = (raw_metadata as Dictionary).duplicate(true) if raw_metadata is Dictionary else {}
	return sequence

func to_dict() -> Dictionary:
	var serialized: Array[Dictionary] = []
	for entry in entries:
		serialized.append(entry.to_dict())
	return {
		"id": id,
		"event": event,
		"once_only": once_only,
		"entries": serialized,
		"metadata": metadata.duplicate(true)
	}
