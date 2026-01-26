class_name HUD
extends Control
## Main HUD layout container
## Manages screen regions: top bar, left sidebar, right panel, bottom bar
## See: documentation/ui/hud-layout.md

# Color scheme constants (from documentation)
const COLOR_TOP_BAR := Color("#1a1a2e")
const COLOR_SIDEBAR := Color("#16213e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")
const COLOR_ACCENT := Color("#e94560")

# Size constants
const TOP_BAR_HEIGHT := 40
const BOTTOM_BAR_HEIGHT := 64
const LEFT_SIDEBAR_COLLAPSED := 56
const LEFT_SIDEBAR_EXPANDED := 200
const RIGHT_PANEL_WIDTH := 280

# Animation constants
const PANEL_ANIM_DURATION := 0.2

# Signals
signal left_sidebar_toggled(expanded: bool)
signal right_panel_toggled(visible: bool)
signal viewport_clicked(event: InputEventMouseButton)

# UI components
var top_bar: Control
var left_sidebar: Control
var right_panel: Control
var bottom_bar: Control
var viewport_margin: MarginContainer

# State
var _left_expanded := false
var _right_visible := false


func _ready() -> void:
	_setup_layout()
	_apply_theme()


func _setup_layout() -> void:
	# Full screen - use both anchors AND offsets for proper sizing
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Main vertical container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Top bar
	top_bar = _create_top_bar()
	vbox.add_child(top_bar)

	# Middle section (sidebar + viewport + panel)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(middle)

	# Left sidebar
	left_sidebar = _create_left_sidebar()
	middle.add_child(left_sidebar)

	# Central viewport spacer (game renders underneath)
	# This Control captures clicks in the game area and emits a signal
	viewport_margin = MarginContainer.new()
	viewport_margin.name = "ViewportMargin"
	viewport_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Use PASS to receive events but also let them through to _unhandled_input
	viewport_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	viewport_margin.gui_input.connect(_on_viewport_input)
	middle.add_child(viewport_margin)

	# Right panel
	right_panel = _create_right_panel()
	right_panel.visible = false  # Hidden by default
	middle.add_child(right_panel)

	# Bottom bar
	bottom_bar = _create_bottom_bar()
	vbox.add_child(bottom_bar)


func _create_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, TOP_BAR_HEIGHT)
	bar.name = "TopBar"

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 16)
	bar.add_child(hbox)

	# Menu button (left)
	var menu_btn := Button.new()
	menu_btn.text = "≡"
	menu_btn.tooltip_text = "Menu (Esc)"
	menu_btn.custom_minimum_size = Vector2(40, 32)
	menu_btn.name = "MenuButton"
	hbox.add_child(menu_btn)

	# Resources display
	var resources := HBoxContainer.new()
	resources.name = "Resources"
	resources.add_theme_constant_override("separation", 24)
	hbox.add_child(resources)

	var money_label := Label.new()
	money_label.text = "$124,500"
	money_label.name = "MoneyLabel"
	resources.add_child(money_label)

	var pop_label := Label.new()
	pop_label.text = "Pop: 0"
	pop_label.name = "PopLabel"
	resources.add_child(pop_label)

	var aei_label := Label.new()
	aei_label.text = "AEI: 0"
	aei_label.name = "AEILabel"
	resources.add_child(aei_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Time controls (date/time display + speed controls)
	var time_controls := TimeControls.new()
	time_controls.name = "TimeControls"
	hbox.add_child(time_controls)

	# Notification tray
	var notif_tray := NotificationTray.new()
	notif_tray.name = "NotificationTray"
	hbox.add_child(notif_tray)

	return bar


func _create_left_sidebar() -> Control:
	# Use ToolSidebar component with full functionality
	var sidebar := ToolSidebar.new()
	sidebar.name = "LeftSidebar"
	return sidebar


func _create_right_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(RIGHT_PANEL_WIDTH, 0)
	panel.name = "RightPanel"

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Panel header
	var header := HBoxContainer.new()
	header.name = "HBoxContainer"
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Info"
	title.name = "PanelTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.tooltip_text = "Close panel"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.name = "CloseButton"
	close_btn.pressed.connect(_on_right_panel_close)
	header.add_child(close_btn)

	# Content area
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.name = "ContentArea"
	vbox.add_child(content)

	# Placeholder content
	var placeholder := Label.new()
	placeholder.text = "Select a block or resident\nto see details here."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.name = "Placeholder"
	content.add_child(placeholder)

	return panel


func _create_bottom_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, BOTTOM_BAR_HEIGHT)
	bar.name = "BottomBar"

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	# Note: Build categories are handled by BuildToolbar (added in main.gd)
	# This avoids duplicate buttons

	# Floor navigator (using FloorNavigator component)
	var floor_navigator := FloorNavigator.new()
	floor_navigator.name = "FloorNavigator"
	hbox.add_child(floor_navigator)

	# Separator
	var sep2 := VSeparator.new()
	sep2.custom_minimum_size = Vector2(2, 60)
	hbox.add_child(sep2)

	# Overlay buttons
	var overlay_btn := Button.new()
	overlay_btn.text = "Overlays ▼"
	overlay_btn.tooltip_text = "Toggle overlays (O)"
	overlay_btn.custom_minimum_size = Vector2(100, 40)
	overlay_btn.name = "OverlaysButton"
	hbox.add_child(overlay_btn)

	return bar


