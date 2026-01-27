extends SceneTree

# Test: Spike3D scene loads correctly and has expected nodes

func _init():
	print("=== Testing Spike3D Scene ===")

	# Load the scene
	var scene = load("res://scenes/spike/spike_3d.tscn")
	assert(scene != null, "Scene should load")
	print("PASS: Scene loaded")

	# Instantiate it
	var instance = scene.instantiate()
	assert(instance != null, "Scene should instantiate")
	print("PASS: Scene instantiated")

	# Check root node type
	assert(instance is Node3D, "Root should be Node3D")
	print("PASS: Root is Node3D")

	# Check Camera3D exists and is orthographic
	var camera = instance.get_node_or_null("Camera3D")
	assert(camera != null, "Camera3D should exist")
	assert(camera is Camera3D, "Should be Camera3D type")
	assert(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera should be orthographic")
	assert(camera.size == 50.0, "Camera ortho size should be 50")
	print("PASS: Camera3D is orthographic with size 50")

	# Check DirectionalLight3D exists and has shadows
	var light = instance.get_node_or_null("DirectionalLight3D")
	assert(light != null, "DirectionalLight3D should exist")
	assert(light is DirectionalLight3D, "Should be DirectionalLight3D type")
	assert(light.shadow_enabled == true, "Shadows should be enabled")
	print("PASS: DirectionalLight3D with shadows enabled")

	# Check ground plane exists
	var ground = instance.get_node_or_null("GroundPlane")
	assert(ground != null, "GroundPlane should exist")
	assert(ground is MeshInstance3D, "Ground should be MeshInstance3D")
	assert(ground.mesh is PlaneMesh, "Ground mesh should be PlaneMesh")
	var plane_mesh: PlaneMesh = ground.mesh
	assert(plane_mesh.size == Vector2(100, 100), "Ground should be 100x100")
	print("PASS: GroundPlane is 100x100 MeshInstance3D")

	# Check WorldEnvironment exists
	var env = instance.get_node_or_null("WorldEnvironment")
	assert(env != null, "WorldEnvironment should exist")
	print("PASS: WorldEnvironment exists")

	# Cleanup
	instance.queue_free()

	print("=== All Spike3D Scene Tests Passed ===")
	quit()
