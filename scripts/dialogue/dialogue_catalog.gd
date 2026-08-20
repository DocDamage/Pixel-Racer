extends RefCounted
class_name DialogueCatalog

const DEFAULT_CHARACTER_PATH := "res://data/dialogue/dialogue_characters.json"

var characters: Dictionary = {}
var sequences: Dictionary = {}

func load_characters(path: String = DEFAULT_CHARACTER_PATH) -> bool:
	characters.clear()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var root: Dictionary = parsed as Dictionary
	var raw_characters: Variant = root.get("characters", [])
	if not raw_characters is Array:
		return false
	for raw_character in raw_characters as Array:
		if not raw_character is Dictionary:
			continue
		var character := DialogueCharacter.from_dict(raw_character as Dictionary)
		if not character.id.is_empty():
			characters[character.id] = character
	return not characters.is_empty()

func load_sequences(path: String) -> bool:
	sequences.clear()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var root: Dictionary = parsed as Dictionary
	var raw_sequences: Variant = root.get("sequences", [])
	if not raw_sequences is Array:
		return false
	for raw_sequence in raw_sequences as Array:
		if not raw_sequence is Dictionary:
			continue
		var sequence := DialogueSequence.from_dict(raw_sequence as Dictionary)
		if not sequence.id.is_empty():
			sequences[sequence.id] = sequence
	return not sequences.is_empty()

func character_ids() -> Array[String]:
	var output: Array[String] = []
	for key in characters.keys():
		output.append(str(key))
	output.sort()
	return output

func get_character(character_id: String) -> DialogueCharacter:
	return characters.get(character_id) as DialogueCharacter

func get_sequence(sequence_id: String) -> DialogueSequence:
	return sequences.get(sequence_id) as DialogueSequence

func display_name(speaker_id: String) -> String:
	var character: DialogueCharacter = get_character(speaker_id)
	return character.display_name if character != null else speaker_id.replace("_", " ").capitalize()
