class_name CameraControlsPane
extends Control
## Collapsible camera controls pane (Cities Skylines style)
## Shows rotation compass, zoom controls, and view mode toggle
## Hotkeys: Q/E rotate, +/- zoom, I/T view mode, H toggle pane

# Color constants
const COLOR_PANEL_BG := Color("#1a1a2e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")

# Size constants
const PANE_WIDTH := 180
const BUTTON_SIZE := Vector2(40, 40)
const COMPASS_SIZE := 80

# Signals
signal rotation_requested(direction: int)  # -1 = CCW, 1 = CW
signal zoom_requested(direction: int)      # -1 = out, 1 = in
signal zoom_reset_requested
signal view_mode_changed(mode: String)     # "iso" or "top"
signal pane_toggled(visible: bool)

# References
var _camera_controller: CameraController

# UI elements
var _main_panel: PanelContainer
var _collapse_button: Button
var _compass: Control
var _compass_needle: Control
var _zoom_label: Label
var _iso_button: Button
var _top_button: Button

# State
var _is_collapsed := false
var _current_rotation := 0.0
var _current_zoom := 1.0
var _current_view_mode := "iso"


func _ready() -> void:
	_setup_ui()
	_connect_hotkeys()


func _setup_ui() -> void:
	# Position in bottom-right corner
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -PANE_WIDTH - 20
	offset_right = -20
	offset_top = -280
	offset_bottom = -100
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Main panel
	_main_panel = PanelContainer.new()
	_main_panel.name = "MainPanel"
	_style_panel(_main_panel)
	add_child(_main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)

	# Header with title and collapse button
	var header := _create_header()
	vbox.add_child(header)

	# Compass for rotation
	var compass_container := _create_compass()
	vbox.add_child(compass_container)

	# Rotation buttons
	var rotation_row := _create_rotation_controls()
	vbox.add_child(rotation_row)

	# Zoom controls
	var zoom_row := _create_zoom_controls()
	vbox.add_child(zoom_row)

	# View mode toggle
	var view_row := _create_view_controls()
	vbox.add_child(view_row)

	# Hotkey hints
	var hints := _create_hotkey_hints()
	vbox.add_child(hints)


func _create_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "CAMERA"
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_collapse_button = Button.new()
	_collapse_button.text = "—"
	_collapse_button.tooltip_text = "Collapse (H)"
	_collapse_button.custom_minimum_size = Vector2(24, 24)
	_collapse_button.pressed.connect(_toggle_collapse)
	_style_button(_collapse_button)
	header.add_child(_collapse_button)

	return header


func _create_compass() -> CenterContainer:
	var container := CenterContainer.new()
	container.custom_minimum_size = Vector2(COMPASS_SIZE + 20, COMPASS_SIZE + 20)
	container.name = "CompassContainer"

	# Compass background
	_compass = Control.new()
	_compass.custom_minimum_size = Vector2(COMPASS_SIZE, COMPASS_SIZE)
	_compass.name = "Compass"
	container.add_child(_compass)

	# Compass drawing
	var compass_bg := ColorRect.new()
	compass_bg.color = Color("#2a2a4e")
	compass_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compass.add_child(compass_bg)

	# Cardinal direction labels
	var n_label := _create_direction_label("N", Vector2(COMPASS_SIZE/2 - 6, 2))
	var s_label := _create_direction_label("S", Vector2(COMPASS_SIZE/2 - 6, COMPASS_SIZE - 18))
	var e_label := _create_direction_label("E", Vector2(COMPASS_SIZE - 14, COMPASS_SIZE/2 - 8))
	var w_label := _create_direction_label("W", Vector2(2, COMPASS_SIZE/2 - 8))
	_compass.add_child(n_label)
	_compass.add_child(s_label)
	_compass.add_child(e_label)
	_compass.add_child(w_label)

	# Needle (indicator of current rotation)
	_compass_needle = ColorRect.new()
	_compass_needle.color = COLOR_BUTTON_ACTIVE
	_compass_needle.size = Vector2(4, 25)
	_compass_needle.position = Vector2(COMPASS_SIZE/2 - 2, 15)
	_compass_needle.pivot_offset = Vector2(2, COMPASS_SIZE/2 - 15)
	_compass.add_child(_compass_needle)

	return container


