class_name InfoPanelManager
extends Node
## Manages info panels in the HUD right sidebar
## Handles opening/closing panels, pinning, and selection
## See: documentation/ui/info-panels.md#panel-behavior

signal panel_opened(panel_type: String)
signal panel_closed(panel_type: String)
signal block_action(action: String, block_pos: Vector3i)
signal resident_action(action: String, resident_id: String)
signal budget_action(action: String)
signal aei_action(action: String)

# Panel types
enum PanelType { NONE, BLOCK, RESIDENT, BUDGET, AEI, MULTI_SELECT, QUICK_STATS }

# Maximum pinned panels
const MAX_PINNED := 3

# References
var _hud: HUD
var _content_area: VBoxContainer

# State
var _current_panel: InfoPanel
var _current_panel_type := PanelType.NONE
var _pinned_panels: Array[InfoPanel] = []

# Panel data (for refreshing)
var _current_block_pos: Vector3i
var _current_block_type: String
var _current_resident_id: String


func _ready() -> void:
	pass


## Initialize with HUD reference
func setup(hud: HUD) -> void:
	_hud = hud
	_content_area = hud.get_right_panel_content()


## Show block info panel
func show_block_info(block_pos: Vector3i, block_type: String, block_data: Dictionary = {}) -> void:
	_clear_current_panel()

	_current_block_pos = block_pos
	_current_block_type = block_type

	var panel := BlockInfoPanel.new()
	panel.setup(block_pos, block_type, block_data)

	_setup_panel(panel, PanelType.BLOCK, "Block Info")

	# Connect to actions
	panel.action_pressed.connect(_on_block_action)


## Show resident info panel
func show_resident_info(resident_id: String, resident_data: Dictionary) -> void:
	_clear_current_panel()

	_current_resident_id = resident_id

	var panel := ResidentInfoPanel.new()
	panel.setup(resident_id, resident_data)

	_setup_panel(panel, PanelType.RESIDENT, "Resident Info")

	# Connect to actions
	panel.action_pressed.connect(_on_resident_action)


## Show budget panel
func show_budget(budget_data: Dictionary) -> void:
	_clear_current_panel()

	var panel := BudgetPanel.new()
	panel.setup(budget_data)

	_setup_panel(panel, PanelType.BUDGET, "Budget")

	# Connect to actions
	panel.action_pressed.connect(_on_budget_action)


## Show AEI dashboard
func show_aei(aei_data: Dictionary) -> void:
	_clear_current_panel()

	var panel := AEIDashboard.new()
	panel.setup(aei_data)

	_setup_panel(panel, PanelType.AEI, "AEI Dashboard")

	# Connect to actions
	panel.action_pressed.connect(_on_aei_action)


## Show quick stats (empty state)
func show_quick_stats(stats_data: Dictionary) -> void:
	_clear_current_panel()

	var panel := InfoPanel.new()

	# Quick Stats section
	var stats_section := panel.add_section("QuickStats", "QUICK STATS")

	var population: int = stats_data.get("population", 0)
	var avg_flourishing: float = stats_data.get("avg_flourishing", 0.0)
	var monthly_net: int = stats_data.get("monthly_net", 0)
	var aei_score: float = stats_data.get("aei_score", 0.0)

	stats_section.add_child(panel.create_stat_row("Population", panel.format_number(population)))
	stats_section.add_child(panel.create_stat_row("Avg Flourishing", "%d" % int(avg_flourishing)))

	var net_color := (
		InfoPanel.COLOR_TEXT_POSITIVE if monthly_net >= 0 else InfoPanel.COLOR_TEXT_NEGATIVE
	)
	var net_prefix := "+" if monthly_net >= 0 else ""
	stats_section.add_child(
		panel.create_stat_row(
			"Monthly Net", net_prefix + panel.format_money(monthly_net), net_color
		)
	)

	stats_section.add_child(panel.create_stat_row("AEI Score", "%d" % int(aei_score)))

	# Alerts section
	var alerts: Array = stats_data.get("alerts", [])
	if not alerts.is_empty():
		var alerts_section := panel.add_section("Alerts", "ALERTS")

		for alert in alerts:
			var alert_row := HBoxContainer.new()
			alert_row.add_theme_constant_override("separation", 8)

			var icon := Label.new()
			icon.text = "⚠"
			icon.add_theme_color_override("font_color", InfoPanel.COLOR_TEXT_NEGATIVE)
			alert_row.add_child(icon)

			var text := Label.new()
			text.text = alert.get("message", "Unknown alert")
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			alert_row.add_child(text)

			alerts_section.add_child(alert_row)

	# Instruction
	var instruction_section := panel.add_section("Instruction", "")

	var instruction := Label.new()
	instruction.text = "Click any block or resident\nto see detailed information."
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_color_override("font_color", InfoPanel.COLOR_TEXT_SECONDARY)
	instruction_section.add_child(instruction)

	_setup_panel(panel, PanelType.QUICK_STATS, "Quick Stats")


