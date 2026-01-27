extends SceneTree

# Test: BlockPlacer raycast click-to-place system

func _init():
	print("=== Testing BlockPlacer ===")

	var BlockPlacerClass = load("res://src/spike/block_placer.gd")
	var BlockSpawnerClass = load("res://src/spike/block_spawner.gd")
	var Block3DClass = load("res://src/spike/block_3d.gd")

	# Test 1: Placer instantiates
	print("\nTest 1: Placer instantiates")
	var placer: Node3D = BlockPlacerClass.new()
	assert(placer != null, "Placer should instantiate")
	print("PASS: Placer instantiated")

	# Test 2: Default selected block type
	print("\nTest 2: Default selected block type")
	assert(placer.selected_block_type == "corridor", "Default should be corridor")
	print("PASS: Default block type is corridor")

	# Test 3: Set selected block type
	print("\nTest 3: Set selected block type")
	placer.set_selected_block_type("residential_basic")
	assert(placer.selected_block_type == "residential_basic", "Should update to residential_basic")
	print("PASS: Block type updated")

	# Test 4: Ghost position accessor (default zero)
	print("\nTest 4: Ghost position accessor")
	var ghost_pos: Vector3i = placer.get_ghost_position()
	assert(ghost_pos == Vector3i.ZERO, "Default ghost position should be zero")
	print("PASS: Ghost position accessible")

	# Test 5: Ghost visibility (starts hidden)
	print("\nTest 5: Ghost visibility starts hidden")
	assert(placer.is_ghost_visible() == false, "Ghost should start hidden")
	print("PASS: Ghost starts hidden")

	# Test 6: Placement validity check (requires spawner)
	print("\nTest 6: Placement validity check with spawner")
	var spawner: Node3D = BlockSpawnerClass.new()
	placer.spawner = spawner

	# Empty position should be valid
	# Note: _is_valid_placement is private, so we test through is_placement_valid
	# which requires ghost_visible - we'll test the method directly with instance vars
	var is_valid_method = placer._is_valid_placement
	assert(placer._is_valid_placement(Vector3i(0, 0, 0)) == true, "Empty position at Y>=0 should be valid")
	print("PASS: Empty position valid")

	# Test 7: Below ground is invalid
	print("\nTest 7: Below ground is invalid")
	assert(placer._is_valid_placement(Vector3i(0, -1, 0)) == false, "Y=-1 should be invalid")
	assert(placer._is_valid_placement(Vector3i(5, -5, 10)) == false, "Any Y<0 should be invalid")
	print("PASS: Below ground positions are invalid")

	# Test 8: Occupied position is invalid
	print("\nTest 8: Occupied position is invalid")
	spawner.place_block(Vector3i(5, 0, 5), "corridor")
	assert(placer._is_valid_placement(Vector3i(5, 0, 5)) == false, "Occupied position should be invalid")
	assert(placer._is_valid_placement(Vector3i(5, 1, 5)) == true, "Position above occupied should be valid")
	print("PASS: Occupied positions are invalid")

	# Test 9: Signals are defined
	print("\nTest 9: Signals are defined")
	assert(placer.has_signal("block_placed"), "Should have block_placed signal")
	assert(placer.has_signal("block_removed"), "Should have block_removed signal")
	print("PASS: Signals defined")

	# Test 10: Grid coordinate conversion from Block3D
	print("\nTest 10: Grid coordinate conversion")
	var world_pos: Vector3 = Block3DClass.grid_to_world(Vector3i(2, 1, 3))
	var back_to_grid: Vector3i = Block3DClass.world_to_grid(world_pos)
	assert(back_to_grid == Vector3i(2, 1, 3), "Round-trip conversion should match")
	print("PASS: Grid coordinate conversion works")

	# Test 11: is_placement_valid requires ghost visibility
	print("\nTest 11: is_placement_valid requires ghost visibility")
	# Ghost is not visible, so even valid position should return false
	assert(placer.is_placement_valid() == false, "Should return false when ghost not visible")
	print("PASS: is_placement_valid checks ghost visibility")

	# Test 12: Collision mask is correct
	print("\nTest 12: Collision mask covers ground and blocks")
	assert(placer.COLLISION_MASK == 0b11, "Should include layers 1 and 2")
	print("PASS: Collision mask correct")

	# Test 13: Ray length is sufficient
	print("\nTest 13: Ray length is sufficient")
	assert(placer.RAY_LENGTH >= 1000.0, "Ray should be at least 1000 units")
	print("PASS: Ray length sufficient")

	# Cleanup
	spawner.queue_free()
	placer.queue_free()

	print("\n=== All BlockPlacer Tests Passed ===")
	quit()
