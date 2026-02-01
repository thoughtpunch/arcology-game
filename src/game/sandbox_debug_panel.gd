extends Control

## Extensible debug panel for the Phase 0 sandbox.
## Toggle with F3. Does not pause the game.
##
## To add new controls, call the public helpers:
##   add_section("Section Title")
##   add_slider("Label", min, max, default, callback)
##   add_checkbox("Label", default, callback)
##   add_label("key")  → returns Label (update .text each frame if needed)
##
## The panel uses MOUSE_FILTER_PASS on its background so clicks pass
## through to the 3D scene, except on interactive widgets (MOUSE_FILTER_STOP).

signal time_changed(hour: float)
signal sun_energy_changed(energy: float)
signal ambient_energy_changed(energy: float)

const COLOR_BG := Color(0.08, 0.08, 0.12, 0.75)
const COLOR_SECTION := Color(0.0, 0.9, 0.9)
const COLOR_TEXT := Color(0.85, 0.85, 0.85)
const COLOR_DIM := Color(0.5, 0.5, 0.55)
const PANEL_WIDTH := 260.0

var _panel_bg: PanelContainer
var _content: VBoxContainer
var _time_value_label: Label
var _fps_label: Label


func _ready() -> void:
	_setup_layout()
	_build_default_controls()
	visible = false


func _process(_delta: float) -> void:
	if visible and _fps_label:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			visible = not visible
			get_viewport().set_input_as_handled()


# --- Layout ---


func _setup_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel_bg = PanelContainer.new()
	_panel_bg.name = "DebugPanelBG"
	_panel_bg.mouse_filter = Control.MOUSE_FILTER_PASS

	# Anchor top-right
	_panel_bg.anchor_left = 1.0
	_panel_bg.anchor_right = 1.0
	_panel_bg.anchor_top = 0.0
	_panel_bg.anchor_bottom = 0.0
	_panel_bg.offset_left = -PANEL_WIDTH - 12
	_panel_bg.offset_right = -12
	_panel_bg.offset_top = 12
	_panel_bg.anchor_bottom = 1.0
	_panel_bg.offset_bottom = -12
	_panel_bg.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 14
	_panel_bg.add_theme_stylebox_override("panel", style)
	add_child(_panel_bg)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel_bg.add_child(scroll)

	_content = VBoxContainer.new()
	_content.name = "DebugContent"
	_content.add_theme_constant_override("separation", 6)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(_content)

	# Title
	var title := Label.new()
	title.text = "DEBUG"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_SECTION)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(title)


# --- Public API for extensibility ---


func add_section(title: String) -> void:
	## Add a section header label.
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(sep)

	var lbl := Label.new()
	lbl.text = title.to_upper()
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", COLOR_SECTION)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(lbl)


func add_slider(
	label_text: String, min_val: float, max_val: float, default_val: float, callback: Callable
) -> HSlider:
	## Add a labeled slider. Returns the HSlider for external reference.
	## callback signature: func(value: float)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", COLOR_TEXT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(lbl)

	var value_label := Label.new()
	value_label.text = _format_slider_value(default_val, label_text)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", COLOR_DIM)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(value_label)

	row.add_child(header)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default_val
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(0, 18)
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	slider.value_changed.connect(
		func(val: float):
			value_label.text = _format_slider_value(val, label_text)
			callback.call(val)
	)
	row.add_child(slider)

	_content.add_child(row)

	# Store time value label for external access
	if label_text == "Time of Day":
		_time_value_label = value_label

	return slider


func add_checkbox(label_text: String, default_val: bool, callback: Callable) -> CheckBox:
	## Add a labeled checkbox. Returns the CheckBox.
	## callback signature: func(enabled: bool)
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = default_val
	cb.add_theme_font_size_override("font_size", 12)
	cb.add_theme_color_override("font_color", COLOR_TEXT)
	cb.mouse_filter = Control.MOUSE_FILTER_STOP
	cb.toggled.connect(callback)
	_content.add_child(cb)
	return cb


func add_info_label(key: String) -> Label:
	## Add a read-only info label. Returns it so callers can update .text.
	var lbl := Label.new()
	lbl.name = "Info_" + key
	lbl.text = key + ": —"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", COLOR_DIM)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(lbl)
	return lbl


# --- Default controls (built-in) ---


func _build_default_controls() -> void:
	_fps_label = add_info_label("FPS")

	add_section("Lighting")

	add_slider("Time of Day", 0.0, 24.0, 12.0, func(val: float): time_changed.emit(val))
	add_slider("Sun Energy", 0.0, 2.0, 1.2, func(val: float): sun_energy_changed.emit(val))
	add_slider("Ambient Energy", 0.0, 1.5, 0.5, func(val: float): ambient_energy_changed.emit(val))


func _format_slider_value(val: float, label_text: String) -> String:
	if label_text == "Time of Day":
		var h := int(val) % 24
		var m := int((val - floor(val)) * 60.0)
		return "%02d:%02d" % [h, m]
	return "%.2f" % val
