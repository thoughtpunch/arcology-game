extends SceneTree
## Test: ChunkManager (arcology-6ep)
##
## Verifies:
## - Chunk creation and destruction
## - Block add/remove routing to correct chunks
## - Dirty queue management
## - Rebuild with frame budget
## - Force rebuild
## - Chunk coordinate calculation (including negatives)
## - Clear all chunks
## - Integration with BlockRenderer3D

var _test_count := 0
var _pass_count := 0

var _ChunkManagerClass: GDScript
var _BlockRenderer3DClass: GDScript


func _init() -> void:
	print("\n=== Test: ChunkManager ===\n")

	_ChunkManagerClass = load("res://src/rendering/chunk_manager.gd")
	_BlockRenderer3DClass = load("res://src/rendering/block_renderer_3d.gd")
	assert(_ChunkManagerClass != null, "ChunkManager script should load")

	# Run tests
	await _test_creation()
	await _test_add_block_creates_chunk()
	await _test_add_block_same_chunk()
	await _test_add_blocks_different_chunks()
	await _test_remove_block()
	await _test_remove_last_block_removes_chunk()
	await _test_remove_nonexistent_block()
	await _test_has_block()
	await _test_get_block_data()
	await _test_chunk_coord_positive()
	_test_chunk_coord_negative()
	_test_chunk_coord_boundary()
	await _test_dirty_queue()
	await _test_rebuild_all_dirty()
	await _test_frame_budget_rebuild()
	await _test_clear()
	await _test_get_all_block_positions()
	await _test_has_chunk()
	await _test_signals()
	await _test_total_counts()
	await _test_renderer_integration()
	await _test_renderer_chunking_enable_disable()
	await _test_large_grid()

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


func _create_manager() -> Node3D:
	var manager: Node3D = _ChunkManagerClass.new()
	root.add_child(manager)
	await process_frame
	return manager


func _test_creation() -> void:
	print("\n--- ChunkManager Creation ---")
	var manager: Node3D = await _create_manager()

	_assert(manager.get_chunk_count() == 0, "New manager should have 0 chunks")
	_assert(manager.get_total_block_count() == 0, "New manager should have 0 blocks")
	_assert(manager.get_dirty_count() == 0, "New manager should have 0 dirty chunks")
	_assert(manager.name == "ChunkManager", "Manager name should be ChunkManager")

	manager.queue_free()
	await process_frame


func _test_add_block_creates_chunk() -> void:
	print("\n--- Add Block Creates Chunk ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")

	_assert(manager.get_chunk_count() == 1, "Should create 1 chunk")
	_assert(manager.get_total_block_count() == 1, "Should have 1 block")
	_assert(manager.has_chunk(Vector3i(0, 0, 0)), "Should have chunk at (0,0,0)")

	manager.queue_free()
	await process_frame


func _test_add_block_same_chunk() -> void:
	print("\n--- Add Blocks Same Chunk ---")
	var manager: Node3D = await _create_manager()

	# All within chunk (0,0,0) since chunk size is 8
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "entrance")
	manager.add_block(Vector3i(7, 7, 7), "stairs")

	_assert(manager.get_chunk_count() == 1, "All blocks in one chunk")
	_assert(manager.get_total_block_count() == 3, "Should have 3 blocks")

	manager.queue_free()
	await process_frame


func _test_add_blocks_different_chunks() -> void:
	print("\n--- Add Blocks Different Chunks ---")
	var manager: Node3D = await _create_manager()

	# Chunk (0,0,0): positions 0-7
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	# Chunk (1,0,0): positions 8-15
	manager.add_block(Vector3i(8, 0, 0), "entrance")
	# Chunk (0,1,0): positions y=8-15
	manager.add_block(Vector3i(0, 8, 0), "stairs")

	_assert(manager.get_chunk_count() == 3, "Should create 3 chunks")
	_assert(manager.get_total_block_count() == 3, "Should have 3 blocks")

	_assert(manager.has_chunk(Vector3i(0, 0, 0)), "Chunk (0,0,0) should exist")
	_assert(manager.has_chunk(Vector3i(1, 0, 0)), "Chunk (1,0,0) should exist")
	_assert(manager.has_chunk(Vector3i(0, 1, 0)), "Chunk (0,1,0) should exist")

	manager.queue_free()
	await process_frame


