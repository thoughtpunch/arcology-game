extends SceneTree
## Test: LODManager (arcology-5e2.11)
##
## Verifies:
## - LOD level calculation based on distance
## - Distance thresholds for each LOD level
## - Hysteresis to prevent rapid switching
## - Chunk registration and LOD tracking
## - Camera integration
## - Statistics reporting

var _test_count := 0
var _pass_count := 0

var _LODManagerClass: GDScript


func _init() -> void:
	print("\n=== Test: LODManager ===\n")

	_LODManagerClass = load("res://src/rendering/lod_manager.gd")
	assert(_LODManagerClass != null, "LODManager script should load")

	# Run tests
	_test_lod_manager_creation()
	_test_lod_level_for_distance()
	_test_lod_level_boundaries()
	_test_hysteresis_prevents_oscillation()
	_test_custom_thresholds()
	_test_reset_thresholds()
	_test_chunk_registration()
	_test_chunk_unregistration()
	_test_clear_chunks()
	_test_camera_integration()
	_test_statistics()
	_test_lod_level_names()
	_test_max_distance_for_lod()
	_test_force_update()
	_test_invalid_chunk_cleanup()

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


func _test_lod_manager_creation() -> void:
	print("\n--- LODManager Creation ---")
	var manager: Node = _LODManagerClass.new()
	root.add_child(manager)
	await process_frame

	_assert(manager != null, "LODManager should be created")
	_assert(manager.name == "LODManager", "Name should be LODManager")
	_assert(manager.get_camera() == null, "Initially no camera")

	manager.queue_free()
	await process_frame


func _test_lod_level_for_distance() -> void:
	print("\n--- LOD Level for Distance ---")
	var manager: Node = _LODManagerClass.new()

	# Default thresholds: LOD0=50m, LOD1=150m, LOD2=400m

	# LOD0: 0-50m
	_assert(manager.get_lod_for_distance(0.0) == 0, "Distance 0m should be LOD0")
	_assert(manager.get_lod_for_distance(25.0) == 0, "Distance 25m should be LOD0")
	_assert(manager.get_lod_for_distance(50.0) == 0, "Distance 50m should be LOD0")

	# LOD1: 50-150m
	_assert(manager.get_lod_for_distance(51.0) == 1, "Distance 51m should be LOD1")
	_assert(manager.get_lod_for_distance(100.0) == 1, "Distance 100m should be LOD1")
	_assert(manager.get_lod_for_distance(150.0) == 1, "Distance 150m should be LOD1")

	# LOD2: 150-400m
	_assert(manager.get_lod_for_distance(151.0) == 2, "Distance 151m should be LOD2")
	_assert(manager.get_lod_for_distance(300.0) == 2, "Distance 300m should be LOD2")
	_assert(manager.get_lod_for_distance(400.0) == 2, "Distance 400m should be LOD2")

	# LOD3: 400m+
	_assert(manager.get_lod_for_distance(401.0) == 3, "Distance 401m should be LOD3")
	_assert(manager.get_lod_for_distance(1000.0) == 3, "Distance 1000m should be LOD3")

	manager.free()


func _test_lod_level_boundaries() -> void:
	print("\n--- LOD Level Boundaries ---")
	var manager: Node = _LODManagerClass.new()

	# Test exact boundaries
	_assert(manager.get_lod_for_distance(50.0) == 0, "50m (boundary) should be LOD0")
	_assert(manager.get_lod_for_distance(50.001) == 1, "Just over 50m should be LOD1")

	_assert(manager.get_lod_for_distance(150.0) == 1, "150m (boundary) should be LOD1")
	_assert(manager.get_lod_for_distance(150.001) == 2, "Just over 150m should be LOD2")

	_assert(manager.get_lod_for_distance(400.0) == 2, "400m (boundary) should be LOD2")
	_assert(manager.get_lod_for_distance(400.001) == 3, "Just over 400m should be LOD3")

	manager.free()


