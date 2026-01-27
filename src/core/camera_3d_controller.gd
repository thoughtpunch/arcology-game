extends Node3D
class_name ArcologyCamera
## 3D Orbital camera controller with free rotation and orthographic snap views
##
## Controls:
## - Q/E: Rotate around Y axis (azimuth)
## - R/F: Tilt up/down (elevation)
## - WASD: Pan relative to camera facing
## - Scroll: Zoom in/out
## - Middle mouse drag: Orbit
## - Shift+middle mouse: Pan
## - Tab: Toggle between FREE and ORTHO modes
## - 1-7 in ORTHO mode: Snap to view (TOP, NORTH, EAST, SOUTH, WEST, BOTTOM, ISO)

## Camera mode
enum Mode { FREE, ORTHO }

## Orthographic snap views
enum OrthoView {
	TOP,      # Looking down (Y-)
	NORTH,    # Looking south (Z+)
	EAST,     # Looking west (X-)
	SOUTH,    # Looking north (Z-)
	WEST,     # Looking east (X+)
	BOTTOM,   # Looking up (Y+) - rare but useful
	ISO       # 45° isometric (traditional arcology view)
}

# Signals
signal mode_changed(new_mode: Mode)
signal ortho_view_changed(new_view: OrthoView)

# Current state
var mode: Mode = Mode.FREE
var ortho_view: OrthoView = OrthoView.ISO

# Target point the camera orbits around
var target: Vector3 = Vector3.ZERO

# Spherical coordinates relative to target (FREE mode)
var azimuth: float = 45.0  # Rotation around Y axis (degrees)
var elevation: float = 45.0  # Angle from horizontal (degrees)
var distance: float = 100.0  # Distance from target

# Orthographic size (ORTHO mode)
var ortho_size: float = 50.0

# Smooth movement targets
var _target_azimuth: float = 45.0
var _target_elevation: float = 45.0
var _target_distance: float = 100.0
var _target_target: Vector3 = Vector3.ZERO
var _target_ortho_size: float = 50.0

# Constraints
const MIN_DISTANCE: float = 10.0
const MAX_DISTANCE: float = 2000.0
const MIN_ELEVATION: float = 5.0
const MAX_ELEVATION: float = 89.0
const MIN_ORTHO_SIZE: float = 10.0
const MAX_ORTHO_SIZE: float = 500.0

# Speed settings
const ROTATION_SPEED: float = 90.0  # Degrees per second
const TILT_SPEED: float = 45.0  # Degrees per second
const PAN_SPEED: float = 50.0  # Units per second (scales with zoom)
const ZOOM_SPEED: float = 0.1  # Multiplier per scroll
const LERP_FACTOR: float = 10.0  # Smoothing factor

# Mouse drag state
var _is_dragging: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
const MOUSE_SENSITIVITY: float = 0.3

# Camera node reference (created as child)
var _camera: Camera3D

# Ortho view presets: [azimuth, elevation, distance_multiplier]
const ORTHO_PRESETS := {
	OrthoView.TOP: { "azimuth": 0.0, "elevation": 89.0, "label": "Top" },
	OrthoView.NORTH: { "azimuth": 0.0, "elevation": 0.0, "label": "North" },
	OrthoView.EAST: { "azimuth": 90.0, "elevation": 0.0, "label": "East" },
	OrthoView.SOUTH: { "azimuth": 180.0, "elevation": 0.0, "label": "South" },
	OrthoView.WEST: { "azimuth": 270.0, "elevation": 0.0, "label": "West" },
	OrthoView.BOTTOM: { "azimuth": 0.0, "elevation": -89.0, "label": "Bottom" },
	OrthoView.ISO: { "azimuth": 45.0, "elevation": 35.264, "label": "Isometric" }  # arctan(1/sqrt(2)) ≈ 35.264°
}


func _ready() -> void:
	# Create the Camera3D as a child
	_camera = Camera3D.new()
	_camera.name = "Camera"
	add_child(_camera)

	# Start in orthographic mode for consistent arcology look
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ortho_size
	_camera.far = 2000.0
	_camera.near = 0.1

	# Initialize targets
	_target_azimuth = azimuth
	_target_elevation = elevation
	_target_distance = distance
	_target_target = target
	_target_ortho_size = ortho_size

	_update_camera_transform()


func _process(delta: float) -> void:
	_handle_keyboard_input(delta)
	_smooth_interpolate(delta)
	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key_press(event)


