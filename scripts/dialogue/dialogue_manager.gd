extends Node
class_name DialogueManager

signal dialogue_started(entry: DialogueEntry)
signal dialogue_finished(entry: DialogueEntry)
signal queue_empty

var condition_context: Dictionary = {}
var _pending: Array[DialogueEntry] = []
var _active: DialogueEntry = null
var _remaining: float = 0.0
var _seen_once: Dictionary = {}
var _last_shown_msec: Dictionary = {}

func _process(delta: float) -> void:
	if _active == null:
		_start_next()
		return
	if _active.blocking:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_finish_active()

func queue_entry(entry: DialogueEntry) -> bool:
	if entry == null or entry.text.strip_edges().is_empty():
		return false
	if not _condition_passes(entry.condition):
		return false
	var entry_key: String = _entry_key(entry)
	if entry.once_only and _seen_once.has(entry_key):
		return false
	if entry.cooldown > 0.0 and _last_shown_msec.has(entry_key):
		var elapsed_msec: int = Time.get_ticks_msec() - int(_last_shown_msec[entry_key])
		if float(elapsed_msec) < entry.cooldown * 1000.0:
			return false
	var insert_index: int = _pending.size()
	for index in range(_pending.size()):
		if entry.priority > _pending[index].priority:
			insert_index = index
			break
	_pending.insert(insert_index, entry)
	if _active == null:
		_start_next()
	return true

func queue_dict(data: Dictionary) -> bool:
	return queue_entry(DialogueEntry.from_dict(data))

func advance() -> void:
	if _active == null:
		_start_next()
		return
	_finish_active()

func dismiss_non_blocking() -> void:
	if _active != null and not _active.blocking:
		_finish_active()

func clear() -> void:
	_pending.clear()
	_active = null
	_remaining = 0.0
	queue_empty.emit()

func active_entry() -> DialogueEntry:
	return _active

func has_active_dialogue() -> bool:
	return _active != null

func set_condition(key: String, value: bool) -> void:
	condition_context[key] = value

func serialize_state() -> Dictionary:
	return {"seen_once": _seen_once.keys()}

func load_state(data: Dictionary) -> void:
	_seen_once.clear()
	var seen_values: Variant = data.get("seen_once", [])
	if seen_values is Array:
		for value in seen_values:
			_seen_once[str(value)] = true

func _start_next() -> void:
	while not _pending.is_empty():
		var candidate: DialogueEntry = _pending.pop_front()
		if candidate == null or not _condition_passes(candidate.condition):
			continue
		var entry_key: String = _entry_key(candidate)
		if candidate.once_only and _seen_once.has(entry_key):
			continue
		_active = candidate
		_remaining = candidate.duration
		_last_shown_msec[entry_key] = Time.get_ticks_msec()
		if candidate.once_only:
			_seen_once[entry_key] = true
		dialogue_started.emit(candidate)
		return
	queue_empty.emit()

func _finish_active() -> void:
	if _active == null:
		return
	var completed: DialogueEntry = _active
	_active = null
	_remaining = 0.0
	dialogue_finished.emit(completed)
	_start_next()

func _condition_passes(condition: String) -> bool:
	if condition.is_empty():
		return true
	if condition.begins_with("!"):
		var negated_key: String = condition.substr(1)
		return not bool(condition_context.get(negated_key, false))
	return bool(condition_context.get(condition, false))

func _entry_key(entry: DialogueEntry) -> String:
	if not entry.id.is_empty():
		return entry.id
	return "%s:%s:%s" % [entry.speaker_id, entry.event, entry.text]
