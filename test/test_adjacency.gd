extends SceneTree
## Unit tests for adjacency detection
## Tests neighbor finding, occupied neighbors, and walkable connections
## Run with: godot --headless --script test/test_adjacency.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Adjacency Detection Tests ===")

	# Wait for autoloads to be ready
	await process_frame

	# Create test grid
	var grid := Grid.new()
	get_root().add_child(grid)

	# Test 1: get_neighbors returns 6 positions
	print("\nTest 1: get_neighbors returns 6 adjacent positions")
	var center := Vector3i(5, 5, 2)
	var neighbors := grid.get_neighbors(center)

	if neighbors.size() == 6:
		print("  PASS: Returns 6 neighbors")
		tests_passed += 1
	else:
		print("  FAIL: Expected 6 neighbors, got %d" % neighbors.size())
		tests_failed += 1

	# Test 2: Verify neighbor positions are correct
	print("\nTest 2: Neighbor positions are correct")
	var expected_neighbors: Array[Vector3i] = [
		Vector3i(6, 5, 2),  # +X
		Vector3i(4, 5, 2),  # -X
		Vector3i(5, 6, 2),  # +Y
		Vector3i(5, 4, 2),  # -Y
		Vector3i(5, 5, 3),  # +Z
		Vector3i(5, 5, 1),  # -Z
	]

	var all_match := true
	for expected in expected_neighbors:
		if expected not in neighbors:
			print("  FAIL: Missing neighbor %s" % expected)
			all_match = false
			break

	if all_match:
		print("  PASS: All neighbor positions correct")
		tests_passed += 1
	else:
		tests_failed += 1

	# Test 3: get_occupied_neighbors returns only positions with blocks
	print("\nTest 3: get_occupied_neighbors returns only occupied positions")
	grid.clear()

	# Place center block
	var center_block := Block.new("corridor", Vector3i(0, 0, 0))
	grid.set_block(center_block.grid_position, center_block)

	# Place 2 neighbors
	var neighbor1 := Block.new("corridor", Vector3i(1, 0, 0))
	var neighbor2 := Block.new("corridor", Vector3i(0, 1, 0))
	grid.set_block(neighbor1.grid_position, neighbor1)
	grid.set_block(neighbor2.grid_position, neighbor2)

	var occupied := grid.get_occupied_neighbors(Vector3i(0, 0, 0))
	if occupied.size() == 2:
		print("  PASS: Returns 2 occupied neighbors (out of 6)")
		tests_passed += 1
	else:
		print("  FAIL: Expected 2 occupied neighbors, got %d" % occupied.size())
		tests_failed += 1

	# Test 4: Corridor-to-corridor connects (public-public)
	print("\nTest 4: Corridor-to-corridor connects horizontally")
	grid.clear()

	var corridor1 := Block.new("corridor", Vector3i(0, 0, 0))
	var corridor2 := Block.new("corridor", Vector3i(1, 0, 0))
	grid.set_block(corridor1.grid_position, corridor1)
	grid.set_block(corridor2.grid_position, corridor2)

	if grid.can_connect(Vector3i(0, 0, 0), Vector3i(1, 0, 0)):
		print("  PASS: Corridors connect horizontally")
		tests_passed += 1
	else:
		print("  FAIL: Corridors should connect")
		tests_failed += 1

	# Test 5: Corridor-to-residential connects (public-private, can reach destination)
	print("\nTest 5: Corridor-to-residential connects (reach destination)")
	grid.clear()

	var corridor := Block.new("corridor", Vector3i(0, 0, 0))
	var residential := Block.new("residential_basic", Vector3i(1, 0, 0))
	grid.set_block(corridor.grid_position, corridor)
	grid.set_block(residential.grid_position, residential)

	if grid.can_connect(Vector3i(0, 0, 0), Vector3i(1, 0, 0)):
		print("  PASS: Corridor connects to residential (can reach destination)")
		tests_passed += 1
	else:
		print("  FAIL: Corridor should connect to residential")
		tests_failed += 1

	# Test 6: NEGATIVE - Residential-to-residential does NOT connect through
	print("\nTest 6: Residential-to-residential does NOT connect (private-private)")
	grid.clear()

	var res1 := Block.new("residential_basic", Vector3i(0, 0, 0))
	var res2 := Block.new("residential_basic", Vector3i(1, 0, 0))
	grid.set_block(res1.grid_position, res1)
	grid.set_block(res2.grid_position, res2)

	if not grid.can_connect(Vector3i(0, 0, 0), Vector3i(1, 0, 0)):
		print("  PASS: Residential does not connect to residential (no through-traffic)")
		tests_passed += 1
	else:
		print("  FAIL: Residential should NOT connect to residential")
		tests_failed += 1

	# Test 7: Stairs connect vertically
	print("\nTest 7: Stairs connect vertically (same column)")
	grid.clear()

	var stairs_z0 := Block.new("stairs", Vector3i(0, 0, 0))
	var stairs_z1 := Block.new("stairs", Vector3i(0, 0, 1))
	grid.set_block(stairs_z0.grid_position, stairs_z0)
	grid.set_block(stairs_z1.grid_position, stairs_z1)

	if grid.can_connect(Vector3i(0, 0, 0), Vector3i(0, 0, 1)):
		print("  PASS: Stairs connect vertically")
		tests_passed += 1
	else:
		print("  FAIL: Stairs should connect vertically")
		tests_failed += 1

	# Test 8: NEGATIVE - Corridor does not connect vertically
	print("\nTest 8: Corridor does NOT connect vertically")
	grid.clear()

	var corridor_z0 := Block.new("corridor", Vector3i(0, 0, 0))
	var corridor_z1 := Block.new("corridor", Vector3i(0, 0, 1))
	grid.set_block(corridor_z0.grid_position, corridor_z0)
	grid.set_block(corridor_z1.grid_position, corridor_z1)

	if not grid.can_connect(Vector3i(0, 0, 0), Vector3i(0, 0, 1)):
		print("  PASS: Corridor does not connect vertically")
		tests_passed += 1
	else:
		print("  FAIL: Corridor should NOT connect vertically")
		tests_failed += 1

	# Test 9: NEGATIVE - Empty position does not connect
	print("\nTest 9: Empty position does not connect")
	grid.clear()

	var single_block := Block.new("corridor", Vector3i(0, 0, 0))
	grid.set_block(single_block.grid_position, single_block)

	if not grid.can_connect(Vector3i(0, 0, 0), Vector3i(1, 0, 0)):
		print("  PASS: Cannot connect to empty position")
		tests_passed += 1
	else:
		print("  FAIL: Should not connect to empty position")
		tests_failed += 1

	# Test 10: NEGATIVE - Non-adjacent positions don't connect
	print("\nTest 10: Non-adjacent positions do NOT connect")
	grid.clear()

	var block_a := Block.new("corridor", Vector3i(0, 0, 0))
	var block_b := Block.new("corridor", Vector3i(2, 0, 0))  # 2 steps away
	grid.set_block(block_a.grid_position, block_a)
	grid.set_block(block_b.grid_position, block_b)

	if not grid.can_connect(Vector3i(0, 0, 0), Vector3i(2, 0, 0)):
		print("  PASS: Non-adjacent blocks do not connect")
		tests_passed += 1
	else:
		print("  FAIL: Non-adjacent should not connect")
		tests_failed += 1

	# Test 11: get_walkable_neighbors returns correct set
	print("\nTest 11: get_walkable_neighbors filters correctly")
	grid.clear()

	# Setup: corridor surrounded by corridor, residential, and empty
	var center_corridor := Block.new("corridor", Vector3i(0, 0, 0))
	var adj_corridor := Block.new("corridor", Vector3i(1, 0, 0))   # +X: public
	var adj_residential := Block.new("residential_basic", Vector3i(0, 1, 0))  # +Y: private
	var adj_stairs := Block.new("stairs", Vector3i(0, 0, 1))  # +Z: vertical
	# -X, -Y, -Z are empty
	grid.set_block(center_corridor.grid_position, center_corridor)
	grid.set_block(adj_corridor.grid_position, adj_corridor)
	grid.set_block(adj_residential.grid_position, adj_residential)
	grid.set_block(adj_stairs.grid_position, adj_stairs)

	var walkable := grid.get_walkable_neighbors(Vector3i(0, 0, 0))

	# Should include: corridor (+X), residential (+Y) (can reach destination)
	# Should NOT include: stairs (+Z) because corridor doesn't connect_vertical
	# Expected: 2 walkable neighbors
	if walkable.size() == 2:
		print("  PASS: get_walkable_neighbors returns 2 neighbors")
		tests_passed += 1
	else:
		print("  FAIL: Expected 2 walkable neighbors, got %d: %s" % [walkable.size(), str(walkable)])
		tests_failed += 1

	# Test 12: Elevator shaft connects vertically
	print("\nTest 12: Elevator shaft connects vertically")
	grid.clear()

	var elev_z0 := Block.new("elevator_shaft", Vector3i(0, 0, 0))
	var elev_z1 := Block.new("elevator_shaft", Vector3i(0, 0, 1))
	grid.set_block(elev_z0.grid_position, elev_z0)
	grid.set_block(elev_z1.grid_position, elev_z1)

	if grid.can_connect(Vector3i(0, 0, 0), Vector3i(0, 0, 1)):
		print("  PASS: Elevator shaft connects vertically")
		tests_passed += 1
	else:
		print("  FAIL: Elevator shaft should connect vertically")
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
