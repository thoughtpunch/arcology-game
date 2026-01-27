extends SceneTree
## Integration test: Settings persist across restarts
## Tests that settings survive a simulated application restart

const SETTINGS_PATH := "user://settings.json"
var _persistence_script = preload("res://src/core/settings_persistence.gd")


func _init():
	print("=== test_settings_persist_restart.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_settings_survive_restart(),
		_test_modified_settings_survive_restart(),
		_test_all_categories_survive_restart(),
		_test_keybindings_survive_restart(),
		_test_partial_settings_merged_on_restart(),
		_test_reset_to_defaults_persists(),
	]

	for result in results:
		if result:
			passed += 1
		else:
			failed += 1

	# Clean up test file
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])

	if failed > 0:
		quit(1)
	else:
		quit(0)


func _create_persistence() -> Node:
	var instance := Node.new()
	instance.set_script(_persistence_script)
	instance._settings = instance.DEFAULT_SETTINGS.duplicate(true)
	instance.load_settings()
	return instance


func _cleanup_settings_file() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)


func _test_settings_survive_restart() -> bool:
	print("\nTest: settings_survive_restart")
	_cleanup_settings_file()

	# Session 1: Change and save settings
	var session1: Node = _create_persistence()
	session1.set_setting("master_volume", 42)
	session1.set_setting("vsync", false)
	session1.save_settings()
	session1.free()

	# Session 2: Load and verify
	var session2: Node = _create_persistence()
	assert(session2.get_setting("master_volume") == 42, "Volume should survive restart")
	assert(session2.get_setting("vsync") == false, "VSync should survive restart")
	session2.free()

	print("  PASSED")
	return true


func _test_modified_settings_survive_restart() -> bool:
	print("\nTest: modified_settings_survive_restart")
	_cleanup_settings_file()

	# Session 1: Modify multiple settings
	var session1: Node = _create_persistence()
	session1.set_setting("music_volume", 25)
	session1.set_setting("sfx_volume", 90)
	session1.set_setting("scroll_speed", 75)
	session1.set_setting("show_fps", true)
	session1.save_settings()
	session1.free()

	# Session 2: Verify all modifications persisted
	var session2: Node = _create_persistence()
	assert(session2.get_setting("music_volume") == 25, "Music volume should persist")
	assert(session2.get_setting("sfx_volume") == 90, "SFX volume should persist")
	assert(session2.get_setting("scroll_speed") == 75, "Scroll speed should persist")
	assert(session2.get_setting("show_fps") == true, "Show FPS should persist")
	session2.free()

	print("  PASSED")
	return true


func _test_all_categories_survive_restart() -> bool:
	print("\nTest: all_categories_survive_restart")
	_cleanup_settings_file()

	# Session 1: Change settings from each category
	var session1: Node = _create_persistence()
	# Game
	session1.set_setting("auto_save_interval", 5)
	session1.set_setting("edge_scrolling", false)
	# Graphics
	session1.set_setting("resolution", "2560x1440")
	session1.set_setting("display_mode", "Windowed")
	# Audio
	session1.set_setting("master_volume", 50)
	session1.set_setting("mute_when_minimized", false)
	# Controls
	session1.set_setting("invert_scroll_zoom", true)
	session1.set_setting("mouse_sensitivity", 75)
	# Accessibility
	session1.set_setting("colorblind_mode", "Deuteranopia")
	session1.set_setting("reduce_motion", true)
	session1.save_settings()
	session1.free()

	# Session 2: Verify all categories
	var session2: Node = _create_persistence()
	# Game
	assert(session2.get_setting("auto_save_interval") == 5, "Game setting persists")
	assert(session2.get_setting("edge_scrolling") == false, "Game setting persists")
	# Graphics
	assert(session2.get_setting("resolution") == "2560x1440", "Graphics setting persists")
	assert(session2.get_setting("display_mode") == "Windowed", "Graphics setting persists")
	# Audio
	assert(session2.get_setting("master_volume") == 50, "Audio setting persists")
	assert(session2.get_setting("mute_when_minimized") == false, "Audio setting persists")
	# Controls
	assert(session2.get_setting("invert_scroll_zoom") == true, "Controls setting persists")
	assert(session2.get_setting("mouse_sensitivity") == 75, "Controls setting persists")
	# Accessibility
	assert(session2.get_setting("colorblind_mode") == "Deuteranopia", "Accessibility setting persists")
	assert(session2.get_setting("reduce_motion") == true, "Accessibility setting persists")
	session2.free()

	print("  PASSED")
	return true


func _test_keybindings_survive_restart() -> bool:
	print("\nTest: keybindings_survive_restart")
	_cleanup_settings_file()

	# Session 1: Set custom keybindings
	var session1: Node = _create_persistence()
	session1.set_setting("keybindings", {
		"camera_up": "W",
		"camera_down": "S",
		"camera_left": "A",
		"camera_right": "D",
		"zoom_in": "Q",
		"zoom_out": "E"
	})
	session1.save_settings()
	session1.free()

	# Session 2: Verify keybindings
	var session2: Node = _create_persistence()
	var keybindings: Dictionary = session2.get_setting("keybindings")
	assert(keybindings is Dictionary, "Keybindings should be dict")
	assert(keybindings.get("camera_up") == "W", "Keybinding W persists")
	assert(keybindings.get("camera_down") == "S", "Keybinding S persists")
	assert(keybindings.get("camera_left") == "A", "Keybinding A persists")
	assert(keybindings.get("camera_right") == "D", "Keybinding D persists")
	assert(keybindings.get("zoom_in") == "Q", "Keybinding Q persists")
	assert(keybindings.get("zoom_out") == "E", "Keybinding E persists")
	session2.free()

	print("  PASSED")
	return true


func _test_partial_settings_merged_on_restart() -> bool:
	print("\nTest: partial_settings_merged_on_restart")
	_cleanup_settings_file()

	# Session 1: Only change one setting
	var session1: Node = _create_persistence()
	session1.set_setting("master_volume", 65)
	session1.save_settings()
	session1.free()

	# Session 2: Verify changed setting and defaults for unchanged
	var session2: Node = _create_persistence()
	assert(session2.get_setting("master_volume") == 65, "Changed setting persists")
	# These should still be defaults
	assert(session2.get_setting("music_volume") == 60, "Default music_volume")
	assert(session2.get_setting("vsync") == true, "Default vsync")
	assert(session2.get_setting("resolution") == "1920x1080", "Default resolution")
	session2.free()

	print("  PASSED")
	return true


func _test_reset_to_defaults_persists() -> bool:
	print("\nTest: reset_to_defaults_persists")
	_cleanup_settings_file()

	# Session 1: Change settings then reset
	var session1: Node = _create_persistence()
	session1.set_setting("master_volume", 10)
	session1.set_setting("vsync", false)
	session1.reset_to_defaults()
	session1.save_settings()
	session1.free()

	# Session 2: Verify defaults are loaded
	var session2: Node = _create_persistence()
	assert(session2.get_setting("master_volume") == 80, "Default volume after reset")
	assert(session2.get_setting("vsync") == true, "Default vsync after reset")
	session2.free()

	print("  PASSED")
	return true
