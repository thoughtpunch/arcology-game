extends SceneTree
## Unit tests for ControlsSettings autoload

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	print("Running ControlsSettings tests...")

	# Positive tests
	_test_default_keybindings_valid()
	_test_is_scroll_zoom_inverted_default()
	_test_get_mouse_sensitivity_default()
	_test_get_remappable_actions()
	_test_event_to_string_key()
	_test_event_to_string_mouse()
	_test_create_events_from_binding()

	# Negative tests
	_test_check_conflict_no_conflict()

	# Integration tests
	_test_settings_to_controls_integration()

	# Summary
	print("\n=== ControlsSettings Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _create_controls_settings() -> Node:
	var script := load("res://src/core/controls_settings.gd")
	var instance := Node.new()
	instance.set_script(script)
	return instance


# === POSITIVE TESTS ===

func _test_default_keybindings_valid() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	# Verify all default keybindings exist
	var defaults: Dictionary = cs.DEFAULT_KEYBINDINGS
	assert("move_up" in defaults, "Should have move_up")
	assert("move_down" in defaults, "Should have move_down")
	assert("move_left" in defaults, "Should have move_left")
	assert("move_right" in defaults, "Should have move_right")
	assert("zoom_in" in defaults, "Should have zoom_in")
	assert("zoom_out" in defaults, "Should have zoom_out")

	# Verify move_up has expected keys
	var move_up: Dictionary = defaults["move_up"]
	assert("key" in move_up, "move_up should have key")
	assert(move_up["key"] == KEY_W, "move_up key should be W")

	cs.free()
	_tests_passed += 1
	print("  ✓ default_keybindings_valid")


func _test_is_scroll_zoom_inverted_default() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	# Default should be false
	assert(cs.is_scroll_zoom_inverted() == false, "Should default to non-inverted")

	# Set via internal property
	cs._invert_scroll_zoom = true
	assert(cs.is_scroll_zoom_inverted() == true, "Should return updated value")

	cs.free()
	_tests_passed += 1
	print("  ✓ is_scroll_zoom_inverted_default")


func _test_get_mouse_sensitivity_default() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	# Default should be 0.5 (50%)
	var sens: float = cs.get_mouse_sensitivity()
	assert(sens == 0.5, "Default sensitivity should be 0.5, got %f" % sens)

	# Set via internal property
	cs._mouse_sensitivity = 1.0
	assert(cs.get_mouse_sensitivity() == 1.0, "Should return updated value")

	cs.free()
	_tests_passed += 1
	print("  ✓ get_mouse_sensitivity_default")


func _test_get_remappable_actions() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	var actions: Array[String] = cs.get_remappable_actions()
	assert(actions.size() == 6, "Should have 6 remappable actions")
	assert("move_up" in actions, "Should include move_up")
	assert("zoom_in" in actions, "Should include zoom_in")

	cs.free()
	_tests_passed += 1
	print("  ✓ get_remappable_actions")


func _test_event_to_string_key() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	var key_event := InputEventKey.new()
	key_event.keycode = KEY_W
	var result: String = cs.event_to_string(key_event)
	assert(result == "W", "Should return 'W' for KEY_W, got '%s'" % result)

	var space_event := InputEventKey.new()
	space_event.keycode = KEY_SPACE
	var space_result: String = cs.event_to_string(space_event)
	assert(space_result == "Space", "Should return 'Space' for KEY_SPACE, got '%s'" % space_result)

	cs.free()
	_tests_passed += 1
	print("  ✓ event_to_string_key")


func _test_event_to_string_mouse() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	var result: String = cs.event_to_string(wheel_up)
	assert(result == "Mouse Wheel Up", "Should return 'Mouse Wheel Up', got '%s'" % result)

	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	var left_result: String = cs.event_to_string(left_click)
	assert(left_result == "Mouse Left", "Should return 'Mouse Left', got '%s'" % left_result)

	cs.free()
	_tests_passed += 1
	print("  ✓ event_to_string_mouse")


func _test_create_events_from_binding() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	# Test key binding
	var binding := {"key": KEY_W, "alt_key": KEY_UP}
	var events: Array[InputEvent] = cs._create_events_from_binding(binding)

	assert(events.size() == 2, "Should create 2 events")
	assert(events[0] is InputEventKey, "First should be key event")
	assert((events[0] as InputEventKey).keycode == KEY_W, "First should be W")
	assert((events[1] as InputEventKey).keycode == KEY_UP, "Second should be Up")

	# Test with mouse
	var mouse_binding := {"key": KEY_EQUAL, "mouse": MOUSE_BUTTON_WHEEL_UP}
	var mouse_events: Array[InputEvent] = cs._create_events_from_binding(mouse_binding)
	assert(mouse_events.size() == 2, "Should create 2 events for key+mouse")

	cs.free()
	_tests_passed += 1
	print("  ✓ create_events_from_binding")


# === NEGATIVE TESTS ===

func _test_check_conflict_no_conflict() -> void:
	_tests_run += 1
	var cs := _create_controls_settings()

	# Create an event that's unlikely to conflict
	var rare_key := InputEventKey.new()
	rare_key.keycode = KEY_F12

	var conflict: String = cs.check_conflict("move_up", rare_key)
	assert(conflict == "", "F12 should not conflict with anything")

	cs.free()
	_tests_passed += 1
	print("  ✓ check_conflict_no_conflict")


# === INTEGRATION TESTS ===

func _test_settings_to_controls_integration() -> void:
	_tests_run += 1

	# Create settings persistence
	var sp_script := load("res://src/core/settings_persistence.gd")
	var sp := Node.new()
	sp.set_script(sp_script)
	sp._settings = sp.DEFAULT_SETTINGS.duplicate(true)
	sp.load_settings()

	var cs := _create_controls_settings()

	# Test that controls settings keys exist in SettingsPersistence
	assert(sp.has_setting("invert_scroll_zoom"), "invert_scroll_zoom should exist")
	assert(sp.has_setting("mouse_sensitivity"), "mouse_sensitivity should exist")
	assert(sp.has_setting("keybindings"), "keybindings should exist")

	# Test keybindings is a dictionary
	var keybindings = sp.get_setting("keybindings")
	assert(keybindings is Dictionary, "keybindings should be a Dictionary")

	sp.free()
	cs.free()
	_tests_passed += 1
	print("  ✓ settings_to_controls_integration")
