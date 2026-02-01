extends SceneTree
## Tests for ViewCube widget — view_cube.gd
## Task: arcology-ha9

var _tests_passed := 0
var _tests_failed := 0

var _view_cube_script: GDScript
var _camera_script: GDScript


func _init() -> void:
	print("=== ViewCube Tests (arcology-ha9) ===")

	_view_cube_script = load("res://src/ui/view_cube.gd") as GDScript
	_camera_script = load("res://src/game/orbital_camera.gd") as GDScript

	if not _view_cube_script:
		print("ERROR: Could not load view_cube.gd")
		quit()
		return
	if not _camera_script:
		print("ERROR: Could not load orbital_camera.gd")
		quit()
		return

	print("\n--- Positive Assertions ---")

	# Construction tests
	_test_view_cube_creates_successfully()
	_test_sub_viewport_exists()
	_test_cube_root_exists()
	_test_face_materials_created()
	_test_face_labels_created()

	# Hit zone angles setup
	_test_hit_zone_angles_populated()
	_test_face_angles_correct()
	_test_edge_angles_correct()
	_test_corner_angles_correct()

	# Hit classification tests
	_test_classify_hit_point_top_face()
	_test_classify_hit_point_bottom_face()
	_test_classify_hit_point_front_face()
	_test_classify_hit_point_right_face()
	_test_classify_hit_point_edge()
	_test_classify_hit_point_corner()

	# Face zone mapping
	_test_get_face_zone_x_positive()
	_test_get_face_zone_x_negative()
	_test_get_face_zone_y_positive()
	_test_get_face_zone_y_negative()
	_test_get_face_zone_z_positive()
	_test_get_face_zone_z_negative()

	# Edge lookup
	_test_edge_from_faces_top_front()
	_test_edge_from_faces_bottom_right()
	_test_edge_from_faces_order_independent()

	# Hover highlight
	_test_faces_for_face_zone()
	_test_faces_for_edge_zone()
	_test_faces_for_corner_zone()

	# Camera connection
	_test_connect_to_camera()

	# Ray-AABB intersection
	_test_ray_aabb_hit_from_front()
	_test_ray_aabb_miss()

	print("\n--- Negative Assertions ---")

	# No camera connected
	_test_process_without_camera_no_crash()
	_test_view_snap_without_camera_no_crash()
	_test_drag_rotate_without_camera_no_crash()

	# Invalid hit zones
	_test_classify_interior_point_returns_none()
	_test_get_faces_for_none_zone()

	# Ray miss
	_test_ray_aabb_behind_camera()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


# === Helpers ===

func _create_view_cube() -> Control:
	var vc = _view_cube_script.new()
	vc.initialize()
	return vc


func _create_camera() -> Node3D:
	return _camera_script.new()


