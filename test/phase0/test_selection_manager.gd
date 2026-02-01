## GdUnit4 test suite for Phase 0 SelectionManager.
## Tests selection, deselection, toggle, multi-select, and signal behavior.
class_name TestSelectionManager
extends GdUnitTestSuite

const SelectionManagerScript = preload("res://src/phase0/selection_manager.gd")

var _mgr: RefCounted
var _selected_signals: Array[int]
var _deselected_signals: Array[int]
var _change_count: int


func before_test() -> void:
	_mgr = auto_free(SelectionManagerScript.new())
	_selected_signals = []
	_deselected_signals = []
	_change_count = 0
	_mgr.block_selected.connect(func(id: int): _selected_signals.append(id))
	_mgr.block_deselected.connect(func(id: int): _deselected_signals.append(id))
	_mgr.selection_changed.connect(func(_ids: Array[int]): _change_count += 1)


# --- Positive: Basic selection ---


func test_initially_empty() -> void:
	assert_int(_mgr.get_selected_count()).is_equal(0)
	assert_array(_mgr.get_selected_ids()).is_empty()


func test_select_single_block() -> void:
	_mgr.select(1)
	assert_int(_mgr.get_selected_count()).is_equal(1)
	assert_bool(_mgr.is_selected(1)).is_true()
	assert_array(_mgr.get_selected_ids()).contains_exactly([1])


func test_select_replaces_previous() -> void:
	_mgr.select(1)
	_mgr.select(2)
	assert_int(_mgr.get_selected_count()).is_equal(1)
	assert_bool(_mgr.is_selected(1)).is_false()
	assert_bool(_mgr.is_selected(2)).is_true()


func test_select_same_block_no_change() -> void:
	_mgr.select(1)
	_change_count = 0
	_mgr.select(1)
	# Selecting the same block again should not emit change
	assert_int(_change_count).is_equal(0)


# --- Positive: Add to selection ---


func test_add_to_selection() -> void:
	_mgr.select(1)
	_mgr.add_to_selection(2)
	assert_int(_mgr.get_selected_count()).is_equal(2)
	assert_bool(_mgr.is_selected(1)).is_true()
	assert_bool(_mgr.is_selected(2)).is_true()


func test_add_to_selection_multiple() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	_mgr.add_to_selection(3)
	assert_int(_mgr.get_selected_count()).is_equal(3)
	assert_array(_mgr.get_selected_ids()).contains_exactly([1, 2, 3])


func test_add_already_selected_no_change() -> void:
	_mgr.add_to_selection(1)
	_change_count = 0
	_mgr.add_to_selection(1)
	assert_int(_change_count).is_equal(0)
	assert_int(_mgr.get_selected_count()).is_equal(1)


# --- Positive: Remove from selection ---


func test_remove_from_selection() -> void:
	_mgr.select(1)
	_mgr.add_to_selection(2)
	_mgr.remove_from_selection(1)
	assert_int(_mgr.get_selected_count()).is_equal(1)
	assert_bool(_mgr.is_selected(1)).is_false()
	assert_bool(_mgr.is_selected(2)).is_true()


func test_remove_last_block_empties_selection() -> void:
	_mgr.select(1)
	_mgr.remove_from_selection(1)
	assert_int(_mgr.get_selected_count()).is_equal(0)
	assert_array(_mgr.get_selected_ids()).is_empty()


# --- Positive: Toggle ---


func test_toggle_adds_unselected() -> void:
	_mgr.toggle_selection(1)
	assert_bool(_mgr.is_selected(1)).is_true()


func test_toggle_removes_selected() -> void:
	_mgr.select(1)
	_mgr.toggle_selection(1)
	assert_bool(_mgr.is_selected(1)).is_false()


func test_toggle_preserves_other_selection() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	_mgr.toggle_selection(1)
	assert_bool(_mgr.is_selected(1)).is_false()
	assert_bool(_mgr.is_selected(2)).is_true()


# --- Positive: Clear ---


func test_clear_empties_selection() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	_mgr.add_to_selection(3)
	_mgr.clear()
	assert_int(_mgr.get_selected_count()).is_equal(0)
	assert_array(_mgr.get_selected_ids()).is_empty()


