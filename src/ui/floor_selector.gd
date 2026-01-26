class_name FloorSelector
extends Control
## UI panel for selecting and displaying the current floor
## Shows floor number with up/down buttons and handles keyboard shortcuts

signal floor_change_requested(new_floor: int)

# UI components (minimal - visual UI now handled by HUD)
var _floor_label: Label
var _up_button: Button
var _down_button: Button


func _ready() -> void:
	_setup_ui()
	# Defer connection to ensure GameState autoload is ready
	call_deferred("_connect_to_game_state")


func _setup_ui() -> void:
	# Legacy UI - hidden since HUD now provides visual floor navigation
	# Keep this Control active for keyboard shortcut handling (PageUp/PageDown)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Still need internal references for programmatic access
	_floor_label = Label.new()
	_floor_label.text = "Floor: 0"
	add_child(_floor_label)

	# Placeholder buttons (hidden but needed for code that references them)
	_up_button = Button.new()
	_up_button.visible = false
	add_child(_up_button)

	_down_button = Button.new()
	_down_button.visible = false
	add_child(_down_button)


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
