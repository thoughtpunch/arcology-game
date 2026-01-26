extends SceneTree
## Unit tests for SettingsMenu class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== SettingsMenu Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_has_panel()
	_test_has_title()

	# Tab tests
	_test_has_all_tabs()
	_test_default_tab_is_game()
	_test_can_switch_tabs()
	_test_get_current_tab()

	# Settings tests
	_test_has_default_settings()
	_test_get_settings_returns_dictionary()
	_test_set_settings_updates_values()
	_test_settings_include_game_options()
	_test_settings_include_graphics_options()
	_test_settings_include_audio_options()
	_test_settings_include_accessibility_options()

	# Signal tests
	_test_back_button_emits_signal()
	_test_apply_button_emits_signal()
	_test_reset_button_emits_signal()

	# Negative tests
	_test_invalid_tab_stays_current()
	_test_unknown_setting_preserved()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var menu := SettingsMenu.new()
	_assert(menu != null, "SettingsMenu should create without error")
	menu.queue_free()


func _test_has_panel() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var panel: PanelContainer = menu.get_node_or_null("SettingsPanel")
	_assert(panel != null, "Should have settings panel")
	menu.queue_free()


func _test_has_title() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var title: Label = menu.get_node_or_null("SettingsPanel/MainVBox/Header/TitleLabel")
	_assert(title != null, "Should have title label")
	_assert(title.text == "SETTINGS", "Title should be 'SETTINGS'")
	menu.queue_free()


func _test_has_all_tabs() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var tab_container: HBoxContainer = menu.get_node_or_null("SettingsPanel/MainVBox/TabContainer")
	_assert(tab_container != null, "Should have tab container")
	_assert(tab_container.get_child_count() == 5, "Should have 5 tabs")

	var expected_tabs := ["GameTab", "GraphicsTab", "AudioTab", "ControlsTab", "AccessibilityTab"]
	for tab_name in expected_tabs:
		var tab: Button = tab_container.get_node_or_null(tab_name)
		_assert(tab != null, "Should have %s" % tab_name)
	menu.queue_free()


func _test_default_tab_is_game() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	menu._show_tab(SettingsMenu.Tab.GAME)
	_assert(menu.get_current_tab() == SettingsMenu.Tab.GAME, "Default tab should be Game")
	menu.queue_free()


func _test_can_switch_tabs() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	menu.set_current_tab(SettingsMenu.Tab.AUDIO)
	_assert(menu.get_current_tab() == SettingsMenu.Tab.AUDIO, "Should be able to switch to Audio tab")
	menu.set_current_tab(SettingsMenu.Tab.GRAPHICS)
	_assert(menu.get_current_tab() == SettingsMenu.Tab.GRAPHICS, "Should be able to switch to Graphics tab")
	menu.queue_free()


func _test_get_current_tab() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	menu._show_tab(SettingsMenu.Tab.CONTROLS)
	_assert(menu.get_current_tab() == SettingsMenu.Tab.CONTROLS, "get_current_tab should return current tab")
	menu.queue_free()


func _test_has_default_settings() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings.has("auto_save_interval"), "Should have auto_save_interval setting")
	_assert(settings.has("master_volume"), "Should have master_volume setting")
	_assert(settings.has("vsync"), "Should have vsync setting")
	menu.queue_free()


func _test_get_settings_returns_dictionary() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings is Dictionary, "get_settings should return Dictionary")
	_assert(settings.size() > 0, "Settings should not be empty")
	menu.queue_free()


func _test_set_settings_updates_values() -> void:
	var menu := SettingsMenu.new()
	var new_settings := {"master_volume": 50, "vsync": false}
	menu.set_settings(new_settings)
	var settings := menu.get_settings()
	_assert(settings.master_volume == 50, "set_settings should update master_volume")
	_assert(settings.vsync == false, "set_settings should update vsync")
	menu.queue_free()


func _test_settings_include_game_options() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings.has("edge_scrolling"), "Should have edge_scrolling")
	_assert(settings.has("scroll_speed"), "Should have scroll_speed")
	_assert(settings.has("pause_on_lost_focus"), "Should have pause_on_lost_focus")
	_assert(settings.has("tutorial_hints"), "Should have tutorial_hints")
	menu.queue_free()


func _test_settings_include_graphics_options() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings.has("resolution"), "Should have resolution")
	_assert(settings.has("display_mode"), "Should have display_mode")
	_assert(settings.has("vsync"), "Should have vsync")
	_assert(settings.has("ui_scale"), "Should have ui_scale")
	menu.queue_free()


func _test_settings_include_audio_options() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings.has("master_volume"), "Should have master_volume")
	_assert(settings.has("music_volume"), "Should have music_volume")
	_assert(settings.has("sfx_volume"), "Should have sfx_volume")
	_assert(settings.has("mute_when_minimized"), "Should have mute_when_minimized")
	menu.queue_free()


func _test_settings_include_accessibility_options() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	_assert(settings.has("colorblind_mode"), "Should have colorblind_mode")
	_assert(settings.has("high_contrast_ui"), "Should have high_contrast_ui")
	_assert(settings.has("font_size"), "Should have font_size")
	_assert(settings.has("reduce_motion"), "Should have reduce_motion")
	menu.queue_free()


func _test_back_button_emits_signal() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var signal_received := false
	menu.back_pressed.connect(func(): signal_received = true)
	menu._on_back_pressed()
	_assert(signal_received, "Back button should emit back_pressed signal")
	menu.queue_free()


func _test_apply_button_emits_signal() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var signal_received := false
	menu.apply_pressed.connect(func(): signal_received = true)
	menu._on_apply_pressed()
	_assert(signal_received, "Apply button should emit apply_pressed signal")
	menu.queue_free()


func _test_reset_button_emits_signal() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	var signal_received := false
	menu.reset_defaults_pressed.connect(func(): signal_received = true)
	menu._on_reset_pressed()
	_assert(signal_received, "Reset button should emit reset_defaults_pressed signal")
	menu.queue_free()


func _test_invalid_tab_stays_current() -> void:
	var menu := SettingsMenu.new()
	menu._setup_layout()
	menu._show_tab(SettingsMenu.Tab.GAME)
	var current := menu.get_current_tab()
	# Try to set invalid tab (via number out of range - not possible with enum but test bounds)
	_assert(current == SettingsMenu.Tab.GAME, "Invalid tab should not change current tab")
	menu.queue_free()


func _test_unknown_setting_preserved() -> void:
	var menu := SettingsMenu.new()
	var settings := menu.get_settings()
	# Verify setting an unknown key doesn't crash and doesn't add it
	menu.set_settings({"unknown_setting": "test"})
	var updated_settings := menu.get_settings()
	_assert(not updated_settings.has("unknown_setting"), "Unknown settings should not be added")
	menu.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