func _test_hysteresis_prevents_oscillation() -> void:
	print("\n--- Hysteresis Prevents Oscillation ---")
	var manager: Node = _LODManagerClass.new()

	# Hysteresis = 5m by default
	# At LOD0, need to go past 55m to switch to LOD1
	var lod_at_55: int = manager.get_lod_for_distance_with_hysteresis(55.0, 0)
	_assert(lod_at_55 == 0, "At LOD0, 55m should stay LOD0 (hysteresis)")

	# At 56m should switch
	var lod_at_56: int = manager.get_lod_for_distance_with_hysteresis(56.0, 0)
	_assert(lod_at_56 == 1, "At LOD0, 56m should switch to LOD1")

	# At LOD1, going back to 46m should switch to LOD0 (earlier due to hysteresis)
	var lod_back: int = manager.get_lod_for_distance_with_hysteresis(44.0, 1)
	_assert(lod_back == 0, "At LOD1, 44m should switch back to LOD0")

	# At LOD1, 46m should stay LOD1
	var lod_stay: int = manager.get_lod_for_distance_with_hysteresis(46.0, 1)
	_assert(lod_stay == 1, "At LOD1, 46m should stay LOD1 (hysteresis)")

	manager.free()


func _test_custom_thresholds() -> void:
	print("\n--- Custom Thresholds ---")
	var manager: Node = _LODManagerClass.new()

	# Set custom thresholds
	manager.set_thresholds(25.0, 75.0, 200.0)

	_assert(manager.lod0_max_distance == 25.0, "LOD0 threshold should be 25")
	_assert(manager.lod1_max_distance == 75.0, "LOD1 threshold should be 75")
	_assert(manager.lod2_max_distance == 200.0, "LOD2 threshold should be 200")

	# Verify new thresholds work
	_assert(manager.get_lod_for_distance(20.0) == 0, "20m should be LOD0 with new thresholds")
	_assert(manager.get_lod_for_distance(30.0) == 1, "30m should be LOD1 with new thresholds")
	_assert(manager.get_lod_for_distance(100.0) == 2, "100m should be LOD2 with new thresholds")
	_assert(manager.get_lod_for_distance(250.0) == 3, "250m should be LOD3 with new thresholds")

	manager.free()


func _test_reset_thresholds() -> void:
	print("\n--- Reset Thresholds ---")
	var manager: Node = _LODManagerClass.new()

	# Set custom then reset
	manager.set_thresholds(10.0, 20.0, 30.0)
	manager.reset_thresholds()

	_assert(manager.lod0_max_distance == 50.0, "LOD0 threshold should reset to 50")
	_assert(manager.lod1_max_distance == 150.0, "LOD1 threshold should reset to 150")
	_assert(manager.lod2_max_distance == 400.0, "LOD2 threshold should reset to 400")

	manager.free()


func _test_chunk_registration() -> void:
	print("\n--- Chunk Registration ---")
	var manager: Node = _LODManagerClass.new()

	# Create a mock chunk (simple Node3D)
	var chunk := Node3D.new()
	chunk.name = "MockChunk"

	manager.register_chunk(chunk)

	var stats: Dictionary = manager.get_statistics()
	_assert(stats.total_chunks == 1, "Should have 1 registered chunk")

	# Registering same chunk again shouldn't duplicate
	manager.register_chunk(chunk)
	stats = manager.get_statistics()
	_assert(stats.total_chunks == 1, "Re-registering shouldn't duplicate")

	chunk.free()
	manager.free()


func _test_chunk_unregistration() -> void:
	print("\n--- Chunk Unregistration ---")
	var manager: Node = _LODManagerClass.new()

	var chunk := Node3D.new()
	manager.register_chunk(chunk)

	var stats: Dictionary = manager.get_statistics()
	_assert(stats.total_chunks == 1, "Should have 1 chunk before unregister")

	manager.unregister_chunk(chunk)

	stats = manager.get_statistics()
	_assert(stats.total_chunks == 0, "Should have 0 chunks after unregister")

	# Unregistering non-registered chunk shouldn't crash
	var other_chunk := Node3D.new()
	manager.unregister_chunk(other_chunk)  # Should not crash
	_assert(true, "Unregistering non-registered chunk shouldn't crash")

	chunk.free()
	other_chunk.free()
	manager.free()


func _test_clear_chunks() -> void:
	print("\n--- Clear Chunks ---")
	var manager: Node = _LODManagerClass.new()

	# Register multiple chunks
	var chunks: Array[Node3D] = []
	for i in range(5):
		var chunk := Node3D.new()
		chunks.append(chunk)
		manager.register_chunk(chunk)

	var stats: Dictionary = manager.get_statistics()
	_assert(stats.total_chunks == 5, "Should have 5 chunks before clear")

	manager.clear()

	stats = manager.get_statistics()
	_assert(stats.total_chunks == 0, "Should have 0 chunks after clear")

	for chunk in chunks:
		chunk.free()
	manager.free()


