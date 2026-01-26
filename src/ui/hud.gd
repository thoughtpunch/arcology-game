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
const TOP_BAR_HEIGHT := 48
const BOTTOM_BAR_HEIGHT := 80
const LEFT_SIDEBAR_COLLAPSED := 64
const LEFT_SIDEBAR_EXPANDED := 240
const RIGHT_PANEL_WIDTH := 320

# Animation constants
const PANEL_ANIM_DURATION := 0.2

# Signals
signal left_sidebar_toggled(expanded: bool)
signal right_panel_toggled(visible: bool)

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
	viewport_margin = MarginContainer.new()
	viewport_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# Date/time display
	var datetime := Label.new()
	datetime.text = "Y1 M1 D1"
	datetime.name = "DateTimeLabel"
	datetime.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	datetime.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(datetime)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	# Speed controls
	var speed_box := HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 4)
	hbox.add_child(speed_box)

	var pause_btn := Button.new()
	pause_btn.text = "⏸"
	pause_btn.tooltip_text = "Pause (Space)"
	pause_btn.toggle_mode = true
	pause_btn.custom_minimum_size = Vector2(32, 32)
	pause_btn.name = "PauseButton"
	speed_box.add_child(pause_btn)

	var speed1_btn := Button.new()
	speed1_btn.text = "▶"
	speed1_btn.tooltip_text = "Normal speed (1)"
	speed1_btn.toggle_mode = true
	speed1_btn.button_pressed = true
	speed1_btn.custom_minimum_size = Vector2(32, 32)
	speed1_btn.name = "Speed1Button"
	speed_box.add_child(speed1_btn)

	var speed2_btn := Button.new()
	speed2_btn.text = "▶▶"
	speed2_btn.tooltip_text = "Fast (2)"
	speed2_btn.toggle_mode = true
	speed2_btn.custom_minimum_size = Vector2(40, 32)
	speed2_btn.name = "Speed2Button"
	speed_box.add_child(speed2_btn)

	var speed3_btn := Button.new()
	speed3_btn.text = "▶▶▶"
	speed3_btn.tooltip_text = "Very fast (3)"
	speed3_btn.toggle_mode = true
	speed3_btn.custom_minimum_size = Vector2(48, 32)
	speed3_btn.name = "Speed3Button"
	speed_box.add_child(speed3_btn)

	# Notification badge
	var notif_btn := Button.new()
	notif_btn.text = "🔔"
	notif_btn.tooltip_text = "Notifications"
	notif_btn.custom_minimum_size = Vector2(40, 32)
	notif_btn.name = "NotificationButton"
	hbox.add_child(notif_btn)

	return bar


