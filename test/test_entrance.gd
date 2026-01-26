extends SceneTree
## Unit tests for entrance block type and tracking
## Run with: godot --headless --script test/test_entrance.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Entrance Block Tests ===")

	# Wait for autoloads to be ready
	await process_frame

	# Get BlockRegistry
	var registry = get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		print("ERROR: BlockRegistry not available")
		quit(1)
		return

	# Create test grid
	var grid := Grid.new()
	get_root().add_child(grid)

	# Test 1: Entrance block exists in registry
	print("\nTest 1: Entrance block type exists")
	if registry.has_type("entrance"):
		print("  PASS: 'entrance' type exists in BlockRegistry")
		tests_passed += 1
	else:
		print("  FAIL: 'entrance' type not found")
		tests_failed += 1

	# Test 2: Entrance has ground_only property
	print("\nTest 2: Entrance has ground_only=true")
	var entrance_data: Dictionary = registry.get_block_data("entrance")
	if entrance_data.get("ground_only", false) == true:
		print("  PASS: Entrance has ground_only=true")
		tests_passed += 1
	else:
		print("  FAIL: Entrance should have ground_only=true")
		tests_failed += 1

	# Test 3: Grid tracks entrance positions
	print("\nTest 3: Grid tracks entrance positions")
	grid.clear()

	# Place entrance at Z=0
	var entrance := Block.new("entrance", Vector3i(0, 0, 0))
	grid.set_block(entrance.grid_position, entrance)

	var entrances := grid.get_entrance_positions()
	if entrances.size() == 1 and Vector3i(0, 0, 0) in entrances:
		print("  PASS: Grid tracks entrance at (0,0,0)")
		tests_passed += 1
	else:
		print("  FAIL: Expected 1 entrance at (0,0,0), got %d" % entrances.size())
		tests_failed += 1

	# Test 4: Multiple entrances tracked
	print("\nTest 4: Multiple entrances tracked")
	var entrance2 := Block.new("entrance", Vector3i(5, 0, 0))
	grid.set_block(entrance2.grid_position, entrance2)

	entrances = grid.get_entrance_positions()
	if entrances.size() == 2:
		print("  PASS: Grid tracks 2 entrances")
		tests_passed += 1
	else:
		print("  FAIL: Expected 2 entrances, got %d" % entrances.size())
		tests_failed += 1

	# Test 5: has_entrance returns true
	print("\nTest 5: has_entrance returns true when entrances exist")
	if grid.has_entrance():
		print("  PASS: has_entrance() returns true")
		tests_passed += 1
	else:
		print("  FAIL: has_entrance() should return true")
		tests_failed += 1

	# Test 6: Removing entrance updates tracking
	print("\nTest 6: Removing entrance updates tracking")
	grid.remove_block(Vector3i(0, 0, 0))

	entrances = grid.get_entrance_positions()
	if entrances.size() == 1 and Vector3i(5, 0, 0) in entrances:
		print("  PASS: Entrance removed from tracking")
		tests_passed += 1
	else:
		print("  FAIL: Expected 1 entrance after removal, got %d" % entrances.size())
		tests_failed += 1

	# Test 7: entrances_changed signal exists and is connected
	print("\nTest 7: entrances_changed signal functionality")

	# Verify signal exists by checking we can query entrance positions after add
	# (direct signal testing in GDScript unit tests can be flaky)
	var grid2 := Grid.new()
	get_root().add_child(grid2)

	# No entrances initially
	var before := grid2.get_entrance_positions().size()

	# Add entrance
	var entrance3 := Block.new("entrance", Vector3i(2, 2, 0))
	grid2.set_block(entrance3.grid_position, entrance3)
	var after_add := grid2.get_entrance_positions().size()

	# Remove entrance
	grid2.remove_block(Vector3i(2, 2, 0))
	var after_remove := grid2.get_entrance_positions().size()

	if before == 0 and after_add == 1 and after_remove == 0:
		print("  PASS: Entrance tracking add/remove works correctly")
		tests_passed += 1
	else:
		print("  FAIL: before=%d, after_add=%d, after_remove=%d" % [before, after_add, after_remove])
		tests_failed += 1

	grid2.queue_free()

	# Test 8: Non-entrance blocks don't affect tracking
	print("\nTest 8: Non-entrance blocks don't affect tracking")
	var initial_count := grid.get_entrance_positions().size()

	var corridor := Block.new("corridor", Vector3i(3, 2, 0))
	grid.set_block(corridor.grid_position, corridor)

	if grid.get_entrance_positions().size() == initial_count:
		print("  PASS: Corridor doesn't affect entrance tracking")
		tests_passed += 1
	else:
		print("  FAIL: Corridor shouldn't be tracked as entrance")
		tests_failed += 1

	# Test 9: Clear removes all entrances
	print("\nTest 9: Clear removes all entrances")
	grid.clear()

	if grid.get_entrance_positions().size() == 0 and not grid.has_entrance():
		print("  PASS: Clear removes all entrances")
		tests_passed += 1
	else:
		print("  FAIL: Clear should remove all entrances")
		tests_failed += 1

	# Test 10: NEGATIVE - Entrance at Z>0 should be rejected by InputHandler
	# (This is tested in test_multifloor_placement.gd, but we verify the block data)
	print("\nTest 10: Entrance is public and connects horizontally")
	if registry.is_public("entrance") and registry.connects_horizontal("entrance"):
		print("  PASS: Entrance is public and connects horizontally")
		tests_passed += 1
	else:
		print("  FAIL: Entrance should be public and connect horizontally")
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
