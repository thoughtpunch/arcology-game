extends SceneTree
## Unit tests for GameSettings autoload

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	print("Running GameSettings tests...")

	# Positive tests
	_test_auto_save_intervals_valid()
	_test_get_scroll_speed_multiplier()
	_test_is_edge_scrolling_enabled()
	_test_should_show_news_popups()
	_test_should_play_notification_sound()
	_test_should_auto_pause_emergencies()
	_test_is_window_focused_default()

	# Integration tests
	_test_settings_to_game_integration()

	# Summary
	print("\n=== GameSettings Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _create_game_settings() -> Node:
	var script := load("res://src/game/game_settings.gd")
	var instance := Node.new()
	instance.set_script(script)
	return instance


# === POSITIVE TESTS ===

func _test_auto_save_intervals_valid() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Verify all interval presets are valid
	var intervals: Dictionary = gs.AUTO_SAVE_INTERVALS
	assert("5 minutes" in intervals, "Should have 5 minute option")
	assert("10 minutes" in intervals, "Should have 10 minute option")
	assert("15 minutes" in intervals, "Should have 15 minute option")
	assert("30 minutes" in intervals, "Should have 30 minute option")
	assert("Disabled" in intervals, "Should have Disabled option")

	# Verify values
	assert(intervals["10 minutes"] == 10, "10 minutes should be 10")
	assert(intervals["Disabled"] == 0, "Disabled should be 0")

	gs.free()
	_tests_passed += 1
	print("  ✓ auto_save_intervals_valid")


func _test_get_scroll_speed_multiplier() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Without SettingsPersistence, should return default 0.5
	var multiplier: float = gs.get_scroll_speed_multiplier()
	assert(multiplier >= 0.0 and multiplier <= 1.0, "Multiplier should be between 0 and 1")

	gs.free()
	_tests_passed += 1
	print("  ✓ get_scroll_speed_multiplier")


func _test_is_edge_scrolling_enabled() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Without SettingsPersistence, should return default true
	var enabled: bool = gs.is_edge_scrolling_enabled()
	assert(enabled == true, "Edge scrolling should default to true")

	gs.free()
	_tests_passed += 1
	print("  ✓ is_edge_scrolling_enabled")


func _test_should_show_news_popups() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Default should be true
	assert(gs.should_show_news_popups() == true, "News popups should default to true")

	# Set via internal property
	gs._show_news_popups = false
	assert(gs.should_show_news_popups() == false, "Should return updated value")

	gs.free()
	_tests_passed += 1
	print("  ✓ should_show_news_popups")


func _test_should_play_notification_sound() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Default should be true
	assert(gs.should_play_notification_sound() == true, "Notification sound should default to true")

	# Set via internal property
	gs._notification_sound_enabled = false
	assert(gs.should_play_notification_sound() == false, "Should return updated value")

	gs.free()
	_tests_passed += 1
	print("  ✓ should_play_notification_sound")


func _test_should_auto_pause_emergencies() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Default should be true
	assert(gs.should_auto_pause_emergencies() == true, "Auto-pause should default to true")

	# Set via internal property
	gs._auto_pause_emergencies = false
	assert(gs.should_auto_pause_emergencies() == false, "Should return updated value")

	gs.free()
	_tests_passed += 1
	print("  ✓ should_auto_pause_emergencies")


func _test_is_window_focused_default() -> void:
	_tests_run += 1
	var gs := _create_game_settings()

	# Default should be true
	assert(gs.is_window_focused() == true, "Window should default to focused")

	gs.free()
	_tests_passed += 1
	print("  ✓ is_window_focused_default")


# === INTEGRATION TESTS ===

func _test_settings_to_game_integration() -> void:
	_tests_run += 1

	# Create settings persistence
	var sp_script := load("res://src/game/settings_persistence.gd")
	var sp := Node.new()
	sp.set_script(sp_script)
	sp._settings = sp.DEFAULT_SETTINGS.duplicate(true)
	sp.load_settings()

	var gs := _create_game_settings()

	# Test that game tab settings keys exist in SettingsPersistence
	assert(sp.has_setting("auto_save_interval"), "auto_save_interval should exist")
	assert(sp.has_setting("edge_scrolling"), "edge_scrolling should exist")
	assert(sp.has_setting("scroll_speed"), "scroll_speed should exist")
	assert(sp.has_setting("pause_on_lost_focus"), "pause_on_lost_focus should exist")
	assert(sp.has_setting("tutorial_hints"), "tutorial_hints should exist")
	assert(sp.has_setting("show_news_popups"), "show_news_popups should exist")
	assert(sp.has_setting("auto_pause_emergencies"), "auto_pause_emergencies should exist")
	assert(sp.has_setting("notification_sound"), "notification_sound should exist")

	sp.free()
	gs.free()
	_tests_passed += 1
	print("  ✓ settings_to_game_integration")
