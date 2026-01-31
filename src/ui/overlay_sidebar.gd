class_name OverlaySidebar
extends Control
## Right-side overlay toggle panel for data visualization layers
## Provides collapsed icon strip and expanded view with labels and legend
## See: documentation/ui/sidebars.md

signal overlay_changed(overlay_type: int)
signal expanded_changed(is_expanded: bool)

# Overlay types enum for type safety
enum OverlayType {
	NONE, LIGHT, AIR_QUALITY, NOISE, SAFETY, VIBES, CONNECTIVITY, BLOCK_TYPE, FOOT_TRAFFIC
}

# Overlay configuration
const OVERLAY_CONFIG := {
	OverlayType.NONE: {"name": "None", "icon": "👁", "key": KEY_QUOTELEFT, "key_label": "`"},
	OverlayType.LIGHT: {"name": "Light", "icon": "☀", "key": KEY_F2, "key_label": "F2"},
	OverlayType.AIR_QUALITY: {"name": "Air Quality", "icon": "💨", "key": KEY_F3, "key_label": "F3"},
	OverlayType.NOISE: {"name": "Noise", "icon": "🔊", "key": KEY_F4, "key_label": "F4"},
	OverlayType.SAFETY: {"name": "Safety", "icon": "🛡", "key": KEY_F5, "key_label": "F5"},
	OverlayType.VIBES: {"name": "Vibes", "icon": "✨", "key": KEY_F6, "key_label": "F6"},
	OverlayType.CONNECTIVITY:
	{"name": "Connectivity", "icon": "🔗", "key": KEY_F7, "key_label": "F7"},
	OverlayType.BLOCK_TYPE: {"name": "Block Type", "icon": "🏠", "key": KEY_F8, "key_label": "F8"},
	OverlayType.FOOT_TRAFFIC:
	{"name": "Foot Traffic", "icon": "👣", "key": KEY_F9, "key_label": "F9"}
}

# Legend configurations per overlay type
const LEGEND_CONFIG := {
	OverlayType.LIGHT:
	{
		"title": "Light Level",
		"colors":
		[Color("#ffff00"), Color("#cccc00"), Color("#999900"), Color("#666600"), Color("#333300")],
		"labels":
		["Bright (80%+)", "Good (60-80%)", "Fair (40-60%)", "Poor (20-40%)", "Dark (<20%)"]
	},
	OverlayType.AIR_QUALITY:
	{
		"title": "Air Quality",
		"colors":
		[Color("#00ff00"), Color("#88ff00"), Color("#ffff00"), Color("#ff8800"), Color("#ff0000")],
		"labels":
		["Excellent (80%+)", "Good (60-80%)", "Fair (40-60%)", "Poor (20-40%)", "Bad (<20%)"]
	},
	OverlayType.NOISE:
	{
		"title": "Noise Level",
		"colors":
		[Color("#00ff00"), Color("#88ff00"), Color("#ffff00"), Color("#ff8800"), Color("#ff0000")],
		"labels":
		["Quiet (80%+)", "Calm (60-80%)", "Moderate (40-60%)", "Noisy (20-40%)", "Loud (<20%)"]
	},
	OverlayType.SAFETY:
	{
		"title": "Safety Rating",
		"colors":
		[Color("#00ff00"), Color("#88ff00"), Color("#ffff00"), Color("#ff8800"), Color("#ff0000")],
		"labels":
		[
			"Very Safe (80%+)",
			"Safe (60-80%)",
			"Moderate (40-60%)",
			"Risky (20-40%)",
			"Dangerous (<20%)"
		]
	},
	OverlayType.VIBES:
	{
		"title": "Vibes Score",
		"colors":
		[Color("#ff00ff"), Color("#cc00cc"), Color("#990099"), Color("#660066"), Color("#330033")],
		"labels": ["Amazing (80%+)", "Good (60-80%)", "Okay (40-60%)", "Meh (20-40%)", "Bad (<20%)"]
	},
	OverlayType.CONNECTIVITY:
	{
		"title": "Connectivity",
		"colors": [Color("#00ff00"), Color("#ff0000")],
		"labels": ["Connected", "Disconnected"]
	},
	OverlayType.BLOCK_TYPE:
	{
		"title": "Block Categories",
		"colors":
		[
			Color("#4488ff"),
			Color("#ff8844"),
			Color("#888888"),
			Color("#00cc88"),
			Color("#88ff00"),
			Color("#ff44ff"),
			Color("#ffff00")
		],
		"labels":
		["Residential", "Commercial", "Industrial", "Transit", "Green", "Civic", "Infrastructure"]
	},
	OverlayType.FOOT_TRAFFIC:
	{
		"title": "Foot Traffic",
		"colors":
		[Color("#ff0000"), Color("#ff8800"), Color("#ffff00"), Color("#88ff00"), Color("#00ff00")],
		"labels": ["Very High", "High", "Medium", "Low", "None"]
	}
}

