extends SceneTree
## Integration tests for HUD in main scene context

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== HUD Integration Tests ===")

	# Run all tests
	test_hud_floor_sync_with_gamestate()
	test_hud_components_initialized()
	test_hud_window_responsive()

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


func test_hud_floor_sync_with_gamestate() -> void:
	print("\ntest_hud_floor_sync_with_gamestate:")

	# Create HUD and simulate GameState integration
	var hud := HUD.new()
	hud._setup_layout()

	# Test floor display updates
	hud.update_floor_display(0)
	var floor_label: Label = hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator/FloorLabel")
	assert_not_null(floor_label, "Floor label should exist")
	assert_eq(floor_label.text, "F0", "Floor 0 should display as F0")

	hud.update_floor_display(5)
	assert_eq(floor_label.text, "F5", "Floor 5 should display as F5")

	hud.update_floor_display(-1)
	assert_eq(floor_label.text, "F-1", "Underground floor should display as F-1")

	hud.free()


func test_hud_components_initialized() -> void:
	print("\ntest_hud_components_initialized:")
	var hud := HUD.new()
	hud._setup_layout()
	hud._apply_theme()

	# Verify all main components exist
	assert_not_null(hud.top_bar, "Top bar should be initialized")
	assert_not_null(hud.left_sidebar, "Left sidebar should be initialized")
	assert_not_null(hud.right_panel, "Right panel should be initialized")
	assert_not_null(hud.bottom_bar, "Bottom bar should be initialized")

	# Verify top bar has menu button
	var menu_btn := hud.top_bar.get_node_or_null("HBoxContainer/MenuButton")
	assert_not_null(menu_btn, "Menu button should exist in top bar")

	# Verify bottom bar has build categories
	var build_cats := hud.bottom_bar.get_node_or_null("HBoxContainer/BuildCategories")
	assert_not_null(build_cats, "Build categories should exist in bottom bar")
	assert_eq(build_cats.get_child_count(), 7, "Should have 7 build category buttons")

	# Verify left sidebar has tool buttons
	var tools := hud.left_sidebar.get_node_or_null("VBoxContainer")
	assert_not_null(tools, "Sidebar VBox should exist")

	hud.free()


func test_hud_window_responsive() -> void:
	print("\ntest_hud_window_responsive:")
	var hud := HUD.new()
	hud._setup_layout()

	# Test that HUD fills screen
	assert_eq(hud.anchor_left, 0.0, "HUD should anchor to left")
	assert_eq(hud.anchor_right, 1.0, "HUD should anchor to right")
	assert_eq(hud.anchor_top, 0.0, "HUD should anchor to top")
	assert_eq(hud.anchor_bottom, 1.0, "HUD should anchor to bottom")

	# Test that mouse input passes through to viewport
	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD should ignore mouse for pass-through")

	hud.free()
