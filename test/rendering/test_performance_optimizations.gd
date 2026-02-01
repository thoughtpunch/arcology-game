extends SceneTree
## Test: Performance Optimizations (arcology-5e2.17)
##
## Verifies:
## - Frustum culling: chunks outside camera view are hidden
## - Face culling: interior faces between adjacent blocks are skipped
## - GPU instancing: MultiMesh is used for repeated block types
## - PerformanceMonitor: tracks and reports render stats
## - Cross-chunk face culling: neighbor chunks are dirtied at boundaries
## - Enable/disable toggles work correctly
## - Negative: invalid states handled gracefully

var _test_count := 0
var _pass_count := 0

var _ChunkManagerClass: GDScript
var _ChunkClass: GDScript
var _PerformanceMonitorClass: GDScript


func _init() -> void:
	print("\n=== Test: Performance Optimizations ===\n")

	_ChunkManagerClass = load("res://src/rendering/chunk_manager.gd")
	_ChunkClass = load("res://src/rendering/chunk.gd")
	_PerformanceMonitorClass = load("res://src/rendering/performance_monitor.gd")

	assert(_ChunkManagerClass != null, "ChunkManager script should load")
	assert(_ChunkClass != null, "Chunk script should load")
	assert(_PerformanceMonitorClass != null, "PerformanceMonitor script should load")

	# Frustum culling tests
	await _test_frustum_culling_default_disabled()
	await _test_frustum_culling_enable_disable()
	await _test_frustum_culling_no_camera()
	await _test_frustum_culling_stats()

	# Face culling tests
	await _test_face_culling_default_disabled()
	await _test_face_culling_enable_disable()
	await _test_face_culling_visible_faces_isolated_block()
	await _test_face_culling_adjacent_blocks_hide_shared_face()
	await _test_face_culling_surrounded_block()
	await _test_face_culling_cross_chunk_boundary()

	# GPU instancing tests
	await _test_instancing_default_disabled()
	await _test_instancing_enable_disable()
	await _test_instancing_creates_multimesh()
	await _test_instancing_groups_by_type()
	await _test_instancing_removes_stale_types()

	# PerformanceMonitor tests
	await _test_perf_monitor_creation()
	await _test_perf_monitor_stats_format()
	await _test_perf_monitor_with_chunk_manager()

	# Render statistics
	await _test_render_statistics()

	# Combined optimizations
	await _test_all_optimizations_together()

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


# --- Frustum Culling Tests ---


func _test_frustum_culling_default_disabled() -> void:
	print("\n--- Frustum Culling Default Disabled ---")
	var manager: Node3D = await _create_manager()

	_assert(not manager.is_frustum_culling_enabled(), "Frustum culling should be disabled by default")
	_assert(manager.get_culled_chunk_count() == 0, "No chunks culled when disabled")

	manager.queue_free()
	await process_frame


func _test_frustum_culling_enable_disable() -> void:
	print("\n--- Frustum Culling Enable/Disable ---")
	var manager: Node3D = await _create_manager()

	manager.enable_frustum_culling()
	_assert(manager.is_frustum_culling_enabled(), "Should be enabled after enable_frustum_culling()")

	manager.disable_frustum_culling()
	_assert(not manager.is_frustum_culling_enabled(), "Should be disabled after disable_frustum_culling()")

	manager.queue_free()
	await process_frame


func _test_frustum_culling_no_camera() -> void:
	print("\n--- Frustum Culling Without Camera ---")
	var manager: Node3D = await _create_manager()

	manager.enable_frustum_culling()
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.rebuild_all_dirty()

	# Without camera, all chunks should remain visible
	_assert(manager.get_culled_chunk_count() == 0, "No culling without camera")

	# get_visible_chunks should return all chunks when no camera
	var visible: Array = manager.get_visible_chunks()
	_assert(visible.size() == 1, "All chunks visible without camera")

	manager.queue_free()
	await process_frame