# Color scheme (match HUD)
const COLOR_SIDEBAR := Color("#16213e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")

# Size constants
const COLLAPSED_WIDTH := 64
const EXPANDED_WIDTH := 240
const BUTTON_SIZE := 48
const EXPAND_DELAY := 0.3  # seconds before hover expand
const ANIM_DURATION := 0.15

# State
var _current_overlay: int = OverlayType.NONE
var _expanded := false
var _pinned := false
var _hover_timer: Timer
var _is_hovering := false

# UI components
var _panel: PanelContainer
var _vbox: VBoxContainer
var _buttons: Dictionary = {}  # OverlayType -> Button
var _labels: Dictionary = {}  # OverlayType -> Label
var _legend_container: VBoxContainer
var _pin_button: Button


func _ready() -> void:
	_setup_ui()
	_setup_hover_timer()
	_connect_keyboard_shortcuts()


func _setup_ui() -> void:
	# Root panel - anchored to right side
	_panel = PanelContainer.new()
	_panel.name = "OverlaySidebarPanel"
	_panel.custom_minimum_size = Vector2(COLLAPSED_WIDTH, 0)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_panel)

	# Apply styling
	_apply_panel_style()

	# Main vertical container
	_vbox = VBoxContainer.new()
	_vbox.name = "VBoxContainer"
	_vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(_vbox)

	# Header with title and pin
	var header := _create_header()
	_vbox.add_child(header)

	# Separator
	var sep := HSeparator.new()
	_vbox.add_child(sep)

	# Overlay buttons
	_create_overlay_buttons()

	# Separator before legend
	var sep2 := HSeparator.new()
	sep2.name = "LegendSeparator"
	sep2.visible = false  # Hidden until overlay selected
	_vbox.add_child(sep2)

	# Legend container
	_legend_container = VBoxContainer.new()
	_legend_container.name = "LegendContainer"
	_legend_container.visible = false
	_legend_container.add_theme_constant_override("separation", 2)
	_vbox.add_child(_legend_container)

	# Connect mouse events for hover behavior
	_panel.mouse_entered.connect(_on_mouse_entered)
	_panel.mouse_exited.connect(_on_mouse_exited)

	# Update visual state
	_update_visual_state()


func _create_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 4)

	# Title label (hidden when collapsed)
	var title := Label.new()
	title.text = "OVERLAYS"
	title.name = "Title"
	title.visible = false  # Only visible when expanded
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Spacer for collapsed state
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	# Pin button
	_pin_button = Button.new()
	_pin_button.text = "📌"
	_pin_button.tooltip_text = "Pin panel open"
	_pin_button.toggle_mode = true
	_pin_button.custom_minimum_size = Vector2(32, 32)
	_pin_button.name = "PinButton"
	_pin_button.toggled.connect(_on_pin_toggled)
	_pin_button.visible = false  # Only visible when expanded
	header.add_child(_pin_button)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.tooltip_text = "Close panel"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.name = "CloseButton"
	close_btn.pressed.connect(_on_close_pressed)
	close_btn.visible = false  # Only visible when expanded
	header.add_child(close_btn)

	return header


