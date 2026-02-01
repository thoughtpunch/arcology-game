extends Node3D

## Orbital camera with industry-standard 3D navigation.
##
## Mouse:
##   Right-click + drag: Orbit (rotate + tilt)
##   Middle-click + drag: Pan (truck in camera plane)
##   Scroll wheel: Zoom in/out (proportional to distance)
##   Shift + left-click + drag: Zoom (vertical drag, MacBook-friendly)
##   Alt + left-click + drag: Orbit around point under cursor (3DS Max/Blender style)
##   Alt + right-click + drag: Dolly zoom (Hitchcock/Vertigo effect — zoom FOV while
##     adjusting distance to maintain subject framing)
##   Shift + right-click + drag: Roll camera (flight sim style, for cinematic angles)
##   Double-click: Handled by parent (focus on object)
##
## Trackpad gestures (macOS):
##   Two-finger swipe: Pan (no click needed)
##   Pinch: Zoom in/out
##   Alt + two-finger swipe: Orbit (rotate + tilt, no click needed)
##
## Keyboard — Movement:
##   WASD: Pan horizontally (speed scales with zoom distance)
##   Q / Space: Ascend (move camera target up)
##   E / C: Descend (move camera target down)
##
## Keyboard — Speed modulation:
##   Shift (hold): 0.25x precision mode
##   Ctrl (hold): 3x boost
##   Shift + Ctrl: 10x sprint
##
## Keyboard — Camera:
##   H: Return to home position
##   Z: Level horizon (reset elevation to default)
##   [ / ]: Decrease / increase FOV
##   Backspace: Previous camera position (history)
##   Shift + Backspace: Next camera position (history)
##
## Keyboard — Views:
##   Numpad 1: Front view
##   Numpad 3: Right view
##   Numpad 7: Top view
##   Numpad 5: Toggle perspective / orthographic
##
## Keyboard — Ground Snap:
##   X: Snap target to ground (Y=0) at cursor XZ position (raycast)
##   V: Snap target to ground (Y=0) at current target XZ position
##
## Keyboard — Bookmarks:
##   Ctrl+1-9: Save camera bookmark to slot
##   Alt+1-9: Recall camera bookmark from slot
##
## Keyboard — Path Recording:
##   Ctrl+R: Start/stop recording camera path (captures keyframes)
##   Ctrl+P: Start/stop playback of recorded path (smooth interpolation, loops)
##
## Right-click behavior:
##   A right-click that is released without significant mouse movement
##   is NOT consumed by the camera, allowing the parent scene to handle
##   it (e.g., block removal). Only drags past DRAG_THRESHOLD pixels
##   are treated as camera orbits.

# --- Limits ---
const MIN_ELEVATION: float = -89.0
const MAX_ELEVATION: float = 89.0
const MIN_DISTANCE: float = 5.0
const MAX_DISTANCE: float = 2000.0
const MIN_FOV: float = 20.0
const MAX_FOV: float = 120.0
const DEFAULT_FOV: float = 70.0
const MIN_TARGET_Y: float = -50.0

# --- Speeds ---
const PAN_BASE_SPEED: float = 60.0
const VERTICAL_SPEED: float = 50.0
const ORBIT_SENSITIVITY: float = 0.25
const PAN_MOUSE_SENSITIVITY: float = 0.15
const ZOOM_SCROLL_FACTOR: float = 0.12
const ZOOM_DRAG_SENSITIVITY: float = 0.005
const DOLLY_ZOOM_SENSITIVITY: float = 0.3  # Degrees of FOV change per pixel of vertical drag
const TRACKPAD_PAN_SENSITIVITY: float = 2.0  # Multiplier for InputEventPanGesture delta
const TRACKPAD_ORBIT_SENSITIVITY: float = 8.0  # Degrees per unit of PanGesture delta (with Alt)
const TRACKPAD_ZOOM_SENSITIVITY: float = 0.5  # Zoom blend factor for InputEventMagnifyGesture
const FOV_STEP: float = 5.0
const FOV_FINE_STEP: float = 1.0
const LERP_FACTOR: float = 14.0

# --- Inertia ---
const INERTIA_DECAY_RATE: float = 4.0  # How quickly momentum decays (higher = faster decay)
const INERTIA_MIN_VELOCITY: float = 0.5  # Stop inertia below this velocity (degrees/sec)
const INERTIA_VELOCITY_SCALE: float = 60.0  # Convert mouse delta to degrees/sec

# --- Thresholds ---
const DRAG_THRESHOLD: float = 4.0  # Pixels before a click becomes a drag
const HISTORY_MIN_DISTANCE: float = 20.0  # Min target movement to push history
const HISTORY_MIN_ANGLE: float = 5.0  # Min azimuth change to push history
const MAX_HISTORY: int = 50
const LOG_PREFIX := "[Camera] "

# --- State ---
var target: Vector3 = Vector3.ZERO
var azimuth: float = 45.0
var elevation: float = 30.0
var distance: float = 200.0
var fov: float = DEFAULT_FOV
var roll: float = 0.0  # Camera roll in degrees (0 = level, positive = clockwise)
var is_orthographic: bool = false
var camera: Camera3D

# Smooth interpolation targets
var _target_azimuth: float = 45.0
var _target_elevation: float = 30.0
var _target_distance: float = 200.0
var _target_target: Vector3 = Vector3.ZERO
var _target_fov: float = DEFAULT_FOV
var _target_roll: float = 0.0

# Roll drag state
var _roll_drag_pressed: bool = false
var _roll_drag_active: bool = false
var _roll_drag_press_pos: Vector2 = Vector2.ZERO
const ROLL_SENSITIVITY: float = 0.3  # Degrees per pixel of drag