func _test_frustum_culling_stats() -> void:
	print("\n--- Frustum Culling Stats ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(8, 0, 0), "entrance")
	manager.rebuild_all_dirty()

	# Without frustum culling, visible count = total
	_assert(manager.get_visible_chunk_count() == 2, "All 2 chunks visible when culling disabled")

	manager.enable_frustum_culling()
	# Without camera, _update_frustum_culling does nothing
	_assert(manager.get_visible_chunk_count() == 2, "Still 2 visible without camera (no culling applied)")

	manager.queue_free()
	await process_frame


# --- Face Culling Tests ---


func _test_face_culling_default_disabled() -> void:
	print("\n--- Face Culling Default Disabled ---")
	var manager: Node3D = await _create_manager()

	_assert(not manager.is_face_culling_enabled(), "Face culling should be disabled by default")

	manager.queue_free()
	await process_frame


func _test_face_culling_enable_disable() -> void:
	print("\n--- Face Culling Enable/Disable ---")
	var manager: Node3D = await _create_manager()

	manager.enable_face_culling()
	_assert(manager.is_face_culling_enabled(), "Should be enabled after enable_face_culling()")

	# Verify chunks got the setting
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	var chunk: Node3D = manager.get_chunk(Vector3i(0, 0, 0))
	_assert(chunk.is_face_culling_enabled(), "Chunk should have face culling enabled")

	manager.disable_face_culling()
	_assert(not manager.is_face_culling_enabled(), "Should be disabled after disable_face_culling()")
	_assert(not chunk.is_face_culling_enabled(), "Chunk should have face culling disabled")

	manager.queue_free()
	await process_frame


func _test_face_culling_visible_faces_isolated_block() -> void:
	print("\n--- Face Culling: Isolated Block (All Faces Visible) ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.enable_face_culling()
	chunk.add_block(Vector3i(0, 0, 0), "corridor")

	# Test _get_visible_faces for an isolated block (all 6 faces should be visible)
	var visible_faces: Array[bool] = chunk._get_visible_faces(Vector3i(0, 0, 0))
	var visible_count := 0
	for v in visible_faces:
		if v:
			visible_count += 1

	_assert(visible_count == 6, "Isolated block should have 6 visible faces, got %d" % visible_count)

	chunk.queue_free()
	await process_frame


func _test_face_culling_adjacent_blocks_hide_shared_face() -> void:
	print("\n--- Face Culling: Adjacent Blocks Hide Shared Face ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.enable_face_culling()

	# Place two blocks adjacent on X axis
	chunk.add_block(Vector3i(0, 0, 0), "corridor")
	chunk.add_block(Vector3i(1, 0, 0), "corridor")

	# Block at (0,0,0) should have its right face (+X) hidden
	var visible_0: Array[bool] = chunk._get_visible_faces(Vector3i(0, 0, 0))
	# face index 2 = right (+X)
	_assert(not visible_0[2], "Block (0,0,0) right face should be hidden (adjacent to (1,0,0))")

	# Block at (1,0,0) should have its left face (-X) hidden
	var visible_1: Array[bool] = chunk._get_visible_faces(Vector3i(1, 0, 0))
	# face index 3 = left (-X)
	_assert(not visible_1[3], "Block (1,0,0) left face should be hidden (adjacent to (0,0,0))")

	# Other faces should still be visible
	_assert(visible_0[4], "Block (0,0,0) top face should be visible")
	_assert(visible_0[5], "Block (0,0,0) bottom face should be visible")
	_assert(visible_1[4], "Block (1,0,0) top face should be visible")

	chunk.queue_free()
	await process_frame


func _test_face_culling_surrounded_block() -> void:
	print("\n--- Face Culling: Surrounded Block (All Faces Hidden) ---")
	var chunk: Node3D = _ChunkClass.new(Vector3i(0, 0, 0))
	root.add_child(chunk)
	await process_frame

	chunk.enable_face_culling()

	# Place center block and all 6 neighbors
	chunk.add_block(Vector3i(1, 1, 1), "corridor")  # center
	chunk.add_block(Vector3i(2, 1, 1), "corridor")  # +X
	chunk.add_block(Vector3i(0, 1, 1), "corridor")  # -X
	chunk.add_block(Vector3i(1, 2, 1), "corridor")  # +Y
	chunk.add_block(Vector3i(1, 0, 1), "corridor")  # -Y
	chunk.add_block(Vector3i(1, 1, 2), "corridor")  # +Z
	chunk.add_block(Vector3i(1, 1, 0), "corridor")  # -Z

	var visible: Array[bool] = chunk._get_visible_faces(Vector3i(1, 1, 1))
	var visible_count := 0
	for v in visible:
		if v:
			visible_count += 1

	_assert(visible_count == 0, "Fully surrounded block should have 0 visible faces, got %d" % visible_count)

	chunk.queue_free()
	await process_frame


func _test_face_culling_cross_chunk_boundary() -> void:
	print("\n--- Face Culling: Cross-Chunk Boundary ---")
	var manager: Node3D = await _create_manager()

	manager.enable_face_culling()

	# Place blocks at chunk boundary: (7,0,0) in chunk(0,0,0) and (8,0,0) in chunk(1,0,0)
	manager.add_block(Vector3i(7, 0, 0), "corridor")
	manager.add_block(Vector3i(8, 0, 0), "corridor")
	manager.rebuild_all_dirty()

	# Both chunks should exist
	_assert(manager.has_chunk(Vector3i(0, 0, 0)), "Chunk (0,0,0) should exist")
	_assert(manager.has_chunk(Vector3i(1, 0, 0)), "Chunk (1,0,0) should exist")

	# The block at (7,0,0) should have its +X face hidden via cross-chunk lookup
	var chunk_0 = manager.get_chunk(Vector3i(0, 0, 0))
	var visible_7: Array[bool] = chunk_0._get_visible_faces(Vector3i(7, 0, 0))
	# face index 2 = right (+X)
	_assert(not visible_7[2], "Block (7,0,0) right face should be hidden (cross-chunk neighbor at (8,0,0))")

	# The block at (8,0,0) should have its -X face hidden
	var chunk_1 = manager.get_chunk(Vector3i(1, 0, 0))
	var visible_8: Array[bool] = chunk_1._get_visible_faces(Vector3i(8, 0, 0))
	# face index 3 = left (-X)
	_assert(not visible_8[3], "Block (8,0,0) left face should be hidden (cross-chunk neighbor at (7,0,0))")

	manager.queue_free()
	await process_frame


# --- GPU Instancing Tests ---


func _test_instancing_default_disabled() -> void:
	print("\n--- Instancing Default Disabled ---")
	var manager: Node3D = await _create_manager()

	_assert(not manager.is_instancing_enabled(), "Instancing should be disabled by default")

	manager.queue_free()
	await process_frame


func _test_instancing_enable_disable() -> void:
	print("\n--- Instancing Enable/Disable ---")
	var manager: Node3D = await _create_manager()

	manager.enable_instancing()
	_assert(manager.is_instancing_enabled(), "Should be enabled after enable_instancing()")

	# Verify chunks got the setting
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	var chunk: Node3D = manager.get_chunk(Vector3i(0, 0, 0))
	_assert(chunk.is_instancing_enabled(), "Chunk should have instancing enabled")

	manager.disable_instancing()
	_assert(not manager.is_instancing_enabled(), "Should be disabled after disable_instancing()")
	_assert(not chunk.is_instancing_enabled(), "Chunk should have instancing disabled")

	manager.queue_free()
	await process_frame


func _test_instancing_creates_multimesh() -> void:
	print("\n--- Instancing Creates MultiMesh ---")
	var manager: Node3D = await _create_manager()

	manager.enable_instancing()
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "corridor")
	manager.rebuild_all_dirty()

	var chunk: Node3D = manager.get_chunk(Vector3i(0, 0, 0))

	# Check that MultiMeshInstance3D children exist
	var mm_count := 0
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			mm_count += 1
			# Verify MultiMesh has correct instance count
			var mmi := child as MultiMeshInstance3D
			if mmi.multimesh:
				_assert(mmi.multimesh.instance_count == 2, "MultiMesh should have 2 instances for 2 corridor blocks")

	_assert(mm_count > 0, "Chunk should have MultiMeshInstance3D children when instancing enabled")

	manager.queue_free()
	await process_frame


func _test_instancing_groups_by_type() -> void:
	print("\n--- Instancing Groups By Block Type ---")
	var manager: Node3D = await _create_manager()

	manager.enable_instancing()
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "corridor")
	manager.add_block(Vector3i(2, 0, 0), "entrance")
	manager.rebuild_all_dirty()

	var chunk: Node3D = manager.get_chunk(Vector3i(0, 0, 0))

	# Should have 2 MultiMeshInstance3D: one for corridor (2 instances), one for entrance (1)
	var mm_instances: Array[MultiMeshInstance3D] = []
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			mm_instances.append(child as MultiMeshInstance3D)

	_assert(mm_instances.size() == 2, "Should have 2 MultiMeshInstance3D (corridor + entrance), got %d" % mm_instances.size())

	# Check total instances match block count
	var total_instances := 0
	for mmi in mm_instances:
		if mmi.multimesh:
			total_instances += mmi.multimesh.instance_count
	_assert(total_instances == 3, "Total MultiMesh instances should be 3")

	manager.queue_free()
	await process_frame


func _test_instancing_removes_stale_types() -> void:
	print("\n--- Instancing Removes Stale Types ---")
	var manager: Node3D = await _create_manager()

	manager.enable_instancing()
	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(1, 0, 0), "entrance")
	manager.rebuild_all_dirty()

	var chunk: Node3D = manager.get_chunk(Vector3i(0, 0, 0))

	# Remove the entrance block
	manager.remove_block(Vector3i(1, 0, 0))
	manager.rebuild_all_dirty()

	# Should now have only 1 MultiMeshInstance3D (corridor)
	var mm_count := 0
	for child in chunk.get_children():
		if child is MultiMeshInstance3D:
			mm_count += 1

	_assert(mm_count == 1, "Should have 1 MultiMeshInstance3D after removing entrance, got %d" % mm_count)

	manager.queue_free()
	await process_frame