func _handle_keyboard_input(delta: float) -> void:
	# Orbit rotation (Q/E) - only in FREE mode
	if mode == Mode.FREE:
		if Input.is_key_pressed(KEY_Q):
			_target_azimuth -= ROTATION_SPEED * delta
		if Input.is_key_pressed(KEY_E):
			_target_azimuth += ROTATION_SPEED * delta

		# Tilt (R/F) - only in FREE mode
		if Input.is_key_pressed(KEY_R):
			_target_elevation = clampf(_target_elevation + TILT_SPEED * delta, MIN_ELEVATION, MAX_ELEVATION)
		if Input.is_key_pressed(KEY_F):
			_target_elevation = clampf(_target_elevation - TILT_SPEED * delta, MIN_ELEVATION, MAX_ELEVATION)

	# Pan (WASD) - relative to camera facing (works in both modes)
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
		# Pan speed scales with zoom (distance or ortho_size)
		var zoom_factor := distance / 100.0 if mode == Mode.FREE else ortho_size / 50.0
		var pan_speed := PAN_SPEED * delta * zoom_factor

		# Get forward and right vectors in XZ plane based on azimuth
		var forward := Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))
		var right := Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))

		_target_target += forward * pan_input.y * pan_speed
		_target_target += right * pan_input.x * pan_speed


func _handle_key_press(event: InputEventKey) -> void:
	match event.keycode:
		KEY_TAB:
			# Toggle between FREE and ORTHO modes
			toggle_mode()
		KEY_HOME:
			# Reset to default view
			reset_view()
		# Ortho view shortcuts (Shift+1-7)
		KEY_1:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.TOP)
		KEY_2:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.NORTH)
		KEY_3:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.EAST)
		KEY_4:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.SOUTH)
		KEY_5:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.WEST)
		KEY_6:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.BOTTOM)
		KEY_7:
			if event.shift_pressed or mode == Mode.ORTHO:
				snap_to_ortho(OrthoView.ISO)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_dragging = true
				_is_panning = Input.is_key_pressed(KEY_SHIFT)
				_last_mouse_pos = event.position
			else:
				_is_dragging = false
				_is_panning = false
		MOUSE_BUTTON_RIGHT:
			# Right-click also drags (pan only)
			if event.pressed:
				_is_dragging = true
				_is_panning = true
				_last_mouse_pos = event.position
			else:
				_is_dragging = false
				_is_panning = false
		MOUSE_BUTTON_WHEEL_UP:
			zoom(-ZOOM_SPEED)
		MOUSE_BUTTON_WHEEL_DOWN:
			zoom(ZOOM_SPEED)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _is_dragging:
		return

	var delta_motion := event.position - _last_mouse_pos
	_last_mouse_pos = event.position

	if _is_panning:
		# Pan with Shift+middle mouse or right mouse
		var zoom_factor := distance / 100.0 if mode == Mode.FREE else ortho_size / 50.0
		var pan_amount := delta_motion * MOUSE_SENSITIVITY * 0.1 * zoom_factor
		var forward := Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))
		var right := Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))
		_target_target -= right * pan_amount.x
		_target_target -= forward * pan_amount.y
	else:
		# Orbit with middle mouse - only in FREE mode
		if mode == Mode.FREE:
			_target_azimuth += delta_motion.x * MOUSE_SENSITIVITY
			_target_elevation = clampf(_target_elevation - delta_motion.y * MOUSE_SENSITIVITY, MIN_ELEVATION, MAX_ELEVATION)
		else:
			# In ORTHO mode, dragging cycles through views based on direction
			# (Could implement this as a view cube interaction later)
			pass


func zoom(amount: float) -> void:
	## Zoom in/out. Positive amount = zoom out, negative = zoom in.
	if mode == Mode.ORTHO or _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		# Orthographic: adjust size
		_target_ortho_size = clampf(_target_ortho_size * (1.0 + amount), MIN_ORTHO_SIZE, MAX_ORTHO_SIZE)
	else:
		# Perspective: adjust distance
		_target_distance = clampf(_target_distance * (1.0 + amount), MIN_DISTANCE, MAX_DISTANCE)


func _smooth_interpolate(delta: float) -> void:
	var t := 1.0 - exp(-LERP_FACTOR * delta)
	azimuth = lerpf(azimuth, _target_azimuth, t)
	elevation = lerpf(elevation, _target_elevation, t)
	distance = lerpf(distance, _target_distance, t)
	target = target.lerp(_target_target, t)
	ortho_size = lerpf(ortho_size, _target_ortho_size, t)

	# Update camera orthographic size
	if _camera:
		_camera.size = ortho_size


func _update_camera_transform() -> void:
	## Update camera position based on spherical coordinates
	var azimuth_rad := deg_to_rad(azimuth)
	var elevation_rad := deg_to_rad(elevation)

	# Convert spherical to Cartesian coordinates
	var offset := Vector3(
		sin(azimuth_rad) * cos(elevation_rad),
		sin(elevation_rad),
		cos(azimuth_rad) * cos(elevation_rad)
	) * distance

	# Position camera
	if _camera:
		_camera.global_position = target + offset

		# Look at target
		if is_inside_tree():
			_camera.look_at(target, Vector3.UP)
		else:
			# Manual look_at when not in tree
			var forward := (target - _camera.position).normalized()
			if forward.length_squared() > 0.001:
				_camera.transform.basis = Basis.looking_at(forward, Vector3.UP)


# --- Public API ---

