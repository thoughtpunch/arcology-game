extends SceneTree
## Unit tests for HUD layout

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== HUD Layout Tests ===")

	# Run all tests
	test_hud_creation()
	test_top_bar_structure()
	test_left_sidebar_structure()
	test_right_panel_structure()
	test_bottom_bar_structure()
	test_color_constants()
	test_size_constants()
	test_sidebar_toggle_state()
	test_right_panel_visibility()
	test_number_formatting()
	test_floor_display_update()
	test_resources_update()
	test_datetime_update()
	test_right_panel_content_access()

	# Print summary
	print("")
	print("=== Test Summary ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed == 0:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	quit()


func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s" % message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(a, b, message: String) -> void:
	if a == b:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s (got %s, expected %s)" % [message, str(a), str(b)])


func assert_not_null(obj, message: String) -> void:
	assert_true(obj != null, message)


func test_hud_creation() -> void:
	print("\ntest_hud_creation:")
	var hud := HUD.new()

	assert_not_null(hud, "HUD instance should be created")
	assert_true(hud is Control, "HUD should extend Control")

	hud.free()


func test_top_bar_structure() -> void:
	print("\ntest_top_bar_structure:")
	var hud := HUD.new()

	# Need to trigger _ready by adding to tree
	# For this test, call _setup_layout directly
	hud._setup_layout()

	assert_not_null(hud.top_bar, "Top bar should exist")
	assert_true(hud.top_bar is PanelContainer, "Top bar should be PanelContainer")
	assert_eq(int(hud.top_bar.custom_minimum_size.y), HUD.TOP_BAR_HEIGHT, "Top bar should have correct height")

	# Check top bar has content
	var hbox := hud.top_bar.get_child(0)
	assert_true(hbox is HBoxContainer, "Top bar should contain HBoxContainer")
	assert_true(hbox.get_child_count() > 0, "Top bar should have child elements")

	hud.free()


func test_left_sidebar_structure() -> void:
	print("\ntest_left_sidebar_structure:")
	var hud := HUD.new()
	hud._setup_layout()

	assert_not_null(hud.left_sidebar, "Left sidebar should exist")
	assert_true(hud.left_sidebar is PanelContainer, "Left sidebar should be PanelContainer")
	assert_eq(int(hud.left_sidebar.custom_minimum_size.x), HUD.LEFT_SIDEBAR_COLLAPSED, "Left sidebar should start collapsed")

	# Check toggle button exists
	var toggle_btn := hud.left_sidebar.get_node_or_null("VBoxContainer/ToggleButton")
	assert_not_null(toggle_btn, "Toggle button should exist")
	assert_true(toggle_btn is Button, "Toggle should be Button")

	hud.free()


func test_right_panel_structure() -> void:
	print("\ntest_right_panel_structure:")
	var hud := HUD.new()
	hud._setup_layout()

	assert_not_null(hud.right_panel, "Right panel should exist")
	assert_true(hud.right_panel is PanelContainer, "Right panel should be PanelContainer")
	assert_eq(int(hud.right_panel.custom_minimum_size.x), HUD.RIGHT_PANEL_WIDTH, "Right panel should have correct width")
	assert_false(hud.right_panel.visible, "Right panel should be hidden by default")

	# Check close button exists
	var close_btn := hud.right_panel.get_node_or_null("VBoxContainer/HBoxContainer/CloseButton")
	assert_not_null(close_btn, "Close button should exist")

	hud.free()


func test_bottom_bar_structure() -> void:
	print("\ntest_bottom_bar_structure:")
	var hud := HUD.new()
	hud._setup_layout()

	assert_not_null(hud.bottom_bar, "Bottom bar should exist")
	assert_true(hud.bottom_bar is PanelContainer, "Bottom bar should be PanelContainer")
	assert_eq(int(hud.bottom_bar.custom_minimum_size.y), HUD.BOTTOM_BAR_HEIGHT, "Bottom bar should have correct height")

	# Check floor navigator exists
	var floor_nav := hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator")
	assert_not_null(floor_nav, "Floor navigator should exist")

	# Check build categories exist
	var build_cats := hud.bottom_bar.get_node_or_null("HBoxContainer/BuildCategories")
	assert_not_null(build_cats, "Build categories should exist")
	assert_eq(build_cats.get_child_count(), 7, "Should have 7 build category buttons")

	hud.free()


func test_color_constants() -> void:
	print("\ntest_color_constants:")

	# Verify color constants match documentation
	assert_eq(HUD.COLOR_TOP_BAR, Color("#1a1a2e"), "Top bar color should match docs")
	assert_eq(HUD.COLOR_SIDEBAR, Color("#16213e"), "Sidebar color should match docs")
	assert_eq(HUD.COLOR_PANEL_BORDER, Color("#0f3460"), "Panel border color should match docs")
	assert_eq(HUD.COLOR_BUTTON, Color("#0f3460"), "Button color should match docs")
	assert_eq(HUD.COLOR_BUTTON_HOVER, Color("#e94560"), "Button hover color should match docs")
	assert_eq(HUD.COLOR_TEXT, Color("#ffffff"), "Text color should match docs")
	assert_eq(HUD.COLOR_ACCENT, Color("#e94560"), "Accent color should match docs")


func test_size_constants() -> void:
	print("\ntest_size_constants:")

	# Verify size constants match documentation
	assert_eq(HUD.TOP_BAR_HEIGHT, 48, "Top bar height should be 48px")
	assert_eq(HUD.BOTTOM_BAR_HEIGHT, 80, "Bottom bar height should be 80px")
	assert_eq(HUD.LEFT_SIDEBAR_COLLAPSED, 64, "Collapsed sidebar width should be 64px")
	assert_eq(HUD.LEFT_SIDEBAR_EXPANDED, 240, "Expanded sidebar width should be 240px")
	assert_eq(HUD.RIGHT_PANEL_WIDTH, 320, "Right panel width should be 320px")


func test_sidebar_toggle_state() -> void:
	print("\ntest_sidebar_toggle_state:")
	var hud := HUD.new()
	hud._setup_layout()

	# Check initial state
	assert_false(hud.is_left_sidebar_expanded(), "Sidebar should start collapsed")

	# Toggle and check state changes
	hud._left_expanded = true
	assert_true(hud.is_left_sidebar_expanded(), "Sidebar should report expanded state")

	hud._left_expanded = false
	assert_false(hud.is_left_sidebar_expanded(), "Sidebar should report collapsed state")

	hud.free()


func test_right_panel_visibility() -> void:
	print("\ntest_right_panel_visibility:")
	var hud := HUD.new()
	hud._setup_layout()

	# Check initial state
	assert_false(hud.is_right_panel_visible(), "Right panel should start hidden")
	assert_false(hud.right_panel.visible, "Right panel node should be invisible")

	# Manually set visibility (without animation for test)
	hud._right_visible = true
	hud.right_panel.visible = true
	assert_true(hud.is_right_panel_visible(), "Right panel should report visible state")

	hud.free()


func test_number_formatting() -> void:
	print("\ntest_number_formatting:")
	var hud := HUD.new()

	# Test various number formats
	assert_eq(hud._format_number(0), "0", "Zero should format correctly")
	assert_eq(hud._format_number(100), "100", "Small numbers should format correctly")
	assert_eq(hud._format_number(1000), "1,000", "1000 should have comma")
	assert_eq(hud._format_number(10000), "10,000", "10000 should have comma")
	assert_eq(hud._format_number(100000), "100,000", "100000 should have comma")
	assert_eq(hud._format_number(1000000), "1,000,000", "Million should have two commas")
	assert_eq(hud._format_number(-1000), "-1,000", "Negative numbers should format correctly")

	hud.free()


func test_floor_display_update() -> void:
	print("\ntest_floor_display_update:")
	var hud := HUD.new()
	hud._setup_layout()

	# Get floor label
	var floor_label: Label = hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator/FloorLabel")
	assert_not_null(floor_label, "Floor label should exist")

	# Initial value
	assert_eq(floor_label.text, "F0", "Floor label should start at F0")

	# Update floor
	hud.update_floor_display(5)
	assert_eq(floor_label.text, "F5", "Floor label should update to F5")

	hud.update_floor_display(-2)
	assert_eq(floor_label.text, "F-2", "Floor label should show negative floors")

	hud.free()


func test_resources_update() -> void:
	print("\ntest_resources_update:")
	var hud := HUD.new()
	hud._setup_layout()

	# Update resources
	hud.update_resources(50000, 1234, 85)

	# Check money label
	var money_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/MoneyLabel")
	assert_not_null(money_label, "Money label should exist")
	assert_eq(money_label.text, "$50,000", "Money should be formatted with comma")

	# Check population label
	var pop_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/PopLabel")
	assert_not_null(pop_label, "Population label should exist")
	assert_eq(pop_label.text, "Pop: 1,234", "Population should be formatted")

	# Check AEI label
	var aei_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/AEILabel")
	assert_not_null(aei_label, "AEI label should exist")
	assert_eq(aei_label.text, "AEI: 85", "AEI should be displayed")

	hud.free()


func test_datetime_update() -> void:
	print("\ntest_datetime_update:")
	var hud := HUD.new()
	hud._setup_layout()

	# Update datetime
	hud.update_datetime(5, 3, 12)

	# Check datetime label
	var datetime_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/DateTimeLabel")
	assert_not_null(datetime_label, "DateTime label should exist")
	assert_eq(datetime_label.text, "Y5 M3 D12", "DateTime should format correctly")

	hud.free()


func test_right_panel_content_access() -> void:
	print("\ntest_right_panel_content_access:")
	var hud := HUD.new()
	hud._setup_layout()

	var content := hud.get_right_panel_content()
	assert_not_null(content, "Content area should be accessible")
	assert_true(content is VBoxContainer, "Content area should be VBoxContainer")

	hud.free()
