## GdUnit4 test suite for CameraInertia - camera orbit momentum
class_name TestCameraInertia
extends GdUnitTestSuite

const InertiaScript = preload("res://src/game/camera_inertia.gd")


func test_default_enabled() -> void:
	var inertia := InertiaScript.new()

	assert_bool(inertia.is_enabled()).is_true()


func test_set_enabled() -> void:
	var inertia := InertiaScript.new()

	inertia.set_enabled(false)

	assert_bool(inertia.is_enabled()).is_false()


func test_toggle_emits_signal() -> void:
	var inertia := InertiaScript.new()
	var result := [null]  # Use array to capture in lambda
	inertia.toggled.connect(func(v): result[0] = v)

	inertia.set_enabled(false)

	assert_bool(result[0] == false).is_true()


func test_record_and_start_creates_velocity() -> void:
	var inertia := InertiaScript.new()

	inertia.record_velocity(1.0, 0.5)
	inertia.record_velocity(1.0, 0.5)
	inertia.start()

	assert_bool(inertia.is_active()).is_true()
	assert_float(inertia.get_velocity().length()).is_greater(0.0)


func test_update_returns_delta_angles() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(1.0, 0.0)
	inertia.start()

	var delta_angles := inertia.update(0.016)  # ~60fps

	assert_float(delta_angles.x).is_greater(0.0)


func test_velocity_decays_over_time() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(5.0, 0.0)
	inertia.start()
	var initial_vel := inertia.get_velocity().length()

	inertia.update(0.5)  # Half second

	assert_float(inertia.get_velocity().length()).is_less(initial_vel)


func test_velocity_stops_when_below_threshold() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(0.001, 0.0)  # Very small
	inertia.start()

	# After starting with tiny velocity, should stop quickly
	inertia.update(1.0)

	assert_bool(inertia.is_active()).is_false()


func test_stop_clears_velocity() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(5.0, 5.0)
	inertia.start()

	inertia.stop()

	assert_bool(inertia.is_active()).is_false()
	assert_vector(inertia.get_velocity()).is_equal(Vector2.ZERO)


func test_disabled_returns_zero() -> void:
	var inertia := InertiaScript.new()
	inertia.set_enabled(false)
	inertia.record_velocity(5.0, 5.0)
	inertia.start()

	var delta := inertia.update(0.016)

	assert_vector(delta).is_equal(Vector2.ZERO)


func test_record_disabled_does_nothing() -> void:
	var inertia := InertiaScript.new()
	inertia.set_enabled(false)

	inertia.record_velocity(10.0, 10.0)
	inertia.set_enabled(true)  # Re-enable
	inertia.start()

	assert_bool(inertia.is_active()).is_false()


func test_samples_are_averaged() -> void:
	var inertia := InertiaScript.new()

	# Record different velocities
	inertia.record_velocity(10.0, 0.0)
	inertia.record_velocity(20.0, 0.0)
	inertia.record_velocity(30.0, 0.0)
	inertia.start()

	# Should be around 20 * scale
	var vel := inertia.get_velocity()
	assert_float(vel.x).is_equal_approx(20.0 * inertia.velocity_scale, 1.0)


func test_clear_samples() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(10.0, 10.0)

	inertia.clear_samples()
	inertia.start()

	assert_bool(inertia.is_active()).is_false()


func test_disabling_stops_inertia() -> void:
	var inertia := InertiaScript.new()
	inertia.record_velocity(10.0, 10.0)
	inertia.start()
	assert_bool(inertia.is_active()).is_true()

	inertia.set_enabled(false)

	assert_bool(inertia.is_active()).is_false()


func test_sample_count_limits() -> void:
	var inertia := InertiaScript.new()

	# Record many samples - only last SAMPLE_COUNT should be kept
	for i in range(10):
		inertia.record_velocity(float(i), 0.0)

	inertia.start()

	# Should average the last 3 samples (7, 8, 9)
	var expected := ((7.0 + 8.0 + 9.0) / 3.0) * inertia.velocity_scale
	assert_float(inertia.get_velocity().x).is_equal_approx(expected, 1.0)
