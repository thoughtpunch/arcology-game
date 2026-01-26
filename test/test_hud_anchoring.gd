extends SceneTree
## Unit tests for HUD anchoring and responsive behavior

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== HUD Anchoring Tests ===")

	# Run all tests
	test_hud_anchors()
	test_hud_offsets()
	test_vbox_fills_parent()
	test_top_bar_position()
	test_bottom_bar_position()
	test_middle_section_expands()
	test_resize_behavior()
	test_anchor_presets()

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


func assert_approx(a: float, b: float, message: String, epsilon: float = 0.01) -> void:
	if absf(a - b) < epsilon:
		tests_passed += 1
		print("  ✓ %s" % message)
	else:
		tests_failed += 1
		print("  ✗ FAILED: %s (got %s, expected %s)" % [message, str(a), str(b)])


func test_hud_anchors() -> void:
	print("\ntest_hud_anchors:")
	var hud := HUD.new()
	hud._setup_layout()

	# HUD should have full rect anchors (0,0 to 1,1)
	assert_approx(hud.anchor_left, 0.0, "HUD anchor_left should be 0")
	assert_approx(hud.anchor_top, 0.0, "HUD anchor_top should be 0")
	assert_approx(hud.anchor_right, 1.0, "HUD anchor_right should be 1")
	assert_approx(hud.anchor_bottom, 1.0, "HUD anchor_bottom should be 1")

	hud.free()


func test_hud_offsets() -> void:
	print("\ntest_hud_offsets:")
	var hud := HUD.new()
	hud._setup_layout()

	# HUD should have zero offsets (fills entire anchor area)
	assert_approx(hud.offset_left, 0.0, "HUD offset_left should be 0")
	assert_approx(hud.offset_top, 0.0, "HUD offset_top should be 0")
	assert_approx(hud.offset_right, 0.0, "HUD offset_right should be 0")
	assert_approx(hud.offset_bottom, 0.0, "HUD offset_bottom should be 0")

	hud.free()


func test_vbox_fills_parent() -> void:
	print("\ntest_vbox_fills_parent:")
	var hud := HUD.new()
	hud._setup_layout()

	# Get the VBoxContainer
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	assert_true(vbox != null, "VBoxContainer should be first child")

	# VBoxContainer should have full rect anchors
	assert_approx(vbox.anchor_left, 0.0, "VBox anchor_left should be 0")
	assert_approx(vbox.anchor_top, 0.0, "VBox anchor_top should be 0")
	assert_approx(vbox.anchor_right, 1.0, "VBox anchor_right should be 1")
	assert_approx(vbox.anchor_bottom, 1.0, "VBox anchor_bottom should be 1")

	hud.free()


func test_top_bar_position() -> void:
	print("\ntest_top_bar_position:")
	var hud := HUD.new()
	hud._setup_layout()

	# Top bar should be first in VBox (position 0)
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	assert_true(vbox.get_child(0) == hud.top_bar, "Top bar should be first child of VBox")

	# Top bar should have fixed height
	assert_eq(int(hud.top_bar.custom_minimum_size.y), HUD.TOP_BAR_HEIGHT, "Top bar should have correct min height")

	# Top bar should NOT expand vertically
	var top_flags := hud.top_bar.size_flags_vertical
	assert_false((top_flags & Control.SIZE_EXPAND) != 0, "Top bar should not have vertical expand flag")

	hud.free()


func test_bottom_bar_position() -> void:
	print("\ntest_bottom_bar_position:")
	var hud := HUD.new()
	hud._setup_layout()

	# Bottom bar should be last in VBox
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var last_index := vbox.get_child_count() - 1
	assert_true(vbox.get_child(last_index) == hud.bottom_bar, "Bottom bar should be last child of VBox")

	# Bottom bar should have fixed height
	assert_eq(int(hud.bottom_bar.custom_minimum_size.y), HUD.BOTTOM_BAR_HEIGHT, "Bottom bar should have correct min height")

	# Bottom bar should NOT expand vertically
	var bottom_flags := hud.bottom_bar.size_flags_vertical
	assert_false((bottom_flags & Control.SIZE_EXPAND) != 0, "Bottom bar should not have vertical expand flag")

	hud.free()


func test_middle_section_expands() -> void:
	print("\ntest_middle_section_expands:")
	var hud := HUD.new()
	hud._setup_layout()

	# Get middle HBox (between top and bottom bars)
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var middle: HBoxContainer = vbox.get_child(1) as HBoxContainer
	assert_true(middle != null, "Middle section should be HBoxContainer")

	# Middle section should expand to fill available space
	var middle_flags := middle.size_flags_vertical
	assert_true((middle_flags & Control.SIZE_EXPAND_FILL) != 0, "Middle section should have vertical expand fill flag")

	hud.free()


func test_resize_behavior() -> void:
	print("\ntest_resize_behavior:")
	var hud := HUD.new()
	hud._setup_layout()

	# Simulate different viewport sizes by setting HUD size
	# Since HUD uses anchors relative to parent, we can test the structure

	# At any size, top bar should maintain its height
	hud.size = Vector2(1920, 1080)
	assert_eq(int(hud.top_bar.custom_minimum_size.y), HUD.TOP_BAR_HEIGHT, "Top bar height constant at 1920x1080")

	hud.size = Vector2(1280, 720)
	assert_eq(int(hud.top_bar.custom_minimum_size.y), HUD.TOP_BAR_HEIGHT, "Top bar height constant at 1280x720")

	# Bottom bar height should also be constant
	assert_eq(int(hud.bottom_bar.custom_minimum_size.y), HUD.BOTTOM_BAR_HEIGHT, "Bottom bar height constant at any size")

	hud.free()


func test_anchor_presets() -> void:
	print("\ntest_anchor_presets:")
	var hud := HUD.new()
	hud._setup_layout()

	# Verify mouse filter allows click-through
	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD should ignore mouse events for click-through")

	# Verify VBox also allows click-through
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	assert_eq(vbox.mouse_filter, Control.MOUSE_FILTER_IGNORE, "VBox should ignore mouse events")

	# Verify viewport margin allows click-through
	assert_eq(hud.viewport_margin.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Viewport margin should ignore mouse events")

	hud.free()