# Home position (saved on _ready)
var _home_target: Vector3
var _home_azimuth: float
var _home_elevation: float
var _home_distance: float

# Mouse state
var _right_pressed: bool = false
var _right_drag_active: bool = false
var _right_press_pos: Vector2 = Vector2.ZERO
var _middle_pressed: bool = false
var _zoom_drag_pressed: bool = false
var _zoom_drag_active: bool = false
var _zoom_drag_press_pos: Vector2 = Vector2.ZERO
var _alt_orbit_pressed: bool = false
var _alt_orbit_active: bool = false
var _alt_orbit_press_pos: Vector2 = Vector2.ZERO
var _alt_orbit_pivot: Vector3 = Vector3.ZERO  # World-space raycast hit point
var _alt_orbit_original_target: Vector3 = Vector3.ZERO  # Target before alt-orbit began
var _dolly_zoom_pressed: bool = false
var _dolly_zoom_active: bool = false
var _dolly_zoom_press_pos: Vector2 = Vector2.ZERO
var _dolly_zoom_frame_height: float = 0.0  # distance * tan(fov/2) — kept constant during dolly
var _last_mouse_pos: Vector2 = Vector2.ZERO

# Speed modulation (recomputed each frame)
var _movement_speed: float = 1.0
var _precision: float = 1.0
var _prev_speed_mode: String = "normal"
var _sticky_sprint: bool = false  # Toggled by middle-click (no drag)
var _middle_press_pos: Vector2 = Vector2.ZERO  # Track for click vs drag detection
const MIDDLE_CLICK_DRAG_THRESHOLD: float = 5.0  # Pixels before middle-click becomes pan

# History
var _history: Array[Dictionary] = []
var _history_index: int = -1

# Bookmarks (slots 0-8, mapped to keys 1-9)
var _bookmarks: Dictionary = {}  # int -> Dictionary (slot -> camera state)

# Path recording and playback
var _path_keyframes: Array[Dictionary] = []  # Recorded camera path keyframes
var _is_recording: bool = false
var _is_playing: bool = false
var _playback_time: float = 0.0
var _playback_speed: float = 1.0  # Units per second (adjustable)
const PATH_PLAYBACK_DURATION: float = 2.0  # Seconds between keyframes during playback
const MIN_KEYFRAME_INTERVAL: float = 0.5  # Minimum seconds between auto-captured keyframes
var _last_keyframe_time: float = 0.0

# Inertia state
var inertia_enabled: bool = true  # Toggle in settings
var _inertia_velocity: Vector2 = Vector2.ZERO  # degrees/sec for azimuth (x) and elevation (y)
var _orbit_velocity_samples: Array[Vector2] = []  # Recent velocity samples for smoothing
const VELOCITY_SAMPLE_COUNT: int = 3  # Number of samples to average

# --- Double-Tap Dash ---
const DOUBLE_TAP_WINDOW: float = 0.3  # Seconds to detect double-tap
const DASH_DISTANCE_MULTIPLIER: float = 5.0  # How far dash moves (relative to normal movement)
var _last_tap_times: Dictionary = {}  # KEY_* -> float (timestamp of last tap)

signal dash_triggered(direction: Vector3)
signal inertia_toggled(enabled: bool)
signal bookmark_saved(slot: int)
signal bookmark_recalled(slot: int)
signal path_recording_started()
signal path_recording_stopped(keyframe_count: int)
signal path_playback_started(keyframe_count: int)
signal path_playback_stopped()
signal path_keyframe_added(index: int)
signal ground_snap(position: Vector3)


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.far = 3000.0
	camera.fov = fov
	add_child(camera)
	camera.current = true

	_target_azimuth = azimuth
	_target_elevation = elevation
	_target_distance = distance
	_target_target = target
	_target_fov = fov
	_update_camera_position()

	# Save home position
	_home_target = target
	_home_azimuth = azimuth
	_home_elevation = elevation
	_home_distance = distance

	_push_history()
	_log(
		(
			"Camera ready — home at %s, az=%.0f, el=%.0f, dist=%.0f"
			% [
				target,
				azimuth,
				elevation,
				distance,
			]
		)
	)


func _process(delta: float) -> void:
	if _is_playing:
		_update_playback(delta)
	else:
		_update_speed_factors()
		_handle_keyboard(delta)
		_apply_inertia(delta)
	_smooth_interpolate(delta)
	_update_camera_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventPanGesture:
		_handle_pan_gesture(event)
	elif event is InputEventMagnifyGesture:
		_handle_magnify_gesture(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)


# --- Logging ---


static func _log(msg: String) -> void:
	if OS.is_debug_build():
		print(LOG_PREFIX + msg)


# --- Speed Modulation ---


func _update_speed_factors() -> void:
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var caps := Input.is_key_pressed(KEY_CAPSLOCK)
	_precision = 0.25 if shift else 1.0
	var mode_name: String

	# Caps Lock or sticky sprint acts like permanent sprint toggle
	var sprint_active := _sticky_sprint or caps

	if shift and ctrl:
		_movement_speed = 10.0
		mode_name = "sprint (10x)"
	elif ctrl:
		_movement_speed = 3.0
		mode_name = "boost (3x)"
	elif shift:
		_movement_speed = 0.25
		mode_name = "precision (0.25x)"
	elif sprint_active:
		_movement_speed = 10.0
		mode_name = "sticky sprint (10x)"
	else:
		_movement_speed = 1.0
		mode_name = "normal"
	if mode_name != _prev_speed_mode:
		_log("Speed mode: %s" % mode_name)
		_prev_speed_mode = mode_name


