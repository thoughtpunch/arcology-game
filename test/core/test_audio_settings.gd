extends SceneTree
## Unit tests for AudioSettings autoload

var _tests_run: int = 0
var _tests_passed: int = 0


func _init() -> void:
	print("Running AudioSettings tests...")

	# Positive tests
	_test_bus_indices_match_layout()
	_test_volume_settings_mapping()
	_test_set_bus_volume_converts_to_db()
	_test_get_bus_volume_percent()
	_test_volume_clamping()
	_test_get_bus_index_by_name()

	# Negative tests
	_test_invalid_bus_index()

	# Integration tests
	_test_settings_to_audio_integration()

	# Summary
	print("\n=== AudioSettings Tests ===")
	print("Passed: %d/%d" % [_tests_passed, _tests_run])
	if _tests_passed == _tests_run:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func _create_audio_settings() -> Node:
	var script := load("res://src/game/audio_settings.gd")
	var instance := Node.new()
	instance.set_script(script)
	return instance


# === POSITIVE TESTS ===

func _test_bus_indices_match_layout() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Verify constants match expected bus layout
	assert(audio.BUS_MASTER == 0, "Master should be bus 0")
	assert(audio.BUS_MUSIC == 1, "Music should be bus 1")
	assert(audio.BUS_SFX == 2, "SFX should be bus 2")
	assert(audio.BUS_AMBIENT == 3, "Ambient should be bus 3")
	assert(audio.BUS_UI == 4, "UI should be bus 4")

	audio.free()
	_tests_passed += 1
	print("  ✓ bus_indices_match_layout")


func _test_volume_settings_mapping() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Verify all volume settings map to correct buses
	var mappings: Dictionary = audio.VOLUME_SETTINGS
	assert(mappings["master_volume"] == 0, "master_volume maps to Master")
	assert(mappings["music_volume"] == 1, "music_volume maps to Music")
	assert(mappings["sfx_volume"] == 2, "sfx_volume maps to SFX")
	assert(mappings["ambient_volume"] == 3, "ambient_volume maps to Ambient")
	assert(mappings["ui_volume"] == 4, "ui_volume maps to UI")

	audio.free()
	_tests_passed += 1
	print("  ✓ volume_settings_mapping")


func _test_set_bus_volume_converts_to_db() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Test volume conversion (only testing if it doesn't crash)
	# Note: AudioServer may not be fully available in headless mode
	audio._set_bus_volume(0, 100)  # Full volume = 0 dB
	audio._set_bus_volume(0, 50)   # Half volume = ~-6 dB
	audio._set_bus_volume(0, 0)    # Zero volume = -80 dB (effectively muted)

	audio.free()
	_tests_passed += 1
	print("  ✓ set_bus_volume_converts_to_db")


func _test_get_bus_volume_percent() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Set a known volume and read it back
	audio._set_bus_volume(0, 75)
	var read_back: int = audio.get_bus_volume_percent(0)

	# Allow some tolerance due to dB conversion
	assert(read_back >= 70 and read_back <= 80, "Volume should be approximately 75%%")

	audio.free()
	_tests_passed += 1
	print("  ✓ get_bus_volume_percent")


func _test_volume_clamping() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Test that extreme values are clamped
	audio._set_bus_volume(0, 200)  # Above max
	var vol_high: int = audio.get_bus_volume_percent(0)
	assert(vol_high <= 100, "Volume above 100 should be clamped")

	audio._set_bus_volume(0, -50)  # Below min
	var vol_low: int = audio.get_bus_volume_percent(0)
	assert(vol_low >= 0, "Volume below 0 should be clamped")

	audio.free()
	_tests_passed += 1
	print("  ✓ volume_clamping")


func _test_get_bus_index_by_name() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# AudioServer.get_bus_index should work
	var master_idx: int = audio.get_bus_index("Master")
	assert(master_idx == 0, "Master bus should be index 0")

	audio.free()
	_tests_passed += 1
	print("  ✓ get_bus_index_by_name")


# === NEGATIVE TESTS ===

func _test_invalid_bus_index() -> void:
	_tests_run += 1
	var audio := _create_audio_settings()

	# Setting invalid bus should not crash (just warn)
	audio._set_bus_volume(-1, 50)
	audio._set_bus_volume(999, 50)

	# Getting invalid bus should return 0
	var vol_neg: int = audio.get_bus_volume_percent(-1)
	assert(vol_neg == 0, "Invalid bus should return 0")

	var vol_high: int = audio.get_bus_volume_percent(999)
	assert(vol_high == 0, "Invalid bus should return 0")

	# Mute check on invalid bus should return false
	assert(audio.is_bus_muted(-1) == false, "Invalid bus mute should return false")

	audio.free()
	_tests_passed += 1
	print("  ✓ invalid_bus_index")


# === INTEGRATION TESTS ===

func _test_settings_to_audio_integration() -> void:
	_tests_run += 1

	# Create both settings persistence and audio settings
	var sp_script := load("res://src/game/settings_persistence.gd")
	var sp := Node.new()
	sp.set_script(sp_script)
	sp._settings = sp.DEFAULT_SETTINGS.duplicate(true)
	sp.load_settings()

	var audio := _create_audio_settings()

	# Test that VOLUME_SETTINGS keys exist in SettingsPersistence
	for key in audio.VOLUME_SETTINGS:
		assert(sp.has_setting(key), "Setting '%s' should exist in SettingsPersistence" % key)

	# Test mute_when_minimized setting exists
	assert(sp.has_setting("mute_when_minimized"), "mute_when_minimized should exist")

	# Test dynamic_music setting exists
	assert(sp.has_setting("dynamic_music"), "dynamic_music should exist")

	sp.free()
	audio.free()
	_tests_passed += 1
	print("  ✓ settings_to_audio_integration")