func orbit(delta_azimuth: float, delta_elevation: float) -> void:
	## Orbit camera by given amounts (degrees)
	_target_azimuth += delta_azimuth
	_target_elevation = clampf(_target_elevation + delta_elevation, MIN_ELEVATION, MAX_ELEVATION)


func pan(screen_delta: Vector2) -> void:
	## Pan camera by screen-space delta
	var zoom_factor := distance / 100.0 if mode == Mode.FREE else ortho_size / 50.0
	var pan_amount := screen_delta * 0.1 * zoom_factor
	var forward := Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))
	var right := Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))
	_target_target -= right * pan_amount.x
	_target_target -= forward * pan_amount.y


func focus_on(world_pos: Vector3, immediate: bool = false) -> void:
	## Focus camera on a world position
	_target_target = world_pos
	if immediate:
		target = world_pos
		_update_camera_transform()


func snap_to_ortho(view: OrthoView) -> void:
	## Snap to orthographic view preset
	if not ORTHO_PRESETS.has(view):
		return

	var preset: Dictionary = ORTHO_PRESETS[view]
	_target_azimuth = preset.azimuth

	# Handle elevation specially for side views
	if view == OrthoView.TOP:
		_target_elevation = MAX_ELEVATION  # Look straight down
	elif view == OrthoView.BOTTOM:
		_target_elevation = MIN_ELEVATION  # Look straight up (clamped to min)
	elif view == OrthoView.NORTH or view == OrthoView.SOUTH or view == OrthoView.EAST or view == OrthoView.WEST:
		# Side views - use a slight elevation to avoid looking exactly horizontal
		_target_elevation = 15.0
	else:
		_target_elevation = preset.elevation

	# Switch to ORTHO mode
	mode = Mode.ORTHO
	ortho_view = view
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL

	mode_changed.emit(mode)
	ortho_view_changed.emit(view)

	print("Camera: Ortho view - %s" % preset.label)


func return_to_free() -> void:
	## Return to free camera mode
	mode = Mode.FREE
	# Keep orthographic projection for consistent arcology look
	# Could switch to perspective here if desired:
	# _camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	mode_changed.emit(mode)
	print("Camera: Free mode")


func toggle_mode() -> void:
	## Toggle between FREE and ORTHO modes
	if mode == Mode.FREE:
		snap_to_ortho(ortho_view)  # Snap to last ortho view
	else:
		return_to_free()


func reset_view(immediate: bool = false) -> void:
	## Reset to default isometric view
	_target_azimuth = 45.0
	_target_elevation = 45.0
	_target_distance = 100.0
	_target_target = Vector3.ZERO
	_target_ortho_size = 50.0

	if immediate:
		azimuth = _target_azimuth
		elevation = _target_elevation
		distance = _target_distance
		target = _target_target
		ortho_size = _target_ortho_size
		if _camera:
			_camera.size = ortho_size
		_update_camera_transform()

	print("Camera: Reset to default view")


# --- Getters and Setters ---

func get_camera() -> Camera3D:
	## Get the Camera3D node
	return _camera


func set_target(new_target: Vector3, immediate: bool = false) -> void:
	_target_target = new_target
	if immediate:
		target = new_target
		_update_camera_transform()


func set_azimuth(degrees: float, immediate: bool = false) -> void:
	_target_azimuth = degrees
	if immediate:
		azimuth = degrees
		_update_camera_transform()


func set_elevation(degrees: float, immediate: bool = false) -> void:
	_target_elevation = clampf(degrees, MIN_ELEVATION, MAX_ELEVATION)
	if immediate:
		elevation = _target_elevation
		_update_camera_transform()


func set_distance(dist: float, immediate: bool = false) -> void:
	_target_distance = clampf(dist, MIN_DISTANCE, MAX_DISTANCE)
	if immediate:
		distance = _target_distance
		_update_camera_transform()


func set_ortho_size(size: float, immediate: bool = false) -> void:
	_target_ortho_size = clampf(size, MIN_ORTHO_SIZE, MAX_ORTHO_SIZE)
	if immediate:
		ortho_size = _target_ortho_size
		if _camera:
			_camera.size = ortho_size


func get_mode() -> Mode:
	return mode


func get_ortho_view() -> OrthoView:
	return ortho_view


func get_forward_direction() -> Vector3:
	## Returns the forward direction in XZ plane based on azimuth
	return Vector3(sin(deg_to_rad(azimuth)), 0, cos(deg_to_rad(azimuth)))


func get_right_direction() -> Vector3:
	## Returns the right direction in XZ plane based on azimuth
	return Vector3(cos(deg_to_rad(azimuth)), 0, -sin(deg_to_rad(azimuth)))


func apply_immediately() -> void:
	## Force all target values to apply immediately (no lerping)
	azimuth = _target_azimuth
	elevation = _target_elevation
	distance = _target_distance
	target = _target_target
	ortho_size = _target_ortho_size
	if _camera:
		_camera.size = ortho_size
	_update_camera_transform()
