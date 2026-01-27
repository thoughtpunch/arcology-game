extends SceneTree
## Unit tests for InputHandler3D

const InputHandler3DClass := preload("res://src/core/input_handler_3d.gd")


func _init() -> void:
	print("=== InputHandler3D Tests ===")
	var passed := 0
	var failed := 0

	# Test 1: Creation
	print("\n1. InputHandler3D creation...")
	var handler: Node3D = InputHandler3DClass.new()
	if handler != null:
		print("  PASS: InputHandler3D created")
		passed += 1
	else:
		print("  FAIL: InputHandler3D is null")
		failed += 1

	# Test 2: Default mode is BUILD
	print("\n2. Default mode is BUILD...")
	if handler.current_mode == InputHandler3DClass.Mode.BUILD:
		print("  PASS: Default mode is BUILD")
		passed += 1
	else:
		print("  FAIL: Expected BUILD mode, got %s" % handler.current_mode)
		failed += 1

	# Test 3: Default selected block type
	print("\n3. Default selected block type...")
	if handler.selected_block_type == "corridor":
		print("  PASS: Default block type is corridor")
		passed += 1
	else:
		print("  FAIL: Expected corridor, got %s" % handler.selected_block_type)
		failed += 1

	# Test 4: Set mode
	print("\n4. Set mode...")
	handler.set_mode(InputHandler3DClass.Mode.SELECT)
	if handler.get_mode() == InputHandler3DClass.Mode.SELECT:
		print("  PASS: Mode set to SELECT")
		passed += 1
	else:
		print("  FAIL: Mode should be SELECT, got %s" % handler.get_mode())
		failed += 1

	# Test 5: Set mode to DEMOLISH
	print("\n5. Set mode to DEMOLISH...")
	handler.set_mode(InputHandler3DClass.Mode.DEMOLISH)
	if handler.get_mode() == InputHandler3DClass.Mode.DEMOLISH:
		print("  PASS: Mode set to DEMOLISH")
		passed += 1
	else:
		print("  FAIL: Mode should be DEMOLISH, got %s" % handler.get_mode())
		failed += 1

	# Test 6: Set selected block type
	print("\n6. Set selected block type...")
	handler.set_selected_block_type("residential_basic")
	if handler.get_selected_block_type() == "residential_basic":
		print("  PASS: Block type changed to residential_basic")
		passed += 1
	else:
		print("  FAIL: Expected residential_basic, got %s" % handler.get_selected_block_type())
		failed += 1

	# Test 7: _is_ready returns false without setup
	print("\n7. _is_ready returns false without setup...")
	if not handler._is_ready():
		print("  PASS: Not ready before setup")
		passed += 1
	else:
		print("  FAIL: Should not be ready before setup")
		failed += 1

	# Test 8: Ghost not visible initially
	print("\n8. Ghost not visible initially...")
	if not handler.is_ghost_visible():
		print("  PASS: Ghost not visible initially")
		passed += 1
	else:
		print("  FAIL: Ghost should not be visible initially")
		failed += 1

	# Test 9: CubeFace enum values
	print("\n9. CubeFace enum values...")
	if InputHandler3DClass.CubeFace.TOP == 0 and \
	   InputHandler3DClass.CubeFace.BOTTOM == 1 and \
	   InputHandler3DClass.CubeFace.NORTH == 2 and \
	   InputHandler3DClass.CubeFace.SOUTH == 3 and \
	   InputHandler3DClass.CubeFace.EAST == 4 and \
	   InputHandler3DClass.CubeFace.WEST == 5:
		print("  PASS: CubeFace enum values correct")
		passed += 1
	else:
		print("  FAIL: CubeFace enum values incorrect")
		failed += 1

	# Test 10: Mode enum values
	print("\n10. Mode enum values...")
	if InputHandler3DClass.Mode.BUILD == 0 and \
	   InputHandler3DClass.Mode.SELECT == 1 and \
	   InputHandler3DClass.Mode.DEMOLISH == 2:
		print("  PASS: Mode enum values correct")
		passed += 1
	else:
		print("  FAIL: Mode enum values incorrect")
		failed += 1

	# Test 11: _normal_to_face - TOP
	print("\n11. _normal_to_face - TOP...")
	var face: int = handler._normal_to_face(Vector3(0, 1, 0))
	if face == InputHandler3DClass.CubeFace.TOP:
		print("  PASS: Y+ normal -> TOP face")
		passed += 1
	else:
		print("  FAIL: Expected TOP, got %s" % face)
		failed += 1

	# Test 12: _normal_to_face - BOTTOM
	print("\n12. _normal_to_face - BOTTOM...")
	face = handler._normal_to_face(Vector3(0, -1, 0))
	if face == InputHandler3DClass.CubeFace.BOTTOM:
		print("  PASS: Y- normal -> BOTTOM face")
		passed += 1
	else:
		print("  FAIL: Expected BOTTOM, got %s" % face)
		failed += 1

	# Test 13: _normal_to_face - NORTH
	print("\n13. _normal_to_face - NORTH...")
	face = handler._normal_to_face(Vector3(0, 0, 1))
	if face == InputHandler3DClass.CubeFace.NORTH:
		print("  PASS: Z+ normal -> NORTH face")
		passed += 1
	else:
		print("  FAIL: Expected NORTH, got %s" % face)
		failed += 1

	# Test 14: _normal_to_face - SOUTH
	print("\n14. _normal_to_face - SOUTH...")
	face = handler._normal_to_face(Vector3(0, 0, -1))
	if face == InputHandler3DClass.CubeFace.SOUTH:
		print("  PASS: Z- normal -> SOUTH face")
		passed += 1
	else:
		print("  FAIL: Expected SOUTH, got %s" % face)
		failed += 1

	# Test 15: _normal_to_face - EAST
	print("\n15. _normal_to_face - EAST...")
	face = handler._normal_to_face(Vector3(1, 0, 0))
	if face == InputHandler3DClass.CubeFace.EAST:
		print("  PASS: X+ normal -> EAST face")
		passed += 1
	else:
		print("  FAIL: Expected EAST, got %s" % face)
		failed += 1

	# Test 16: _normal_to_face - WEST
	print("\n16. _normal_to_face - WEST...")
	face = handler._normal_to_face(Vector3(-1, 0, 0))
	if face == InputHandler3DClass.CubeFace.WEST:
		print("  PASS: X- normal -> WEST face")
		passed += 1
	else:
		print("  FAIL: Expected WEST, got %s" % face)
		failed += 1

	# Test 17: _world_to_grid - origin
	print("\n17. _world_to_grid - origin...")
	var grid_pos: Vector3i = handler._world_to_grid(Vector3(0, 1.75, 0))  # Center of block at origin
	if grid_pos == Vector3i(0, 0, 0):
		print("  PASS: World origin center -> grid (0, 0, 0)")
		passed += 1
	else:
		print("  FAIL: Expected (0, 0, 0), got %s" % grid_pos)
		failed += 1

	# Test 18: _world_to_grid - offset block
	print("\n18. _world_to_grid - offset block...")
	# Block at grid (2, 3, 1) should be at world (12, 5.25, 18)
	# X = 2 * 6 = 12
	# Y = 1 * 3.5 + 1.75 = 5.25 (center)
	# Z = 3 * 6 = 18
	grid_pos = handler._world_to_grid(Vector3(12, 5.25, 18))
	if grid_pos == Vector3i(2, 3, 1):
		print("  PASS: World (12, 5.25, 18) -> grid (2, 3, 1)")
		passed += 1
	else:
		print("  FAIL: Expected (2, 3, 1), got %s" % grid_pos)
		failed += 1

	# Test 19: _grid_to_world_center - origin
	print("\n19. _grid_to_world_center - origin...")
	var world_pos: Vector3 = handler._grid_to_world_center(Vector3i(0, 0, 0))
	if is_equal_approx(world_pos.x, 0.0) and is_equal_approx(world_pos.y, 1.75) and is_equal_approx(world_pos.z, 0.0):
		print("  PASS: Grid (0, 0, 0) -> world center (0, 1.75, 0)")
		passed += 1
	else:
		print("  FAIL: Expected (0, 1.75, 0), got %s" % world_pos)
		failed += 1

	# Test 20: _grid_to_world_center - offset
	print("\n20. _grid_to_world_center - offset...")
	world_pos = handler._grid_to_world_center(Vector3i(1, 2, 3))
	# X = 1 * 6 = 6
	# Y = 3 * 3.5 + 1.75 = 12.25
	# Z = 2 * 6 = 12
	if is_equal_approx(world_pos.x, 6.0) and is_equal_approx(world_pos.y, 12.25) and is_equal_approx(world_pos.z, 12.0):
		print("  PASS: Grid (1, 2, 3) -> world center (6, 12.25, 12)")
		passed += 1
	else:
		print("  FAIL: Expected (6, 12.25, 12), got %s" % world_pos)
		failed += 1

	# Test 21: get_placement_position - empty hit
	print("\n21. get_placement_position - empty hit...")
	var empty_hit := { "hit": false }
	var place_pos: Vector3i = handler.get_placement_position(empty_hit)
	if place_pos == Vector3i.ZERO:
		print("  PASS: Empty hit returns zero")
		passed += 1
	else:
		print("  FAIL: Expected zero, got %s" % place_pos)
		failed += 1

	# Test 22: get_placement_position - top face hit
	print("\n22. get_placement_position - top face hit...")
	var top_hit := {
		"hit": true,
		"grid_pos": Vector3i(0, 0, 0),
		"normal": Vector3(0, 1, 0)
	}
	place_pos = handler.get_placement_position(top_hit)
	if place_pos == Vector3i(0, 0, 1):  # One floor up
		print("  PASS: Top face hit places block above")
		passed += 1
	else:
		print("  FAIL: Expected (0, 0, 1), got %s" % place_pos)
		failed += 1

	# Test 23: get_placement_position - north face hit
	print("\n23. get_placement_position - north face hit...")
	var north_hit := {
		"hit": true,
		"grid_pos": Vector3i(0, 0, 0),
		"normal": Vector3(0, 0, 1)
	}
	place_pos = handler.get_placement_position(north_hit)
	if place_pos == Vector3i(0, 1, 0):  # +Y in grid (north)
		print("  PASS: North face hit places block north")
		passed += 1
	else:
		print("  FAIL: Expected (0, 1, 0), got %s" % place_pos)
		failed += 1

	# Test 24: get_placement_position - east face hit
	print("\n24. get_placement_position - east face hit...")
	var east_hit := {
		"hit": true,
		"grid_pos": Vector3i(0, 0, 0),
		"normal": Vector3(1, 0, 0)
	}
	place_pos = handler.get_placement_position(east_hit)
	if place_pos == Vector3i(1, 0, 0):  # +X in grid (east)
		print("  PASS: East face hit places block east")
		passed += 1
	else:
		print("  FAIL: Expected (1, 0, 0), got %s" % place_pos)
		failed += 1

	# Test 25: Selection changed signal exists and is connected correctly
	print("\n25. Selection changed signal exists...")
	# Test that the signal exists and can be connected
	var signal_list := handler.get_signal_list()
	var has_signal := false
	for sig in signal_list:
		if sig.name == "selection_changed":
			has_signal = true
			break
	if has_signal:
		print("  PASS: selection_changed signal exists")
		passed += 1
	else:
		print("  FAIL: selection_changed signal not found")
		failed += 1

	# Cleanup
	handler.free()

	# Summary
	print("\n=== Summary ===")
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)
	print("Total:  %d" % (passed + failed))

	if failed > 0:
		print("\nTESTS FAILED")
	else:
		print("\nALL TESTS PASSED")

	quit()
