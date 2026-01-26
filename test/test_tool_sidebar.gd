extends SceneTree
## Unit tests for ToolSidebar UI component

var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== ToolSidebar Tests ===")

	# Test basic creation and UI
	_test_tool_sidebar_creation()
	_test_tool_sidebar_ui_elements()
	_test_tool_buttons_exist()

	# Test expand/collapse
	_test_initial_collapsed_state()
	_test_expand_collapse()
	_test_pin_behavior()

	# Test tool selection
	_test_tool_selection()
	_test_tool_icons_and_labels()

	# Test quick build
	_test_recent_blocks()
	_test_recent_blocks_limit()

	# Test favorites
	_test_favorites_add_remove()
	_test_favorites_limit()

	# Test utility methods
	_test_format_block_name()
	_test_get_current_tool()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit(_tests_failed)


func _test_tool_sidebar_creation() -> void:
	print("Testing ToolSidebar creation...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	assert(sidebar != null, "ToolSidebar should be created")
	assert(sidebar.name == "ToolSidebar", "Name should be set")

	sidebar.free()
	_pass("ToolSidebar creation")


func _test_tool_sidebar_ui_elements() -> void:
	print("Testing ToolSidebar UI elements...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Check main elements exist
	assert(sidebar._vbox != null, "VBox should exist")
	assert(sidebar._menu_btn != null, "Menu button should exist")
	assert(sidebar._pin_btn != null, "Pin button should exist")
	assert(sidebar._quick_build_section != null, "Quick build section should exist")
	assert(sidebar._favorites_section != null, "Favorites section should exist")

	sidebar.free()
	_pass("ToolSidebar UI elements")


func _test_tool_buttons_exist() -> void:
	print("Testing tool buttons exist...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Check all tool buttons exist
	assert(ToolSidebar.Tool.SELECT in sidebar._tool_buttons, "Select button should exist")
	assert(ToolSidebar.Tool.BUILD in sidebar._tool_buttons, "Build button should exist")
	assert(ToolSidebar.Tool.DEMOLISH in sidebar._tool_buttons, "Demolish button should exist")
	assert(ToolSidebar.Tool.INFO in sidebar._tool_buttons, "Info button should exist")
	assert(ToolSidebar.Tool.UPGRADE in sidebar._tool_buttons, "Upgrade button should exist")

	sidebar.free()
	_pass("tool buttons exist")


func _test_initial_collapsed_state() -> void:
	print("Testing initial collapsed state...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	assert(not sidebar.is_expanded(), "Sidebar should start collapsed")
	assert(not sidebar.is_pinned(), "Sidebar should start unpinned")
	assert(sidebar.custom_minimum_size.x == ToolSidebar.COLLAPSED_WIDTH, "Width should be collapsed")

	# Quick build and favorites should be hidden
	assert(not sidebar._quick_build_section.visible, "Quick build should be hidden when collapsed")
	assert(not sidebar._favorites_section.visible, "Favorites should be hidden when collapsed")

	sidebar.free()
	_pass("initial collapsed state")


func _test_expand_collapse() -> void:
	print("Testing expand/collapse...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Expand
	sidebar.expand()
	assert(sidebar.is_expanded(), "Sidebar should be expanded")
	assert(sidebar.custom_minimum_size.x == ToolSidebar.EXPANDED_WIDTH, "Width should be expanded")
	assert(sidebar._quick_build_section.visible, "Quick build should be visible when expanded")
	assert(sidebar._favorites_section.visible, "Favorites should be visible when expanded")

	# Collapse
	sidebar.collapse()
	assert(not sidebar.is_expanded(), "Sidebar should be collapsed")
	assert(sidebar.custom_minimum_size.x == ToolSidebar.COLLAPSED_WIDTH, "Width should be collapsed")

	sidebar.free()
	_pass("expand/collapse")


func _test_pin_behavior() -> void:
	print("Testing pin behavior...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	assert(not sidebar.is_pinned(), "Should start unpinned")

	sidebar.toggle_pin()
	assert(sidebar.is_pinned(), "Should be pinned after toggle")

	sidebar.toggle_pin()
	assert(not sidebar.is_pinned(), "Should be unpinned after second toggle")

	# When pinned, collapse should not work
	sidebar.expand()
	sidebar.toggle_pin()
	sidebar.collapse()  # Should not collapse because pinned
	assert(sidebar.is_expanded(), "Should stay expanded when pinned")

	sidebar.free()
	_pass("pin behavior")


func _test_tool_selection() -> void:
	print("Testing tool selection...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Default tool should be SELECT
	assert(sidebar.get_current_tool() == ToolSidebar.Tool.SELECT, "Default tool should be SELECT")

	# Select BUILD
	sidebar.set_current_tool(ToolSidebar.Tool.BUILD)
	assert(sidebar.get_current_tool() == ToolSidebar.Tool.BUILD, "Should be BUILD after set")
	assert(sidebar._tool_buttons[ToolSidebar.Tool.BUILD].button_pressed, "BUILD button should be pressed")
	assert(not sidebar._tool_buttons[ToolSidebar.Tool.SELECT].button_pressed, "SELECT button should not be pressed")

	# Select DEMOLISH
	sidebar.set_current_tool(ToolSidebar.Tool.DEMOLISH)
	assert(sidebar.get_current_tool() == ToolSidebar.Tool.DEMOLISH, "Should be DEMOLISH")
	assert(sidebar._tool_buttons[ToolSidebar.Tool.DEMOLISH].button_pressed, "DEMOLISH button should be pressed")

	sidebar.free()
	_pass("tool selection")


func _test_tool_icons_and_labels() -> void:
	print("Testing tool icons and labels...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Test icons (collapsed state)
	assert(sidebar._get_tool_icon(ToolSidebar.Tool.SELECT) == "🔍", "Select icon")
	assert(sidebar._get_tool_icon(ToolSidebar.Tool.BUILD) == "🔨", "Build icon")
	assert(sidebar._get_tool_icon(ToolSidebar.Tool.DEMOLISH) == "💥", "Demolish icon")
	assert(sidebar._get_tool_icon(ToolSidebar.Tool.INFO) == "ℹ", "Info icon")
	assert(sidebar._get_tool_icon(ToolSidebar.Tool.UPGRADE) == "⬆", "Upgrade icon")

	# Test labels (expanded state)
	assert(sidebar._get_tool_label(ToolSidebar.Tool.SELECT).contains("Select"), "Select label")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.BUILD).contains("Build"), "Build label")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.DEMOLISH).contains("Demolish"), "Demolish label")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.INFO).contains("Info"), "Info label")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.UPGRADE).contains("Upgrade"), "Upgrade label")

	# Labels should contain keyboard shortcuts
	assert(sidebar._get_tool_label(ToolSidebar.Tool.SELECT).contains("(Q)"), "Select should have Q shortcut")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.BUILD).contains("(B)"), "Build should have B shortcut")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.DEMOLISH).contains("(X)"), "Demolish should have X shortcut")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.INFO).contains("(I)"), "Info should have I shortcut")
	assert(sidebar._get_tool_label(ToolSidebar.Tool.UPGRADE).contains("(U)"), "Upgrade should have U shortcut")

	sidebar.free()
	_pass("tool icons and labels")


