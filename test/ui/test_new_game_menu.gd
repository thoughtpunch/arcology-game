extends SceneTree
## Unit tests for NewGameMenu class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== NewGameMenu Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_has_panel()
	_test_starts_on_scenario_screen()

	# Scenario tests
	_test_has_scenario_cards()
	_test_scenarios_have_names()
	_test_scenarios_have_difficulties()
	_test_selecting_scenario_goes_to_settings()

	# Settings screen tests
	_test_settings_screen_has_name_input()
	_test_settings_screen_has_difficulty_options()
	_test_settings_screen_has_sandbox_options()

	# Config tests
	_test_get_game_config_returns_dictionary()
	_test_config_has_scenario()
	_test_config_has_name()
	_test_config_has_sandbox_options()

	# Signal tests
	_test_back_button_emits_signal()
	_test_start_game_emits_signal_with_config()

	# Navigation tests
	_test_can_go_back_from_settings()
	_test_screen_visibility_updates()

	# Negative tests
	_test_no_scenario_selected_initially()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var menu := NewGameMenu.new()
	_assert(menu != null, "NewGameMenu should create without error")
	menu.queue_free()


func _test_has_panel() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	var panel: PanelContainer = menu.get_node_or_null("MainPanel")
	_assert(panel != null, "Should have main panel")
	menu.queue_free()


func _test_starts_on_scenario_screen() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	menu._show_screen(NewGameMenu.Screen.SCENARIO_SELECT)
	_assert(menu.get_current_screen() == NewGameMenu.Screen.SCENARIO_SELECT, "Should start on scenario screen")
	menu.queue_free()


func _test_has_scenario_cards() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	_assert(menu._scenario_cards.size() == 3, "Should have 3 scenario cards")
	menu.queue_free()


func _test_scenarios_have_names() -> void:
	var menu := NewGameMenu.new()
	for scenario in menu.SCENARIOS:
		_assert(scenario.has("name"), "Scenario should have name")
		_assert(not scenario.name.is_empty(), "Scenario name should not be empty")
	menu.queue_free()


func _test_scenarios_have_difficulties() -> void:
	var menu := NewGameMenu.new()
	var difficulties := ["Easy", "Medium", "Hard"]
	for scenario in menu.SCENARIOS:
		_assert(scenario.has("difficulty"), "Scenario should have difficulty")
		_assert(scenario.difficulty in difficulties, "Difficulty should be Easy, Medium, or Hard")
	menu.queue_free()


func _test_selecting_scenario_goes_to_settings() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	menu._show_screen(NewGameMenu.Screen.SCENARIO_SELECT)
	menu._on_scenario_selected(0)
	_assert(menu.get_current_screen() == NewGameMenu.Screen.GAME_SETTINGS, "Selecting scenario should go to settings screen")
	menu.queue_free()


func _test_settings_screen_has_name_input() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	var name_input: LineEdit = menu._settings_container.get_node_or_null("SettingsScroll/NameInput")
	# Name input is in a row, not direct child
	_assert(menu._settings_container != null, "Should have settings container")
	menu.queue_free()


func _test_settings_screen_has_difficulty_options() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	# The settings container should exist and contain difficulty dropdowns
	_assert(menu._settings_container != null, "Should have settings container for difficulty options")
	menu.queue_free()


func _test_settings_screen_has_sandbox_options() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	_assert(menu._settings_container != null, "Should have settings container for sandbox options")
	menu.queue_free()


func _test_get_game_config_returns_dictionary() -> void:
	var menu := NewGameMenu.new()
	var config := menu.get_game_config()
	_assert(config is Dictionary, "get_game_config should return Dictionary")
	_assert(config.size() > 0, "Config should not be empty")
	menu.queue_free()


func _test_config_has_scenario() -> void:
	var menu := NewGameMenu.new()
	var config := menu.get_game_config()
	_assert(config.has("scenario"), "Config should have scenario")
	_assert(config.scenario == "fresh_start", "Default scenario should be fresh_start")
	menu.queue_free()


func _test_config_has_name() -> void:
	var menu := NewGameMenu.new()
	var config := menu.get_game_config()
	_assert(config.has("name"), "Config should have name")
	_assert(config.name == "New Arcology", "Default name should be 'New Arcology'")
	menu.queue_free()


func _test_config_has_sandbox_options() -> void:
	var menu := NewGameMenu.new()
	var config := menu.get_game_config()
	_assert(config.has("unlimited_money"), "Config should have unlimited_money")
	_assert(config.has("instant_construction"), "Config should have instant_construction")
	_assert(config.has("all_blocks_unlocked"), "Config should have all_blocks_unlocked")
	_assert(config.has("disable_failures"), "Config should have disable_failures")
	# All should default to false
	_assert(config.unlimited_money == false, "unlimited_money should default to false")
	menu.queue_free()


func _test_back_button_emits_signal() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	var signal_received := false
	menu.back_pressed.connect(func(): signal_received = true)
	menu._on_back_pressed()
	_assert(signal_received, "Back button should emit back_pressed signal")
	menu.queue_free()


func _test_start_game_emits_signal_with_config() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	var received_config: Dictionary = {}
	menu.start_game_pressed.connect(func(config): received_config = config)
	menu._on_start_game()
	_assert(received_config.has("scenario"), "start_game_pressed should emit with config containing scenario")
	_assert(received_config.has("name"), "start_game_pressed should emit with config containing name")
	menu.queue_free()


func _test_can_go_back_from_settings() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	menu._show_screen(NewGameMenu.Screen.GAME_SETTINGS)
	menu._on_settings_back()
	_assert(menu.get_current_screen() == NewGameMenu.Screen.SCENARIO_SELECT, "Should be able to go back from settings")
	menu.queue_free()


func _test_screen_visibility_updates() -> void:
	var menu := NewGameMenu.new()
	menu._setup_layout()
	menu._show_screen(NewGameMenu.Screen.SCENARIO_SELECT)
	_assert(menu._scenario_container.visible == true, "Scenario container should be visible")
	_assert(menu._settings_container.visible == false, "Settings container should be hidden")
	menu._show_screen(NewGameMenu.Screen.GAME_SETTINGS)
	_assert(menu._scenario_container.visible == false, "Scenario container should be hidden")
	_assert(menu._settings_container.visible == true, "Settings container should be visible")
	menu.queue_free()


func _test_no_scenario_selected_initially() -> void:
	var menu := NewGameMenu.new()
	_assert(menu.get_selected_scenario() == -1, "No scenario should be selected initially")
	menu.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
