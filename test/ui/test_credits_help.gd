extends SceneTree
## Tests for Credits screen and Help menu
## Verifies: display, navigation, content

var _credits_script = preload("res://src/ui/credits_screen.gd")
var _help_script = preload("res://src/ui/help_screen.gd")


func _init():
	print("=== test_credits_help.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_credits_screen_creates(),
		_test_credits_has_content(),
		_test_credits_back_signal(),
		_test_credits_reset_scroll(),
		_test_help_screen_creates(),
		_test_help_has_content(),
		_test_help_back_signal(),
		_test_help_has_tabs(),
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


func _test_credits_screen_creates() -> bool:
	print("\nTest: credits_screen_creates")
	var credits: Control = _credits_script.new()

	assert(credits != null, "Credits screen should be created")
	assert(credits is Control, "Should be a Control")

	credits.free()
	print("  PASSED")
	return true


func _test_credits_has_content() -> bool:
	print("\nTest: credits_has_content")
	var credits: Control = _credits_script.new()

	var text: String = credits.get_credits_text()
	assert(text.length() > 100, "Credits should have substantial content")
	assert(text.contains("A R C O L O G Y"), "Should contain game title")
	assert(text.contains("Godot"), "Should credit Godot Engine")
	assert(text.contains("GAME DESIGN") or text.contains("PROGRAMMING"), "Should have sections")

	credits.free()
	print("  PASSED")
	return true


func _test_credits_back_signal() -> bool:
	print("\nTest: credits_back_signal")
	var credits: Control = _credits_script.new()

	var signal_received := [false]
	credits.back_pressed.connect(func(): signal_received[0] = true)

	# Emit signal
	credits.back_pressed.emit()

	assert(signal_received[0] == true, "back_pressed signal should be received")

	credits.free()
	print("  PASSED")
	return true


func _test_credits_reset_scroll() -> bool:
	print("\nTest: credits_reset_scroll")
	var credits: Control = _credits_script.new()

	# Just verify reset_scroll doesn't crash
	credits.reset_scroll()

	credits.free()
	print("  PASSED")
	return true


func _test_help_screen_creates() -> bool:
	print("\nTest: help_screen_creates")
	var help: Control = _help_script.new()

	assert(help != null, "Help screen should be created")
	assert(help is Control, "Should be a Control")

	help.free()
	print("  PASSED")
	return true


func _test_help_has_content() -> bool:
	print("\nTest: help_has_content")
	var help: Control = _help_script.new()

	var controls: String = help.get_controls_text()
	var tips: String = help.get_tips_text()

	assert(controls.length() > 50, "Controls should have content")
	assert(tips.length() > 50, "Tips should have content")
	assert(controls.contains("WASD") or controls.contains("Arrow"), "Controls should mention movement keys")
	assert(controls.contains("Camera") or controls.contains("camera"), "Controls should mention camera")
	assert(tips.contains("entrance") or tips.contains("Entrance"), "Tips should mention starting")

	help.free()
	print("  PASSED")
	return true


func _test_help_back_signal() -> bool:
	print("\nTest: help_back_signal")
	var help: Control = _help_script.new()

	var signal_received := [false]
	help.back_pressed.connect(func(): signal_received[0] = true)

	# Emit signal
	help.back_pressed.emit()

	assert(signal_received[0] == true, "back_pressed signal should be received")

	help.free()
	print("  PASSED")
	return true


func _test_help_has_tabs() -> bool:
	print("\nTest: help_has_tabs")
	var help: Control = _help_script.new()

	# The HelpScreen has a TabContainer with Controls and Tips tabs
	# Verify the content sections exist
	var controls: String = help.get_controls_text()
	var tips: String = help.get_tips_text()

	assert(controls.contains("CONTROLS"), "Should have controls section")
	assert(tips.contains("TIPS") or tips.contains("Tips"), "Should have tips section")

	help.free()
	print("  PASSED")
	return true
