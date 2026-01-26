class_name CameraController
extends Node
## Enhanced camera controller with Cities Skylines-style controls
## Features: smooth zoom, middle-mouse drag, double-click center, rotation

# Camera reference
var camera: Camera2D

# Pan settings
const PAN_SPEED := 500.0
const PAN_SMOOTHING := 8.0  # Higher = snappier response

# Zoom settings
const ZOOM_SPEED := 0.15
const MIN_ZOOM := 0.25
const MAX_ZOOM := 4.0
const ZOOM_SMOOTHING := 10.0  # Higher = snappier response

# Rotation settings (4 fixed isometric angles)
const ROTATION_ANGLES := [0.0, 90.0, 180.0, 270.0]
const ROTATION_SMOOTHING := 8.0

# Double-click settings
const DOUBLE_CLICK_TIME := 0.3  # Seconds between clicks to count as double-click
const CENTER_SMOOTHING := 5.0

# State
var _target_position := Vector2.ZERO
var _target_zoom := 1.0
var _target_rotation_index := 0  # Index into ROTATION_ANGLES

var _is_dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_camera := Vector2.ZERO

var _last_click_time := 0.0
var _last_click_position := Vector2.ZERO

# Signals
signal camera_moved(position: Vector2)
signal camera_zoomed(zoom_level: float)
signal camera_rotated(angle: float)


func _ready() -> void:
	# Initialize targets from camera
	if camera:
		_target_position = camera.position
		_target_zoom = camera.zoom.x


func setup(cam: Camera2D) -> void:
	camera = cam
	_target_position = camera.position
	_target_zoom = camera.zoom.x


func _process(delta: float) -> void:
	if not camera:
		return

	_handle_keyboard_pan(delta)
	_apply_smooth_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not camera:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey:
		_handle_key_input(event as InputEventKey)


