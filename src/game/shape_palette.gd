extends VBoxContainer

signal shape_selected(definition: Resource)

var registry: RefCounted
var _category_tabs: HBoxContainer
var _block_buttons_container: HBoxContainer
var _tab_buttons: Dictionary = {}  # String (category) -> Button
var _block_buttons: Dictionary = {}  # String (block id) -> Button
var _current_category: String = "transit"
var _current_id: String = "entrance"
var _categories: Array[String] = []


func _ready() -> void:
	if not registry:
		return
	_categories = registry.get_categories()
	_build_ui()


func _build_ui() -> void:
	# Category tabs row
	_category_tabs = HBoxContainer.new()
	_category_tabs.add_theme_constant_override("separation", 4)
	_category_tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_category_tabs)

	for cat in _categories:
		var btn := Button.new()
		btn.text = registry.get_category_display_name(cat)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(80, 30)

		var cat_color: Color = registry.get_category_color(cat)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.3)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)

		var style_pressed := StyleBoxFlat.new()
		style_pressed.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.7)
		style_pressed.corner_radius_top_left = 4
		style_pressed.corner_radius_top_right = 4
		style_pressed.corner_radius_bottom_left = 4
		style_pressed.corner_radius_bottom_right = 4
		style_pressed.content_margin_left = 8
		style_pressed.content_margin_right = 8
		style_pressed.content_margin_top = 4
		style_pressed.content_margin_bottom = 4
		btn.add_theme_stylebox_override("pressed", style_pressed)

		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.5)
		style_hover.corner_radius_top_left = 4
		style_hover.corner_radius_top_right = 4
		style_hover.corner_radius_bottom_left = 4
		style_hover.corner_radius_bottom_right = 4
		style_hover.content_margin_left = 8
		style_hover.content_margin_right = 8
		style_hover.content_margin_top = 4
		style_hover.content_margin_bottom = 4
		btn.add_theme_stylebox_override("hover", style_hover)

		btn.pressed.connect(_on_category_pressed.bind(cat))
		_category_tabs.add_child(btn)
		_tab_buttons[cat] = btn

	# Block buttons row
	_block_buttons_container = HBoxContainer.new()
	_block_buttons_container.add_theme_constant_override("separation", 4)
	_block_buttons_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_block_buttons_container)

	# Show default category
	_show_category(_current_category)


func _show_category(cat: String) -> void:
	_current_category = cat

	# Update tab highlighting
	for c in _tab_buttons:
		_tab_buttons[c].button_pressed = (c == cat)

	# Clear old block buttons
	for child in _block_buttons_container.get_children():
		child.queue_free()
	_block_buttons.clear()

	# Build block buttons for this category
	var defs: Array = registry.get_definitions_for_category(cat)
	var cat_color: Color = registry.get_category_color(cat)
	var index := 0
	for def in defs:
		index += 1
		var btn := Button.new()
		btn.text = "%d: %s" % [index, def.display_name]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(100, 36)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.25)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)

		var style_pressed := StyleBoxFlat.new()
		style_pressed.bg_color = Color(cat_color.r, cat_color.g, cat_color.b, 0.6)
		style_pressed.corner_radius_top_left = 3
		style_pressed.corner_radius_top_right = 3
		style_pressed.corner_radius_bottom_left = 3
		style_pressed.corner_radius_bottom_right = 3
		style_pressed.content_margin_left = 6
		style_pressed.content_margin_right = 6
		style_pressed.content_margin_top = 4
		style_pressed.content_margin_bottom = 4
		btn.add_theme_stylebox_override("pressed", style_pressed)

		btn.pressed.connect(_on_block_pressed.bind(def))
		_block_buttons_container.add_child(btn)
		_block_buttons[def.id] = btn

	# Highlight current selection if it's in this category
	if _block_buttons.has(_current_id):
		_block_buttons[_current_id].button_pressed = true


func _on_category_pressed(cat: String) -> void:
	_show_category(cat)


func _on_block_pressed(definition: Resource) -> void:
	highlight_definition(definition)
	shape_selected.emit(definition)


func highlight_definition(definition: Resource) -> void:
	_current_id = definition.id
	# Switch to the definition's category if needed
	if definition.category != _current_category:
		_show_category(definition.category)
	# Update block button highlighting
	for id in _block_buttons:
		_block_buttons[id].button_pressed = (id == _current_id)


func cycle_category(direction: int) -> void:
	if _categories.is_empty():
		return
	var idx := _categories.find(_current_category)
	if idx < 0:
		idx = 0
	idx = (idx + direction) % _categories.size()
	if idx < 0:
		idx += _categories.size()
	_show_category(_categories[idx])
	# Auto-select first block in new category
	var defs: Array = registry.get_definitions_for_category(_categories[idx])
	if defs.size() > 0:
		highlight_definition(defs[0])
		shape_selected.emit(defs[0])


func get_current_category_definitions() -> Array:
	return registry.get_definitions_for_category(_current_category)
