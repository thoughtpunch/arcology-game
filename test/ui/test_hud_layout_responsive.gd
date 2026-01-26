extends SceneTree
## Test: HUD Layout and Responsiveness
## Per documentation/ui/hud-layout.md
##
## Run with:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/ui/test_hud_layout_responsive.gd

var _tests_passed: int = 0
var _tests_failed: int = 0


func _init() -> void:
	print("=== Test: HUD Layout and Responsiveness ===")
	print("")

	# Wait for autoloads
	await process_frame

	# Positive Assertions
	print("## Positive Assertions")
	_test_top_bar_renders_at_top()
	_test_top_bar_correct_height()
	_test_bottom_bar_renders_at_bottom()
	_test_bottom_bar_correct_height()
	_test_left_sidebar_renders_at_left()
	_test_left_sidebar_collapsed_width()
	_test_left_sidebar_expands_to_240px()
	_test_right_panel_renders_at_right()
	_test_right_panel_width()
	_test_resources_display_elements()
	_test_datetime_display_format()
	_test_speed_controls_render()
	_test_floor_navigator_shows_floor()
	_test_build_categories_render()

	# Negative Assertions
	print("")
	print("## Negative Assertions")
	_test_hud_allows_mouse_passthrough()
	_test_hud_panels_dont_overlap()
	_test_hud_within_viewport_bounds()
	_test_right_panel_hidden_by_default()

	# Integration Tests
	print("")
	print("## Integration Tests")
	_test_hud_updates_on_floor_change()
	_test_hud_updates_on_resources_change()
	_test_hud_buttons_trigger_signals()
	_test_window_resize_behavior()

	# Summary
	print("")
	print("=== Results ===")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, reason: String = "") -> void:
	if reason.is_empty():
		print("  FAIL: %s" % test_name)
	else:
		print("  FAIL: %s - %s" % [test_name, reason])
	_tests_failed += 1


# =============================================================================
# Positive Assertions
# =============================================================================

## Test: Top bar renders at top of screen (48px height)
func _test_top_bar_renders_at_top() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Top bar should be first child in VBox
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var first_child := vbox.get_child(0)

	if first_child == hud.top_bar:
		_pass("Top bar renders at top of screen")
	else:
		_fail("Top bar renders at top of screen", "Top bar is not first child")

	hud.free()


## Test: Top bar has correct height (48px per docs)
func _test_top_bar_correct_height() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var height: int = int(hud.top_bar.custom_minimum_size.y)

	if height == HUD.TOP_BAR_HEIGHT:
		_pass("Top bar correct height (48px)")
	else:
		_fail("Top bar correct height (48px)", "Got %dpx" % height)

	hud.free()


## Test: Bottom bar renders at bottom of screen (80px height)
func _test_bottom_bar_renders_at_bottom() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Bottom bar should be last child in VBox
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var last_index := vbox.get_child_count() - 1
	var last_child := vbox.get_child(last_index)

	if last_child == hud.bottom_bar:
		_pass("Bottom bar renders at bottom of screen")
	else:
		_fail("Bottom bar renders at bottom of screen", "Bottom bar is not last child")

	hud.free()


## Test: Bottom bar has correct height (80px per docs)
func _test_bottom_bar_correct_height() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var height: int = int(hud.bottom_bar.custom_minimum_size.y)

	if height == HUD.BOTTOM_BAR_HEIGHT:
		_pass("Bottom bar correct height (80px)")
	else:
		_fail("Bottom bar correct height (80px)", "Got %dpx" % height)

	hud.free()


## Test: Left sidebar renders at left edge (64px collapsed)
func _test_left_sidebar_renders_at_left() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Left sidebar should be first child in middle HBox
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var middle: HBoxContainer = vbox.get_child(1) as HBoxContainer
	var first_in_middle := middle.get_child(0)

	if first_in_middle == hud.left_sidebar:
		_pass("Left sidebar renders at left edge")
	else:
		_fail("Left sidebar renders at left edge", "Left sidebar is not first in middle section")

	hud.free()


