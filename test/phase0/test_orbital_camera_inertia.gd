## GdUnit4 test suite for OrbitalCamera inertia/momentum system.
## Tests velocity tracking during orbit, momentum decay after release,
## enable/disable toggle, and velocity thresholds.
class_name TestOrbitalCameraInertia
extends GdUnitTestSuite

const CameraScript = preload("res://src/game/orbital_camera.gd")


# --- Helpers ---

func _make_camera() -> Node3D:
	## Create a camera in the scene tree so viewport calls work
	var cam: Node3D = CameraScript.new()
	cam.target = Vector3(0, 0, 0)
	cam._target_target = Vector3(0, 0, 0)
	add_child(cam)
	return cam


func _simulate_orbit_drag(cam: Node3D, deltas: Array[Vector2]) -> void:
	## Simulate an orbit drag with given mouse deltas
	# Start drag
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_RIGHT
	press_event.pressed = true
	press_event.position = Vector2(100, 100)
	cam._handle_mouse_button(press_event)

	# Move past threshold to activate drag
	var base_pos := Vector2(100, 100)
	var motion := InputEventMouseMotion.new()
	motion.position = base_pos + Vector2(10, 0)  # Past DRAG_THRESHOLD
	cam._last_mouse_pos = base_pos
	cam._handle_mouse_motion(motion)

	# Apply deltas
	for delta in deltas:
		var prev_pos := motion.position
		motion = InputEventMouseMotion.new()
		motion.position = prev_pos + delta
		cam._last_mouse_pos = prev_pos
		cam._handle_mouse_motion(motion)

	# Release
	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_RIGHT
	release_event.pressed = false
	release_event.position = motion.position
	cam._handle_mouse_button(release_event)


# --- Tests: Initial state ---

func test_inertia_enabled_by_default() -> void:
	var cam := _make_camera()
	assert_bool(cam.inertia_enabled).is_true()
	assert_bool(cam.is_inertia_enabled()).is_true()
	cam.queue_free()


func test_initial_inertia_velocity_is_zero() -> void:
	var cam := _make_camera()
	assert_vector(cam.get_inertia_velocity()).is_equal(Vector2.ZERO)
	cam.queue_free()


# --- Tests: Enable/disable toggle ---

func test_set_inertia_enabled_false_disables() -> void:
	var cam := _make_camera()
	cam.set_inertia_enabled(false)
	assert_bool(cam.inertia_enabled).is_false()
	assert_bool(cam.is_inertia_enabled()).is_false()
	cam.queue_free()


func test_set_inertia_enabled_true_enables() -> void:
	var cam := _make_camera()
	cam.set_inertia_enabled(false)
	cam.set_inertia_enabled(true)
	assert_bool(cam.inertia_enabled).is_true()
	cam.queue_free()


func test_disabling_inertia_clears_velocity() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(50, 30)
	cam.set_inertia_enabled(false)
	assert_vector(cam.get_inertia_velocity()).is_equal(Vector2.ZERO)
	cam.queue_free()


func test_disabling_inertia_clears_velocity_samples() -> void:
	var cam := _make_camera()
	cam._orbit_velocity_samples.append(Vector2(10, 5))
	cam._orbit_velocity_samples.append(Vector2(20, 10))
	cam.set_inertia_enabled(false)
	assert_int(cam._orbit_velocity_samples.size()).is_equal(0)
	cam.queue_free()


func test_inertia_toggled_signal_emitted() -> void:
	var cam := _make_camera()
	var signal_monitor := monitor_signals(cam)
	cam.set_inertia_enabled(false)
	assert_signal(cam).is_emitted("inertia_toggled", [false])
	cam.queue_free()


func test_inertia_toggled_signal_not_emitted_if_same_state() -> void:
	var cam := _make_camera()
	var signal_monitor := monitor_signals(cam)
	cam.set_inertia_enabled(true)  # Already true
	assert_signal(cam).is_not_emitted("inertia_toggled")
	cam.queue_free()


# --- Tests: stop_inertia API ---

func test_stop_inertia_clears_velocity() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)
	cam.stop_inertia()
	assert_vector(cam.get_inertia_velocity()).is_equal(Vector2.ZERO)
	cam.queue_free()