func _create_overlay_buttons() -> void:
	var button_container := VBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.add_theme_constant_override("separation", 2)
	_vbox.add_child(button_container)

	# Create button for each overlay type
	for overlay_type in OVERLAY_CONFIG.keys():
		var config: Dictionary = OVERLAY_CONFIG[overlay_type]

		var row := HBoxContainer.new()
		row.name = "Row_%d" % overlay_type
		row.add_theme_constant_override("separation", 8)
		button_container.add_child(row)

		# Radio indicator (only in expanded mode)
		var radio := Label.new()
		radio.text = "○"
		radio.name = "Radio_%d" % overlay_type
		radio.visible = false  # Only visible when expanded
		radio.custom_minimum_size = Vector2(20, 0)
		row.add_child(radio)

		# Icon button
		var btn := Button.new()
		btn.text = config["icon"]
		btn.tooltip_text = "%s (%s)" % [config["name"], config["key_label"]]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		btn.name = "Button_%d" % overlay_type
		btn.pressed.connect(_on_overlay_button_pressed.bind(overlay_type))
		row.add_child(btn)
		_buttons[overlay_type] = btn

		# Label (only visible when expanded)
		var label := Label.new()
		label.text = "%s (%s)" % [config["name"], config["key_label"]]
		label.name = "Label_%d" % overlay_type
		label.visible = false
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		_labels[overlay_type] = label


func _setup_hover_timer() -> void:
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.wait_time = EXPAND_DELAY
	_hover_timer.timeout.connect(_on_hover_expand)
	add_child(_hover_timer)


func _connect_keyboard_shortcuts() -> void:
	# Keyboard shortcuts are handled in _unhandled_input
	pass


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SIDEBAR
	style.border_color = COLOR_PANEL_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		for overlay_type in OVERLAY_CONFIG.keys():
			var config: Dictionary = OVERLAY_CONFIG[overlay_type]
			if key_event.keycode == config["key"]:
				set_active_overlay(overlay_type)
				get_viewport().set_input_as_handled()
				return


func _on_mouse_entered() -> void:
	_is_hovering = true
	if not _expanded and not _pinned:
		_hover_timer.start()


func _on_mouse_exited() -> void:
	_is_hovering = false
	_hover_timer.stop()
	if _expanded and not _pinned:
		_collapse()


func _on_hover_expand() -> void:
	if _is_hovering and not _expanded:
		_expand()


func _on_pin_toggled(button_pressed: bool) -> void:
	_pinned = button_pressed
	_pin_button.tooltip_text = "Unpin panel" if _pinned else "Pin panel open"


func _on_close_pressed() -> void:
	if _pinned:
		_pinned = false
		_pin_button.button_pressed = false
	_collapse()


func _on_overlay_button_pressed(overlay_type: int) -> void:
	set_active_overlay(overlay_type)


func _expand() -> void:
	if _expanded:
		return

	_expanded = true

	# Animate width
	var tween := create_tween()
	tween.tween_property(_panel, "custom_minimum_size:x", EXPANDED_WIDTH, ANIM_DURATION)

	# Show expanded elements
	_update_visual_state()

	expanded_changed.emit(true)


func _collapse() -> void:
	if not _expanded:
		return

	_expanded = false

	# Animate width
	var tween := create_tween()
	tween.tween_property(_panel, "custom_minimum_size:x", COLLAPSED_WIDTH, ANIM_DURATION)

	# Hide expanded elements
	_update_visual_state()

	expanded_changed.emit(false)