## Setup common panel behavior
func _setup_panel(panel: InfoPanel, panel_type: PanelType, title: String) -> void:
	if not _content_area:
		push_warning("InfoPanelManager: No content area available")
		return

	_current_panel = panel
	_current_panel_type = panel_type

	# Add to content area
	_content_area.add_child(panel)

	# Connect signals
	panel.close_requested.connect(_on_panel_close_requested)
	panel.pin_toggled.connect(_on_panel_pin_toggled)

	# Show the right panel
	if _hud:
		_hud.show_right_panel(title)

	panel_opened.emit(_get_panel_type_name(panel_type))


## Clear current non-pinned panel
func _clear_current_panel() -> void:
	if _current_panel and not _current_panel.is_pinned():
		_current_panel.queue_free()
		_current_panel = null
		_current_panel_type = PanelType.NONE


## Close the current panel
func close_current_panel() -> void:
	if _current_panel:
		var panel_type_name := _get_panel_type_name(_current_panel_type)
		_current_panel.queue_free()
		_current_panel = null
		_current_panel_type = PanelType.NONE

		# Hide right panel if no pinned panels
		if _pinned_panels.is_empty() and _hud:
			_hud.hide_right_panel()

		panel_closed.emit(panel_type_name)


## Handle close request from panel
func _on_panel_close_requested() -> void:
	close_current_panel()


## Handle pin toggle from panel
func _on_panel_pin_toggled(pinned: bool) -> void:
	if not _current_panel:
		return

	if pinned:
		if _pinned_panels.size() >= MAX_PINNED:
			# Unpin oldest
			var oldest := _pinned_panels[0]
			oldest.set_pinned(false)
			_pinned_panels.remove_at(0)

		_pinned_panels.append(_current_panel)
	else:
		var idx := _pinned_panels.find(_current_panel)
		if idx >= 0:
			_pinned_panels.remove_at(idx)


## Handle block action
func _on_block_action(action: String) -> void:
	block_action.emit(action, _current_block_pos)


## Handle resident action
func _on_resident_action(action: String) -> void:
	resident_action.emit(action, _current_resident_id)


## Handle budget action
func _on_budget_action(action: String) -> void:
	budget_action.emit(action)


## Handle AEI action
func _on_aei_action(action: String) -> void:
	aei_action.emit(action)


## Get panel type name
func _get_panel_type_name(panel_type: PanelType) -> String:
	match panel_type:
		PanelType.BLOCK:
			return "block"
		PanelType.RESIDENT:
			return "resident"
		PanelType.BUDGET:
			return "budget"
		PanelType.AEI:
			return "aei"
		PanelType.MULTI_SELECT:
			return "multi_select"
		PanelType.QUICK_STATS:
			return "quick_stats"
	return "none"


## Check if a panel is currently open
func is_panel_open() -> bool:
	return _current_panel != null


## Get current panel type
func get_current_panel_type() -> PanelType:
	return _current_panel_type


## Update current block panel with new data
func update_block_environment(env_data: Dictionary) -> void:
	if _current_panel is BlockInfoPanel:
		_current_panel.update_environment(env_data)


## Update current block panel economics
func update_block_economics(econ_data: Dictionary) -> void:
	if _current_panel is BlockInfoPanel:
		_current_panel.update_economics(econ_data)


## Update current resident panel needs
func update_resident_needs(needs: Dictionary) -> void:
	if _current_panel is ResidentInfoPanel:
		_current_panel.update_needs(needs)


## Update current resident flourishing
func update_resident_flourishing(value: float, trend: String = "stable") -> void:
	if _current_panel is ResidentInfoPanel:
		_current_panel.update_flourishing(value, trend)


## Update budget balance
func update_budget_balance(balance: int, monthly_net: int) -> void:
	if _current_panel is BudgetPanel:
		_current_panel.update_balance(balance, monthly_net)


## Update AEI overall score
func update_aei_overall(score: float) -> void:
	if _current_panel is AEIDashboard:
		_current_panel.update_overall(score)


## Update AEI components
func update_aei_components(components: Dictionary) -> void:
	if _current_panel is AEIDashboard:
		_current_panel.update_components(components)


## Handle keyboard shortcuts
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if is_panel_open():
					close_current_panel()
					get_viewport().set_input_as_handled()
			KEY_DOLLAR, KEY_4:  # $ key or Shift+4
				if event.shift_pressed or event.keycode == KEY_DOLLAR:
					# Show budget panel (placeholder data for now)
					show_budget({})
					get_viewport().set_input_as_handled()
			KEY_Y:
				# Show AEI dashboard (placeholder data for now)
				show_aei({})
				get_viewport().set_input_as_handled()
