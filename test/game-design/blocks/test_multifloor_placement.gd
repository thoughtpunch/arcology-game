extends SceneTree
## Integration tests for multi-floor block placement
## Tests that blocks can be placed on different floors using GameState
## Run with: godot --headless --script test/test_multifloor_placement.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Multi-Floor Placement Tests ===")

	# Wait for autoloads to be ready
	await process_frame

	# Get GameState autoload
	var game_state = get_root().get_node_or_null("/root/GameState")
	if game_state == null:
		print("ERROR: GameState autoload not available")
		quit(1)
		return

	# Create test grid and input handler
	var grid := Grid.new()
	var input_handler := InputHandler.new()
	get_root().add_child(grid)
	get_root().add_child(input_handler)

	# Setup input handler with grid (no camera needed for direct placement tests)
	input_handler.grid = grid

	# Test 1: Place block at floor 0 (default)
	print("\nTest 1: Place block at floor 0")
	game_state.set_floor(0)

	var pos_z0 := Vector3i(0, 0, 0)
	input_handler._try_place_block(pos_z0)

	if grid.has_block(pos_z0) and grid.get_block(pos_z0).grid_position.z == 0:
		print("  PASS: Block placed at Z=0")
		tests_passed += 1
	else:
		print("  FAIL: Block not at Z=0")
		tests_failed += 1

	# Test 2: Change floor and place block at floor 3
	print("\nTest 2: Place block at floor 3 after floor change")
	game_state.set_floor(3)

	var pos_z3 := Vector3i(1, 0, 3)  # Note: Z=3 in position
	input_handler._try_place_block(pos_z3)

	if grid.has_block(pos_z3) and grid.get_block(pos_z3).grid_position.z == 3:
		print("  PASS: Block placed at Z=3")
		tests_passed += 1
	else:
		print("  FAIL: Block not at Z=3, grid has: %s" % str(grid.get_all_positions()))
		tests_failed += 1

	# Test 3: Build 5-story tower (acceptance criteria)
	print("\nTest 3: Build 5-story tower")
	grid.clear()

	# Build tower at position (5, 5) on floors 0-4
	for floor_num in range(5):
		game_state.set_floor(floor_num)
		var tower_pos := Vector3i(5, 5, floor_num)
		input_handler._try_place_block(tower_pos)

	# Verify all 5 blocks exist
	var tower_complete := true
	for floor_num in range(5):
		var tower_pos := Vector3i(5, 5, floor_num)
		if not grid.has_block(tower_pos):
			print("  FAIL: Missing block at Z=%d" % floor_num)
			tower_complete = false
			break

	if tower_complete and grid.get_block_count() == 5:
		print("  PASS: Built 5-story tower successfully")
		tests_passed += 1
	else:
		print("  FAIL: Tower incomplete, block count=%d" % grid.get_block_count())
		tests_failed += 1

	# Test 4: Blocks at different floors sort correctly (visual test via z_index)
	print("\nTest 4: Z-index ordering for floor stacking")

	# Create renderer to test sprite sorting
	var renderer := BlockRenderer.new()
	get_root().add_child(renderer)
	renderer.connect_to_grid(grid)

	# Existing blocks from tower should be rendered
	var z0_sprite: Sprite2D = renderer._sprites.get(Vector3i(5, 5, 0))
	var z2_sprite: Sprite2D = renderer._sprites.get(Vector3i(5, 5, 2))
	var z4_sprite: Sprite2D = renderer._sprites.get(Vector3i(5, 5, 4))

	if z0_sprite and z2_sprite and z4_sprite:
		# Higher floors should have higher z_index
		if z4_sprite.z_index > z2_sprite.z_index and z2_sprite.z_index > z0_sprite.z_index:
			print("  PASS: Higher floors have higher z_index (correct stacking)")
			tests_passed += 1
		else:
			print("  FAIL: z_index not correct: Z0=%d, Z2=%d, Z4=%d" % [
				z0_sprite.z_index, z2_sprite.z_index, z4_sprite.z_index
			])
			tests_failed += 1
	else:
		print("  FAIL: Some sprites missing")
		tests_failed += 1

	# Test 5: Ghost preview uses current floor (verify _get_current_floor integration)
	print("\nTest 5: _get_current_floor returns GameState floor")

	game_state.set_floor(7)
	var reported_floor := input_handler._get_current_floor()

	if reported_floor == 7:
		print("  PASS: _get_current_floor returns GameState value (7)")
		tests_passed += 1
	else:
		print("  FAIL: _get_current_floor returned %d, expected 7" % reported_floor)
		tests_failed += 1

	# Test 6: Placement validation at current floor
	print("\nTest 6: Validation checks at current floor")

	game_state.set_floor(3)
	grid.clear()

	# Place block at (2, 2, 3)
	var validation_pos := Vector3i(2, 2, 3)
	input_handler._try_place_block(validation_pos)

	# Same position should be invalid for new placement
	if not input_handler._is_placement_valid(validation_pos):
		print("  PASS: Occupied position on floor 3 is invalid")
		tests_passed += 1
	else:
		print("  FAIL: Should reject occupied position")
		tests_failed += 1

	# Test 7: Entrance can only be placed at Z=0 (ground_only constraint)
	print("\nTest 7: Entrance ground_only constraint at floor > 0")

	game_state.set_floor(2)
	grid.clear()

	input_handler.set_selected_block_type("entrance")
	var upper_entrance_pos := Vector3i(0, 0, 2)
	input_handler._try_place_block(upper_entrance_pos)

	if not grid.has_block(upper_entrance_pos):
		print("  PASS: Entrance rejected at Z=2")
		tests_passed += 1
	else:
		print("  FAIL: Entrance should be rejected at Z>0")
		tests_failed += 1

	# Test 8: NEGATIVE - Cannot place multiple blocks at same position
	print("\nTest 8: Reject duplicate placement")

	game_state.set_floor(0)
	grid.clear()
	input_handler.set_selected_block_type("corridor")

	var dup_pos := Vector3i(3, 3, 0)
	input_handler._try_place_block(dup_pos)  # First placement
	input_handler._try_place_block(dup_pos)  # Duplicate attempt

	# Should still have only 1 block
	if grid.get_block_count() == 1:
		print("  PASS: Duplicate placement rejected")
		tests_passed += 1
	else:
		print("  FAIL: Should have 1 block, got %d" % grid.get_block_count())
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