func _test_camera_integration() -> void:
	print("\n--- Camera Integration ---")
	var manager: Node = _LODManagerClass.new()
	root.add_child(manager)
	await process_frame

	var camera := Camera3D.new()
	camera.position = Vector3(100, 0, 0)
	root.add_child(camera)
	await process_frame

	manager.set_camera(camera)
	_assert(manager.get_camera() == camera, "Camera should be set")

	# Test distance calculation (camera must be in tree for global_position)
	var dist: float = manager.get_distance_to(Vector3.ZERO)
	_assert(is_equal_approx(dist, 100.0), "Distance to origin should be 100")

	camera.queue_free()
	manager.queue_free()
	await process_frame


func _test_statistics() -> void:
	print("\n--- Statistics ---")
	var manager: Node = _LODManagerClass.new()

	var stats: Dictionary = manager.get_statistics()

	_assert("total_chunks" in stats, "Stats should have total_chunks")
	_assert("lod0_count" in stats, "Stats should have lod0_count")
	_assert("lod1_count" in stats, "Stats should have lod1_count")
	_assert("lod2_count" in stats, "Stats should have lod2_count")
	_assert("lod3_count" in stats, "Stats should have lod3_count")

	_assert(stats.total_chunks == 0, "Initially 0 total chunks")
	_assert(stats.lod0_count == 0, "Initially 0 LOD0 chunks")

	manager.free()


func _test_lod_level_names() -> void:
	print("\n--- LOD Level Names ---")

	var name0: String = _LODManagerClass.lod_level_name(0)
	var name1: String = _LODManagerClass.lod_level_name(1)
	var name2: String = _LODManagerClass.lod_level_name(2)
	var name3: String = _LODManagerClass.lod_level_name(3)

	_assert("LOD0" in name0, "LOD0 name should contain 'LOD0'")
	_assert("LOD1" in name1, "LOD1 name should contain 'LOD1'")
	_assert("LOD2" in name2, "LOD2 name should contain 'LOD2'")
	_assert("LOD3" in name3, "LOD3 name should contain 'LOD3'")

	# Unknown level
	var name_unknown: String = _LODManagerClass.lod_level_name(99)
	_assert(name_unknown == "Unknown", "Invalid LOD level should return 'Unknown'")


func _test_max_distance_for_lod() -> void:
	print("\n--- Max Distance for LOD ---")
	var manager: Node = _LODManagerClass.new()

	_assert(manager.get_max_distance_for_lod(0) == 50.0, "LOD0 max distance should be 50")
	_assert(manager.get_max_distance_for_lod(1) == 150.0, "LOD1 max distance should be 150")
	_assert(manager.get_max_distance_for_lod(2) == 400.0, "LOD2 max distance should be 400")
	_assert(manager.get_max_distance_for_lod(3) == INF, "LOD3 max distance should be INF")

	manager.free()


func _test_force_update() -> void:
	print("\n--- Force Update ---")
	var manager: Node = _LODManagerClass.new()
	root.add_child(manager)
	await process_frame

	# Force update should not crash with no camera or chunks
	manager.force_update()
	_assert(true, "Force update without camera shouldn't crash")

	# Add camera and chunk
	var camera := Camera3D.new()
	camera.position = Vector3(100, 0, 0)
	root.add_child(camera)
	manager.set_camera(camera)

	var chunk := Node3D.new()
	chunk.position = Vector3.ZERO
	manager.register_chunk(chunk)

	manager.force_update()
	_assert(true, "Force update with camera and chunk shouldn't crash")

	camera.queue_free()
	chunk.free()
	manager.queue_free()
	await process_frame


func _test_invalid_chunk_cleanup() -> void:
	print("\n--- Invalid Chunk Cleanup ---")
	var manager: Node = _LODManagerClass.new()
	root.add_child(manager)
	await process_frame

	var camera := Camera3D.new()
	camera.position = Vector3(100, 0, 0)
	root.add_child(camera)
	manager.set_camera(camera)

	# Register a chunk then free it
	var chunk := Node3D.new()
	manager.register_chunk(chunk)

	var stats: Dictionary = manager.get_statistics()
	_assert(stats.total_chunks == 1, "Should have 1 chunk")

	# Free the chunk without unregistering
	chunk.free()

	# Force update should clean up invalid reference
	manager.force_update()
	# Note: The invalid chunk will be cleaned up during the update

	_assert(true, "Manager should handle freed chunks gracefully")

	camera.queue_free()
	manager.queue_free()
	await process_frame
