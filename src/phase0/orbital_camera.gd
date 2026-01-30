extends Node3D

## Orbital camera for Phase 0 sandbox.
## Controls match Cities: Skylines conventions.
##
## - WASD: Pan horizontally
## - Q/E: Rotate camera left/right
## - R/F: Zoom in/out (keyboard)
## - T/G: Move camera target up/down
## - Middle mouse drag: Orbit (rotate + tilt)
## - Shift+middle mouse: Pan
## - Scroll wheel: Zoom

const MIN_ELEVATION: float = -45.0
const MAX_ELEVATION: float = 85.0
const MIN_DISTANCE: float = 10.0
const MAX_DISTANCE: float = 500.0
const ROTATION_SPEED: float = 90.0
const PAN_SPEED: float = 30.0
const VERTICAL_PAN_SPEED: float = 20.0
const ZOOM_KEY_SPEED: float = 50.0
const ZOOM_SCROLL_SPEED: float = 0.1
const LERP_FACTOR: float = 10.0
const MOUSE_SENSITIVITY: float = 0.3
const MIN_TARGET_Y: float = 0.0

var target: Vector3 = Vector3.ZERO
var azimuth: float = 45.0
var elevation: float = 30.0
var distance: float = 80.0
var camera: Camera3D

var _target_azimuth: float = 45.0
var _target_elevation: float = 30.0
var _target_distance: float = 80.0
var _target_target: Vector3 = Vector3.ZERO
var _is_dragging: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)
	camera.current = true

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
	# Rotate camera (Q/E)
	if Input.is_key_pressed(KEY_Q):
		_target_azimuth -= ROTATION_SPEED * delta
	if Input.is_key_pressed(KEY_E):
		_target_azimuth += ROTATION_SPEED * delta

	# Horizontal pan (WASD)
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
		var speed := PAN_SPEED * delta
		var fwd := Vector3(
			sin(deg_to_rad(azimuth)), 0,
			cos(deg_to_rad(azimuth)),
		)
		var right := Vector3(
			cos(deg_to_rad(azimuth)), 0,
			-sin(deg_to_rad(azimuth)),
		)
		_target_target += fwd * pan_input.y * speed
		_target_target += right * pan_input.x * speed

	# Vertical pan (T/G)
	if Input.is_key_pressed(KEY_T):
		_target_target.y += VERTICAL_PAN_SPEED * delta
	if Input.is_key_pressed(KEY_G):
		_target_target.y -= VERTICAL_PAN_SPEED * delta
	_target_target.y = maxf(_target_target.y, MIN_TARGET_Y)

	# Keyboard zoom (R/F)
	if Input.is_key_pressed(KEY_R):
		_target_distance = clampf(
			_target_distance - ZOOM_KEY_SPEED * delta,
			MIN_DISTANCE, MAX_DISTANCE,
		)
	if Input.is_key_pressed(KEY_F):
		_target_distance = clampf(
			_target_distance + ZOOM_KEY_SPEED * delta,
			MIN_DISTANCE, MAX_DISTANCE,
		)


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
		_target_distance = clampf(
			_target_distance * (1.0 - ZOOM_SCROLL_SPEED),
			MIN_DISTANCE, MAX_DISTANCE,
		)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_distance = clampf(
			_target_distance * (1.0 + ZOOM_SCROLL_SPEED),
			MIN_DISTANCE, MAX_DISTANCE,
		)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _is_dragging:
		return

	var delta := event.position - _last_mouse_pos
	_last_mouse_pos = event.position

	if _is_panning:
		var pan_amount := delta * MOUSE_SENSITIVITY * 0.1
		var fwd := Vector3(
			sin(deg_to_rad(azimuth)), 0,
			cos(deg_to_rad(azimuth)),
		)
		var right := Vector3(
			cos(deg_to_rad(azimuth)), 0,
			-sin(deg_to_rad(azimuth)),
		)
		_target_target -= right * pan_amount.x
		_target_target -= fwd * pan_amount.y
	else:
		_target_azimuth += delta.x * MOUSE_SENSITIVITY
		var new_el := _target_elevation - delta.y * MOUSE_SENSITIVITY
		_target_elevation = clampf(
			new_el, MIN_ELEVATION, MAX_ELEVATION,
		)


func _smooth_interpolate(delta: float) -> void:
	var t := 1.0 - exp(-LERP_FACTOR * delta)
	azimuth = lerpf(azimuth, _target_azimuth, t)
	elevation = lerpf(elevation, _target_elevation, t)
	distance = lerpf(distance, _target_distance, t)
	target = target.lerp(_target_target, t)


func _update_camera_position() -> void:
	var azimuth_rad := deg_to_rad(azimuth)
	var elevation_rad := deg_to_rad(elevation)

	var offset := Vector3(
		sin(azimuth_rad) * cos(elevation_rad),
		sin(elevation_rad),
		cos(azimuth_rad) * cos(elevation_rad)
	) * distance

	camera.global_position = target + offset
	if camera.is_inside_tree():
		camera.look_at(target, Vector3.UP)
