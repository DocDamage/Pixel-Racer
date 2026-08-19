extends CanvasLayer
class_name DialoguePresenter

var manager: DialogueManager = null
var atlas: PortraitAtlas = null
var dialogue_overlay: DialogueOverlay
var radio_overlay: RaceRadioOverlay
var race_mode: bool = false
var speaker_names: Dictionary = {}

func setup(dialogue_manager: DialogueManager, portrait_atlas: PortraitAtlas = null) -> void:
	manager = dialogue_manager
	atlas = portrait_atlas
	layer = 30
	_build_overlays()
	if manager != null:
		if not manager.dialogue_started.is_connected(_on_dialogue_started):
			manager.dialogue_started.connect(_on_dialogue_started)
		if not manager.dialogue_finished.is_connected(_on_dialogue_finished):
			manager.dialogue_finished.connect(_on_dialogue_finished)
		if not manager.queue_empty.is_connected(_on_queue_empty):
			manager.queue_empty.connect(_on_queue_empty)

func set_race_mode(enabled: bool) -> void:
	race_mode = enabled
	if not enabled and radio_overlay != null:
		radio_overlay.hide_entry()

func set_speaker_name(speaker_id: String, display_name: String) -> void:
	speaker_names[speaker_id] = display_name

func clear() -> void:
	if dialogue_overlay != null:
		dialogue_overlay.hide_entry()
	if radio_overlay != null:
		radio_overlay.hide_entry()

func _build_overlays() -> void:
	if dialogue_overlay == null:
		dialogue_overlay = DialogueOverlay.new()
		dialogue_overlay.name = "DialogueOverlay"
		add_child(dialogue_overlay)
		dialogue_overlay.advance_requested.connect(_on_advance_requested)
	if radio_overlay == null:
		radio_overlay = RaceRadioOverlay.new()
		radio_overlay.name = "RaceRadioOverlay"
		add_child(radio_overlay)

func _on_dialogue_started(entry: DialogueEntry) -> void:
	var speaker_name: String = str(speaker_names.get(entry.speaker_id, ""))
	var force_full: bool = bool(entry.metadata.get("force_full", false))
	var use_radio: bool = race_mode and not entry.blocking and not force_full
	if use_radio:
		dialogue_overlay.hide_entry()
		radio_overlay.show_entry(entry, atlas, speaker_name)
	else:
		radio_overlay.hide_entry()
		dialogue_overlay.show_entry(entry, atlas, speaker_name)

func _on_dialogue_finished(entry: DialogueEntry) -> void:
	if entry == null:
		return
	var force_full: bool = bool(entry.metadata.get("force_full", false))
	if race_mode and not entry.blocking and not force_full:
		radio_overlay.hide_entry()
	else:
		dialogue_overlay.hide_entry()

func _on_queue_empty() -> void:
	clear()

func _on_advance_requested() -> void:
	if manager != null:
		manager.advance()