func _apply_inertia(delta: float) -> void:
	## Apply decaying momentum from orbit release.
	if not inertia_enabled:
		return
	if _inertia_velocity.length() < INERTIA_MIN_VELOCITY:
		_inertia_velocity = Vector2.ZERO
		return
	# Don't apply inertia while actively dragging
	if _right_drag_active or _alt_orbit_active:
		return

	# Apply velocity to target angles
	_target_azimuth += _inertia_velocity.x * delta
	var new_el := _target_elevation + _inertia_velocity.y * delta
	_target_elevation = clampf(new_el, MIN_ELEVATION, MAX_ELEVATION)

	# Decay velocity exponentially
	_inertia_velocity *= exp(-INERTIA_DECAY_RATE * delta)


func _start_orbit_inertia() -> void:
	## Calculate and apply inertia velocity from recent orbit drag samples.
	if not inertia_enabled or _orbit_velocity_samples.is_empty():
		_inertia_velocity = Vector2.ZERO
		return

	# Average recent velocity samples for smooth inertia start
	var avg_velocity := Vector2.ZERO
	for sample in _orbit_velocity_samples:
		avg_velocity += sample
	avg_velocity /= _orbit_velocity_samples.size()

	_inertia_velocity = avg_velocity
	_orbit_velocity_samples.clear()

	if _inertia_velocity.length() > INERTIA_MIN_VELOCITY:
		_log("Orbit inertia started (vel=%.1f, %.1f)" % [_inertia_velocity.x, _inertia_velocity.y])


# --- Keyboard (continuous, polled each frame) ---


func _handle_keyboard(delta: float) -> void:
	# Vertical movement (Q/Space = up, E/C = down)
	var vertical := 0.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_SPACE):
		vertical += 1.0
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_C):
		vertical -= 1.0
	if vertical != 0.0:
		_target_target.y += vertical * VERTICAL_SPEED * _movement_speed * delta

	# Horizontal pan (WASD) — speed scales with distance
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
		var speed := PAN_BASE_SPEED * (distance / 100.0) * _movement_speed * delta
		var fwd := Vector3(
			sin(deg_to_rad(azimuth)),
			0,
			cos(deg_to_rad(azimuth)),
		)
		var right := Vector3(
			cos(deg_to_rad(azimuth)),
			0,
			-sin(deg_to_rad(azimuth)),
		)
		_target_target += fwd * pan_input.y * speed
		_target_target += right * pan_input.x * speed

	_target_target.y = maxf(_target_target.y, MIN_TARGET_Y)


# --- Mouse Buttons ---


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed and event.alt_pressed:
				# Alt + left-click: orbit around cursor raycast hit point
				_alt_orbit_pressed = true
				_alt_orbit_active = false
				_alt_orbit_press_pos = event.position
				_last_mouse_pos = event.position
				# Raycast to find pivot point under cursor
				var pivot = _raycast_pivot(event.position)
				if pivot != null:
					_alt_orbit_pivot = pivot
					_alt_orbit_original_target = _target_target
				else:
					# No hit — fall back to current target as pivot
					_alt_orbit_pivot = _target_target
					_alt_orbit_original_target = _target_target
				get_viewport().set_input_as_handled()
			elif not event.pressed and _alt_orbit_pressed:
				if _alt_orbit_active:
					_push_history()
					_log("Alt-orbit ended (pivot=%s)" % _alt_orbit_pivot)
				_alt_orbit_pressed = false
				_alt_orbit_active = false
				get_viewport().set_input_as_handled()
			elif event.pressed and event.shift_pressed:
				_zoom_drag_pressed = true
				_zoom_drag_active = false
				_zoom_drag_press_pos = event.position
				_last_mouse_pos = event.position
				get_viewport().set_input_as_handled()
			elif not event.pressed and _zoom_drag_pressed:
				if _zoom_drag_active:
					_push_history()
					_log("Zoom drag ended")
				_zoom_drag_pressed = false
				_zoom_drag_active = false
				get_viewport().set_input_as_handled()

		MOUSE_BUTTON_RIGHT:
			if event.pressed and event.alt_pressed:
				# Alt + right-click: dolly zoom (Hitchcock/Vertigo effect)
				_dolly_zoom_pressed = true
				_dolly_zoom_active = false
				_dolly_zoom_press_pos = event.position
				_last_mouse_pos = event.position
				# Store the frame height so we can maintain it as FOV changes
				_dolly_zoom_frame_height = _target_distance * tan(deg_to_rad(_target_fov * 0.5))
				get_viewport().set_input_as_handled()
			elif not event.pressed and _dolly_zoom_pressed:
				if _dolly_zoom_active:
					_push_history()
					_log("Dolly zoom ended (fov=%.1f dist=%.1f)" % [_target_fov, _target_distance])
				_dolly_zoom_pressed = false
				_dolly_zoom_active = false
				get_viewport().set_input_as_handled()
			elif event.pressed and event.shift_pressed:
				# Shift + right-click: roll camera
				_roll_drag_pressed = true
				_roll_drag_active = false
				_roll_drag_press_pos = event.position
				_last_mouse_pos = event.position
				get_viewport().set_input_as_handled()
			elif not event.pressed and _roll_drag_pressed:
				if _roll_drag_active:
					_push_history()
					_log("Roll drag ended (roll=%.1f)" % _target_roll)
				_roll_drag_pressed = false
				_roll_drag_active = false
				get_viewport().set_input_as_handled()
			elif event.pressed:
				_right_pressed = true
				_right_drag_active = false
				_right_press_pos = event.position
				_last_mouse_pos = event.position
				_orbit_velocity_samples.clear()
			else:
				if _right_drag_active:
					_push_history()
					get_viewport().set_input_as_handled()
					# Apply inertia from accumulated velocity samples
					_start_orbit_inertia()
					_log("Orbit drag ended")
				_right_pressed = false
				_right_drag_active = false

		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_middle_pressed = true
				_middle_press_pos = event.position
				_last_mouse_pos = event.position
			else:
				if _middle_pressed:
					# Check if it was a click (no drag) vs a pan drag
					var drag_distance := event.position.distance_to(_middle_press_pos)
					if drag_distance < MIDDLE_CLICK_DRAG_THRESHOLD:
						# Click without drag → toggle sticky sprint
						_sticky_sprint = not _sticky_sprint
						_log("Sticky sprint %s" % ("ON (10x)" if _sticky_sprint else "OFF"))
					else:
						# Was a pan drag
						_push_history()
						_log("Pan drag ended")
				_middle_pressed = false

		MOUSE_BUTTON_WHEEL_UP:
			var factor := 1.0 - ZOOM_SCROLL_FACTOR * _movement_speed
			if is_orthographic:
				camera.size = maxf(camera.size * factor, 5.0)
				_log("Zoom in (ortho) → size=%.1f" % camera.size)
			else:
				_target_distance = clampf(
					_target_distance * factor,
					MIN_DISTANCE,
					MAX_DISTANCE,
				)
				_log("Zoom in → dist=%.1f" % _target_distance)

		MOUSE_BUTTON_WHEEL_DOWN:
			var factor := 1.0 + ZOOM_SCROLL_FACTOR * _movement_speed
			if is_orthographic:
				camera.size = minf(camera.size * factor, 500.0)
				_log("Zoom out (ortho) → size=%.1f" % camera.size)
			else:
				_target_distance = clampf(
					_target_distance * factor,
					MIN_DISTANCE,
					MAX_DISTANCE,
				)
				_log("Zoom out → dist=%.1f" % _target_distance)