# --- Tests: Velocity tracking during orbit drag ---

func test_orbit_drag_accumulates_velocity_samples() -> void:
	var cam := _make_camera()
	# Manually set up for testing
	cam._right_pressed = true
	cam._right_drag_active = true
	cam._orbit_velocity_samples.clear()
	cam._last_mouse_pos = Vector2(100, 100)

	# Simulate motion
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(110, 100)  # 10px right
	cam._handle_mouse_motion(motion)

	assert_int(cam._orbit_velocity_samples.size()).is_equal(1)
	# Velocity should be positive for rightward movement (increases azimuth)
	assert_float(cam._orbit_velocity_samples[0].x).is_greater(0.0)

	cam._right_pressed = false
	cam._right_drag_active = false
	cam.queue_free()


func test_velocity_samples_limited_to_max_count() -> void:
	var cam := _make_camera()
	cam._right_pressed = true
	cam._right_drag_active = true
	cam._orbit_velocity_samples.clear()
	cam._last_mouse_pos = Vector2(100, 100)

	# Add more samples than the limit
	for i in range(10):
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(100 + i * 5, 100)
		cam._handle_mouse_motion(motion)
		cam._last_mouse_pos = motion.position

	assert_int(cam._orbit_velocity_samples.size()).is_equal(cam.VELOCITY_SAMPLE_COUNT)

	cam._right_pressed = false
	cam._right_drag_active = false
	cam.queue_free()


func test_orbit_drag_samples_cleared_on_press() -> void:
	var cam := _make_camera()
	cam._orbit_velocity_samples.append(Vector2(50, 30))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(100, 100)
	cam._handle_mouse_button(press)

	assert_int(cam._orbit_velocity_samples.size()).is_equal(0)

	cam._right_pressed = false
	cam.queue_free()


# --- Tests: Inertia start on release ---

func test_start_orbit_inertia_averages_samples() -> void:
	var cam := _make_camera()
	cam._orbit_velocity_samples.clear()
	cam._orbit_velocity_samples.append(Vector2(60, 30))
	cam._orbit_velocity_samples.append(Vector2(80, 50))
	cam._orbit_velocity_samples.append(Vector2(100, 40))

	cam._start_orbit_inertia()

	# Average: (60+80+100)/3 = 80, (30+50+40)/3 = 40
	assert_float(cam._inertia_velocity.x).is_equal(80.0)
	assert_float(cam._inertia_velocity.y).is_equal(40.0)
	cam.queue_free()


func test_start_orbit_inertia_clears_samples() -> void:
	var cam := _make_camera()
	cam._orbit_velocity_samples.append(Vector2(60, 30))
	cam._start_orbit_inertia()
	assert_int(cam._orbit_velocity_samples.size()).is_equal(0)
	cam.queue_free()


func test_start_orbit_inertia_with_disabled_sets_zero() -> void:
	var cam := _make_camera()
	cam.inertia_enabled = false
	cam._orbit_velocity_samples.append(Vector2(100, 50))

	cam._start_orbit_inertia()

	assert_vector(cam._inertia_velocity).is_equal(Vector2.ZERO)
	cam.queue_free()


func test_start_orbit_inertia_with_empty_samples_sets_zero() -> void:
	var cam := _make_camera()
	cam._orbit_velocity_samples.clear()
	cam._inertia_velocity = Vector2(50, 25)  # Pre-existing velocity

	cam._start_orbit_inertia()

	assert_vector(cam._inertia_velocity).is_equal(Vector2.ZERO)
	cam.queue_free()


# --- Tests: Inertia application in _apply_inertia ---

func test_apply_inertia_changes_target_angles() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(60, 30)  # degrees/sec
	cam._target_azimuth = 45.0
	cam._target_elevation = 20.0

	cam._apply_inertia(0.1)  # 100ms delta

	# Should have added some rotation
	assert_float(cam._target_azimuth).is_greater(45.0)
	assert_float(cam._target_elevation).is_greater(20.0)
	cam.queue_free()


func test_apply_inertia_decays_velocity() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)
	var initial_vel: float = cam._inertia_velocity.length()

	cam._apply_inertia(0.1)

	assert_float(cam._inertia_velocity.length()).is_less(initial_vel)
	cam.queue_free()