func test_clear_empty_no_signal() -> void:
	_change_count = 0
	_mgr.clear()
	assert_int(_change_count).is_equal(0)


# --- Positive: Select multiple ---


func test_select_multiple() -> void:
	var ids: Array[int] = [1, 3, 5]
	_mgr.select_multiple(ids)
	assert_int(_mgr.get_selected_count()).is_equal(3)
	assert_bool(_mgr.is_selected(1)).is_true()
	assert_bool(_mgr.is_selected(3)).is_true()
	assert_bool(_mgr.is_selected(5)).is_true()


func test_select_multiple_replaces_existing() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	var new_ids: Array[int] = [3, 4]
	_mgr.select_multiple(new_ids)
	assert_int(_mgr.get_selected_count()).is_equal(2)
	assert_bool(_mgr.is_selected(1)).is_false()
	assert_bool(_mgr.is_selected(2)).is_false()
	assert_bool(_mgr.is_selected(3)).is_true()
	assert_bool(_mgr.is_selected(4)).is_true()


# --- Positive: Block removal callback ---


func test_on_block_removed_deselects() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	_mgr.on_block_removed(1)
	assert_int(_mgr.get_selected_count()).is_equal(1)
	assert_bool(_mgr.is_selected(1)).is_false()
	assert_bool(_mgr.is_selected(2)).is_true()


func test_on_block_removed_last_empties() -> void:
	_mgr.select(1)
	_mgr.on_block_removed(1)
	assert_int(_mgr.get_selected_count()).is_equal(0)


# --- Positive: Signal emissions ---


func test_select_emits_selected_signal() -> void:
	_mgr.select(5)
	assert_array(_selected_signals).contains_exactly([5])


func test_select_emits_deselected_for_previous() -> void:
	_mgr.select(1)
	_deselected_signals.clear()
	_mgr.select(2)
	assert_array(_deselected_signals).contains_exactly([1])


func test_add_emits_selected_signal() -> void:
	_selected_signals.clear()
	_mgr.add_to_selection(3)
	assert_array(_selected_signals).contains_exactly([3])


func test_remove_emits_deselected_signal() -> void:
	_mgr.select(1)
	_deselected_signals.clear()
	_mgr.remove_from_selection(1)
	assert_array(_deselected_signals).contains_exactly([1])


func test_clear_emits_deselected_for_all() -> void:
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(2)
	_deselected_signals.clear()
	_mgr.clear()
	assert_array(_deselected_signals).contains_exactly_in_any_order([1, 2])


func test_selection_changed_fires_on_select() -> void:
	_change_count = 0
	_mgr.select(1)
	assert_int(_change_count).is_equal(1)


func test_selection_changed_fires_on_clear() -> void:
	_mgr.add_to_selection(1)
	_change_count = 0
	_mgr.clear()
	assert_int(_change_count).is_equal(1)


# --- Negative: Edge cases ---


func test_is_selected_returns_false_for_unknown() -> void:
	assert_bool(_mgr.is_selected(999)).is_false()


func test_remove_unselected_no_change() -> void:
	_mgr.select(1)
	_change_count = 0
	_mgr.remove_from_selection(999)
	assert_int(_change_count).is_equal(0)
	assert_int(_mgr.get_selected_count()).is_equal(1)


func test_on_block_removed_unselected_no_change() -> void:
	_mgr.select(1)
	_change_count = 0
	_mgr.on_block_removed(999)
	assert_int(_change_count).is_equal(0)
	assert_int(_mgr.get_selected_count()).is_equal(1)


func test_get_selected_ids_returns_sorted() -> void:
	_mgr.add_to_selection(5)
	_mgr.add_to_selection(1)
	_mgr.add_to_selection(3)
	var ids: Array[int] = _mgr.get_selected_ids()
	assert_array(ids).contains_exactly([1, 3, 5])


func test_select_multiple_empty_clears() -> void:
	_mgr.add_to_selection(1)
	var empty: Array[int] = []
	_mgr.select_multiple(empty)
	assert_int(_mgr.get_selected_count()).is_equal(0)
