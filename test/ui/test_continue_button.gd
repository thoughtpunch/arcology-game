extends SceneTree
## Tests for Continue button functionality
## Verifies: save detection, tooltip with save info, most recent save tracking

var _main_menu_script = preload("res://src/ui/main_menu.gd")


func _init():
	print("=== test_continue_button.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_continue_hidden_without_saves(),
		_test_continue_visible_with_saves(),
		_test_most_recent_save_tracked(),
		_test_tooltip_format(),
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


func _test_continue_hidden_without_saves() -> bool:
	print("\nTest: continue_hidden_without_saves")
	var menu: Control = _main_menu_script.new()

	# Initially should be hidden (no saves by default)
	# Note: _check_for_saves is called deferred, so we set state manually
	menu.set_has_saves(false)

	assert(menu.is_continue_visible() == false, "Continue should be hidden without saves")

	menu.free()
	print("  PASSED")
	return true


func _test_continue_visible_with_saves() -> bool:
	print("\nTest: continue_visible_with_saves")
	var menu: Control = _main_menu_script.new()

	# Need to call _setup_layout to create the button
	menu._setup_layout()

	# Set that saves exist
	menu.set_has_saves(true)

	assert(menu.is_continue_visible() == true, "Continue should be visible with saves")

	menu.free()
	print("  PASSED")
	return true


func _test_most_recent_save_tracked() -> bool:
	print("\nTest: most_recent_save_tracked")
	var menu: Control = _main_menu_script.new()

	# Initially no save tracked
	assert(menu.get_most_recent_save().is_empty(), "Should start with no save tracked")

	# After setting save data manually via _most_recent_save
	menu._most_recent_save = {
		"name": "Test Save",
		"timestamp": 1706300000.0,
		"path": "user://saves/test.save"
	}

	var save_data: Dictionary = menu.get_most_recent_save()
	assert(save_data.name == "Test Save", "Should track save name")
	assert(save_data.timestamp == 1706300000.0, "Should track timestamp")
	assert(save_data.path == "user://saves/test.save", "Should track path")

	menu.free()
	print("  PASSED")
	return true


func _test_tooltip_format() -> bool:
	print("\nTest: tooltip_format")
	var menu: Control = _main_menu_script.new()

	# Need to call _setup_layout to create the button
	menu._setup_layout()

	# Set up save data
	menu._most_recent_save = {
		"name": "My Arcology",
		"timestamp": 1706313600.0,  # 2024-01-27 00:00:00 UTC
	}

	# Call tooltip update
	menu._update_continue_tooltip()

	# Check tooltip was set
	var tooltip: String = menu._continue_button.tooltip_text
	assert(tooltip.contains("My Arcology"), "Tooltip should contain save name")
	assert(tooltip.contains("Continue:"), "Tooltip should have Continue: prefix")
	assert(tooltip.contains("Saved:"), "Tooltip should have Saved: line")

	menu.free()
	print("  PASSED")
	return true
