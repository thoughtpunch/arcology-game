extends SceneTree

## Unit tests for LODManager
##
## Tests:
## - LOD level calculation at different distances
## - Hysteresis prevents rapid LOD switching
## - Block registration and unregistration
## - LOD stats tracking
## - Visibility changes at LOD transitions
## - Force LOD override
## - Disabled state behavior

const LODManagerScript = preload("res://src/game/lod_manager.gd")

# LOD level constants (mirror enum from lod_manager.gd)
const LOD0: int = 0
const LOD1: int = 1
const LOD2: int = 2
const LOD3: int = 3

var _tests_passed: int = 0
var _tests_failed: int = 0


func _init() -> void:
	print("=== LODManager Tests ===\n")

	# Basic functionality
	_test_lod_levels_at_distances()
	_test_hysteresis_prevents_rapid_switching()
	_test_block_registration()
	_test_unregister_block()
	_test_lod_stats()
	_test_disabled_state()
	_test_no_camera()
	_test_custom_thresholds()
	_test_force_lod()
	_test_visibility_changes()
	_test_update_block_position()
	_test_lod_changed_signal()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])

	if _tests_failed > 0:
		quit(1)
	else:
		quit(0)


func _test_lod_levels_at_distances() -> void:
	print("Test: LOD levels at different distances")

	var lod := LODManagerScript.new()

	# Test _get_lod_for_distance at various distances
	# Starting from LOD0 (no hysteresis bias)

	# LOD0: 0-50m
	var lod_at_0m: int = lod._get_lod_for_distance(0.0, 0)
	assert(lod_at_0m == LOD0, "0m should be LOD0, got %d" % lod_at_0m)

	var lod_at_40m: int = lod._get_lod_for_distance(40.0, 0)
	assert(lod_at_40m == LOD0, "40m should be LOD0, got %d" % lod_at_40m)

	# LOD1: 50-150m (with hysteresis, need to be past 55m from LOD0)
	var lod_at_60m: int = lod._get_lod_for_distance(60.0, 0)
	assert(lod_at_60m == LOD1, "60m from LOD0 should be LOD1, got %d" % lod_at_60m)

	var lod_at_100m: int = lod._get_lod_for_distance(100.0, 1)
	assert(lod_at_100m == LOD1, "100m should be LOD1, got %d" % lod_at_100m)

	# LOD2: 150-400m (with hysteresis, need to be past 155m from LOD1)
	var lod_at_200m: int = lod._get_lod_for_distance(200.0, 1)
	assert(lod_at_200m == LOD2, "200m from LOD1 should be LOD2, got %d" % lod_at_200m)

	var lod_at_300m: int = lod._get_lod_for_distance(300.0, 2)
	assert(lod_at_300m == LOD2, "300m should be LOD2, got %d" % lod_at_300m)

	# LOD3: 400m+
	var lod_at_500m: int = lod._get_lod_for_distance(500.0, 2)
	assert(lod_at_500m == LOD3, "500m from LOD2 should be LOD3, got %d" % lod_at_500m)

	var lod_at_1000m: int = lod._get_lod_for_distance(1000.0, 3)
	assert(lod_at_1000m == LOD3, "1000m should be LOD3, got %d" % lod_at_1000m)

	_pass()


func _test_hysteresis_prevents_rapid_switching() -> void:
	print("Test: Hysteresis prevents rapid LOD switching")

	var lod := LODManagerScript.new()

	# At LOD1 (50-150m range), moving to 52m should NOT switch back to LOD0
	# because hysteresis requires going below 50-5=45m
	var lod_at_52m_from_lod1: int = lod._get_lod_for_distance(52.0, 1)
	assert(lod_at_52m_from_lod1 == LOD1, "52m from LOD1 should stay LOD1 (hysteresis), got %d" % lod_at_52m_from_lod1)

	# But at 42m (below 50-5=45), should switch to LOD0
	var lod_at_42m_from_lod1: int = lod._get_lod_for_distance(42.0, 1)
	assert(lod_at_42m_from_lod1 == LOD0, "42m from LOD1 should be LOD0, got %d" % lod_at_42m_from_lod1)

	# At LOD0, staying at 52m should remain LOD0 (below threshold + hysteresis = 55)
	var lod_at_52m_from_lod0: int = lod._get_lod_for_distance(52.0, 0)
	assert(lod_at_52m_from_lod0 == LOD0, "52m from LOD0 should stay LOD0 (hysteresis), got %d" % lod_at_52m_from_lod0)

	# But at 58m (above 50+5=55), should switch to LOD1
	var lod_at_58m_from_lod0: int = lod._get_lod_for_distance(58.0, 0)
	assert(lod_at_58m_from_lod0 == LOD1, "58m from LOD0 should be LOD1, got %d" % lod_at_58m_from_lod0)

	_pass()


