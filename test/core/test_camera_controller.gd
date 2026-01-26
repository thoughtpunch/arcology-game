extends SceneTree
## Tests for CameraController - enhanced camera controls

var _camera_script: GDScript
var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== CameraController Tests ===")

	# Load the script dynamically
	_camera_script = load("res://src/core/camera_controller.gd") as GDScript
	if not _camera_script:
		print("ERROR: Could not load camera_controller.gd")
		quit()
		return

	# Setup tests
	_test_initialization()
	_test_default_values()

	# Zoom tests
	_test_zoom_within_bounds()
	_test_zoom_respects_min_limit()
	_test_zoom_respects_max_limit()
	_test_zoom_smooth_interpolation()

	# Pan tests
	_test_set_position()
	_test_smooth_position_movement()

	# Rotation tests
	_test_rotation_angles()
	_test_rotation_wraps_around()
	_test_rotation_counter_clockwise()

	# Double-click centering tests
	_test_center_on_world_position()

	# Drag state tests
	_test_drag_state()

	# Public API tests
	_test_snap_to_target()
	_test_get_current_zoom()

	# Signal tests
	_test_signals_exist()

	# Negative tests
	_test_invalid_rotation_index()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


func _create_controller() -> Node:
	return _camera_script.new()


func _test_initialization() -> void:
	var controller := _create_controller()
	assert(controller != null, "CameraController should instantiate")
	_pass("initialization")
	controller.free()


func _test_default_values() -> void:
	var controller := _create_controller()

	assert(controller._target_zoom == 1.0, "Default target zoom should be 1.0")
	assert(controller._target_position == Vector2.ZERO, "Default target position should be zero")
	assert(controller._target_rotation_index == 0, "Default rotation index should be 0")
	assert(controller._is_dragging == false, "Should not be dragging by default")

	_pass("default_values")
	controller.free()


func _test_zoom_within_bounds() -> void:
	var controller := _create_controller()

	controller.set_zoom(2.0)
	assert(controller.get_zoom() == 2.0, "Zoom should be set to 2.0")

	controller.set_zoom(0.5)
	assert(controller.get_zoom() == 0.5, "Zoom should be set to 0.5")

	_pass("zoom_within_bounds")
	controller.free()


func _test_zoom_respects_min_limit() -> void:
	var controller := _create_controller()
	var min_zoom: float = controller.MIN_ZOOM

	controller.set_zoom(0.1)  # Below MIN_ZOOM (0.25)
	assert(controller.get_zoom() == min_zoom, "Zoom should be clamped to MIN_ZOOM")

	controller.set_zoom(-1.0)
	assert(controller.get_zoom() == min_zoom, "Negative zoom should be clamped to MIN_ZOOM")

	_pass("zoom_respects_min_limit")
	controller.free()


func _test_zoom_respects_max_limit() -> void:
	var controller := _create_controller()
	var max_zoom: float = controller.MAX_ZOOM

	controller.set_zoom(10.0)  # Above MAX_ZOOM (4.0)
	assert(controller.get_zoom() == max_zoom, "Zoom should be clamped to MAX_ZOOM")

	controller.set_zoom(100.0)
	assert(controller.get_zoom() == max_zoom, "Very high zoom should be clamped to MAX_ZOOM")

	_pass("zoom_respects_max_limit")
	controller.free()


func _test_zoom_smooth_interpolation() -> void:
	var controller := _create_controller()
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0)
	controller.camera = camera
	controller._target_zoom = 2.0

	# Simulate a very small frame to ensure interpolation is visible
	controller._apply_smooth_movement(0.01)

	# Camera should move toward target
	assert(camera.zoom.x > 1.0, "Camera zoom should increase toward target")
	# With small delta, it should not have fully reached target
	assert(camera.zoom.x < 1.5, "Camera zoom should not jump significantly in small frame")

	_pass("zoom_smooth_interpolation")
	camera.free()
	controller.free()


func _test_set_position() -> void:
	var controller := _create_controller()

	var target := Vector2(100.0, 200.0)
	controller.set_position(target)

	assert(controller.get_position() == target, "Position should be set correctly")

	_pass("set_position")
	controller.free()


func _test_smooth_position_movement() -> void:
	var controller := _create_controller()
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	controller.camera = camera
	controller._target_position = Vector2(100.0, 100.0)

	# Simulate one frame of smoothing
	controller._apply_smooth_movement(0.1)

	# Camera should move toward target but not reach it instantly
	assert(camera.position.x > 0.0, "Camera X should move toward target")
	assert(camera.position.y > 0.0, "Camera Y should move toward target")
	assert(camera.position.x < 100.0, "Camera X should not jump instantly to target")
	assert(camera.position.y < 100.0, "Camera Y should not jump instantly to target")

	_pass("smooth_position_movement")
	camera.free()
	controller.free()