func _create_direction_label(text: String, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 11)
	return label


func _create_rotation_controls() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var ccw_btn := Button.new()
	ccw_btn.text = "Q"
	ccw_btn.tooltip_text = "Rotate left (Q)"
	ccw_btn.custom_minimum_size = BUTTON_SIZE
	ccw_btn.pressed.connect(func(): rotation_requested.emit(-1))
	_style_button(ccw_btn)
	row.add_child(ccw_btn)

	var rot_label := Label.new()
	rot_label.text = "Rotate"
	rot_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(rot_label)

	var cw_btn := Button.new()
	cw_btn.text = "E"
	cw_btn.tooltip_text = "Rotate right (E)"
	cw_btn.custom_minimum_size = BUTTON_SIZE
	cw_btn.pressed.connect(func(): rotation_requested.emit(1))
	_style_button(cw_btn)
	row.add_child(cw_btn)

	return row


func _create_zoom_controls() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var out_btn := Button.new()
	out_btn.text = "-"
	out_btn.tooltip_text = "Zoom out (-)"
	out_btn.custom_minimum_size = BUTTON_SIZE
	out_btn.pressed.connect(func(): zoom_requested.emit(-1))
	_style_button(out_btn)
	row.add_child(out_btn)

	_zoom_label = Label.new()
	_zoom_label.text = "100%"
	_zoom_label.custom_minimum_size = Vector2(50, 0)
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.add_theme_color_override("font_color", COLOR_TEXT)
	_zoom_label.tooltip_text = "Double-click to reset (Home)"
	row.add_child(_zoom_label)

	var in_btn := Button.new()
	in_btn.text = "+"
	in_btn.tooltip_text = "Zoom in (+)"
	in_btn.custom_minimum_size = BUTTON_SIZE
	in_btn.pressed.connect(func(): zoom_requested.emit(1))
	_style_button(in_btn)
	row.add_child(in_btn)

	# Make zoom label clickable for reset
	var zoom_click := Button.new()
	zoom_click.flat = true
	zoom_click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	zoom_click.pressed.connect(func(): zoom_reset_requested.emit())
	_zoom_label.add_child(zoom_click)

	return row


func _create_view_controls() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	_iso_button = Button.new()
	_iso_button.text = "ISO"
	_iso_button.tooltip_text = "Isometric view (I)"
	_iso_button.toggle_mode = true
	_iso_button.button_pressed = true
	_iso_button.custom_minimum_size = Vector2(60, 32)
	_iso_button.pressed.connect(_on_iso_pressed)
	_style_toggle_button(_iso_button)
	row.add_child(_iso_button)

	_top_button = Button.new()
	_top_button.text = "TOP"
	_top_button.tooltip_text = "Top-down view (T)"
	_top_button.toggle_mode = true
	_top_button.custom_minimum_size = Vector2(60, 32)
	_top_button.pressed.connect(_on_top_pressed)
	_style_toggle_button(_top_button)
	row.add_child(_top_button)

	return row


func _create_hotkey_hints() -> Label:
	var hints := Label.new()
	hints.text = "H: toggle | Scroll: zoom"
	hints.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hints.add_theme_font_size_override("font_size", 10)
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return hints


func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.border_color = COLOR_PANEL_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _style_toggle_button(btn: Button) -> void:
	_style_button(btn)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_BUTTON_ACTIVE
	pressed.corner_radius_top_left = 4
	pressed.corner_radius_top_right = 4
	pressed.corner_radius_bottom_left = 4
	pressed.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", pressed)


