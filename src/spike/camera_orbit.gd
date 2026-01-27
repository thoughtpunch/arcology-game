extends Camera3D
class_name CameraOrbit

## Orbital camera controller for 3D spike
##
## Controls:
## - Q/E: Rotate around Y axis (azimuth)
## - R/F: Tilt up/down (elevation)
## - WASD: Pan relative to camera facing
## - Scroll: Zoom in/out
## - Middle mouse drag: Orbit
## - Shift+middle mouse: Pan

# Target point the camera orbits around
var target: Vector3 = Vector3.ZERO

# Spherical coordinates relative to target
var azimuth: float = 0.0  # Rotation around Y axis (degrees)
var elevation: float = 45.0  # Angle from horizontal (degrees)
var distance: float = 50.0  # Distance from target

# Smooth movement targets
var _target_azimuth: float = 0.0
var _target_elevation: float = 45.0
var _target_distance: float = 50.0
var _target_target: Vector3 = Vector3.ZERO

# Limits
const MIN_ELEVATION: float = 5.0
const MAX_ELEVATION: float = 85.0
const MIN_DISTANCE: float = 10.0
const MAX_DISTANCE: float = 500.0
const MIN_ORTHO_SIZE: float = 10.0
const MAX_ORTHO_SIZE: float = 200.0

# Speed settings
const ROTATION_SPEED: float = 90.0  # Degrees per second
const TILT_SPEED: float = 45.0  # Degrees per second
const PAN_SPEED: float = 30.0  # Units per second
const ZOOM_SPEED: float = 0.1  # Multiplier per scroll
const LERP_FACTOR: float = 10.0  # Smoothing factor

# Mouse drag state
var _is_dragging: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
const MOUSE_SENSITIVITY: float = 0.3


func _ready() -> void:
	_target_azimuth = azimuth
	_target_elevation = elevation
	_target_distance = distance
	_target_target = target
	_update_camera_position()


func _process(delta: float) -> void:
	_handle_keyboard_input(delta)
	_smooth_interpolate(delta)
	_update_camera_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_keyboard_input(delta: float) -> void:
	# Orbit rotation (Q/E)
	if Input.is_key_pressed(KEY_Q):
		_target_azimuth -= ROTATION_SPEED * delta
	if Input.is_key_pressed(KEY_E):
		_target_azimuth += ROTATION_SPEED * delta

	# Tilt (R/F)
	if Input.is_key_pressed(KEY_R):
		_target_elevation = clampf(_target_elevation + TILT_SPEED * delta, MIN_ELEVATION, MAX_ELEVATION)
	if Input.is_key_pressed(KEY_F):
		_target_elevation = clampf(_target_elevation - TILT_SPEED * delta, MIN_ELEVATION, MAX_ELEVATION)

	# Pan (WASD) - relative to camera facing
	var pan_input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		pan_input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		pan_input.y += 1.0
	if Input.is_key_pressed(KEY_A):
		pan_input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		pan_input.x += 1.0

	if pan_input != Vector2.ZERO:
		pan_input = pan_input.normalized()
		var pan_speed := PAN_SPEED * delta

		# Get forward and right vectors in XZ plane based on azimuth
		var forward := Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))
		var right := Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))

		_target_target += forward * pan_input.y * pan_speed
		_target_target += right * pan_input.x * pan_speed


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			_is_dragging = true
			_is_panning = Input.is_key_pressed(KEY_SHIFT)
			_last_mouse_pos = event.position
		else:
			_is_dragging = false
			_is_panning = false
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-ZOOM_SPEED)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(ZOOM_SPEED)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _is_dragging:
		return

	var delta := event.position - _last_mouse_pos
	_last_mouse_pos = event.position

	if _is_panning:
		# Pan with Shift+middle mouse
		var pan_amount := delta * MOUSE_SENSITIVITY * 0.1
		var forward := Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))
		var right := Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))
		_target_target -= right * pan_amount.x
		_target_target -= forward * pan_amount.y
	else:
		# Orbit with middle mouse
		_target_azimuth += delta.x * MOUSE_SENSITIVITY
		_target_elevation = clampf(_target_elevation - delta.y * MOUSE_SENSITIVITY, MIN_ELEVATION, MAX_ELEVATION)


func _zoom(amount: float) -> void:
	if projection == PROJECTION_ORTHOGONAL:
		# Orthographic: adjust size
		var new_size := size * (1.0 + amount)
		size = clampf(new_size, MIN_ORTHO_SIZE, MAX_ORTHO_SIZE)
	else:
		# Perspective: adjust distance
		_target_distance = clampf(_target_distance * (1.0 + amount), MIN_DISTANCE, MAX_DISTANCE)


func _smooth_interpolate(delta: float) -> void:
	var t := 1.0 - exp(-LERP_FACTOR * delta)
	azimuth = lerpf(azimuth, _target_azimuth, t)
	elevation = lerpf(elevation, _target_elevation, t)
	distance = lerpf(distance, _target_distance, t)
	target = target.lerp(_target_target, t)


func _update_camera_position() -> void:
	# Convert spherical to Cartesian coordinates
	var azimuth_rad := deg_to_rad(azimuth)
	var elevation_rad := deg_to_rad(elevation)

	var offset := Vector3(
		sin(azimuth_rad) * cos(elevation_rad),
		sin(elevation_rad),
		cos(azimuth_rad) * cos(elevation_rad)
	) * distance

	# Use position instead of global_position when not in tree
	position = target + offset
	if is_inside_tree():
		look_at(target, Vector3.UP)
	else:
		# Manual look_at when not in tree
		var forward := (target - position).normalized()
		if forward.length_squared() > 0.001:
			transform.basis = Basis.looking_at(forward, Vector3.UP)


# Public API for programmatic control

func set_target(new_target: Vector3, immediate: bool = false) -> void:
	_target_target = new_target
	if immediate:
		target = new_target
		_update_camera_position()


func set_azimuth(degrees: float, immediate: bool = false) -> void:
	_target_azimuth = degrees
	if immediate:
		azimuth = degrees
		_update_camera_position()


func set_elevation(degrees: float, immediate: bool = false) -> void:
	_target_elevation = clampf(degrees, MIN_ELEVATION, MAX_ELEVATION)
	if immediate:
		elevation = _target_elevation
		_update_camera_position()


func set_distance(dist: float, immediate: bool = false) -> void:
	_target_distance = clampf(dist, MIN_DISTANCE, MAX_DISTANCE)
	if immediate:
		distance = _target_distance
		_update_camera_position()


func reset_view(immediate: bool = false) -> void:
	_target_azimuth = 0.0
	_target_elevation = 45.0
	_target_distance = 50.0
	_target_target = Vector3.ZERO
	if immediate:
		azimuth = _target_azimuth
		elevation = _target_elevation
		distance = _target_distance
		target = _target_target
		_update_camera_position()


func get_forward_direction() -> Vector3:
	## Returns the forward direction in XZ plane based on azimuth
	return Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))


func get_right_direction() -> Vector3:
	## Returns the right direction in XZ plane based on azimuth
	return Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))
