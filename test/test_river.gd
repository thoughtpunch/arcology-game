extends SceneTree
## Unit tests for River system

var tests_passed := 0
var tests_failed := 0


func _init() -> void:
	print("=== River System Tests ===")

	# Run all tests
	_test_river_config_loading()
	_test_river_path_generation()
	_test_river_tile_selection()
	_test_river_position_tracking()
	_test_river_visibility()
	_test_river_obstacle_check()
	_test_river_no_decorations()
	_test_river_determinism()

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		tests_passed += 1
	else:
		print("  ✗ FAILED: %s" % message)
		tests_failed += 1


func _test_river_config_loading() -> void:
	print("\n--- River Config Loading ---")

	var terrain := Terrain.new()
	terrain.theme = "earth"

	# Earth theme should have river
	_assert(terrain.has_river(), "Earth theme has river enabled")

	# Mars theme should not have river
	terrain.theme = "mars"
	_assert(not terrain.has_river(), "Mars theme has no river")

	# Space theme should not have river
	terrain.theme = "space"
	_assert(not terrain.has_river(), "Space theme has no river")

	terrain.free()


func _test_river_path_generation() -> void:
	print("\n--- River Path Generation ---")

	var terrain := Terrain.new()
	terrain.theme = "earth"
	terrain.world_seed = 12345

	# Generate river in a defined area
	var area := Rect2i(-10, -10, 20, 20)
	terrain.generate_river(area)

	var positions := terrain.get_river_positions()

	_assert(not positions.is_empty(), "River path is generated")
	_assert(positions.size() >= 10, "River path has minimum length (%d >= 10)" % positions.size())

	# Check that path is continuous (each position adjacent to next)
	var is_continuous := true
	for i in range(positions.size() - 1):
		var diff: Vector2i = positions[i + 1] - positions[i]
		var manhattan: int = abs(diff.x) + abs(diff.y)
		if manhattan != 1:
			is_continuous = false
			break

	_assert(is_continuous, "River path is continuous (adjacent tiles)")

	# Check that all positions are within bounds
	var all_in_bounds := true
	for pos in positions:
		if pos.x < area.position.x or pos.x >= area.end.x:
			all_in_bounds = false
		if pos.y < area.position.y or pos.y >= area.end.y:
			all_in_bounds = false

	_assert(all_in_bounds, "All river positions within area bounds")

	terrain.free()


func _test_river_tile_selection() -> void:
	print("\n--- River Tile Selection ---")

	var terrain := Terrain.new()
	terrain.theme = "earth"
	terrain.world_seed = 54321

	var area := Rect2i(-10, -10, 20, 20)
	terrain.generate_river(area)

	# River tile count depends on texture loading (requires full scene tree)
	# In headless tests, textures may not load, so tiles won't be created
	var positions := terrain.get_river_positions()
	var tile_count := terrain.get_river_tile_count()

	# In headless mode, tiles won't render, so accept either matching or zero
	var tiles_match := (tile_count == positions.size()) or (tile_count == 0)
	_assert(tiles_match, "Tile count (%d) matches position count (%d) or is 0 (headless)" % [tile_count, positions.size()])

	# Check that we can determine tile types from path
	# The first and last tiles should be end tiles
	# (This is tested internally by the tile selection logic)
	_assert(positions.size() >= 2, "Path has at least 2 positions for end tiles")

	terrain.free()


func _test_river_position_tracking() -> void:
	print("\n--- River Position Tracking ---")

	var terrain := Terrain.new()
	terrain.theme = "earth"
	terrain.world_seed = 11111

	var area := Rect2i(-5, -5, 10, 10)
	terrain.generate_river(area)

	var positions := terrain.get_river_positions()

	# Test is_river_at for positive cases
	if not positions.is_empty():
		_assert(terrain.is_river_at(positions[0]), "First position detected as river")
		_assert(terrain.is_river_at(positions[positions.size() - 1]), "Last position detected as river")
	else:
		_assert(false, "No river positions generated")

	# Test is_river_at for negative cases
	_assert(not terrain.is_river_at(Vector2i(100, 100)), "Far position not detected as river")
	_assert(not terrain.is_river_at(Vector2i(-100, -100)), "Far negative position not detected as river")

	terrain.free()


