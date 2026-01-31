class_name InfoPanel
extends VBoxContainer
## Base class for all info panels (block info, resident info, budget, AEI)
## Provides common styling, sections, and behavior
## See: documentation/ui/info-panels.md

signal close_requested
signal pin_toggled(pinned: bool)
signal action_pressed(action_name: String)

# Color constants (match HUD color scheme)
const COLOR_SECTION_BG := Color("#1a1a2e")
const COLOR_SECTION_BORDER := Color("#0f3460")
const COLOR_BAR_BG := Color("#2d2d44")
const COLOR_BAR_FILL := Color("#e94560")
const COLOR_BAR_FILL_GREEN := Color("#4ecdc4")
const COLOR_BAR_FILL_YELLOW := Color("#f9ca24")
const COLOR_BAR_FILL_RED := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#a0a0a0")
const COLOR_TEXT_POSITIVE := Color("#4ecdc4")
const COLOR_TEXT_NEGATIVE := Color("#e94560")

# Status colors (from documentation)
const STATUS_OCCUPIED := Color("#4ecdc4")  # Green
const STATUS_VACANT := Color("#f9ca24")  # Yellow
const STATUS_CONSTRUCTION := Color("#3498db")  # Blue
const STATUS_DAMAGED := Color("#e67e22")  # Orange
const STATUS_CONDEMNED := Color("#e94560")  # Red

# Panel state
var _pinned := false
var _sections: Dictionary = {}  # name -> section container


func _init() -> void:
	add_theme_constant_override("separation", 0)


## Create a section with a title header
func add_section(
	section_name: String, title: String = "", collapsible: bool = false
) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = section_name
	section.add_theme_constant_override("separation", 4)

	# Section panel styling
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SECTION_BG
	style.border_color = COLOR_SECTION_BORDER
	style.border_width_bottom = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	# Title header if provided
	if title != "":
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 4)

		if collapsible:
			var collapse_btn := Button.new()
			collapse_btn.text = "▼"
			collapse_btn.flat = true
			collapse_btn.custom_minimum_size = Vector2(20, 20)
			collapse_btn.pressed.connect(_toggle_section.bind(section_name))
			header.add_child(collapse_btn)

		var label := Label.new()
		label.text = title
		label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		label.add_theme_font_size_override("font_size", 12)
		header.add_child(label)

		section.add_child(header)

	# Content container
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 4)
	section.add_child(content)

	panel.add_child(section)
	add_child(panel)

	_sections[section_name] = content
	return content


## Get a section's content container
func get_section(section_name: String) -> VBoxContainer:
	return _sections.get(section_name)


## Toggle section visibility (for collapsible sections)
func _toggle_section(section_name: String) -> void:
	var section: VBoxContainer = _sections.get(section_name)
	if section:
		section.visible = not section.visible