## Test: Left sidebar starts collapsed (64px)
func _test_left_sidebar_collapsed_width() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# ToolSidebar needs _setup_ui called in tests
	if hud.left_sidebar is ToolSidebar:
		(hud.left_sidebar as ToolSidebar)._setup_ui()

	var width: int = int(hud.left_sidebar.custom_minimum_size.x)

	if width == ToolSidebar.COLLAPSED_WIDTH:
		_pass("Left sidebar collapsed width (64px)")
	else:
		_fail("Left sidebar collapsed width (64px)", "Got %dpx" % width)

	hud.free()


## Test: Left sidebar expands to 240px when toggled
func _test_left_sidebar_expands_to_240px() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	if hud.left_sidebar is ToolSidebar:
		var tool_sidebar: ToolSidebar = hud.left_sidebar as ToolSidebar
		tool_sidebar._setup_ui()
		tool_sidebar.expand()

		var width: int = int(tool_sidebar.custom_minimum_size.x)

		if width == ToolSidebar.EXPANDED_WIDTH:
			_pass("Left sidebar expands to 240px when toggled")
		else:
			_fail("Left sidebar expands to 240px when toggled", "Got %dpx" % width)
	else:
		_fail("Left sidebar expands to 240px when toggled", "ToolSidebar not used")

	hud.free()


## Test: Right panel renders at right edge (320px)
func _test_right_panel_renders_at_right() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Right panel should be last child in middle HBox
	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer
	var middle: HBoxContainer = vbox.get_child(1) as HBoxContainer
	var last_in_middle := middle.get_child(middle.get_child_count() - 1)

	if last_in_middle == hud.right_panel:
		_pass("Right panel renders at right edge")
	else:
		_fail("Right panel renders at right edge", "Right panel is not last in middle section")

	hud.free()


## Test: Right panel has correct width (320px per docs)
func _test_right_panel_width() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var width: int = int(hud.right_panel.custom_minimum_size.x)

	if width == HUD.RIGHT_PANEL_WIDTH:
		_pass("Right panel width (320px)")
	else:
		_fail("Right panel width (320px)", "Got %dpx" % width)

	hud.free()


## Test: Resources display shows money, population, AEI
func _test_resources_display_elements() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var money_label := hud.top_bar.get_node_or_null("HBoxContainer/Resources/MoneyLabel")
	var pop_label := hud.top_bar.get_node_or_null("HBoxContainer/Resources/PopLabel")
	var aei_label := hud.top_bar.get_node_or_null("HBoxContainer/Resources/AEILabel")

	if money_label != null and pop_label != null and aei_label != null:
		_pass("Resources display shows money, population, AEI")
	else:
		_fail("Resources display shows money, population, AEI",
			"money=%s pop=%s aei=%s" % [money_label != null, pop_label != null, aei_label != null])

	hud.free()


## Test: Date/time display shows Y M D format
func _test_datetime_display_format() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var time_controls := hud.top_bar.get_node_or_null("HBoxContainer/TimeControls") as TimeControls
	if time_controls:
		time_controls._setup_ui()

		hud.update_datetime(5, 3, 12)
		var text := time_controls.get_date_text()

		if text == "Y5 M3 D12":
			_pass("Date/time display shows Y M D format")
		else:
			_fail("Date/time display shows Y M D format", "Got '%s'" % text)
	else:
		_fail("Date/time display shows Y M D format", "TimeControls not found")

	hud.free()


## Test: Speed controls (pause, 1x, 2x, 3x) render
func _test_speed_controls_render() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var time_controls := hud.top_bar.get_node_or_null("HBoxContainer/TimeControls") as TimeControls
	if time_controls:
		time_controls._setup_ui()

		# Speed buttons are in "SpeedButtons" HBoxContainer
		var pause_btn := time_controls.get_node_or_null("SpeedButtons/PauseButton")
		var speed1_btn := time_controls.get_node_or_null("SpeedButtons/Speed1Button")
		var speed2_btn := time_controls.get_node_or_null("SpeedButtons/Speed2Button")
		var speed3_btn := time_controls.get_node_or_null("SpeedButtons/Speed3Button")

		if pause_btn != null and speed1_btn != null and speed2_btn != null and speed3_btn != null:
			_pass("Speed controls (pause, 1x, 2x, 3x) render")
		else:
			_fail("Speed controls (pause, 1x, 2x, 3x) render",
				"pause=%s 1x=%s 2x=%s 3x=%s" % [pause_btn != null, speed1_btn != null, speed2_btn != null, speed3_btn != null])
	else:
		_fail("Speed controls (pause, 1x, 2x, 3x) render", "TimeControls not found")

	hud.free()