func _apply_theme() -> void:
	# Apply color scheme to all panels
	_style_panel(top_bar, COLOR_TOP_BAR)
	_style_panel(left_sidebar, COLOR_SIDEBAR, COLOR_PANEL_BORDER)
	_style_panel(right_panel, COLOR_SIDEBAR, COLOR_PANEL_BORDER)
	_style_panel(bottom_bar, COLOR_TOP_BAR)


func _style_panel(panel: Control, bg_color: Color, border_color: Color = Color.TRANSPARENT) -> void:
	if panel is PanelContainer:
		var style := StyleBoxFlat.new()
		style.bg_color = bg_color
		if border_color != Color.TRANSPARENT:
			style.border_color = border_color
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)


func _on_viewport_input(event: InputEvent) -> void:
	# Forward mouse clicks in the game viewport area
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		# Only forward press events, not release
		if mouse_event.pressed:
			viewport_clicked.emit(mouse_event)
			# Mark as handled so _unhandled_input doesn't also process it
			viewport_margin.accept_event()


func _on_sidebar_toggle() -> void:
	# ToolSidebar handles its own expand/collapse
	if left_sidebar is ToolSidebar:
		var tool_sidebar: ToolSidebar = left_sidebar
		if tool_sidebar.is_expanded():
			tool_sidebar.collapse()
		else:
			tool_sidebar.expand()
		_left_expanded = tool_sidebar.is_expanded()
	else:
		_left_expanded = not _left_expanded

	left_sidebar_toggled.emit(_left_expanded)


func _on_right_panel_close() -> void:
	hide_right_panel()


## Show the right panel with optional title
func show_right_panel(title: String = "Info") -> void:
	_right_visible = true
	right_panel.visible = true

	var title_label: Label = right_panel.get_node_or_null("VBoxContainer/HBoxContainer/PanelTitle")
	if title_label:
		title_label.text = title

	# Animate in
	right_panel.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(right_panel, "modulate:a", 1.0, PANEL_ANIM_DURATION)

	right_panel_toggled.emit(true)


## Hide the right panel
func hide_right_panel() -> void:
	_right_visible = false

	# Animate out
	var tween := create_tween()
	tween.tween_property(right_panel, "modulate:a", 0.0, PANEL_ANIM_DURATION)
	tween.tween_callback(func(): right_panel.visible = false)

	right_panel_toggled.emit(false)


## Toggle left sidebar expanded state
func toggle_left_sidebar() -> void:
	_on_sidebar_toggle()


## Check if right panel is visible
func is_right_panel_visible() -> bool:
	return _right_visible


## Check if left sidebar is expanded
func is_left_sidebar_expanded() -> bool:
	if left_sidebar is ToolSidebar:
		return (left_sidebar as ToolSidebar).is_expanded()
	return _left_expanded


## Get the content area of the right panel for adding custom content
func get_right_panel_content() -> VBoxContainer:
	return right_panel.get_node_or_null("VBoxContainer/ContentArea")


## Update the floor display
func update_floor_display(floor_num: int) -> void:
	var floor_navigator: FloorNavigator = bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator")
	if floor_navigator:
		floor_navigator.update_display(floor_num)


## Update resources display
func update_resources(money: int, population: int, aei: int) -> void:
	var money_label: Label = top_bar.get_node_or_null("HBoxContainer/Resources/MoneyLabel")
	if money_label:
		money_label.text = "$%s" % _format_number(money)

	var pop_label: Label = top_bar.get_node_or_null("HBoxContainer/Resources/PopLabel")
	if pop_label:
		pop_label.text = "Pop: %s" % _format_number(population)

	var aei_label: Label = top_bar.get_node_or_null("HBoxContainer/Resources/AEILabel")
	if aei_label:
		aei_label.text = "AEI: %d" % aei


## Update date/time display
func update_datetime(year: int, month: int, day: int, hour: int = 8) -> void:
	var time_controls: TimeControls = top_bar.get_node_or_null("HBoxContainer/TimeControls")
	if time_controls:
		time_controls.update_display(year, month, day, hour)


## Format large numbers with commas
func _format_number(num: int) -> String:
	var s := str(abs(num))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" if num < 0 else "") + result
