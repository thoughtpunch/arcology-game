extends SceneTree
## Unit tests for GhostPreview3D

const GhostPreview3DClass := preload("res://src/core/ghost_preview_3d.gd")


func _init() -> void:
	print("=== GhostPreview3D Tests ===")
	var passed := 0
	var failed := 0

	# Test 1: Creation
	print("\n1. GhostPreview3D creation...")
	var ghost: Node3D = GhostPreview3DClass.new()
	ghost._ready()  # Call manually since not in tree
	if ghost != null:
		print("  PASS: GhostPreview3D created")
		passed += 1
	else:
		print("  FAIL: GhostPreview3D is null")
		failed += 1

	# Test 2: Default state is HIDDEN
	print("\n2. Default state is HIDDEN...")
	if ghost.get_state() == GhostPreview3DClass.GhostState.HIDDEN:
		print("  PASS: Default state is HIDDEN")
		passed += 1
	else:
		print("  FAIL: Expected HIDDEN state, got %s" % ghost.get_state())
		failed += 1

	# Test 3: Set state to VALID
	print("\n3. Set state to VALID...")
	ghost.set_state(GhostPreview3DClass.GhostState.VALID)
	if ghost.get_state() == GhostPreview3DClass.GhostState.VALID:
		print("  PASS: State set to VALID")
		passed += 1
	else:
		print("  FAIL: State should be VALID, got %s" % ghost.get_state())
		failed += 1

	# Test 4: Set state to WARNING
	print("\n4. Set state to WARNING...")
	ghost.set_state(GhostPreview3DClass.GhostState.WARNING)
	if ghost.get_state() == GhostPreview3DClass.GhostState.WARNING:
		print("  PASS: State set to WARNING")
		passed += 1
	else:
		print("  FAIL: State should be WARNING, got %s" % ghost.get_state())
		failed += 1

	# Test 5: Set state to INVALID
	print("\n5. Set state to INVALID...")
	ghost.set_state(GhostPreview3DClass.GhostState.INVALID)
	if ghost.get_state() == GhostPreview3DClass.GhostState.INVALID:
		print("  PASS: State set to INVALID")
		passed += 1
	else:
		print("  FAIL: State should be INVALID, got %s" % ghost.get_state())
		failed += 1

	# Test 6: GhostState enum values
	print("\n6. GhostState enum values...")
	if GhostPreview3DClass.GhostState.HIDDEN == 0 and \
	   GhostPreview3DClass.GhostState.VALID == 1 and \
	   GhostPreview3DClass.GhostState.WARNING == 2 and \
	   GhostPreview3DClass.GhostState.INVALID == 3:
		print("  PASS: GhostState enum values correct")
		passed += 1
	else:
		print("  FAIL: GhostState enum values incorrect")
		failed += 1

	# Test 7: Set grid position
	print("\n7. Set grid position...")
	var test_pos := Vector3i(5, 3, 2)
	ghost.set_grid_position(test_pos)
	if ghost.get_grid_position() == test_pos:
		print("  PASS: Grid position set to %s" % test_pos)
		passed += 1
	else:
		print("  FAIL: Expected %s, got %s" % [test_pos, ghost.get_grid_position()])
		failed += 1

	# Test 8: World position from grid position
	print("\n8. World position from grid position...")
	ghost.set_grid_position(Vector3i(0, 0, 0))
	# Grid (0,0,0) -> World (0, 1.75, 0)
	if is_equal_approx(ghost.position.x, 0.0) and \
	   is_equal_approx(ghost.position.y, 1.75) and \
	   is_equal_approx(ghost.position.z, 0.0):
		print("  PASS: World position correct at origin")
		passed += 1
	else:
		print("  FAIL: Expected (0, 1.75, 0), got %s" % ghost.position)
		failed += 1

	# Test 9: Set block type
	print("\n9. Set block type...")
	ghost.set_block_type("residential_basic")
	if ghost.get_block_type() == "residential_basic":
		print("  PASS: Block type set to residential_basic")
		passed += 1
	else:
		print("  FAIL: Expected residential_basic, got %s" % ghost.get_block_type())
		failed += 1

	# Test 10: Default rotation is 0
	print("\n10. Default rotation is 0...")
	if ghost.get_rotation_index() == 0:
		print("  PASS: Default rotation is 0")
		passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % ghost.get_rotation_index())
		failed += 1

	# Test 11: Set rotation
	print("\n11. Set rotation...")
	ghost.set_rotation_index(2)
	if ghost.get_rotation_index() == 2:
		print("  PASS: Rotation set to 2 (south)")
		passed += 1
	else:
		print("  FAIL: Expected 2, got %d" % ghost.get_rotation_index())
		failed += 1

	# Test 12: Rotation wraps at 4
	print("\n12. Rotation wraps at 4...")
	ghost.set_rotation_index(5)
	if ghost.get_rotation_index() == 1:  # 5 % 4 = 1
		print("  PASS: Rotation 5 wraps to 1")
		passed += 1
	else:
		print("  FAIL: Expected 1, got %d" % ghost.get_rotation_index())
		failed += 1

	# Test 13: rotate_ghost increments rotation
	print("\n13. rotate_ghost increments rotation...")
	ghost.set_rotation_index(0)
	ghost.rotate_ghost()
	if ghost.get_rotation_index() == 1:
		print("  PASS: rotate_ghost() incremented to 1")
		passed += 1
	else:
		print("  FAIL: Expected 1, got %d" % ghost.get_rotation_index())
		failed += 1

	# Test 14: rotate_ghost wraps from 3 to 0
	print("\n14. rotate_ghost wraps from 3 to 0...")
	ghost.set_rotation_index(3)
	ghost.rotate_ghost()
	if ghost.get_rotation_index() == 0:
		print("  PASS: rotate_ghost() wrapped from 3 to 0")
		passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % ghost.get_rotation_index())
		failed += 1

	# Test 15: show_at sets position and state
	print("\n15. show_at sets position and state...")
	ghost.hide_ghost()
	ghost.show_at(Vector3i(10, 5, 3), GhostPreview3DClass.GhostState.VALID)
	if ghost.get_grid_position() == Vector3i(10, 5, 3) and \
	   ghost.get_state() == GhostPreview3DClass.GhostState.VALID and \
	   ghost.visible:
		print("  PASS: show_at sets position, state, and visibility")
		passed += 1
	else:
		print("  FAIL: show_at didn't set all values correctly")
		failed += 1

	# Test 16: hide_ghost sets state to HIDDEN
	print("\n16. hide_ghost sets state to HIDDEN...")
	ghost.show_at(Vector3i(0, 0, 0), GhostPreview3DClass.GhostState.VALID)
	ghost.hide_ghost()
	if not ghost.visible:
		print("  PASS: hide_ghost() hides the ghost")
		passed += 1
	else:
		print("  FAIL: Ghost should be invisible after hide_ghost()")
		failed += 1

	# Test 17: grid_to_world_center static function
	print("\n17. grid_to_world_center static function...")
	var world_pos: Vector3 = GhostPreview3DClass.grid_to_world_center(Vector3i(1, 2, 3))
	# X = 1 * 6 = 6
	# Y = 3 * 3.5 + 1.75 = 12.25
	# Z = 2 * 6 = 12
	if is_equal_approx(world_pos.x, 6.0) and \
	   is_equal_approx(world_pos.y, 12.25) and \
	   is_equal_approx(world_pos.z, 12.0):
		print("  PASS: grid_to_world_center(1,2,3) = (6, 12.25, 12)")
		passed += 1
	else:
		print("  FAIL: Expected (6, 12.25, 12), got %s" % world_pos)
		failed += 1

	# Test 18: Mesh instance exists
	print("\n18. Mesh instance exists...")
	if ghost._mesh_instance != null:
		print("  PASS: Mesh instance created")
		passed += 1
	else:
		print("  FAIL: Mesh instance is null")
		failed += 1

	# Test 19: Floor label exists
	print("\n19. Floor label exists...")
	if ghost._floor_label != null:
		print("  PASS: Floor label created")
		passed += 1
	else:
		print("  FAIL: Floor label is null")
		failed += 1

	# Test 20: Floor label updates with position
	print("\n20. Floor label updates with position...")
	ghost.set_grid_position(Vector3i(0, 0, 5))
	if ghost._floor_label.text == "Floor 5":
		print("  PASS: Floor label shows 'Floor 5'")
		passed += 1
	else:
		print("  FAIL: Expected 'Floor 5', got '%s'" % ghost._floor_label.text)
		failed += 1

	# Test 21: Static body exists for collision exclusion
	print("\n21. Static body exists for collision exclusion...")
	if ghost._static_body != null:
		print("  PASS: Static body created for collision exclusion")
		passed += 1
	else:
		print("  FAIL: Static body is null")
		failed += 1

	# Test 22: Collision layer is correct (layer 4 = bit 3 = 8)
	print("\n22. Collision layer is correct...")
	if ghost._static_body and ghost._static_body.collision_layer == 8:
		print("  PASS: Collision layer is 8 (layer 4)")
		passed += 1
	else:
		var layer: int = ghost._static_body.collision_layer if ghost._static_body else -1
		print("  FAIL: Expected collision_layer=8, got %d" % layer)
		failed += 1

	# Test 23: Materials exist for all states
	print("\n23. Materials exist for all states...")
	if ghost._material_valid != null and \
	   ghost._material_warning != null and \
	   ghost._material_invalid != null:
		print("  PASS: All state materials created")
		passed += 1
	else:
		print("  FAIL: Some state materials are null")
		failed += 1

	# Test 24: Valid material is green-ish
	print("\n24. Valid material color...")
	if ghost._material_valid and ghost._material_valid.albedo_color.g > 0.7:
		print("  PASS: Valid material is green (g=%.2f)" % ghost._material_valid.albedo_color.g)
		passed += 1
	else:
		print("  FAIL: Valid material should be green")
		failed += 1

	# Test 25: Invalid material is red-ish
	print("\n25. Invalid material color...")
	if ghost._material_invalid and ghost._material_invalid.albedo_color.r > 0.7:
		print("  PASS: Invalid material is red (r=%.2f)" % ghost._material_invalid.albedo_color.r)
		passed += 1
	else:
		print("  FAIL: Invalid material should be red")
		failed += 1

	# Cleanup
	ghost.free()

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
