extends Control

## Scenario picker — full-screen overlay shown before the sandbox world builds.
## Offers three preset scenarios (Blank Slate, Megastructure, Custom Game).
## Custom Game opens a scrollable parameter editor with sliders/checkboxes.
## Emits scenario_selected(config) when the player clicks START.

signal scenario_selected(config: RefCounted)

const ScenarioConfigScript = preload("res://src/phase0/scenario_config.gd")

# Reuse color scheme from sandbox_pause_menu.gd
const COLOR_OVERLAY := Color(0.04, 0.06, 0.12, 0.95)
const COLOR_PANEL := Color("#16213e")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_ACCENT := Color("#e94560")
const COLOR_DIM := Color(0.5, 0.5, 0.55)
const COLOR_SECTION := Color(0.0, 0.9, 0.9)
const COLOR_CARD_NORMAL := Color(0.08, 0.12, 0.22)
const COLOR_CARD_SELECTED := Color(0.12, 0.2, 0.38)
const COLOR_CARD_BORDER := Color(0.0, 0.9, 0.9)

var _selected_id: String = "megastructure"
var _config: RefCounted = null
var _cards: Dictionary = {}  # id -> PanelContainer
var _description_label: Label
var _start_button: Button
var _main_screen: Control
var _custom_screen: ScrollContainer
var _custom_config: RefCounted = null


func _ready() -> void:
	_setup_layout()


func _setup_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_OVERLAY
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Outer panel
	var outer_panel := PanelContainer.new()
	outer_panel.custom_minimum_size = Vector2(700, 500)
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = COLOR_PANEL
	outer_style.corner_radius_top_left = 12
	outer_style.corner_radius_top_right = 12
	outer_style.corner_radius_bottom_left = 12
	outer_style.corner_radius_bottom_right = 12
	outer_style.content_margin_left = 32
	outer_style.content_margin_right = 32
	outer_style.content_margin_top = 28
	outer_style.content_margin_bottom = 28
	outer_panel.add_theme_stylebox_override("panel", outer_style)
	center.add_child(outer_panel)

	# Main VBox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	outer_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PHASE 0 SANDBOX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_SECTION)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Select a scenario"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", COLOR_DIM)
	vbox.add_child(subtitle)

	# --- Main screen (card selection) ---
	_main_screen = VBoxContainer.new()
	(_main_screen as VBoxContainer).add_theme_constant_override("separation", 16)
	vbox.add_child(_main_screen)

	# Card row
	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 16)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_screen.add_child(card_row)

	_add_card(card_row, "blank_slate", "BLANK\nSLATE", "Mountains\n+ River")
	_add_card(card_row, "megastructure", "MEGA-\nSTRUCTURE", "City\nskyline")
	_add_card(card_row, "custom", "CUSTOM\nGAME", "Tune all\nsettings")

	# Description
	_description_label = Label.new()
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.add_theme_font_size_override("font_size", 14)
	_description_label.add_theme_color_override("font_color", COLOR_DIM)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.custom_minimum_size = Vector2(600, 0)
	_main_screen.add_child(_description_label)

	# --- Custom screen (parameter editor, hidden initially) ---
	_custom_screen = ScrollContainer.new()
	_custom_screen.custom_minimum_size = Vector2(600, 300)
	_custom_screen.visible = false
	_custom_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_custom_screen)

	# Start button (shared)
	_start_button = _create_accent_button("START")
	_start_button.custom_minimum_size = Vector2(200, 44)
	_start_button.pressed.connect(_on_start_pressed)
	var btn_center := CenterContainer.new()
	btn_center.add_child(_start_button)
	vbox.add_child(btn_center)

	# Select default
	_select_scenario("megastructure")


func _add_card(
	parent: HBoxContainer, id: String, title_text: String, subtitle_text: String
) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 140)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_NORMAL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = subtitle_text
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", COLOR_DIM)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	card.gui_input.connect(_on_card_input.bind(id))
	parent.add_child(card)
	_cards[id] = card


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_scenario(id)


