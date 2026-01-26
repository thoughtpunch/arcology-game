extends SceneTree
## Unit tests for FloorNavigator UI component

var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== FloorNavigator Tests ===")

	# Test basic creation and UI
	_test_floor_navigator_creation()
	_test_floor_navigator_ui_elements()
	_test_floor_display_format()

	# Test button states
	_test_button_states_default()
	_test_up_down_buttons()

	# Test popup
	_test_popup_creation()
	_test_popup_visibility()

	# Test keyboard shortcuts
	_test_keyboard_shortcuts_handling()

	# Test floor item creation
	_test_floor_item_indicators()
	_test_floor_item_names()

	# Test Grid floor methods
	_test_grid_get_blocks_on_floor()
	_test_grid_block_count_on_floor()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit(_tests_failed)


func _test_floor_navigator_creation() -> void:
	print("Testing FloorNavigator creation...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	assert(navigator != null, "FloorNavigator should be created")
	assert(navigator.name == "FloorNavigator", "Name should be set")

	navigator.free()
	_pass("FloorNavigator creation")


func _test_floor_navigator_ui_elements() -> void:
	print("Testing FloorNavigator UI elements...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Check main elements exist
	assert(navigator._up_button != null, "Up button should exist")
	assert(navigator._down_button != null, "Down button should exist")
	assert(navigator._floor_button != null, "Floor button should exist")
	assert(navigator._floor_list_popup != null, "Floor list popup should exist")

	# Check button names
	assert(navigator._up_button.name == "UpButton", "Up button should have correct name")
	assert(navigator._down_button.name == "DownButton", "Down button should have correct name")
	assert(navigator._floor_button.name == "FloorButton", "Floor button should have correct name")

	navigator.free()
	_pass("FloorNavigator UI elements")


func _test_floor_display_format() -> void:
	print("Testing floor display format...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Test positive floors
	navigator.update_display(0)
	assert(navigator.get_floor_text() == "F0 (G)", "Ground floor should show F0 (G)")

	navigator.update_display(1)
	assert(navigator.get_floor_text() == "F1", "Floor 1 should show F1")

	navigator.update_display(10)
	assert(navigator.get_floor_text() == "F10", "Floor 10 should show F10")

	# Test basement floors
	navigator.update_display(-1)
	assert(navigator.get_floor_text() == "B1", "Basement 1 should show B1")

	navigator.update_display(-2)
	assert(navigator.get_floor_text() == "B2", "Basement 2 should show B2")

	navigator.free()
	_pass("floor display format")


func _test_button_states_default() -> void:
	print("Testing button states (default)...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Without GameState connected, buttons shouldn't be disabled by update
	assert(not navigator._up_button.disabled, "Up button should start enabled")
	assert(not navigator._down_button.disabled, "Down button should start enabled")

	navigator.free()
	_pass("button states default")


func _test_up_down_buttons() -> void:
	print("Testing up/down button existence and signals...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Verify buttons have pressed signal connections
	assert(navigator._up_button.pressed.get_connections().size() > 0, "Up button should have pressed connections")
	assert(navigator._down_button.pressed.get_connections().size() > 0, "Down button should have pressed connections")
	assert(navigator._floor_button.pressed.get_connections().size() > 0, "Floor button should have pressed connections")

	navigator.free()
	_pass("up/down buttons")


func _test_popup_creation() -> void:
	print("Testing popup creation...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Check popup structure
	var popup := navigator._floor_list_popup
	assert(popup != null, "Popup should exist")
	assert(popup is PanelContainer, "Popup should be PanelContainer")
	assert(popup.name == "FloorListPopup", "Popup should have correct name")

	# Check popup has expected children
	var vbox := popup.get_node_or_null("VBoxContainer")
	assert(vbox != null, "Popup should have VBoxContainer")

	var header := vbox.get_node_or_null("Header")
	assert(header != null, "Popup should have header")
	assert(header.text == "FLOOR SELECTOR", "Header should have correct text")

	var scroll := vbox.get_node_or_null("ScrollContainer")
	assert(scroll != null, "Popup should have ScrollContainer")

	var floor_list := scroll.get_node_or_null("FloorList")
	assert(floor_list != null, "Popup should have FloorList")

	navigator.free()
	_pass("popup creation")


func _test_popup_visibility() -> void:
	print("Testing popup visibility...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Popup should start hidden
	assert(not navigator._floor_list_popup.visible, "Popup should start hidden")
	assert(not navigator.is_popup_visible(), "is_popup_visible should return false")

	# Show popup (without GameState, list will be empty but popup should show)
	navigator._show_floor_list()
	assert(navigator._floor_list_popup.visible, "Popup should be visible after show")
	assert(navigator.is_popup_visible(), "is_popup_visible should return true")

	# Hide popup
	navigator._hide_floor_list()
	assert(not navigator._floor_list_popup.visible, "Popup should be hidden after hide")
	assert(not navigator.is_popup_visible(), "is_popup_visible should return false")

	navigator.free()
	_pass("popup visibility")


func _test_keyboard_shortcuts_handling() -> void:
	print("Testing keyboard shortcuts availability...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Verify FloorNavigator has _unhandled_input method
	assert(navigator.has_method("_unhandled_input"), "Should have _unhandled_input method")

	# Test that get_current_floor returns sensible default without GameState
	assert(navigator.get_current_floor() == 0, "Default floor should be 0")

	navigator.free()
	_pass("keyboard shortcuts handling")


func _test_floor_item_indicators() -> void:
	print("Testing floor item indicators...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Test indicator for current floor
	var current_indicator := navigator._get_floor_indicator(5, 5, null)
	assert(current_indicator == "●", "Current floor indicator should be ●")

	# Test indicator for other floors (without grid, defaults to ◐)
	var other_indicator := navigator._get_floor_indicator(3, 5, null)
	assert(other_indicator == "◐", "Other floor indicator should be ◐ (has content)")

	navigator.free()
	_pass("floor item indicators")


func _test_floor_item_names() -> void:
	print("Testing floor item names...")

	var navigator := FloorNavigator.new()
	navigator._setup_ui()

	# Test floor item creation with names
	var item_ground := navigator._create_floor_item(0, 0, null)
	assert(item_ground.text.contains("Ground"), "Ground floor should have 'Ground' label")

	var item_basement := navigator._create_floor_item(-1, 0, null)
	assert(item_basement.text.contains("B1"), "Basement floor should have B1")
	assert(item_basement.text.contains("Basement"), "First basement should have 'Basement' label")

	var item_top := navigator._create_floor_item(10, 0, null)
	assert(item_top.text.contains("10"), "Top floor should have 10")
	assert(item_top.text.contains("Penthouse"), "Top floor should have 'Penthouse' label")

	var item_regular := navigator._create_floor_item(5, 0, null)
	assert(item_regular.text.contains("05"), "Regular floor should have 05")

	item_ground.free()
	item_basement.free()
	item_top.free()
	item_regular.free()
	navigator.free()
	_pass("floor item names")


func _test_grid_get_blocks_on_floor() -> void:
	print("Testing Grid.get_blocks_on_floor...")

	var script := load("res://src/core/grid.gd")
	var grid: Node = script.new()

	# Add some test blocks at different floors
	var block0_1 := {"block_type": "corridor", "floor": 0}
	var block0_2 := {"block_type": "corridor", "floor": 0}
	var block1_1 := {"block_type": "stairs", "floor": 1}
	var block2_1 := {"block_type": "residential", "floor": 2}

	grid._blocks[Vector3i(0, 0, 0)] = block0_1
	grid._blocks[Vector3i(1, 0, 0)] = block0_2
	grid._blocks[Vector3i(0, 0, 1)] = block1_1
	grid._blocks[Vector3i(0, 0, 2)] = block2_1

	# Test getting blocks by floor
	var floor0_blocks: Array = grid.get_blocks_on_floor(0)
	assert(floor0_blocks.size() == 2, "Floor 0 should have 2 blocks")

	var floor1_blocks: Array = grid.get_blocks_on_floor(1)
	assert(floor1_blocks.size() == 1, "Floor 1 should have 1 block")

	var floor2_blocks: Array = grid.get_blocks_on_floor(2)
	assert(floor2_blocks.size() == 1, "Floor 2 should have 1 block")

	var floor3_blocks: Array = grid.get_blocks_on_floor(3)
	assert(floor3_blocks.size() == 0, "Floor 3 should have 0 blocks")

	_pass("Grid.get_blocks_on_floor")


func _test_grid_block_count_on_floor() -> void:
	print("Testing Grid.get_block_count_on_floor...")

	var script := load("res://src/core/grid.gd")
	var grid: Node = script.new()

	# Add some test blocks at different floors
	grid._blocks[Vector3i(0, 0, 0)] = {"block_type": "a"}
	grid._blocks[Vector3i(1, 0, 0)] = {"block_type": "b"}
	grid._blocks[Vector3i(2, 0, 0)] = {"block_type": "c"}
	grid._blocks[Vector3i(0, 0, 1)] = {"block_type": "d"}

	# Test counting blocks by floor
	assert(grid.get_block_count_on_floor(0) == 3, "Floor 0 should have 3 blocks")
	assert(grid.get_block_count_on_floor(1) == 1, "Floor 1 should have 1 block")
	assert(grid.get_block_count_on_floor(2) == 0, "Floor 2 should have 0 blocks")
	assert(grid.get_block_count_on_floor(-1) == 0, "Floor -1 should have 0 blocks")

	_pass("Grid.get_block_count_on_floor")


func _pass(test_name: String) -> void:
	print("  ✓ " + test_name)
	_tests_passed += 1


func _fail(test_name: String, msg: String) -> void:
	print("  ✗ " + test_name + ": " + msg)
	_tests_failed += 1