# --- Mouse Motion ---


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var delta := event.position - _last_mouse_pos
	_last_mouse_pos = event.position

	# Alt + left-click drag → orbit around raycast pivot
	if _alt_orbit_pressed:
		if not _alt_orbit_active:
			if event.position.distance_to(_alt_orbit_press_pos) > DRAG_THRESHOLD:
				_alt_orbit_active = true
				# Snap target to pivot and recompute distance so orbit feels centered
				_push_history()
				var camera_pos := camera.global_position
				_target_distance = camera_pos.distance_to(_alt_orbit_pivot)
				_target_distance = clampf(_target_distance, MIN_DISTANCE, MAX_DISTANCE)
				_target_target = _alt_orbit_pivot
				# Immediately sync interpolated values to prevent drift
				target = _target_target
				distance = _target_distance
				_update_camera_position()
				_log("Alt-orbit started (pivot=%s dist=%.1f)" % [_alt_orbit_pivot, _target_distance])
		if _alt_orbit_active:
			_target_azimuth += delta.x * ORBIT_SENSITIVITY * _precision
			var new_el := _target_elevation - delta.y * ORBIT_SENSITIVITY * _precision
			_target_elevation = clampf(new_el, MIN_ELEVATION, MAX_ELEVATION)
		get_viewport().set_input_as_handled()
		return

	# Alt + right-click drag → dolly zoom (Vertigo effect)
	if _dolly_zoom_pressed:
		if not _dolly_zoom_active:
			if event.position.distance_to(_dolly_zoom_press_pos) > DRAG_THRESHOLD:
				_dolly_zoom_active = true
				_push_history()
				_log("Dolly zoom started (fov=%.1f dist=%.1f)" % [_target_fov, _target_distance])
		if _dolly_zoom_active:
			# Vertical drag changes FOV; distance adjusts to maintain framing
			var fov_delta := -delta.y * DOLLY_ZOOM_SENSITIVITY * _precision
			var new_fov := clampf(_target_fov + fov_delta, MIN_FOV, MAX_FOV)
			# Recompute distance to keep frame height constant:
			# frame_height = distance * tan(fov/2)  →  distance = frame_height / tan(fov/2)
			var half_fov_rad := deg_to_rad(new_fov * 0.5)
			var new_distance := _dolly_zoom_frame_height / tan(half_fov_rad)
			new_distance = clampf(new_distance, MIN_DISTANCE, MAX_DISTANCE)
			_target_fov = new_fov
			_target_distance = new_distance
		get_viewport().set_input_as_handled()
		return

	# Shift + right-click drag → roll
	if _roll_drag_pressed:
		if not _roll_drag_active:
			if event.position.distance_to(_roll_drag_press_pos) > DRAG_THRESHOLD:
				_roll_drag_active = true
				_push_history()
				_log("Roll drag started (roll=%.1f)" % _target_roll)
		if _roll_drag_active:
			# Horizontal drag adjusts roll
			var roll_delta := delta.x * ROLL_SENSITIVITY * _precision
			_target_roll = fmod(_target_roll + roll_delta, 360.0)
		get_viewport().set_input_as_handled()
		return

	# Shift + left-click drag → zoom
	if _zoom_drag_pressed:
		if not _zoom_drag_active:
			if event.position.distance_to(_zoom_drag_press_pos) > DRAG_THRESHOLD:
				_zoom_drag_active = true
				_log("Zoom drag started")
		if _zoom_drag_active:
			var zoom_delta := delta.y * ZOOM_DRAG_SENSITIVITY * _movement_speed
			if is_orthographic:
				camera.size = clampf(camera.size * (1.0 + zoom_delta), 5.0, 500.0)
			else:
				_target_distance = clampf(
					_target_distance * (1.0 + zoom_delta),
					MIN_DISTANCE,
					MAX_DISTANCE,
				)
		get_viewport().set_input_as_handled()
		return

	# Right-click drag → orbit
	if _right_pressed:
		if not _right_drag_active:
			if event.position.distance_to(_right_press_pos) > DRAG_THRESHOLD:
				_right_drag_active = true
				_orbit_velocity_samples.clear()
				_log("Orbit drag started")
		if _right_drag_active:
			var az_delta := delta.x * ORBIT_SENSITIVITY * _precision
			var el_delta := -delta.y * ORBIT_SENSITIVITY * _precision
			_target_azimuth += az_delta
			var new_el := _target_elevation + el_delta
			_target_elevation = clampf(new_el, MIN_ELEVATION, MAX_ELEVATION)
			# Track velocity for inertia (convert to degrees/sec)
			if inertia_enabled:
				var velocity := Vector2(az_delta, el_delta) * INERTIA_VELOCITY_SCALE
				_orbit_velocity_samples.append(velocity)
				if _orbit_velocity_samples.size() > VELOCITY_SAMPLE_COUNT:
					_orbit_velocity_samples.pop_front()
			get_viewport().set_input_as_handled()

	# Middle-click drag → pan
	if _middle_pressed:
		var pan_scale := PAN_MOUSE_SENSITIVITY * (distance / 100.0) * _movement_speed
		var fwd := Vector3(
			sin(deg_to_rad(azimuth)),
			0,
			cos(deg_to_rad(azimuth)),
		)
		var right := Vector3(
			cos(deg_to_rad(azimuth)),
			0,
			-sin(deg_to_rad(azimuth)),
		)
		_target_target -= right * delta.x * pan_scale
		_target_target -= fwd * delta.y * pan_scale
		get_viewport().set_input_as_handled()