func _connect_hotkeys() -> void:
	# Hotkeys handled in _unhandled_input
	pass


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key := event as InputEventKey

	# Skip if modifier keys are held (except for +/-)
	var has_modifier := key.ctrl_pressed or key.alt_pressed
	if has_modifier and key.keycode != KEY_EQUAL and key.keycode != KEY_MINUS:
		return

	match key.keycode:
		KEY_H:
			if not key.shift_pressed:
				_toggle_collapse()
				get_viewport().set_input_as_handled()
		KEY_I:
			_set_view_mode("iso")
			get_viewport().set_input_as_handled()
		KEY_T:
			if not key.ctrl_pressed:  # Don't capture Ctrl+T
				_set_view_mode("top")
				get_viewport().set_input_as_handled()
		KEY_MINUS, KEY_KP_SUBTRACT:
			zoom_requested.emit(-1)
			get_viewport().set_input_as_handled()
		KEY_EQUAL, KEY_KP_ADD:  # + is Shift+= on most keyboards
			zoom_requested.emit(1)
			get_viewport().set_input_as_handled()
		KEY_HOME:
			zoom_reset_requested.emit()
			get_viewport().set_input_as_handled()


func _toggle_collapse() -> void:
	_is_collapsed = not _is_collapsed

	if _is_collapsed:
		_collapse_button.text = "+"
		# Hide everything except header
		for child in _main_panel.get_child(0).get_children():
			if child != _main_panel.get_child(0).get_child(0):  # Not header
				child.visible = false
	else:
		_collapse_button.text = "—"
		for child in _main_panel.get_child(0).get_children():
			child.visible = true

	pane_toggled.emit(not _is_collapsed)


func _on_iso_pressed() -> void:
	_set_view_mode("iso")


func _on_top_pressed() -> void:
	_set_view_mode("top")


func _set_view_mode(mode: String) -> void:
	_current_view_mode = mode
	_iso_button.button_pressed = (mode == "iso")
	_top_button.button_pressed = (mode == "top")
	view_mode_changed.emit(mode)


## Connect to a camera controller for live updates
func connect_to_camera(controller: CameraController) -> void:
	_camera_controller = controller

	if _camera_controller:
		_camera_controller.camera_rotated.connect(_on_camera_rotated)
		_camera_controller.camera_zoomed.connect(_on_camera_zoomed)

		# Connect our signals to controller
		rotation_requested.connect(_on_rotation_requested)
		zoom_requested.connect(_on_zoom_requested)
		zoom_reset_requested.connect(_on_zoom_reset)

		# Initialize display
		update_rotation(_camera_controller.get_rotation_angle())
		update_zoom(_camera_controller.get_current_zoom())


func _on_rotation_requested(direction: int) -> void:
	if _camera_controller:
		_camera_controller.rotate_camera(direction)


func _on_zoom_requested(direction: int) -> void:
	if _camera_controller:
		var current := _camera_controller.get_zoom()
		var new_zoom := current + (direction * 0.15)
		_camera_controller.set_zoom(new_zoom)


func _on_zoom_reset() -> void:
	if _camera_controller:
		_camera_controller.set_zoom(1.0)


func _on_camera_rotated(angle: float) -> void:
	update_rotation(angle)


func _on_camera_zoomed(zoom: float) -> void:
	update_zoom(zoom)


## Update compass display
func update_rotation(angle: float) -> void:
	_current_rotation = angle
	if _compass_needle:
		_compass_needle.rotation_degrees = angle


## Update zoom display
func update_zoom(zoom: float) -> void:
	_current_zoom = zoom
	if _zoom_label:
		_zoom_label.text = "%d%%" % int(zoom * 100)


## Check if pane is collapsed
func is_collapsed() -> bool:
	return _is_collapsed


## Set collapsed state
func set_collapsed(collapsed: bool) -> void:
	if _is_collapsed != collapsed:
		_toggle_collapse()


## Get current view mode
func get_view_mode() -> String:
	return _current_view_mode
