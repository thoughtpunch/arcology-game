extends SceneTree
## Unit tests for SaveLoadMenu class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== SaveLoadMenu Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_has_panel()
	_test_has_save_list()

	# Mode tests
	_test_default_mode_is_load()
	_test_can_set_save_mode()
	_test_can_set_load_mode()
	_test_mode_changes_title()

	# UI element tests
	_test_has_filter_dropdown()
	_test_has_sort_dropdown()
	_test_has_save_name_input()
	_test_save_name_input_visibility()

	# Signal tests
	_test_back_button_emits_signal()
	_test_save_action_emits_signal()
	_test_delete_emits_signal()

	# Number formatting tests
	_test_format_number_small()
	_test_format_number_thousands()
	_test_format_number_millions()
	_test_format_number_negative()

	# Negative tests
	_test_empty_save_list()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var menu := SaveLoadMenu.new()
	_assert(menu != null, "SaveLoadMenu should create without error")
	menu.queue_free()


func _test_has_panel() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var panel: PanelContainer = menu.get_node_or_null("MainPanel")
	_assert(panel != null, "Should have main panel")
	menu.queue_free()


func _test_has_save_list() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	_assert(menu._save_list != null, "Should have save list container")
	menu.queue_free()


func _test_default_mode_is_load() -> void:
	var menu := SaveLoadMenu.new()
	_assert(menu.get_mode() == SaveLoadMenu.Mode.LOAD, "Default mode should be LOAD")
	menu.queue_free()


func _test_can_set_save_mode() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	menu.set_mode(SaveLoadMenu.Mode.SAVE)
	_assert(menu.get_mode() == SaveLoadMenu.Mode.SAVE, "Should be able to set SAVE mode")
	menu.queue_free()


func _test_can_set_load_mode() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	menu.set_mode(SaveLoadMenu.Mode.SAVE)
	menu.set_mode(SaveLoadMenu.Mode.LOAD)
	_assert(menu.get_mode() == SaveLoadMenu.Mode.LOAD, "Should be able to set LOAD mode")
	menu.queue_free()


func _test_mode_changes_title() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var title: Label = menu._panel.get_node_or_null("MainVBox/Header/TitleLabel")

	menu.set_mode(SaveLoadMenu.Mode.LOAD)
	_assert(title.text == "LOAD GAME", "Title should be 'LOAD GAME' in load mode")

	menu.set_mode(SaveLoadMenu.Mode.SAVE)
	_assert(title.text == "SAVE GAME", "Title should be 'SAVE GAME' in save mode")
	menu.queue_free()


func _test_has_filter_dropdown() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var filter: OptionButton = menu._panel.get_node_or_null("MainVBox/FilterBar/FilterDropdown")
	_assert(filter != null, "Should have filter dropdown")
	_assert(filter.item_count >= 3, "Filter should have at least 3 options")
	menu.queue_free()


func _test_has_sort_dropdown() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var sort_dropdown: OptionButton = menu._panel.get_node_or_null("MainVBox/FilterBar/SortDropdown")
	_assert(sort_dropdown != null, "Should have sort dropdown")
	_assert(sort_dropdown.item_count >= 3, "Sort should have at least 3 options")
	menu.queue_free()


func _test_has_save_name_input() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	_assert(menu._save_name_input != null, "Should have save name input")
	_assert(menu._save_name_input.text == "New Save", "Default save name should be 'New Save'")
	menu.queue_free()


func _test_save_name_input_visibility() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var name_row: Control = menu._panel.get_node_or_null("MainVBox/SaveNameRow")

	menu.set_mode(SaveLoadMenu.Mode.SAVE)
	_assert(name_row.visible == true, "Save name row should be visible in save mode")

	menu.set_mode(SaveLoadMenu.Mode.LOAD)
	_assert(name_row.visible == false, "Save name row should be hidden in load mode")
	menu.queue_free()


func _test_back_button_emits_signal() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var signal_received := false
	menu.back_pressed.connect(func(): signal_received = true)
	menu._on_back_pressed()
	_assert(signal_received, "Back button should emit back_pressed signal")
	menu.queue_free()


func _test_save_action_emits_signal() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	menu.set_mode(SaveLoadMenu.Mode.SAVE)
	var received_name := ""
	menu.save_selected.connect(func(name): received_name = name)
	menu._on_action_pressed()
	_assert(received_name == "New Save", "Save action should emit save_selected with name")
	menu.queue_free()


func _test_delete_emits_signal() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	var received_path := ""
	menu.save_deleted.connect(func(path): received_path = path)
	menu._on_delete_pressed("test/path.save")
	_assert(received_path == "test/path.save", "Delete should emit save_deleted with path")
	menu.queue_free()


func _test_format_number_small() -> void:
	var menu := SaveLoadMenu.new()
	var result := menu._format_number(42)
	_assert(result == "42", "Small numbers should not have commas")
	menu.queue_free()


func _test_format_number_thousands() -> void:
	var menu := SaveLoadMenu.new()
	var result := menu._format_number(1234)
	_assert(result == "1,234", "Thousands should have comma: got '%s'" % result)
	menu.queue_free()


func _test_format_number_millions() -> void:
	var menu := SaveLoadMenu.new()
	var result := menu._format_number(1234567)
	_assert(result == "1,234,567", "Millions should have two commas: got '%s'" % result)
	menu.queue_free()


func _test_format_number_negative() -> void:
	var menu := SaveLoadMenu.new()
	var result := menu._format_number(-5000)
	_assert(result == "-5,000", "Negative numbers should keep negative sign: got '%s'" % result)
	menu.queue_free()


func _test_empty_save_list() -> void:
	var menu := SaveLoadMenu.new()
	menu._setup_layout()
	# get_save_count should work even if directory doesn't exist
	var count := menu.get_save_count()
	_assert(count >= 0, "Save count should be non-negative")
	menu.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
