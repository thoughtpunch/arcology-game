class_name TimeControls
extends HBoxContainer
## Time control UI component
## Displays date/time and provides speed control buttons
## See: documentation/ui/sidebars.md#speed-controls

# Color constants (from HUD)
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_BUTTON_ACTIVE := Color("#e94560")
const COLOR_TEXT := Color("#ffffff")

# Animation constants
const CLOCK_PULSE_DURATION := 0.5

# UI elements
var _pause_btn: Button
var _speed1_btn: Button
var _speed2_btn: Button
var _speed3_btn: Button
var _datetime_label: Label
var _clock_icon: Label

# State
var _current_speed: int = 1
var _is_paused: bool = false
var _pulse_tween: Tween


func _ready() -> void:
	_setup_ui()
	_connect_game_state()
	_update_button_states()


func _setup_ui() -> void:
	name = "TimeControls"
	add_theme_constant_override("separation", 8)

	# Date/time display with clock icon
	var datetime_box := HBoxContainer.new()
	datetime_box.add_theme_constant_override("separation", 4)
	add_child(datetime_box)

	_clock_icon = Label.new()
	_clock_icon.text = "🕐"
	_clock_icon.name = "ClockIcon"
	datetime_box.add_child(_clock_icon)

	_datetime_label = Label.new()
	_datetime_label.text = "Y1 M1 D1"
	_datetime_label.name = "DateTimeLabel"
	_datetime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_datetime_label.custom_minimum_size = Vector2(100, 0)
	datetime_box.add_child(_datetime_label)

	# Time of day indicator
	var tod_label := Label.new()
	tod_label.text = "🌅"
	tod_label.name = "TimeOfDayLabel"
	datetime_box.add_child(tod_label)

	# Separator
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 24)
	add_child(sep)

	# Speed control buttons
	var speed_box := HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 2)
	speed_box.name = "SpeedButtons"
	add_child(speed_box)

	_pause_btn = _create_speed_button("⏸", "Pause (Space)", "PauseButton")
	speed_box.add_child(_pause_btn)

	_speed1_btn = _create_speed_button("▶", "Normal speed (1)", "Speed1Button")
	_speed1_btn.button_pressed = true  # Default selected
	speed_box.add_child(_speed1_btn)

	_speed2_btn = _create_speed_button("▶▶", "Fast speed (2)", "Speed2Button")
	speed_box.add_child(_speed2_btn)

	_speed3_btn = _create_speed_button("▶▶▶", "Fastest speed (3)", "Speed3Button")
	speed_box.add_child(_speed3_btn)

	# Connect button signals
	_pause_btn.pressed.connect(_on_pause_pressed)
	_speed1_btn.pressed.connect(_on_speed1_pressed)
	_speed2_btn.pressed.connect(_on_speed2_pressed)
	_speed3_btn.pressed.connect(_on_speed3_pressed)


func _create_speed_button(text: String, tooltip: String, btn_name: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(36, 28)
	btn.name = btn_name
	_style_button(btn)
	return btn


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER

	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_BUTTON_ACTIVE

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)


func _connect_game_state() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.time_changed.connect(_on_time_changed)
		game_state.speed_changed.connect(_on_speed_changed)
		game_state.paused_changed.connect(_on_paused_changed)

		# Initialize with current state
		_update_datetime(game_state.year, game_state.month, game_state.day, game_state.hour)
		_current_speed = game_state.game_speed
		_is_paused = game_state.paused
		_update_button_states()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_toggle_pause()
				get_viewport().set_input_as_handled()
			KEY_1:
				_set_speed(1)
				get_viewport().set_input_as_handled()
			KEY_2:
				_set_speed(2)
				get_viewport().set_input_as_handled()
			KEY_3:
				_set_speed(3)
				get_viewport().set_input_as_handled()


func _on_pause_pressed() -> void:
	_toggle_pause()


func _on_speed1_pressed() -> void:
	_set_speed(1)


func _on_speed2_pressed() -> void:
	_set_speed(2)


func _on_speed3_pressed() -> void:
	_set_speed(3)


func _toggle_pause() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.toggle_pause()


func _set_speed(speed: int) -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_game_speed(speed)


func _on_time_changed(year: int, month: int, day: int, hour: int) -> void:
	_update_datetime(year, month, day, hour)


func _on_speed_changed(speed: int) -> void:
	_current_speed = speed
	_update_button_states()
	_update_clock_animation()


func _on_paused_changed(paused: bool) -> void:
	_is_paused = paused
	_update_button_states()
	_update_clock_animation()


func _update_datetime(year: int, month: int, day: int, hour: int) -> void:
	if _datetime_label:
		_datetime_label.text = "Y%d M%d D%d" % [year, month, day]

	# Update time of day icon
	var tod_label: Label = get_node_or_null("HBoxContainer/TimeOfDayLabel")
	if not tod_label:
		# Try direct path from datetime_box
		for child in get_children():
			if child is HBoxContainer:
				tod_label = child.get_node_or_null("TimeOfDayLabel")
				break

	if tod_label:
		tod_label.text = _get_time_of_day_icon(hour)


func _get_time_of_day_icon(hour: int) -> String:
	if hour >= 6 and hour < 12:
		return "🌅"  # Morning
	if hour >= 12 and hour < 18:
		return "☀️"  # Afternoon
	if hour >= 18 and hour < 22:
		return "🌆"  # Evening
	return "🌙"  # Night


func _update_button_states() -> void:
	if not _pause_btn:
		return

	# Clear all button states first
	_pause_btn.button_pressed = false
	_speed1_btn.button_pressed = false
	_speed2_btn.button_pressed = false
	_speed3_btn.button_pressed = false

	# Set active button based on state
	if _is_paused:
		_pause_btn.button_pressed = true
	else:
		match _current_speed:
			1:
				_speed1_btn.button_pressed = true
			2:
				_speed2_btn.button_pressed = true
			3:
				_speed3_btn.button_pressed = true


func _update_clock_animation() -> void:
	# Stop existing animation
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if not _clock_icon:
		return

	if _is_paused:
		# Pulsing pause animation
		_pulse_tween = create_tween()
		_pulse_tween.set_loops()
		_pulse_tween.tween_property(_clock_icon, "modulate:a", 0.4, CLOCK_PULSE_DURATION)
		_pulse_tween.tween_property(_clock_icon, "modulate:a", 1.0, CLOCK_PULSE_DURATION)
	else:
		# Reset to full opacity
		_clock_icon.modulate.a = 1.0

		# Rotate clock icon based on speed (visual indicator)
		# Higher speed = faster rotation hint via scale pulse
		if _current_speed > 1:
			_pulse_tween = create_tween()
			_pulse_tween.set_loops()
			var speed_factor: float = 1.0 / _current_speed
			_pulse_tween.tween_property(
				_clock_icon, "scale", Vector2(1.1, 1.1), CLOCK_PULSE_DURATION * speed_factor
			)
			_pulse_tween.tween_property(
				_clock_icon, "scale", Vector2(1.0, 1.0), CLOCK_PULSE_DURATION * speed_factor
			)
		else:
			_clock_icon.scale = Vector2.ONE


## Update the display directly (for external calls)
func update_display(year: int, month: int, day: int, hour: int = 8) -> void:
	_update_datetime(year, month, day, hour)


## Get the current displayed date string
func get_date_text() -> String:
	if _datetime_label:
		return _datetime_label.text
	return ""


## Check if currently paused
func is_paused() -> bool:
	return _is_paused


## Get current speed (0-3)
func get_speed() -> int:
	return _current_speed
