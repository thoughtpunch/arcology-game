extends SceneTree
## Unit tests for MainMenu class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== MainMenu Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_has_title()
	_test_has_tagline()
	_test_has_all_buttons()
	_test_buttons_are_accessible()

	# Layout tests
	_test_full_screen_layout()
	_test_has_background()
	_test_has_footer()
	_test_version_and_copyright()

	# Button signal tests
	_test_new_game_button_emits_signal()
	_test_load_game_button_emits_signal()
	_test_settings_button_emits_signal()
	_test_credits_button_emits_signal()
	_test_quit_button_emits_signal()

	# Continue button tests
	_test_continue_button_hidden_by_default()
	_test_continue_button_shows_when_saves_exist()

	# Negative tests
	_test_invalid_button_returns_null()
	_test_continue_hidden_without_saves()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var menu := MainMenu.new()
	_assert(menu != null, "MainMenu should create without error")
	menu.queue_free()


func _test_has_title() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var title: Label = menu.get_node_or_null("CenterContainer/ContentBox/TitleSection/TitleLabel")
	_assert(title != null, "Should have title label")
	_assert(title.text == "A R C O L O G Y", "Title should be 'A R C O L O G Y'")
	menu.queue_free()


func _test_has_tagline() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var tagline: Label = menu.get_node_or_null("CenterContainer/ContentBox/TitleSection/TaglineLabel")
	_assert(tagline != null, "Should have tagline label")
	_assert(tagline.text == "Build. Nurture. Flourish.", "Tagline should be 'Build. Nurture. Flourish.'")
	menu.queue_free()


func _test_has_all_buttons() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var button_container = menu.get_node_or_null("CenterContainer/ContentBox/ButtonContainer")
	_assert(button_container != null, "Should have button container")

	var expected_buttons := ["NewGameButton", "ContinueButton", "LoadGameButton", "SettingsButton", "CreditsButton", "QuitButton"]
	for btn_name in expected_buttons:
		var btn: Button = button_container.get_node_or_null(btn_name)
		_assert(btn != null, "Should have %s" % btn_name)

	menu.queue_free()


func _test_buttons_are_accessible() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.get_button("NewGameButton") != null, "get_button should find NewGameButton")
	_assert(menu.get_button("LoadGameButton") != null, "get_button should find LoadGameButton")
	_assert(menu.get_button("SettingsButton") != null, "get_button should find SettingsButton")
	menu.queue_free()


func _test_full_screen_layout() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.anchor_left == 0.0, "Should anchor left to 0")
	_assert(menu.anchor_right == 1.0, "Should anchor right to 1")
	_assert(menu.anchor_top == 0.0, "Should anchor top to 0")
	_assert(menu.anchor_bottom == 1.0, "Should anchor bottom to 1")
	menu.queue_free()


func _test_has_background() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var bg: ColorRect = menu.get_node_or_null("Background")
	_assert(bg != null, "Should have background ColorRect")
	_assert(bg.color == MainMenu.COLOR_BACKGROUND, "Background should use correct color")
	menu.queue_free()


func _test_has_footer() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var footer: HBoxContainer = menu.get_node_or_null("Footer")
	_assert(footer != null, "Should have footer container")
	menu.queue_free()


func _test_version_and_copyright() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var version: Label = menu.get_node_or_null("Footer/VersionLabel")
	var copyright: Label = menu.get_node_or_null("Footer/CopyrightLabel")
	_assert(version != null, "Should have version label")
	_assert(copyright != null, "Should have copyright label")
	_assert(version.text.begins_with("v"), "Version should start with 'v'")
	_assert(copyright.text.contains("Arcology"), "Copyright should mention Arcology")
	menu.queue_free()


func _test_new_game_button_emits_signal() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	# Verify signal exists and button is connected
	_assert(menu.has_signal("new_game_pressed"), "Should have new_game_pressed signal")
	var btn := menu.get_button("NewGameButton")
	_assert(btn.pressed.is_connected(menu._on_new_game_pressed), "NewGameButton should be connected")
	menu.queue_free()


func _test_load_game_button_emits_signal() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("load_game_pressed"), "Should have load_game_pressed signal")
	var btn := menu.get_button("LoadGameButton")
	_assert(btn.pressed.is_connected(menu._on_load_pressed), "LoadGameButton should be connected")
	menu.queue_free()


func _test_settings_button_emits_signal() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("settings_pressed"), "Should have settings_pressed signal")
	var btn := menu.get_button("SettingsButton")
	_assert(btn.pressed.is_connected(menu._on_settings_pressed), "SettingsButton should be connected")
	menu.queue_free()


func _test_credits_button_emits_signal() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("credits_pressed"), "Should have credits_pressed signal")
	var btn := menu.get_button("CreditsButton")
	_assert(btn.pressed.is_connected(menu._on_credits_pressed), "CreditsButton should be connected")
	menu.queue_free()


func _test_quit_button_emits_signal() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	_assert(menu.has_signal("quit_pressed"), "Should have quit_pressed signal")
	var btn := menu.get_button("QuitButton")
	_assert(btn.pressed.is_connected(menu._on_quit_pressed), "QuitButton should be connected")
	menu.queue_free()


func _test_continue_button_hidden_by_default() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	# Before check_for_saves is called
	_assert(menu.is_continue_visible() == false, "Continue button should be hidden by default")
	menu.queue_free()


func _test_continue_button_shows_when_saves_exist() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	menu.set_has_saves(true)
	_assert(menu.is_continue_visible() == true, "Continue button should show when saves exist")
	menu.queue_free()


func _test_invalid_button_returns_null() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	var btn := menu.get_button("NonExistentButton")
	_assert(btn == null, "get_button should return null for non-existent button")
	menu.queue_free()


func _test_continue_hidden_without_saves() -> void:
	var menu := MainMenu.new()
	menu._setup_layout()
	menu.set_has_saves(false)
	_assert(menu.is_continue_visible() == false, "Continue button should be hidden without saves")
	menu.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