func _test_block_registration() -> void:
	print("Test: Block registration")

	var lod := LODManagerScript.new()

	# Initially no blocks
	assert(lod.get_registered_count() == 0, "Should start with 0 blocks")

	# Register a block
	var block_node := Node3D.new()
	lod.register_block(1, block_node, Vector3(10, 0, 10))
	assert(lod.get_registered_count() == 1, "Should have 1 block after registration")

	# Check initial LOD is LOD0
	assert(lod.get_block_lod(1) == LOD0, "Initial LOD should be LOD0")

	# Register another block
	var block_node2 := Node3D.new()
	lod.register_block(2, block_node2, Vector3(200, 0, 200))
	assert(lod.get_registered_count() == 2, "Should have 2 blocks")

	# Unregistered block returns -1
	assert(lod.get_block_lod(999) == -1, "Unregistered block should return -1")

	block_node.queue_free()
	block_node2.queue_free()
	_pass()


func _test_unregister_block() -> void:
	print("Test: Unregister block")

	var lod := LODManagerScript.new()
	var block_node := Node3D.new()

	lod.register_block(1, block_node, Vector3.ZERO)
	assert(lod.get_registered_count() == 1, "Should have 1 block")

	lod.unregister_block(1)
	assert(lod.get_registered_count() == 0, "Should have 0 blocks after unregister")
	assert(lod.get_block_lod(1) == -1, "Unregistered block should return -1")

	# Unregistering non-existent block should not error
	lod.unregister_block(999)
	assert(lod.get_registered_count() == 0, "Count should still be 0")

	block_node.queue_free()
	_pass()


func _test_lod_stats() -> void:
	print("Test: LOD stats tracking")

	var lod := LODManagerScript.new()

	# Create mock camera
	var camera := Node3D.new()
	camera.global_position = Vector3.ZERO
	lod.set_camera(camera)
	lod.enable()

	# Register blocks at different distances
	var nodes: Array[Node3D] = []
	for i in range(4):
		var n := Node3D.new()
		nodes.append(n)

	# Block at 30m (LOD0)
	lod.register_block(1, nodes[0], Vector3(30, 0, 0))
	# Block at 100m (LOD1)
	lod.register_block(2, nodes[1], Vector3(100, 0, 0))
	# Block at 250m (LOD2)
	lod.register_block(3, nodes[2], Vector3(250, 0, 0))
	# Block at 500m (LOD3)
	lod.register_block(4, nodes[3], Vector3(500, 0, 0))

	# Update to apply LOD changes
	lod.update()

	var stats: Dictionary = lod.get_lod_stats()
	assert(stats["total"] == 4, "Should have 4 total blocks")
	assert(stats["lod0"] == 1, "Should have 1 block at LOD0, got %d" % stats["lod0"])
	assert(stats["lod1"] == 1, "Should have 1 block at LOD1, got %d" % stats["lod1"])
	assert(stats["lod2"] == 1, "Should have 1 block at LOD2, got %d" % stats["lod2"])
	assert(stats["lod3"] == 1, "Should have 1 block at LOD3, got %d" % stats["lod3"])

	for n in nodes:
		n.queue_free()
	camera.queue_free()
	_pass()


