## GdUnit4 test suite for Phase 0 UI bug fixes.
## Tests building stats HUD visibility (arcology-6k3) and debug panel text (arcology-2u8).
class_name TestUIBugFixes
extends GdUnitTestSuite

const DebugPanelScript = preload("res://src/game/sandbox_debug_panel.gd")


# --- arcology-6k3: Building stats HUD uses PRESET_TOP_WIDE for proper width ---


func test_hud_label_top_wide_has_positive_width() -> void:
	## A Label with PRESET_TOP_WIDE should have anchor_left < anchor_right,
	## giving it actual width across the screen for right-aligned text.
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_right = -20
	lbl.offset_top = 20
	add_child(lbl)
	lbl.text = "Blocks: 5  |  Height: 3  |  Volume: 12  |  Footprint: 4"

	# PRESET_TOP_WIDE sets anchor_left=0, anchor_right=1 → label has real width
	assert_float(lbl.anchor_left).is_equal(0.0)
	assert_float(lbl.anchor_right).is_equal(1.0)
	# Anchors differ → the label has positive width in any parent
	assert_bool(lbl.anchor_right > lbl.anchor_left).is_true()
	lbl.queue_free()


func test_hud_label_top_right_has_zero_width() -> void:
	## Demonstrate the bug: PRESET_TOP_RIGHT gives anchor_left == anchor_right,
	## resulting in zero or negative width for the label.
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl.offset_right = -20
	lbl.offset_top = 20
	add_child(lbl)
	lbl.text = "Blocks: 5  |  Height: 3  |  Volume: 12  |  Footprint: 4"

	# Both anchors at 1.0 → width depends only on offsets, which are negative
	assert_float(lbl.anchor_left).is_equal(1.0)
	assert_float(lbl.anchor_right).is_equal(1.0)
	# offset_right - offset_left = -20 - 0 = -20 → no usable width
	assert_bool(lbl.offset_right <= lbl.offset_left).is_true()
	lbl.queue_free()


# --- arcology-2u8: Debug panel has proper vertical sizing ---


func test_debug_panel_has_vertical_extent() -> void:
	## The debug panel's background should stretch vertically so its
	## ScrollContainer has room to display content.
	var panel: Control = auto_free(DebugPanelScript.new())
	add_child(panel)
	panel.visible = true

	# Find the PanelContainer background
	var panel_bg: PanelContainer = panel.get_node("DebugPanelBG")
	assert_object(panel_bg).is_not_null()

	# anchor_bottom should be > anchor_top so the panel has height
	assert_bool(panel_bg.anchor_bottom > panel_bg.anchor_top).is_true()


func test_debug_panel_has_content_children() -> void:
	## The debug panel should contain visible child controls (FPS, sliders).
	var panel: Control = auto_free(DebugPanelScript.new())
	add_child(panel)
	panel.visible = true

	var panel_bg: PanelContainer = panel.get_node("DebugPanelBG")
	assert_object(panel_bg).is_not_null()

	# The content VBox should exist and have children
	var scroll: ScrollContainer = panel_bg.get_child(0) as ScrollContainer
	assert_object(scroll).is_not_null()
	var content: VBoxContainer = scroll.get_child(0) as VBoxContainer
	assert_object(content).is_not_null()
	# At minimum: title + FPS label + separator + section header + 3 sliders = 7+ children
	assert_bool(content.get_child_count() >= 5).is_true()


func test_debug_panel_offset_bottom_is_negative() -> void:
	## The bottom offset should be negative to leave a margin from the screen bottom.
	var panel: Control = auto_free(DebugPanelScript.new())
	add_child(panel)

	var panel_bg: PanelContainer = panel.get_node("DebugPanelBG")
	assert_float(panel_bg.offset_bottom).is_less(-1.0)


func test_debug_panel_adds_info_labels() -> void:
	## add_info_label() should create labels with initial text.
	var panel: Control = auto_free(DebugPanelScript.new())
	add_child(panel)

	var lbl: Label = panel.add_info_label("TestKey")
	assert_object(lbl).is_not_null()
	assert_str(lbl.text).contains("TestKey")


func test_debug_panel_adds_sections() -> void:
	## add_section() should add a header label without error.
	var panel: Control = auto_free(DebugPanelScript.new())
	add_child(panel)

	# Should not error
	panel.add_section("Stats")
	var lbl: Label = panel.add_info_label("Volume")
	assert_str(lbl.text).contains("Volume")
