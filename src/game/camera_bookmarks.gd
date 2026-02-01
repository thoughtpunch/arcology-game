class_name CameraBookmarks
extends RefCounted
## Manages camera bookmark slots for saving and recalling camera positions.
##
## Usage:
##   var bookmarks := CameraBookmarks.new()
##   bookmarks.save(0, camera_state)
##   var state := bookmarks.recall(0)
##
## Each bookmark stores: target, azimuth, elevation, distance, fov, is_orthographic

signal bookmark_saved(slot: int)
signal bookmark_recalled(slot: int)

const MAX_SLOTS: int = 9  # Slots 0-8, mapped to keys 1-9

var _bookmarks: Dictionary = {}  # int -> Dictionary


## Save a camera state to a bookmark slot (0-8).
## Invalid slots are silently ignored.
func save(slot: int, state: Dictionary) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	_bookmarks[slot] = state.duplicate()
	bookmark_saved.emit(slot)


## Recall a bookmark. Returns the state dictionary, or empty dict if slot is empty.
func recall(slot: int) -> Dictionary:
	if not _bookmarks.has(slot):
		return {}
	bookmark_recalled.emit(slot)
	return _bookmarks[slot].duplicate()


## Check if a slot has a saved bookmark.
func has(slot: int) -> bool:
	return _bookmarks.has(slot)


## Get bookmark without emitting signal (for inspection).
func get_bookmark(slot: int) -> Dictionary:
	return _bookmarks.get(slot, {}).duplicate()


## Clear a specific bookmark slot.
func clear(slot: int) -> void:
	_bookmarks.erase(slot)


## Clear all bookmark slots.
func clear_all() -> void:
	_bookmarks.clear()


## Get count of saved bookmarks.
func get_count() -> int:
	return _bookmarks.size()


## Get list of occupied slot indices.
func get_occupied_slots() -> Array[int]:
	var slots: Array[int] = []
	for key in _bookmarks.keys():
		slots.append(key as int)
	slots.sort()
	return slots


## Export all bookmarks as a dictionary (for saving).
func export_all() -> Dictionary:
	var result := {}
	for slot in _bookmarks:
		result[slot] = _bookmarks[slot].duplicate()
	return result


## Import bookmarks from a dictionary (for loading).
func import_all(data: Dictionary) -> void:
	_bookmarks.clear()
	for key in data:
		var slot := int(key)
		if slot >= 0 and slot < MAX_SLOTS:
			_bookmarks[slot] = data[key].duplicate()