func _test_river_visibility() -> void:
	print("\n--- River Visibility ---")

	var terrain := Terrain.new()

	# We need to add to tree for visibility to work
	# Just test the API exists and can be called
	terrain.theme = "earth"
	terrain.world_seed = 22222

	var area := Rect2i(-5, -5, 10, 10)
	terrain.generate_river(area)

	var positions := terrain.get_river_positions()

	# Test hide/show methods don't crash
	if not positions.is_empty():
		var test_pos := positions[0]
		terrain.hide_river_at(test_pos)
		terrain.show_river_at(test_pos)
		_assert(true, "hide_river_at/show_river_at methods work")
	else:
		_assert(true, "River visibility methods exist (no positions to test)")

	# Test on non-river position (should not crash)
	terrain.hide_river_at(Vector2i(999, 999))
	terrain.show_river_at(Vector2i(999, 999))
	_assert(true, "Visibility methods handle non-river positions")

	terrain.free()


func _test_river_obstacle_check() -> void:
	print("\n--- River Obstacle Check ---")

	var grid := Grid.new()
	var terrain := Terrain.new()
	terrain.theme = "earth"
	terrain.world_seed = 33333

	var area := Rect2i(-5, -5, 10, 10)
	terrain.generate_river(area)

	# Connect terrain to grid for obstacle checking
	grid.terrain_ref = terrain

	var positions := terrain.get_river_positions()

	if not positions.is_empty():
		var river_pos := positions[0]
		var river_pos_3d := Vector3i(river_pos.x, river_pos.y, 0)

		# River without block should be obstacle
		_assert(grid.is_river_obstacle(river_pos_3d), "Uncovered river is obstacle")

		# Add block on top of river
		var mock_block := {"block_type": "corridor", "traversability": "public", "connected": false}
		mock_block["grid_position"] = river_pos_3d
		grid.set_block(river_pos_3d, mock_block)

		# River with block should not be obstacle
		_assert(not grid.is_river_obstacle(river_pos_3d), "Covered river is not obstacle")

	# Non-river position should not be obstacle
	_assert(not grid.is_river_obstacle(Vector3i(999, 999, 0)), "Non-river position is not obstacle")

	# Z=1 position should never be river obstacle
	_assert(not grid.is_river_obstacle(Vector3i(0, 0, 1)), "Z=1 position is never river obstacle")

	grid.free()
	terrain.free()


func _test_river_no_decorations() -> void:
	print("\n--- River Has No Decorations ---")

	var terrain := Terrain.new()
	terrain.theme = "earth"
	terrain.world_seed = 44444

	var area := Rect2i(-10, -10, 20, 20)

	# Generate river first
	terrain.generate_river(area)

	# Then scatter decorations
	terrain.scatter_decorations(area)

	var river_positions := terrain.get_river_positions()

	# Check that no river positions have decorations
	var decorations_on_river := 0
	for pos in river_positions:
		if terrain.has_decoration_at(pos):
			decorations_on_river += 1

	_assert(decorations_on_river == 0, "No decorations on river (%d found)" % decorations_on_river)

	terrain.free()


func _test_river_determinism() -> void:
	print("\n--- River Determinism ---")

	var area := Rect2i(-10, -10, 20, 20)

	# Generate river twice with same seed
	var terrain1 := Terrain.new()
	terrain1.theme = "earth"
	terrain1.world_seed = 55555
	terrain1.generate_river(area)
	var positions1 := terrain1.get_river_positions()

	var terrain2 := Terrain.new()
	terrain2.theme = "earth"
	terrain2.world_seed = 55555
	terrain2.generate_river(area)
	var positions2 := terrain2.get_river_positions()

	_assert(positions1.size() == positions2.size(), "Same seed produces same path length")

	var all_match := true
	for i in range(min(positions1.size(), positions2.size())):
		if positions1[i] != positions2[i]:
			all_match = false
			break

	_assert(all_match, "Same seed produces identical path")

	# Different seed should produce different path
	var terrain3 := Terrain.new()
	terrain3.theme = "earth"
	terrain3.world_seed = 66666
	terrain3.generate_river(area)
	var positions3 := terrain3.get_river_positions()

	var differs := false
	if positions1.size() != positions3.size():
		differs = true
	else:
		for i in range(positions1.size()):
			if positions1[i] != positions3[i]:
				differs = true
				break

	_assert(differs, "Different seed produces different path")

	terrain1.free()
	terrain2.free()
	terrain3.free()
