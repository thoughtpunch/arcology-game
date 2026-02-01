extends SceneTree
## Unit tests for GameState

var game_state: Node


func _init() -> void:
	print("Testing GameState...")
	_setup()
	_test_initial_state()
	_test_set_floor()
	_test_floor_up()
	_test_floor_down()
	_test_floor_limits()
	_test_can_go_up_down()
	_test_signal_emission()
	print("GameState tests PASSED")
	quit()


func _setup() -> void:
	# Load the GameState script
	var GameStateScript = load("res://src/game/game_state.gd")
	game_state = GameStateScript.new()


func _test_initial_state() -> void:
	# Initial floor should be 0
	assert(game_state.current_floor == 0, "Initial floor should be 0")
	print("  initial state: OK")


func _test_set_floor() -> void:
	# Set to floor 5
	game_state.set_floor(5)
	assert(game_state.current_floor == 5, "Floor should be 5")

	# Set to floor 3
	game_state.set_floor(3)
	assert(game_state.current_floor == 3, "Floor should be 3")

	# Reset
	game_state.set_floor(0)
	print("  set_floor: OK")


func _test_floor_up() -> void:
	game_state.set_floor(0)

	game_state.floor_up()
	assert(game_state.current_floor == 1, "Floor should be 1 after floor_up")

	game_state.floor_up()
	assert(game_state.current_floor == 2, "Floor should be 2 after another floor_up")

	game_state.set_floor(0)
	print("  floor_up: OK")


func _test_floor_down() -> void:
	game_state.set_floor(5)

	game_state.floor_down()
	assert(game_state.current_floor == 4, "Floor should be 4 after floor_down")

	game_state.floor_down()
	assert(game_state.current_floor == 3, "Floor should be 3 after another floor_down")

	game_state.set_floor(0)
	print("  floor_down: OK")


func _test_floor_limits() -> void:
	# Test max limit
	game_state.set_floor(10)
	assert(game_state.current_floor == 10, "Floor should be 10 (max)")

	game_state.set_floor(15)
	assert(game_state.current_floor == 10, "Floor should clamp to 10 (max)")

	game_state.floor_up()
	assert(game_state.current_floor == 10, "Floor should stay at 10 when at max")

	# Test min limit
	game_state.set_floor(0)
	assert(game_state.current_floor == 0, "Floor should be 0 (min)")

	game_state.set_floor(-5)
	assert(game_state.current_floor == 0, "Floor should clamp to 0 (min)")

	game_state.floor_down()
	assert(game_state.current_floor == 0, "Floor should stay at 0 when at min")

	print("  floor_limits: OK")


func _test_can_go_up_down() -> void:
	# At floor 0: can go up, cannot go down
	game_state.set_floor(0)
	assert(game_state.can_go_up() == true, "Should be able to go up from floor 0")
	assert(game_state.can_go_down() == false, "Should NOT be able to go down from floor 0")

	# At floor 5: can go both
	game_state.set_floor(5)
	assert(game_state.can_go_up() == true, "Should be able to go up from floor 5")
	assert(game_state.can_go_down() == true, "Should be able to go down from floor 5")

	# At floor 10: cannot go up, can go down
	game_state.set_floor(10)
	assert(game_state.can_go_up() == false, "Should NOT be able to go up from floor 10")
	assert(game_state.can_go_down() == true, "Should be able to go down from floor 10")

	game_state.set_floor(0)
	print("  can_go_up_down: OK")


func _test_signal_emission() -> void:
	# Test that signal exists and can be connected
	assert(game_state.has_signal("floor_changed"), "Should have floor_changed signal")

	# Test signal connection count increases
	var callback := func(_floor_num: int) -> void:
		pass

	var initial_count: int = game_state.floor_changed.get_connections().size()
	game_state.floor_changed.connect(callback)
	var after_count: int = game_state.floor_changed.get_connections().size()
	assert(after_count == initial_count + 1, "Signal connection count should increase")

	game_state.floor_changed.disconnect(callback)
	print("  signal_emission: OK")
