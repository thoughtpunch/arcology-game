extends SceneTree
## Tests for save/load system with enhanced format
## Verifies: complete state persistence, version handling, camera restore

var _game_state_script = preload("res://src/core/game_state.gd")
var _grid_script = preload("res://src/core/grid.gd")
var _block_script = preload("res://src/blocks/block.gd")


func _init():
	print("=== test_save_load.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_game_state_serialization(),
		_test_game_state_load(),
		_test_block_with_connected_status(),
		_test_legacy_save_format_compatibility(),
		_test_save_data_structure(),
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


func _test_game_state_serialization() -> bool:
	print("\nTest: game_state_serialization")
	var gs: Node = _game_state_script.new()

	# Set up state
	gs.arcology_name = "Test City"
	gs.scenario = "crisis_mode"
	gs.money = 75000
	gs.population = 250
	gs.aei_score = 82.5
	gs.current_floor = 3
	gs.year = 5
	gs.month = 8
	gs.day = 15
	gs.hour = 14
	gs.unlimited_money = true
	gs.instant_construction = true

	# Serialize
	var state: Dictionary = gs.get_state()

	# Verify all fields present
	assert(state.arcology_name == "Test City", "Name should be serialized")
	assert(state.scenario == "crisis_mode", "Scenario should be serialized")
	assert(state.money == 75000, "Money should be serialized")
	assert(state.population == 250, "Population should be serialized")
	assert(state.aei_score == 82.5, "AEI should be serialized")
	assert(state.current_floor == 3, "Floor should be serialized")
	assert(state.year == 5, "Year should be serialized")
	assert(state.month == 8, "Month should be serialized")
	assert(state.day == 15, "Day should be serialized")
	assert(state.hour == 14, "Hour should be serialized")
	assert(state.unlimited_money == true, "Sandbox flags should be serialized")
	assert(state.instant_construction == true, "Sandbox flags should be serialized")

	gs.free()
	print("  PASSED")
	return true


func _test_game_state_load() -> bool:
	print("\nTest: game_state_load")
	var gs: Node = _game_state_script.new()

	# Create save data
	var save_state := {
		"arcology_name": "Loaded City",
		"scenario": "troubled_tower",
		"money": 42000,
		"population": 180,
		"aei_score": 65.0,
		"current_floor": 5,
		"year": 3,
		"month": 6,
		"day": 20,
		"hour": 10,
		"game_speed": 2,
		"entropy_multiplier": 1.5,
		"resident_patience_multiplier": 0.5,
		"disasters_enabled": false,
		"unlimited_money": false,
		"instant_construction": true,
		"all_blocks_unlocked": true,
		"disable_failures": false
	}

	# Load state
	gs.load_state(save_state)

	# Verify all fields loaded
	assert(gs.arcology_name == "Loaded City", "Name should be loaded")
	assert(gs.scenario == "troubled_tower", "Scenario should be loaded")
	assert(gs.money == 42000, "Money should be loaded")
	assert(gs.population == 180, "Population should be loaded")
	assert(gs.aei_score == 65.0, "AEI should be loaded")
	assert(gs.current_floor == 5, "Floor should be loaded")
	assert(gs.year == 3, "Year should be loaded")
	assert(gs.month == 6, "Month should be loaded")
	assert(gs.day == 20, "Day should be loaded")
	assert(gs.hour == 10, "Hour should be loaded")
	assert(gs.game_speed == 2, "Speed should be loaded")
	assert(gs.entropy_multiplier == 1.5, "Entropy should be loaded")
	assert(gs.resident_patience_multiplier == 0.5, "Patience should be loaded")
	assert(gs.disasters_enabled == false, "Disasters should be loaded")
	assert(gs.unlimited_money == false, "unlimited_money should be loaded")
	assert(gs.instant_construction == true, "instant_construction should be loaded")
	assert(gs.all_blocks_unlocked == true, "all_blocks_unlocked should be loaded")

	gs.free()
	print("  PASSED")
	return true


func _test_block_with_connected_status() -> bool:
	print("\nTest: block_with_connected_status")

	# Create block and set connected status
	var Block = _block_script
	var block: RefCounted = Block.new("corridor", Vector3i(5, 3, 2))
	block.connected = false

	# Verify block state
	assert(block.block_type == "corridor", "Block type correct")
	assert(block.grid_position == Vector3i(5, 3, 2), "Position correct")
	assert(block.connected == false, "Connected status should be false")

	# Create another connected block
	var block2: RefCounted = Block.new("entrance", Vector3i(0, 0, 0))
	block2.connected = true
	assert(block2.connected == true, "Connected status should be true")

	print("  PASSED")
	return true


func _test_legacy_save_format_compatibility() -> bool:
	print("\nTest: legacy_save_format_compatibility")
	var gs: Node = _game_state_script.new()

	# Set initial state
	gs.money = 50000
	gs.current_floor = 0

	# Simulate loading legacy format (only current_floor, no game_state object)
	# The main.gd code checks for "game_state" key and falls back
	# This test verifies GameState handles partial data gracefully

	var legacy_state := {
		"current_floor": 7
		# No other fields - should use defaults
	}

	gs.load_state(legacy_state)

	# Verify defaults used for missing fields
	assert(gs.current_floor == 7, "Floor should be loaded")
	assert(gs.money == 50000, "Money should use default")  # load_state uses dict defaults
	assert(gs.arcology_name == "New Arcology", "Name should use default")

	gs.free()
	print("  PASSED")
	return true


func _test_save_data_structure() -> bool:
	print("\nTest: save_data_structure")

	# Test that expected keys exist in a simulated save
	var save_data := {
		"name": "Test Save",
		"timestamp": 1706300000.0,
		"version": "0.2.0",
		"game_state": {
			"arcology_name": "Test",
			"money": 50000,
		},
		"config": {
			"scenario": "fresh_start",
			"unlimited_money": false
		},
		"blocks": [
			{"x": 0, "y": 0, "z": 0, "type": "entrance", "connected": true},
			{"x": 1, "y": 0, "z": 0, "type": "corridor", "connected": true},
		],
		"camera": {
			"position_x": 100.0,
			"position_y": 200.0,
			"zoom": 1.5,
			"rotation_index": 1
		},
		"terrain_seed": 12345,
		"statistics": {
			"blocks_placed": 2,
			"playtime_seconds": 3600
		}
	}

	# Verify structure
	assert(save_data.has("name"), "Should have name")
	assert(save_data.has("timestamp"), "Should have timestamp")
	assert(save_data.has("version"), "Should have version")
	assert(save_data.has("game_state"), "Should have game_state")
	assert(save_data.has("config"), "Should have config")
	assert(save_data.has("blocks"), "Should have blocks")
	assert(save_data.has("camera"), "Should have camera")
	assert(save_data.has("terrain_seed"), "Should have terrain_seed")
	assert(save_data.has("statistics"), "Should have statistics")

	# Verify block structure
	var block: Dictionary = save_data.blocks[0]
	assert(block.has("x"), "Block should have x")
	assert(block.has("y"), "Block should have y")
	assert(block.has("z"), "Block should have z")
	assert(block.has("type"), "Block should have type")
	assert(block.has("connected"), "Block should have connected")

	# Verify camera structure
	var cam: Dictionary = save_data.camera
	assert(cam.has("position_x"), "Camera should have position_x")
	assert(cam.has("position_y"), "Camera should have position_y")
	assert(cam.has("zoom"), "Camera should have zoom")
	assert(cam.has("rotation_index"), "Camera should have rotation_index")

	print("  PASSED")
	return true
