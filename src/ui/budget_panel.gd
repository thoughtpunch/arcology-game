class_name BudgetPanel
extends InfoPanel
## Budget panel showing income, expenses, trends, and projections
## Accessed via top bar or $ key
## See: documentation/ui/info-panels.md#budget-panel

# Time range options
enum TimeRange { THREE_MONTHS, SIX_MONTHS, ONE_YEAR }

# Cached UI elements
var _balance_label: Label
var _net_label: Label
var _income_container: VBoxContainer
var _expense_container: VBoxContainer
var _trend_container: Control
var _projection_container: VBoxContainer
var _time_range_buttons: Dictionary = {}

# State
var _current_time_range := TimeRange.THREE_MONTHS
var _income_expanded := true
var _expense_expanded := true


func _init() -> void:
	super._init()


## Build the panel UI with budget data
func setup(budget_data: Dictionary) -> void:
	clear()

	# Header section (Balance and Monthly Net)
	var header_section := add_section("Header", "BUDGET")

	# Close button header
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "BUDGET"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	# Settings button
	var settings_btn := Button.new()
	settings_btn.text = "⚙"
	settings_btn.flat = true
	settings_btn.tooltip_text = "Budget settings"
	settings_btn.custom_minimum_size = Vector2(24, 24)
	header_row.add_child(settings_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.tooltip_text = "Close"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(func(): close_requested.emit())
	header_row.add_child(close_btn)

	header_section.add_child(header_row)

	# Balance
	var balance: int = budget_data.get("balance", 0)
	var balance_row := HBoxContainer.new()

	var balance_label := Label.new()
	balance_label.text = "BALANCE"
	balance_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	balance_label.custom_minimum_size = Vector2(100, 0)
	balance_row.add_child(balance_label)

	_balance_label = Label.new()
	_balance_label.text = format_money(balance)
	_balance_label.add_theme_font_size_override("font_size", 18)
	_balance_label.add_theme_color_override("font_color", COLOR_TEXT)
	_balance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance_row.add_child(_balance_label)

	header_section.add_child(balance_row)

	# Monthly Net
	var monthly_net: int = budget_data.get("monthly_net", 0)
	var net_row := HBoxContainer.new()

	var net_title := Label.new()
	net_title.text = "Monthly Net"
	net_title.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	net_title.custom_minimum_size = Vector2(100, 0)
	net_row.add_child(net_title)

	_net_label = Label.new()
	var net_prefix := "+" if monthly_net >= 0 else ""
	_net_label.text = net_prefix + format_money(monthly_net)
	_net_label.add_theme_font_size_override("font_size", 14)
	var net_color := COLOR_TEXT_POSITIVE if monthly_net >= 0 else COLOR_TEXT_NEGATIVE
	_net_label.add_theme_color_override("font_color", net_color)
	_net_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	net_row.add_child(_net_label)

	header_section.add_child(net_row)

	# Income section
	var income_section := add_section("Income", "INCOME", true)
	_income_container = income_section

	var income_data: Dictionary = budget_data.get("income", {})
	var total_income: int = budget_data.get("total_income", 0)

	# Income header with total
	var income_total := create_stat_row("Total", format_money(total_income) + "/mo", COLOR_TEXT_POSITIVE)
	income_section.add_child(income_total)

	# Income breakdown
	_add_budget_items(income_section, income_data, true)

	# Expenses section
	var expense_section := add_section("Expenses", "EXPENSES", true)
	_expense_container = expense_section

	var expense_data: Dictionary = budget_data.get("expenses", {})
	var total_expenses: int = budget_data.get("total_expenses", 0)

	# Expense header with total
	var expense_total := create_stat_row("Total", format_money(total_expenses) + "/mo", COLOR_TEXT_NEGATIVE)
	expense_section.add_child(expense_total)

	# Expense breakdown
	_add_budget_items(expense_section, expense_data, false)

	# Trends section
	var trends_section := add_section("Trends", "TRENDS")
	_trend_container = trends_section

	# Time range selector
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 4)
	time_row.alignment = BoxContainer.ALIGNMENT_END

	for range_val in [TimeRange.THREE_MONTHS, TimeRange.SIX_MONTHS, TimeRange.ONE_YEAR]:
		var btn := Button.new()
		btn.text = _get_time_range_label(range_val)
		btn.toggle_mode = true
		btn.button_pressed = (range_val == _current_time_range)
		btn.custom_minimum_size = Vector2(40, 24)
		btn.pressed.connect(_on_time_range_selected.bind(range_val))
		_time_range_buttons[range_val] = btn
		time_row.add_child(btn)

	trends_section.add_child(time_row)

	# Trend sparklines (simplified visual)
	var trend_data: Dictionary = budget_data.get("trends", {})
	_add_trend_display(trends_section, trend_data)

	# Projections section
	var proj_section := add_section("Projections", "PROJECTIONS")
	_projection_container = proj_section

	var projections: Dictionary = budget_data.get("projections", {})

	var next_month: int = projections.get("next_month", 0)
	var next_prefix: String = "+" if next_month >= 0 else ""
	var next_color: Color = COLOR_TEXT_POSITIVE if next_month >= 0 else COLOR_TEXT_NEGATIVE
	var next_row := create_stat_row("Next month", next_prefix + format_money(next_month) + " (estimate)", next_color)
	proj_section.add_child(next_row)

	var construction_pending: int = projections.get("construction_pending", 0)
	if construction_pending != 0:
		var constr_row := create_stat_row("Construction pending", format_money(-abs(construction_pending)), COLOR_TEXT_NEGATIVE)
		proj_section.add_child(constr_row)

	var loans_available: int = projections.get("loans_available", 0)
	if loans_available > 0:
		var loans_row := create_stat_row("Loans available", format_money(loans_available), COLOR_TEXT)
		proj_section.add_child(loans_row)

	# Actions
	var actions_section := add_section("Actions", "")

	var actions: Array[Dictionary] = [
		{"text": "Take Loan", "action": "take_loan", "tooltip": "Borrow money"},
		{"text": "View History", "action": "view_history", "tooltip": "View budget history"},
		{"text": "Export", "action": "export", "tooltip": "Export budget data"}
	]

	var action_bar := create_action_bar(actions)
	actions_section.add_child(action_bar)


