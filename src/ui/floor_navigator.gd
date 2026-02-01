class_name FloorNavigator
extends Control
## Floor navigation widget for HUD bottom bar
## Shows current floor with up/down buttons and extended floor list popup
## In isolate visibility mode, shows the isolated floor instead
## See: documentation/ui/sidebars.md#floor-navigator

signal floor_changed(floor_num: int)

# Color constants (from HUD)
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_PANEL_BG := Color("#16213e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_HIGHLIGHT := Color("#e94560")
const COLOR_ISOLATE_MODE := Color("#ff9800")  # Orange for isolate mode

# Size constants
const BUTTON_SIZE := Vector2(36, 36)
const FLOOR_LABEL_WIDTH := 80

# UI elements
var _up_button: Button
var _down_button: Button
var _floor_button: Button
var _floor_list_popup: Control

# State
var _popup_visible := false
var _show_all_floors := false
var _isolate_mode := false
var _isolate_floor := 0


func _ready() -> void:
	add_to_group("floor_navigator")
	_setup_ui()
	_connect_game_state()


func _setup_ui() -> void:
	name = "FloorNavigator"

	# Main container - horizontal layout
	var main_box := HBoxContainer.new()
	main_box.add_theme_constant_override("separation", 4)
	main_box.name = "MainBox"
	add_child(main_box)

	# Down button
	_down_button = _create_nav_button("▼", "Floor Down (PageDown)", "DownButton")
	_down_button.pressed.connect(_on_down_pressed)
	main_box.add_child(_down_button)

	# Floor display button (clickable for popup)
	_floor_button = Button.new()
	_floor_button.text = "F0"
	_floor_button.tooltip_text = "Click for floor list"
	_floor_button.custom_minimum_size = Vector2(FLOOR_LABEL_WIDTH, BUTTON_SIZE.y)
	_floor_button.name = "FloorButton"
	_floor_button.pressed.connect(_on_floor_button_pressed)
	_style_floor_button(_floor_button)
	main_box.add_child(_floor_button)

	# Up button
	_up_button = _create_nav_button("▲", "Floor Up (PageUp)", "UpButton")
	_up_button.pressed.connect(_on_up_pressed)
	main_box.add_child(_up_button)

	# Floor list popup (initially hidden)
	_floor_list_popup = _create_floor_list_popup()
	_floor_list_popup.visible = false
	add_child(_floor_list_popup)


func _create_nav_button(text: String, tooltip: String, btn_name: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = BUTTON_SIZE
	btn.name = btn_name
	_style_nav_button(btn)
	return btn


func _style_nav_button(btn: Button) -> void:
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

	var disabled := normal.duplicate()
	disabled.bg_color = COLOR_BUTTON.darkened(0.3)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)


func _style_floor_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PANEL_BG
	normal.border_color = COLOR_PANEL_BORDER
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate()
	hover.border_color = COLOR_BUTTON_HOVER

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)


