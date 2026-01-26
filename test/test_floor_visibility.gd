extends SceneTree
## Test script for floor visibility system
## Run with: godot --headless --script test/test_floor_visibility.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Floor Visibility Tests ===")

	# Wait for autoload to be ready
	await process_frame

	# Create test grid and renderer
	var grid := Grid.new()
	var renderer := BlockRenderer.new()
	get_root().add_child(grid)
	get_root().add_child(renderer)
	renderer.connect_to_grid(grid)

	# Place blocks at multiple floors for testing
	# Floor 0
	var block_z0 := Block.new("corridor", Vector3i(0, 0, 0))
	grid.set_block(block_z0.grid_position, block_z0)

	# Floor 1
	var block_z1 := Block.new("corridor", Vector3i(0, 0, 1))
	grid.set_block(block_z1.grid_position, block_z1)

	# Floor 2
	var block_z2 := Block.new("corridor", Vector3i(0, 0, 2))
	grid.set_block(block_z2.grid_position, block_z2)

	# Floor 3
	var block_z3 := Block.new("corridor", Vector3i(0, 0, 3))
	grid.set_block(block_z3.grid_position, block_z3)

	# Floor 4
	var block_z4 := Block.new("corridor", Vector3i(0, 0, 4))
	grid.set_block(block_z4.grid_position, block_z4)

	# Test 1: Current floor fully visible (100% opacity)
	print("\nTest 1: Current floor fully visible")
	renderer.update_visibility(2)  # Set current floor to 2

	var sprite_z2: Sprite2D = renderer._sprites[Vector3i(0, 0, 2)]
	if sprite_z2.visible and sprite_z2.modulate.a == 1.0:
		print("  PASS: Floor 2 (current) is visible at 100%% opacity")
		tests_passed += 1
	else:
		print("  FAIL: Floor 2 visible=%s, opacity=%f" % [sprite_z2.visible, sprite_z2.modulate.a])
		tests_failed += 1

	# Test 2: Floor above hidden
	print("\nTest 2: Floors above hidden")
	var sprite_z3: Sprite2D = renderer._sprites[Vector3i(0, 0, 3)]
	var sprite_z4: Sprite2D = renderer._sprites[Vector3i(0, 0, 4)]

	if not sprite_z3.visible and not sprite_z4.visible:
		print("  PASS: Floors 3 and 4 are hidden")
		tests_passed += 1
	else:
		print("  FAIL: Floor 3 visible=%s, Floor 4 visible=%s" % [sprite_z3.visible, sprite_z4.visible])
		tests_failed += 1

	# Test 3: One floor below with 70% opacity
	print("\nTest 3: One floor below at 70%% opacity")
	var sprite_z1: Sprite2D = renderer._sprites[Vector3i(0, 0, 1)]

	# Expected: 1.0 - (1 * 0.3) = 0.7
	var expected_opacity := 0.7
	if sprite_z1.visible and absf(sprite_z1.modulate.a - expected_opacity) < 0.01:
		print("  PASS: Floor 1 is visible at ~70%% opacity (got %f)" % sprite_z1.modulate.a)
		tests_passed += 1
	else:
		print("  FAIL: Floor 1 visible=%s, opacity=%f (expected %f)" % [sprite_z1.visible, sprite_z1.modulate.a, expected_opacity])
		tests_failed += 1

	# Test 4: Two floors below with 40% opacity
	print("\nTest 4: Two floors below at 40%% opacity")
	var sprite_z0: Sprite2D = renderer._sprites[Vector3i(0, 0, 0)]

	# Expected: 1.0 - (2 * 0.3) = 0.4
	expected_opacity = 0.4
	if sprite_z0.visible and absf(sprite_z0.modulate.a - expected_opacity) < 0.01:
		print("  PASS: Floor 0 is visible at ~40%% opacity (got %f)" % sprite_z0.modulate.a)
		tests_passed += 1
	else:
		print("  FAIL: Floor 0 visible=%s, opacity=%f (expected %f)" % [sprite_z0.visible, sprite_z0.modulate.a, expected_opacity])
		tests_failed += 1

	# Test 5: Three floors below hidden (beyond visible range)
	print("\nTest 5: Three+ floors below hidden")

	# Add block at Z=-1 (we need to test below range scenario)
	# Instead, test with current_floor = 4
	renderer.update_visibility(4)

	# Now floor 1 should be 3 below (4-1=3), which is beyond FLOORS_BELOW_VISIBLE (2)
	sprite_z1 = renderer._sprites[Vector3i(0, 0, 1)]
	if not sprite_z1.visible:
		print("  PASS: Floor 1 is hidden (3 floors below current)")
		tests_passed += 1
	else:
		print("  FAIL: Floor 1 should be hidden (3 floors below), visible=%s" % sprite_z1.visible)
		tests_failed += 1

	# Test 6: Visibility updates when floor changes
	print("\nTest 6: Visibility updates on floor change")

	# Change to floor 0
	renderer.update_visibility(0)

	sprite_z0 = renderer._sprites[Vector3i(0, 0, 0)]
	sprite_z1 = renderer._sprites[Vector3i(0, 0, 1)]
	sprite_z2 = renderer._sprites[Vector3i(0, 0, 2)]

	# Floor 0 should now be current (100%)
	# Floors 1 and 2 should be hidden (above current)
	var floor_0_correct := sprite_z0.visible and sprite_z0.modulate.a == 1.0
	var floors_above_hidden := not sprite_z1.visible and not sprite_z2.visible

	if floor_0_correct and floors_above_hidden:
		print("  PASS: Floor 0 visible, floors above hidden")
		tests_passed += 1
	else:
		print("  FAIL: Z0 visible=%s opacity=%f, Z1 visible=%s, Z2 visible=%s" % [
			sprite_z0.visible, sprite_z0.modulate.a, sprite_z1.visible, sprite_z2.visible
		])
		tests_failed += 1

	# Test 7: NEGATIVE - Invalid floor doesn't crash
	print("\nTest 7: Update with extreme floor values")
	renderer.update_visibility(-5)  # Negative floor
	renderer.update_visibility(100)  # Very high floor

	# Just verify no crash occurred
	print("  PASS: No crash with extreme floor values")
	tests_passed += 1

	# Test 8: NEGATIVE - Empty grid doesn't crash
	print("\nTest 8: Update visibility on empty renderer")
	var empty_grid := Grid.new()
	var empty_renderer := BlockRenderer.new()
	get_root().add_child(empty_grid)
	get_root().add_child(empty_renderer)
	empty_renderer.connect_to_grid(empty_grid)

	empty_renderer.update_visibility(5)  # Should handle empty _sprites gracefully
	print("  PASS: No crash on empty renderer")
	tests_passed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
