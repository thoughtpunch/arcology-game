extends SceneTree
## Unit tests for AccessibilitySettings autoload

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	print("Running AccessibilitySettings tests...")

	# Positive tests
	_test_colorblind_modes_valid()
	_test_font_sizes_valid()
	_test_speed_constants_valid()
	_test_get_colorblind_mode_default()
	_test_is_high_contrast_default()
	_test_should_reduce_motion_default()
	_test_are_screen_flash_effects_default()
	_test_get_font_size_multiplier_default()
	_test_get_max_game_speed()
	_test_get_adjusted_duration()
	_test_get_colorblind_mode_name()

	# Integration tests
	_test_settings_to_accessibility_integration()

	# Summary
	print("\n=== AccessibilitySettings Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _create_accessibility_settings() -> Node:
	var script := load("res://src/game/accessibility_settings.gd")
	var instance := Node.new()
	instance.set_script(script)
	return instance


# === POSITIVE TESTS ===

func _test_colorblind_modes_valid() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	var modes: Dictionary = as_node.COLORBLIND_MODES
	assert("Off" in modes, "Should have Off mode")
	assert("Protanopia" in modes, "Should have Protanopia")
	assert("Deuteranopia" in modes, "Should have Deuteranopia")
	assert("Tritanopia" in modes, "Should have Tritanopia")

	assert(modes["Off"] == 0, "Off should be 0")
	assert(modes["Protanopia"] == 1, "Protanopia should be 1")

	as_node.free()
	_tests_passed += 1
	print("  ✓ colorblind_modes_valid")


func _test_font_sizes_valid() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	var sizes: Dictionary = as_node.FONT_SIZES
	assert("Small" in sizes, "Should have Small")
	assert("Medium" in sizes, "Should have Medium")
	assert("Large" in sizes, "Should have Large")
	assert("Extra Large" in sizes, "Should have Extra Large")

	assert(sizes["Small"] == 0.9, "Small should be 0.9")
	assert(sizes["Medium"] == 1.0, "Medium should be 1.0")
	assert(sizes["Large"] == 1.2, "Large should be 1.2")
	assert(sizes["Extra Large"] == 1.5, "Extra Large should be 1.5")

	as_node.free()
	_tests_passed += 1
	print("  ✓ font_sizes_valid")


func _test_speed_constants_valid() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.SLOWER_SPEED_MAX == 2, "Slower max should be 2")
	assert(as_node.NORMAL_SPEED_MAX == 3, "Normal max should be 3")

	as_node.free()
	_tests_passed += 1
	print("  ✓ speed_constants_valid")


func _test_get_colorblind_mode_default() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.get_colorblind_mode() == 0, "Default should be 0 (off)")

	as_node._colorblind_mode = 2
	assert(as_node.get_colorblind_mode() == 2, "Should return updated value")

	as_node.free()
	_tests_passed += 1
	print("  ✓ get_colorblind_mode_default")


func _test_is_high_contrast_default() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.is_high_contrast_enabled() == false, "Default should be false")

	as_node._high_contrast_ui = true
	assert(as_node.is_high_contrast_enabled() == true, "Should return updated value")

	as_node.free()
	_tests_passed += 1
	print("  ✓ is_high_contrast_default")


func _test_should_reduce_motion_default() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.should_reduce_motion() == false, "Default should be false")

	as_node._reduce_motion = true
	assert(as_node.should_reduce_motion() == true, "Should return updated value")
	assert(as_node.should_instant_tween() == true, "Should instant tween when reduce motion")

	as_node.free()
	_tests_passed += 1
	print("  ✓ should_reduce_motion_default")


func _test_are_screen_flash_effects_default() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.are_screen_flash_effects_enabled() == true, "Default should be true")

	as_node._screen_flash_effects = false
	assert(as_node.are_screen_flash_effects_enabled() == false, "Should return updated value")

	as_node.free()
	_tests_passed += 1
	print("  ✓ are_screen_flash_effects_default")


func _test_get_font_size_multiplier_default() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.get_font_size_multiplier() == 1.0, "Default should be 1.0")

	as_node._font_size_multiplier = 1.5
	assert(as_node.get_font_size_multiplier() == 1.5, "Should return updated value")

	as_node.free()
	_tests_passed += 1
	print("  ✓ get_font_size_multiplier_default")


func _test_get_max_game_speed() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	# Default (slower_speed_max = false)
	assert(as_node.get_max_game_speed() == 3, "Default max should be 3")

	# With slower max enabled
	as_node._slower_speed_max = true
	assert(as_node.get_max_game_speed() == 2, "Slower max should be 2")

	as_node.free()
	_tests_passed += 1
	print("  ✓ get_max_game_speed")


func _test_get_adjusted_duration() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	# Normal (no reduce motion)
	assert(as_node.get_adjusted_duration(0.5) == 0.5, "Should return base duration")

	# With reduce motion
	as_node._reduce_motion = true
	assert(as_node.get_adjusted_duration(0.5) == 0.0, "Should return 0 for instant")

	as_node.free()
	_tests_passed += 1
	print("  ✓ get_adjusted_duration")


func _test_get_colorblind_mode_name() -> void:
	_tests_run += 1
	var as_node := _create_accessibility_settings()

	assert(as_node.get_colorblind_mode_name() == "Off", "Default should be 'Off'")

	as_node._colorblind_mode = 1
	assert(as_node.get_colorblind_mode_name() == "Protanopia", "Should return 'Protanopia'")

	as_node._colorblind_mode = 2
	assert(as_node.get_colorblind_mode_name() == "Deuteranopia", "Should return 'Deuteranopia'")

	as_node.free()
	_tests_passed += 1
	print("  ✓ get_colorblind_mode_name")


# === INTEGRATION TESTS ===

func _test_settings_to_accessibility_integration() -> void:
	_tests_run += 1

	# Create settings persistence
	var sp_script := load("res://src/game/settings_persistence.gd")
	var sp := Node.new()
	sp.set_script(sp_script)
	sp._settings = sp.DEFAULT_SETTINGS.duplicate(true)
	sp.load_settings()

	var as_node := _create_accessibility_settings()

	# Test that accessibility settings keys exist in SettingsPersistence
	assert(sp.has_setting("colorblind_mode"), "colorblind_mode should exist")
	assert(sp.has_setting("high_contrast_ui"), "high_contrast_ui should exist")
	assert(sp.has_setting("reduce_motion"), "reduce_motion should exist")
	assert(sp.has_setting("screen_flash_effects"), "screen_flash_effects should exist")
	assert(sp.has_setting("font_size"), "font_size should exist")
	assert(sp.has_setting("dyslexia_font"), "dyslexia_font should exist")
	assert(sp.has_setting("extended_tooltips"), "extended_tooltips should exist")
	assert(sp.has_setting("slower_game_speed_max"), "slower_game_speed_max should exist")

	sp.free()
	as_node.free()
	_tests_passed += 1
	print("  ✓ settings_to_accessibility_integration")