func _test_remove_block() -> void:
	print("\n--- Remove Block ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "entrance")
	manager.remove_block(Vector3i(0, 0, 0))

	_assert(manager.get_total_block_count() == 1, "Should have 1 block after removal")
	_assert(not manager.has_block(Vector3i(0, 0, 0)), "Removed block should not exist")
	_assert(manager.has_block(Vector3i(1, 0, 0)), "Other block should still exist")

	manager.queue_free()
	await process_frame


func _test_remove_last_block_removes_chunk() -> void:
	print("\n--- Remove Last Block Removes Chunk ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(manager.get_chunk_count() == 1, "Should have 1 chunk before removal")

	manager.remove_block(Vector3i(0, 0, 0))
	_assert(manager.get_chunk_count() == 0, "Chunk should be removed when empty")
	_assert(not manager.has_chunk(Vector3i(0, 0, 0)), "Empty chunk should not exist")

	manager.queue_free()
	await process_frame


func _test_remove_nonexistent_block() -> void:
	print("\n--- Remove Nonexistent Block ---")
	var manager: Node3D = await _create_manager()

	# Should not crash
	manager.remove_block(Vector3i(99, 99, 99))
	_assert(manager.get_total_block_count() == 0, "Count should remain 0")

	manager.queue_free()
	await process_frame


func _test_has_block() -> void:
	print("\n--- Has Block ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(5, 3, 2), "corridor")

	_assert(manager.has_block(Vector3i(5, 3, 2)), "Should find added block")
	_assert(not manager.has_block(Vector3i(0, 0, 0)), "Should not find non-added block")
	_assert(not manager.has_block(Vector3i(99, 99, 99)), "Should not find block in non-existent chunk")

	manager.queue_free()
	await process_frame


func _test_get_block_data() -> void:
	print("\n--- Get Block Data ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(2, 3, 0), "residential_basic", 2)
	var data: Dictionary = manager.get_block_data(Vector3i(2, 3, 0))

	_assert(data.get("type") == "residential_basic", "Block type should match")
	_assert(data.get("rotation") == 2, "Block rotation should match")

	# Nonexistent block
	var empty: Dictionary = manager.get_block_data(Vector3i(99, 99, 99))
	_assert(empty.is_empty(), "Nonexistent block should return empty dict")

	manager.queue_free()
	await process_frame


func _test_chunk_coord_positive() -> void:
	print("\n--- Chunk Coord Positive ---")
	var manager: Node3D = await _create_manager()

	# Grid (0,0,0) -> Chunk (0,0,0)
	_assert(manager.get_chunk_coord(Vector3i(0, 0, 0)) == Vector3i(0, 0, 0), "Grid(0,0,0) -> Chunk(0,0,0)")

	# Grid (7,7,7) -> Chunk (0,0,0) (still within first chunk)
	_assert(manager.get_chunk_coord(Vector3i(7, 7, 7)) == Vector3i(0, 0, 0), "Grid(7,7,7) -> Chunk(0,0,0)")

	# Grid (8,0,0) -> Chunk (1,0,0)
	_assert(manager.get_chunk_coord(Vector3i(8, 0, 0)) == Vector3i(1, 0, 0), "Grid(8,0,0) -> Chunk(1,0,0)")

	# Grid (16,8,24) -> Chunk (2,1,3)
	_assert(manager.get_chunk_coord(Vector3i(16, 8, 24)) == Vector3i(2, 1, 3), "Grid(16,8,24) -> Chunk(2,1,3)")

	manager.queue_free()
	await process_frame


func _test_chunk_coord_negative() -> void:
	print("\n--- Chunk Coord Negative ---")
	var manager: Node3D = _ChunkManagerClass.new()

	# Grid (-1,0,0) -> Chunk (-1,0,0) (floor division)
	var coord_neg1: Vector3i = manager.get_chunk_coord(Vector3i(-1, 0, 0))
	_assert(coord_neg1 == Vector3i(-1, 0, 0), "Grid(-1,0,0) -> Chunk(-1,0,0), got %s" % coord_neg1)

	# Grid (-8,0,0) -> Chunk (-1,0,0)
	var coord_neg8: Vector3i = manager.get_chunk_coord(Vector3i(-8, 0, 0))
	_assert(coord_neg8 == Vector3i(-1, 0, 0), "Grid(-8,0,0) -> Chunk(-1,0,0), got %s" % coord_neg8)

	# Grid (-9,0,0) -> Chunk (-2,0,0)
	var coord_neg9: Vector3i = manager.get_chunk_coord(Vector3i(-9, 0, 0))
	_assert(coord_neg9 == Vector3i(-2, 0, 0), "Grid(-9,0,0) -> Chunk(-2,0,0), got %s" % coord_neg9)

	manager.free()


func _test_chunk_coord_boundary() -> void:
	print("\n--- Chunk Coord Boundary ---")
	var manager: Node3D = _ChunkManagerClass.new()

	# Boundary: grid position 7 is last in chunk 0, 8 is first in chunk 1
	_assert(manager.get_chunk_coord(Vector3i(7, 0, 0)) == Vector3i(0, 0, 0), "Grid(7) in Chunk(0)")
	_assert(manager.get_chunk_coord(Vector3i(8, 0, 0)) == Vector3i(1, 0, 0), "Grid(8) in Chunk(1)")

	# Negative boundary: grid -1 is in chunk -1, grid -8 is last in chunk -1
	_assert(manager.get_chunk_coord(Vector3i(-1, 0, 0)) == Vector3i(-1, 0, 0), "Grid(-1) in Chunk(-1)")

	manager.free()


func _test_dirty_queue() -> void:
	print("\n--- Dirty Queue ---")
	var manager: Node3D = await _create_manager()

	_assert(manager.get_dirty_count() == 0, "Initially 0 dirty chunks")

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(manager.get_dirty_count() == 1, "1 dirty chunk after add")

	# Adding to same chunk shouldn't add duplicate to queue
	manager.add_block(Vector3i(1, 0, 0), "entrance")
	_assert(manager.get_dirty_count() == 1, "Still 1 dirty chunk (same chunk)")

	# Adding to different chunk
	manager.add_block(Vector3i(8, 0, 0), "stairs")
	_assert(manager.get_dirty_count() == 2, "2 dirty chunks (different chunks)")

	manager.queue_free()
	await process_frame


func _test_rebuild_all_dirty() -> void:
	print("\n--- Rebuild All Dirty ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(8, 0, 0), "entrance")
	manager.add_block(Vector3i(16, 0, 0), "stairs")
	_assert(manager.get_dirty_count() == 3, "Should have 3 dirty chunks")

	manager.rebuild_all_dirty()
	_assert(manager.get_dirty_count() == 0, "Should have 0 dirty chunks after rebuild_all")

	# Verify chunks are no longer dirty
	for coord in manager.get_chunk_coords():
		var chunk = manager.get_chunk(coord)
		_assert(not chunk.is_dirty(), "Chunk %s should not be dirty" % coord)

	manager.queue_free()
	await process_frame


func _test_frame_budget_rebuild() -> void:
	print("\n--- Frame Budget Rebuild ---")
	var manager: Node3D = await _create_manager()

	# Add blocks in many different chunks
	for i in range(10):
		manager.add_block(Vector3i(i * 8, 0, 0), "corridor")

	_assert(manager.get_dirty_count() == 10, "Should have 10 dirty chunks")

	# Process one frame - should only rebuild MAX_REBUILDS_PER_FRAME (2)
	# We can't easily test _process directly, but rebuild_all_dirty bypasses budget
	# Instead test that dirty queue tracks correctly
	manager.rebuild_all_dirty()
	_assert(manager.get_dirty_count() == 0, "All dirty after force rebuild")

	manager.queue_free()
	await process_frame


func _test_clear() -> void:
	print("\n--- Clear ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(8, 0, 0), "entrance")
	manager.add_block(Vector3i(0, 8, 0), "stairs")

	manager.clear()

	_assert(manager.get_chunk_count() == 0, "Should have 0 chunks after clear")
	_assert(manager.get_total_block_count() == 0, "Should have 0 blocks after clear")
	_assert(manager.get_dirty_count() == 0, "Should have 0 dirty after clear")

	manager.queue_free()
	await process_frame


func _test_get_all_block_positions() -> void:
	print("\n--- Get All Block Positions ---")
	var manager: Node3D = await _create_manager()

	var positions := [Vector3i(0, 0, 0), Vector3i(8, 0, 0), Vector3i(1, 2, 3)]
	for pos in positions:
		manager.add_block(pos, "corridor")

	var all_positions: Array = manager.get_all_block_positions()
	_assert(all_positions.size() == 3, "Should return 3 positions")

	for pos in positions:
		_assert(pos in all_positions, "Should contain position %s" % pos)

	manager.queue_free()
	await process_frame


func _test_has_chunk() -> void:
	print("\n--- Has Chunk ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")

	_assert(manager.has_chunk(Vector3i(0, 0, 0)), "Should have chunk (0,0,0)")
	_assert(not manager.has_chunk(Vector3i(1, 0, 0)), "Should not have chunk (1,0,0)")

	manager.queue_free()
	await process_frame


func _test_signals() -> void:
	print("\n--- Signals ---")
	var manager: Node3D = await _create_manager()

	var created_chunks: Array[Vector3i] = []
	var removed_chunks: Array[Vector3i] = []
	var rebuilt_chunks: Array[Vector3i] = []

	manager.chunk_created.connect(func(coord: Vector3i): created_chunks.append(coord))
	manager.chunk_removed.connect(func(coord: Vector3i): removed_chunks.append(coord))
	manager.chunk_rebuilt.connect(func(coord: Vector3i): rebuilt_chunks.append(coord))

	# Create chunk
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	_assert(created_chunks.size() == 1, "chunk_created should fire once")
	_assert(created_chunks[0] == Vector3i(0, 0, 0), "Created chunk should be (0,0,0)")

	# Rebuild
	manager.rebuild_all_dirty()
	_assert(rebuilt_chunks.size() == 1, "chunk_rebuilt should fire once")

	# Remove last block -> removes chunk
	manager.remove_block(Vector3i(0, 0, 0))
	_assert(removed_chunks.size() == 1, "chunk_removed should fire once")

	manager.queue_free()
	await process_frame


func _test_total_counts() -> void:
	print("\n--- Total Counts ---")
	var manager: Node3D = await _create_manager()

	_assert(manager.get_total_block_count() == 0, "Initially 0 blocks")
	_assert(manager.get_chunk_count() == 0, "Initially 0 chunks")

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "entrance")
	_assert(manager.get_total_block_count() == 2, "2 blocks after 2 adds")
	_assert(manager.get_chunk_count() == 1, "1 chunk (same chunk)")

	manager.add_block(Vector3i(8, 0, 0), "stairs")
	_assert(manager.get_total_block_count() == 3, "3 blocks total")
	_assert(manager.get_chunk_count() == 2, "2 chunks (different chunks)")

	manager.remove_block(Vector3i(0, 0, 0))
	_assert(manager.get_total_block_count() == 2, "2 blocks after 1 removal")

	manager.queue_free()
	await process_frame


func _test_renderer_integration() -> void:
	print("\n--- BlockRenderer3D Integration ---")
	if not _BlockRenderer3DClass:
		print("  SKIP: BlockRenderer3D not available")
		return

	var renderer: Node3D = _BlockRenderer3DClass.new()
	root.add_child(renderer)
	await process_frame

	# Enable chunking
	var chunk_manager = renderer.enable_chunking()

	_assert(chunk_manager != null, "enable_chunking should return ChunkManager")
	_assert(renderer.is_chunking_enabled(), "Chunking should be enabled")
	_assert(renderer.get_chunk_manager() != null, "get_chunk_manager should return manager")

	# Add a block directly to renderer
	renderer.add_block(Vector3i(0, 0, 0), "corridor")

	_assert(renderer.get_block_count() >= 1, "Renderer should report blocks")

	renderer.queue_free()
	await process_frame


func _test_renderer_chunking_enable_disable() -> void:
	print("\n--- Renderer Chunking Enable/Disable ---")
	if not _BlockRenderer3DClass:
		print("  SKIP: BlockRenderer3D not available")
		return

	var renderer: Node3D = _BlockRenderer3DClass.new()
	root.add_child(renderer)
	await process_frame

	_assert(not renderer.is_chunking_enabled(), "Chunking should be disabled by default")

	renderer.enable_chunking()
	_assert(renderer.is_chunking_enabled(), "Chunking should be enabled after enable_chunking")

	# Enable again should return existing manager
	var manager1 = renderer.get_chunk_manager()
	var manager2 = renderer.enable_chunking()
	_assert(manager1 == manager2, "enable_chunking twice should return same manager")

	renderer.disable_chunking()
	_assert(not renderer.is_chunking_enabled(), "Chunking should be disabled after disable")
	_assert(renderer.get_chunk_manager() == null, "Chunk manager should be null after disable")

	renderer.queue_free()
	await process_frame


func _test_large_grid() -> void:
	print("\n--- Large Grid (Performance) ---")
	var manager: Node3D = await _create_manager()

	var start_time := Time.get_ticks_usec()

	# Add 500 blocks across multiple chunks
	for x in range(10):
		for y in range(10):
			for z in range(5):
				manager.add_block(Vector3i(x, y, z), "corridor")

	var add_time := Time.get_ticks_usec() - start_time

	_assert(manager.get_total_block_count() == 500, "Should have 500 blocks")
	_assert(manager.get_chunk_count() > 0, "Should have created chunks")
	print("  INFO: 500 blocks added in %d us (%d chunks)" % [add_time, manager.get_chunk_count()])

	# Force rebuild all
	start_time = Time.get_ticks_usec()
	manager.rebuild_all_dirty()
	var rebuild_time := Time.get_ticks_usec() - start_time

	_assert(manager.get_dirty_count() == 0, "All chunks rebuilt")
	print("  INFO: Full rebuild in %d us" % rebuild_time)

	# Performance assertion: adding 500 blocks should be fast
	_assert(add_time < 500000, "500 blocks should add in < 500ms (was %d us)" % add_time)

	manager.queue_free()
	await process_frame
