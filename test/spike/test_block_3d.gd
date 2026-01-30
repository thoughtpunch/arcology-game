extends SceneTree

# Test: Block3D CSG blocks for 3D spike

const EPSILON := 0.001

func _init():
	print("=== Testing Block3D ===")

	var Block3DClass = load("res://src/spike/block_3d.gd")

	# Test 1: Block dimensions
	print("\nTest 1: Block dimensions")
	var block: CSGBox3D = Block3DClass.new()
	assert(abs(block.size.x - 6.0) < EPSILON, "Width should be 6m")
	assert(abs(block.size.y - 6.0) < EPSILON, "Height should be 6m")
	assert(abs(block.size.z - 6.0) < EPSILON, "Depth should be 6m")
	print("PASS: Block dimensions are 6x6x6m (true cube)")

	# Test 2: Collision enabled
	print("\nTest 2: Collision enabled")
	assert(block.use_collision == true, "Collision should be enabled")
	assert(block.collision_layer == 2, "Collision layer should be 2")
	print("PASS: Collision is enabled on layer 2")

	# Test 3: Grid to world conversion
	print("\nTest 3: Grid to world conversion")
	var world_pos: Vector3 = Block3DClass.grid_to_world(Vector3i(0, 0, 0))
	assert(abs(world_pos.x) < EPSILON, "Origin X should be 0")
	assert(abs(world_pos.y - 3.0) < EPSILON, "Origin Y should be half height (3.0)")
	assert(abs(world_pos.z) < EPSILON, "Origin Z should be 0")
	print("PASS: Grid (0,0,0) -> World (0, 3.0, 0)")

	# Test 4: Grid to world at different positions
	print("\nTest 4: Grid position offset")
	world_pos = Block3DClass.grid_to_world(Vector3i(1, 2, -1))
	assert(abs(world_pos.x - 6.0) < EPSILON, "X should be 6 at grid x=1")
	assert(abs(world_pos.y - 15.0) < EPSILON, "Y should be 15.0 at grid y=2")  # 2*6.0 + 3.0
	assert(abs(world_pos.z - (-6.0)) < EPSILON, "Z should be -6 at grid z=-1")
	print("PASS: Grid (1,2,-1) -> World (6, 15.0, -6)")

	# Test 5: World to grid conversion (inverse)
	print("\nTest 5: World to grid conversion")
	var grid_pos: Vector3i = Block3DClass.world_to_grid(Vector3(6.0, 15.0, -6.0))
	assert(grid_pos.x == 1, "Grid X should be 1")
	assert(grid_pos.y == 2, "Grid Y should be 2")
	assert(grid_pos.z == -1, "Grid Z should be -1")
	print("PASS: World (6, 15.0, -6) -> Grid (1, 2, -1)")

	# Test 6: Round-trip conversion
	print("\nTest 6: Round-trip grid->world->grid")
	var original := Vector3i(3, 5, -2)
	var round_trip: Vector3i = Block3DClass.world_to_grid(Block3DClass.grid_to_world(original))
	assert(round_trip == original, "Round-trip should preserve coordinates")
	print("PASS: Round-trip preserves coordinates")

	# Test 7: Block type changes material
	print("\nTest 7: Block type materials")
	block.block_type = "residential_basic"
	assert(block.material != null, "Material should be set")
	var residential_color: Color = block.material.albedo_color
	block.block_type = "commercial_basic"
	var commercial_color: Color = block.material.albedo_color
	assert(residential_color != commercial_color, "Different types should have different colors")
	print("PASS: Block types have different materials")

	# Test 8: Grid position updates world position
	print("\nTest 8: Grid position setter")
	block.grid_position = Vector3i(2, 1, 3)
	var expected_pos: Vector3 = Block3DClass.grid_to_world(Vector3i(2, 1, 3))
	assert((block.position - expected_pos).length() < EPSILON, "Position should match grid conversion")
	print("PASS: Grid position setter updates world position")

	# Test 9: Available types
	print("\nTest 9: Available block types")
	var types: Array = Block3DClass.get_available_types()
	assert(types.size() >= 6, "Should have at least 6 block types")
	assert("corridor" in types, "Should include corridor")
	assert("residential_basic" in types, "Should include residential_basic")
	assert("commercial_basic" in types, "Should include commercial_basic")
	print("PASS: Block types available: " + str(types.size()))

	# Test 10: Unknown type gets default material
	print("\nTest 10: Unknown type fallback")
	block.block_type = "nonexistent_type"
	assert(block.material != null, "Should have fallback material")
	print("PASS: Unknown type uses default material")

	# Cleanup
	block.queue_free()

	print("\n=== All Block3D Tests Passed ===")
	quit()
