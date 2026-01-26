extends SceneTree
## Unit tests for InfoPanel base class
## Tests common functionality: sections, bars, stats, headers, formatting

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== InfoPanel Unit Tests ===")

	# Section tests
	_test_add_section()
	_test_add_section_with_title()
	_test_add_section_collapsible()
	_test_get_section()
	_test_multiple_sections()

	# Bar tests
	_test_create_bar()
	_test_create_bar_colors()
	_test_update_bar()
	_test_get_bar_color_by_value()

	# Stat row tests
	_test_create_stat_row()
	_test_create_stat_row_with_color()

	# Action tests
	_test_create_action_button()
	_test_create_action_bar()

	# Header tests
	_test_create_header()
	_test_create_header_with_pin()

	# Formatting tests
	_test_format_money_positive()
	_test_format_money_negative()
	_test_format_money_zero()
	_test_format_number()
	_test_format_number_large()

	# State tests
	_test_pin_state()
	_test_clear()

	# Status color tests
	_test_get_status_color()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)


# Section tests

func _test_add_section() -> void:
	var panel := InfoPanel.new()
	var section := panel.add_section("TestSection")

	_assert(section != null, "add_section returns VBoxContainer")
	_assert(section is VBoxContainer, "section is VBoxContainer")
	_assert(panel.get_child_count() > 0, "panel has children after add_section")
	panel.free()


func _test_add_section_with_title() -> void:
	var panel := InfoPanel.new()
	var section := panel.add_section("TestSection", "Test Title")

	_assert(section != null, "add_section with title returns VBoxContainer")
	panel.free()


func _test_add_section_collapsible() -> void:
	var panel := InfoPanel.new()
	var section := panel.add_section("TestSection", "Test Title", true)

	_assert(section != null, "add_section collapsible returns VBoxContainer")
	panel.free()


func _test_get_section() -> void:
	var panel := InfoPanel.new()
	panel.add_section("MySection")
	var section := panel.get_section("MySection")

	_assert(section != null, "get_section returns stored section")
	_assert(panel.get_section("NonExistent") == null, "get_section returns null for missing")
	panel.free()


func _test_multiple_sections() -> void:
	var panel := InfoPanel.new()
	var sec1 := panel.add_section("Section1", "First")
	var sec2 := panel.add_section("Section2", "Second")
	var sec3 := panel.add_section("Section3", "Third")

	_assert(sec1 != sec2, "multiple sections are distinct")
	_assert(panel.get_section("Section1") != null, "first section retrievable")
	_assert(panel.get_section("Section2") != null, "second section retrievable")
	_assert(panel.get_section("Section3") != null, "third section retrievable")
	panel.free()


# Bar tests

func _test_create_bar() -> void:
	var panel := InfoPanel.new()
	var bar := panel.create_bar("Test", 50.0)

	_assert(bar != null, "create_bar returns HBoxContainer")
	_assert(bar is HBoxContainer, "bar is HBoxContainer")
	_assert(bar.get_child_count() >= 3, "bar has label, bar, value")
	panel.free()


func _test_create_bar_colors() -> void:
	var panel := InfoPanel.new()
	var bar := panel.create_bar("Test", 50.0, 100.0, Color.RED)

	_assert(bar != null, "create_bar with custom color returns HBoxContainer")
	panel.free()


func _test_update_bar() -> void:
	var panel := InfoPanel.new()
	var bar := panel.create_bar("Test", 50.0)

	# Should not crash
	panel.update_bar(bar, 75.0)
	panel.update_bar(bar, 100.0, 100.0, Color.GREEN)

	_assert(true, "update_bar completes without error")
	panel.free()


func _test_get_bar_color_by_value() -> void:
	var panel := InfoPanel.new()

	var high := panel.get_bar_color_by_value(80.0)
	var mid := panel.get_bar_color_by_value(55.0)
	var low := panel.get_bar_color_by_value(20.0)

	_assert(high == InfoPanel.COLOR_BAR_FILL_GREEN, "high value returns green")
	_assert(mid == InfoPanel.COLOR_BAR_FILL_YELLOW, "mid value returns yellow")
	_assert(low == InfoPanel.COLOR_BAR_FILL_RED, "low value returns red")
	panel.free()


# Stat row tests

func _test_create_stat_row() -> void:
	var panel := InfoPanel.new()
	var row := panel.create_stat_row("Label", "Value")

	_assert(row != null, "create_stat_row returns HBoxContainer")
	_assert(row is HBoxContainer, "row is HBoxContainer")
	_assert(row.get_child_count() >= 2, "row has label and value")
	panel.free()


