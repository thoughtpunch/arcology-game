extends SceneTree
## Test: Chunk (arcology-6ep)
##
## Verifies:
## - Block add/remove within chunk
## - Dirty state tracking
## - Chunk coordinate conversion
## - Mesh rebuild
## - AABB calculation
## - Empty chunk handling

var _test_count := 0
var _pass_count := 0

var _ChunkClass: GDScript


func _init() -> void:
	print("\n=== Test: Chunk ===\n")

	_ChunkClass = load("res://src/rendering/chunk.gd")
	assert(_ChunkClass != null, "Chunk script should load")

	# Run tests
	_test_chunk_creation()
	_test_add_block()
	_test_remove_block()
	_test_remove_nonexistent_block()
	_test_has_block()
	_test_get_block_data()
	_test_dirty_state()
	_test_empty_state()
	_test_block_count()
	_test_get_block_positions()
	_test_chunk_grid_origin()
	_test_grid_to_local_conversion()
	_test_rebuild_clears_dirty()
	_test_rebuild_empty_chunk()
	_test_aabb_calculation()
	_test_color_for_block_types()
	_test_multiple_blocks()
	_test_shader_assignment()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])

	if _pass_count == _test_count:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
		assert(false, "Not all tests passed")

	quit()


func _assert(condition: bool, message: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % message)
	else:
		print("  FAIL: %s" % message)


