extends RefCounted
class_name TrackUndoStack

var undo_states: Array[Dictionary] = []
var redo_states: Array[Dictionary] = []
var limit := 100

func clear() -> void:
	undo_states.clear()
	redo_states.clear()

func record_before(track) -> void:
	if track == null:
		return
	undo_states.append(track.to_dict())
	if undo_states.size() > limit:
		undo_states.pop_front()
	redo_states.clear()

func can_undo() -> bool:
	return not undo_states.is_empty()

func can_redo() -> bool:
	return not redo_states.is_empty()

func undo(track):
	if track == null or undo_states.is_empty():
		return track
	redo_states.append(track.to_dict())
	var state: Dictionary = undo_states.pop_back()
	var restored := TrackData.new()
	restored.from_dict(state)
	restored.dirty = true
	return restored

func redo(track):
	if track == null or redo_states.is_empty():
		return track
	undo_states.append(track.to_dict())
	var state: Dictionary = redo_states.pop_back()
	var restored := TrackData.new()
	restored.from_dict(state)
	restored.dirty = true
	return restored
