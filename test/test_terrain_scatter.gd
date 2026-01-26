extends SceneTree
## Test script for Terrain decoration scatter system
## Run with: godot --headless --script test/test_terrain_scatter.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Terrain Decoration Scatter Tests ===")

	# Test 1: Default world_seed is 0
	print("\nTest 1: Default world_seed is 0")
	var terrain := Terrain.new()
	if terrain.world_seed == 0:
		print("  PASS: Default world_seed is 0")
		tests_passed += 1
	else:
		print("  FAIL: Default world_seed is %d" % terrain.world_seed)
		tests_failed += 1

	# Test 2: Can set world_seed
	print("\nTest 2: Can set world_seed")
	terrain.world_seed = 12345
	if terrain.world_seed == 12345:
		print("  PASS: world_seed set to 12345")
		tests_passed += 1
	else:
		print("  FAIL: world_seed is %d, expected 12345" % terrain.world_seed)
		tests_failed += 1

	# Test 3: Scatter area default
	print("\nTest 3: Default scatter area is Rect2i(-20, -20, 40, 40)")
	if terrain._scatter_area == Rect2i(-20, -20, 40, 40):
		print("  PASS: Default scatter area correct")
		tests_passed += 1
	else:
		print("  FAIL: Scatter area is %s" % terrain._scatter_area)
		tests_failed += 1

	# Test 4: Same seed produces same placement (deterministic)
	print("\nTest 4: Same seed produces same placement")
	var terrain1 := Terrain.new()
	var terrain2 := Terrain.new()
	# Add to tree so they can call scatter
	get_root().add_child(terrain1)
	get_root().add_child(terrain2)

	terrain1.world_seed = 42
	terrain2.world_seed = 42
	terrain1.scatter_decorations(Rect2i(-5, -5, 10, 10))
	terrain2.scatter_decorations(Rect2i(-5, -5, 10, 10))

	var positions1 := terrain1.get_all_decoration_positions()
	var positions2 := terrain2.get_all_decoration_positions()

	if positions1.size() == positions2.size():
		var match_count := 0
		for pos in positions1:
			if pos in positions2:
				match_count += 1
		if match_count == positions1.size():
			print("  PASS: Same seed produces identical positions (%d decorations)" % positions1.size())
			tests_passed += 1
		else:
			print("  FAIL: Positions don't match (%d/%d matched)" % [match_count, positions1.size()])
			tests_failed += 1
	else:
		print("  FAIL: Different decoration counts (%d vs %d)" % [positions1.size(), positions2.size()])
		tests_failed += 1

	terrain1.queue_free()
	terrain2.queue_free()

	# Test 5: Different seeds produce different placements
	print("\nTest 5: Different seeds produce different placements")
	var terrain3 := Terrain.new()
	var terrain4 := Terrain.new()
	get_root().add_child(terrain3)
	get_root().add_child(terrain4)

	terrain3.world_seed = 100
	terrain4.world_seed = 200
	terrain3.scatter_decorations(Rect2i(-5, -5, 10, 10))
	terrain4.scatter_decorations(Rect2i(-5, -5, 10, 10))

	var positions3 := terrain3.get_all_decoration_positions()
	var positions4 := terrain4.get_all_decoration_positions()

	# With different seeds, we expect at least some positions to differ
	var matching := 0
	for pos in positions3:
		if pos in positions4:
			matching += 1

	# If there are some decorations and not all match, that's expected
	if positions3.size() > 0 and positions4.size() > 0 and matching < positions3.size():
		print("  PASS: Different seeds produce different positions (%d matching)" % matching)
		tests_passed += 1
	elif positions3.size() == 0 and positions4.size() == 0:
		print("  SKIP: No decorations placed (density issue)")
		tests_passed += 1
	else:
		print("  FAIL: All positions match - seeds should differ")
		tests_failed += 1

	terrain3.queue_free()
	terrain4.queue_free()

	# Test 6: Space theme produces no decorations
	print("\nTest 6: Space theme produces no decorations")
	var terrain_space := Terrain.new()
	get_root().add_child(terrain_space)
	terrain_space.theme = "space"
	terrain_space.world_seed = 42
	terrain_space.scatter_decorations(Rect2i(-5, -5, 10, 10))

	if terrain_space.get_decoration_count() == 0:
		print("  PASS: Space theme has 0 decorations")
		tests_passed += 1
	else:
		print("  FAIL: Space theme has %d decorations" % terrain_space.get_decoration_count())
		tests_failed += 1

	terrain_space.queue_free()

	# Test 7: Hide decoration at position
	print("\nTest 7: hide_decoration_at() hides decoration")
	var terrain5 := Terrain.new()
	get_root().add_child(terrain5)
	terrain5.theme = "earth"
	terrain5.world_seed = 42
	terrain5.scatter_decorations(Rect2i(-5, -5, 10, 10))

	var all_positions := terrain5.get_all_decoration_positions()
	if all_positions.size() > 0:
		var test_pos := all_positions[0]
		terrain5.hide_decoration_at(test_pos)
		var sprite: Sprite2D = terrain5._decorations[test_pos]
		if sprite and not sprite.visible:
			print("  PASS: Decoration at %s is now hidden" % test_pos)
			tests_passed += 1
		else:
			print("  FAIL: Decoration at %s should be hidden" % test_pos)
			tests_failed += 1
	else:
		print("  SKIP: No decorations to hide")
		tests_passed += 1

	terrain5.queue_free()

	# Test 8: Show decoration at position
	print("\nTest 8: show_decoration_at() shows hidden decoration")
	var terrain6 := Terrain.new()
	get_root().add_child(terrain6)
	terrain6.theme = "earth"
	terrain6.world_seed = 42
	terrain6.scatter_decorations(Rect2i(-5, -5, 10, 10))

	all_positions = terrain6.get_all_decoration_positions()
	if all_positions.size() > 0:
		var test_pos := all_positions[0]
		terrain6.hide_decoration_at(test_pos)
		terrain6.show_decoration_at(test_pos)
		var sprite: Sprite2D = terrain6._decorations[test_pos]
		if sprite and sprite.visible:
			print("  PASS: Decoration at %s is now visible" % test_pos)
			tests_passed += 1
		else:
			print("  FAIL: Decoration at %s should be visible" % test_pos)
			tests_failed += 1
	else:
		print("  SKIP: No decorations to show")
		tests_passed += 1

	terrain6.queue_free()

	# Test 9: has_decoration_at returns true for existing positions
	print("\nTest 9: has_decoration_at() returns true for existing positions")
	var terrain7 := Terrain.new()
	get_root().add_child(terrain7)
	terrain7.theme = "earth"
	terrain7.world_seed = 42
	terrain7.scatter_decorations(Rect2i(-5, -5, 10, 10))

	all_positions = terrain7.get_all_decoration_positions()
	if all_positions.size() > 0:
		var has_all := true
		for pos in all_positions:
			if not terrain7.has_decoration_at(pos):
				has_all = false
				break
		if has_all:
			print("  PASS: has_decoration_at returns true for all positions")
			tests_passed += 1
		else:
			print("  FAIL: has_decoration_at returned false for existing position")
			tests_failed += 1
	else:
		print("  SKIP: No decorations to check")
		tests_passed += 1

	terrain7.queue_free()

	# Test 10: has_decoration_at returns false for empty positions
	print("\nTest 10: has_decoration_at() returns false for empty positions")
	var terrain8 := Terrain.new()
	get_root().add_child(terrain8)
	terrain8.theme = "earth"
	terrain8.world_seed = 42
	terrain8.scatter_decorations(Rect2i(-5, -5, 10, 10))

	# Position far outside the scatter area
	var empty_pos := Vector2i(1000, 1000)
	if not terrain8.has_decoration_at(empty_pos):
		print("  PASS: has_decoration_at returns false for empty position")
		tests_passed += 1
	else:
		print("  FAIL: has_decoration_at should return false for %s" % empty_pos)
		tests_failed += 1

	terrain8.queue_free()

	# Test 11: Clear decorations removes all
	print("\nTest 11: _clear_decorations() removes all decorations")
	var terrain9 := Terrain.new()
	get_root().add_child(terrain9)
	terrain9.theme = "earth"
	terrain9.world_seed = 42
	terrain9.scatter_decorations(Rect2i(-5, -5, 10, 10))

	var count_before := terrain9.get_decoration_count()
	terrain9._clear_decorations()
	var count_after := terrain9.get_decoration_count()

	if count_before > 0 and count_after == 0:
		print("  PASS: Clear removed %d decorations" % count_before)
		tests_passed += 1
	elif count_before == 0:
		print("  SKIP: No decorations to clear")
		tests_passed += 1
	else:
		print("  FAIL: Still have %d decorations after clear" % count_after)
		tests_failed += 1

	terrain9.queue_free()

	# Test 12: Earth theme produces decorations
	print("\nTest 12: Earth theme produces decorations")
	var terrain10 := Terrain.new()
	get_root().add_child(terrain10)
	terrain10.theme = "earth"
	terrain10.world_seed = 42
	terrain10.scatter_decorations(Rect2i(-10, -10, 20, 20))

	var earth_count := terrain10.get_decoration_count()
	# With 0.08 density over 400 cells, expect roughly 32 decorations (but RNG varies)
	if earth_count > 0:
		print("  PASS: Earth theme produced %d decorations" % earth_count)
		tests_passed += 1
	else:
		print("  FAIL: Earth theme should produce decorations")
		tests_failed += 1

	terrain10.queue_free()

	# Test 13: Grid to screen conversion
	print("\nTest 13: _grid_to_screen() produces correct isometric coordinates")
	var terrain11 := Terrain.new()
	var screen_pos := terrain11._grid_to_screen(Vector2i(0, 0))
	if screen_pos == Vector2(0, 0):
		print("  PASS: (0,0) maps to screen (0,0)")
		tests_passed += 1
	else:
		print("  FAIL: (0,0) maps to %s, expected (0,0)" % screen_pos)
		tests_failed += 1

	# Test 14: Grid (1,0) should be right and down
	print("\nTest 14: Grid (1,0) maps correctly")
	screen_pos = terrain11._grid_to_screen(Vector2i(1, 0))
	if screen_pos == Vector2(32, 16):
		print("  PASS: (1,0) maps to screen (32, 16)")
		tests_passed += 1
	else:
		print("  FAIL: (1,0) maps to %s, expected (32, 16)" % screen_pos)
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
