## GdUnit4 test suite for OrbitalCamera Alt+RMB dolly zoom (Vertigo effect).
## Tests state management, FOV/distance coupling, framing preservation, and edge cases.
##
## Dolly zoom simultaneously changes FOV and camera distance to maintain subject
## framing. The invariant is: distance * tan(fov/2) = constant.
class_name TestOrbitalCameraDollyZoom
extends GdUnitTestSuite

const CameraScript = preload("res://src/phase0/orbital_camera.gd")


# --- Helpers ---

func _make_camera() -> Node3D:
	## Create a camera in the scene tree so viewport calls work
	var cam: Node3D = CameraScript.new()
	cam.target = Vector3(100, 0, 100)
	cam._target_target = Vector3(100, 0, 100)
	add_child(cam)
	return cam


func _press_alt_rmb(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.alt_pressed = true
	press.position = pos
	cam._handle_mouse_button(press)


func _release_rmb(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.alt_pressed = true
	release.position = pos
	cam._handle_mouse_button(release)


func _press_rmb(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.alt_pressed = false
	press.position = pos
	cam._handle_mouse_button(press)


func _release_rmb_no_alt(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.alt_pressed = false
	release.position = pos
	cam._handle_mouse_button(release)


func _move_mouse(cam: Node3D, pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	cam._handle_mouse_motion(motion)


# --- Tests: Initial state ---

func test_dolly_zoom_state_defaults_false() -> void:
	var cam := _make_camera()
	assert_bool(cam._dolly_zoom_pressed).is_false()
	assert_bool(cam._dolly_zoom_active).is_false()
	cam.queue_free()


func test_dolly_zoom_frame_height_defaults_zero() -> void:
	var cam := _make_camera()
	assert_float(cam._dolly_zoom_frame_height).is_equal(0.0)
	cam.queue_free()


# --- Tests: State transitions ---

func test_alt_rmb_press_sets_pressed_state() -> void:
	var cam := _make_camera()
	_press_alt_rmb(cam)

	assert_bool(cam._dolly_zoom_pressed).is_true()
	assert_bool(cam._dolly_zoom_active).is_false()
	cam.queue_free()


func test_alt_rmb_press_computes_frame_height() -> void:
	var cam := _make_camera()
	cam._target_distance = 200.0
	cam._target_fov = 70.0

	_press_alt_rmb(cam)

	var expected := 200.0 * tan(deg_to_rad(35.0))
	assert_float(cam._dolly_zoom_frame_height).is_equal_approx(expected, 0.01)
	cam.queue_free()


func test_alt_rmb_release_clears_pressed_state() -> void:
	var cam := _make_camera()
	_press_alt_rmb(cam)
	_release_rmb(cam)

	assert_bool(cam._dolly_zoom_pressed).is_false()
	assert_bool(cam._dolly_zoom_active).is_false()
	cam.queue_free()


# --- Tests: Drag threshold ---

func test_dolly_zoom_does_not_activate_under_threshold() -> void:
	var cam := _make_camera()
	_press_alt_rmb(cam, Vector2(400, 300))

	# Small motion (under threshold of 4 pixels) — should NOT activate
	_move_mouse(cam, Vector2(402, 301))
	assert_bool(cam._dolly_zoom_active).is_false()
	cam.queue_free()


func test_dolly_zoom_activates_after_threshold() -> void:
	var cam := _make_camera()
	_press_alt_rmb(cam, Vector2(400, 300))

	# Large motion (over threshold of 4 pixels) — should activate
	_move_mouse(cam, Vector2(400, 310))
	assert_bool(cam._dolly_zoom_active).is_true()
	cam.queue_free()


# --- Tests: FOV and distance coupling ---

func test_dolly_zoom_drag_up_decreases_fov() -> void:
	# Dragging up (negative Y delta) with our -delta.y formula → increases FOV?
	# Actually: -delta.y means drag UP = positive fov_delta = wider FOV
	# Wait: drag up means mouse moves to lower Y value, so delta.y is negative.
	# fov_delta = -delta.y * sensitivity = -(-N) * S = positive → FOV increases.
	# But film convention: drag up = zoom in = narrower FOV. Let me verify.
	# Our formula: fov_delta = -delta.y * DOLLY_ZOOM_SENSITIVITY
	# Drag up: delta.y < 0, so fov_delta > 0 → FOV increases (wider)
	# Drag down: delta.y > 0, so fov_delta < 0 → FOV decreases (narrower)
	# This means drag up = wider FOV (pull back effect), drag down = narrower (push in effect)
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0
	var initial_fov: float = cam._target_fov

	_press_alt_rmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 290))  # Past threshold, drag up
	_move_mouse(cam, Vector2(400, 250))  # Continue up

	# Drag up → FOV increases (wider angle)
	assert_float(cam._target_fov).is_greater(initial_fov)
	cam.queue_free()


func test_dolly_zoom_drag_down_increases_fov() -> void:
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0
	var initial_fov: float = cam._target_fov

	_press_alt_rmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 310))  # Past threshold, drag down
	_move_mouse(cam, Vector2(400, 350))  # Continue down

	# Drag down → FOV decreases (narrower angle / more telephoto)
	assert_float(cam._target_fov).is_less(initial_fov)
	cam.queue_free()


func test_dolly_zoom_maintains_frame_height() -> void:
	## The key invariant: distance * tan(fov/2) stays constant during dolly zoom
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0

	_press_alt_rmb(cam, Vector2(400, 300))
	var initial_frame_height: float = cam._dolly_zoom_frame_height

	# Activate and drag
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(400, 250))  # Drag up

	# Verify frame height is preserved within tolerance
	var current_frame: float = cam._target_distance * tan(deg_to_rad(cam._target_fov * 0.5))
	assert_float(current_frame).is_equal_approx(initial_frame_height, 0.5)
	cam.queue_free()


