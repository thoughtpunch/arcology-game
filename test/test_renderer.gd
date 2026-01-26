extends SceneTree
## Test script for BlockRenderer isometric positioning
## Run with: godot --headless --script test/test_renderer.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== BlockRenderer Tests ===")

	# Wait for autoload to be ready
	await process_frame

	# Create test grid and renderer
	var grid := Grid.new()
	var renderer := BlockRenderer.new()
	get_root().add_child(grid)
	get_root().add_child(renderer)
	renderer.connect_to_grid(grid)

	# Test 1: Correct isometric positioning
	print("\nTest 1: Isometric positioning")

	# Place block at origin
	var block1 := Block.new("corridor", Vector3i(0, 0, 0))
	grid.set_block(block1.grid_position, block1)

	if renderer._sprites.has(Vector3i(0, 0, 0)):
		var sprite: Sprite2D = renderer._sprites[Vector3i(0, 0, 0)]
		if sprite.position == Vector2(0, 0):
			print("  PASS: Block at (0,0,0) renders at screen (0,0)")
			tests_passed += 1
		else:
			print("  FAIL: Block at (0,0,0) renders at %s, expected (0,0)" % sprite.position)
			tests_failed += 1
	else:
		print("  FAIL: No sprite created for (0,0,0)")
		tests_failed += 1

	# Test 2: X offset
	var block2 := Block.new("corridor", Vector3i(1, 0, 0))
	grid.set_block(block2.grid_position, block2)

	if renderer._sprites.has(Vector3i(1, 0, 0)):
		var sprite: Sprite2D = renderer._sprites[Vector3i(1, 0, 0)]
		# x = (1-0) * 32 = 32, y = (1+0) * 16 = 16
		if sprite.position == Vector2(32, 16):
			print("  PASS: Block at (1,0,0) renders at screen (32,16)")
			tests_passed += 1
		else:
			print("  FAIL: Block at (1,0,0) renders at %s, expected (32,16)" % sprite.position)
			tests_failed += 1
	else:
		print("  FAIL: No sprite created for (1,0,0)")
		tests_failed += 1

	# Test 3: Y offset
	var block3 := Block.new("corridor", Vector3i(0, 1, 0))
	grid.set_block(block3.grid_position, block3)

	if renderer._sprites.has(Vector3i(0, 1, 0)):
		var sprite: Sprite2D = renderer._sprites[Vector3i(0, 1, 0)]
		# x = (0-1) * 32 = -32, y = (0+1) * 16 = 16
		if sprite.position == Vector2(-32, 16):
			print("  PASS: Block at (0,1,0) renders at screen (-32,16)")
			tests_passed += 1
		else:
			print("  FAIL: Block at (0,1,0) renders at %s, expected (-32,16)" % sprite.position)
			tests_failed += 1
	else:
		print("  FAIL: No sprite created for (0,1,0)")
		tests_failed += 1

	# Test 4: Z (floor) offset
	print("\nTest 4: Floor stacking (Z offset)")
	var block4 := Block.new("corridor", Vector3i(0, 0, 1))
	grid.set_block(block4.grid_position, block4)

	if renderer._sprites.has(Vector3i(0, 0, 1)):
		var sprite: Sprite2D = renderer._sprites[Vector3i(0, 0, 1)]
		# x = 0, y = 0 - 32 = -32 (higher on screen)
		if sprite.position == Vector2(0, -32):
			print("  PASS: Block at (0,0,1) renders at screen (0,-32)")
			tests_passed += 1
		else:
			print("  FAIL: Block at (0,0,1) renders at %s, expected (0,-32)" % sprite.position)
			tests_failed += 1
	else:
		print("  FAIL: No sprite created for (0,0,1)")
		tests_failed += 1

	# Test 5: Z-index for floor stacking
	print("\nTest 5: Z-index ordering")
	var sprite_z0: Sprite2D = renderer._sprites[Vector3i(0, 0, 0)]
	var sprite_z1: Sprite2D = renderer._sprites[Vector3i(0, 0, 1)]

	# Z=1 should have higher z_index than Z=0
	if sprite_z1.z_index > sprite_z0.z_index:
		print("  PASS: Z=1 sprite has higher z_index than Z=0")
		tests_passed += 1
	else:
		print("  FAIL: z_index(Z=1)=%d, z_index(Z=0)=%d" % [sprite_z1.z_index, sprite_z0.z_index])
		tests_failed += 1

	# Test 6: Y-sorting within a floor
	print("\nTest 6: Y-sorting within floor")
	# Blocks at same Z, different Y
	var block_y0 := Block.new("corridor", Vector3i(2, 0, 0))
	var block_y2 := Block.new("corridor", Vector3i(2, 2, 0))
	grid.set_block(block_y0.grid_position, block_y0)
	grid.set_block(block_y2.grid_position, block_y2)

	var sprite_y0: Sprite2D = renderer._sprites[Vector3i(2, 0, 0)]
	var sprite_y2: Sprite2D = renderer._sprites[Vector3i(2, 2, 0)]

	# Higher Y should have higher z_index (drawn in front)
	if sprite_y2.z_index > sprite_y0.z_index:
		print("  PASS: Higher Y has higher z_index (drawn in front)")
		tests_passed += 1
	else:
		print("  FAIL: z_index(Y=2)=%d should be > z_index(Y=0)=%d" % [sprite_y2.z_index, sprite_y0.z_index])
		tests_failed += 1

	# Test 7: Block removal removes sprite
	print("\nTest 7: Block removal")
	var remove_pos := Vector3i(2, 2, 0)
	grid.remove_block(remove_pos)

	if not renderer._sprites.has(remove_pos):
		print("  PASS: Sprite removed when block removed")
		tests_passed += 1
	else:
		print("  FAIL: Sprite still exists after block removal")
		tests_failed += 1

	# Test 8: Y-sort enabled on renderer
	print("\nTest 8: Y-sort enabled")
	if renderer.y_sort_enabled:
		print("  PASS: y_sort_enabled is true")
		tests_passed += 1
	else:
		print("  FAIL: y_sort_enabled is false")
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