func _test_rotation_angles() -> void:
	var controller := _create_controller()
	var angles: Array = controller.ROTATION_ANGLES

	assert(angles.size() == 4, "Should have 4 rotation angles")
	assert(angles[0] == 0.0, "First angle should be 0")
	assert(angles[1] == 90.0, "Second angle should be 90")
	assert(angles[2] == 180.0, "Third angle should be 180")
	assert(angles[3] == 270.0, "Fourth angle should be 270")

	_pass("rotation_angles")
	controller.free()


func _test_rotation_wraps_around() -> void:
	var controller := _create_controller()

	# Start at index 3 (270 degrees), rotate clockwise
	controller._target_rotation_index = 3
	controller.rotate_camera(1)

	assert(controller._target_rotation_index == 0, "Rotation should wrap from 3 to 0")
	assert(controller.get_rotation_angle() == 0.0, "Angle should be 0 after wrap")

	_pass("rotation_wraps_around")
	controller.free()


func _test_rotation_counter_clockwise() -> void:
	var controller := _create_controller()

	# Start at index 0 (0 degrees), rotate counter-clockwise
	controller._target_rotation_index = 0
	controller.rotate_camera(-1)

	assert(controller._target_rotation_index == 3, "Rotation should wrap from 0 to 3")
	assert(controller.get_rotation_angle() == 270.0, "Angle should be 270 after CCW rotation")

	_pass("rotation_counter_clockwise")
	controller.free()


func _test_center_on_world_position() -> void:
	var controller := _create_controller()

	var target := Vector2(500.0, -300.0)
	controller.center_on_world_position(target)

	assert(controller.get_position() == target, "Target position should be set to center point")

	_pass("center_on_world_position")
	controller.free()


func _test_drag_state() -> void:
	var controller := _create_controller()

	assert(controller.is_dragging() == false, "Should not be dragging initially")

	controller._start_drag(Vector2(100, 100))
	assert(controller.is_dragging() == true, "Should be dragging after start_drag")
	assert(controller._drag_start_mouse == Vector2(100, 100), "Drag start mouse should be recorded")

	controller._end_drag()
	assert(controller.is_dragging() == false, "Should not be dragging after end_drag")

	_pass("drag_state")
	controller.free()


func _test_snap_to_target() -> void:
	var controller := _create_controller()
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.0, 1.0)
	camera.rotation_degrees = 0.0
	controller.camera = camera

	controller._target_position = Vector2(500.0, 300.0)
	controller._target_zoom = 2.5
	controller._target_rotation_index = 2  # 180 degrees

	controller.snap_to_target()

	assert(camera.position == Vector2(500.0, 300.0), "Camera position should snap immediately")
	assert(camera.zoom == Vector2(2.5, 2.5), "Camera zoom should snap immediately")
	assert(camera.rotation_degrees == 180.0, "Camera rotation should snap immediately")

	_pass("snap_to_target")
	camera.free()
	controller.free()


func _test_get_current_zoom() -> void:
	var controller := _create_controller()
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.5, 1.5)
	controller.camera = camera

	assert(controller.get_current_zoom() == 1.5, "get_current_zoom should return camera's actual zoom")

	# Without camera, should return target zoom
	controller.camera = null
	controller._target_zoom = 2.0
	assert(controller.get_current_zoom() == 2.0, "Without camera, should return target zoom")

	_pass("get_current_zoom")
	camera.free()
	controller.free()


func _test_signals_exist() -> void:
	var controller := _create_controller()

	assert(controller.has_signal("camera_moved"), "Should have camera_moved signal")
	assert(controller.has_signal("camera_zoomed"), "Should have camera_zoomed signal")
	assert(controller.has_signal("camera_rotated"), "Should have camera_rotated signal")

	_pass("signals_exist")
	controller.free()


# Negative tests

func _test_invalid_rotation_index() -> void:
	var controller := _create_controller()

	controller.set_rotation_index(-1)
	assert(controller.get_rotation_index() == 0, "Negative index should be clamped to 0")

	controller.set_rotation_index(10)
	assert(controller.get_rotation_index() == 3, "Index > max should be clamped to max")

	_pass("invalid_rotation_index")
	controller.free()


func _pass(test_name: String) -> void:
	print("  ✓ %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, message: String) -> void:
	print("  ✗ %s: %s" % [test_name, message])
	_tests_failed += 1