func _update_visual_state() -> void:
	# Update header elements
	var title: Label = _vbox.get_node_or_null("Header/Title")
	if title:
		title.visible = _expanded

	var spacer: Control = _vbox.get_node_or_null("Header/Spacer")
	if spacer:
		spacer.visible = not _expanded

	if _pin_button:
		_pin_button.visible = _expanded

	var close_btn: Button = _vbox.get_node_or_null("Header/CloseButton")
	if close_btn:
		close_btn.visible = _expanded

	# Update radio indicators and labels
	for overlay_type in OVERLAY_CONFIG.keys():
		var radio: Label = _vbox.get_node_or_null(
			"ButtonContainer/Row_%d/Radio_%d" % [overlay_type, overlay_type]
		)
		if radio:
			radio.visible = _expanded
			radio.text = "●" if overlay_type == _current_overlay else "○"

		if _labels.has(overlay_type):
			_labels[overlay_type].visible = _expanded

	# Update button styles
	_update_button_styles()

	# Update legend visibility
	_update_legend()


func _update_button_styles() -> void:
	for overlay_type in _buttons.keys():
		var btn: Button = _buttons[overlay_type]
		var is_active: bool = overlay_type == _current_overlay

		# Create style for active state
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_BUTTON_ACTIVE if is_active else COLOR_BUTTON
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4

		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("pressed", style)

		# Hover style
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = (
			COLOR_BUTTON_ACTIVE.lightened(0.2) if is_active else COLOR_BUTTON.lightened(0.2)
		)
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("hover", hover_style)


func _update_legend() -> void:
	# Clear existing legend
	for child in _legend_container.get_children():
		child.queue_free()

	# Get separator
	var sep: HSeparator = _vbox.get_node_or_null("LegendSeparator")

	# Show/hide based on active overlay
	if _current_overlay == OverlayType.NONE or not LEGEND_CONFIG.has(_current_overlay):
		_legend_container.visible = false
		if sep:
			sep.visible = false
		return

	_legend_container.visible = _expanded
	if sep:
		sep.visible = _expanded

	if not _expanded:
		return

	# Add legend content
	var legend_data: Dictionary = LEGEND_CONFIG[_current_overlay]

	# Title
	var title := Label.new()
	title.text = legend_data["title"]
	title.add_theme_color_override("font_color", COLOR_TEXT)
	_legend_container.add_child(title)

	# Color entries
	var colors: Array = legend_data["colors"]
	var labels: Array = legend_data["labels"]

	for i in range(min(colors.size(), labels.size())):
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 8)
		_legend_container.add_child(entry)

		# Color swatch
		var swatch := ColorRect.new()
		swatch.color = colors[i]
		swatch.custom_minimum_size = Vector2(20, 16)
		entry.add_child(swatch)

		# Label
		var label := Label.new()
		label.text = labels[i]
		label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		label.add_theme_font_size_override("font_size", 12)
		entry.add_child(label)


## Set the active overlay (radio selection - deselects others)
func set_active_overlay(overlay_type: int) -> void:
	if overlay_type == _current_overlay:
		return

	_current_overlay = overlay_type
	_update_visual_state()
	overlay_changed.emit(overlay_type)


## Get the currently active overlay
func get_active_overlay() -> int:
	return _current_overlay


## Check if an overlay is active (not NONE)
func has_active_overlay() -> bool:
	return _current_overlay != OverlayType.NONE


## Toggle expansion state
func toggle_expanded() -> void:
	if _expanded:
		_collapse()
	else:
		_expand()


## Check if sidebar is expanded
func is_expanded() -> bool:
	return _expanded


## Check if sidebar is pinned
func is_pinned() -> bool:
	return _pinned


## Set pinned state
func set_pinned(pinned: bool) -> void:
	_pinned = pinned
	if _pin_button:
		_pin_button.button_pressed = pinned


## Expand the sidebar (public API)
func expand() -> void:
	_expand()


## Collapse the sidebar (public API)
func collapse() -> void:
	if not _pinned:
		_collapse()


## Get overlay name by type
static func get_overlay_name(overlay_type: int) -> String:
	if OVERLAY_CONFIG.has(overlay_type):
		return OVERLAY_CONFIG[overlay_type]["name"]
	return "Unknown"


## Get all available overlay types
static func get_available_overlays() -> Array:
	return OVERLAY_CONFIG.keys()