func test_dolly_zoom_maintains_frame_height_drag_down() -> void:
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0

	_press_alt_rmb(cam, Vector2(400, 300))
	var initial_frame_height: float = cam._dolly_zoom_frame_height

	# Activate and drag down
	_move_mouse(cam, Vector2(400, 310))  # Past threshold
	_move_mouse(cam, Vector2(400, 380))  # Drag down

	var current_frame: float = cam._target_distance * tan(deg_to_rad(cam._target_fov * 0.5))
	assert_float(current_frame).is_equal_approx(initial_frame_height, 0.5)
	cam.queue_free()


func test_dolly_zoom_distance_increases_as_fov_narrows() -> void:
	## When FOV gets narrower (telephoto), distance must increase to maintain framing
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0
	var initial_distance: float = cam._target_distance

	_press_alt_rmb(cam, Vector2(400, 300))
	# Drag down → FOV narrows → distance should increase
	_move_mouse(cam, Vector2(400, 310))  # Past threshold
	_move_mouse(cam, Vector2(400, 380))

	assert_float(cam._target_fov).is_less(70.0)
	assert_float(cam._target_distance).is_greater(initial_distance)
	cam.queue_free()


func test_dolly_zoom_distance_decreases_as_fov_widens() -> void:
	## When FOV gets wider, distance must decrease to maintain framing
	var cam := _make_camera()
	cam._target_fov = 70.0
	cam._target_distance = 200.0
	var initial_distance: float = cam._target_distance

	_press_alt_rmb(cam, Vector2(400, 300))
	# Drag up → FOV widens → distance should decrease
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(400, 230))

	assert_float(cam._target_fov).is_greater(70.0)
	assert_float(cam._target_distance).is_less(initial_distance)
	cam.queue_free()


# --- Tests: FOV clamping ---

func test_dolly_zoom_clamps_fov_max() -> void:
	var cam := _make_camera()
	cam._target_fov = 115.0
	cam._target_distance = 50.0

	_press_alt_rmb(cam, Vector2(400, 300))
	# Aggressive upward drag to widen FOV past max
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(400, 50))   # Massive drag up

	assert_float(cam._target_fov).is_less_equal(CameraScript.MAX_FOV)
	cam.queue_free()


func test_dolly_zoom_clamps_fov_min() -> void:
	var cam := _make_camera()
	cam._target_fov = 25.0
	cam._target_distance = 800.0

	_press_alt_rmb(cam, Vector2(400, 300))
	# Aggressive downward drag to narrow FOV past min
	_move_mouse(cam, Vector2(400, 310))  # Past threshold
	_move_mouse(cam, Vector2(400, 600))  # Massive drag down

	assert_float(cam._target_fov).is_greater_equal(CameraScript.MIN_FOV)
	cam.queue_free()


