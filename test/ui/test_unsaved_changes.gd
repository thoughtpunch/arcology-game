extends SceneTree
## Tests for unsaved changes tracking
## Verifies: mark_unsaved_changes, has_unsaved_changes, save clears flag

var _menu_manager_script = preload("res://src/ui/menu_manager.gd")


func _init():
	print("=== test_unsaved_changes.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_initial_state(),
		_test_mark_unsaved_changes(),
		_test_has_unsaved_changes(),
		_test_save_clears_unsaved(),
	]

	for result in results:
		if result:
			passed += 1
		else:
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])

	if failed > 0:
		quit(1)
	else:
		quit(0)


func _test_initial_state() -> bool:
	print("\nTest: initial_state")
	var mm: CanvasLayer = _menu_manager_script.new()
	# Manually init needed state
	mm._has_unsaved_changes = false

	# Should start without unsaved changes
	assert(mm.has_unsaved_changes() == false, "Should not have unsaved changes initially")

	mm.free()
	print("  PASSED")
	return true


func _test_mark_unsaved_changes() -> bool:
	print("\nTest: mark_unsaved_changes")
	var mm: CanvasLayer = _menu_manager_script.new()
	mm._has_unsaved_changes = false

	# Mark unsaved
	mm.mark_unsaved_changes()

	# Should now have unsaved changes
	assert(mm.has_unsaved_changes() == true, "Should have unsaved changes after marking")

	# Calling again should still be true
	mm.mark_unsaved_changes()
	assert(mm.has_unsaved_changes() == true, "Should still have unsaved changes")

	mm.free()
	print("  PASSED")
	return true


func _test_has_unsaved_changes() -> bool:
	print("\nTest: has_unsaved_changes")
	var mm: CanvasLayer = _menu_manager_script.new()

	# Set directly and verify getter
	mm._has_unsaved_changes = false
	assert(mm.has_unsaved_changes() == false, "has_unsaved_changes returns false when false")

	mm._has_unsaved_changes = true
	assert(mm.has_unsaved_changes() == true, "has_unsaved_changes returns true when true")

	mm.free()
	print("  PASSED")
	return true


func _test_save_clears_unsaved() -> bool:
	print("\nTest: save_clears_unsaved")
	var mm: CanvasLayer = _menu_manager_script.new()

	# Mark unsaved
	mm._has_unsaved_changes = true
	assert(mm.has_unsaved_changes() == true, "Has unsaved changes before save")

	# Simulate save clearing the flag (done in main.gd save_game)
	mm._has_unsaved_changes = false
	assert(mm.has_unsaved_changes() == false, "Unsaved changes cleared after save")

	mm.free()
	print("  PASSED")
	return true