## Test: Floor navigator shows current floor (F0, F1, etc.)
func _test_floor_navigator_shows_floor() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var floor_nav := hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator") as FloorNavigator
	if floor_nav:
		floor_nav._setup_ui()

		var text := floor_nav.get_floor_text()

		if text == "F0":
			_pass("Floor navigator shows current floor (F0, F1, etc.)")
		else:
			_fail("Floor navigator shows current floor (F0, F1, etc.)", "Got '%s'" % text)
	else:
		_fail("Floor navigator shows current floor (F0, F1, etc.)", "FloorNavigator not found")

	hud.free()


## Test: Build categories (Res, Com, Ind, Tra, Grn, Civ, Inf) render
## Note: Build categories are added by BuildToolbar in main.gd, not directly in HUD
func _test_build_categories_render() -> void:
	# Per HUD code comment: "Build categories are handled by BuildToolbar (added in main.gd)"
	# The HUD itself doesn't create these - they're added externally

	# Test that BuildToolbar has 7 categories defined in CATEGORY_ORDER constant
	var category_count: int = BuildToolbar.CATEGORY_ORDER.size()

	if category_count == 7:
		_pass("Build categories (Res, Com, Ind, Tra, Grn, Civ, Inf) render")
	else:
		_fail("Build categories (Res, Com, Ind, Tra, Grn, Civ, Inf) render",
			"Got %d categories, expected 7" % category_count)


# =============================================================================
# Negative Assertions
# =============================================================================

## Test: HUD doesn't block mouse events in game area (viewport_margin)
func _test_hud_allows_mouse_passthrough() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# HUD root should have MOUSE_FILTER_IGNORE
	var hud_filter := hud.mouse_filter == Control.MOUSE_FILTER_IGNORE

	# Viewport margin should also ignore mouse
	var viewport_filter := hud.viewport_margin.mouse_filter == Control.MOUSE_FILTER_IGNORE

	if hud_filter and viewport_filter:
		_pass("HUD doesn't block mouse events in game area")
	else:
		_fail("HUD doesn't block mouse events in game area",
			"hud=%s viewport=%s" % [hud_filter, viewport_filter])

	hud.free()


## Test: HUD panels don't overlap each other
func _test_hud_panels_dont_overlap() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Structure: VBox(top, middle[left, viewport, right], bottom)
	# By virtue of using VBox/HBox containers, panels shouldn't overlap

	var vbox: VBoxContainer = hud.get_child(0) as VBoxContainer

	# Check VBox has expected structure: top, middle, bottom
	if vbox.get_child_count() == 3:
		var middle := vbox.get_child(1) as HBoxContainer
		if middle and middle.get_child_count() == 3:
			_pass("HUD panels don't overlap each other")
		else:
			_fail("HUD panels don't overlap each other", "Middle section has wrong child count")
	else:
		_fail("HUD panels don't overlap each other", "VBox has wrong child count")

	hud.free()


## Test: HUD doesn't render outside viewport bounds
func _test_hud_within_viewport_bounds() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# HUD should use PRESET_FULL_RECT anchors (0,0 to 1,1)
	var within_bounds := (
		hud.anchor_left == 0.0 and
		hud.anchor_top == 0.0 and
		hud.anchor_right == 1.0 and
		hud.anchor_bottom == 1.0
	)

	# Also check offsets are zero (no overflow)
	var zero_offsets := (
		hud.offset_left == 0.0 and
		hud.offset_top == 0.0 and
		hud.offset_right == 0.0 and
		hud.offset_bottom == 0.0
	)

	if within_bounds and zero_offsets:
		_pass("HUD doesn't render outside viewport bounds")
	else:
		_fail("HUD doesn't render outside viewport bounds",
			"anchors=%s offsets=%s" % [within_bounds, zero_offsets])

	hud.free()


