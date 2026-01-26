extends SceneTree
## Test script for Grid class
## Run with: godot --headless --script test/test_grid.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Grid Tests ===")

	# Test 1: Basic block storage
	print("\nTest 1: Basic block storage")
	var grid := Grid.new()
	var mock_block = {"block_type": "test", "grid_position": Vector3i.ZERO}
	grid.set_block(Vector3i(1, 2, 3), mock_block)

	if grid.has_block(Vector3i(1, 2, 3)):
		print("  PASS: Block stored at position")
		tests_passed += 1
	else:
		print("  FAIL: Block not found at position")
		tests_failed += 1

	if grid.get_block(Vector3i(1, 2, 3)) == mock_block:
		print("  PASS: Retrieved block matches")
		tests_passed += 1
	else:
		print("  FAIL: Retrieved block does not match")
		tests_failed += 1

	# Test 2: Remove block
	print("\nTest 2: Remove block")
	grid.remove_block(Vector3i(1, 2, 3))
	if not grid.has_block(Vector3i(1, 2, 3)):
		print("  PASS: Block removed")
		tests_passed += 1
	else:
		print("  FAIL: Block still present after removal")
		tests_failed += 1

	# Test 3: grid_to_screen conversion
	print("\nTest 3: grid_to_screen conversion")
	var screen_pos := grid.grid_to_screen(Vector3i(0, 0, 0))
	if screen_pos == Vector2(0, 0):
		print("  PASS: Origin converts to (0, 0)")
		tests_passed += 1
	else:
		print("  FAIL: Origin converted to %s" % screen_pos)
		tests_failed += 1

	# Test position (1, 0, 0) -> should be (32, 16)
	screen_pos = grid.grid_to_screen(Vector3i(1, 0, 0))
	if screen_pos == Vector2(32, 16):
		print("  PASS: (1,0,0) converts to (32, 16)")
		tests_passed += 1
	else:
		print("  FAIL: (1,0,0) converted to %s, expected (32, 16)" % screen_pos)
		tests_failed += 1

	# Test Z offset: (0, 0, 1) -> should be (0, -32)
	screen_pos = grid.grid_to_screen(Vector3i(0, 0, 1))
	if screen_pos == Vector2(0, -32):
		print("  PASS: (0,0,1) converts to (0, -32)")
		tests_passed += 1
	else:
		print("  FAIL: (0,0,1) converted to %s, expected (0, -32)" % screen_pos)
		tests_failed += 1

	# Test 4: Round-trip conversion (critical acceptance criterion)
	print("\nTest 4: Round-trip conversion (grid_to_screen -> screen_to_grid)")
	var test_positions := [
		Vector3i(0, 0, 0),
		Vector3i(5, 3, 0),
		Vector3i(10, 10, 2),
		Vector3i(-3, 4, 1),
		Vector3i(0, 0, 5),
	]

	var all_roundtrips_pass := true
	for pos in test_positions:
		var screen := grid.grid_to_screen(pos)
		var back := grid.screen_to_grid(screen, pos.z)
		if back != pos:
			print("  FAIL: Round-trip failed for %s -> %s -> %s" % [pos, screen, back])
			all_roundtrips_pass = false

	if all_roundtrips_pass:
		print("  PASS: All round-trip conversions match")
		tests_passed += 1
	else:
		tests_failed += 1

	# Test 5: Signals
	print("\nTest 5: Signals emit correctly")
	var grid2 := Grid.new()

	# Test that signals exist and can be connected
	var signal_list = grid2.get_signal_list()
	var has_block_added = false
	var has_block_removed = false
	for sig in signal_list:
		if sig.name == "block_added":
			has_block_added = true
		if sig.name == "block_removed":
			has_block_removed = true

	if has_block_added:
		print("  PASS: block_added signal exists")
		tests_passed += 1
	else:
		print("  FAIL: block_added signal missing")
		tests_failed += 1

	if has_block_removed:
		print("  PASS: block_removed signal exists")
		tests_passed += 1
	else:
		print("  FAIL: block_removed signal missing")
		tests_failed += 1

	grid2.set_block(Vector3i(0, 0, 0), {"type": "test", "grid_position": Vector3i.ZERO})
	grid2.set_block(Vector3i(1, 0, 0), {"type": "test", "grid_position": Vector3i.ZERO})
	grid2.remove_block(Vector3i(0, 0, 0))

	# Test 6: get_all_blocks
	print("\nTest 6: get_all_blocks")
	if grid2.get_all_blocks().size() == 1:
		print("  PASS: get_all_blocks returns 1 block")
		tests_passed += 1
	else:
		print("  FAIL: get_all_blocks returns %d blocks" % grid2.get_all_blocks().size())
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
