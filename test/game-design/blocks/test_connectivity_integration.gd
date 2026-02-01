extends SceneTree
## Integration tests for connectivity with BlockRegistry autoload
## These tests load the full scene to test traversability rules

var _tests_passed := 0
var _tests_failed := 0


func _init():
	print("=== Connectivity Integration Tests ===")

	# Load BlockRegistry to enable proper traversability checks
	var block_registry_script = load("res://src/game/block_registry.gd")
	var block_registry = block_registry_script.new()
	root.add_child(block_registry)
	block_registry.name = "BlockRegistry"
	# Manually call _load_blocks since _ready() doesn't fire until next frame
	block_registry._load_blocks()

	_test_private_block_not_traversable()
	_test_corridor_is_traversable()
	_test_stairs_connect_vertically()
	_test_elevator_connects_vertically()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


func _assert(condition: bool, message: String):
	if condition:
		_tests_passed += 1
		print("  ✓ " + message)
	else:
		_tests_failed += 1
		print("  ✗ " + message)


func _test_private_block_not_traversable():
	print("\nTest: Cannot traverse THROUGH private blocks (with registry)")
	var grid = Grid.new()
	grid.block_registry = root.get_node("BlockRegistry")  # Set registry directly
	root.add_child(grid)

	var entrance = Block.new("entrance", Vector3i(0, 0, 0))
	var residential = Block.new("residential_basic", Vector3i(1, 0, 0))
	var end_corridor = Block.new("corridor", Vector3i(2, 0, 0))

	grid.set_block(Vector3i(0, 0, 0), entrance)
	grid.set_block(Vector3i(1, 0, 0), residential)
	grid.set_block(Vector3i(2, 0, 0), end_corridor)
	grid.calculate_connectivity()

	_assert(entrance.connected == true, "Entrance should be connected")
	_assert(residential.connected == true, "Residential is reachable from entrance")
	_assert(end_corridor.connected == false, "Corridor behind residential should NOT be connected")

	grid.queue_free()


func _test_corridor_is_traversable():
	print("\nTest: CAN traverse through public corridor")
	var grid = Grid.new()
	grid.block_registry = root.get_node("BlockRegistry")
	root.add_child(grid)

	var entrance = Block.new("entrance", Vector3i(0, 0, 0))
	var corridor = Block.new("corridor", Vector3i(1, 0, 0))
	var end_residential = Block.new("residential_basic", Vector3i(2, 0, 0))

	grid.set_block(Vector3i(0, 0, 0), entrance)
	grid.set_block(Vector3i(1, 0, 0), corridor)
	grid.set_block(Vector3i(2, 0, 0), end_residential)
	grid.calculate_connectivity()

	_assert(entrance.connected == true, "Entrance should be connected")
	_assert(corridor.connected == true, "Corridor should be connected")
	_assert(end_residential.connected == true, "Residential via corridor should be connected")

	grid.queue_free()


func _test_stairs_connect_vertically():
	print("\nTest: Stairs connect floors vertically")
	var grid = Grid.new()
	grid.block_registry = root.get_node("BlockRegistry")
	root.add_child(grid)

	var entrance = Block.new("entrance", Vector3i(0, 0, 0))
	var stairs_bottom = Block.new("stairs", Vector3i(1, 0, 0))
	var stairs_top = Block.new("stairs", Vector3i(1, 0, 1))
	var corridor_top = Block.new("corridor", Vector3i(2, 0, 1))

	grid.set_block(Vector3i(0, 0, 0), entrance)
	grid.set_block(Vector3i(1, 0, 0), stairs_bottom)
	grid.set_block(Vector3i(1, 0, 1), stairs_top)
	grid.set_block(Vector3i(2, 0, 1), corridor_top)
	grid.calculate_connectivity()

	_assert(entrance.connected == true, "Entrance should be connected")
	_assert(stairs_bottom.connected == true, "Bottom stairs should be connected")
	_assert(stairs_top.connected == true, "Top stairs should be connected")
	_assert(corridor_top.connected == true, "Upper corridor should be connected via stairs")

	grid.queue_free()


func _test_elevator_connects_vertically():
	print("\nTest: Elevator connects multiple floors")
	var grid = Grid.new()
	grid.block_registry = root.get_node("BlockRegistry")
	root.add_child(grid)

	var entrance = Block.new("entrance", Vector3i(0, 0, 0))
	var elevator_0 = Block.new("elevator_shaft", Vector3i(1, 0, 0))
	var elevator_1 = Block.new("elevator_shaft", Vector3i(1, 0, 1))
	var elevator_2 = Block.new("elevator_shaft", Vector3i(1, 0, 2))
	var corridor_top = Block.new("corridor", Vector3i(2, 0, 2))

	grid.set_block(Vector3i(0, 0, 0), entrance)
	grid.set_block(Vector3i(1, 0, 0), elevator_0)
	grid.set_block(Vector3i(1, 0, 1), elevator_1)
	grid.set_block(Vector3i(1, 0, 2), elevator_2)
	grid.set_block(Vector3i(2, 0, 2), corridor_top)
	grid.calculate_connectivity()

	_assert(entrance.connected == true, "Entrance should be connected")
	_assert(elevator_0.connected == true, "Floor 0 elevator should be connected")
	_assert(elevator_1.connected == true, "Floor 1 elevator should be connected")
	_assert(elevator_2.connected == true, "Floor 2 elevator should be connected")
	_assert(corridor_top.connected == true, "Top corridor should be connected via elevator")

	grid.queue_free()