func _select_scenario(id: String) -> void:
	_selected_id = id

	# Update card visuals
	for card_id in _cards:
		var card: PanelContainer = _cards[card_id]
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if card_id == id:
			style.bg_color = COLOR_CARD_SELECTED
			style.border_color = COLOR_CARD_BORDER
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		else:
			style.bg_color = COLOR_CARD_NORMAL
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_top = 0
			style.border_width_bottom = 0

	# Update description
	match id:
		"blank_slate":
			_config = ScenarioConfigScript.blank_slate()
		"megastructure":
			_config = ScenarioConfigScript.megastructure()
		"custom":
			if _custom_config == null:
				_custom_config = ScenarioConfigScript.custom_default()
			_config = _custom_config

	_description_label.text = _config.description

	# Show/hide custom editor
	if id == "custom":
		_main_screen.visible = false
		_custom_screen.visible = true
		_build_custom_editor()
	else:
		_main_screen.visible = true
		_custom_screen.visible = false


func _build_custom_editor() -> void:
	# Clear previous editor content
	for child in _custom_screen.get_children():
		child.queue_free()

	var cfg := _custom_config
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_custom_screen.add_child(content)

	# Back button row
	var back_row := HBoxContainer.new()
	var back_btn := _create_menu_button("< BACK")
	back_btn.custom_minimum_size = Vector2(100, 32)
	back_btn.pressed.connect(
		func():
			_main_screen.visible = true
			_custom_screen.visible = false
	)
	back_row.add_child(back_btn)
	content.add_child(back_row)

	# --- TERRAIN ---
	_add_section_header(content, "TERRAIN")
	_add_slider_row(
		content,
		"Ground Size",
		20.0,
		200.0,
		cfg.ground_size,
		1.0,
		func(v: float): cfg.ground_size = int(v)
	)
	_add_slider_row(
		content,
		"Ground Depth",
		1.0,
		10.0,
		cfg.ground_depth,
		1.0,
		func(v: float): cfg.ground_depth = int(v)
	)

	# --- SKYLINE ---
	_add_section_header(content, "SKYLINE")
	var skyline_type_row := HBoxContainer.new()
	skyline_type_row.add_theme_constant_override("separation", 8)
	var skyline_label := Label.new()
	skyline_label.text = "Type"
	skyline_label.add_theme_font_size_override("font_size", 13)
	skyline_label.add_theme_color_override("font_color", COLOR_TEXT)
	skyline_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skyline_type_row.add_child(skyline_label)

	var skyline_option := OptionButton.new()
	skyline_option.add_item("None", 0)
	skyline_option.add_item("City Buildings", 1)
	skyline_option.selected = cfg.skyline_type
	skyline_option.item_selected.connect(func(idx: int): cfg.skyline_type = idx)
	skyline_type_row.add_child(skyline_option)
	content.add_child(skyline_type_row)

	_add_slider_row(
		content,
		"Building Count",
		0.0,
		600.0,
		cfg.skyline_building_count,
		10.0,
		func(v: float): cfg.skyline_building_count = int(v)
	)
	_add_slider_row(
		content,
		"Skyline Seed",
		0.0,
		999.0,
		cfg.skyline_seed,
		1.0,
		func(v: float): cfg.skyline_seed = int(v)
	)

	# --- MOUNTAINS ---
	_add_section_header(content, "MOUNTAINS")
	_add_checkbox_row(
		content, "Enable Mountains", cfg.mountains_enabled, func(v: bool): cfg.mountains_enabled = v
	)
	_add_slider_row(
		content,
		"Count",
		0.0,
		200.0,
		cfg.mountain_count,
		1.0,
		func(v: float): cfg.mountain_count = int(v)
	)
	_add_slider_row(
		content,
		"Min Height",
		10.0,
		200.0,
		cfg.mountain_min_height,
		5.0,
		func(v: float): cfg.mountain_min_height = v
	)
	_add_slider_row(
		content,
		"Max Height",
		50.0,
		600.0,
		cfg.mountain_max_height,
		10.0,
		func(v: float): cfg.mountain_max_height = v
	)
	_add_slider_row(
		content,
		"Mountain Seed",
		0.0,
		999.0,
		cfg.mountain_seed,
		1.0,
		func(v: float): cfg.mountain_seed = int(v)
	)

	# --- RIVER ---
	_add_section_header(content, "RIVER")
	_add_checkbox_row(
		content, "Enable River", cfg.river_enabled, func(v: bool): cfg.river_enabled = v
	)
	_add_slider_row(
		content, "Width", 5.0, 100.0, cfg.river_width, 1.0, func(v: float): cfg.river_width = v
	)
	_add_slider_row(
		content,
		"Flow Angle",
		0.0,
		180.0,
		cfg.river_flow_angle,
		5.0,
		func(v: float): cfg.river_flow_angle = v
	)
	_add_slider_row(
		content, "Offset", 0.0, 300.0, cfg.river_offset, 10.0, func(v: float): cfg.river_offset = v
	)

	# --- ENVIRONMENT ---
	_add_section_header(content, "ENVIRONMENT")
	_add_slider_row(
		content, "Sun Energy", 0.0, 3.0, cfg.sun_energy, 0.1, func(v: float): cfg.sun_energy = v
	)
	_add_slider_row(
		content,
		"Ambient Energy",
		0.0,
		2.0,
		cfg.ambient_energy,
		0.05,
		func(v: float): cfg.ambient_energy = v
	)
	_add_slider_row(
		content,
		"Fog Density",
		0.0,
		0.01,
		cfg.fog_density,
		0.0001,
		func(v: float): cfg.fog_density = v
	)


