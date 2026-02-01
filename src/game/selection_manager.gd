## Manages block selection state: single select, add-to-selection, remove-from-selection.
##
## Selection modes:
##   - Click (LMB): Replace selection with clicked block
##   - Shift+Click: Add clicked block to selection
##   - Ctrl+Click: Remove clicked block from selection (toggle)
##   - Alt+Click: Select-through (ignore topmost, select block behind)
##   - Click empty: Clear selection
##
## Loaded via preload — no class_name (same pattern as other phase0 scripts).

signal selection_changed(selected_ids: Array[int])
signal block_selected(block_id: int)
signal block_deselected(block_id: int)

var _selected_ids: Dictionary = {}  # block_id -> true (set semantics)


func get_selected_ids() -> Array[int]:
	## Returns the currently selected block IDs as a sorted array.
	var ids: Array[int] = []
	for id in _selected_ids:
		ids.append(id)
	ids.sort()
	return ids


func get_selected_count() -> int:
	return _selected_ids.size()


func is_selected(block_id: int) -> bool:
	return _selected_ids.has(block_id)


func select(block_id: int) -> void:
	## Replace selection with a single block.
	var changed := false
	var old_ids := _selected_ids.duplicate()

	# Deselect everything except the target
	for id in old_ids:
		if id != block_id:
			_selected_ids.erase(id)
			block_deselected.emit(id)
			changed = true

	# Select the target if not already selected
	if not _selected_ids.has(block_id):
		_selected_ids[block_id] = true
		block_selected.emit(block_id)
		changed = true

	if changed:
		selection_changed.emit(get_selected_ids())


func add_to_selection(block_id: int) -> void:
	## Add a block to the current selection (Shift+click).
	if not _selected_ids.has(block_id):
		_selected_ids[block_id] = true
		block_selected.emit(block_id)
		selection_changed.emit(get_selected_ids())


func remove_from_selection(block_id: int) -> void:
	## Remove a block from the current selection (Ctrl+click).
	if _selected_ids.has(block_id):
		_selected_ids.erase(block_id)
		block_deselected.emit(block_id)
		selection_changed.emit(get_selected_ids())


func toggle_selection(block_id: int) -> void:
	## Toggle a block in/out of selection.
	if _selected_ids.has(block_id):
		remove_from_selection(block_id)
	else:
		add_to_selection(block_id)


func clear() -> void:
	## Clear all selection.
	if _selected_ids.is_empty():
		return
	var old_ids := _selected_ids.duplicate()
	_selected_ids.clear()
	for id in old_ids:
		block_deselected.emit(id)
	selection_changed.emit(get_selected_ids())


func select_multiple(block_ids: Array[int]) -> void:
	## Replace selection with multiple blocks at once.
	var old_ids := _selected_ids.duplicate()
	_selected_ids.clear()
	for id in old_ids:
		if not block_ids.has(id):
			block_deselected.emit(id)
	for id in block_ids:
		_selected_ids[id] = true
		if not old_ids.has(id):
			block_selected.emit(id)
	selection_changed.emit(get_selected_ids())


func on_block_removed(block_id: int) -> void:
	## Called when a block is removed from the world. Silently removes from selection.
	if _selected_ids.has(block_id):
		_selected_ids.erase(block_id)
		block_deselected.emit(block_id)
		selection_changed.emit(get_selected_ids())