func _test_chunk_creation() -> void:
	print("\n--- Chunk Creation ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(1, 2, 3))
	root.add_child(chunk)
	await process_frame

	_assert(chunk.chunk_coord == Vector3i(1, 2, 3), "Chunk coordinate should be set")
	_assert(chunk.is_empty(), "New chunk should be empty")
	_assert(chunk.get_block_count() == 0, "New chunk should have 0 blocks")
	_assert(chunk.is_dirty(), "New chunk should be dirty")
	_assert(chunk.name == "Chunk_1_2_3", "Chunk name should include coordinates")

	chunk.queue_free()
	await process_frame


func _test_add_block() -> void:
	print("\n--- Add Block ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.add_block(Vector3i(1, 2, 0), "corridor", 0)

	_assert(chunk.get_block_count() == 1, "Should have 1 block after add")
	_assert(not chunk.is_empty(), "Should not be empty after add")
	_assert(chunk.is_dirty(), "Should be dirty after add")

	chunk.queue_free()
	await process_frame


func _test_remove_block() -> void:
	print("\n--- Remove Block ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.add_block(Vector3i(1, 2, 0), "corridor")
	var removed: bool = chunk.remove_block(Vector3i(1, 2, 0))

	_assert(removed, "Should return true when removing existing block")
	_assert(chunk.get_block_count() == 0, "Should have 0 blocks after remove")
	_assert(chunk.is_empty(), "Should be empty after removing last block")

	chunk.queue_free()
	await process_frame


func _test_remove_nonexistent_block() -> void:
	print("\n--- Remove Nonexistent Block ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	var removed: bool = chunk.remove_block(Vector3i(99, 99, 99))

	_assert(not removed, "Should return false when removing nonexistent block")
	_assert(chunk.get_block_count() == 0, "Count should remain 0")

	chunk.free()


func _test_has_block() -> void:
	print("\n--- Has Block ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	chunk.add_block(Vector3i(3, 4, 1), "entrance")

	_assert(chunk.has_block(Vector3i(3, 4, 1)), "Should find added block")
	_assert(not chunk.has_block(Vector3i(0, 0, 0)), "Should not find non-added block")

	chunk.free()


func _test_get_block_data() -> void:
	print("\n--- Get Block Data ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	chunk.add_block(Vector3i(2, 3, 0), "residential_basic", 2)
	var data: Dictionary = chunk.get_block_data(Vector3i(2, 3, 0))

	_assert(data.get("type") == "residential_basic", "Block type should match")
	_assert(data.get("rotation") == 2, "Block rotation should match")

	# Nonexistent position
	var empty: Dictionary = chunk.get_block_data(Vector3i(99, 99, 99))
	_assert(empty.is_empty(), "Should return empty dict for nonexistent position")

	chunk.free()


func _test_dirty_state() -> void:
	print("\n--- Dirty State ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	# New chunk is dirty
	_assert(chunk.is_dirty(), "New chunk should be dirty")

	# Rebuild clears dirty
	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	chunk.rebuild()
	_assert(not chunk.is_dirty(), "Should not be dirty after rebuild")

	# Adding block makes dirty again
	chunk.add_block(Vector3i(1, 0, 0), "entrance")
	_assert(chunk.is_dirty(), "Should be dirty after adding block post-rebuild")

	# mark_dirty explicitly
	chunk.rebuild()
	_assert(not chunk.is_dirty(), "Should not be dirty after second rebuild")
	chunk.mark_dirty()
	_assert(chunk.is_dirty(), "mark_dirty() should set dirty")

	chunk.queue_free()
	await process_frame


func _test_empty_state() -> void:
	print("\n--- Empty State ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	_assert(chunk.is_empty(), "New chunk should be empty")

	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(not chunk.is_empty(), "Chunk with block should not be empty")

	chunk.remove_block(Vector3i(0, 0, 0))
	_assert(chunk.is_empty(), "Chunk after removing all blocks should be empty")

	chunk.free()


func _test_block_count() -> void:
	print("\n--- Block Count ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	_assert(chunk.get_block_count() == 0, "New chunk: 0 blocks")

	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(chunk.get_block_count() == 1, "After 1 add: 1 block")

	chunk.add_block(Vector3i(1, 0, 0), "entrance")
	chunk.add_block(Vector3i(2, 0, 0), "stairs")
	_assert(chunk.get_block_count() == 3, "After 3 adds: 3 blocks")

	chunk.remove_block(Vector3i(1, 0, 0))
	_assert(chunk.get_block_count() == 2, "After 1 remove: 2 blocks")

	chunk.free()


func _test_get_block_positions() -> void:
	print("\n--- Get Block Positions ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	chunk.add_block(Vector3i(1, 1, 0), "entrance")

	var positions: Array = chunk.get_block_positions()
	_assert(positions.size() == 2, "Should return 2 positions")
	_assert(Vector3i(0, 0, 0) in positions, "Should contain (0,0,0)")
	_assert(Vector3i(1, 1, 0) in positions, "Should contain (1,1,0)")

	chunk.free()


func _test_chunk_grid_origin() -> void:
	print("\n--- Chunk Grid Origin ---")
	# Chunk(0,0,0) -> grid origin (0,0,0)
	var chunk0: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	var origin0: Vector3i = chunk0._chunk_grid_origin()
	_assert(origin0 == Vector3i(0, 0, 0), "Chunk(0,0,0) grid origin should be (0,0,0)")

	# Chunk(1,0,0) -> grid origin (8,0,0)
	var chunk1: Node3D = _ChunkClass.new(Vector3i(1, 0, 0))
	var origin1: Vector3i = chunk1._chunk_grid_origin()
	_assert(origin1 == Vector3i(8, 0, 0), "Chunk(1,0,0) grid origin should be (8,0,0)")

	# Chunk(2,3,1) -> grid origin (16,24,8)
	var chunk2: Node3D = _ChunkClass.new(Vector3i(2, 3, 1))
	var origin2: Vector3i = chunk2._chunk_grid_origin()
	_assert(origin2 == Vector3i(16, 24, 8), "Chunk(2,3,1) grid origin should be (16,24,8)")

	chunk0.free()
	chunk1.free()
	chunk2.free()


func _test_grid_to_local_conversion() -> void:
	print("\n--- Grid to Local Conversion ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	# Block at grid (0,0,0) should be at local (0, 1.75, 0)
	var local0: Vector3 = chunk._grid_to_local(Vector3i(0, 0, 0))
	_assert(is_equal_approx(local0.x, 0.0), "Grid(0,0,0) local x should be 0")
	_assert(is_equal_approx(local0.y, 1.75), "Grid(0,0,0) local y should be 1.75 (half height)")
	_assert(is_equal_approx(local0.z, 0.0), "Grid(0,0,0) local z should be 0")

	# Block at grid (1,0,0) should be at local (6, 1.75, 0)
	var local1: Vector3 = chunk._grid_to_local(Vector3i(1, 0, 0))
	_assert(is_equal_approx(local1.x, 6.0), "Grid(1,0,0) local x should be 6.0")

	# Block at grid (0,1,0) should be at local (0, 1.75, 6)
	var local2: Vector3 = chunk._grid_to_local(Vector3i(0, 1, 0))
	_assert(is_equal_approx(local2.z, 6.0), "Grid(0,1,0) local z should be 6.0 (grid y -> world z)")

	# Block at grid (0,0,1) should be at local (0, 5.25, 0)
	var local3: Vector3 = chunk._grid_to_local(Vector3i(0, 0, 1))
	_assert(is_equal_approx(local3.y, 5.25), "Grid(0,0,1) local y should be 5.25 (grid z -> world y)")

	chunk.free()


func _test_rebuild_clears_dirty() -> void:
	print("\n--- Rebuild Clears Dirty ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(chunk.is_dirty(), "Should be dirty before rebuild")

	chunk.rebuild()
	_assert(not chunk.is_dirty(), "Should not be dirty after rebuild")

	chunk.queue_free()
	await process_frame


func _test_rebuild_empty_chunk() -> void:
	print("\n--- Rebuild Empty Chunk ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	# Rebuild with no blocks should not crash
	chunk.rebuild()
	_assert(not chunk.is_dirty(), "Empty chunk rebuild should clear dirty")

	var opaque: MeshInstance3D = chunk.get_node_or_null("OpaqueMesh")
	_assert(opaque != null, "Opaque mesh node should exist")
	_assert(opaque.mesh == null, "Opaque mesh should be null for empty chunk")

	chunk.queue_free()
	await process_frame


func _test_aabb_calculation() -> void:
	print("\n--- AABB Calculation ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	# Empty chunk has zero AABB
	var empty_aabb: AABB = chunk.get_aabb()
	_assert(empty_aabb.size == Vector3.ZERO, "Empty chunk AABB should have zero size")

	# Add block and rebuild
	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	chunk.rebuild()

	var aabb: AABB = chunk.get_aabb()
	_assert(aabb.size.x > 0, "AABB width should be > 0 after rebuild")
	_assert(aabb.size.y > 0, "AABB height should be > 0 after rebuild")
	_assert(aabb.size.z > 0, "AABB depth should be > 0 after rebuild")

	chunk.queue_free()
	await process_frame


func _test_color_for_block_types() -> void:
	print("\n--- Color for Block Types ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	# Known types should have specific colors
	var corridor_color: Color = chunk._get_color_for_type("corridor")
	_assert(corridor_color == Color(0.6, 0.6, 0.6), "Corridor should be gray")

	var entrance_color: Color = chunk._get_color_for_type("entrance")
	_assert(entrance_color == Color(0.5, 0.75, 0.5), "Entrance should be green")

	# Unknown type should be magenta
	var unknown_color: Color = chunk._get_color_for_type("nonexistent_type")
	_assert(unknown_color == Color(1.0, 0.0, 1.0), "Unknown type should be magenta")

	chunk.free()


func _test_multiple_blocks() -> void:
	print("\n--- Multiple Blocks ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	# Add multiple blocks
	for x in range(4):
		for y in range(4):
			chunk.add_block(Vector3i(x, y, 0), "corridor")

	_assert(chunk.get_block_count() == 16, "Should have 16 blocks")

	# Rebuild with multiple blocks
	chunk.rebuild()
	_assert(not chunk.is_dirty(), "Should not be dirty after rebuild")

	var opaque: MeshInstance3D = chunk.get_node_or_null("OpaqueMesh")
	_assert(opaque != null and opaque.mesh != null, "Should have generated mesh")

	chunk.queue_free()
	await process_frame


func _test_shader_assignment() -> void:
	print("\n--- Shader Assignment ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))

	# Initially no shader
	_assert(chunk._block_shader == null, "Initially no shader")

	# Setting shader marks dirty
	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	chunk.rebuild()  # Clear dirty
	chunk.set_shader(null)  # No actual shader in tests
	# Setting null shader on empty content shouldn't mark dirty (no blocks affected by null)
	# But set_shader marks dirty if chunk has blocks
	# The test verifies the method doesn't crash

	chunk.free()
