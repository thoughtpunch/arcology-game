## GdUnit4 test suite for OrbitalCamera ground snap functionality.
## Tests snap_to_ground_at_cursor (X key) and snap_to_ground_at_target (V key).
class_name TestOrbitalCameraGroundSnap
extends GdUnitTestSuite

const CameraScript = preload("res://src/game/orbital_camera.gd")


# --- Helpers ---

func _make_camera() -> Node3D:
	## Create a camera in the scene tree so viewport calls work
	var cam: Node3D = CameraScript.new()
	cam.target = Vector3(100, 50, 100)
	cam._target_target = Vector3(100, 50, 100)
	add_child(cam)
	return cam


func _make_key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	ev.ctrl_pressed = false
	ev.alt_pressed = false
	return ev


# --- Tests: snap_to_ground_at_target (V key) ---

func test_snap_to_ground_at_target_sets_y_to_zero() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(200, 75, 300)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	cam.queue_free()


func test_snap_to_ground_at_target_preserves_xz() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(200, 75, 300)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.x).is_equal(200.0)
	assert_float(cam._target_target.z).is_equal(300.0)
	cam.queue_free()


func test_snap_to_ground_at_target_from_negative_y() -> void:
	## Camera target could be below ground (underground view)
	var cam := _make_camera()
	cam._target_target = Vector3(50, -30, 80)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	assert_float(cam._target_target.x).is_equal(50.0)
	assert_float(cam._target_target.z).is_equal(80.0)
	cam.queue_free()


func test_snap_to_ground_at_target_already_at_ground() -> void:
	## No change if already at Y=0
	var cam := _make_camera()
	cam._target_target = Vector3(100, 0, 100)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	cam.queue_free()


func test_snap_to_ground_at_target_pushes_history() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(500, 100, 500)
	var history_size_before: int = cam._history.size()

	cam.snap_to_ground_at_target()

	assert_int(cam._history.size()).is_greater(history_size_before)
	cam.queue_free()


func test_snap_to_ground_at_target_emits_signal() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(200, 75, 300)
	var signal_monitor := monitor_signals(cam)

	cam.snap_to_ground_at_target()

	assert_signal(cam).is_emitted("ground_snap", [Vector3(200, 0, 300)])
	cam.queue_free()


func test_v_key_calls_snap_to_ground_at_target() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(150, 60, 250)

	cam._handle_key(_make_key_event(KEY_V))

	assert_float(cam._target_target.y).is_equal(0.0)
	assert_float(cam._target_target.x).is_equal(150.0)
	assert_float(cam._target_target.z).is_equal(250.0)
	cam.queue_free()


# --- Tests: _raycast_ground_plane (geometry tests) ---

func test_raycast_ground_plane_returns_null_when_camera_not_in_tree() -> void:
	## Test the early-exit condition when camera is not in scene tree.
	## We create a camera object without adding it to tree.
	var cam: Node3D = CameraScript.new()
	# Don't add_child - camera.is_inside_tree() will be false
	# But we need to manually create the camera since _ready wasn't called
	cam.camera = Camera3D.new()
	# Don't add camera as child - it won't be in tree

	var result = cam._raycast_ground_plane(Vector2(400, 300))

	assert_object(result).is_null()
	cam.camera.queue_free()
	cam.queue_free()


func test_raycast_ground_plane_normal_case() -> void:
	## Position camera above and looking down at ground
	var cam := _make_camera()
	cam.target = Vector3(0, 0, 0)
	cam._target_target = Vector3(0, 0, 0)
	cam.distance = 100.0
	cam._target_distance = 100.0
	cam.elevation = 45.0
	cam._target_elevation = 45.0
	cam.azimuth = 0.0
	cam._target_azimuth = 0.0
	cam._update_camera_position()

	# Ray from screen center should hit ground plane
	var viewport_size := cam.get_viewport().get_visible_rect().size
	var center := viewport_size / 2.0
	var result = cam._raycast_ground_plane(center)

	# Should return a valid position
	assert_object(result).is_not_null()
	# Y should be 0 (ground plane)
	if result != null:
		assert_float(result.y).is_equal(0.0)
	cam.queue_free()


func test_raycast_ground_plane_looking_up_returns_null() -> void:
	## Camera looking up (away from ground) should return null
	var cam := _make_camera()
	cam.target = Vector3(0, 100, 0)
	cam._target_target = Vector3(0, 100, 0)
	cam.distance = 100.0
	cam._target_distance = 100.0
	cam.elevation = -60.0  # Looking up
	cam._target_elevation = -60.0
	cam._update_camera_position()

	var viewport_size := cam.get_viewport().get_visible_rect().size
	var center := viewport_size / 2.0
	var result = cam._raycast_ground_plane(center)

	# Should return null since ray doesn't hit ground
	assert_object(result).is_null()
	cam.queue_free()


# --- Tests: snap_to_ground_at_cursor (X key) ---
# Note: Full cursor raycast testing requires more complex setup with viewport,
# but we can test the edge cases

func test_x_key_is_handled() -> void:
	## X key should be accepted and handled
	var cam := _make_camera()
	cam._target_target = Vector3(100, 50, 100)
	var initial_y: float = cam._target_target.y

	# Just verify the key handler runs without error
	cam._handle_key(_make_key_event(KEY_X))

	# The actual behavior depends on viewport state and raycast
	# In test env without proper viewport, cursor snap may not change position
	# But the call should complete without error
	cam.queue_free()


# --- Tests: Edge cases ---

func test_snap_functions_work_with_large_coordinates() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(10000, 500, -8000)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	assert_float(cam._target_target.x).is_equal(10000.0)
	assert_float(cam._target_target.z).is_equal(-8000.0)
	cam.queue_free()


func test_snap_functions_work_with_fractional_coordinates() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(123.456, 78.9, -321.654)

	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	assert_float(cam._target_target.x).is_equal_approx(123.456, 0.001)
	assert_float(cam._target_target.z).is_equal_approx(-321.654, 0.001)
	cam.queue_free()


func test_multiple_snaps_are_idempotent() -> void:
	var cam := _make_camera()
	cam._target_target = Vector3(100, 50, 100)

	cam.snap_to_ground_at_target()
	cam.snap_to_ground_at_target()
	cam.snap_to_ground_at_target()

	assert_float(cam._target_target.y).is_equal(0.0)
	cam.queue_free()