# --- Trackpad Gestures ---


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
	if Input.is_key_pressed(KEY_ALT):
		# Alt + two-finger swipe → orbit (rotate + tilt)
		_target_azimuth -= event.delta.x * TRACKPAD_ORBIT_SENSITIVITY * _precision
		var new_el := _target_elevation + event.delta.y * TRACKPAD_ORBIT_SENSITIVITY * _precision
		_target_elevation = clampf(new_el, MIN_ELEVATION, MAX_ELEVATION)
		get_viewport().set_input_as_handled()
	else:
		# Two-finger swipe → pan in camera plane
		var pan_scale := TRACKPAD_PAN_SENSITIVITY * (distance / 100.0) * _movement_speed
		var fwd := Vector3(
			sin(deg_to_rad(azimuth)),
			0,
			cos(deg_to_rad(azimuth)),
		)
		var right := Vector3(
			cos(deg_to_rad(azimuth)),
			0,
			-sin(deg_to_rad(azimuth)),
		)
		_target_target += right * event.delta.x * pan_scale
		_target_target += fwd * event.delta.y * pan_scale
		get_viewport().set_input_as_handled()


func _handle_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	# Pinch-to-zoom: factor > 1 = spread (zoom in), factor < 1 = pinch (zoom out)
	var zoom_amount := lerpf(1.0, event.factor, TRACKPAD_ZOOM_SENSITIVITY)
	if is_orthographic:
		camera.size = clampf(camera.size / zoom_amount, 5.0, 500.0)
		_log("Trackpad zoom (ortho) → size=%.1f" % camera.size)
	else:
		_target_distance = clampf(
			_target_distance / zoom_amount,
			MIN_DISTANCE,
			MAX_DISTANCE,
		)
		_log("Trackpad zoom → dist=%.1f" % _target_distance)
	get_viewport().set_input_as_handled()


# --- Special Keys (single-press) ---


func _handle_key(event: InputEventKey) -> void:
	# Double-tap WASD to dash
	if event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		if _check_double_tap(event.keycode):
			_trigger_dash(event.keycode)
			get_viewport().set_input_as_handled()
			return

	# Ctrl+R: toggle path recording
	if event.keycode == KEY_R and event.ctrl_pressed and not event.alt_pressed:
		toggle_path_recording()
		get_viewport().set_input_as_handled()
		return

	# Ctrl+P: toggle path playback
	if event.keycode == KEY_P and event.ctrl_pressed and not event.alt_pressed:
		toggle_path_playback()
		get_viewport().set_input_as_handled()
		return

	# Ctrl+1-9: save bookmark, Alt+1-9: recall bookmark
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var slot: int = event.keycode - KEY_1  # 0-8
		if event.ctrl_pressed and not event.alt_pressed:
			save_bookmark(slot)
			get_viewport().set_input_as_handled()
			return
		elif event.alt_pressed and not event.ctrl_pressed:
			recall_bookmark(slot)
			get_viewport().set_input_as_handled()
			return

	match event.keycode:
		KEY_H:
			go_home()
			get_viewport().set_input_as_handled()

		KEY_Z:
			# Level horizon — reset elevation and roll to defaults
			_push_history()
			_target_elevation = 30.0
			_target_roll = 0.0
			_log("Leveled horizon (elevation → 30°, roll → 0°)")
			get_viewport().set_input_as_handled()

		KEY_X:
			# Snap to ground at cursor XZ position
			snap_to_ground_at_cursor()
			get_viewport().set_input_as_handled()

		KEY_V:
			# Snap to ground at current target XZ position
			snap_to_ground_at_target()
			get_viewport().set_input_as_handled()

		KEY_BRACKETLEFT:
			var step := FOV_FINE_STEP if event.shift_pressed else FOV_STEP
			_target_fov = clampf(_target_fov - step, MIN_FOV, MAX_FOV)
			_log("FOV → %.0f" % _target_fov)
			get_viewport().set_input_as_handled()

		KEY_BRACKETRIGHT:
			var step := FOV_FINE_STEP if event.shift_pressed else FOV_STEP
			_target_fov = clampf(_target_fov + step, MIN_FOV, MAX_FOV)
			_log("FOV → %.0f" % _target_fov)
			get_viewport().set_input_as_handled()

		KEY_BACKSPACE:
			if event.shift_pressed:
				_history_forward()
			else:
				_history_back()
			get_viewport().set_input_as_handled()

		# Numpad views
		KEY_KP_1:
			_snap_to_view(0.0, 0.0)  # Front
			get_viewport().set_input_as_handled()

		KEY_KP_3:
			_snap_to_view(90.0, 0.0)  # Right
			get_viewport().set_input_as_handled()

		KEY_KP_7:
			_snap_to_view(_target_azimuth, 89.0)  # Top (keep current azimuth)
			get_viewport().set_input_as_handled()

		KEY_KP_5:
			_toggle_orthographic()
			get_viewport().set_input_as_handled()


