extends SceneTree
## Unit tests for ArcologyCamera

const ArcologyCameraClass := preload("res://src/core/camera_3d_controller.gd")


func _init() -> void:
	print("=== ArcologyCamera Tests ===")
	var passed := 0
	var failed := 0

	# Test 1: Camera creation
	print("\n1. Camera creation...")
	var camera: Node3D = ArcologyCameraClass.new()
	camera._ready()  # Call manually since not in tree
	if camera != null and camera.get_camera() != null:
		print("  PASS: Camera created with Camera3D child")
		passed += 1
	else:
		print("  FAIL: Camera or Camera3D child is null")
		failed += 1

	# Test 2: Initial values
	print("\n2. Initial values...")
	if camera.mode == ArcologyCameraClass.Mode.FREE:
		print("  PASS: Mode is FREE by default")
		passed += 1
	else:
		print("  FAIL: Mode should be FREE, got %s" % camera.mode)
		failed += 1

	# Test 3: Spherical coordinates
	print("\n3. Spherical coordinate conversion...")
	camera.set_azimuth(45.0, true)
	camera.set_elevation(45.0, true)
	camera.set_distance(100.0, true)
	camera.set_target(Vector3.ZERO, true)
	camera._update_camera_transform()
	var cam_pos: Vector3 = camera.get_camera().position
	# At azimuth=45, elevation=45, distance=100:
	# x = sin(45°) * cos(45°) * 100 ≈ 50
	# y = sin(45°) * 100 ≈ 70.71
	# z = cos(45°) * cos(45°) * 100 ≈ 50
	var expected_x := sin(deg_to_rad(45.0)) * cos(deg_to_rad(45.0)) * 100.0
	var expected_y := sin(deg_to_rad(45.0)) * 100.0
	var expected_z := cos(deg_to_rad(45.0)) * cos(deg_to_rad(45.0)) * 100.0
	if is_equal_approx(cam_pos.x, expected_x) and is_equal_approx(cam_pos.y, expected_y) and is_equal_approx(cam_pos.z, expected_z):
		print("  PASS: Camera position matches spherical coordinates (%.2f, %.2f, %.2f)" % [cam_pos.x, cam_pos.y, cam_pos.z])
		passed += 1
	else:
		print("  FAIL: Expected (%.2f, %.2f, %.2f), got (%.2f, %.2f, %.2f)" % [expected_x, expected_y, expected_z, cam_pos.x, cam_pos.y, cam_pos.z])
		failed += 1

	# Test 4: Azimuth clamping (wraparound, not clamped)
	print("\n4. Azimuth values...")
	camera.set_azimuth(360.0, true)
	if camera.azimuth == 360.0:  # Azimuth wraps naturally via trig functions
		print("  PASS: Azimuth accepts values >= 360 (will wrap via math)")
		passed += 1
	else:
		print("  FAIL: Azimuth set to 360 should be accepted")
		failed += 1

	# Test 5: Elevation clamping
	print("\n5. Elevation clamping...")
	camera.set_elevation(100.0, true)  # Above max
	if camera.elevation <= ArcologyCameraClass.MAX_ELEVATION:
		print("  PASS: Elevation clamped to max (%.1f)" % camera.elevation)
		passed += 1
	else:
		print("  FAIL: Elevation should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MAX_ELEVATION, camera.elevation])
		failed += 1

	# Test 6: Elevation minimum clamping
	print("\n6. Elevation minimum clamping...")
	camera.set_elevation(-10.0, true)  # Below min
	if camera.elevation >= ArcologyCameraClass.MIN_ELEVATION:
		print("  PASS: Elevation clamped to min (%.1f)" % camera.elevation)
		passed += 1
	else:
		print("  FAIL: Elevation should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MIN_ELEVATION, camera.elevation])
		failed += 1

	# Test 7: Distance clamping (max)
	print("\n7. Distance clamping (max)...")
	camera.set_distance(5000.0, true)  # Above max
	if camera.distance <= ArcologyCameraClass.MAX_DISTANCE:
		print("  PASS: Distance clamped to max (%.1f)" % camera.distance)
		passed += 1
	else:
		print("  FAIL: Distance should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MAX_DISTANCE, camera.distance])
		failed += 1

	# Test 8: Distance clamping (min)
	print("\n8. Distance clamping (min)...")
	camera.set_distance(1.0, true)  # Below min
	if camera.distance >= ArcologyCameraClass.MIN_DISTANCE:
		print("  PASS: Distance clamped to min (%.1f)" % camera.distance)
		passed += 1
	else:
		print("  FAIL: Distance should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MIN_DISTANCE, camera.distance])
		failed += 1

	# Test 9: Ortho size clamping (max)
	print("\n9. Ortho size clamping (max)...")
	camera.set_ortho_size(1000.0, true)  # Above max
	if camera.ortho_size <= ArcologyCameraClass.MAX_ORTHO_SIZE:
		print("  PASS: Ortho size clamped to max (%.1f)" % camera.ortho_size)
		passed += 1
	else:
		print("  FAIL: Ortho size should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MAX_ORTHO_SIZE, camera.ortho_size])
		failed += 1

	# Test 10: Ortho size clamping (min)
	print("\n10. Ortho size clamping (min)...")
	camera.set_ortho_size(1.0, true)  # Below min
	if camera.ortho_size >= ArcologyCameraClass.MIN_ORTHO_SIZE:
		print("  PASS: Ortho size clamped to min (%.1f)" % camera.ortho_size)
		passed += 1
	else:
		print("  FAIL: Ortho size should be clamped to %.1f, got %.1f" % [ArcologyCameraClass.MIN_ORTHO_SIZE, camera.ortho_size])
		failed += 1

	# Test 11: Snap to ortho view - TOP
	print("\n11. Snap to ortho view - TOP...")
	camera.snap_to_ortho(ArcologyCameraClass.OrthoView.TOP)
	if camera.mode == ArcologyCameraClass.Mode.ORTHO and camera.ortho_view == ArcologyCameraClass.OrthoView.TOP:
		print("  PASS: Snapped to TOP view (mode=ORTHO, view=TOP)")
		passed += 1
	else:
		print("  FAIL: Should be ORTHO mode with TOP view, got mode=%s view=%s" % [camera.mode, camera.ortho_view])
		failed += 1

	# Test 12: Snap to ortho view - ISO
	print("\n12. Snap to ortho view - ISO...")
	camera.snap_to_ortho(ArcologyCameraClass.OrthoView.ISO)
	camera.apply_immediately()
	var preset_iso: Dictionary = ArcologyCameraClass.ORTHO_PRESETS[ArcologyCameraClass.OrthoView.ISO]
	if is_equal_approx(camera.azimuth, preset_iso.azimuth) and camera.ortho_view == ArcologyCameraClass.OrthoView.ISO:
		print("  PASS: Snapped to ISO view (azimuth=%.1f)" % camera.azimuth)
		passed += 1
	else:
		print("  FAIL: ISO view should have azimuth=%.1f, got %.1f" % [preset_iso.azimuth, camera.azimuth])
		failed += 1

	# Test 13: Return to free mode
	print("\n13. Return to free mode...")
	camera.return_to_free()
	if camera.mode == ArcologyCameraClass.Mode.FREE:
		print("  PASS: Returned to FREE mode")
		passed += 1
	else:
		print("  FAIL: Should be FREE mode, got %s" % camera.mode)
		failed += 1

	# Test 14: Toggle mode
	print("\n14. Toggle mode...")
	var initial_mode: int = camera.mode
	camera.toggle_mode()
	var after_toggle: int = camera.mode
	camera.toggle_mode()
	var after_second_toggle: int = camera.mode
	if initial_mode == after_second_toggle and initial_mode != after_toggle:
		print("  PASS: Toggle mode works (FREE -> ORTHO -> FREE)")
		passed += 1
	else:
		print("  FAIL: Toggle didn't work correctly: %s -> %s -> %s" % [initial_mode, after_toggle, after_second_toggle])
		failed += 1

	# Test 15: Focus on position
	print("\n15. Focus on position...")
	var focus_pos := Vector3(50.0, 0.0, 50.0)
	camera.focus_on(focus_pos, true)
	if camera.target == focus_pos:
		print("  PASS: Camera focused on (%.1f, %.1f, %.1f)" % [camera.target.x, camera.target.y, camera.target.z])
		passed += 1
	else:
		print("  FAIL: Target should be (%.1f, %.1f, %.1f), got (%.1f, %.1f, %.1f)" % [focus_pos.x, focus_pos.y, focus_pos.z, camera.target.x, camera.target.y, camera.target.z])
		failed += 1

	# Test 16: Reset view
	print("\n16. Reset view...")
	camera.focus_on(Vector3(100, 50, 100), true)
	camera.set_azimuth(180.0, true)
	camera.set_elevation(60.0, true)
	camera.reset_view(true)
	if is_equal_approx(camera.azimuth, 45.0) and is_equal_approx(camera.elevation, 45.0) and camera.target == Vector3.ZERO:
		print("  PASS: View reset to defaults (az=45, el=45, target=origin)")
		passed += 1
	else:
		print("  FAIL: Reset should set azimuth=45, elevation=45, target=origin, got az=%.1f el=%.1f target=%s" % [camera.azimuth, camera.elevation, camera.target])
		failed += 1

	# Test 17: Get forward direction
	print("\n17. Get forward direction...")
	camera.set_azimuth(0.0, true)  # Facing north (Z+)
	var forward: Vector3 = camera.get_forward_direction()
	# At azimuth=0: forward = (sin(0), 0, cos(0)) = (0, 0, 1)
	if is_equal_approx(forward.x, 0.0) and is_equal_approx(forward.z, 1.0):
		print("  PASS: Forward direction at azimuth=0 is (0, 0, 1)")
		passed += 1
	else:
		print("  FAIL: Expected forward=(0, 0, 1), got (%.2f, %.2f, %.2f)" % [forward.x, forward.y, forward.z])
		failed += 1

	# Test 18: Get right direction
	print("\n18. Get right direction...")
	camera.set_azimuth(0.0, true)
	var right: Vector3 = camera.get_right_direction()
	# At azimuth=0: right = (cos(0), 0, -sin(0)) = (1, 0, 0)
	if is_equal_approx(right.x, 1.0) and is_equal_approx(right.z, 0.0):
		print("  PASS: Right direction at azimuth=0 is (1, 0, 0)")
		passed += 1
	else:
		print("  FAIL: Expected right=(1, 0, 0), got (%.2f, %.2f, %.2f)" % [right.x, right.y, right.z])
		failed += 1

	# Test 19: Orbit method
	print("\n19. Orbit method...")
	camera.set_azimuth(0.0, true)
	camera.set_elevation(45.0, true)
	camera.orbit(90.0, 10.0)  # Add to targets
	camera.apply_immediately()
	if is_equal_approx(camera.azimuth, 90.0) and is_equal_approx(camera.elevation, 55.0):
		print("  PASS: Orbit added (90, 10) to azimuth and elevation")
		passed += 1
	else:
		print("  FAIL: After orbit(90, 10), expected az=90 el=55, got az=%.1f el=%.1f" % [camera.azimuth, camera.elevation])
		failed += 1

	# Test 20: Zoom method - zoom out
	print("\n20. Zoom method (ortho size)...")
	camera.set_ortho_size(50.0, true)
	var initial_size: float = camera.ortho_size
	camera.zoom(0.1)  # Zoom out 10%
	camera.apply_immediately()
	var expected_size: float = initial_size * 1.1
	if is_equal_approx(camera.ortho_size, expected_size):
		print("  PASS: Zoom out increased ortho_size from %.1f to %.1f" % [initial_size, camera.ortho_size])
		passed += 1
	else:
		print("  FAIL: Expected ortho_size=%.1f after 10%% zoom out, got %.1f" % [expected_size, camera.ortho_size])
		failed += 1

	# Test 21: Zoom method - zoom in
	print("\n21. Zoom method - zoom in...")
	camera.set_ortho_size(50.0, true)
	initial_size = camera.ortho_size
	camera.zoom(-0.1)  # Zoom in 10%
	camera.apply_immediately()
	expected_size = initial_size * 0.9
	if is_equal_approx(camera.ortho_size, expected_size):
		print("  PASS: Zoom in decreased ortho_size from %.1f to %.1f" % [initial_size, camera.ortho_size])
		passed += 1
	else:
		print("  FAIL: Expected ortho_size=%.1f after 10%% zoom in, got %.1f" % [expected_size, camera.ortho_size])
		failed += 1

	# Test 22: All ortho views are valid
	print("\n22. All ortho views have presets...")
	var all_valid := true
	for view in [ArcologyCameraClass.OrthoView.TOP, ArcologyCameraClass.OrthoView.NORTH,
				 ArcologyCameraClass.OrthoView.EAST, ArcologyCameraClass.OrthoView.SOUTH,
				 ArcologyCameraClass.OrthoView.WEST, ArcologyCameraClass.OrthoView.BOTTOM,
				 ArcologyCameraClass.OrthoView.ISO]:
		if not ArcologyCameraClass.ORTHO_PRESETS.has(view):
			all_valid = false
			print("  Missing preset for view %s" % view)
	if all_valid:
		print("  PASS: All 7 ortho views have presets")
		passed += 1
	else:
		print("  FAIL: Some ortho views missing presets")
		failed += 1

	# Test 23: Camera projection is orthographic
	print("\n23. Camera projection is orthographic...")
	var cam_3d: Camera3D = camera.get_camera()
	if cam_3d and cam_3d.projection == Camera3D.PROJECTION_ORTHOGONAL:
		print("  PASS: Camera projection is orthographic")
		passed += 1
	else:
		print("  FAIL: Camera projection should be orthographic")
		failed += 1

	# Test 24: Snap to each cardinal ortho view
	print("\n24. Snap to cardinal views...")
	var cardinal_views := [
		[ArcologyCameraClass.OrthoView.NORTH, 0.0],
		[ArcologyCameraClass.OrthoView.EAST, 90.0],
		[ArcologyCameraClass.OrthoView.SOUTH, 180.0],
		[ArcologyCameraClass.OrthoView.WEST, 270.0]
	]
	var cardinal_pass := true
	for view_data in cardinal_views:
		var view: int = view_data[0]
		var expected_azimuth: float = view_data[1]
		camera.snap_to_ortho(view)
		camera.apply_immediately()
		if not is_equal_approx(camera.azimuth, expected_azimuth):
			print("  View %s: expected azimuth=%.1f, got %.1f" % [view, expected_azimuth, camera.azimuth])
			cardinal_pass = false
	if cardinal_pass:
		print("  PASS: All cardinal views have correct azimuth values")
		passed += 1
	else:
		print("  FAIL: Some cardinal views have wrong azimuth")
		failed += 1

	# Test 25: Get mode and ortho view getters
	print("\n25. Getters for mode and ortho_view...")
	camera.snap_to_ortho(ArcologyCameraClass.OrthoView.TOP)
	if camera.get_mode() == ArcologyCameraClass.Mode.ORTHO and camera.get_ortho_view() == ArcologyCameraClass.OrthoView.TOP:
		print("  PASS: Getters return correct values")
		passed += 1
	else:
		print("  FAIL: Getters returned wrong values")
		failed += 1

	# Cleanup
	camera.free()

	# Summary
	print("\n=== Summary ===")
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)
	print("Total:  %d" % (passed + failed))

	if failed > 0:
		print("\nTESTS FAILED")
	else:
		print("\nALL TESTS PASSED")

	quit()
