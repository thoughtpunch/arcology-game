extends SceneTree
## Tests for GameState new game configuration
## Verifies: apply_new_game_config, money management, sandbox flags

var _game_state_script = preload("res://src/game/game_state.gd")


func _init():
	print("=== test_game_state_config.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_default_values(),
		_test_apply_config_basic(),
		_test_apply_config_starting_funds(),
		_test_apply_config_entropy_rate(),
		_test_apply_config_patience_rate(),
		_test_apply_config_sandbox_flags(),
		_test_money_management(),
		_test_spend_money_insufficient(),
		_test_unlimited_money(),
		_test_can_afford(),
		_test_reset_all(),
		_test_get_state(),
		_test_load_state(),
		_test_parse_funds_string(),
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


func _test_default_values() -> bool:
	print("\nTest: default values")
	var gs: Node = _game_state_script.new()

	# Check defaults
	assert(gs.money == 50000, "Default money should be 50000")
	assert(gs.arcology_name == "New Arcology", "Default name")
	assert(gs.scenario == "fresh_start", "Default scenario")
	assert(gs.entropy_multiplier == 1.0, "Default entropy")
	assert(gs.resident_patience_multiplier == 1.0, "Default patience")
	assert(gs.disasters_enabled == true, "Default disasters")
	assert(gs.unlimited_money == false, "Default unlimited_money")
	assert(gs.instant_construction == false, "Default instant_construction")
	assert(gs.all_blocks_unlocked == false, "Default all_blocks_unlocked")
	assert(gs.disable_failures == false, "Default disable_failures")

	gs.free()
	print("  PASSED")
	return true


func _test_apply_config_basic() -> bool:
	print("\nTest: apply_config_basic")
	var gs: Node = _game_state_script.new()

	var config := {
		"scenario": "troubled_tower",
		"name": "Test Arcology",
		"starting_funds": 25000,
		"disasters": false,
	}

	gs.apply_new_game_config(config)

	assert(gs.scenario == "troubled_tower", "Scenario should be updated")
	assert(gs.arcology_name == "Test Arcology", "Name should be updated")
	assert(gs.money == 25000, "Money should be updated")
	assert(gs.disasters_enabled == false, "Disasters should be disabled")

	gs.free()
	print("  PASSED")
	return true


func _test_apply_config_starting_funds() -> bool:
	print("\nTest: apply_config_starting_funds (string format)")
	var gs: Node = _game_state_script.new()

	# Test string format from dropdown
	var config := {
		"starting_funds": "$100,000 (Easy)",
	}

	gs.apply_new_game_config(config)
	assert(gs.money == 100000, "Should parse $100,000 (Easy) to 100000, got %d" % gs.money)

	# Test another format
	config = {"starting_funds": "$25,000 (Hard)"}
	gs.apply_new_game_config(config)
	assert(gs.money == 25000, "Should parse $25,000 (Hard) to 25000, got %d" % gs.money)

	gs.free()
	print("  PASSED")
	return true


func _test_apply_config_entropy_rate() -> bool:
	print("\nTest: apply_config_entropy_rate")
	var gs: Node = _game_state_script.new()

	# Test Fast
	gs.apply_new_game_config({"entropy_rate": "Fast"})
	assert(gs.entropy_multiplier == 1.5, "Fast should be 1.5x")

	# Test Normal
	gs.apply_new_game_config({"entropy_rate": "Normal"})
	assert(gs.entropy_multiplier == 1.0, "Normal should be 1.0x")

	# Test Slow
	gs.apply_new_game_config({"entropy_rate": "Slow"})
	assert(gs.entropy_multiplier == 0.5, "Slow should be 0.5x")

	gs.free()
	print("  PASSED")
	return true


func _test_apply_config_patience_rate() -> bool:
	print("\nTest: apply_config_patience_rate")
	var gs: Node = _game_state_script.new()

	# Test Impatient
	gs.apply_new_game_config({"resident_patience": "Impatient"})
	assert(gs.resident_patience_multiplier == 0.5, "Impatient should be 0.5x")

	# Test Normal
	gs.apply_new_game_config({"resident_patience": "Normal"})
	assert(gs.resident_patience_multiplier == 1.0, "Normal should be 1.0x")

	# Test Patient
	gs.apply_new_game_config({"resident_patience": "Patient"})
	assert(gs.resident_patience_multiplier == 2.0, "Patient should be 2.0x")

	gs.free()
	print("  PASSED")
	return true


func _test_apply_config_sandbox_flags() -> bool:
	print("\nTest: apply_config_sandbox_flags")
	var gs: Node = _game_state_script.new()

	var config := {
		"unlimited_money": true,
		"instant_construction": true,
		"all_blocks_unlocked": true,
		"disable_failures": true,
	}

	gs.apply_new_game_config(config)

	assert(gs.unlimited_money == true, "unlimited_money should be true")
	assert(gs.instant_construction == true, "instant_construction should be true")
	assert(gs.all_blocks_unlocked == true, "all_blocks_unlocked should be true")
	assert(gs.disable_failures == true, "disable_failures should be true")

	gs.free()
	print("  PASSED")
	return true


func _test_money_management() -> bool:
	print("\nTest: money_management")
	var gs: Node = _game_state_script.new()
	gs.money = 1000

	# Add money
	var result: bool = gs.add_money(500)
	assert(result == true, "add_money should succeed")
	assert(gs.money == 1500, "Money should be 1500")

	# Spend money (via add_money with negative)
	result = gs.add_money(-300)
	assert(result == true, "Spending 300 should succeed")
	assert(gs.money == 1200, "Money should be 1200")

	gs.free()
	print("  PASSED")
	return true


func _test_spend_money_insufficient() -> bool:
	print("\nTest: spend_money_insufficient")
	var gs: Node = _game_state_script.new()
	gs.money = 100

	# Try to spend more than available
	var result: bool = gs.spend_money(500)
	assert(result == false, "spend_money should fail with insufficient funds")
	assert(gs.money == 100, "Money should not change")

	# Spend exact amount
	result = gs.spend_money(100)
	assert(result == true, "Spending exact amount should work")
	assert(gs.money == 0, "Money should be 0")

	gs.free()
	print("  PASSED")
	return true


func _test_unlimited_money() -> bool:
	print("\nTest: unlimited_money")
	var gs: Node = _game_state_script.new()
	gs.money = 100
	gs.unlimited_money = true

	# Spend more than available with unlimited
	var result: bool = gs.spend_money(10000)
	assert(result == true, "spend_money should succeed with unlimited_money")
	# Note: money doesn't decrease in unlimited mode

	# Can spend any amount
	result = gs.add_money(-99999)
	assert(result == true, "Negative add_money should succeed with unlimited")

	gs.free()
	print("  PASSED")
	return true


func _test_can_afford() -> bool:
	print("\nTest: can_afford")
	var gs: Node = _game_state_script.new()
	gs.money = 500

	assert(gs.can_afford(500) == true, "Can afford exact amount")
	assert(gs.can_afford(499) == true, "Can afford less")
	assert(gs.can_afford(501) == false, "Cannot afford more")

	# With unlimited money
	gs.unlimited_money = true
	assert(gs.can_afford(999999) == true, "Can afford anything with unlimited")

	gs.free()
	print("  PASSED")
	return true


func _test_reset_all() -> bool:
	print("\nTest: reset_all")
	var gs: Node = _game_state_script.new()

	# Set various non-default values
	gs.money = 999999
	gs.arcology_name = "Modified"
	gs.unlimited_money = true
	gs.year = 10
	gs.current_floor = 5

	gs.reset_all()

	assert(gs.money == 50000, "Money should be reset to 50000")
	assert(gs.arcology_name == "New Arcology", "Name should be reset")
	assert(gs.unlimited_money == false, "unlimited_money should be reset")
	assert(gs.year == 1, "Year should be reset")
	assert(gs.current_floor == 0, "Floor should be reset")

	gs.free()
	print("  PASSED")
	return true


func _test_get_state() -> bool:
	print("\nTest: get_state")
	var gs: Node = _game_state_script.new()
	gs.money = 75000
	gs.arcology_name = "Test State"
	gs.unlimited_money = true
	gs.year = 5

	var state: Dictionary = gs.get_state()

	assert(state.money == 75000, "State should include money")
	assert(state.arcology_name == "Test State", "State should include name")
	assert(state.unlimited_money == true, "State should include sandbox flags")
	assert(state.year == 5, "State should include time")

	gs.free()
	print("  PASSED")
	return true


func _test_load_state() -> bool:
	print("\nTest: load_state")
	var gs: Node = _game_state_script.new()

	var state := {
		"arcology_name": "Loaded Arcology",
		"scenario": "crisis_mode",
		"money": 12345,
		"population": 500,
		"aei_score": 85.5,
		"current_floor": 3,
		"year": 7,
		"month": 6,
		"day": 15,
		"hour": 14,
		"game_speed": 2,
		"unlimited_money": true,
		"instant_construction": true,
	}

	gs.load_state(state)

	assert(gs.arcology_name == "Loaded Arcology", "Name should be loaded")
	assert(gs.scenario == "crisis_mode", "Scenario should be loaded")
	assert(gs.money == 12345, "Money should be loaded")
	assert(gs.population == 500, "Population should be loaded")
	assert(gs.aei_score == 85.5, "AEI should be loaded")
	assert(gs.current_floor == 3, "Floor should be loaded")
	assert(gs.year == 7, "Year should be loaded")
	assert(gs.unlimited_money == true, "Sandbox flags should be loaded")

	gs.free()
	print("  PASSED")
	return true


func _test_parse_funds_string() -> bool:
	print("\nTest: parse_funds_string")
	var gs: Node = _game_state_script.new()

	# Test various formats
	assert(gs._parse_funds_string("$25,000 (Hard)") == 25000, "Parse 25,000")
	assert(gs._parse_funds_string("$50,000 (Normal)") == 50000, "Parse 50,000")
	assert(gs._parse_funds_string("$100,000 (Easy)") == 100000, "Parse 100,000")
	assert(gs._parse_funds_string("1000") == 1000, "Parse plain number")
	assert(gs._parse_funds_string("invalid") == 50000, "Invalid returns default")

	gs.free()
	print("  PASSED")
	return true