# --- Double-Tap Dash ---


func _check_double_tap(keycode: int) -> bool:
	## Check if this keypress is a double-tap (within DOUBLE_TAP_WINDOW of last press).
	## Always updates the last tap time for this key.
	var now := Time.get_ticks_msec() / 1000.0
	var last_time: float = _last_tap_times.get(keycode, 0.0)
	var is_double := (now - last_time) < DOUBLE_TAP_WINDOW
	_last_tap_times[keycode] = now
	return is_double


func _trigger_dash(keycode: int) -> void:
	## Execute a dash movement in the direction of the pressed key.
	var dash_dir := Vector2.ZERO
	match keycode:
		KEY_W:
			dash_dir = Vector2(0, -1)  # Forward
		KEY_S:
			dash_dir = Vector2(0, 1)   # Backward
		KEY_A:
			dash_dir = Vector2(-1, 0)  # Left
		KEY_D:
			dash_dir = Vector2(1, 0)   # Right

	if dash_dir == Vector2.ZERO:
		return

	# Calculate world-space movement based on camera orientation
	var fwd := Vector3(
		sin(deg_to_rad(azimuth)),
		0,
		cos(deg_to_rad(azimuth)),
	)
	var right := Vector3(
		cos(deg_to_rad(azimuth)),
		0,
		-sin(deg_to_rad(azimuth)),
	)

	# Dash distance scales with current zoom level
	var dash_amount := PAN_BASE_SPEED * (distance / 100.0) * DASH_DISTANCE_MULTIPLIER * 0.1
	var world_dir := (fwd * dash_dir.y + right * dash_dir.x).normalized()

	_push_history()
	_target_target += world_dir * dash_amount
	_target_target.y = maxf(_target_target.y, MIN_TARGET_Y)

	dash_triggered.emit(world_dir)
	_log("Dash! dir=%s amount=%.1f" % [world_dir, dash_amount])


# --- Interpolation ---


func _smooth_interpolate(delta: float) -> void:
	var t := 1.0 - exp(-LERP_FACTOR * delta)
	azimuth = lerpf(azimuth, _target_azimuth, t)
	elevation = lerpf(elevation, _target_elevation, t)
	distance = lerpf(distance, _target_distance, t)
	target = target.lerp(_target_target, t)
	fov = lerpf(fov, _target_fov, t)
	roll = lerpf(roll, _target_roll, t)


func _update_camera_position() -> void:
	var azimuth_rad := deg_to_rad(azimuth)
	var elevation_rad := deg_to_rad(elevation)

	var offset := (
		Vector3(
			sin(azimuth_rad) * cos(elevation_rad),
			sin(elevation_rad),
			cos(azimuth_rad) * cos(elevation_rad),
		)
		* distance
	)

	camera.global_position = target + offset
	camera.fov = fov

	if is_orthographic:
		camera.size = distance * 0.3

	if camera.is_inside_tree():
		camera.look_at(target, Vector3.UP)
		# Apply roll rotation around forward axis (flight sim style)
		if roll != 0.0:
			camera.rotate_object_local(Vector3.FORWARD, deg_to_rad(roll))


# --- Alt-Orbit Raycast ---


func _raycast_pivot(screen_pos: Vector2):
	## Cast a ray from the camera through screen_pos to find a pivot point.
	## Returns Vector3 on hit, null on miss.
	if not camera or not camera.is_inside_tree():
		return null
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var to := from + dir * 2000.0

	var world_3d := get_world_3d()
	if not world_3d:
		return null
	var space_state := world_3d.direct_space_state
	if not space_state:
		return null

	var query := PhysicsRayQueryParameters3D.create(from, to)
	# Hit terrain (layer 1) and blocks (layer 2)
	query.collision_mask = 0b11
	var result := space_state.intersect_ray(query)
	if result and result.has("position"):
		return result.position as Vector3
	return null


# --- Public API ---


func focus_on(world_pos: Vector3) -> void:
	## Smoothly move camera to frame a world position.
	_push_history()
	_target_target = world_pos
	if _target_distance > 80.0:
		_target_distance = 80.0
	_log("Focus on %s" % world_pos)


func go_home() -> void:
	## Return to the saved home position.
	_push_history()
	_target_target = _home_target
	_target_azimuth = _home_azimuth
	_target_elevation = _home_elevation
	_target_distance = _home_distance
	_log("Go home")


# --- Ground Snap ---


func snap_to_ground_at_cursor() -> void:
	## Snap camera target to ground level (Y=0) at the XZ position under the cursor.
	## Uses a raycast to find where the cursor intersects the ground plane.
	var mouse_pos := get_viewport().get_mouse_position()
	var ground_pos = _raycast_ground_plane(mouse_pos)  # Variant (nullable Vector3)
	if ground_pos != null:
		_push_history()
		_target_target = ground_pos as Vector3
		ground_snap.emit(ground_pos as Vector3)
		_log("Snap to ground at cursor (XZ=%.0f, %.0f)" % [ground_pos.x, ground_pos.z])