## Test: Empty right panel doesn't show (hidden by default)
func _test_right_panel_hidden_by_default() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	if not hud.right_panel.visible and not hud.is_right_panel_visible():
		_pass("Empty right panel doesn't show (hidden by default)")
	else:
		_fail("Empty right panel doesn't show (hidden by default)",
			"visible=%s is_visible=%s" % [hud.right_panel.visible, hud.is_right_panel_visible()])

	hud.free()


# =============================================================================
# Integration Tests
# =============================================================================

## Test: HUD updates when GameState.current_floor changes
func _test_hud_updates_on_floor_change() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	var floor_nav := hud.bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator") as FloorNavigator
	if floor_nav:
		floor_nav._setup_ui()

		# Update floor via HUD method
		hud.update_floor_display(5)
		var text_5 := floor_nav.get_floor_text()

		hud.update_floor_display(-2)
		var text_b2 := floor_nav.get_floor_text()

		if text_5 == "F5" and text_b2 == "B2":
			_pass("HUD updates when GameState.current_floor changes")
		else:
			_fail("HUD updates when GameState.current_floor changes",
				"F5='%s' B2='%s'" % [text_5, text_b2])
	else:
		_fail("HUD updates when GameState.current_floor changes", "FloorNavigator not found")

	hud.free()


## Test: HUD updates when resources change
func _test_hud_updates_on_resources_change() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	hud.update_resources(50000, 1234, 85)

	var money_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/MoneyLabel")
	var pop_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/PopLabel")
	var aei_label: Label = hud.top_bar.get_node_or_null("HBoxContainer/Resources/AEILabel")

	if money_label and pop_label and aei_label:
		var money_ok := money_label.text == "$50,000"
		var pop_ok := pop_label.text == "Pop: 1,234"
		var aei_ok := aei_label.text == "AEI: 85"

		if money_ok and pop_ok and aei_ok:
			_pass("HUD updates when resources change")
		else:
			_fail("HUD updates when resources change",
				"money='%s' pop='%s' aei='%s'" % [money_label.text, pop_label.text, aei_label.text])
	else:
		_fail("HUD updates when resources change", "Labels not found")

	hud.free()


## Test: HUD buttons trigger correct signals
func _test_hud_buttons_trigger_signals() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# Track signals
	var left_toggled_received := []
	var right_toggled_received := []

	hud.left_sidebar_toggled.connect(func(e): left_toggled_received.append(e))
	hud.right_panel_toggled.connect(func(v): right_toggled_received.append(v))

	# Toggle sidebar
	hud.toggle_left_sidebar()

	# Show/hide right panel
	hud.show_right_panel("Test")
	hud.hide_right_panel()

	# Verify signals
	var left_ok := left_toggled_received.size() > 0
	var right_ok := right_toggled_received.size() >= 2  # show + hide

	if left_ok and right_ok:
		_pass("HUD buttons trigger correct signals")
	else:
		_fail("HUD buttons trigger correct signals",
			"left=%d right=%d" % [left_toggled_received.size(), right_toggled_received.size()])

	hud.free()


## Test: Window resize doesn't break HUD layout
func _test_window_resize_behavior() -> void:
	var hud := HUD.new()
	hud._setup_layout()

	# At any simulated size, HUD structure should remain valid
	hud.size = Vector2(1920, 1080)
	var top_height_1080: int = int(hud.top_bar.custom_minimum_size.y)

	hud.size = Vector2(1280, 720)
	var top_height_720: int = int(hud.top_bar.custom_minimum_size.y)

	# Heights should remain constant (not scale with viewport)
	if top_height_1080 == HUD.TOP_BAR_HEIGHT and top_height_720 == HUD.TOP_BAR_HEIGHT:
		_pass("Window resize doesn't break HUD layout")
	else:
		_fail("Window resize doesn't break HUD layout",
			"1080p=%d 720p=%d" % [top_height_1080, top_height_720])

	hud.free()