## Create a progress bar with label
func create_bar(
	label_text: String,
	value: float,
	max_value: float = 100.0,
	bar_color: Color = COLOR_BAR_FILL,
	show_percent: bool = true
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Label
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)

	# Progress bar container
	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(100, 16)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_container)

	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = COLOR_BAR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_container.add_child(bg)

	# Fill
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = bar_color
	fill.anchor_left = 0
	fill.anchor_top = 0
	fill.anchor_right = clampf(value / max_value, 0.0, 1.0)
	fill.anchor_bottom = 1.0
	fill.offset_left = 0
	fill.offset_top = 0
	fill.offset_right = 0
	fill.offset_bottom = 0
	bar_container.add_child(fill)

	# Value label
	var value_label := Label.new()
	if show_percent:
		value_label.text = "%d%%" % int(value)
	else:
		value_label.text = "%d" % int(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(value_label)

	return row


## Create a stat row with label and value
func create_stat_row(
	label_text: String, value_text: String, value_color: Color = COLOR_TEXT
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", value_color)
	row.add_child(value)

	return row


## Create an action button
func create_action_button(text: String, action_name: String, tooltip: String = "") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.pressed.connect(func(): action_pressed.emit(action_name))
	return btn


## Create an action bar with multiple buttons
func create_action_bar(actions: Array[Dictionary]) -> HBoxContainer:
	# Each dict: {text: String, action: String, tooltip: String (optional)}
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER

	for action in actions:
		var btn := create_action_button(
			action.get("text", "Action"), action.get("action", ""), action.get("tooltip", "")
		)
		bar.add_child(btn)

	return bar


## Update a progress bar value
func update_bar(
	bar_row: HBoxContainer,
	value: float,
	max_value: float = 100.0,
	bar_color: Color = COLOR_BAR_FILL,
	show_percent: bool = true
) -> void:
	# Find the bar container (second child)
	if bar_row.get_child_count() >= 3:
		var bar_container := bar_row.get_child(1) as Control
		if bar_container:
			var fill := bar_container.get_node_or_null("Fill") as ColorRect
			if fill:
				fill.color = bar_color
				fill.anchor_right = clampf(value / max_value, 0.0, 1.0)

		# Update value label (third child)
		var value_label := bar_row.get_child(2) as Label
		if value_label:
			if show_percent:
				value_label.text = "%d%%" % int(value)
			else:
				value_label.text = "%d" % int(value)


## Get bar color based on value threshold
func get_bar_color_by_value(
	value: float, low_threshold: float = 40.0, high_threshold: float = 70.0
) -> Color:
	if value >= high_threshold:
		return COLOR_BAR_FILL_GREEN
	if value >= low_threshold:
		return COLOR_BAR_FILL_YELLOW
	return COLOR_BAR_FILL_RED


## Get status color
func get_status_color(status: String) -> Color:
	match status.to_lower():
		"occupied":
			return STATUS_OCCUPIED
		"vacant":
			return STATUS_VACANT
		"under construction", "construction":
			return STATUS_CONSTRUCTION
		"damaged":
			return STATUS_DAMAGED
		"condemned":
			return STATUS_CONDEMNED
		_:
			return COLOR_TEXT


## Create header with sprite, name, and close button
func create_header(
	sprite_texture: Texture2D,
	title: String,
	subtitle: String,
	show_pin: bool = true,
	show_close: bool = true
) -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	# Sprite
	if sprite_texture:
		var sprite := TextureRect.new()
		sprite.texture = sprite_texture
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.custom_minimum_size = Vector2(48, 48)
		header.add_child(sprite)

	# Text info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	info.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	info.add_child(subtitle_label)

	header.add_child(info)

	# Pin button
	if show_pin:
		var pin_btn := Button.new()
		pin_btn.text = "📌" if _pinned else "📍"
		pin_btn.tooltip_text = "Unpin" if _pinned else "Pin"
		pin_btn.flat = true
		pin_btn.custom_minimum_size = Vector2(24, 24)
		pin_btn.name = "PinButton"
		pin_btn.pressed.connect(_on_pin_pressed)
		header.add_child(pin_btn)

	# Close button
	if show_close:
		var close_btn := Button.new()
		close_btn.text = "✕"
		close_btn.tooltip_text = "Close"
		close_btn.flat = true
		close_btn.custom_minimum_size = Vector2(24, 24)
		close_btn.name = "CloseButton"
		close_btn.pressed.connect(_on_close_pressed)
		header.add_child(close_btn)

	return header


## Pin/unpin toggle
func _on_pin_pressed() -> void:
	_pinned = not _pinned
	var pin_btn := get_node_or_null("PinButton") as Button
	if pin_btn:
		pin_btn.text = "📌" if _pinned else "📍"
		pin_btn.tooltip_text = "Unpin" if _pinned else "Pin"
	pin_toggled.emit(_pinned)


## Close button
func _on_close_pressed() -> void:
	close_requested.emit()


## Check if panel is pinned
func is_pinned() -> bool:
	return _pinned


## Set pinned state
func set_pinned(pinned: bool) -> void:
	_pinned = pinned
	var pin_btn := get_node_or_null("PinButton") as Button
	if pin_btn:
		pin_btn.text = "📌" if _pinned else "📍"
		pin_btn.tooltip_text = "Unpin" if _pinned else "Pin"


## Clear all sections and content
func clear() -> void:
	for child in get_children():
		child.queue_free()
	_sections.clear()


## Format money with $ and commas
func format_money(amount: int) -> String:
	var s := str(abs(amount))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("$" if amount >= 0 else "-$") + result


## Format number with commas
func format_number(num: int) -> String:
	var s := str(abs(num))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return ("-" if num < 0 else "") + result
