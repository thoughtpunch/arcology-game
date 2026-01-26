extends SceneTree
## Unit tests for BudgetPanel
## Tests budget display, income/expenses, trends, projections

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== BudgetPanel Unit Tests ===")

	# Setup tests
	_test_setup_basic()
	_test_setup_with_full_data()

	# Section tests
	_test_has_header_section()
	_test_has_income_section()
	_test_has_expenses_section()
	_test_has_trends_section()
	_test_has_projections_section()
	_test_has_actions_section()

	# Update tests
	_test_update_balance()

	# Time range tests
	_test_get_time_range()
	_test_time_range_default()

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
	var panel := BudgetPanel.new()
	panel.setup({})

	_assert(panel.get_child_count() > 0, "basic setup creates children")
	panel.free()


func _test_setup_with_full_data() -> void:
	var panel := BudgetPanel.new()
	var data := {
		"balance": 124500,
		"monthly_net": 2400,
		"total_income": 18200,
		"income": {
			"Residential Rent": 12400,
			"Commercial Rent": 4200,
			"Industrial Lease": 1200,
			"Permits & Fees": 400
		},
		"total_expenses": 15800,
		"expenses": {
			"Maintenance": 4200,
			"Utilities": 3800,
			"Staff Wages": 5200,
			"Security": 1800,
			"Debt Service": 800
		},
		"trends": {
			"income": [10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000],
			"expenses": [8000, 8500, 9000, 9500, 10000, 11000, 12000, 13000, 14000]
		},
		"projections": {
			"next_month": 2600,
			"construction_pending": 12000,
			"loans_available": 50000
		}
	}
	panel.setup(data)

	_assert(panel.get_child_count() > 0, "full data creates complete panel")
	panel.free()


# Section tests

func _test_has_header_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({"balance": 100000, "monthly_net": 1000})

	var header_section := panel.get_section("Header")
	_assert(header_section != null, "has Header section")
	panel.free()


func _test_has_income_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({"income": {"Rent": 5000}})

	var income_section := panel.get_section("Income")
	_assert(income_section != null, "has Income section")
	panel.free()


func _test_has_expenses_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({"expenses": {"Utilities": 1000}})

	var expense_section := panel.get_section("Expenses")
	_assert(expense_section != null, "has Expenses section")
	panel.free()


func _test_has_trends_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({})

	var trends_section := panel.get_section("Trends")
	_assert(trends_section != null, "has Trends section")
	panel.free()


func _test_has_projections_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({"projections": {"next_month": 1000}})

	var proj_section := panel.get_section("Projections")
	_assert(proj_section != null, "has Projections section")
	panel.free()


func _test_has_actions_section() -> void:
	var panel := BudgetPanel.new()
	panel.setup({})

	var actions_section := panel.get_section("Actions")
	_assert(actions_section != null, "has Actions section")
	panel.free()


# Update tests

func _test_update_balance() -> void:
	var panel := BudgetPanel.new()
	panel.setup({"balance": 100000, "monthly_net": 1000})

	# Should not crash
	panel.update_balance(150000, 2000)
	panel.update_balance(50000, -500)

	_assert(true, "update_balance completes without error")
	panel.free()


# Time range tests

func _test_get_time_range() -> void:
	var panel := BudgetPanel.new()
	panel.setup({})

	var range := panel.get_time_range()
	_assert(range == BudgetPanel.TimeRange.THREE_MONTHS or
			range == BudgetPanel.TimeRange.SIX_MONTHS or
			range == BudgetPanel.TimeRange.ONE_YEAR,
			"get_time_range returns valid TimeRange")
	panel.free()


func _test_time_range_default() -> void:
	var panel := BudgetPanel.new()
	panel.setup({})

	_assert(panel.get_time_range() == BudgetPanel.TimeRange.THREE_MONTHS,
			"default time range is THREE_MONTHS")
	panel.free()
