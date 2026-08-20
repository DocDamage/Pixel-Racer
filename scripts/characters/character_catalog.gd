extends RefCounted
class_name CharacterCatalog

const DEFAULT_MANIFEST_PATH := "res://data/characters/character_manifest.json"

var characters: Dictionary = {}
var portrait_manifest: Dictionary = {}
var measured: bool = false
var source_path: String = ""

func load_manifest(path: String = DEFAULT_MANIFEST_PATH) -> bool:
	characters.clear()
	portrait_manifest.clear()
	measured = false
	source_path = path
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var root: Dictionary = parsed as Dictionary
	measured = bool(root.get("measured", false))
	var raw_characters: Variant = root.get("characters", [])
	if raw_characters is Array:
		for raw_character in raw_characters as Array:
			if not raw_character is Dictionary:
				continue
			var definition := CharacterDefinition.from_dict(raw_character as Dictionary)
			if definition.id.is_empty():
				continue
			characters[definition.id] = definition
	var raw_portraits: Variant = root.get("portraits", {})
	if raw_portraits is Dictionary:
		portrait_manifest = (raw_portraits as Dictionary).duplicate(true)
	return not characters.is_empty()

func ids() -> Array[String]:
	var output: Array[String] = []
	for key in characters.keys():
		output.append(str(key))
	output.sort()
	return output

func get_character(character_id: String) -> CharacterDefinition:
	return characters.get(character_id) as CharacterDefinition

func is_runtime_ready() -> bool:
	if not measured or characters.is_empty():
		return false
	for character_id in ids():
		var definition: CharacterDefinition = get_character(character_id)
		if definition == null or not definition.atlas_is_measured() or not definition.sheets_are_available():
			return false
	return true

func validation_issues() -> Array[String]:
	var issues: Array[String] = []
	if characters.is_empty():
		issues.append("Character manifest contains no definitions.")
	if not measured:
		issues.append("Character atlas geometry has not been measured yet.")
	for character_id in ids():
		var definition: CharacterDefinition = get_character(character_id)
		if definition == null:
			issues.append("Character '%s' did not parse." % character_id)
			continue
		if not definition.atlas_is_measured():
			issues.append("Character '%s' has no measured body/head cell size." % character_id)
		if not definition.sheets_are_available():
			issues.append("Character '%s' is missing one or more source sheets." % character_id)
	return issues