func _test_disabled_state() -> void:
	print("Test: Disabled state")

	var lod := LODManagerScript.new()
	var camera := Node3D.new()
	camera.global_position = Vector3.ZERO
	lod.set_camera(camera)

	var block_node := Node3D.new()
	lod.register_block(1, block_node, Vector3(100, 0, 0))  # 100m away -> would be LOD1

	# Initially disabled
	assert(not lod.is_enabled(), "Should start disabled")

	# Update while disabled - should not change LOD
	lod.update()
	assert(lod.get_block_lod(1) == LOD0, "LOD should stay LOD0 when disabled")

	# Enable and update
	lod.enable()
	assert(lod.is_enabled(), "Should be enabled")
	lod.update()
	assert(lod.get_block_lod(1) == LOD1, "LOD should be LOD1 when enabled")

	# Disable - LOD should not change
	lod.disable()
	assert(not lod.is_enabled(), "Should be disabled")
	# Move camera closer - but disabled so no change
	camera.global_position = Vector3(99, 0, 0)  # 1m away
	lod.update()
	assert(lod.get_block_lod(1) == LOD1, "LOD should stay LOD1 when disabled")

	block_node.queue_free()
	camera.queue_free()
	_pass()


func _test_no_camera() -> void:
	print("Test: No camera set")

	var lod := LODManagerScript.new()
	lod.enable()

	var block_node := Node3D.new()
	lod.register_block(1, block_node, Vector3(100, 0, 0))

	# Update without camera - should not error or change LOD
	lod.update()
	assert(lod.get_block_lod(1) == LOD0, "LOD should stay LOD0 without camera")

	block_node.queue_free()
	_pass()


func _test_custom_thresholds() -> void:
	print("Test: Custom thresholds")

	var lod := LODManagerScript.new()

	# Default thresholds
	var defaults: Dictionary = lod.get_thresholds()
	assert(defaults["lod0_max"] == 50.0, "Default LOD0 max should be 50")
	assert(defaults["lod1_max"] == 150.0, "Default LOD1 max should be 150")
	assert(defaults["lod2_max"] == 400.0, "Default LOD2 max should be 400")

	# Set custom thresholds
	lod.set_thresholds(25.0, 75.0, 200.0)
	var custom: Dictionary = lod.get_thresholds()
	assert(custom["lod0_max"] == 25.0, "Custom LOD0 max should be 25")
	assert(custom["lod1_max"] == 75.0, "Custom LOD1 max should be 75")
	assert(custom["lod2_max"] == 200.0, "Custom LOD2 max should be 200")

	# Test that new thresholds are used (35m should now be LOD1, not LOD0)
	var lod_at_35m: int = lod._get_lod_for_distance(35.0, 0)
	assert(lod_at_35m == LOD1, "35m with custom thresholds should be LOD1, got %d" % lod_at_35m)

	_pass()


func _test_force_lod() -> void:
	print("Test: Force LOD override")

	var lod := LODManagerScript.new()
	var camera := Node3D.new()
	camera.global_position = Vector3.ZERO
	lod.set_camera(camera)
	lod.enable()

	# Create block with mesh for visibility testing
	var block_node := _create_test_block_node()
	lod.register_block(1, block_node, Vector3(30, 0, 0))  # 30m -> normally LOD0

	lod.update()
	assert(lod.get_block_lod(1) == LOD0, "Should be LOD0 normally")

	# Force to LOD2
	lod.force_lod(1, LOD2)
	assert(lod.get_block_lod(1) == LOD2, "Should be forced to LOD2")

	# Force non-existent block - should not error
	lod.force_lod(999, LOD3)

	block_node.queue_free()
	camera.queue_free()
	_pass()