func _handle_keyboard_pan(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	if direction != Vector2.ZERO:
		# Adjust pan direction for camera rotation
		var rotated_direction := direction.normalized().rotated(deg_to_rad(camera.rotation_degrees))
		# Scale pan speed by inverse of zoom (pan faster when zoomed out)
		var zoom_adjusted_speed := PAN_SPEED / camera.zoom.x
		_target_position += rotated_direction * zoom_adjusted_speed * delta


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_MIDDLE:
			_handle_middle_mouse(event)
		MOUSE_BUTTON_RIGHT:
			_handle_right_mouse(event)
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				if event.shift_pressed:
					# Shift+scroll = rotate camera
					rotate_camera(-1)
				else:
					_zoom_toward_mouse(ZOOM_SPEED, event.position)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				if event.shift_pressed:
					rotate_camera(1)
				else:
					_zoom_toward_mouse(-ZOOM_SPEED, event.position)
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_click(event)


func _handle_middle_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		# Middle-click: start drag or reset view
		if event.double_click:
			# Double middle-click: reset zoom to 1.0
			_target_zoom = 1.0
		else:
			_start_drag(event.position)
	else:
		_end_drag()


func _handle_right_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		# Right-click: start drag pan
		_start_drag(event.position)
	else:
		_end_drag()


func _handle_left_click(event: InputEventMouseButton) -> void:
	# NOTE: Single left-clicks should pass through to InputHandler for block placement
	# CameraController only handles double-clicks for centering
	var current_time := Time.get_ticks_msec() / 1000.0
	var time_since_last := current_time - _last_click_time
	var distance_from_last := event.position.distance_to(_last_click_position)

	# Check for double-click (within time and distance threshold)
	if time_since_last < DOUBLE_CLICK_TIME and distance_from_last < 20.0:
		# Double-click: center camera on clicked position
		center_on_screen_position(event.position)
		_last_click_time = 0.0  # Reset to prevent triple-click
		# Mark as handled so InputHandler doesn't place a block
		get_viewport().set_input_as_handled()
	else:
		# Single click - just track for potential double-click, but don't consume event
		_last_click_time = current_time
		_last_click_position = event.position
		# Don't call set_input_as_handled() - let InputHandler process this for block placement


func _start_drag(mouse_pos: Vector2) -> void:
	_is_dragging = true
	_drag_start_mouse = mouse_pos
	_drag_start_camera = _target_position


func _end_drag() -> void:
	_is_dragging = false


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_dragging:
		# Calculate how much the mouse moved in screen space
		var mouse_delta := event.position - _drag_start_mouse
		# Convert to world space (account for zoom and rotation)
		var world_delta := mouse_delta.rotated(deg_to_rad(camera.rotation_degrees)) / camera.zoom.x
		# Move camera in opposite direction of drag
		_target_position = _drag_start_camera - world_delta


func _handle_key_input(event: InputEventKey) -> void:
	if not event.pressed:
		return

	match event.keycode:
		KEY_Q:
			# Rotate counter-clockwise
			rotate_camera(-1)
		KEY_E:
			# Rotate clockwise
			rotate_camera(1)
		KEY_HOME:
			# Reset zoom
			_target_zoom = 1.0
		KEY_END:
			# Reset position to origin
			_target_position = Vector2.ZERO


func _zoom_toward_mouse(amount: float, mouse_screen_pos: Vector2) -> void:
	if not camera:
		return

	# Get mouse position in world space before zoom
	var viewport := camera.get_viewport()
	if not viewport:
		return

	var viewport_size := viewport.get_visible_rect().size
	var viewport_center := viewport_size / 2.0

	# Mouse offset from viewport center
	var mouse_offset := mouse_screen_pos - viewport_center

	# Mouse position in world space (before zoom)
	var world_mouse_before := camera.position + mouse_offset / camera.zoom.x

	# Apply zoom
	var old_zoom := _target_zoom
	_target_zoom = clampf(_target_zoom + amount, MIN_ZOOM, MAX_ZOOM)

	# If zoom actually changed, adjust position to keep mouse point stationary
	if _target_zoom != old_zoom:
		# Mouse position in world space (after zoom)
		var world_mouse_after := camera.position + mouse_offset / _target_zoom

		# Adjust camera position to compensate
		_target_position += world_mouse_before - world_mouse_after


func rotate_camera(direction: int) -> void:
	_target_rotation_index = wrapi(_target_rotation_index + direction, 0, ROTATION_ANGLES.size())
	camera_rotated.emit(ROTATION_ANGLES[_target_rotation_index])


func center_on_screen_position(screen_pos: Vector2) -> void:
	if not camera:
		return

	var viewport := camera.get_viewport()
	if not viewport:
		return

	var viewport_size := viewport.get_visible_rect().size
	var viewport_center := viewport_size / 2.0

	# Convert screen position to world position
	var mouse_offset := screen_pos - viewport_center
	var world_pos := camera.position + mouse_offset.rotated(deg_to_rad(camera.rotation_degrees)) / camera.zoom.x

	_target_position = world_pos
	camera_moved.emit(_target_position)


func center_on_world_position(world_pos: Vector2) -> void:
	_target_position = world_pos
	camera_moved.emit(_target_position)


func _apply_smooth_movement(delta: float) -> void:
	if not camera:
		return

	# Smooth position
	camera.position = camera.position.lerp(_target_position, PAN_SMOOTHING * delta)

	# Smooth zoom
	var current_zoom := camera.zoom.x
	var new_zoom := lerpf(current_zoom, _target_zoom, ZOOM_SMOOTHING * delta)
	camera.zoom = Vector2(new_zoom, new_zoom)

	# Smooth rotation
	var target_rotation: float = ROTATION_ANGLES[_target_rotation_index]
	var current_rotation: float = camera.rotation_degrees

	# Handle wraparound (e.g., 350 -> 10 should go through 0)
	var rotation_diff: float = target_rotation - current_rotation
	if rotation_diff > 180.0:
		rotation_diff -= 360.0
	elif rotation_diff < -180.0:
		rotation_diff += 360.0

	camera.rotation_degrees = current_rotation + rotation_diff * ROTATION_SMOOTHING * delta

	# Emit signals when significant movement occurs
	if camera.position.distance_to(_target_position) > 1.0:
		camera_moved.emit(camera.position)
	if absf(current_zoom - _target_zoom) > 0.01:
		camera_zoomed.emit(new_zoom)


# Public API for external control

func set_zoom(zoom_level: float) -> void:
	_target_zoom = clampf(zoom_level, MIN_ZOOM, MAX_ZOOM)
	camera_zoomed.emit(_target_zoom)


func get_zoom() -> float:
	return _target_zoom


func get_current_zoom() -> float:
	if camera:
		return camera.zoom.x
	return _target_zoom


func set_position(pos: Vector2) -> void:
	_target_position = pos


func get_position() -> Vector2:
	return _target_position


func get_rotation_angle() -> float:
	return ROTATION_ANGLES[_target_rotation_index]


func get_rotation_index() -> int:
	return _target_rotation_index


func set_rotation_index(index: int) -> void:
	_target_rotation_index = clampi(index, 0, ROTATION_ANGLES.size() - 1)


func is_dragging() -> bool:
	return _is_dragging


# Snap camera to target immediately (no smoothing)
func snap_to_target() -> void:
	if camera:
		camera.position = _target_position
		camera.zoom = Vector2(_target_zoom, _target_zoom)
		camera.rotation_degrees = ROTATION_ANGLES[_target_rotation_index]
