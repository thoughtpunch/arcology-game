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
##   Double-click: Handled by parent (focus on object)
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
## Keyboard — Bookmarks:
##   Ctrl+1-9: Save camera bookmark to slot
##   Alt+1-9: Recall camera bookmark from slot
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
const FOV_STEP: float = 5.0
const FOV_FINE_STEP: float = 1.0
const LERP_FACTOR: float = 14.0

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
var is_orthographic: bool = false
var camera: Camera3D

# Smooth interpolation targets
var _target_azimuth: float = 45.0
var _target_elevation: float = 30.0
var _target_distance: float = 200.0
var _target_target: Vector3 = Vector3.ZERO
var _target_fov: float = DEFAULT_FOV

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

# History
var _history: Array[Dictionary] = []
var _history_index: int = -1

# Bookmarks (slots 0-8, mapped to keys 1-9)
var _bookmarks: Dictionary = {}  # int -> Dictionary (slot -> camera state)

signal bookmark_saved(slot: int)
signal bookmark_recalled(slot: int)


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
	_update_speed_factors()
	_handle_keyboard(delta)
	_smooth_interpolate(delta)
	_update_camera_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
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
	_precision = 0.25 if shift else 1.0
	var mode_name: String
	if shift and ctrl:
		_movement_speed = 10.0
		mode_name = "sprint (10x)"
	elif ctrl:
		_movement_speed = 3.0
		mode_name = "boost (3x)"
	elif shift:
		_movement_speed = 0.25
		mode_name = "precision (0.25x)"
	else:
		_movement_speed = 1.0
		mode_name = "normal"
	if mode_name != _prev_speed_mode:
		_log("Speed mode: %s" % mode_name)
		_prev_speed_mode = mode_name


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
			elif event.pressed:
				_right_pressed = true
				_right_drag_active = false
				_right_press_pos = event.position
				_last_mouse_pos = event.position
			else:
				if _right_drag_active:
					_push_history()
					get_viewport().set_input_as_handled()
					_log("Orbit drag ended")
				_right_pressed = false
				_right_drag_active = false

		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_middle_pressed = true
				_last_mouse_pos = event.position
				_log("Pan drag started")
			else:
				if _middle_pressed:
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
				_log("Orbit drag started")
		if _right_drag_active:
			_target_azimuth += delta.x * ORBIT_SENSITIVITY * _precision
			var new_el := _target_elevation - delta.y * ORBIT_SENSITIVITY * _precision
			_target_elevation = clampf(new_el, MIN_ELEVATION, MAX_ELEVATION)
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


# --- Special Keys (single-press) ---


func _handle_key(event: InputEventKey) -> void:
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
			# Level horizon — reset elevation to comfortable default
			_push_history()
			_target_elevation = 30.0
			_log("Leveled horizon (elevation → 30°)")
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


# --- Interpolation ---


func _smooth_interpolate(delta: float) -> void:
	var t := 1.0 - exp(-LERP_FACTOR * delta)
	azimuth = lerpf(azimuth, _target_azimuth, t)
	elevation = lerpf(elevation, _target_elevation, t)
	distance = lerpf(distance, _target_distance, t)
	target = target.lerp(_target_target, t)
	fov = lerpf(fov, _target_fov, t)


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