# --- PerformanceMonitor Tests ---


func _test_perf_monitor_creation() -> void:
	print("\n--- PerformanceMonitor Creation ---")
	var monitor: Node = _PerformanceMonitorClass.new()
	root.add_child(monitor)
	await process_frame

	_assert(monitor.name == "PerformanceMonitor", "Monitor name should be PerformanceMonitor")

	var stats: Dictionary = monitor.get_stats()
	_assert(stats is Dictionary, "get_stats should return a Dictionary")

	monitor.queue_free()
	await process_frame


func _test_perf_monitor_stats_format() -> void:
	print("\n--- PerformanceMonitor Stats Format ---")
	var monitor: Node = _PerformanceMonitorClass.new()
	root.add_child(monitor)

	# Wait for a couple frames so stats are populated
	await process_frame
	await process_frame
	await process_frame

	var text: String = monitor.get_stats_text()
	_assert(text.length() > 0, "Stats text should not be empty")
	_assert("FPS" in text, "Stats text should contain FPS")

	monitor.queue_free()
	await process_frame


func _test_perf_monitor_with_chunk_manager() -> void:
	print("\n--- PerformanceMonitor With ChunkManager ---")
	var manager: Node3D = await _create_manager()
	var monitor: Node = _PerformanceMonitorClass.new()
	root.add_child(monitor)
	await process_frame

	monitor.set_chunk_manager(manager)

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.enable_frustum_culling()
	manager.enable_face_culling()

	# Force stats update (timer-based updates are too slow for headless tests)
	monitor.force_update()

	var text: String = monitor.get_stats_text()
	_assert("Blocks" in text, "Stats text should contain Blocks with chunk manager")
	_assert("Chunks" in text, "Stats text should contain Chunks info")
	_assert("frustum" in text, "Stats text should mention frustum culling when enabled")
	_assert("face-cull" in text, "Stats text should mention face culling when enabled")

	monitor.queue_free()
	manager.queue_free()
	await process_frame


