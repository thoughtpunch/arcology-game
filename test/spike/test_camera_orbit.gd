extends SceneTree

# Test: CameraOrbit orbital camera controller

const EPSILON := 0.01

func _init():
	print("=== Testing CameraOrbit ===")

	# Load the class
	var CameraOrbitClass = load("res://src/spike/camera_orbit.gd")

	# Test 1: Initial state
	print("\nTest 1: Initial state")
	var camera: Camera3D = CameraOrbitClass.new()
	assert(camera != null, "Camera should instantiate")
	assert(camera.azimuth == 0.0, "Initial azimuth should be 0")
	assert(camera.elevation == 45.0, "Initial elevation should be 45")
	assert(camera.distance == 50.0, "Initial distance should be 50")
	assert(camera.target == Vector3.ZERO, "Initial target should be origin")
	print("PASS: Initial state correct")

	# Test 2: Elevation clamping
	print("\nTest 2: Elevation clamping")
	camera.set_elevation(0.0, true)
	assert(camera.elevation >= camera.MIN_ELEVATION, "Elevation should clamp to MIN")
	camera.set_elevation(90.0, true)
	assert(camera.elevation <= camera.MAX_ELEVATION, "Elevation should clamp to MAX")
	print("PASS: Elevation clamping works")

	# Test 3: Distance clamping
	print("\nTest 3: Distance clamping")
	camera.set_distance(1.0, true)
	assert(camera.distance >= camera.MIN_DISTANCE, "Distance should clamp to MIN")
	camera.set_distance(1000.0, true)
	assert(camera.distance <= camera.MAX_DISTANCE, "Distance should clamp to MAX")
	print("PASS: Distance clamping works")

	# Test 4: Set target
	print("\nTest 4: Set target")
	var new_target := Vector3(10, 0, 10)
	camera.set_target(new_target, true)
	assert((camera.target - new_target).length() < EPSILON, "Target should be set")
	print("PASS: Target setting works")

	# Test 5: Set azimuth
	print("\nTest 5: Set azimuth")
	camera.set_azimuth(90.0, true)
	assert(abs(camera.azimuth - 90.0) < EPSILON, "Azimuth should be 90")
	print("PASS: Azimuth setting works")

	# Test 6: Reset view
	print("\nTest 6: Reset view")
	camera.set_target(Vector3(50, 0, 50), true)
	camera.set_azimuth(180.0, true)
	camera.set_elevation(60.0, true)
	camera.reset_view(true)
	assert(abs(camera.azimuth) < EPSILON, "Azimuth should reset to 0")
	assert(abs(camera.elevation - 45.0) < EPSILON, "Elevation should reset to 45")
	assert(abs(camera.distance - 50.0) < EPSILON, "Distance should reset to 50")
	assert(camera.target.length() < EPSILON, "Target should reset to origin")
	print("PASS: Reset view works")

	# Test 7: Camera position calculation
	print("\nTest 7: Camera position calculation")
	camera.reset_view(true)
	camera._update_camera_position()
	# At azimuth=0, elevation=45, distance=50, camera should be at:
	# x = sin(0) * cos(45) * 50 = 0
	# y = sin(45) * 50 = ~35.35
	# z = cos(0) * cos(45) * 50 = ~35.35
	assert(abs(camera.position.x) < EPSILON, "X should be 0 at azimuth 0")
	assert(camera.position.y > 30 and camera.position.y < 40, "Y should be ~35")
	assert(camera.position.z > 30 and camera.position.z < 40, "Z should be ~35")
	print("PASS: Camera position calculation correct")

	# Test 8: Forward direction
	print("\nTest 8: Forward direction")
	camera.set_azimuth(0.0, true)
	var forward: Vector3 = camera.get_forward_direction()
	# At azimuth=0, forward should be (0, 0, 1) in XZ plane
	assert(abs(forward.x) < EPSILON, "Forward X should be 0 at azimuth 0")
	assert(abs(forward.y) < EPSILON, "Forward Y should be 0 (XZ plane)")
	assert(abs(forward.z - 1.0) < EPSILON, "Forward Z should be 1 at azimuth 0")
	print("PASS: Forward direction correct")

	# Test 9: Right direction
	print("\nTest 9: Right direction")
	var right: Vector3 = camera.get_right_direction()
	# At azimuth=0, right should be (1, 0, 0)
	assert(abs(right.x - 1.0) < EPSILON, "Right X should be 1 at azimuth 0")
	assert(abs(right.y) < EPSILON, "Right Y should be 0 (XZ plane)")
	assert(abs(right.z) < EPSILON, "Right Z should be 0 at azimuth 0")
	print("PASS: Right direction correct")

	# Test 10: 90-degree rotation
	print("\nTest 10: 90-degree rotation directions")
	camera.set_azimuth(90.0, true)
	var forward90: Vector3 = camera.get_forward_direction()
	var right90: Vector3 = camera.get_right_direction()
	# At azimuth=90, forward should be (1, 0, 0), right should be (0, 0, -1)
	assert(abs(forward90.x - 1.0) < EPSILON, "Forward X should be 1 at azimuth 90")
	assert(abs(forward90.z) < EPSILON, "Forward Z should be 0 at azimuth 90")
	assert(abs(right90.x) < EPSILON, "Right X should be 0 at azimuth 90")
	assert(abs(right90.z - (-1.0)) < EPSILON, "Right Z should be -1 at azimuth 90")
	print("PASS: 90-degree rotation correct")

	# Test 11: Smooth interpolation (targets differ from current)
	print("\nTest 11: Smooth interpolation targets")
	camera.reset_view(true)
	camera.set_target(Vector3(100, 0, 100))  # No immediate flag
	camera.set_azimuth(180.0)  # No immediate flag
	# Targets should be different from current
	assert(camera._target_target != camera.target, "Target should have deferred update")
	assert(camera._target_azimuth != camera.azimuth, "Azimuth should have deferred update")
	print("PASS: Deferred targets work correctly")

	# Test 12: Orthographic zoom size clamping
	print("\nTest 12: Orthographic zoom clamping")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 50.0
	camera._zoom(10.0)  # Zoom way out
	assert(camera.size <= camera.MAX_ORTHO_SIZE, "Ortho size should clamp to MAX")
	camera._zoom(-10.0)  # Zoom way in
	assert(camera.size >= camera.MIN_ORTHO_SIZE, "Ortho size should clamp to MIN")
	print("PASS: Orthographic zoom clamping works")

	# Test 13: Perspective zoom distance clamping
	print("\nTest 13: Perspective zoom clamping")
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.set_distance(50.0, true)
	camera._zoom(10.0)  # Zoom way out
	assert(camera._target_distance <= camera.MAX_DISTANCE, "Distance should clamp to MAX")
	camera._zoom(-10.0)  # Zoom way in
	assert(camera._target_distance >= camera.MIN_DISTANCE, "Distance should clamp to MIN")
	print("PASS: Perspective zoom clamping works")

	# Cleanup
	camera.queue_free()

	print("\n=== All CameraOrbit Tests Passed ===")
	quit()