func _pass(test_name: String) -> void:
	print("  PASS %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, message: String) -> void:
	print("  FAIL %s: %s" % [test_name, message])
	_tests_failed += 1


# === Positive Tests: Construction ===

func _test_view_cube_creates_successfully() -> void:
	var vc := _create_view_cube()
	if vc != null:
		_pass("view_cube_creates_successfully")
	else:
		_fail("view_cube_creates_successfully", "ViewCube instance is null")
	if vc and is_instance_valid(vc):
		vc.queue_free()


func _test_sub_viewport_exists() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Give it a frame to run _ready
	var vp = vc.get_sub_viewport()
	if vp != null and vp is SubViewport:
		_pass("sub_viewport_exists")
	else:
		_fail("sub_viewport_exists", "SubViewport not found")
	vc.queue_free()


func _test_cube_root_exists() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var cube_root = vc.get_cube_root()
	if cube_root != null and cube_root is Node3D:
		_pass("cube_root_exists")
	else:
		_fail("cube_root_exists", "CubeRoot not found")
	vc.queue_free()


func _test_face_materials_created() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# There should be 6 face materials (one per face)
	var count: int = vc._face_materials.size()
	if count == 6:
		_pass("face_materials_created (6 faces)")
	else:
		_fail("face_materials_created", "Expected 6, got %d" % count)
	vc.queue_free()


func _test_face_labels_created() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Labels: TOP, BOT, S, N, E, W
	var count: int = vc._face_labels.size()
	if count == 6:
		_pass("face_labels_created (6 labels)")
	else:
		_fail("face_labels_created", "Expected 6, got %d" % count)
	vc.queue_free()


# === Positive Tests: Hit Zone Angles ===

func _test_hit_zone_angles_populated() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Should have entries for 6 faces + 12 edges + 8 corners = 26 zones
	var count: int = vc._hit_zone_angles.size()
	if count == 26:
		_pass("hit_zone_angles_populated (26 zones)")
	else:
		_fail("hit_zone_angles_populated", "Expected 26, got %d" % count)
	vc.queue_free()


func _test_face_angles_correct() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var top: Vector2 = vc._hit_zone_angles[HZ.FACE_TOP]
	var front: Vector2 = vc._hit_zone_angles[HZ.FACE_FRONT]
	var right: Vector2 = vc._hit_zone_angles[HZ.FACE_RIGHT]

	if absf(top.y - 89.0) < 0.01 and absf(front.x) < 0.01 and absf(front.y) < 0.01 and absf(right.x - 90.0) < 0.01:
		_pass("face_angles_correct")
	else:
		_fail("face_angles_correct", "TOP=(%s), FRONT=(%s), RIGHT=(%s)" % [top, front, right])
	vc.queue_free()


func _test_edge_angles_correct() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var edge_tf: Vector2 = vc._hit_zone_angles[HZ.EDGE_TOP_FRONT]
	# Top-Front edge should be az=0, el=45
	if absf(edge_tf.x) < 0.01 and absf(edge_tf.y - 45.0) < 0.01:
		_pass("edge_angles_correct")
	else:
		_fail("edge_angles_correct", "TOP_FRONT=(%s), expected (0, 45)" % edge_tf)
	vc.queue_free()


func _test_corner_angles_correct() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var corner: Vector2 = vc._hit_zone_angles[HZ.CORNER_TOP_FRONT_RIGHT]
	# Isometric: az=45, el~35.264
	if absf(corner.x - 45.0) < 0.01 and absf(corner.y - 35.264) < 0.01:
		_pass("corner_angles_correct")
	else:
		_fail("corner_angles_correct", "TOP_FRONT_RIGHT=(%s), expected (45, 35.264)" % corner)
	vc.queue_free()


# === Positive Tests: Hit Classification ===

func _test_classify_hit_point_top_face() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	# Point on top face center: y = CUBE_HALF, x and z near 0
	var point := Vector3(0.0, vc.CUBE_HALF, 0.0)
	var zone: int = vc._classify_hit_point(point, vc.CUBE_HALF)
	if zone == HZ.FACE_TOP:
		_pass("classify_hit_point_top_face")
	else:
		_fail("classify_hit_point_top_face", "Expected FACE_TOP (%d), got %d" % [HZ.FACE_TOP, zone])
	vc.queue_free()


func _test_classify_hit_point_bottom_face() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var point := Vector3(0.0, -vc.CUBE_HALF, 0.0)
	var zone: int = vc._classify_hit_point(point, vc.CUBE_HALF)
	if zone == HZ.FACE_BOTTOM:
		_pass("classify_hit_point_bottom_face")
	else:
		_fail("classify_hit_point_bottom_face", "Expected FACE_BOTTOM (%d), got %d" % [HZ.FACE_BOTTOM, zone])
	vc.queue_free()


func _test_classify_hit_point_front_face() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	# Front face: z = +CUBE_HALF, x and y near center
	var point := Vector3(0.0, 0.0, vc.CUBE_HALF)
	var zone: int = vc._classify_hit_point(point, vc.CUBE_HALF)
	if zone == HZ.FACE_FRONT:
		_pass("classify_hit_point_front_face")
	else:
		_fail("classify_hit_point_front_face", "Expected FACE_FRONT (%d), got %d" % [HZ.FACE_FRONT, zone])
	vc.queue_free()


func _test_classify_hit_point_right_face() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var point := Vector3(vc.CUBE_HALF, 0.0, 0.0)
	var zone: int = vc._classify_hit_point(point, vc.CUBE_HALF)
	if zone == HZ.FACE_RIGHT:
		_pass("classify_hit_point_right_face")
	else:
		_fail("classify_hit_point_right_face", "Expected FACE_RIGHT (%d), got %d" % [HZ.FACE_RIGHT, zone])
	vc.queue_free()


func _test_classify_hit_point_edge() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var h: float = vc.CUBE_HALF
	# Point on top face but near the front edge: y=CUBE_HALF, z near CUBE_HALF
	var point := Vector3(0.0, h, h * 0.85)
	var zone: int = vc._classify_hit_point(point, h)
	if zone == HZ.EDGE_TOP_FRONT:
		_pass("classify_hit_point_edge (top-front)")
	else:
		_fail("classify_hit_point_edge", "Expected EDGE_TOP_FRONT (%d), got %d" % [HZ.EDGE_TOP_FRONT, zone])
	vc.queue_free()


func _test_classify_hit_point_corner() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var h: float = vc.CUBE_HALF
	# Point on top face, near front-right corner
	var point := Vector3(h * 0.85, h, h * 0.85)
	var zone: int = vc._classify_hit_point(point, h)
	if zone == HZ.CORNER_TOP_FRONT_RIGHT:
		_pass("classify_hit_point_corner (top-front-right)")
	else:
		_fail("classify_hit_point_corner", "Expected CORNER_TOP_FRONT_RIGHT (%d), got %d" % [HZ.CORNER_TOP_FRONT_RIGHT, zone])
	vc.queue_free()


# === Positive Tests: Face Zone Mapping ===

func _test_get_face_zone_x_positive() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(0, 1.0)  # X+
	if zone == vc.HitZone.FACE_RIGHT:
		_pass("get_face_zone_x_positive -> FACE_RIGHT")
	else:
		_fail("get_face_zone_x_positive", "Expected FACE_RIGHT, got %d" % zone)
	vc.queue_free()


func _test_get_face_zone_x_negative() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(0, -1.0)  # X-
	if zone == vc.HitZone.FACE_LEFT:
		_pass("get_face_zone_x_negative -> FACE_LEFT")
	else:
		_fail("get_face_zone_x_negative", "Expected FACE_LEFT, got %d" % zone)
	vc.queue_free()


func _test_get_face_zone_y_positive() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(1, 1.0)  # Y+
	if zone == vc.HitZone.FACE_TOP:
		_pass("get_face_zone_y_positive -> FACE_TOP")
	else:
		_fail("get_face_zone_y_positive", "Expected FACE_TOP, got %d" % zone)
	vc.queue_free()


func _test_get_face_zone_y_negative() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(1, -1.0)  # Y-
	if zone == vc.HitZone.FACE_BOTTOM:
		_pass("get_face_zone_y_negative -> FACE_BOTTOM")
	else:
		_fail("get_face_zone_y_negative", "Expected FACE_BOTTOM, got %d" % zone)
	vc.queue_free()


func _test_get_face_zone_z_positive() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(2, 1.0)  # Z+
	if zone == vc.HitZone.FACE_FRONT:
		_pass("get_face_zone_z_positive -> FACE_FRONT")
	else:
		_fail("get_face_zone_z_positive", "Expected FACE_FRONT, got %d" % zone)
	vc.queue_free()


func _test_get_face_zone_z_negative() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var zone: int = vc._get_face_zone(2, -1.0)  # Z-
	if zone == vc.HitZone.FACE_BACK:
		_pass("get_face_zone_z_negative -> FACE_BACK")
	else:
		_fail("get_face_zone_z_negative", "Expected FACE_BACK, got %d" % zone)
	vc.queue_free()


# === Positive Tests: Edge Lookup ===

func _test_edge_from_faces_top_front() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var edge: int = vc._edge_from_faces(HZ.FACE_TOP, HZ.FACE_FRONT)
	if edge == HZ.EDGE_TOP_FRONT:
		_pass("edge_from_faces_top_front")
	else:
		_fail("edge_from_faces_top_front", "Expected EDGE_TOP_FRONT, got %d" % edge)
	vc.queue_free()


func _test_edge_from_faces_bottom_right() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var edge: int = vc._edge_from_faces(HZ.FACE_BOTTOM, HZ.FACE_RIGHT)
	if edge == HZ.EDGE_BOTTOM_RIGHT:
		_pass("edge_from_faces_bottom_right")
	else:
		_fail("edge_from_faces_bottom_right", "Expected EDGE_BOTTOM_RIGHT, got %d" % edge)
	vc.queue_free()


func _test_edge_from_faces_order_independent() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var edge_ab: int = vc._edge_from_faces(HZ.FACE_FRONT, HZ.FACE_LEFT)
	var edge_ba: int = vc._edge_from_faces(HZ.FACE_LEFT, HZ.FACE_FRONT)
	if edge_ab == edge_ba and edge_ab == HZ.EDGE_FRONT_LEFT:
		_pass("edge_from_faces_order_independent")
	else:
		_fail("edge_from_faces_order_independent", "AB=%d, BA=%d, expected EDGE_FRONT_LEFT=%d" % [edge_ab, edge_ba, HZ.EDGE_FRONT_LEFT])
	vc.queue_free()


# === Positive Tests: Hover Highlight ===

func _test_faces_for_face_zone() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var faces: Array[int] = vc._get_faces_for_zone(HZ.FACE_TOP)
	if faces.size() == 1 and faces[0] == HZ.FACE_TOP:
		_pass("faces_for_face_zone (single face)")
	else:
		_fail("faces_for_face_zone", "Expected [FACE_TOP], got %s" % str(faces))
	vc.queue_free()


func _test_faces_for_edge_zone() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var faces: Array[int] = vc._get_faces_for_zone(HZ.EDGE_TOP_RIGHT)
	if faces.size() == 2 and HZ.FACE_TOP in faces and HZ.FACE_RIGHT in faces:
		_pass("faces_for_edge_zone (two faces)")
	else:
		_fail("faces_for_edge_zone", "Expected [FACE_TOP, FACE_RIGHT], got %s" % str(faces))
	vc.queue_free()


func _test_faces_for_corner_zone() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var HZ = vc.HitZone
	var faces: Array[int] = vc._get_faces_for_zone(HZ.CORNER_TOP_FRONT_RIGHT)
	if faces.size() == 3 and HZ.FACE_TOP in faces and HZ.FACE_FRONT in faces and HZ.FACE_RIGHT in faces:
		_pass("faces_for_corner_zone (three faces)")
	else:
		_fail("faces_for_corner_zone", "Expected 3 faces, got %s" % str(faces))
	vc.queue_free()


# === Positive Tests: Camera Connection ===

func _test_connect_to_camera() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var cam := _create_camera()
	root.add_child(cam)

	vc.connect_to_camera(cam)
	if vc._main_camera == cam:
		_pass("connect_to_camera sets reference")
	else:
		_fail("connect_to_camera", "Camera reference not set")

	cam.queue_free()
	vc.queue_free()


# === Positive Tests: Ray-AABB ===

func _test_ray_aabb_hit_from_front() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Ray from z=5 toward origin should hit front face (z = +CUBE_HALF)
	var result: Dictionary = vc._ray_aabb_hit(
		Vector3(0, 0, 5),
		Vector3(0, 0, -1),
		vc.CUBE_HALF
	)
	if result.zone != vc.HitZone.NONE:
		_pass("ray_aabb_hit_from_front")
	else:
		_fail("ray_aabb_hit_from_front", "Expected hit, got NONE")
	vc.queue_free()


func _test_ray_aabb_miss() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Ray going sideways, missing the cube entirely
	var result: Dictionary = vc._ray_aabb_hit(
		Vector3(5, 5, 5),
		Vector3(1, 0, 0),  # Going away from cube
		vc.CUBE_HALF
	)
	if result.zone == vc.HitZone.NONE:
		_pass("ray_aabb_miss")
	else:
		_fail("ray_aabb_miss", "Expected NONE, got zone %d" % result.zone)
	vc.queue_free()


# === Negative Tests ===

func _test_process_without_camera_no_crash() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# _process should not crash when _main_camera is null
	vc._process(0.016)
	_pass("process_without_camera_no_crash")
	vc.queue_free()


func _test_view_snap_without_camera_no_crash() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Emitting view_snapped when no camera connected should not crash
	vc._on_view_snapped(45.0, 30.0)
	_pass("view_snap_without_camera_no_crash")
	vc.queue_free()


func _test_drag_rotate_without_camera_no_crash() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	vc._on_drag_rotate(10.0, 5.0)
	_pass("drag_rotate_without_camera_no_crash")
	vc.queue_free()


func _test_classify_interior_point_returns_none() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# A point well inside the cube (not on any face)
	var point := Vector3(0.0, 0.0, 0.0)
	var zone: int = vc._classify_hit_point(point, vc.CUBE_HALF)
	if zone == vc.HitZone.NONE:
		_pass("classify_interior_point_returns_none")
	else:
		_fail("classify_interior_point_returns_none", "Expected NONE, got %d" % zone)
	vc.queue_free()


func _test_get_faces_for_none_zone() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	var faces: Array[int] = vc._get_faces_for_zone(vc.HitZone.NONE)
	if faces.size() == 0:
		_pass("get_faces_for_none_zone (empty)")
	else:
		_fail("get_faces_for_none_zone", "Expected empty, got %d faces" % faces.size())
	vc.queue_free()


func _test_ray_aabb_behind_camera() -> void:
	var vc := _create_view_cube()
	root.add_child(vc)
	# Ray starting behind the cube (negative t)
	var result: Dictionary = vc._ray_aabb_hit(
		Vector3(0, 0, -5),
		Vector3(0, 0, -1),  # Going further away
		vc.CUBE_HALF
	)
	if result.zone == vc.HitZone.NONE:
		_pass("ray_aabb_behind_camera")
	else:
		_fail("ray_aabb_behind_camera", "Expected NONE, got zone %d" % result.zone)
	vc.queue_free()