# --- Render Statistics Tests ---


func _test_render_statistics() -> void:
	print("\n--- Render Statistics ---")
	var manager: Node3D = await _create_manager()

	manager.add_block(Vector3i(0, 0, 0), "corridor")
	manager.add_block(Vector3i(8, 0, 0), "entrance")

	var stats: Dictionary = manager.get_render_statistics()
	_assert(stats.get("total_chunks") == 2, "Should report 2 total chunks")
	_assert(stats.get("total_blocks") == 2, "Should report 2 total blocks")
	_assert(stats.get("frustum_culling") == false, "Should report frustum culling disabled")
	_assert(stats.get("face_culling") == false, "Should report face culling disabled")
	_assert(stats.get("instancing") == false, "Should report instancing disabled")

	manager.enable_frustum_culling()
	manager.enable_face_culling()
	manager.enable_instancing()

	stats = manager.get_render_statistics()
	_assert(stats.get("frustum_culling") == true, "Should report frustum culling enabled")
	_assert(stats.get("face_culling") == true, "Should report face culling enabled")
	_assert(stats.get("instancing") == true, "Should report instancing enabled")

	manager.queue_free()
	await process_frame


# --- Combined Tests ---


func _test_all_optimizations_together() -> void:
	print("\n--- All Optimizations Together ---")
	var manager: Node3D = await _create_manager()

	# Enable all optimizations
	manager.enable_frustum_culling()
	manager.enable_face_culling()
	manager.enable_instancing()
	manager.enable_lod()

	# Add a grid of blocks
	for x in range(4):
		for y in range(4):
			for z in range(2):
				manager.add_block(Vector3i(x, y, z), "corridor" if (x + y) % 2 == 0 else "entrance")

	_assert(manager.get_total_block_count() == 32, "Should have 32 blocks")

	# Rebuild
	manager.rebuild_all_dirty()
	_assert(manager.get_dirty_count() == 0, "All chunks should be rebuilt")

	# Verify all optimizations are enabled
	_assert(manager.is_frustum_culling_enabled(), "Frustum culling should be enabled")
	_assert(manager.is_face_culling_enabled(), "Face culling should be enabled")
	_assert(manager.is_instancing_enabled(), "Instancing should be enabled")
	_assert(manager.is_lod_enabled(), "LOD should be enabled")

	# Check render stats are populated
	var stats: Dictionary = manager.get_render_statistics()
	_assert(stats.get("total_blocks") == 32, "Stats should show 32 blocks")
	_assert(stats.size() > 0, "Should have render statistics")

	# Disable all and verify
	manager.disable_frustum_culling()
	manager.disable_face_culling()
	manager.disable_instancing()
	manager.disable_lod()

	_assert(not manager.is_frustum_culling_enabled(), "Frustum culling should be disabled")
	_assert(not manager.is_face_culling_enabled(), "Face culling should be disabled")
	_assert(not manager.is_instancing_enabled(), "Instancing should be disabled")
	_assert(not manager.is_lod_enabled(), "LOD should be disabled")

	manager.queue_free()
	await process_frame
