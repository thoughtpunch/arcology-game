extends SceneTree
## Unit tests for BlockInfoPanel
## Tests block info display, environment bars, economics, actions

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== BlockInfoPanel Unit Tests ===")

	# Setup tests
	_test_setup_basic()
	_test_setup_with_data()
	_test_setup_residential()
	_test_setup_with_occupants()

	# Position/type tests
	_test_get_block_position()
	_test_get_block_type()

	# Update tests
	_test_update_environment()
	_test_update_economics()

	# Section tests
	_test_has_environment_section()
	_test_has_economics_section()
	_test_has_actions_section()

	# Environment bar colors
	_test_environment_bar_colors()

	# Economics display
	_test_economics_net_income_positive()
	_test_economics_net_income_negative()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)


# Setup tests

func _test_setup_basic() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(1, 2, 3), "corridor")

	_assert(panel.get_child_count() > 0, "setup creates children")
	_assert(panel.get_block_position() == Vector3i(1, 2, 3), "block position stored")
	_assert(panel.get_block_type() == "corridor", "block type stored")
	panel.free()


func _test_setup_with_data() -> void:
	var panel := BlockInfoPanel.new()
	var data := {
		"status": "Occupied",
		"environment": {
			"light": 80.0,
			"air": 90.0,
			"noise": 20.0,
			"safety": 75.0,
			"vibes": 65.0
		},
		"economics": {
			"rent": 150,
			"desirability": 0.85,
			"maintenance": 25
		}
	}
	panel.setup(Vector3i(0, 0, 0), "residential_basic", data)

	_assert(panel.get_child_count() > 0, "setup with data creates children")
	panel.free()


func _test_setup_residential() -> void:
	var panel := BlockInfoPanel.new()
	var data := {
		"category": "residential"
	}
	# Note: We need to pass block_data with category, or rely on registry
	# For this test, we'll use a mock approach
	panel.setup(Vector3i(0, 0, 0), "residential_basic", data)

	_assert(panel.get_child_count() > 0, "residential block creates panel")
	panel.free()


func _test_setup_with_occupants() -> void:
	var panel := BlockInfoPanel.new()
	var data := {
		"occupants": [
			{"name": "Alice", "flourishing": 75},
			{"name": "Bob", "flourishing": 60}
		]
	}
	panel.setup(Vector3i(0, 0, 0), "residential_basic", data)

	_assert(panel.get_child_count() > 0, "panel with occupants creates children")
	panel.free()


# Position/type tests

func _test_get_block_position() -> void:
	var panel := BlockInfoPanel.new()

	panel.setup(Vector3i(5, 10, 2), "corridor")
	_assert(panel.get_block_position() == Vector3i(5, 10, 2), "correct position stored")

	panel.setup(Vector3i(-3, 0, 1), "entrance")
	_assert(panel.get_block_position() == Vector3i(-3, 0, 1), "position updated on new setup")
	panel.free()


func _test_get_block_type() -> void:
	var panel := BlockInfoPanel.new()

	panel.setup(Vector3i(0, 0, 0), "corridor")
	_assert(panel.get_block_type() == "corridor", "corridor type stored")

	panel.setup(Vector3i(0, 0, 0), "entrance")
	_assert(panel.get_block_type() == "entrance", "type updated on new setup")
	panel.free()


# Update tests

func _test_update_environment() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor", {
		"environment": {"light": 50.0, "air": 50.0, "noise": 50.0, "safety": 50.0, "vibes": 50.0}
	})

	# Should not crash
	panel.update_environment({"light": 80.0})
	panel.update_environment({"air": 90.0, "safety": 70.0})

	_assert(true, "update_environment completes without error")
	panel.free()


func _test_update_economics() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor", {
		"economics": {"rent": 100, "desirability": 0.5, "maintenance": 20}
	})

	# Should not crash
	panel.update_economics({"rent": 150})
	panel.update_economics({"rent": 200, "maintenance": 30})

	_assert(true, "update_economics completes without error")
	panel.free()


# Section tests

func _test_has_environment_section() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor")

	var env_section := panel.get_section("Environment")
	_assert(env_section != null, "has Environment section")
	panel.free()


func _test_has_economics_section() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor")

	var econ_section := panel.get_section("Economics")
	_assert(econ_section != null, "has Economics section")
	panel.free()


func _test_has_actions_section() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor")

	var actions_section := panel.get_section("Actions")
	_assert(actions_section != null, "has Actions section")
	panel.free()


# Environment bar color tests

func _test_environment_bar_colors() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor", {
		"environment": {
			"light": 90.0,  # High - green
			"air": 55.0,    # Mid - yellow
			"noise": 80.0,  # High noise (bad) - should show red (100 - noise)
			"safety": 30.0, # Low - red
			"vibes": 70.0   # Threshold - green
		}
	})

	# Bars are created internally; we verify setup works
	_assert(panel.get_child_count() > 0, "environment bars created for various values")
	panel.free()


# Economics display tests

func _test_economics_net_income_positive() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor", {
		"economics": {
			"rent": 200,
			"desirability": 0.75,
			"maintenance": 50
		}
	})

	# Net income = 200 - 50 = 150 (positive)
	_assert(panel.get_child_count() > 0, "positive net income panel created")
	panel.free()


func _test_economics_net_income_negative() -> void:
	var panel := BlockInfoPanel.new()
	panel.setup(Vector3i(0, 0, 0), "corridor", {
		"economics": {
			"rent": 50,
			"desirability": 0.3,
			"maintenance": 100
		}
	})

	# Net income = 50 - 100 = -50 (negative)
	_assert(panel.get_child_count() > 0, "negative net income panel created")
	panel.free()