func _create_floor_list_popup() -> Control:
	var popup := PanelContainer.new()
	popup.name = "FloorListPopup"
	popup.custom_minimum_size = Vector2(180, 0)

	# Style the popup
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 4)
	popup.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "FLOOR SELECTOR"
	header.name = "Header"
	header.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(header)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Scroll container for floor list
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.custom_minimum_size = Vector2(160, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	# Floor list container
	var floor_list := VBoxContainer.new()
	floor_list.name = "FloorList"
	floor_list.add_theme_constant_override("separation", 2)
	scroll.add_child(floor_list)

	return popup


func _connect_game_state() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_changed.connect(_on_game_state_floor_changed)
		# Initialize with current state
		_update_display(game_state.current_floor)
		_update_button_states()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key := event as InputEventKey

	match key.keycode:
		KEY_PAGEUP:
			if key.ctrl_pressed:
				_go_to_top_floor()
			else:
				_on_up_pressed()
			get_viewport().set_input_as_handled()
		KEY_PAGEDOWN:
			if key.ctrl_pressed:
				_go_to_ground_floor()
			else:
				_on_down_pressed()
			get_viewport().set_input_as_handled()
		KEY_E:
			if not key.ctrl_pressed and not key.shift_pressed and not key.alt_pressed:
				_on_up_pressed()
				get_viewport().set_input_as_handled()
		KEY_C:
			if not key.ctrl_pressed and not key.shift_pressed and not key.alt_pressed:
				_on_down_pressed()
				get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _popup_visible:
				_hide_floor_list()
				get_viewport().set_input_as_handled()


func _on_up_pressed() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_up()


func _on_down_pressed() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_down()


func _go_to_top_floor() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_floor(game_state.MAX_FLOOR)


func _go_to_ground_floor() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_floor(0)


func _on_floor_button_pressed() -> void:
	if _popup_visible:
		_hide_floor_list()
	else:
		_show_floor_list()


func _on_game_state_floor_changed(new_floor: int) -> void:
	_update_display(new_floor)
	_update_button_states()
	_update_floor_list_selection(new_floor)
	floor_changed.emit(new_floor)


func _update_display(floor_num: int) -> void:
	if not _floor_button:
		return

	# Determine which floor to display based on mode
	var display_floor := floor_num
	if _isolate_mode:
		display_floor = _isolate_floor

	# Show view mode
	if _show_all_floors:
		_floor_button.text = "ALL"
		_floor_button.tooltip_text = "Viewing all floors (V to toggle)"
		_reset_floor_button_style()
	elif _isolate_mode:
		# Isolate mode: show isolated floor with indicator
		if display_floor < 0:
			_floor_button.text = "⊙B%d" % abs(display_floor)  # Basement isolated
		elif display_floor == 0:
			_floor_button.text = "⊙F0"  # Ground isolated
		else:
			_floor_button.text = "⊙F%d" % display_floor
		_floor_button.tooltip_text = "Isolate mode: Floor %d only (I to exit, E/C adjust)" % display_floor
		_apply_isolate_style()
	else:
		# Format floor display for normal/cutaway mode
		if display_floor < 0:
			_floor_button.text = "B%d" % abs(display_floor)  # Basement
		elif display_floor == 0:
			_floor_button.text = "F0 (G)"  # Ground
		else:
			_floor_button.text = "F%d" % display_floor
		_floor_button.tooltip_text = "Click for floor list (V for all floors)"
		_reset_floor_button_style()


func _update_button_states() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if not game_state:
		return

	if _up_button:
		_up_button.disabled = not game_state.can_go_up()
	if _down_button:
		_down_button.disabled = not game_state.can_go_down()


func _show_floor_list() -> void:
	if not _floor_list_popup:
		return

	_popup_visible = true
	_populate_floor_list()

	# Position popup above the floor button
	var floor_btn_pos := _floor_button.global_position
	_floor_list_popup.global_position = Vector2(
		floor_btn_pos.x - 50, floor_btn_pos.y - _floor_list_popup.size.y - 8  # Center above button
	)

	_floor_list_popup.visible = true


func _hide_floor_list() -> void:
	if _floor_list_popup:
		_floor_list_popup.visible = false
	_popup_visible = false


func _populate_floor_list() -> void:
	var scroll: ScrollContainer = _floor_list_popup.get_node_or_null(
		"VBoxContainer/ScrollContainer"
	)
	if not scroll:
		return

	var floor_list: VBoxContainer = scroll.get_node_or_null("FloorList")
	if not floor_list:
		return

	# Clear existing items
	for child in floor_list.get_children():
		child.queue_free()

	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if not game_state:
		return

	var current_floor: int = game_state.current_floor
	var min_floor: int = game_state.MIN_FLOOR
	var max_floor: int = game_state.MAX_FLOOR

	# Get grid for floor state
	var grid = _find_grid()

	# Add floors from top to bottom
	for floor_num in range(max_floor, min_floor - 1, -1):
		var floor_item := _create_floor_item(floor_num, current_floor, grid)
		floor_list.add_child(floor_item)


func _create_floor_item(floor_num: int, current_floor: int, grid) -> Button:
	var btn := Button.new()
	btn.name = "Floor_%d" % floor_num

	# Format floor name
	var floor_name: String
	var indicator: String = _get_floor_indicator(floor_num, current_floor, grid)

	if floor_num < 0:
		floor_name = "B%d" % abs(floor_num)
		if floor_num == -1:
			floor_name += " Basement"
	elif floor_num == 0:
		floor_name = "01 Ground"
	elif floor_num == 10:
		floor_name = "%02d Penthouse" % floor_num
	else:
		floor_name = "%02d" % floor_num

	btn.text = "%s [%s]" % [indicator, floor_name]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Highlight current floor
	var is_current := floor_num == current_floor
	_style_floor_item(btn, is_current)

	# Connect click
	btn.pressed.connect(_on_floor_item_pressed.bind(floor_num))

	return btn


func _get_floor_indicator(floor_num: int, current_floor: int, grid) -> String:
	if floor_num == current_floor:
		return "●"  # Current floor

	# Check if floor has blocks
	if grid and grid.has_method("get_blocks_on_floor"):
		var block_count: int = grid.get_blocks_on_floor(floor_num).size()
		if block_count == 0:
			return "∅"  # Empty

	# Default: has content but not current
	return "◐"


func _style_floor_item(btn: Button, is_current: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_TEXT_HIGHLIGHT if is_current else Color.TRANSPARENT
	normal.corner_radius_top_left = 2
	normal.corner_radius_top_right = 2
	normal.corner_radius_bottom_left = 2
	normal.corner_radius_bottom_right = 2
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER.lightened(0.2) if is_current else COLOR_BUTTON

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)

	if is_current:
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.add_theme_color_override("font_color", COLOR_TEXT)


func _on_floor_item_pressed(floor_num: int) -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_floor(floor_num)

	_hide_floor_list()


func _update_floor_list_selection(_new_floor: int) -> void:
	if not _popup_visible:
		return

	# Repopulate to update highlighting
	_populate_floor_list()


func _find_grid():
	# Try to find Grid in the scene tree
	var tree := get_tree()
	if not tree or not tree.root:
		return null

	# Look for Grid node - it should be under root scene
	var root := tree.root
	for child in root.get_children():
		if child.has_method("get_block_at"):
			return child
		# Check one level deeper
		for grandchild in child.get_children():
			if grandchild.has_method("get_block_at"):
				return grandchild

	return null


## Get current floor number
func get_current_floor() -> int:
	var tree := get_tree()
	if not tree:
		return 0

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		return game_state.current_floor
	return 0


## Check if popup is visible
func is_popup_visible() -> bool:
	return _popup_visible


## Manually update display (for testing)
func update_display(floor_num: int) -> void:
	_update_display(floor_num)


## Get floor display text
func get_floor_text() -> String:
	if _floor_button:
		return _floor_button.text
	return ""


## Set view mode (all floors vs cutaway)
func set_view_mode(show_all: bool) -> void:
	_show_all_floors = show_all
	# Update display with current floor
	_refresh_display()


## Set isolate mode state
func set_isolate_mode(enabled: bool, floor_num: int = 0) -> void:
	_isolate_mode = enabled
	_isolate_floor = floor_num
	_refresh_display()


## Update the isolated floor (called when floor changes in isolate mode)
func set_isolate_floor(floor_num: int) -> void:
	_isolate_floor = floor_num
	if _isolate_mode:
		_refresh_display()


## Check if currently in isolate mode
func is_isolate_mode() -> bool:
	return _isolate_mode


## Get the current isolated floor
func get_isolate_floor() -> int:
	return _isolate_floor


## Helper to refresh display with current floor
func _refresh_display() -> void:
	var tree := get_tree()
	if tree:
		var game_state = tree.get_root().get_node_or_null("/root/GameState")
		if game_state:
			_update_display(game_state.current_floor)
			return
	_update_display(0)


## Apply orange styling for isolate mode indicator
func _apply_isolate_style() -> void:
	if not _floor_button:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_ISOLATE_MODE.darkened(0.6)
	normal.border_color = COLOR_ISOLATE_MODE
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate()
	hover.border_color = COLOR_ISOLATE_MODE.lightened(0.3)

	_floor_button.add_theme_stylebox_override("normal", normal)
	_floor_button.add_theme_stylebox_override("hover", hover)
	_floor_button.add_theme_color_override("font_color", COLOR_ISOLATE_MODE)


## Reset floor button to default styling
func _reset_floor_button_style() -> void:
	if not _floor_button:
		return
	_style_floor_button(_floor_button)