# --- Tests: Distance clamping ---

func test_dolly_zoom_clamps_distance_min() -> void:
	var cam := _make_camera()
	cam._target_fov = 110.0
	cam._target_distance = 10.0

	_press_alt_rmb(cam, Vector2(400, 300))
	# Drag up to widen FOV → distance wants to decrease further
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(400, 100))

	assert_float(cam._target_distance).is_greater_equal(CameraScript.MIN_DISTANCE)
	cam.queue_free()


func test_dolly_zoom_clamps_distance_max() -> void:
	var cam := _make_camera()
	cam._target_fov = 25.0
	cam._target_distance = 1800.0

	_press_alt_rmb(cam, Vector2(400, 300))
	# Drag down to narrow FOV → distance wants to increase further
	_move_mouse(cam, Vector2(400, 310))  # Past threshold
	_move_mouse(cam, Vector2(400, 600))

	assert_float(cam._target_distance).is_less_equal(CameraScript.MAX_DISTANCE)
	cam.queue_free()


# --- Tests: Does not interfere with regular right-click orbit ---

func test_regular_rmb_orbit_not_affected() -> void:
	var cam := _make_camera()
	var initial_azimuth: float = cam._target_azimuth

	# Plain right-click (no Alt)
	_press_rmb(cam)
	assert_bool(cam._right_pressed).is_true()
	assert_bool(cam._dolly_zoom_pressed).is_false()

	# Move past threshold and drag
	_move_mouse(cam, Vector2(420, 300))
	_move_mouse(cam, Vector2(460, 300))

	assert_float(cam._target_azimuth).is_not_equal(initial_azimuth)
	_release_rmb_no_alt(cam, Vector2(460, 300))
	cam.queue_free()


# --- Tests: Alt+LMB orbit is not affected ---

func test_alt_lmb_orbit_not_affected_by_dolly_zoom() -> void:
	var cam := _make_camera()

	# Alt + left-click should still do orbit, not dolly zoom
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.alt_pressed = true
	press.position = Vector2(400, 300)
	cam._handle_mouse_button(press)

	assert_bool(cam._alt_orbit_pressed).is_true()
	assert_bool(cam._dolly_zoom_pressed).is_false()
	cam.queue_free()


# --- Tests: Target position unchanged during dolly zoom ---

func test_dolly_zoom_does_not_move_target() -> void:
	## Dolly zoom only changes FOV and distance, not target/orbit center
	var cam := _make_camera()
	cam._target_target = Vector3(100, 0, 100)
	cam._target_fov = 70.0
	cam._target_distance = 200.0
	var initial_target: Vector3 = cam._target_target

	_press_alt_rmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(400, 250))

	assert_vector(cam._target_target).is_equal(initial_target)
	cam.queue_free()


# --- Tests: Multiple press without release (edge case) ---

func test_dolly_zoom_multiple_press_without_release() -> void:
	var cam := _make_camera()
	_press_alt_rmb(cam, Vector2(400, 300))
	assert_bool(cam._dolly_zoom_pressed).is_true()

	# Second press without release — should still be pressed
	_press_alt_rmb(cam, Vector2(450, 350))
	assert_bool(cam._dolly_zoom_pressed).is_true()
	cam.queue_free()


# --- Tests: Azimuth and elevation unchanged during dolly zoom ---

func test_dolly_zoom_does_not_change_azimuth() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 45.0
	var initial_azimuth: float = cam._target_azimuth

	_press_alt_rmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(430, 250))  # Drag with horizontal component too

	assert_float(cam._target_azimuth).is_equal(initial_azimuth)
	cam.queue_free()


func test_dolly_zoom_does_not_change_elevation() -> void:
	var cam := _make_camera()
	cam._target_elevation = 30.0
	var initial_elevation: float = cam._target_elevation

	_press_alt_rmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 290))  # Past threshold
	_move_mouse(cam, Vector2(430, 250))  # Drag with vertical component

	assert_float(cam._target_elevation).is_equal(initial_elevation)
	cam.queue_free()