func _test_visibility_changes() -> void:
	print("Test: Visibility changes at LOD transitions")

	var lod := LODManagerScript.new()
	var camera := Node3D.new()
	camera.global_position = Vector3.ZERO
	lod.set_camera(camera)
	lod.enable()

	# Create block with Panels and Interiors children
	var block_node := _create_test_block_node()
	var panels: Node3D = block_node.get_node("Panels")
	var interiors: Node3D = block_node.get_node("Interiors")

	lod.register_block(1, block_node, Vector3(30, 0, 0))  # 30m -> LOD0

	# At LOD0: everything visible
	lod.update()
	assert(panels.visible, "Panels should be visible at LOD0")
	assert(interiors.visible, "Interiors should be visible at LOD0")

	# Move to LOD1: interiors hidden
	lod.force_lod(1, LOD1)
	assert(panels.visible, "Panels should be visible at LOD1")
	assert(not interiors.visible, "Interiors should be hidden at LOD1")

	# Move to LOD2: panels also hidden
	lod.force_lod(1, LOD2)
	assert(not panels.visible, "Panels should be hidden at LOD2")
	assert(not interiors.visible, "Interiors should be hidden at LOD2")

	# Move back to LOD0: everything restored
	lod.force_lod(1, LOD0)
	assert(panels.visible, "Panels should be visible at LOD0 again")
	assert(interiors.visible, "Interiors should be visible at LOD0 again")

	block_node.queue_free()
	camera.queue_free()
	_pass()


func _test_update_block_position() -> void:
	print("Test: Update block position")

	var lod := LODManagerScript.new()
	var camera := Node3D.new()
	camera.global_position = Vector3.ZERO
	lod.set_camera(camera)
	lod.enable()

	var block_node := Node3D.new()
	lod.register_block(1, block_node, Vector3(30, 0, 0))  # 30m -> LOD0

	lod.update()
	assert(lod.get_block_lod(1) == LOD0, "Should be LOD0 at 30m")

	# Update position to 200m
	lod.update_block_position(1, Vector3(200, 0, 0))
	lod.update()
	assert(lod.get_block_lod(1) == LOD2, "Should be LOD2 at 200m")

	# Update non-existent block - should not error
	lod.update_block_position(999, Vector3.ZERO)

	block_node.queue_free()
	camera.queue_free()
	_pass()


func _test_lod_changed_signal() -> void:
	print("Test: LOD changed signal")

	var lod := LODManagerScript.new()
	var camera := Node3D.new()
	camera.position = Vector3.ZERO  # Use position, not global_position (not in tree)
	lod.set_camera(camera)
	lod.enable()

	var signal_received := false
	var received_block_id := -1
	var received_old_lod := -1
	var received_new_lod := -1

	var signal_data := {"received": false, "block_id": -1, "old_lod": -1, "new_lod": -1}

	var callback := func(block_id: int, old_lod: int, new_lod: int) -> void:
		signal_data["received"] = true
		signal_data["block_id"] = block_id
		signal_data["old_lod"] = old_lod
		signal_data["new_lod"] = new_lod

	lod.lod_changed.connect(callback)

	var block_node := Node3D.new()
	lod.register_block(1, block_node, Vector3(100, 0, 0))  # 100m -> LOD1

	# Check initial LOD
	var initial_lod: int = lod.get_block_lod(1)

	lod.update()

	# Check LOD after update
	var final_lod: int = lod.get_block_lod(1)

	assert(signal_data["received"], "Signal should be emitted on LOD change (initial=%d, final=%d)" % [initial_lod, final_lod])
	assert(signal_data["block_id"] == 1, "Signal should have block_id=1")
	assert(signal_data["old_lod"] == LOD0, "Signal should have old_lod=LOD0")
	assert(signal_data["new_lod"] == LOD1, "Signal should have new_lod=LOD1")

	block_node.queue_free()
	camera.queue_free()
	_pass()


func _create_test_block_node() -> Node3D:
	## Create a test block node with MeshInstance3D, Panels, and Interiors children.
	var root := Node3D.new()
	root.name = "TestBlock"

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	root.add_child(mesh_instance)

	var panels := Node3D.new()
	panels.name = "Panels"
	panels.visible = true
	root.add_child(panels)

	var interiors := Node3D.new()
	interiors.name = "Interiors"
	interiors.visible = true
	root.add_child(interiors)

	return root


func _pass() -> void:
	print("  ✓ PASSED")
	_tests_passed += 1


func _fail(msg: String) -> void:
	print("  ✗ FAILED: %s" % msg)
	_tests_failed += 1