func _test_create_stat_row_with_color() -> void:
	var panel := InfoPanel.new()
	var row := panel.create_stat_row("Label", "Value", Color.CYAN)

	_assert(row != null, "create_stat_row with color returns HBoxContainer")
	panel.free()


# Action tests

func _test_create_action_button() -> void:
	var panel := InfoPanel.new()
	var btn := panel.create_action_button("Click Me", "click_action", "Tooltip")

	_assert(btn != null, "create_action_button returns Button")
	_assert(btn is Button, "btn is Button")
	_assert(btn.text == "Click Me", "button has correct text")
	panel.free()


func _test_create_action_bar() -> void:
	var panel := InfoPanel.new()
	var actions: Array[Dictionary] = [
		{"text": "A", "action": "a"},
		{"text": "B", "action": "b"}
	]
	var bar := panel.create_action_bar(actions)

	_assert(bar != null, "create_action_bar returns HBoxContainer")
	_assert(bar.get_child_count() == 2, "bar has 2 buttons")
	panel.free()


# Header tests

func _test_create_header() -> void:
	var panel := InfoPanel.new()
	var header := panel.create_header(null, "Title", "Subtitle", false, false)

	_assert(header != null, "create_header returns Control")
	_assert(header is HBoxContainer, "header is HBoxContainer")
	panel.free()


func _test_create_header_with_pin() -> void:
	var panel := InfoPanel.new()
	var header := panel.create_header(null, "Title", "Subtitle", true, true)

	_assert(header != null, "create_header with pin/close returns Control")
	_assert(header.get_child_count() >= 3, "header has info, pin, close")
	panel.free()


# Formatting tests

func _test_format_money_positive() -> void:
	var panel := InfoPanel.new()

	_assert(panel.format_money(100) == "$100", "format 100 as $100")
	_assert(panel.format_money(1234) == "$1,234", "format 1234 with comma")
	_assert(panel.format_money(1234567) == "$1,234,567", "format millions")
	panel.free()


func _test_format_money_negative() -> void:
	var panel := InfoPanel.new()

	_assert(panel.format_money(-100) == "-$100", "format -100 as -$100")
	_assert(panel.format_money(-1234) == "-$1,234", "format -1234 with comma")
	panel.free()


func _test_format_money_zero() -> void:
	var panel := InfoPanel.new()

	_assert(panel.format_money(0) == "$0", "format 0 as $0")
	panel.free()


func _test_format_number() -> void:
	var panel := InfoPanel.new()

	_assert(panel.format_number(0) == "0", "format 0")
	_assert(panel.format_number(100) == "100", "format 100")
	_assert(panel.format_number(1234) == "1,234", "format 1234")
	panel.free()


func _test_format_number_large() -> void:
	var panel := InfoPanel.new()

	_assert(panel.format_number(1000000) == "1,000,000", "format million")
	_assert(panel.format_number(-1000000) == "-1,000,000", "format negative million")
	panel.free()


# State tests

func _test_pin_state() -> void:
	var panel := InfoPanel.new()

	_assert(panel.is_pinned() == false, "initially not pinned")

	panel.set_pinned(true)
	_assert(panel.is_pinned() == true, "pinned after set_pinned(true)")

	panel.set_pinned(false)
	_assert(panel.is_pinned() == false, "unpinned after set_pinned(false)")
	panel.free()


func _test_clear() -> void:
	var panel := InfoPanel.new()
	panel.add_section("Section1")
	panel.add_section("Section2")

	panel.clear()

	# Note: queue_free() schedules removal for end of frame, so children still exist
	# but are marked for deletion. The section cache should be cleared immediately.
	_assert(panel.get_section("Section1") == null, "clear clears section cache for Section1")
	_assert(panel.get_section("Section2") == null, "clear clears section cache for Section2")
	panel.free()


# Status color tests

func _test_get_status_color() -> void:
	var panel := InfoPanel.new()

	_assert(panel.get_status_color("occupied") == InfoPanel.STATUS_OCCUPIED, "occupied status color")
	_assert(panel.get_status_color("vacant") == InfoPanel.STATUS_VACANT, "vacant status color")
	_assert(panel.get_status_color("under construction") == InfoPanel.STATUS_CONSTRUCTION, "construction status color")
	_assert(panel.get_status_color("damaged") == InfoPanel.STATUS_DAMAGED, "damaged status color")
	_assert(panel.get_status_color("condemned") == InfoPanel.STATUS_CONDEMNED, "condemned status color")
	_assert(panel.get_status_color("unknown") == InfoPanel.COLOR_TEXT, "unknown status returns default")
	panel.free()
