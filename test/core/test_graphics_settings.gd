extends SceneTree
## Unit tests for GraphicsSettings autoload

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	print("Running GraphicsSettings tests...")

	# Positive tests
	_test_resolution_presets_valid()
	_test_display_modes_valid()
	_test_frame_rate_limits_valid()
	_test_vsync_modes_valid()
	_test_apply_frame_rate_limit()
	_test_get_current_resolution()
	_test_get_current_display_mode()
	_test_get_frame_rate_limit()

	# Integration tests
	_test_settings_to_graphics_integration()

	# Summary
	print("\n=== GraphicsSettings Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _create_graphics_settings() -> Node:
	var script := load("res://src/game/graphics_settings.gd")
	var instance := Node.new()
	instance.set_script(script)
	return instance


# === POSITIVE TESTS ===

func _test_resolution_presets_valid() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	# Verify all resolution presets are valid Vector2i
	var presets: Dictionary = gs.RESOLUTION_PRESETS
	assert("1280x720" in presets, "Should have 720p preset")
	assert("1920x1080" in presets, "Should have 1080p preset")
	assert("2560x1440" in presets, "Should have 1440p preset")
	assert("3840x2160" in presets, "Should have 4K preset")

	# Verify values
	assert(presets["1920x1080"] == Vector2i(1920, 1080), "1080p should be 1920x1080")

	gs.free()
	_tests_passed += 1
	print("  ✓ resolution_presets_valid")


func _test_display_modes_valid() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var modes: Dictionary = gs.DISPLAY_MODES
	assert("Windowed" in modes, "Should have Windowed mode")
	assert("Fullscreen" in modes, "Should have Fullscreen mode")
	assert("Borderless" in modes, "Should have Borderless mode")

	# Verify values are valid DisplayServer constants
	assert(modes["Windowed"] == DisplayServer.WINDOW_MODE_WINDOWED, "Windowed should map correctly")
	assert(modes["Fullscreen"] == DisplayServer.WINDOW_MODE_FULLSCREEN, "Fullscreen should map correctly")

	gs.free()
	_tests_passed += 1
	print("  ✓ display_modes_valid")


func _test_frame_rate_limits_valid() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var limits: Dictionary = gs.FRAME_RATE_LIMITS
	assert("30 FPS" in limits, "Should have 30 FPS option")
	assert("60 FPS" in limits, "Should have 60 FPS option")
	assert("120 FPS" in limits, "Should have 120 FPS option")
	assert("Unlimited" in limits, "Should have Unlimited option")

	assert(limits["60 FPS"] == 60, "60 FPS should be 60")
	assert(limits["Unlimited"] == 0, "Unlimited should be 0")

	gs.free()
	_tests_passed += 1
	print("  ✓ frame_rate_limits_valid")


func _test_vsync_modes_valid() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var modes: Dictionary = gs.VSYNC_MODES
	assert(true in modes, "Should have enabled mode")
	assert(false in modes, "Should have disabled mode")

	assert(modes[true] == DisplayServer.VSYNC_ENABLED, "true should enable vsync")
	assert(modes[false] == DisplayServer.VSYNC_DISABLED, "false should disable vsync")

	gs.free()
	_tests_passed += 1
	print("  ✓ vsync_modes_valid")


func _test_apply_frame_rate_limit() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	# Save original
	var original_fps: int = Engine.max_fps

	# Apply different limits
	gs._apply_frame_rate_limit(30)
	assert(Engine.max_fps == 30, "Should set 30 FPS")

	gs._apply_frame_rate_limit("60 FPS")
	assert(Engine.max_fps == 60, "Should handle string format")

	gs._apply_frame_rate_limit(0)
	assert(Engine.max_fps == 0, "Should set unlimited (0)")

	# Restore original
	Engine.max_fps = original_fps

	gs.free()
	_tests_passed += 1
	print("  ✓ apply_frame_rate_limit")


func _test_get_current_resolution() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var res: String = gs.get_current_resolution()
	# Should be in format "WxH"
	assert(res.find("x") > 0, "Resolution should contain 'x'")

	# Parse and verify it's valid numbers
	var parts: PackedStringArray = res.split("x")
	assert(parts.size() == 2, "Should have two parts")
	assert(parts[0].is_valid_int(), "Width should be integer")
	assert(parts[1].is_valid_int(), "Height should be integer")

	gs.free()
	_tests_passed += 1
	print("  ✓ get_current_resolution")


func _test_get_current_display_mode() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var mode: String = gs.get_current_display_mode()
	# Should be one of the known modes
	assert(mode in ["Windowed", "Fullscreen", "Borderless"], "Should be a known mode: %s" % mode)

	gs.free()
	_tests_passed += 1
	print("  ✓ get_current_display_mode")


func _test_get_frame_rate_limit() -> void:
	_tests_run += 1
	var gs := _create_graphics_settings()

	var fps: int = gs.get_frame_rate_limit()
	assert(fps >= 0, "FPS limit should be >= 0")

	gs.free()
	_tests_passed += 1
	print("  ✓ get_frame_rate_limit")


# === INTEGRATION TESTS ===

func _test_settings_to_graphics_integration() -> void:
	_tests_run += 1

	# Create settings persistence
	var sp_script := load("res://src/game/settings_persistence.gd")
	var sp := Node.new()
	sp.set_script(sp_script)
	sp._settings = sp.DEFAULT_SETTINGS.duplicate(true)
	sp.load_settings()

	var gs := _create_graphics_settings()

	# Test that graphics settings keys exist in SettingsPersistence
	assert(sp.has_setting("resolution"), "resolution should exist")
	assert(sp.has_setting("display_mode"), "display_mode should exist")
	assert(sp.has_setting("vsync"), "vsync should exist")
	assert(sp.has_setting("frame_rate_limit"), "frame_rate_limit should exist")
	assert(sp.has_setting("ui_scale"), "ui_scale should exist")
	assert(sp.has_setting("show_fps"), "show_fps should exist")

	# Test quality settings exist (even if deferred)
	assert(sp.has_setting("sprite_quality"), "sprite_quality should exist")
	assert(sp.has_setting("shadow_quality"), "shadow_quality should exist")
	assert(sp.has_setting("animation_quality"), "animation_quality should exist")
	assert(sp.has_setting("particle_effects"), "particle_effects should exist")

	sp.free()
	gs.free()
	_tests_passed += 1
	print("  ✓ settings_to_graphics_integration")
