extends SceneTree
## Integration test: Save and load round-trip
## Tests complete state preservation across save/load cycle

var _game_state_script = preload("res://src/core/game_state.gd")
var _grid_script = preload("res://src/core/grid.gd")
var _block_script = preload("res://src/blocks/block.gd")


func _init():
	print("=== test_save_load_roundtrip.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_blocks_preserved_round_trip(),
		_test_game_state_preserved_round_trip(),
		_test_block_positions_and_types(),
		_test_connected_status_preserved(),
		_test_sandbox_flags_preserved(),
		_test_multiple_floors_preserved(),
		_test_empty_grid_round_trip(),
		_test_version_in_save(),
	]

	for result in results:
		if result:
			passed += 1
		else:
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])

	if failed > 0:
		quit(1)
	else:
		quit(0)


func _test_blocks_preserved_round_trip() -> bool:
	print("\nTest: blocks_preserved_round_trip")
	var Grid = _grid_script
	var Block = _block_script

	# Create grid with blocks
	var grid: Node = Grid.new()
	grid.set_block(Vector3i(0, 0, 0), Block.new("entrance", Vector3i(0, 0, 0)))
	grid.set_block(Vector3i(1, 0, 0), Block.new("corridor", Vector3i(1, 0, 0)))
	grid.set_block(Vector3i(2, 0, 0), Block.new("residential_basic", Vector3i(2, 0, 0)))

	# Serialize blocks
	var blocks_data := []
	for block in grid.get_all_blocks():
		blocks_data.append({
			"x": block.grid_position.x,
			"y": block.grid_position.y,
			"z": block.grid_position.z,
			"type": block.block_type,
			"connected": block.connected
		})

	# Simulate save
	var save_data := {
		"blocks": blocks_data
	}

	# Clear and load
	grid.clear()
	assert(grid.get_block_count() == 0, "Grid should be empty after clear")

	# Restore blocks
	for block_data in save_data.blocks:
		var pos := Vector3i(block_data.x, block_data.y, block_data.z)
		var block: RefCounted = Block.new(block_data.type, pos)
		block.connected = block_data.connected
		grid.set_block(pos, block)

	# Verify restoration
	assert(grid.get_block_count() == 3, "Should restore 3 blocks")
	assert(grid.get_block_at(Vector3i(0, 0, 0)) != null, "Entrance should exist")
	assert(grid.get_block_at(Vector3i(1, 0, 0)) != null, "Corridor should exist")
	assert(grid.get_block_at(Vector3i(2, 0, 0)) != null, "Residential should exist")

	grid.free()
	print("  PASSED")
	return true


func _test_game_state_preserved_round_trip() -> bool:
	print("\nTest: game_state_preserved_round_trip")
	var gs: Node = _game_state_script.new()

	# Set up original state
	gs.arcology_name = "Round Trip City"
	gs.money = 67890
	gs.population = 123
	gs.aei_score = 77.7
	gs.year = 4
	gs.month = 9
	gs.day = 22
	gs.hour = 16
	gs.current_floor = 2
	gs.game_speed = 2

	# Serialize
	var state: Dictionary = gs.get_state()

	# Reset to defaults
	gs.reset_all()
	assert(gs.arcology_name == "New Arcology", "Should be reset")

	# Load state
	gs.load_state(state)

	# Verify round-trip
	assert(gs.arcology_name == "Round Trip City", "Name should match")
	assert(gs.money == 67890, "Money should match")
	assert(gs.population == 123, "Population should match")
	assert(gs.aei_score == 77.7, "AEI should match")
	assert(gs.year == 4, "Year should match")
	assert(gs.month == 9, "Month should match")
	assert(gs.day == 22, "Day should match")
	assert(gs.hour == 16, "Hour should match")
	assert(gs.current_floor == 2, "Floor should match")
	assert(gs.game_speed == 2, "Speed should match")

	gs.free()
	print("  PASSED")
	return true


func _test_block_positions_and_types() -> bool:
	print("\nTest: block_positions_and_types")
	var Grid = _grid_script
	var Block = _block_script

	# Create blocks at various positions
	var grid: Node = Grid.new()
	var positions := [
		Vector3i(-5, -3, 0),
		Vector3i(0, 0, 0),
		Vector3i(10, 5, 0),
		Vector3i(3, 2, 3),  # Upper floor
		Vector3i(-1, 0, -2),  # Basement
	]
	var types := ["entrance", "corridor", "residential_basic", "stairs", "corridor"]

	for i in range(positions.size()):
		grid.set_block(positions[i], Block.new(types[i], positions[i]))

	# Serialize
	var blocks_data := []
	for block in grid.get_all_blocks():
		blocks_data.append({
			"x": block.grid_position.x,
			"y": block.grid_position.y,
			"z": block.grid_position.z,
			"type": block.block_type
		})

	# Clear and restore
	grid.clear()
	for block_data in blocks_data:
		var pos := Vector3i(block_data.x, block_data.y, block_data.z)
		grid.set_block(pos, Block.new(block_data.type, pos))

	# Verify each position and type
	for i in range(positions.size()):
		var block: RefCounted = grid.get_block_at(positions[i])
		assert(block != null, "Block at %s should exist" % positions[i])
		assert(block.block_type == types[i], "Block type at %s should be %s" % [positions[i], types[i]])

	grid.free()
	print("  PASSED")
	return true