# --- UI Helper Methods ---


func _add_section_header(parent: VBoxContainer, title: String) -> void:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.2)
	parent.add_child(sep)

	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", COLOR_SECTION)
	parent.add_child(lbl)


func _add_slider_row(
	parent: VBoxContainer,
	label_text: String,
	min_val: float,
	max_val: float,
	default_val: float,
	step_val: float,
	callback: Callable
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", COLOR_TEXT)
	lbl.custom_minimum_size = Vector2(140, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default_val
	slider.step = step_val
	slider.custom_minimum_size = Vector2(200, 18)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = _format_value(default_val, step_val)
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", COLOR_DIM)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.custom_minimum_size = Vector2(60, 0)
	row.add_child(val_lbl)

	slider.value_changed.connect(
		func(v: float):
			val_lbl.text = _format_value(v, step_val)
			callback.call(v)
	)

	parent.add_child(row)


func _add_checkbox_row(
	parent: VBoxContainer, label_text: String, default_val: bool, callback: Callable
) -> void:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = default_val
	cb.add_theme_font_size_override("font_size", 13)
	cb.add_theme_color_override("font_color", COLOR_TEXT)
	cb.mouse_filter = Control.MOUSE_FILTER_STOP
	cb.toggled.connect(callback)
	parent.add_child(cb)


func _format_value(val: float, step: float) -> String:
	if step >= 1.0:
		return "%d" % int(val)
	if step >= 0.01:
		return "%.2f" % val
	return "%.4f" % val


func _on_start_pressed() -> void:
	scenario_selected.emit(_config)


func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 36)
	btn.focus_mode = Control.FOCUS_ALL

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BUTTON
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = COLOR_BUTTON_HOVER
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := hover_style.duplicate()
	pressed_style.bg_color = COLOR_BUTTON_HOVER.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT)

	return btn


func _create_accent_button(text: String) -> Button:
	var btn := _create_menu_button(text)

	var accent_style := StyleBoxFlat.new()
	accent_style.bg_color = COLOR_ACCENT
	accent_style.corner_radius_top_left = 6
	accent_style.corner_radius_top_right = 6
	accent_style.corner_radius_bottom_left = 6
	accent_style.corner_radius_bottom_right = 6
	accent_style.content_margin_left = 16
	accent_style.content_margin_right = 16
	accent_style.content_margin_top = 8
	accent_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", accent_style)

	var hover_style := accent_style.duplicate()
	hover_style.bg_color = COLOR_ACCENT.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	return btn