func snap_to_ground_at_target() -> void:
	## Snap camera target to ground level (Y=0) at current target XZ position.
	_push_history()
	var ground_pos := Vector3(_target_target.x, 0.0, _target_target.z)
	_target_target = ground_pos
	ground_snap.emit(ground_pos)
	_log("Snap to ground at target (XZ=%.0f, %.0f)" % [ground_pos.x, ground_pos.z])


func _raycast_ground_plane(screen_pos: Vector2):
	## Cast a ray from the camera through screen_pos to find intersection with Y=0 plane.
	## Returns Vector3 on hit (with Y=0), null on miss (ray parallel or pointing away).
	if not camera or not camera.is_inside_tree():
		return null
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)

	# Find intersection with Y=0 plane
	# Ray: P = from + t * dir
	# Plane: Y = 0
	# Solve: from.y + t * dir.y = 0  =>  t = -from.y / dir.y
	if abs(dir.y) < 0.0001:
		# Ray is nearly parallel to ground plane
		return null
	var t := -from.y / dir.y
	if t < 0.0:
		# Intersection is behind the camera
		return null

	var hit_pos := from + dir * t
	return Vector3(hit_pos.x, 0.0, hit_pos.z)


# --- Inertia Settings ---


func set_inertia_enabled(enabled: bool) -> void:
	## Enable or disable orbit inertia (momentum on mouse release).
	if inertia_enabled != enabled:
		inertia_enabled = enabled
		if not enabled:
			_inertia_velocity = Vector2.ZERO
			_orbit_velocity_samples.clear()
		inertia_toggled.emit(enabled)
		_log("Inertia %s" % ("enabled" if enabled else "disabled"))


func is_inertia_enabled() -> bool:
	## Returns true if orbit inertia is enabled.
	return inertia_enabled


func stop_inertia() -> void:
	## Immediately stop any active inertia momentum.
	_inertia_velocity = Vector2.ZERO


func get_inertia_velocity() -> Vector2:
	## Returns the current inertia velocity (for debugging/UI).
	return _inertia_velocity


# --- Bookmarks ---


func save_bookmark(slot: int) -> void:
	## Save current camera state to a bookmark slot (0-8).
	_bookmarks[slot] = {
		"target": _target_target,
		"azimuth": _target_azimuth,
		"elevation": _target_elevation,
		"distance": _target_distance,
		"fov": _target_fov,
		"is_orthographic": is_orthographic,
	}
	bookmark_saved.emit(slot)
	_log("Bookmark %d saved (target=%s az=%.0f el=%.0f dist=%.0f fov=%.0f)" % [
		slot + 1, _target_target, _target_azimuth, _target_elevation,
		_target_distance, _target_fov])


func recall_bookmark(slot: int) -> void:
	## Recall a previously saved bookmark. Does nothing if slot is empty.
	if not _bookmarks.has(slot):
		_log("Bookmark %d is empty" % (slot + 1))
		return
	_push_history()
	var state: Dictionary = _bookmarks[slot]
	_target_target = state.target
	_target_azimuth = state.azimuth
	_target_elevation = state.elevation
	_target_distance = state.distance
	_target_fov = state.fov
	if state.is_orthographic != is_orthographic:
		_toggle_orthographic()
	bookmark_recalled.emit(slot)
	_log("Bookmark %d recalled (target=%s az=%.0f el=%.0f dist=%.0f fov=%.0f)" % [
		slot + 1, _target_target, _target_azimuth, _target_elevation,
		_target_distance, _target_fov])


func has_bookmark(slot: int) -> bool:
	## Returns true if the given bookmark slot has been saved.
	return _bookmarks.has(slot)


func get_bookmark(slot: int) -> Dictionary:
	## Returns the bookmark state at the given slot, or empty dict if not set.
	return _bookmarks.get(slot, {})


func clear_bookmark(slot: int) -> void:
	## Clear a bookmark slot.
	_bookmarks.erase(slot)
	_log("Bookmark %d cleared" % (slot + 1))


func clear_all_bookmarks() -> void:
	## Clear all bookmark slots.
	_bookmarks.clear()
	_log("All bookmarks cleared")


# --- Orthographic Views ---


func _snap_to_view(az: float, el: float) -> void:
	_push_history()
	_target_azimuth = az
	_target_elevation = el
	_log("Snap to view az=%.0f, el=%.0f" % [az, el])


func _toggle_orthographic() -> void:
	is_orthographic = not is_orthographic
	if is_orthographic:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = distance * 0.3
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_log("Orthographic: %s" % is_orthographic)


# --- History ---


func _push_history() -> void:
	var state := {
		"target": _target_target,
		"azimuth": _target_azimuth,
		"elevation": _target_elevation,
		"distance": _target_distance,
	}
	# Skip if barely moved from current top
	if _history.size() > 0 and _history_index >= 0:
		var last: Dictionary = _history[_history_index]
		if (
			last.target.distance_to(state.target) < HISTORY_MIN_DISTANCE
			and absf(last.azimuth - state.azimuth) < HISTORY_MIN_ANGLE
		):
			return

	# Truncate forward history when pushing after going back
	if _history_index < _history.size() - 1:
		_history.resize(_history_index + 1)

	_history.append(state)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_history_index = _history.size() - 1


func _history_back() -> void:
	if _history_index > 0:
		_history_index -= 1
		_restore_history(_history[_history_index])
		_log("History back (%d/%d)" % [_history_index, _history.size()])


func _history_forward() -> void:
	if _history_index < _history.size() - 1:
		_history_index += 1
		_restore_history(_history[_history_index])
		_log("History forward (%d/%d)" % [_history_index, _history.size()])


func _restore_history(state: Dictionary) -> void:
	_target_target = state.target
	_target_azimuth = state.azimuth
	_target_elevation = state.elevation
	_target_distance = state.distance


# --- Path Recording and Playback ---