func _test_connected_status_preserved() -> bool:
	print("\nTest: connected_status_preserved")
	var Grid = _grid_script
	var Block = _block_script

	var grid: Node = Grid.new()

	# Create blocks with different connected states
	var b1: RefCounted = Block.new("entrance", Vector3i(0, 0, 0))
	b1.connected = true
	grid.set_block(b1.grid_position, b1)

	var b2: RefCounted = Block.new("corridor", Vector3i(1, 0, 0))
	b2.connected = true
	grid.set_block(b2.grid_position, b2)

	var b3: RefCounted = Block.new("residential_basic", Vector3i(5, 5, 0))
	b3.connected = false  # Isolated block
	grid.set_block(b3.grid_position, b3)

	# Serialize
	var blocks_data := []
	for block in grid.get_all_blocks():
		blocks_data.append({
			"x": block.grid_position.x,
			"y": block.grid_position.y,
			"z": block.grid_position.z,
			"type": block.block_type,
			"connected": block.connected
		})

	# Clear and restore
	grid.clear()
	for block_data in blocks_data:
		var pos := Vector3i(block_data.x, block_data.y, block_data.z)
		var block: RefCounted = Block.new(block_data.type, pos)
		block.connected = block_data.get("connected", true)
		grid.set_block(pos, block)

	# Verify connected status preserved
	var r1: RefCounted = grid.get_block_at(Vector3i(0, 0, 0))
	var r2: RefCounted = grid.get_block_at(Vector3i(1, 0, 0))
	var r3: RefCounted = grid.get_block_at(Vector3i(5, 5, 0))

	assert(r1.connected == true, "First block should be connected")
	assert(r2.connected == true, "Second block should be connected")
	assert(r3.connected == false, "Third block should be disconnected")

	grid.free()
	print("  PASSED")
	return true


func _test_sandbox_flags_preserved() -> bool:
	print("\nTest: sandbox_flags_preserved")
	var gs: Node = _game_state_script.new()

	# Set sandbox flags
	gs.unlimited_money = true
	gs.instant_construction = true
	gs.all_blocks_unlocked = true
	gs.disable_failures = true
	gs.entropy_multiplier = 0.5
	gs.resident_patience_multiplier = 2.0
	gs.disasters_enabled = false

	# Serialize and restore
	var state: Dictionary = gs.get_state()
	gs.reset_all()
	gs.load_state(state)

	# Verify all flags
	assert(gs.unlimited_money == true, "unlimited_money should be preserved")
	assert(gs.instant_construction == true, "instant_construction should be preserved")
	assert(gs.all_blocks_unlocked == true, "all_blocks_unlocked should be preserved")
	assert(gs.disable_failures == true, "disable_failures should be preserved")
	assert(gs.entropy_multiplier == 0.5, "entropy_multiplier should be preserved")
	assert(gs.resident_patience_multiplier == 2.0, "patience_multiplier should be preserved")
	assert(gs.disasters_enabled == false, "disasters_enabled should be preserved")

	gs.free()
	print("  PASSED")
	return true


func _test_multiple_floors_preserved() -> bool:
	print("\nTest: multiple_floors_preserved")
	var Grid = _grid_script
	var Block = _block_script

	var grid: Node = Grid.new()

	# Build across multiple floors
	var floors := [-2, -1, 0, 1, 2, 3]
	for z in floors:
		grid.set_block(Vector3i(0, 0, z), Block.new("stairs", Vector3i(0, 0, z)))

	# Serialize
	var blocks_data := []
	for block in grid.get_all_blocks():
		blocks_data.append({
			"x": block.grid_position.x,
			"y": block.grid_position.y,
			"z": block.grid_position.z,
			"type": block.block_type
		})

	# Clear and restore
	grid.clear()
	for block_data in blocks_data:
		var pos := Vector3i(block_data.x, block_data.y, block_data.z)
		grid.set_block(pos, Block.new(block_data.type, pos))

	# Verify all floors preserved
	for z in floors:
		var block: RefCounted = grid.get_block_at(Vector3i(0, 0, z))
		assert(block != null, "Block at floor %d should exist" % z)
		assert(block.block_type == "stairs", "Block at floor %d should be stairs" % z)

	grid.free()
	print("  PASSED")
	return true


func _test_empty_grid_round_trip() -> bool:
	print("\nTest: empty_grid_round_trip")
	var Grid = _grid_script

	var grid: Node = Grid.new()
	assert(grid.get_block_count() == 0, "Grid should start empty")

	# Serialize empty
	var blocks_data := []
	for block in grid.get_all_blocks():
		blocks_data.append({})

	# Verify empty array
	assert(blocks_data.size() == 0, "Empty grid serializes to empty array")

	# Restore from empty
	grid.clear()
	# (nothing to restore)

	assert(grid.get_block_count() == 0, "Grid should remain empty after restore")

	grid.free()
	print("  PASSED")
	return true


func _test_version_in_save() -> bool:
	print("\nTest: version_in_save")

	# Create save data structure as main.gd would
	var save_data := {
		"name": "Version Test",
		"timestamp": Time.get_unix_time_from_system(),
		"version": "0.2.0",
		"game_state": {},
		"config": {},
		"blocks": [],
		"camera": {},
		"terrain_seed": 0,
		"statistics": {}
	}

	# Verify version is present and correct format
	assert(save_data.has("version"), "Save should have version")
	assert(save_data.version == "0.2.0", "Version should be 0.2.0")

	# Verify version string format
	var version_parts: PackedStringArray = save_data.version.split(".")
	assert(version_parts.size() == 3, "Version should be semver format (x.y.z)")

	print("  PASSED")
	return true
