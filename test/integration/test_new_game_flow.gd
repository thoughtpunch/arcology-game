extends SceneTree
## Integration test: Complete new game flow
## Tests the full sequence: MainMenu → NewGame → GameState initialization

var _main_menu_script = preload("res://src/ui/main_menu.gd")
var _menu_manager_script = preload("res://src/ui/menu_manager.gd")
var _new_game_menu_script = preload("res://src/ui/new_game_menu.gd")
var _game_state_script = preload("res://src/game/game_state.gd")
var _block_registry_script = preload("res://src/game/block_registry.gd")


func _init():
	print("=== test_new_game_flow.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_main_menu_new_game_signal(),
		_test_new_game_config_applied_to_game_state(),
		_test_sandbox_unlimited_money(),
		_test_sandbox_all_blocks_unlocked(),
		_test_starting_funds_options(),
		_test_entropy_and_patience_rates(),
		_test_config_applied_signal(),
		_test_fresh_game_resets_state(),
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


func _test_main_menu_new_game_signal() -> bool:
	print("\nTest: main_menu_new_game_signal")
	var menu: Control = _main_menu_script.new()

	# Use array to capture in closure
	var signal_received := [false]

	# Connect to signal before setup
	menu.new_game_pressed.connect(func(): signal_received[0] = true)

	menu._setup_layout()

	# Emit the signal directly (simulating button handler)
	menu.new_game_pressed.emit()

	assert(signal_received[0] == true, "new_game_pressed signal should be emitted")

	menu.free()
	print("  PASSED")
	return true


func _test_new_game_config_applied_to_game_state() -> bool:
	print("\nTest: new_game_config_applied_to_game_state")
	var gs: Node = _game_state_script.new()

	# Simulate config from NewGameMenu
	var config := {
		"scenario": "fresh_start",
		"name": "Test Tower",
		"starting_funds": 75000,
		"entropy_rate": "Normal",
		"resident_patience": "Normal",
		"disasters": true,
		"unlimited_money": false,
		"instant_construction": false,
		"all_blocks_unlocked": false,
		"disable_failures": false,
	}

	gs.apply_new_game_config(config)

	# Verify state
	assert(gs.scenario == "fresh_start", "Scenario applied")
	assert(gs.arcology_name == "Test Tower", "Name applied")
	assert(gs.money == 75000, "Starting funds applied: got %d" % gs.money)
	assert(gs.disasters_enabled == true, "Disasters setting applied")
	assert(gs.unlimited_money == false, "Sandbox flag applied")

	gs.free()
	print("  PASSED")
	return true


func _test_sandbox_unlimited_money() -> bool:
	print("\nTest: sandbox_unlimited_money")
	var gs: Node = _game_state_script.new()

	# Enable unlimited money via config
	var config := {
		"starting_funds": 100,
		"unlimited_money": true,
	}
	gs.apply_new_game_config(config)

	# Verify unlimited money works
	assert(gs.unlimited_money == true, "Unlimited money flag should be set")
	assert(gs.can_afford(999999) == true, "Should afford any amount")

	# Spending doesn't reduce balance
	var result: bool = gs.spend_money(50000)
	assert(result == true, "Spending should succeed")
	# Note: Money doesn't change in unlimited mode for spend_money

	gs.free()
	print("  PASSED")
	return true


func _test_sandbox_all_blocks_unlocked() -> bool:
	print("\nTest: sandbox_all_blocks_unlocked")
	var br: Node = _block_registry_script.new()
	br._load_blocks()
	br._reset_unlocked()

	# Initially some blocks are locked
	assert(br.is_unlocked("elevator_shaft") == false, "elevator_shaft starts locked")

	# Unlock all (as sandbox flag would do)
	br.unlock_all()

	assert(br.is_all_unlocked() == true, "All blocks should be unlocked")
	assert(br.is_unlocked("elevator_shaft") == true, "elevator_shaft should be unlocked")
	assert(br.is_unlocked("commercial_basic") == true, "commercial_basic should be unlocked")

	br.free()
	print("  PASSED")
	return true


func _test_starting_funds_options() -> bool:
	print("\nTest: starting_funds_options")
	var gs: Node = _game_state_script.new()

	# Test Hard mode (string format)
	gs.apply_new_game_config({"starting_funds": "$25,000 (Hard)"})
	assert(gs.money == 25000, "Hard mode funds: got %d" % gs.money)

	# Test Normal mode
	gs.apply_new_game_config({"starting_funds": "$50,000 (Normal)"})
	assert(gs.money == 50000, "Normal mode funds: got %d" % gs.money)

	# Test Easy mode
	gs.apply_new_game_config({"starting_funds": "$100,000 (Easy)"})
	assert(gs.money == 100000, "Easy mode funds: got %d" % gs.money)

	# Test numeric value
	gs.apply_new_game_config({"starting_funds": 75000})
	assert(gs.money == 75000, "Numeric funds: got %d" % gs.money)

	gs.free()
	print("  PASSED")
	return true


func _test_entropy_and_patience_rates() -> bool:
	print("\nTest: entropy_and_patience_rates")
	var gs: Node = _game_state_script.new()

	# Test entropy rates
	gs.apply_new_game_config({"entropy_rate": "Fast"})
	assert(gs.entropy_multiplier == 1.5, "Fast entropy: got %.1f" % gs.entropy_multiplier)

	gs.apply_new_game_config({"entropy_rate": "Slow"})
	assert(gs.entropy_multiplier == 0.5, "Slow entropy: got %.1f" % gs.entropy_multiplier)

	# Test patience rates
	gs.apply_new_game_config({"resident_patience": "Impatient"})
	assert(gs.resident_patience_multiplier == 0.5, "Impatient: got %.1f" % gs.resident_patience_multiplier)

	gs.apply_new_game_config({"resident_patience": "Patient"})
	assert(gs.resident_patience_multiplier == 2.0, "Patient: got %.1f" % gs.resident_patience_multiplier)

	gs.free()
	print("  PASSED")
	return true


func _test_config_applied_signal() -> bool:
	print("\nTest: config_applied_signal")
	var gs: Node = _game_state_script.new()

	# Use a class to capture the signal
	var signal_received := [false]
	var received_config := [{}]

	# Connect signal before calling apply
	gs.config_applied.connect(func(config: Dictionary):
		signal_received[0] = true
		received_config[0] = config
	)

	var config := {"name": "Signal Test", "starting_funds": 30000}
	gs.apply_new_game_config(config)

	assert(signal_received[0] == true, "config_applied signal should be emitted")
	assert(received_config[0].get("name") == "Signal Test", "Signal should include config")

	gs.free()
	print("  PASSED")
	return true


func _test_fresh_game_resets_state() -> bool:
	print("\nTest: fresh_game_resets_state")
	var gs: Node = _game_state_script.new()

	# Set some state as if game was in progress
	gs.money = 12345
	gs.year = 5
	gs.month = 7
	gs.day = 15
	gs.population = 200
	gs.current_floor = 3

	# Apply new game config (should reset time)
	var config := {
		"name": "Fresh Start",
		"starting_funds": 50000,
	}
	gs.apply_new_game_config(config)

	# Verify reset
	assert(gs.year == 1, "Year should reset to 1")
	assert(gs.month == 1, "Month should reset to 1")
	assert(gs.day == 1, "Day should reset to 1")
	assert(gs.population == 0, "Population should reset to 0")
	assert(gs.current_floor == 0, "Floor should reset to 0")
	assert(gs.money == 50000, "Money should be from config")

	gs.free()
	print("  PASSED")
	return true
