class_name BuildToolbar
extends Control
## Build toolbar for selecting and placing blocks
## Shows category buttons with flyout panel for block selection
## See: documentation/ui/build-toolbar.md

# Signals
signal block_selected(block_type: String)
signal category_changed(category: String)

# Category definitions
const CATEGORIES := {
	"residential":  # Blue
	{"name": "Residential", "short": "Res", "color": Color("#3498db"), "icon": "🏠", "key": KEY_1},
	"commercial":  # Green
	{"name": "Commercial", "short": "Com", "color": Color("#2ecc71"), "icon": "🏪", "key": KEY_2},
	"industrial":  # Orange
	{"name": "Industrial", "short": "Ind", "color": Color("#e67e22"), "icon": "⚙", "key": KEY_3},
	"transit":  # Gray
	{"name": "Transit", "short": "Tra", "color": Color("#95a5a6"), "icon": "↔", "key": KEY_4},
	"green":  # Dark green
	{"name": "Green", "short": "Grn", "color": Color("#27ae60"), "icon": "🌿", "key": KEY_5},
	"civic":  # Purple
	{"name": "Civic", "short": "Civ", "color": Color("#9b59b6"), "icon": "🏛", "key": KEY_6},
	"infrastructure":  # Yellow
	{"name": "Infrastructure", "short": "Inf", "color": Color("#f1c40f"), "icon": "⚡", "key": KEY_7}
}

# Category order (matches keyboard shortcuts 1-7)
const CATEGORY_ORDER: Array[String] = [
	"residential", "commercial", "industrial", "transit", "green", "civic", "infrastructure"
]

# UI Constants
const CATEGORY_BUTTON_SIZE := Vector2(50, 50)
const FLYOUT_MIN_HEIGHT := 120
const FLYOUT_MAX_HEIGHT := 300
const BLOCK_TILE_SIZE := Vector2(80, 100)
const FLYOUT_ANIM_DURATION := 0.15

# UI nodes
var _category_container: HBoxContainer
var _flyout_panel: PanelContainer
var _flyout_content: GridContainer
var _category_buttons: Dictionary = {}  # category -> Button

# State
var _selected_category: String = ""
var _selected_block: String = ""
var _flyout_visible := false


func _ready() -> void:
	_setup_ui()
	call_deferred("_populate_categories")


func _setup_ui() -> void:
	# Main container - vertical layout with flyout above buttons
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create flyout panel (hidden by default)
	_flyout_panel = _create_flyout_panel()
	_flyout_panel.visible = false
	add_child(_flyout_panel)

	# Category buttons container
	_category_container = HBoxContainer.new()
	_category_container.add_theme_constant_override("separation", 4)
	_category_container.name = "CategoryButtons"
	add_child(_category_container)


func _create_flyout_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "FlyoutPanel"
	panel.custom_minimum_size = Vector2(400, FLYOUT_MIN_HEIGHT)

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a1a2e")
	style.border_color = Color("#0f3460")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	# VBox for header and content
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header with title and close button
	var header := HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)

	var title := Label.new()
	title.name = "CategoryTitle"
	title.text = "Category"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.name = "CloseButton"
	close_btn.pressed.connect(_close_flyout)
	header.add_child(close_btn)

	# Scroll container for blocks
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(scroll)

	# Grid container for block tiles
	_flyout_content = GridContainer.new()
	_flyout_content.name = "BlockGrid"
	_flyout_content.columns = 5
	_flyout_content.add_theme_constant_override("h_separation", 8)
	_flyout_content.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_flyout_content)

	return panel


func _populate_categories() -> void:
	# Create a button for each category
	for i in range(CATEGORY_ORDER.size()):
		var category: String = CATEGORY_ORDER[i]
		var cat_data: Dictionary = CATEGORIES[category]
		_create_category_button(category, cat_data, i + 1)


func _create_category_button(category: String, cat_data: Dictionary, shortcut_num: int) -> void:
	var btn := Button.new()
	btn.name = category.capitalize() + "Button"
	btn.text = cat_data["short"]
	btn.tooltip_text = "%s (%d)" % [cat_data["name"], shortcut_num]
	btn.toggle_mode = true
	btn.custom_minimum_size = CATEGORY_BUTTON_SIZE

	# Style with category color
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color("#0f3460")
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = cat_data["color"].darkened(0.2)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = cat_data["color"]
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.pressed.connect(_on_category_pressed.bind(category))

	_category_container.add_child(btn)
	_category_buttons[category] = btn


func _on_category_pressed(category: String) -> void:
	if _selected_category == category and _flyout_visible:
		# Toggle off
		_close_flyout()
	else:
		_open_flyout(category)


func _open_flyout(category: String) -> void:
	_selected_category = category

	# Update button states
	for cat in _category_buttons:
		_category_buttons[cat].button_pressed = (cat == category)

	# Update flyout title
	var title: Label = _flyout_panel.get_node("VBoxContainer/Header/CategoryTitle")
	if title:
		title.text = CATEGORIES[category]["name"]

	# Populate blocks for this category
	_populate_blocks(category)

	# Position flyout above the toolbar
	_flyout_panel.position = Vector2(0, -_flyout_panel.size.y - 8)

	# Show with animation
	_flyout_panel.visible = true
	_flyout_panel.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(_flyout_panel, "modulate:a", 1.0, FLYOUT_ANIM_DURATION)

	_flyout_visible = true
	category_changed.emit(category)


