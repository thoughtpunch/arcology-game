## GdUnit4 test suite for OrbitalCamera Alt+LMB orbit feature
## Tests state management, input handling, and edge cases.
##
## The orbital camera creates a Camera3D child in _ready() and needs
## to be in the scene tree for viewport/look_at access. All tests
## that interact with mouse handlers use add_child() + queue_free().
class_name TestOrbitalCameraAltOrbit
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


func _press_alt_lmb(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.alt_pressed = true
	press.position = pos
	cam._handle_mouse_button(press)


func _release_lmb(cam: Node3D, pos: Vector2 = Vector2(400, 300)) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.alt_pressed = true
	release.position = pos
	cam._handle_mouse_button(release)


func _move_mouse(cam: Node3D, pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	cam._handle_mouse_motion(motion)


# --- Tests: Initial state ---

func test_alt_orbit_state_defaults_false() -> void:
	var cam := _make_camera()
	assert_bool(cam._alt_orbit_pressed).is_false()
	assert_bool(cam._alt_orbit_active).is_false()
	cam.queue_free()


func test_alt_orbit_pivot_defaults_zero() -> void:
	var cam := _make_camera()
	assert_vector(cam._alt_orbit_pivot).is_equal(Vector3.ZERO)
	cam.queue_free()


# --- Tests: Raycast pivot returns null without physics bodies ---

func test_raycast_pivot_returns_null_without_physics() -> void:
	# In a test tree with no physics bodies, raycast should return null
	var cam := _make_camera()
	var result = cam._raycast_pivot(Vector2(400, 300))
	assert_that(result).is_null()
	cam.queue_free()


# --- Tests: Alt-orbit state transitions via simulated mouse events ---

func test_alt_lmb_press_sets_pressed_state() -> void:
	var cam := _make_camera()
	_press_alt_lmb(cam)

	assert_bool(cam._alt_orbit_pressed).is_true()
	assert_bool(cam._alt_orbit_active).is_false()
	cam.queue_free()


func test_alt_lmb_release_clears_pressed_state() -> void:
	var cam := _make_camera()
	_press_alt_lmb(cam)
	_release_lmb(cam)

	assert_bool(cam._alt_orbit_pressed).is_false()
	assert_bool(cam._alt_orbit_active).is_false()
	cam.queue_free()


func test_alt_lmb_drag_does_not_activate_under_threshold() -> void:
	var cam := _make_camera()
	_press_alt_lmb(cam, Vector2(400, 300))

	# Small motion (under threshold of 4 pixels) — should NOT activate
	_move_mouse(cam, Vector2(402, 301))
	assert_bool(cam._alt_orbit_active).is_false()
	cam.queue_free()


func test_alt_lmb_drag_activates_after_threshold() -> void:
	var cam := _make_camera()
	_press_alt_lmb(cam, Vector2(400, 300))

	# Large motion (over threshold of 4 pixels) — should activate
	_move_mouse(cam, Vector2(410, 310))
	assert_bool(cam._alt_orbit_active).is_true()
	cam.queue_free()


func test_alt_orbit_pivot_fallback_to_target_on_miss() -> void:
	# When raycast misses (no physics bodies), pivot falls back to current target
	var cam := _make_camera()
	cam._target_target = Vector3(50, 10, 80)

	_press_alt_lmb(cam)

	assert_vector(cam._alt_orbit_pivot).is_equal(Vector3(50, 10, 80))
	cam.queue_free()


func test_alt_orbit_stores_original_target() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(200, 0, 200)

	_press_alt_lmb(cam)

	assert_vector(cam._alt_orbit_original_target).is_equal(Vector3(200, 0, 200))
	cam.queue_free()


# --- Tests: Shift+LMB does NOT trigger alt-orbit ---

func test_shift_lmb_does_not_trigger_alt_orbit() -> void:
	var cam := _make_camera()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.shift_pressed = true
	event.alt_pressed = false
	event.position = Vector2(400, 300)
	cam._handle_mouse_button(event)

	assert_bool(cam._alt_orbit_pressed).is_false()
	cam.queue_free()


# --- Tests: Alt-orbit changes azimuth/elevation during drag ---

func test_alt_orbit_drag_changes_azimuth() -> void:
	var cam := _make_camera()
	var initial_azimuth: float = cam._target_azimuth

	_press_alt_lmb(cam, Vector2(400, 300))
	# Move past threshold to activate
	_move_mouse(cam, Vector2(420, 300))
	# Drag horizontally
	_move_mouse(cam, Vector2(460, 300))

	assert_float(cam._target_azimuth).is_not_equal(initial_azimuth)
	cam.queue_free()


func test_alt_orbit_drag_changes_elevation() -> void:
	var cam := _make_camera()
	var initial_elevation: float = cam._target_elevation

	_press_alt_lmb(cam, Vector2(400, 300))
	# Move past threshold to activate
	_move_mouse(cam, Vector2(400, 320))
	# Drag vertically
	_move_mouse(cam, Vector2(400, 360))

	assert_float(cam._target_elevation).is_not_equal(initial_elevation)
	cam.queue_free()


# --- Tests: Elevation remains clamped during alt-orbit ---

func test_alt_orbit_clamps_elevation_max() -> void:
	var cam := _make_camera()
	cam._target_elevation = 85.0

	_press_alt_lmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 280))  # Past threshold
	_move_mouse(cam, Vector2(400, 100))  # Aggressive upward drag

	assert_float(cam._target_elevation).is_less_equal(CameraScript.MAX_ELEVATION)
	cam.queue_free()


func test_alt_orbit_clamps_elevation_min() -> void:
	var cam := _make_camera()
	cam._target_elevation = -85.0

	_press_alt_lmb(cam, Vector2(400, 300))
	_move_mouse(cam, Vector2(400, 320))  # Past threshold
	_move_mouse(cam, Vector2(400, 600))  # Aggressive downward drag

	assert_float(cam._target_elevation).is_greater_equal(CameraScript.MIN_ELEVATION)
	cam.queue_free()


# --- Tests: Regular right-click orbit still works ---

func test_right_click_orbit_not_affected_by_alt_orbit() -> void:
	var cam := _make_camera()
	var initial_azimuth: float = cam._target_azimuth

	# Right-click press
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(400, 300)
	cam._handle_mouse_button(press)

	assert_bool(cam._right_pressed).is_true()
	assert_bool(cam._alt_orbit_pressed).is_false()

	# Move past threshold and drag
	_move_mouse(cam, Vector2(420, 300))
	_move_mouse(cam, Vector2(460, 300))

	assert_float(cam._target_azimuth).is_not_equal(initial_azimuth)
	cam.queue_free()


# --- Tests: Alt-orbit sets target to pivot when activated ---

func test_alt_orbit_sets_target_to_pivot_on_activate() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(100, 0, 100)

	_press_alt_lmb(cam, Vector2(400, 300))
	# Move past threshold to activate — pivot = target (no physics)
	_move_mouse(cam, Vector2(420, 310))

	assert_vector(cam._target_target).is_equal(cam._alt_orbit_pivot)
	cam.queue_free()


# --- Tests: Multiple press without release (edge case) ---

func test_alt_lmb_multiple_press_without_release() -> void:
	var cam := _make_camera()
	_press_alt_lmb(cam, Vector2(400, 300))
	assert_bool(cam._alt_orbit_pressed).is_true()

	# Second press without release — should still be pressed
	_press_alt_lmb(cam, Vector2(450, 350))
	assert_bool(cam._alt_orbit_pressed).is_true()
	cam.queue_free()
