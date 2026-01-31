class_name ToolSidebar
extends PanelContainer
## Left sidebar with tool selection and quick access features
## Supports collapse/expand with hover, pin, and keyboard shortcuts
## See: documentation/ui/sidebars.md#left-sidebar

signal tool_selected(tool: Tool)
signal quick_build_selected(block_type: String)
signal favorite_selected(block_type: String)
signal expanded_changed(is_expanded: bool)

# Tool enum matching InputHandler modes
enum Tool { SELECT, BUILD, DEMOLISH, INFO, UPGRADE }

# Color constants (from HUD)
const COLOR_SIDEBAR := Color("#16213e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#e0e0e0")

# Size constants
const COLLAPSED_WIDTH := 56
const EXPANDED_WIDTH := 200
const BUTTON_SIZE_COLLAPSED := Vector2(44, 44)
const BUTTON_SIZE_EXPANDED := Vector2(180, 36)
const EXPAND_DELAY := 0.3  # Seconds before hover expands

# UI elements
var _vbox: VBoxContainer
var _menu_btn: Button
var _pin_btn: Button
var _tool_buttons: Dictionary = {}  # Tool -> Button
var _quick_build_section: VBoxContainer
var _quick_build_list: VBoxContainer
var _favorites_section: VBoxContainer
var _favorites_list: VBoxContainer

# State
var _expanded := false
var _pinned := false
var _hover_timer: Timer
var _current_tool: Tool = Tool.SELECT
var _recent_blocks: Array[String] = []  # Last 5 unique blocks
var _favorites: Array[String] = []  # Max 10 favorites


func _ready() -> void:
	_setup_ui()
	_setup_hover_behavior()
	_update_tool_selection(Tool.SELECT)


func _setup_ui() -> void:
	name = "ToolSidebar"
	custom_minimum_size = Vector2(COLLAPSED_WIDTH, 0)

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SIDEBAR
	style.border_color = COLOR_PANEL_BORDER
	style.border_width_right = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	# Main VBox
	_vbox = VBoxContainer.new()
	_vbox.name = "VBoxContainer"
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)

	# Header with menu and pin
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 4)
	_vbox.add_child(header)

	_menu_btn = _create_tool_button("≡", "Menu (Esc)", "MenuButton")
	header.add_child(_menu_btn)

	# Expanded header label (hidden when collapsed)
	var header_label := Label.new()
	header_label.text = "TOOLS"
	header_label.name = "HeaderLabel"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.visible = false
	header.add_child(header_label)

	_pin_btn = Button.new()
	_pin_btn.text = "📌"
	_pin_btn.tooltip_text = "Pin sidebar"
	_pin_btn.name = "PinButton"
	_pin_btn.toggle_mode = true
	_pin_btn.custom_minimum_size = Vector2(32, 32)
	_pin_btn.visible = false  # Only visible when expanded
	_pin_btn.pressed.connect(_on_pin_pressed)
	_style_button(_pin_btn)
	header.add_child(_pin_btn)

	# Separator
	var sep1 := HSeparator.new()
	_vbox.add_child(sep1)

	# Tool buttons
	var tools := VBoxContainer.new()
	tools.name = "Tools"
	tools.add_theme_constant_override("separation", 4)
	_vbox.add_child(tools)

	_tool_buttons[Tool.SELECT] = _create_tool_button("🔍", "Select (Q)", "SelectTool", true)
	_tool_buttons[Tool.SELECT].pressed.connect(_on_tool_pressed.bind(Tool.SELECT))
	tools.add_child(_tool_buttons[Tool.SELECT])

	_tool_buttons[Tool.BUILD] = _create_tool_button("🔨", "Build (B)", "BuildTool", true)
	_tool_buttons[Tool.BUILD].pressed.connect(_on_tool_pressed.bind(Tool.BUILD))
	tools.add_child(_tool_buttons[Tool.BUILD])

	_tool_buttons[Tool.DEMOLISH] = _create_tool_button("💥", "Demolish (X)", "DemolishTool", true)
	_tool_buttons[Tool.DEMOLISH].pressed.connect(_on_tool_pressed.bind(Tool.DEMOLISH))
	tools.add_child(_tool_buttons[Tool.DEMOLISH])

	_tool_buttons[Tool.INFO] = _create_tool_button("ℹ", "Info (I)", "InfoTool", true)
	_tool_buttons[Tool.INFO].pressed.connect(_on_tool_pressed.bind(Tool.INFO))
	tools.add_child(_tool_buttons[Tool.INFO])

	_tool_buttons[Tool.UPGRADE] = _create_tool_button("⬆", "Upgrade (U)", "UpgradeTool", true)
	_tool_buttons[Tool.UPGRADE].pressed.connect(_on_tool_pressed.bind(Tool.UPGRADE))
	tools.add_child(_tool_buttons[Tool.UPGRADE])

	# Quick Build section
	_quick_build_section = VBoxContainer.new()
	_quick_build_section.name = "QuickBuildSection"
	_quick_build_section.add_theme_constant_override("separation", 2)
	_vbox.add_child(_quick_build_section)

	var sep2 := HSeparator.new()
	_quick_build_section.add_child(sep2)

	var quick_label := Label.new()
	quick_label.text = "QUICK BUILD"
	quick_label.name = "QuickBuildLabel"
	quick_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_quick_build_section.add_child(quick_label)

	_quick_build_list = VBoxContainer.new()
	_quick_build_list.name = "QuickBuildList"
	_quick_build_list.add_theme_constant_override("separation", 2)
	_quick_build_section.add_child(_quick_build_list)

	# Favorites section
	_favorites_section = VBoxContainer.new()
	_favorites_section.name = "FavoritesSection"
	_favorites_section.add_theme_constant_override("separation", 2)
	_vbox.add_child(_favorites_section)

	var sep3 := HSeparator.new()
	_favorites_section.add_child(sep3)

	var fav_header := HBoxContainer.new()
	_favorites_section.add_child(fav_header)

	var fav_label := Label.new()
	fav_label.text = "FAVORITES"
	fav_label.name = "FavoritesLabel"
	fav_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fav_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	fav_header.add_child(fav_label)

	_favorites_list = VBoxContainer.new()
	_favorites_list.name = "FavoritesList"
	_favorites_list.add_theme_constant_override("separation", 2)
	_favorites_section.add_child(_favorites_list)

	# Initial state: collapsed, hide expanded elements
	_update_collapsed_state()


