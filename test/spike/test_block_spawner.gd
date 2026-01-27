extends SceneTree

# Test: BlockSpawner for managing 3D blocks

func _init():
	print("=== Testing BlockSpawner ===")

	var BlockSpawnerClass = load("res://src/spike/block_spawner.gd")

	# Test 1: Spawner instantiates
	print("\nTest 1: Spawner instantiates")
	var spawner: Node3D = BlockSpawnerClass.new()
	assert(spawner != null, "Spawner should instantiate")
	print("PASS: Spawner instantiated")

	# Test 2: Place a block
	print("\nTest 2: Place a block")
	var block = spawner.place_block(Vector3i(0, 0, 0), "corridor")
	assert(block != null, "Should return placed block")
	assert(spawner.get_block_count() == 1, "Should have 1 block")
	print("PASS: Block placed successfully")

	# Test 3: Duplicate placement returns null
	print("\nTest 3: Duplicate placement rejected")
	var duplicate = spawner.place_block(Vector3i(0, 0, 0), "residential_basic")
	assert(duplicate == null, "Duplicate placement should return null")
	assert(spawner.get_block_count() == 1, "Should still have 1 block")
	print("PASS: Duplicate placement rejected")

	# Test 4: Get block at position
	print("\nTest 4: Get block at position")
	var retrieved = spawner.get_block_at(Vector3i(0, 0, 0))
	assert(retrieved == block, "Should return same block")
	var empty = spawner.get_block_at(Vector3i(99, 99, 99))
	assert(empty == null, "Empty position should return null")
	print("PASS: Block retrieval works")

	# Test 5: Has block at position
	print("\nTest 5: Has block at position")
	assert(spawner.has_block_at(Vector3i(0, 0, 0)) == true, "Should have block at origin")
	assert(spawner.has_block_at(Vector3i(99, 99, 99)) == false, "Should not have block at empty position")
	print("PASS: has_block_at works")

	# Test 6: Place multiple blocks
	print("\nTest 6: Place multiple blocks")
	spawner.place_block(Vector3i(1, 0, 0), "corridor")
	spawner.place_block(Vector3i(0, 1, 0), "residential_basic")
	spawner.place_block(Vector3i(0, 0, 1), "commercial_basic")
	assert(spawner.get_block_count() == 4, "Should have 4 blocks")
	print("PASS: Multiple blocks placed")

	# Test 7: Get all positions
	print("\nTest 7: Get all positions")
	var positions: Array = spawner.get_all_positions()
	assert(positions.size() == 4, "Should return 4 positions")
	assert(Vector3i(0, 0, 0) in positions, "Should include origin")
	assert(Vector3i(1, 0, 0) in positions, "Should include (1,0,0)")
	print("PASS: All positions returned")

	# Test 8: Remove block
	print("\nTest 8: Remove block")
	var removed: bool = spawner.remove_block(Vector3i(1, 0, 0))
	assert(removed == true, "Should return true on removal")
	assert(spawner.get_block_count() == 3, "Should have 3 blocks after removal")
	assert(spawner.has_block_at(Vector3i(1, 0, 0)) == false, "Removed block should be gone")
	print("PASS: Block removed")

	# Test 9: Remove non-existent block returns false
	print("\nTest 9: Remove non-existent block")
	var not_removed: bool = spawner.remove_block(Vector3i(99, 99, 99))
	assert(not_removed == false, "Should return false for non-existent block")
	print("PASS: Non-existent removal returns false")

	# Test 10: Clear all blocks
	print("\nTest 10: Clear all blocks")
	spawner.clear_all_blocks()
	assert(spawner.get_block_count() == 0, "Should have 0 blocks after clear")
	print("PASS: All blocks cleared")

	# Cleanup
	spawner.queue_free()

	print("\n=== All BlockSpawner Tests Passed ===")
	quit()