func test_apply_inertia_clamps_elevation() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(0, 1000)  # Very high upward velocity
	cam._target_elevation = 85.0  # Near max

	cam._apply_inertia(0.1)

	# Should be clamped to MAX_ELEVATION (89)
	assert_float(cam._target_elevation).is_less_equal(89.0)
	cam.queue_free()


func test_apply_inertia_does_nothing_when_disabled() -> void:
	var cam := _make_camera()
	cam.inertia_enabled = false
	cam._inertia_velocity = Vector2(100, 50)
	cam._target_azimuth = 45.0

	cam._apply_inertia(0.1)

	assert_float(cam._target_azimuth).is_equal(45.0)
	cam.queue_free()


func test_apply_inertia_does_nothing_during_orbit_drag() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)
	cam._target_azimuth = 45.0
	cam._right_drag_active = true

	cam._apply_inertia(0.1)

	assert_float(cam._target_azimuth).is_equal(45.0)

	cam._right_drag_active = false
	cam.queue_free()


func test_apply_inertia_does_nothing_during_alt_orbit() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)
	cam._target_azimuth = 45.0
	cam._alt_orbit_active = true

	cam._apply_inertia(0.1)

	assert_float(cam._target_azimuth).is_equal(45.0)

	cam._alt_orbit_active = false
	cam.queue_free()


func test_apply_inertia_stops_below_threshold() -> void:
	var cam := _make_camera()
	# Velocity below INERTIA_MIN_VELOCITY (0.5)
	cam._inertia_velocity = Vector2(0.3, 0.2)
	cam._target_azimuth = 45.0

	cam._apply_inertia(0.1)

	# Velocity should be zeroed, no change to azimuth
	assert_vector(cam._inertia_velocity).is_equal(Vector2.ZERO)
	assert_float(cam._target_azimuth).is_equal(45.0)
	cam.queue_free()


# --- Tests: Integration - full drag-to-inertia cycle ---

func test_full_orbit_drag_sets_inertia_on_release() -> void:
	var cam := _make_camera()
	cam._target_azimuth = 45.0
	cam._target_elevation = 30.0

	# Simulate drag start
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(100, 100)
	cam._handle_mouse_button(press)
	cam._last_mouse_pos = Vector2(100, 100)

	# Move past threshold and continue moving
	for i in range(5):
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(100 + (i + 1) * 10, 100)  # Moving right
		cam._handle_mouse_motion(motion)
		cam._last_mouse_pos = motion.position

	assert_bool(cam._right_drag_active).is_true()
	assert_int(cam._orbit_velocity_samples.size()).is_greater(0)

	# Release
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = cam._last_mouse_pos
	cam._handle_mouse_button(release)

	# Inertia should be set (positive X for rightward movement)
	assert_float(cam._inertia_velocity.x).is_greater(0.0)
	cam.queue_free()


func test_inertia_decays_over_multiple_frames() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)
	var initial_vel: float = cam._inertia_velocity.length()

	var prev_vel: float = initial_vel
	for i in range(10):
		cam._apply_inertia(0.016)  # ~60fps
		assert_float(cam._inertia_velocity.length()).is_less(prev_vel)
		prev_vel = cam._inertia_velocity.length()

	# After 10 frames at 60fps (160ms), velocity should be significantly reduced
	# With decay rate 4.0: e^(-4.0 * 0.16) ≈ 0.53, so ~53% of initial
	assert_float(cam._inertia_velocity.length()).is_less(initial_vel * 0.6)
	cam.queue_free()


func test_new_drag_cancels_inertia() -> void:
	var cam := _make_camera()
	cam._inertia_velocity = Vector2(100, 50)

	# Start new drag
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(100, 100)
	cam._handle_mouse_button(press)

	# Move to activate drag
	cam._last_mouse_pos = Vector2(100, 100)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(110, 100)
	cam._handle_mouse_motion(motion)

	# Inertia should not apply during drag
	cam._apply_inertia(0.1)
	# The target angles shouldn't change from inertia during active drag
	# (they change from the drag itself, but not from _apply_inertia)

	cam._right_pressed = false
	cam._right_drag_active = false
	cam.queue_free()