func _close_flyout() -> void:
	if not _flyout_visible:
		return

	# Deselect category button
	if _selected_category != "" and _category_buttons.has(_selected_category):
		_category_buttons[_selected_category].button_pressed = false

	# Hide with animation
	var tween := create_tween()
	tween.tween_property(_flyout_panel, "modulate:a", 0.0, FLYOUT_ANIM_DURATION)
	tween.tween_callback(func(): _flyout_panel.visible = false)

	_flyout_visible = false
	_selected_category = ""


func _populate_blocks(category: String) -> void:
	# Clear existing blocks
	for child in _flyout_content.get_children():
		child.queue_free()

	# Get BlockRegistry
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		push_warning("BuildToolbar: BlockRegistry not found")
		return

	# Get all blocks in this category
	var blocks: Array = registry.get_types_by_category(category)
	if blocks.is_empty():
		# Show "No blocks" placeholder
		var placeholder := Label.new()
		placeholder.text = "No blocks available"
		placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_flyout_content.add_child(placeholder)
		return

	# Create tile for each block
	for block_type in blocks:
		var block_data: Dictionary = registry.get_block_data(block_type)
		_create_block_tile(block_type, block_data)


func _create_block_tile(block_type: String, block_data: Dictionary) -> void:
	var tile := VBoxContainer.new()
	tile.name = block_type
	tile.custom_minimum_size = BLOCK_TILE_SIZE

	# Container for sprite and selection highlight
	var sprite_container := PanelContainer.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2a2a4e")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	sprite_container.add_theme_stylebox_override("panel", style)

	# Center container for sprite
	var center := CenterContainer.new()
	sprite_container.add_child(center)

	# Block sprite
	var sprite_path: String = block_data.get("sprite", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var texture := load(sprite_path) as Texture2D
		if texture:
			var tex_rect := TextureRect.new()
			tex_rect.texture = texture
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(48, 48)
			center.add_child(tex_rect)

	tile.add_child(sprite_container)

	# Block name
	var name_label := Label.new()
	name_label.text = block_data.get("name", block_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	tile.add_child(name_label)

	# Cost
	var cost: int = block_data.get("cost", 0)
	var cost_label := Label.new()
	cost_label.text = "$%s" % _format_cost(cost)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	tile.add_child(cost_label)

	# Make the whole tile clickable
	var click_area := Button.new()
	click_area.flat = true
	click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_area.mouse_filter = Control.MOUSE_FILTER_PASS
	click_area.pressed.connect(_on_block_tile_pressed.bind(block_type))

	# Add click area over the sprite container
	sprite_container.add_child(click_area)

	_flyout_content.add_child(tile)


func _on_block_tile_pressed(block_type: String) -> void:
	_selected_block = block_type
	block_selected.emit(block_type)

	# Highlight selected tile (optional visual feedback)
	_update_tile_selection(block_type)


func _update_tile_selection(selected_type: String) -> void:
	# Update visual state of all tiles
	for child in _flyout_content.get_children():
		if child is VBoxContainer:
			var sprite_container := child.get_child(0) as PanelContainer
			if sprite_container:
				var style := StyleBoxFlat.new()
				if child.name == selected_type:
					style.bg_color = Color("#3a6a9e")  # Highlighted
					style.border_color = Color("#e94560")
					style.border_width_left = 2
					style.border_width_right = 2
					style.border_width_top = 2
					style.border_width_bottom = 2
				else:
					style.bg_color = Color("#2a2a4e")  # Normal
				style.corner_radius_top_left = 4
				style.corner_radius_top_right = 4
				style.corner_radius_bottom_left = 4
				style.corner_radius_bottom_right = 4
				sprite_container.add_theme_stylebox_override("panel", style)


func _format_cost(cost: int) -> String:
	if cost >= 1000:
		return "%.1fK" % (cost / 1000.0)
	return str(cost)


func _input(event: InputEvent) -> void:
	# Close flyout when clicking outside of it
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _flyout_visible:
			var mouse_event := event as InputEventMouseButton
			var mouse_pos: Vector2 = mouse_event.position
			var flyout_rect: Rect2 = _flyout_panel.get_global_rect()
			var toolbar_rect: Rect2 = _category_container.get_global_rect()

			# Check if click is outside both flyout and category buttons
			if not flyout_rect.has_point(mouse_pos) and not toolbar_rect.has_point(mouse_pos):
				print("[BuildToolbar] Click outside flyout, closing")
				_close_flyout()
				# Don't consume the event - let it pass through to game


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	var key := event as InputEventKey

	# Escape closes flyout
	if key.keycode == KEY_ESCAPE and _flyout_visible:
		_close_flyout()
		get_viewport().set_input_as_handled()
		return

	# Number keys 1-7 open categories
	for i in range(CATEGORY_ORDER.size()):
		var category: String = CATEGORY_ORDER[i]
		var cat_data: Dictionary = CATEGORIES[category]
		if key.keycode == cat_data["key"]:
			_on_category_pressed(category)
			get_viewport().set_input_as_handled()
			return


## Get the currently selected block type
func get_selected_block() -> String:
	return _selected_block


## Get the currently selected category
func get_selected_category() -> String:
	return _selected_category


## Check if the flyout is visible
func is_flyout_visible() -> bool:
	return _flyout_visible


## Programmatically select a block
func select_block(block_type: String) -> void:
	_selected_block = block_type
	block_selected.emit(block_type)
