extends SceneTree
## Unit tests for BuildToolbar

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== Build Toolbar Tests ===")

	# Run all tests
	test_toolbar_creation()
	test_category_constants()
	test_category_order()
	test_category_buttons_created()
	test_flyout_initial_state()
	test_flyout_visibility_toggle()
	test_block_selection_signal()
	test_keyboard_shortcuts_defined()
	test_cost_formatting()
	test_selected_block_accessor()

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


func test_toolbar_creation() -> void:
	print("\ntest_toolbar_creation:")
	var toolbar := BuildToolbar.new()

	assert_not_null(toolbar, "Toolbar instance should be created")
	assert_true(toolbar is Control, "Toolbar should extend Control")

	toolbar.free()


func test_category_constants() -> void:
	print("\ntest_category_constants:")

	# Verify all 7 categories are defined
	assert_eq(BuildToolbar.CATEGORIES.size(), 7, "Should have 7 categories")

	# Check each category has required fields
	var required_fields := ["name", "short", "color", "icon", "key"]
	for cat in BuildToolbar.CATEGORIES:
		var cat_data: Dictionary = BuildToolbar.CATEGORIES[cat]
		for field in required_fields:
			assert_true(cat_data.has(field), "%s should have %s field" % [cat, field])


func test_category_order() -> void:
	print("\ntest_category_order:")

	# Verify category order
	assert_eq(BuildToolbar.CATEGORY_ORDER.size(), 7, "Should have 7 categories in order")
	assert_eq(BuildToolbar.CATEGORY_ORDER[0], "residential", "First category should be residential")
	assert_eq(BuildToolbar.CATEGORY_ORDER[1], "commercial", "Second category should be commercial")
	assert_eq(BuildToolbar.CATEGORY_ORDER[2], "industrial", "Third category should be industrial")
	assert_eq(BuildToolbar.CATEGORY_ORDER[3], "transit", "Fourth category should be transit")
	assert_eq(BuildToolbar.CATEGORY_ORDER[4], "green", "Fifth category should be green")
	assert_eq(BuildToolbar.CATEGORY_ORDER[5], "civic", "Sixth category should be civic")
	assert_eq(BuildToolbar.CATEGORY_ORDER[6], "infrastructure", "Seventh category should be infrastructure")


func test_category_buttons_created() -> void:
	print("\ntest_category_buttons_created:")
	var toolbar := BuildToolbar.new()
	toolbar._setup_ui()
	toolbar._populate_categories()

	# Check buttons were created
	assert_eq(toolbar._category_buttons.size(), 7, "Should have 7 category buttons")

	# Check each category has a button
	for cat in BuildToolbar.CATEGORY_ORDER:
		assert_true(toolbar._category_buttons.has(cat), "Should have button for %s" % cat)

	toolbar.free()


func test_flyout_initial_state() -> void:
	print("\ntest_flyout_initial_state:")
	var toolbar := BuildToolbar.new()
	toolbar._setup_ui()

	# Flyout should be hidden initially
	assert_false(toolbar.is_flyout_visible(), "Flyout should not be visible initially")
	assert_eq(toolbar.get_selected_category(), "", "No category should be selected initially")

	toolbar.free()


func test_flyout_visibility_toggle() -> void:
	print("\ntest_flyout_visibility_toggle:")
	var toolbar := BuildToolbar.new()
	toolbar._setup_ui()
	toolbar._populate_categories()

	# Opening flyout
	toolbar._open_flyout("residential")
	assert_true(toolbar.is_flyout_visible(), "Flyout should be visible after opening")
	assert_eq(toolbar.get_selected_category(), "residential", "Category should be residential")

	# Closing flyout
	toolbar._close_flyout()
	assert_false(toolbar.is_flyout_visible(), "Flyout should be hidden after closing")
	assert_eq(toolbar.get_selected_category(), "", "No category should be selected after closing")

	toolbar.free()


func test_block_selection_signal() -> void:
	print("\ntest_block_selection_signal:")
	var toolbar := BuildToolbar.new()
	toolbar._setup_ui()

	# Use select_block which both sets state and emits signal
	toolbar.select_block("residential_basic")

	# Verify state was set correctly
	assert_eq(toolbar.get_selected_block(), "residential_basic", "Selected block should be stored")

	# Test that internal method also works
	toolbar._selected_block = ""  # Reset
	toolbar._on_block_tile_pressed("corridor")
	assert_eq(toolbar.get_selected_block(), "corridor", "Block should be selected via tile press")

	toolbar.free()


func test_keyboard_shortcuts_defined() -> void:
	print("\ntest_keyboard_shortcuts_defined:")

	# Verify keyboard shortcuts match expected keys
	assert_eq(BuildToolbar.CATEGORIES["residential"]["key"], KEY_1, "Residential should use KEY_1")
	assert_eq(BuildToolbar.CATEGORIES["commercial"]["key"], KEY_2, "Commercial should use KEY_2")
	assert_eq(BuildToolbar.CATEGORIES["industrial"]["key"], KEY_3, "Industrial should use KEY_3")
	assert_eq(BuildToolbar.CATEGORIES["transit"]["key"], KEY_4, "Transit should use KEY_4")
	assert_eq(BuildToolbar.CATEGORIES["green"]["key"], KEY_5, "Green should use KEY_5")
	assert_eq(BuildToolbar.CATEGORIES["civic"]["key"], KEY_6, "Civic should use KEY_6")
	assert_eq(BuildToolbar.CATEGORIES["infrastructure"]["key"], KEY_7, "Infrastructure should use KEY_7")


func test_cost_formatting() -> void:
	print("\ntest_cost_formatting:")
	var toolbar := BuildToolbar.new()

	# Test various cost formats
	assert_eq(toolbar._format_cost(100), "100", "Small cost should show as-is")
	assert_eq(toolbar._format_cost(999), "999", "Under 1000 should show as-is")
	assert_eq(toolbar._format_cost(1000), "1.0K", "1000 should show as 1.0K")
	assert_eq(toolbar._format_cost(1500), "1.5K", "1500 should show as 1.5K")
	assert_eq(toolbar._format_cost(10000), "10.0K", "10000 should show as 10.0K")

	toolbar.free()


func test_selected_block_accessor() -> void:
	print("\ntest_selected_block_accessor:")
	var toolbar := BuildToolbar.new()
	toolbar._setup_ui()

	# Initial state
	assert_eq(toolbar.get_selected_block(), "", "No block should be selected initially")

	# After programmatic selection
	toolbar.select_block("corridor")
	assert_eq(toolbar.get_selected_block(), "corridor", "Selected block should be corridor")

	toolbar.free()