func _test_recent_blocks() -> void:
	print("Testing recent blocks...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Add recent blocks
	sidebar.add_recent_block("corridor")
	var recent := sidebar.get_recent_blocks()
	assert(recent.size() == 1, "Should have 1 recent block")
	assert(recent[0] == "corridor", "First recent should be corridor")

	# Add another
	sidebar.add_recent_block("stairs")
	recent = sidebar.get_recent_blocks()
	assert(recent.size() == 2, "Should have 2 recent blocks")
	assert(recent[0] == "stairs", "Most recent should be stairs")
	assert(recent[1] == "corridor", "Second should be corridor")

	# Add duplicate (should move to front)
	sidebar.add_recent_block("corridor")
	recent = sidebar.get_recent_blocks()
	assert(recent.size() == 2, "Should still have 2 (duplicate moved)")
	assert(recent[0] == "corridor", "Corridor should be first now")

	sidebar.free()
	_pass("recent blocks")


func _test_recent_blocks_limit() -> void:
	print("Testing recent blocks limit...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Add more than 5 blocks
	for i in range(7):
		sidebar.add_recent_block("block_%d" % i)

	var recent := sidebar.get_recent_blocks()
	assert(recent.size() == 5, "Should be limited to 5 blocks")
	assert(recent[0] == "block_6", "Most recent should be block_6")
	assert(recent[4] == "block_2", "Oldest should be block_2")

	sidebar.free()
	_pass("recent blocks limit")


func _test_favorites_add_remove() -> void:
	print("Testing favorites add/remove...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Add favorites
	sidebar.add_favorite("corridor")
	var favs := sidebar.get_favorites()
	assert(favs.size() == 1, "Should have 1 favorite")
	assert(favs[0] == "corridor", "First favorite should be corridor")

	# Add another
	sidebar.add_favorite("stairs")
	favs = sidebar.get_favorites()
	assert(favs.size() == 2, "Should have 2 favorites")

	# Add duplicate (should not add)
	sidebar.add_favorite("corridor")
	favs = sidebar.get_favorites()
	assert(favs.size() == 2, "Should still have 2 (no duplicate)")

	# Remove
	sidebar.remove_favorite("corridor")
	favs = sidebar.get_favorites()
	assert(favs.size() == 1, "Should have 1 after remove")
	assert(favs[0] == "stairs", "Remaining should be stairs")

	sidebar.free()
	_pass("favorites add/remove")


func _test_favorites_limit() -> void:
	print("Testing favorites limit...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Add more than 10 favorites
	for i in range(12):
		sidebar.add_favorite("fav_%d" % i)

	var favs := sidebar.get_favorites()
	assert(favs.size() == 10, "Should be limited to 10 favorites")

	sidebar.free()
	_pass("favorites limit")


func _test_format_block_name() -> void:
	print("Testing block name formatting...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Test formatting
	var formatted := sidebar._format_block_name("corridor")
	assert(formatted.contains("[COR]"), "Should have abbreviation")
	assert(formatted.contains("Corridor"), "Should have full name")

	formatted = sidebar._format_block_name("residential_basic")
	assert(formatted.contains("[RES]"), "Should have abbreviation")
	assert(formatted.contains("Residential Basic"), "Should have full name")

	sidebar.free()
	_pass("block name formatting")


func _test_get_current_tool() -> void:
	print("Testing get_current_tool...")

	var sidebar := ToolSidebar.new()
	sidebar._setup_ui()

	# Verify Tool enum values
	assert(ToolSidebar.Tool.SELECT == 0, "SELECT should be 0")
	assert(ToolSidebar.Tool.BUILD == 1, "BUILD should be 1")
	assert(ToolSidebar.Tool.DEMOLISH == 2, "DEMOLISH should be 2")
	assert(ToolSidebar.Tool.INFO == 3, "INFO should be 3")
	assert(ToolSidebar.Tool.UPGRADE == 4, "UPGRADE should be 4")

	sidebar.free()
	_pass("get_current_tool")


func _pass(test_name: String) -> void:
	print("  ✓ " + test_name)
	_tests_passed += 1


func _fail(test_name: String, msg: String) -> void:
	print("  ✗ " + test_name + ": " + msg)
	_tests_failed += 1
