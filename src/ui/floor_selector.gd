class_name FloorSelector
extends Control
## UI panel for selecting and displaying the current floor
## Shows floor number with up/down buttons and handles keyboard shortcuts

signal floor_change_requested(new_floor: int)

# UI components
var _panel: PanelContainer
var _floor_label: Label
var _up_button: Button
var _down_button: Button


func _ready() -> void:
	_setup_ui()
	# Defer connection to ensure GameState autoload is ready
	call_deferred("_connect_to_game_state")


func _setup_ui() -> void:
	# Position at top-left corner
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 10
	offset_top = 10
	custom_minimum_size = Vector2(180, 40)

	# Create panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# Create horizontal container for layout
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	_panel.add_child(hbox)

	# Floor label
	_floor_label = Label.new()
	_floor_label.text = "Floor: 0"
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(_floor_label)

	# Up button
	_up_button = Button.new()
	_up_button.text = "^"
	_up_button.tooltip_text = "Go up (PageUp)"
	_up_button.custom_minimum_size = Vector2(30, 30)
	_up_button.pressed.connect(_on_up_pressed)
	hbox.add_child(_up_button)

	# Down button
	_down_button = Button.new()
	_down_button.text = "v"
	_down_button.tooltip_text = "Go down (PageDown)"
	_down_button.custom_minimum_size = Vector2(30, 30)
	_down_button.pressed.connect(_on_down_pressed)
	hbox.add_child(_down_button)


func _connect_to_game_state() -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state == null:
		push_warning("FloorSelector: GameState not found")
		return

	# Connect to floor_changed signal
	game_state.floor_changed.connect(_on_floor_changed)

	# Initialize display with current floor
	_update_display(game_state.current_floor)
	_update_button_states()


func _on_up_pressed() -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_up()


func _on_down_pressed() -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.floor_down()


func _on_floor_changed(new_floor: int) -> void:
	_update_display(new_floor)
	_update_button_states()
	floor_change_requested.emit(new_floor)


func _update_display(floor_num: int) -> void:
	_floor_label.text = "Floor: %d" % floor_num


func _update_button_states() -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state == null:
		return

	_up_button.disabled = not game_state.can_go_up()
	_down_button.disabled = not game_state.can_go_down()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	var key := event as InputEventKey

	# Handle PageUp/PageDown for floor changes
	match key.keycode:
		KEY_PAGEUP:
			_on_up_pressed()
			get_viewport().set_input_as_handled()
		KEY_PAGEDOWN:
			_on_down_pressed()
			get_viewport().set_input_as_handled()
