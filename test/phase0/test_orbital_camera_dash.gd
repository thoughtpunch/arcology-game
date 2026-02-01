## GdUnit4 test suite for orbital camera double-tap dash feature.
## Tests that quick double-tap of WASD triggers a dash movement.
class_name TestOrbitalCameraDash
extends GdUnitTestSuite

const CameraScript = preload("res://src/game/orbital_camera.gd")

var camera: Node3D

# Signal tracking for test_dash_emits_signal
var _signal_received: bool = false
var _received_direction: Vector3 = Vector3.ZERO


func _on_dash_triggered(dir: Vector3) -> void:
	_signal_received = true
	_received_direction = dir


func before_test() -> void:
	camera = auto_free(CameraScript.new())
	# Add to tree so camera can access viewport
	add_child(camera)
	await get_tree().process_frame


func after_test() -> void:
	if camera:
		remove_child(camera)


# === Double-Tap Detection ===

func test_single_tap_does_not_trigger_dash() -> void:
	## A single tap should not be detected as a double-tap.
	var is_double: bool = camera._check_double_tap(KEY_W)
	assert_bool(is_double).is_false()


func test_double_tap_within_window_triggers() -> void:
	## Two taps within 300ms should be detected as a double-tap.
	# First tap
	camera._check_double_tap(KEY_W)
	# Second tap immediately after
	var is_double: bool = camera._check_double_tap(KEY_W)
	assert_bool(is_double).is_true()


func test_taps_outside_window_do_not_trigger() -> void:
	## Two taps separated by more than 300ms should not be detected.
	# First tap
	camera._check_double_tap(KEY_W)
	# Manually set the last tap time to 500ms ago
	camera._last_tap_times[KEY_W] = (Time.get_ticks_msec() / 1000.0) - 0.5
	# Second tap now
	var is_double: bool = camera._check_double_tap(KEY_W)
	assert_bool(is_double).is_false()


func test_different_keys_have_separate_timers() -> void:
	## Double-tap detection should track each key independently.
	# Tap W
	camera._check_double_tap(KEY_W)
	# Tap A (different key, should not count as double-tap)
	var is_double_a: bool = camera._check_double_tap(KEY_A)
	assert_bool(is_double_a).is_false()
	# Tap A again (same key, now should be double-tap)
	var is_double_a2: bool = camera._check_double_tap(KEY_A)
	assert_bool(is_double_a2).is_true()


# === Dash Movement ===

func test_dash_forward_moves_target() -> void:
	## Double-tap W should move the camera target forward.
	var initial_target: Vector3 = camera._target_target
	camera._trigger_dash(KEY_W)
	# Target should have moved (Z component changes based on azimuth)
	assert_bool(camera._target_target != initial_target).is_true()


func test_dash_backward_moves_opposite() -> void:
	## Double-tap S should move in the opposite direction of W.
	camera._target_target = Vector3.ZERO
	camera.azimuth = 0.0  # Facing north (positive Z)

	# Dash forward
	camera._trigger_dash(KEY_W)
	var forward_target: Vector3 = camera._target_target

	# Reset and dash backward
	camera._target_target = Vector3.ZERO
	camera._trigger_dash(KEY_S)
	var backward_target: Vector3 = camera._target_target

	# They should be opposite directions (Z signs should differ)
	assert_bool(forward_target.z * backward_target.z < 0).is_true()


func test_dash_left_right_perpendicular() -> void:
	## A and D dashes should move perpendicular to W and S.
	camera._target_target = Vector3.ZERO
	camera.azimuth = 0.0  # Facing north

	# Dash left
	camera._trigger_dash(KEY_A)
	var left_target: Vector3 = camera._target_target

	# Left movement at azimuth=0 should be primarily in negative X
	assert_float(left_target.x).is_less(0)


func test_dash_respects_camera_azimuth() -> void:
	## Dash direction should rotate with the camera's azimuth.
	## At azimuth=90, camera is positioned at +X looking towards -X (west).
	## Forward dash moves target towards where camera is looking.
	camera._target_target = Vector3.ZERO
	camera.azimuth = 90.0  # Camera at +X, looking west (-X)

	camera._trigger_dash(KEY_W)
	var target: Vector3 = camera._target_target

	# At azimuth=90, forward (where camera looks) is negative X direction
	assert_float(target.x).is_less(0)


func test_dash_scales_with_distance() -> void:
	## Dash distance should scale with camera zoom level.
	camera._target_target = Vector3.ZERO
	camera.distance = 100.0
	camera._trigger_dash(KEY_W)
	var close_movement: float = camera._target_target.length()

	camera._target_target = Vector3.ZERO
	camera.distance = 200.0
	camera._trigger_dash(KEY_W)
	var far_movement: float = camera._target_target.length()

	# Farther zoom = larger dash
	assert_float(far_movement).is_greater(close_movement)


func test_dash_emits_signal() -> void:
	## Dash should emit dash_triggered signal with direction.
	_signal_received = false
	_received_direction = Vector3.ZERO

	camera.dash_triggered.connect(_on_dash_triggered)

	camera._trigger_dash(KEY_W)

	assert_bool(_signal_received).is_true()
	assert_bool(_received_direction != Vector3.ZERO).is_true()

	# Clean up connection
	camera.dash_triggered.disconnect(_on_dash_triggered)


func test_dash_moves_further_than_normal_movement() -> void:
	## Dash should move significantly further than normal WASD movement.
	## This verifies the DASH_DISTANCE_MULTIPLIER is effective.
	camera._target_target = Vector3.ZERO
	camera.distance = 100.0  # Fixed distance for consistent test

	# Simulate normal movement (one frame of holding W at default speed)
	var normal_speed: float = CameraScript.PAN_BASE_SPEED * (camera.distance / 100.0) * (1.0 / 60.0)

	# Dash distance
	camera._trigger_dash(KEY_W)
	var dash_distance: float = camera._target_target.length()

	# Dash should be at least 3x normal movement (DASH_DISTANCE_MULTIPLIER >= 5.0)
	assert_float(dash_distance).is_greater(normal_speed * 3.0)


func test_dash_respects_min_target_y() -> void:
	## Dash should not push target below MIN_TARGET_Y.
	camera._target_target = Vector3(0, -40, 0)
	# Dash shouldn't make Y go below the limit
	camera._trigger_dash(KEY_W)
	assert_float(camera._target_target.y).is_greater_equal(camera.MIN_TARGET_Y)


# === Constants ===

func test_double_tap_window_is_reasonable() -> void:
	## Double-tap window should be between 200-500ms for comfortable UX.
	assert_float(CameraScript.DOUBLE_TAP_WINDOW).is_between(0.2, 0.5)


func test_dash_multiplier_is_significant() -> void:
	## Dash should be noticeably faster than normal movement.
	assert_float(CameraScript.DASH_DISTANCE_MULTIPLIER).is_greater_equal(3.0)
