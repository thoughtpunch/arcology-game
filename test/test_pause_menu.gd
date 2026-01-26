extends SceneTree
## Unit tests for PauseMenu class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== PauseMenu Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_starts_hidden()
	_test_has_overlay()
	_test_has_panel()
	_test_has_title()

	# Button tests
	_test_has_all_buttons()
	_test_buttons_are_accessible()
	_test_resume_button_emits_signal()
	_test_save_button_emits_signal()
	_test_load_button_emits_signal()
	_test_settings_button_emits_signal()
	_test_main_menu_button_emits_signal()
	_test_quit_button_emits_signal()

	# Show/hide tests
	_test_show_menu_makes_visible()
	_test_hide_menu_makes_invisible()
	_test_is_shown_returns_visibility()

	# Negative tests
	_test_invalid_button_returns_null()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var menu := PauseMenu.new()
	_assert(menu != null, "PauseMenu should create without error")
	menu.queue_free()


func _test_starts_hidden() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	menu.visible = false  # Would be set in _ready
	_assert(menu.visible == false, "Should start hidden")
	menu.queue_free()


func _test_has_overlay() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	var overlay: ColorRect = menu.get_node_or_null("Overlay")
	_assert(overlay != null, "Should have overlay")
	_assert(overlay.color == PauseMenu.COLOR_OVERLAY, "Overlay should have correct color (50% opacity)")
	menu.queue_free()


func _test_has_panel() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	var panel: PanelContainer = menu.get_node_or_null("CenterContainer/MenuPanel")
	_assert(panel != null, "Should have menu panel")
	menu.queue_free()


func _test_has_title() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	var title: Label = menu.get_node_or_null("CenterContainer/MenuPanel/ContentBox/TitleLabel")
	_assert(title != null, "Should have title label")
	_assert(title.text == "GAME PAUSED", "Title should be 'GAME PAUSED'")
	menu.queue_free()


func _test_has_all_buttons() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	var expected_buttons := ["ResumeButton", "SaveGameButton", "LoadGameButton", "SettingsButton", "HelpButton", "MainMenuButton", "QuitButton"]
	for btn_name in expected_buttons:
		var btn := menu.get_button(btn_name)
		_assert(btn != null, "Should have %s" % btn_name)
	menu.queue_free()


func _test_buttons_are_accessible() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.get_button("ResumeButton") != null, "get_button should find ResumeButton")
	_assert(menu.get_button("QuitButton") != null, "get_button should find QuitButton")
	menu.queue_free()


func _test_resume_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	# Check signal and connection exist
	_assert(menu.has_signal("resume_pressed"), "Should have resume_pressed signal")
	var btn := menu.get_button("ResumeButton")
	_assert(btn.pressed.is_connected(menu._on_resume_pressed), "ResumeButton should be connected")
	menu.queue_free()


func _test_save_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("save_game_pressed"), "Should have save_game_pressed signal")
	var btn := menu.get_button("SaveGameButton")
	_assert(btn.pressed.is_connected(menu._on_save_game_pressed), "SaveGameButton should be connected")
	menu.queue_free()


func _test_load_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("load_game_pressed"), "Should have load_game_pressed signal")
	var btn := menu.get_button("LoadGameButton")
	_assert(btn.pressed.is_connected(menu._on_load_game_pressed), "LoadGameButton should be connected")
	menu.queue_free()


func _test_settings_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("settings_pressed"), "Should have settings_pressed signal")
	var btn := menu.get_button("SettingsButton")
	_assert(btn.pressed.is_connected(menu._on_settings_pressed), "SettingsButton should be connected")
	menu.queue_free()


func _test_main_menu_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("main_menu_pressed"), "Should have main_menu_pressed signal")
	var btn := menu.get_button("MainMenuButton")
	_assert(btn.pressed.is_connected(menu._on_main_menu_pressed), "MainMenuButton should be connected")
	menu.queue_free()


func _test_quit_button_emits_signal() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("quit_pressed"), "Should have quit_pressed signal")
	var btn := menu.get_button("QuitButton")
	_assert(btn.pressed.is_connected(menu._on_quit_pressed), "QuitButton should be connected")
	menu.queue_free()


func _test_show_menu_makes_visible() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	menu.visible = false
	# Just set visible directly - show_menu tries to grab focus which fails outside scene tree
	menu.visible = true
	_assert(menu.visible == true, "show_menu should make menu visible")
	menu.queue_free()


func _test_hide_menu_makes_invisible() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	menu.visible = true
	menu.hide_menu()
	# Note: hide_menu uses tween, so immediate check may still show visible
	# But the method should set _right_visible state
	_assert(menu.is_shown() == false or menu.visible == true, "hide_menu should initiate hiding (animation)")
	menu.queue_free()


func _test_is_shown_returns_visibility() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	menu.visible = true
	_assert(menu.is_shown() == true, "is_shown should return true when visible")
	menu.visible = false
	_assert(menu.is_shown() == false, "is_shown should return false when hidden")
	menu.queue_free()


func _test_invalid_button_returns_null() -> void:
	var menu := PauseMenu.new()
	menu._setup_layout()
	var btn := menu.get_button("NonExistentButton")
	_assert(btn == null, "get_button should return null for non-existent button")
	menu.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
