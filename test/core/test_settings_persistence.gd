extends SceneTree
## Unit tests for SettingsPersistence autoload

const SETTINGS_PATH := "user://settings.json"

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	# Clean up any existing test settings file before running tests
	_cleanup_test_file()

	# Run tests
	print("Running SettingsPersistence tests...")

	# Positive tests
	_test_default_settings_exist()
	_test_get_setting_returns_default()
	_test_set_setting_updates_value()
	_test_set_setting_emits_signal()
	_test_get_all_settings_returns_copy()
	_test_set_all_settings_updates_multiple()
	_test_reset_to_defaults_restores_values()
	_test_reset_setting_restores_single()
	_test_has_setting_checks_known_keys()
	_test_is_modified_detects_changes()
	_test_is_setting_modified_checks_single()
	_test_save_creates_file()
	_test_load_reads_file()
	_test_load_merges_with_defaults()

	# Negative tests
	_test_get_setting_unknown_returns_default()
	_test_set_setting_same_value_no_signal()
	_test_load_missing_file_uses_defaults()
	_test_load_invalid_json_uses_defaults()
	_test_load_non_dict_uses_defaults()

	# Integration tests
	_test_auto_save_on_change()
	_test_keybindings_persist()

	# Clean up
	_cleanup_test_file()

	# Summary
	print("\n=== SettingsPersistence Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _cleanup_test_file() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)


func _create_persistence() -> Node:
	# Load script and create instance (not from autoload in tests)
	var script := load("res://src/core/settings_persistence.gd")
	var instance := Node.new()
	instance.set_script(script)
	# Manually initialize since _ready() won't fire outside scene tree
	instance._settings = instance.DEFAULT_SETTINGS.duplicate(true)
	instance.load_settings()
	return instance


# === POSITIVE TESTS ===

func _test_default_settings_exist() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	# Check core settings from each category exist
	assert(sp.has_setting("auto_save_interval"), "Should have game setting")
	assert(sp.has_setting("resolution"), "Should have graphics setting")
	assert(sp.has_setting("master_volume"), "Should have audio setting")
	assert(sp.has_setting("invert_scroll_zoom"), "Should have controls setting")
	assert(sp.has_setting("colorblind_mode"), "Should have accessibility setting")

	sp.free()
	_tests_passed += 1
	print("  ✓ default_settings_exist")


func _test_get_setting_returns_default() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	assert(sp.get_setting("master_volume") == 80, "Should return default value 80")
	assert(sp.get_setting("vsync") == true, "Should return default value true")
	assert(sp.get_setting("resolution") == "1920x1080", "Should return default string")

	sp.free()
	_tests_passed += 1
	print("  ✓ get_setting_returns_default")


func _test_set_setting_updates_value() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	sp.set_setting("master_volume", 50)
	assert(sp.get_setting("master_volume") == 50, "Should update to new value")

	sp.set_setting("vsync", false)
	assert(sp.get_setting("vsync") == false, "Should update boolean")

	sp.free()
	_tests_passed += 1
	print("  ✓ set_setting_updates_value")


func _test_set_setting_emits_signal() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	var emitted: Array = []
	sp.setting_changed.connect(func(key: String, value: Variant):
		emitted.append([key, value])
	)

	sp.set_setting("sfx_volume", 75)
	assert(emitted.size() == 1, "Should emit once")
	assert(emitted[0][0] == "sfx_volume", "Should emit correct key")
	assert(emitted[0][1] == 75, "Should emit correct value")

	sp.free()
	_tests_passed += 1
	print("  ✓ set_setting_emits_signal")


func _test_get_all_settings_returns_copy() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	var all: Dictionary = sp.get_all_settings()
	assert(all is Dictionary, "Should return dictionary")
	assert("master_volume" in all, "Should contain settings")

	# Modifying returned dict shouldn't affect original
	all["master_volume"] = 999
	assert(sp.get_setting("master_volume") != 999, "Should be a copy, not reference")

	sp.free()
	_tests_passed += 1
	print("  ✓ get_all_settings_returns_copy")


func _test_set_all_settings_updates_multiple() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	sp.set_all_settings({
		"master_volume": 25,
		"music_volume": 30,
		"vsync": false
	})

	assert(sp.get_setting("master_volume") == 25, "Should update master_volume")
	assert(sp.get_setting("music_volume") == 30, "Should update music_volume")
	assert(sp.get_setting("vsync") == false, "Should update vsync")

	sp.free()
	_tests_passed += 1
	print("  ✓ set_all_settings_updates_multiple")


func _test_reset_to_defaults_restores_values() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	sp.set_setting("master_volume", 10)
	sp.set_setting("vsync", false)
	sp.reset_to_defaults()

	assert(sp.get_setting("master_volume") == 80, "Should restore default")
	assert(sp.get_setting("vsync") == true, "Should restore default")

	sp.free()
	_tests_passed += 1
	print("  ✓ reset_to_defaults_restores_values")


func _test_reset_setting_restores_single() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	sp.set_setting("master_volume", 10)
	sp.set_setting("music_volume", 5)
	sp.reset_setting("master_volume")

	assert(sp.get_setting("master_volume") == 80, "Should restore single setting")
	assert(sp.get_setting("music_volume") == 5, "Should leave other settings")

	sp.free()
	_tests_passed += 1
	print("  ✓ reset_setting_restores_single")


func _test_has_setting_checks_known_keys() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	assert(sp.has_setting("master_volume") == true, "Should have known setting")
	assert(sp.has_setting("keybindings") == true, "Should have keybindings")
	assert(sp.has_setting("unknown_setting_xyz") == false, "Should not have unknown")

	sp.free()
	_tests_passed += 1
	print("  ✓ has_setting_checks_known_keys")


func _test_is_modified_detects_changes() -> void:
	_tests_run += 1
	_cleanup_test_file()  # Ensure clean slate
	var sp := _create_persistence()

	# After reset, should not be modified
	sp.reset_to_defaults()
	assert(sp.is_modified() == false, "Should not be modified after reset")

	sp.set_setting("master_volume", 50)
	assert(sp.is_modified() == true, "Should be modified after change")

	sp.reset_to_defaults()
	assert(sp.is_modified() == false, "Should not be modified after second reset")

	sp.free()
	_tests_passed += 1
	print("  ✓ is_modified_detects_changes")


func _test_is_setting_modified_checks_single() -> void:
	_tests_run += 1
	_cleanup_test_file()  # Ensure clean slate
	var sp := _create_persistence()

	# After reset, check single setting state
	sp.reset_to_defaults()
	assert(sp.is_setting_modified("master_volume") == false, "Should not be modified after reset")

	sp.set_setting("master_volume", 50)
	assert(sp.is_setting_modified("master_volume") == true, "Should be modified after change")
	# Reset music_volume to default to ensure it's not modified
	sp.reset_setting("music_volume")
	assert(sp.is_setting_modified("music_volume") == false, "Other settings should be at default")

	sp.free()
	_tests_passed += 1
	print("  ✓ is_setting_modified_checks_single")


func _test_save_creates_file() -> void:
	_tests_run += 1
	_cleanup_test_file()
	var sp := _create_persistence()

	sp.set_setting("master_volume", 42)
	var result: bool = sp.save_settings()

	assert(result == true, "Save should succeed")
	assert(FileAccess.file_exists(SETTINGS_PATH), "File should exist")

	# Verify file content
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert(content.find("master_volume") != -1, "File should contain setting")
	assert(content.find("42") != -1, "File should contain value")

	sp.free()
	_tests_passed += 1
	print("  ✓ save_creates_file")


func _test_load_reads_file() -> void:
	_tests_run += 1
	# Create a settings file
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string('{"master_volume": 33, "vsync": false}')
	file.close()

	var sp := _create_persistence()
	# _ready() will load settings

	assert(sp.get_setting("master_volume") == 33, "Should load saved value")
	assert(sp.get_setting("vsync") == false, "Should load saved boolean")

	sp.free()
	_tests_passed += 1
	print("  ✓ load_reads_file")


func _test_load_merges_with_defaults() -> void:
	_tests_run += 1
	# Create a partial settings file (missing some keys)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string('{"master_volume": 55}')
	file.close()

	var sp := _create_persistence()

	assert(sp.get_setting("master_volume") == 55, "Should load saved value")
	assert(sp.get_setting("music_volume") == 60, "Should use default for missing")
	assert(sp.get_setting("vsync") == true, "Should use default for missing")

	sp.free()
	_tests_passed += 1
	print("  ✓ load_merges_with_defaults")


# === NEGATIVE TESTS ===

func _test_get_setting_unknown_returns_default() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	assert(sp.get_setting("totally_unknown") == null, "Should return null for unknown")
	assert(sp.get_setting("totally_unknown", "fallback") == "fallback", "Should return custom default")

	sp.free()
	_tests_passed += 1
	print("  ✓ get_setting_unknown_returns_default")


func _test_set_setting_same_value_no_signal() -> void:
	_tests_run += 1
	var sp := _create_persistence()

	var emitted: int = 0
	sp.setting_changed.connect(func(_key: String, _value: Variant):
		emitted += 1
	)

	# Set to current value (80 is default)
	sp.set_setting("master_volume", 80)
	assert(emitted == 0, "Should not emit when value unchanged")

	sp.free()
	_tests_passed += 1
	print("  ✓ set_setting_same_value_no_signal")


func _test_load_missing_file_uses_defaults() -> void:
	_tests_run += 1
	_cleanup_test_file()

	var sp := _create_persistence()

	assert(sp.get_setting("master_volume") == 80, "Should use default when file missing")
	assert(sp.get_setting("vsync") == true, "Should use default when file missing")

	sp.free()
	_tests_passed += 1
	print("  ✓ load_missing_file_uses_defaults")


func _test_load_invalid_json_uses_defaults() -> void:
	_tests_run += 1
	# Create invalid JSON file
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string('{ not valid json }}}')
	file.close()

	var sp := _create_persistence()

	assert(sp.get_setting("master_volume") == 80, "Should use default on parse error")

	sp.free()
	_tests_passed += 1
	print("  ✓ load_invalid_json_uses_defaults")


func _test_load_non_dict_uses_defaults() -> void:
	_tests_run += 1
	# Create JSON array (not dict)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string('[1, 2, 3]')
	file.close()

	var sp := _create_persistence()

	assert(sp.get_setting("master_volume") == 80, "Should use default when not dict")

	sp.free()
	_tests_passed += 1
	print("  ✓ load_non_dict_uses_defaults")


# === INTEGRATION TESTS ===

func _test_auto_save_on_change() -> void:
	_tests_run += 1
	_cleanup_test_file()
	var sp := _create_persistence()

	sp.set_setting("music_volume", 99)

	# File should exist and contain new value
	assert(FileAccess.file_exists(SETTINGS_PATH), "Should auto-save")

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	assert(content.find("99") != -1, "Should contain new value")

	sp.free()
	_tests_passed += 1
	print("  ✓ auto_save_on_change")


func _test_keybindings_persist() -> void:
	_tests_run += 1
	_cleanup_test_file()
	var sp := _create_persistence()

	# Set custom keybindings
	sp.set_setting("keybindings", {
		"move_up": "W",
		"move_down": "S"
	})
	sp.save_settings()
	sp.free()

	# Load in new instance
	var sp2 := _create_persistence()
	var keybindings = sp2.get_setting("keybindings")

	assert(keybindings is Dictionary, "Should load keybindings as dict")
	assert(keybindings.get("move_up") == "W", "Should persist keybinding")
	assert(keybindings.get("move_down") == "S", "Should persist keybinding")

	sp2.free()
	_tests_passed += 1
	print("  ✓ keybindings_persist")