func _create_tool_button(
	icon: String, tooltip: String, btn_name: String, toggle: bool = false
) -> Button:
	var btn := Button.new()
	btn.text = icon
	btn.tooltip_text = tooltip
	btn.name = btn_name
	btn.toggle_mode = toggle
	btn.custom_minimum_size = BUTTON_SIZE_COLLAPSED
	_style_button(btn)
	return btn


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER

	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_BUTTON_ACTIVE

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)


func _setup_hover_behavior() -> void:
	_hover_timer = Timer.new()
	_hover_timer.name = "HoverTimer"
	_hover_timer.one_shot = true
	_hover_timer.wait_time = EXPAND_DELAY
	_hover_timer.timeout.connect(_on_hover_timeout)
	add_child(_hover_timer)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	if not _expanded and not _pinned:
		_hover_timer.start()


func _on_mouse_exited() -> void:
	_hover_timer.stop()
	if _expanded and not _pinned:
		_collapse()


func _on_hover_timeout() -> void:
	if not _expanded:
		_expand()


func _expand() -> void:
	_expanded = true
	_update_expanded_state()
	expanded_changed.emit(true)


func _collapse() -> void:
	_expanded = false
	_update_collapsed_state()
	expanded_changed.emit(false)


func _update_expanded_state() -> void:
	custom_minimum_size.x = EXPANDED_WIDTH

	# Show expanded elements
	var header_label := _vbox.get_node_or_null("Header/HeaderLabel")
	if header_label:
		header_label.visible = true
	if _pin_btn:
		_pin_btn.visible = true

	# Update tool buttons to show labels
	for tool_id: int in _tool_buttons:
		var btn: Button = _tool_buttons[tool_id]
		btn.custom_minimum_size = BUTTON_SIZE_EXPANDED
		btn.text = _get_tool_label(tool_id)

	# Show quick build and favorites
	_quick_build_section.visible = true
	_favorites_section.visible = true
	_populate_quick_build()
	_populate_favorites()


func _update_collapsed_state() -> void:
	custom_minimum_size.x = COLLAPSED_WIDTH

	# Hide expanded elements
	var header_label := _vbox.get_node_or_null("Header/HeaderLabel")
	if header_label:
		header_label.visible = false
	if _pin_btn:
		_pin_btn.visible = false

	# Update tool buttons to icon only
	for tool_id: int in _tool_buttons:
		var btn: Button = _tool_buttons[tool_id]
		btn.custom_minimum_size = BUTTON_SIZE_COLLAPSED
		btn.text = _get_tool_icon(tool_id)

	# Hide quick build and favorites
	_quick_build_section.visible = false
	_favorites_section.visible = false


func _get_tool_icon(tool: Tool) -> String:
	match tool:
		Tool.SELECT:
			return "🔍"
		Tool.BUILD:
			return "🔨"
		Tool.DEMOLISH:
			return "💥"
		Tool.INFO:
			return "ℹ"
		Tool.UPGRADE:
			return "⬆"
		_:
			return "?"


func _get_tool_label(tool: Tool) -> String:
	match tool:
		Tool.SELECT:
			return "🔍 Select      (Q)"
		Tool.BUILD:
			return "🔨 Build       (B)"
		Tool.DEMOLISH:
			return "💥 Demolish    (X)"
		Tool.INFO:
			return "ℹ  Info        (I)"
		Tool.UPGRADE:
			return "⬆  Upgrade     (U)"
		_:
			return "?"


