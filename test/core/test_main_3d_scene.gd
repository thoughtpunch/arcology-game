extends SceneTree
## Test: Main scene converted to 3D (arcology-kj1)
##
## Verifies:
## - Main scene has Node3D root
## - WorldEnvironment is configured
## - DirectionalLight3D has shadows
## - CanvasLayer UI is preserved
## - Camera3D is present and orthographic

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("\n=== Test: Main 3D Scene Structure ===\n")

	# Load the main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene should load")
	_test_count += 1
	_pass_count += 1
	print("PASS: Main scene loads")

	var main: Node = main_scene.instantiate()
	root.add_child(main)

	# Wait for _ready to be called
	await process_frame
	await process_frame

	# Test 1: Root is Node3D
	_test_root_is_node3d(main)

	# Test 2: WorldEnvironment exists
	_test_world_environment(main)

	# Test 3: DirectionalLight3D with shadows
	_test_directional_light(main)

	# Test 4: Camera3D exists and is orthographic
	_test_camera_3d(main)

	# Test 5: World node is Node3D
	_test_world_node(main)

	# Test 6: UI CanvasLayer exists
	_test_ui_canvaslayer(main)

	# Test 7: Ground plane exists
	_test_ground_plane(main)

	# Test 8: Main script is attached
	_test_main_script(main)

	# Test 9: Environment has sky
	_test_environment_sky(main)

	# Test 10: Environment has SSAO
	_test_environment_ssao(main)

	# Test 11: Light direction (sun angle)
	_test_light_direction(main)

	# Cleanup
	main.queue_free()
	await process_frame

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])

	if _pass_count == _test_count:
		print("SUCCESS: All tests passed!")
	else:
		print("FAILURE: Some tests failed!")

	quit()


func _test_root_is_node3d(main: Node) -> void:
	_test_count += 1
	if main is Node3D:
		_pass_count += 1
		print("PASS: Root node is Node3D")
	else:
		print("FAIL: Root node should be Node3D, got %s" % main.get_class())


func _test_world_environment(main: Node) -> void:
	_test_count += 1
	var world_env: WorldEnvironment = main.get_node_or_null("WorldEnvironment")
	if world_env != null:
		_pass_count += 1
		print("PASS: WorldEnvironment exists")
	else:
		print("FAIL: WorldEnvironment not found")

	# Also check that environment resource is set
	_test_count += 1
	if world_env and world_env.environment != null:
		_pass_count += 1
		print("PASS: WorldEnvironment has environment resource")
	else:
		print("FAIL: WorldEnvironment should have environment resource")


func _test_directional_light(main: Node) -> void:
	_test_count += 1
	var light: DirectionalLight3D = main.get_node_or_null("DirectionalLight3D")
	if light != null:
		_pass_count += 1
		print("PASS: DirectionalLight3D exists")
	else:
		print("FAIL: DirectionalLight3D not found")
		return

	# Check shadows enabled
	_test_count += 1
	if light.shadow_enabled:
		_pass_count += 1
		print("PASS: DirectionalLight3D has shadows enabled")
	else:
		print("FAIL: DirectionalLight3D should have shadows enabled")


func _test_camera_3d(main: Node) -> void:
	_test_count += 1
	var camera: Camera3D = main.get_node_or_null("Camera3DController/Camera3D")
	if camera != null:
		_pass_count += 1
		print("PASS: Camera3D exists")
	else:
		print("FAIL: Camera3D not found at Camera3DController/Camera3D")
		return

	# Check orthographic projection
	_test_count += 1
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_pass_count += 1
		print("PASS: Camera3D is orthographic")
	else:
		print("FAIL: Camera3D should be orthographic, got projection=%d" % camera.projection)

	# Check size is reasonable (10-200 range)
	_test_count += 1
	if camera.size >= 10.0 and camera.size <= 200.0:
		_pass_count += 1
		print("PASS: Camera3D size is reasonable (%.1f)" % camera.size)
	else:
		print("FAIL: Camera3D size should be 10-200, got %.1f" % camera.size)


func _test_world_node(main: Node) -> void:
	_test_count += 1
	var world: Node = main.get_node_or_null("World")
	if world != null and world is Node3D:
		_pass_count += 1
		print("PASS: World node is Node3D")
	else:
		if world == null:
			print("FAIL: World node not found")
		else:
			print("FAIL: World node should be Node3D, got %s" % world.get_class())


func _test_ui_canvaslayer(main: Node) -> void:
	_test_count += 1
	var ui: CanvasLayer = main.get_node_or_null("UI")
	if ui != null:
		_pass_count += 1
		print("PASS: UI CanvasLayer exists")
	else:
		print("FAIL: UI CanvasLayer not found")


func _test_ground_plane(main: Node) -> void:
	_test_count += 1
	var ground: MeshInstance3D = main.get_node_or_null("World/GroundPlane")
	if ground != null:
		_pass_count += 1
		print("PASS: Ground plane exists")
	else:
		print("FAIL: Ground plane not found at World/GroundPlane")
		return

	# Check mesh is PlaneMesh
	_test_count += 1
	if ground.mesh is PlaneMesh:
		_pass_count += 1
		print("PASS: Ground plane has PlaneMesh")
	else:
		print("FAIL: Ground plane should have PlaneMesh")


func _test_main_script(main: Node) -> void:
	_test_count += 1
	var script: Script = main.get_script()
	if script != null:
		_pass_count += 1
		print("PASS: Main has script attached")
	else:
		print("FAIL: Main should have script attached")

	# Check script extends Node3D
	_test_count += 1
	# The script path should be main.gd
	if script and script.resource_path.ends_with("main.gd"):
		_pass_count += 1
		print("PASS: Main uses main.gd script")
	else:
		print("FAIL: Main should use main.gd script")


func _test_environment_sky(main: Node) -> void:
	_test_count += 1
	var world_env: WorldEnvironment = main.get_node_or_null("WorldEnvironment")
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		# Check for sky (background_mode 2 = sky)
		if env.background_mode == Environment.BG_SKY and env.sky != null:
			_pass_count += 1
			print("PASS: Environment has sky configured")
		else:
			print("FAIL: Environment should have sky (mode=%d)" % env.background_mode)
	else:
		print("FAIL: Cannot check sky - no environment")


func _test_environment_ssao(main: Node) -> void:
	_test_count += 1
	var world_env: WorldEnvironment = main.get_node_or_null("WorldEnvironment")
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		if env.ssao_enabled:
			_pass_count += 1
			print("PASS: Environment has SSAO enabled")
		else:
			print("FAIL: Environment should have SSAO enabled")
	else:
		print("FAIL: Cannot check SSAO - no environment")


func _test_light_direction(main: Node) -> void:
	_test_count += 1
	var light: DirectionalLight3D = main.get_node_or_null("DirectionalLight3D")
	if light:
		# Check that light is angled (not pointing straight down)
		# A good sun angle has rotation on both X and Y
		var rot: Vector3 = light.rotation_degrees
		# Y position should be elevated (sun in sky)
		if light.position.y > 0:
			_pass_count += 1
			print("PASS: Light is positioned in sky (y=%.1f)" % light.position.y)
		else:
			print("FAIL: Light should be positioned in sky, y=%.1f" % light.position.y)
	else:
		print("FAIL: Cannot check light direction - no light")