func _create_left_sidebar() -> Control:
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(LEFT_SIDEBAR_COLLAPSED, 0)
	sidebar.name = "LeftSidebar"

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 8)
	sidebar.add_child(vbox)

	# Collapse/expand button
	var toggle_btn := Button.new()
	toggle_btn.text = "◀"
	toggle_btn.tooltip_text = "Expand sidebar"
	toggle_btn.custom_minimum_size = Vector2(48, 32)
	toggle_btn.name = "ToggleButton"
	toggle_btn.pressed.connect(_on_sidebar_toggle)
	vbox.add_child(toggle_btn)

	# Tool buttons (vertical)
	var tools := VBoxContainer.new()
	tools.add_theme_constant_override("separation", 4)
	vbox.add_child(tools)

	var select_btn := Button.new()
	select_btn.text = "🔍"
	select_btn.tooltip_text = "Select (S)"
	select_btn.toggle_mode = true
	select_btn.button_pressed = true
	select_btn.custom_minimum_size = Vector2(48, 48)
	select_btn.name = "SelectTool"
	tools.add_child(select_btn)

	var build_btn := Button.new()
	build_btn.text = "🔨"
	build_btn.tooltip_text = "Build (B)"
	build_btn.toggle_mode = true
	build_btn.custom_minimum_size = Vector2(48, 48)
	build_btn.name = "BuildTool"
	tools.add_child(build_btn)

	var demolish_btn := Button.new()
	demolish_btn.text = "💥"
	demolish_btn.tooltip_text = "Demolish (X)"
	demolish_btn.toggle_mode = true
	demolish_btn.custom_minimum_size = Vector2(48, 48)
	demolish_btn.name = "DemolishTool"
	tools.add_child(demolish_btn)

	var info_btn := Button.new()
	info_btn.text = "ℹ"
	info_btn.tooltip_text = "Info (I)"
	info_btn.toggle_mode = true
	info_btn.custom_minimum_size = Vector2(48, 48)
	info_btn.name = "InfoTool"
	tools.add_child(info_btn)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "⬆"
	upgrade_btn.tooltip_text = "Upgrade (U)"
	upgrade_btn.toggle_mode = true
	upgrade_btn.custom_minimum_size = Vector2(48, 48)
	upgrade_btn.name = "UpgradeTool"
	tools.add_child(upgrade_btn)

	# Spacer to push favorites down
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Quick build section (hidden when collapsed)
	var quick_label := Label.new()
	quick_label.text = "Quick Build"
	quick_label.name = "QuickBuildLabel"
	quick_label.visible = false  # Only visible when expanded
	vbox.add_child(quick_label)

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

	# Build categories
	var build_box := HBoxContainer.new()
	build_box.add_theme_constant_override("separation", 4)
	build_box.name = "BuildCategories"
	hbox.add_child(build_box)

	var categories := ["Res", "Com", "Ind", "Tra", "Grn", "Civ", "Inf"]
	var tooltips := ["Residential", "Commercial", "Industrial", "Transit", "Green", "Civic", "Infrastructure"]
	for i in range(categories.size()):
		var btn := Button.new()
		btn.text = categories[i]
		btn.tooltip_text = tooltips[i]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(50, 50)
		build_box.add_child(btn)

	# Separator
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 60)
	hbox.add_child(sep)

	# Floor navigator
	var floor_box := HBoxContainer.new()
	floor_box.add_theme_constant_override("separation", 8)
	floor_box.name = "FloorNavigator"
	hbox.add_child(floor_box)

	var floor_down := Button.new()
	floor_down.text = "▼"
	floor_down.tooltip_text = "Down (PageDown)"
	floor_down.custom_minimum_size = Vector2(40, 40)
	floor_down.name = "FloorDownButton"
	floor_box.add_child(floor_down)

	var floor_label := Label.new()
	floor_label.text = "F0"
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.custom_minimum_size = Vector2(60, 0)
	floor_label.name = "FloorLabel"
	floor_box.add_child(floor_label)

	var floor_up := Button.new()
	floor_up.text = "▲"
	floor_up.tooltip_text = "Up (PageUp)"
	floor_up.custom_minimum_size = Vector2(40, 40)
	floor_up.name = "FloorUpButton"
	floor_box.add_child(floor_up)

	# Separator
	var sep2 := VSeparator.new()
	sep2.custom_minimum_size = Vector2(2, 60)
	hbox.add_child(sep2)

	# View mode toggle
	var view_box := HBoxContainer.new()
	view_box.add_theme_constant_override("separation", 4)
	view_box.name = "ViewMode"
	hbox.add_child(view_box)

	var iso_btn := Button.new()
	iso_btn.text = "ISO"
	iso_btn.tooltip_text = "Isometric view"
	iso_btn.toggle_mode = true
	iso_btn.button_pressed = true
	iso_btn.custom_minimum_size = Vector2(50, 40)
	iso_btn.name = "IsoButton"
	view_box.add_child(iso_btn)

	var top_btn := Button.new()
	top_btn.text = "TOP"
	top_btn.tooltip_text = "Top-down view"
	top_btn.toggle_mode = true
	top_btn.custom_minimum_size = Vector2(50, 40)
	top_btn.name = "TopButton"
	view_box.add_child(top_btn)

	# Separator
	var sep3 := VSeparator.new()
	sep3.custom_minimum_size = Vector2(2, 60)
	hbox.add_child(sep3)

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


func _on_sidebar_toggle() -> void:
	_left_expanded = not _left_expanded

	# Animate width change
	var target_width := LEFT_SIDEBAR_EXPANDED if _left_expanded else LEFT_SIDEBAR_COLLAPSED
	var tween := create_tween()
	tween.tween_property(left_sidebar, "custom_minimum_size:x", target_width, PANEL_ANIM_DURATION)

	# Update toggle button
	var toggle_btn: Button = left_sidebar.get_node("VBoxContainer/ToggleButton")
	if toggle_btn:
		toggle_btn.text = "▶" if _left_expanded else "◀"
		toggle_btn.tooltip_text = "Collapse sidebar" if _left_expanded else "Expand sidebar"

	# Show/hide quick build label
	var quick_label: Label = left_sidebar.get_node_or_null("VBoxContainer/QuickBuildLabel")
	if quick_label:
		quick_label.visible = _left_expanded

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
	return _left_expanded


## Get the content area of the right panel for adding custom content
func get_right_panel_content() -> VBoxContainer:
	return right_panel.get_node_or_null("VBoxContainer/ContentArea")


## Update the floor display
func update_floor_display(floor_num: int) -> void:
	var floor_label: Label = bottom_bar.get_node_or_null("HBoxContainer/FloorNavigator/FloorLabel")
	if floor_label:
		floor_label.text = "F%d" % floor_num


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
func update_datetime(year: int, month: int, day: int) -> void:
	var datetime_label: Label = top_bar.get_node_or_null("HBoxContainer/DateTimeLabel")
	if datetime_label:
		datetime_label.text = "Y%d M%d D%d" % [year, month, day]


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