func toggle_path_recording() -> void:
	## Toggle camera path recording on/off.
	## When recording starts, clears any existing path.
	## When recording stops, the path is ready for playback.
	if _is_playing:
		stop_path_playback()
	if _is_recording:
		stop_path_recording()
	else:
		start_path_recording()


func start_path_recording() -> void:
	## Start recording camera path. Clears any existing keyframes.
	_is_recording = true
	_path_keyframes.clear()
	_last_keyframe_time = 0.0
	# Capture initial keyframe
	add_path_keyframe()
	path_recording_started.emit()
	_log("Path recording started")


func stop_path_recording() -> void:
	## Stop recording camera path.
	_is_recording = false
	var count := _path_keyframes.size()
	path_recording_stopped.emit(count)
	_log("Path recording stopped (%d keyframes)" % count)


func add_path_keyframe() -> void:
	## Add current camera state as a path keyframe.
	var keyframe := {
		"target": _target_target,
		"azimuth": _target_azimuth,
		"elevation": _target_elevation,
		"distance": _target_distance,
		"fov": _target_fov,
		"is_orthographic": is_orthographic,
		"time": Time.get_ticks_msec() / 1000.0,
	}
	_path_keyframes.append(keyframe)
	_last_keyframe_time = keyframe.time
	var idx := _path_keyframes.size() - 1
	path_keyframe_added.emit(idx)
	_log("Path keyframe %d added (target=%s az=%.0f el=%.0f)" % [
		idx, _target_target, _target_azimuth, _target_elevation])


func is_recording_path() -> bool:
	## Returns true if currently recording a camera path.
	return _is_recording


func get_path_keyframe_count() -> int:
	## Returns the number of recorded keyframes.
	return _path_keyframes.size()


func clear_path() -> void:
	## Clear all recorded keyframes.
	_path_keyframes.clear()
	_log("Path cleared")


func toggle_path_playback() -> void:
	## Toggle camera path playback on/off.
	if _is_recording:
		stop_path_recording()
	if _is_playing:
		stop_path_playback()
	else:
		start_path_playback()


func start_path_playback() -> void:
	## Start playing back the recorded camera path.
	if _path_keyframes.size() < 2:
		_log("Path playback requires at least 2 keyframes (have %d)" % _path_keyframes.size())
		return
	_is_playing = true
	_playback_time = 0.0
	# Set camera to first keyframe immediately
	var first: Dictionary = _path_keyframes[0]
	_target_target = first.target
	_target_azimuth = first.azimuth
	_target_elevation = first.elevation
	_target_distance = first.distance
	_target_fov = first.fov
	if first.is_orthographic != is_orthographic:
		_toggle_orthographic()
	path_playback_started.emit(_path_keyframes.size())
	_log("Path playback started (%d keyframes)" % _path_keyframes.size())


func stop_path_playback() -> void:
	## Stop path playback.
	_is_playing = false
	path_playback_stopped.emit()
	_log("Path playback stopped")


func is_playing_path() -> bool:
	## Returns true if currently playing back a camera path.
	return _is_playing


func set_playback_speed(speed: float) -> void:
	## Set the playback speed multiplier (default 1.0).
	_playback_speed = maxf(0.1, speed)
	_log("Playback speed set to %.1fx" % _playback_speed)


func get_playback_speed() -> float:
	## Get the current playback speed multiplier.
	return _playback_speed


func _update_playback(delta: float) -> void:
	## Update playback position and interpolate camera state.
	if not _is_playing or _path_keyframes.size() < 2:
		return

	_playback_time += delta * _playback_speed

	# Calculate total path duration (keyframes evenly spaced)
	var segment_count := _path_keyframes.size() - 1
	var total_duration := segment_count * PATH_PLAYBACK_DURATION

	# Loop or stop at end
	if _playback_time >= total_duration:
		# Loop back to start
		_playback_time = fmod(_playback_time, total_duration)

	# Find current segment and interpolation factor
	var segment_index := int(_playback_time / PATH_PLAYBACK_DURATION)
	segment_index = clampi(segment_index, 0, segment_count - 1)
	var segment_t := fmod(_playback_time, PATH_PLAYBACK_DURATION) / PATH_PLAYBACK_DURATION

	# Get keyframes for current segment
	var kf_a: Dictionary = _path_keyframes[segment_index]
	var kf_b: Dictionary = _path_keyframes[segment_index + 1]

	# Smooth interpolation using smoothstep for easing
	var t := _smoothstep(segment_t)

	# Interpolate camera state
	_target_target = kf_a.target.lerp(kf_b.target, t)
	_target_azimuth = lerpf(kf_a.azimuth, kf_b.azimuth, t)
	_target_elevation = lerpf(kf_a.elevation, kf_b.elevation, t)
	_target_distance = lerpf(kf_a.distance, kf_b.distance, t)
	_target_fov = lerpf(kf_a.fov, kf_b.fov, t)

	# Handle orthographic transitions at segment boundaries
	if kf_a.is_orthographic != kf_b.is_orthographic and segment_t > 0.5:
		if is_orthographic != kf_b.is_orthographic:
			_toggle_orthographic()
	elif kf_a.is_orthographic != is_orthographic:
		_toggle_orthographic()


func _smoothstep(t: float) -> float:
	## Hermite smoothstep for smooth easing: 3t² - 2t³
	return t * t * (3.0 - 2.0 * t)


func get_path_keyframes() -> Array[Dictionary]:
	## Returns a copy of the recorded keyframes.
	return _path_keyframes.duplicate()


func set_path_keyframes(keyframes: Array[Dictionary]) -> void:
	## Set keyframes directly (for loading saved paths).
	_path_keyframes = keyframes.duplicate()
	_log("Path loaded (%d keyframes)" % _path_keyframes.size())