## Add budget line items
func _add_budget_items(container: VBoxContainer, items: Dictionary, is_income: bool) -> void:
	for item_name in items:
		var amount: int = items[item_name]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Tree indicator
		var indent := Label.new()
		indent.text = "├─"
		indent.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		indent.custom_minimum_size = Vector2(20, 0)
		row.add_child(indent)

		# Item name
		var name_label := Label.new()
		name_label.text = item_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(name_label)

		# Amount
		var amount_label := Label.new()
		amount_label.text = format_money(amount)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var color := COLOR_TEXT_POSITIVE if is_income else COLOR_TEXT
		amount_label.add_theme_color_override("font_color", color)
		row.add_child(amount_label)

		container.add_child(row)


## Add trend display (simplified sparkline representation)
func _add_trend_display(container: VBoxContainer, trend_data: Dictionary) -> void:
	# Income trend
	var income_trend: Array = trend_data.get("income", [])
	if not income_trend.is_empty():
		var income_row := HBoxContainer.new()
		income_row.add_theme_constant_override("separation", 8)

		var sparkline := _create_sparkline(income_trend)
		income_row.add_child(sparkline)

		var label := Label.new()
		label.text = "Income"
		label.add_theme_color_override("font_color", COLOR_TEXT_POSITIVE)
		income_row.add_child(label)

		container.add_child(income_row)

	# Expense trend
	var expense_trend: Array = trend_data.get("expenses", [])
	if not expense_trend.is_empty():
		var expense_row := HBoxContainer.new()
		expense_row.add_theme_constant_override("separation", 8)

		var sparkline := _create_sparkline(expense_trend)
		expense_row.add_child(sparkline)

		var label := Label.new()
		label.text = "Expenses"
		label.add_theme_color_override("font_color", COLOR_TEXT_NEGATIVE)
		expense_row.add_child(label)

		container.add_child(expense_row)


## Create a simplified sparkline using block characters
func _create_sparkline(values: Array) -> Label:
	var sparkline := Label.new()
	sparkline.custom_minimum_size = Vector2(120, 0)

	if values.is_empty():
		sparkline.text = "No data"
		return sparkline

	# Normalize values and convert to block characters
	var min_val: float = 9999999.0
	var max_val: float = -9999999.0

	for v in values:
		var val: float = float(v)
		min_val = minf(min_val, val)
		max_val = maxf(max_val, val)

	var range_val := max_val - min_val
	if range_val == 0:
		range_val = 1.0

	# Unicode block characters for sparkline
	var blocks := ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

	var result := ""
	for v in values:
		var val: float = float(v)
		var normalized := (val - min_val) / range_val
		var index := int(normalized * 7.0)
		index = clampi(index, 0, 7)
		result += blocks[index]

	sparkline.text = result
	sparkline.add_theme_color_override("font_color", COLOR_TEXT)
	return sparkline


## Get time range label
func _get_time_range_label(range_val: TimeRange) -> String:
	match range_val:
		TimeRange.THREE_MONTHS:
			return "3M"
		TimeRange.SIX_MONTHS:
			return "6M"
		TimeRange.ONE_YEAR:
			return "1Y"
	return "3M"


## Handle time range selection
func _on_time_range_selected(range_val: TimeRange) -> void:
	_current_time_range = range_val

	# Update button states
	for rv in _time_range_buttons:
		var btn: Button = _time_range_buttons[rv]
		btn.button_pressed = (rv == range_val)

	# Emit signal to request trend data update
	action_pressed.emit("change_time_range")


## Update balance display
func update_balance(balance: int, monthly_net: int) -> void:
	if _balance_label:
		_balance_label.text = format_money(balance)

	if _net_label:
		var net_prefix := "+" if monthly_net >= 0 else ""
		_net_label.text = net_prefix + format_money(monthly_net)
		var net_color := COLOR_TEXT_POSITIVE if monthly_net >= 0 else COLOR_TEXT_NEGATIVE
		_net_label.add_theme_color_override("font_color", net_color)


## Get current time range selection
func get_time_range() -> TimeRange:
	return _current_time_range
