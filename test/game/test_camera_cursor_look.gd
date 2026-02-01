## GdUnit4 test suite for CameraCursorLook - mouse position-based camera orbit
class_name TestCameraCursorLook
extends GdUnitTestSuite

const CursorLookScript = preload("res://src/game/camera_cursor_look.gd")

const VIEWPORT_SIZE := Vector2(1920, 1080)
const CENTER := Vector2(960, 540)


func test_default_disabled() -> void:
	var cl := CursorLookScript.new()

	assert_bool(cl.is_enabled()).is_false()


func test_toggle() -> void:
	var cl := CursorLookScript.new()

	cl.toggle()
	assert_bool(cl.is_enabled()).is_true()

	cl.toggle()
	assert_bool(cl.is_enabled()).is_false()


func test_set_enabled() -> void:
	var cl := CursorLookScript.new()

	cl.set_enabled(true)

	assert_bool(cl.is_enabled()).is_true()


func test_toggle_emits_signal() -> void:
	var cl := CursorLookScript.new()
	var result := [null]  # Use array to capture in lambda
	cl.toggled.connect(func(v): result[0] = v)

	cl.toggle()

	assert_bool(result[0] == true).is_true()


func test_update_returns_zero_when_disabled() -> void:
	var cl := CursorLookScript.new()

	var delta := cl.update(0.016, Vector2(1000, 500), VIEWPORT_SIZE)

	assert_vector(delta).is_equal(Vector2.ZERO)


func test_update_returns_zero_at_center() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	var delta := cl.update(0.016, CENTER, VIEWPORT_SIZE)

	assert_vector(delta).is_equal(Vector2.ZERO)


func test_update_returns_positive_x_when_right() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	# Mouse at right edge
	var delta := cl.update(0.016, Vector2(1920, 540), VIEWPORT_SIZE)

	assert_float(delta.x).is_greater(0.0)


func test_update_returns_negative_x_when_left() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	# Mouse at left edge
	var delta := cl.update(0.016, Vector2(0, 540), VIEWPORT_SIZE)

	assert_float(delta.x).is_less(0.0)


func test_update_returns_positive_y_when_mouse_up() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	# Mouse at top edge (remember Y is inverted)
	var delta := cl.update(0.016, Vector2(960, 0), VIEWPORT_SIZE)

	assert_float(delta.y).is_greater(0.0)  # Should tilt camera up


func test_update_returns_negative_y_when_mouse_down() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	# Mouse at bottom edge
	var delta := cl.update(0.016, Vector2(960, 1080), VIEWPORT_SIZE)

	assert_float(delta.y).is_less(0.0)


func test_deadzone_prevents_small_movements() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)
	cl.deadzone = 0.2  # 20% deadzone

	# Mouse slightly off center (within deadzone)
	var mouse_pos := CENTER + Vector2(50, 30)  # Small offset
	var delta := cl.update(0.016, mouse_pos, VIEWPORT_SIZE)

	# Should be zero because within deadzone
	assert_vector(delta).is_equal(Vector2.ZERO)


func test_speed_multiplier_affects_output() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	var mouse_pos := Vector2(1500, 540)  # Right of center
	var delta_normal := cl.update(0.016, mouse_pos, VIEWPORT_SIZE, 1.0)
	var delta_fast := cl.update(0.016, mouse_pos, VIEWPORT_SIZE, 2.0)

	assert_float(delta_fast.x).is_equal_approx(delta_normal.x * 2.0, 0.001)


func test_handles_zero_viewport_size() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	var delta := cl.update(0.016, CENTER, Vector2.ZERO)

	assert_vector(delta).is_equal(Vector2.ZERO)


func test_corner_movement() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	# Mouse at top-right corner
	var delta := cl.update(0.016, Vector2(1920, 0), VIEWPORT_SIZE)

	# Should have both positive X (right) and positive Y (up)
	assert_float(delta.x).is_greater(0.0)
	assert_float(delta.y).is_greater(0.0)


func test_sensitivity_affects_output() -> void:
	var cl := CursorLookScript.new()
	cl.set_enabled(true)

	var mouse_pos := Vector2(1500, 540)

	cl.sensitivity = 0.1
	var delta_low := cl.update(0.016, mouse_pos, VIEWPORT_SIZE)

	cl.sensitivity = 0.3
	var delta_high := cl.update(0.016, mouse_pos, VIEWPORT_SIZE)

	assert_float(delta_high.x).is_greater(delta_low.x)