func _on_pin_pressed() -> void:
	_pinned = not _pinned
	_pin_btn.button_pressed = _pinned
	if _pinned:
		_pin_btn.tooltip_text = "Unpin sidebar"
	else:
		_pin_btn.tooltip_text = "Pin sidebar"


func _on_tool_pressed(tool: Tool) -> void:
	_update_tool_selection(tool)
	tool_selected.emit(tool)


func _update_tool_selection(tool: Tool) -> void:
	_current_tool = tool
	for tool_id: int in _tool_buttons:
		var btn: Button = _tool_buttons[tool_id]
		btn.button_pressed = (tool_id == tool)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key := event as InputEventKey

	# Don't handle shortcuts if modifier keys are pressed
	if key.ctrl_pressed or key.alt_pressed:
		return

	match key.keycode:
		KEY_Q:
			_on_tool_pressed(Tool.SELECT)
			get_viewport().set_input_as_handled()
		KEY_B:
			_on_tool_pressed(Tool.BUILD)
			get_viewport().set_input_as_handled()
		KEY_X:
			_on_tool_pressed(Tool.DEMOLISH)
			get_viewport().set_input_as_handled()
		KEY_I:
			_on_tool_pressed(Tool.INFO)
			get_viewport().set_input_as_handled()
		KEY_U:
			_on_tool_pressed(Tool.UPGRADE)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _expanded and not _pinned:
				_collapse()
				get_viewport().set_input_as_handled()


## Add a block to recent blocks (Quick Build)
func add_recent_block(block_type: String) -> void:
	# Remove if already in list
	if block_type in _recent_blocks:
		_recent_blocks.erase(block_type)

	# Add to front
	_recent_blocks.insert(0, block_type)

	# Keep only last 5
	if _recent_blocks.size() > 5:
		_recent_blocks.resize(5)

	if _expanded:
		_populate_quick_build()


func _populate_quick_build() -> void:
	# Clear existing items
	for child in _quick_build_list.get_children():
		child.queue_free()

	# Add recent blocks
	for block_type in _recent_blocks:
		var btn := Button.new()
		btn.text = _format_block_name(block_type)
		btn.tooltip_text = "Select %s" % block_type
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 28)
		btn.pressed.connect(_on_quick_build_pressed.bind(block_type))
		_style_quick_button(btn)
		_quick_build_list.add_child(btn)


func _on_quick_build_pressed(block_type: String) -> void:
	quick_build_selected.emit(block_type)


## Add a block to favorites
func add_favorite(block_type: String) -> void:
	if block_type in _favorites:
		return  # Already a favorite

	if _favorites.size() >= 10:
		return  # Max 10 favorites

	_favorites.append(block_type)

	if _expanded:
		_populate_favorites()


## Remove a block from favorites
func remove_favorite(block_type: String) -> void:
	_favorites.erase(block_type)

	if _expanded:
		_populate_favorites()


func _populate_favorites() -> void:
	# Clear existing items
	for child in _favorites_list.get_children():
		child.queue_free()

	# Add favorites
	for block_type in _favorites:
		var item := HBoxContainer.new()

		var btn := Button.new()
		btn.text = _format_block_name(block_type)
		btn.tooltip_text = "Select %s" % block_type
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 28)
		btn.pressed.connect(_on_favorite_pressed.bind(block_type))
		_style_quick_button(btn)
		item.add_child(btn)

		var remove_btn := Button.new()
		remove_btn.text = "✕"
		remove_btn.tooltip_text = "Remove from favorites"
		remove_btn.custom_minimum_size = Vector2(24, 24)
		remove_btn.pressed.connect(remove_favorite.bind(block_type))
		_style_quick_button(remove_btn)
		item.add_child(remove_btn)

		_favorites_list.add_child(item)


func _on_favorite_pressed(block_type: String) -> void:
	favorite_selected.emit(block_type)


func _style_quick_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.content_margin_left = 4
	normal.content_margin_right = 4
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)


func _format_block_name(block_type: String) -> String:
	# Convert snake_case to Title Case and abbreviate
	var parts := block_type.split("_")
	if parts.size() > 0:
		var abbrev := parts[0].substr(0, 3).to_upper()
		var name := block_type.replace("_", " ").capitalize()
		return "[%s] %s" % [abbrev, name]
	return block_type


## Get current selected tool
func get_current_tool() -> Tool:
	return _current_tool


## Set current tool
func set_current_tool(tool: Tool) -> void:
	_update_tool_selection(tool)


## Check if sidebar is expanded
func is_expanded() -> bool:
	return _expanded


## Check if sidebar is pinned
func is_pinned() -> bool:
	return _pinned


## Toggle pin state
func toggle_pin() -> void:
	_on_pin_pressed()


## Force expand (for external control)
func expand() -> void:
	if not _expanded:
		_expand()


## Force collapse (for external control)
func collapse() -> void:
	if _expanded and not _pinned:
		_collapse()


## Get recent blocks list
func get_recent_blocks() -> Array[String]:
	return _recent_blocks


## Get favorites list
func get_favorites() -> Array[String]:
	return _favorites
