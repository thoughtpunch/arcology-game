extends SceneTree
## Tests for ExcavationSystem (cost calculations) and UndergroundWallSystem.
## Run with: godot --headless --script test/game/test_excavation_system.gd

const ExcavationSystemScript = preload("res://src/game/excavation_system.gd")
const UndergroundWallScript = preload("res://src/game/underground_wall_system.gd")
const FaceScript = preload("res://src/game/face.gd")


func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Excavation System Tests ===")

	# --- Excavation Cost Tests ---

	# Test 1: Surface has no excavation cost
	print("\nTest 1: Surface (Y >= 0) has no excavation cost")
	var cost_y0 := ExcavationSystemScript.calculate_excavation_cost(0)
	var cost_y1 := ExcavationSystemScript.calculate_excavation_cost(1)
	if cost_y0 == 0 and cost_y1 == 0:
		print("  PASS: Y=0 cost=$%d, Y=1 cost=$%d" % [cost_y0, cost_y1])
		tests_passed += 1
	else:
		print("  FAIL: Expected $0, got Y=0=$%d, Y=1=$%d" % [cost_y0, cost_y1])
		tests_failed += 1

	# Test 2: Shallow depth (-1 to -3) has 1.0x multiplier
	print("\nTest 2: Shallow depth (-1 to -3) uses 1.0x multiplier")
	var cost_shallow := ExcavationSystemScript.calculate_excavation_cost(-1)
	var expected_shallow := ExcavationSystemScript.BASE_EXCAVATION_COST
	if cost_shallow == expected_shallow:
		print("  PASS: Y=-1 cost=$%d (1.0x)" % cost_shallow)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_shallow, cost_shallow])
		tests_failed += 1

	# Test 3: Moderate depth (-4 to -6) has 1.5x multiplier
	print("\nTest 3: Moderate depth (-4 to -6) uses 1.5x multiplier")
	var cost_moderate := ExcavationSystemScript.calculate_excavation_cost(-5)
	var expected_moderate := int(float(ExcavationSystemScript.BASE_EXCAVATION_COST) * 1.5)
	if cost_moderate == expected_moderate:
		print("  PASS: Y=-5 cost=$%d (1.5x)" % cost_moderate)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_moderate, cost_moderate])
		tests_failed += 1

	# Test 4: Hard depth (-7 to -10) has 2.5x multiplier
	print("\nTest 4: Hard depth (-7 to -10) uses 2.5x multiplier")
	var cost_hard := ExcavationSystemScript.calculate_excavation_cost(-8)
	var expected_hard := int(float(ExcavationSystemScript.BASE_EXCAVATION_COST) * 2.5)
	if cost_hard == expected_hard:
		print("  PASS: Y=-8 cost=$%d (2.5x)" % cost_hard)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_hard, cost_hard])
		tests_failed += 1

	# Test 5: Very hard depth (-11 to -20) has 4.0x multiplier
	print("\nTest 5: Very hard depth (-11 to -20) uses 4.0x multiplier")
	var cost_vhard := ExcavationSystemScript.calculate_excavation_cost(-15)
	var expected_vhard := int(float(ExcavationSystemScript.BASE_EXCAVATION_COST) * 4.0)
	if cost_vhard == expected_vhard:
		print("  PASS: Y=-15 cost=$%d (4.0x)" % cost_vhard)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_vhard, cost_vhard])
		tests_failed += 1

	# Test 6: Extreme depth (< -20) has 6.0x multiplier
	print("\nTest 6: Extreme depth (< -20) uses 6.0x multiplier")
	var cost_extreme := ExcavationSystemScript.calculate_excavation_cost(-25)
	var expected_extreme := int(float(ExcavationSystemScript.BASE_EXCAVATION_COST) * 6.0)
	if cost_extreme == expected_extreme:
		print("  PASS: Y=-25 cost=$%d (6.0x)" % cost_extreme)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_extreme, cost_extreme])
		tests_failed += 1

	# Test 7: get_depth_category returns correct labels
	print("\nTest 7: get_depth_category returns correct labels")
	var cat_topsoil := ExcavationSystemScript.get_depth_category(-1)
	var cat_subsoil := ExcavationSystemScript.get_depth_category(-5)
	var cat_bedrock := ExcavationSystemScript.get_depth_category(-8)
	var cat_deep := ExcavationSystemScript.get_depth_category(-15)
	var cat_surface := ExcavationSystemScript.get_depth_category(0)
	if cat_topsoil == "Topsoil" and cat_subsoil == "Subsoil" and cat_bedrock == "Bedrock" and cat_deep == "Deep Rock" and cat_surface == "Surface":
		print("  PASS: Categories: %s, %s, %s, %s, %s" % [cat_topsoil, cat_subsoil, cat_bedrock, cat_deep, cat_surface])
		tests_passed += 1
	else:
		print("  FAIL: Got: %s, %s, %s, %s, %s" % [cat_topsoil, cat_subsoil, cat_bedrock, cat_deep, cat_surface])
		tests_failed += 1

	# Test 8: format_cost formats with commas
	print("\nTest 8: format_cost formats with commas")
	var formatted := ExcavationSystemScript.format_cost(1000)
	if formatted == "$1,000":
		print("  PASS: format_cost(1000) = '%s'" % formatted)
		tests_passed += 1
	else:
		print("  FAIL: Expected '$1,000', got '%s'" % formatted)
		tests_failed += 1

	# Test 9: calculate_total_cost sums multiple cells
	print("\nTest 9: calculate_total_cost sums multiple cells")
	var cells: Array[Vector3i] = [Vector3i(0, -1, 0), Vector3i(0, -2, 0), Vector3i(0, -3, 0)]
	var total := ExcavationSystemScript.calculate_total_cost(cells)
	var expected_total := ExcavationSystemScript.BASE_EXCAVATION_COST * 3  # All 1.0x
	if total == expected_total:
		print("  PASS: Total for 3 shallow cells = $%d" % total)
		tests_passed += 1
	else:
		print("  FAIL: Expected $%d, got $%d" % [expected_total, total])
		tests_failed += 1

	# Test 10: get_cost_preview_text includes all info
	print("\nTest 10: get_cost_preview_text includes category, depth, multiplier, cost")
	var preview := ExcavationSystemScript.get_cost_preview_text(-2)
	if "Topsoil" in preview and "Y=-2" in preview and "1.0x" in preview and "$" in preview:
		print("  PASS: Preview text = '%s'" % preview)
		tests_passed += 1
	else:
		print("  FAIL: Missing info in '%s'" % preview)
		tests_failed += 1

	# --- Underground Wall System Tests ---

	print("\n--- Underground Wall System Tests ---")

	# Test 11: Wall system initializes with empty state
	print("\nTest 11: Wall system initializes with empty state")
	var wall_system := UndergroundWallScript.new()
	if wall_system.get_wall_count() == 0:
		print("  PASS: Initial wall count = 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % wall_system.get_wall_count())
		tests_failed += 1

	# Test 12: get_strata_color returns correct colors for depths
	print("\nTest 12: get_strata_color returns correct colors for depths")
	var color_1 := wall_system.get_strata_color(-1)  # Topsoil
	var color_2 := wall_system.get_strata_color(-2)  # Subsoil
	var color_3 := wall_system.get_strata_color(-3)  # Bedrock
	var color_0 := wall_system.get_strata_color(0)   # Above ground
	var is_brown: bool = color_1.r > 0.3 and color_1.g < color_1.r  # Brownish
	var is_tan: bool = color_2.r > color_2.b  # Tan/clay
	var is_gray: bool = absf(color_3.r - color_3.g) < 0.1 and absf(color_3.g - color_3.b) < 0.1  # Grayish
	var is_transparent: bool = color_0.a < 0.1  # Transparent for surface
	if is_brown and is_tan and is_gray and is_transparent:
		print("  PASS: Strata colors are distinct by depth")
		tests_passed += 1
	else:
		print("  FAIL: Colors not as expected: Y=-1=%s, Y=-2=%s, Y=-3=%s, Y=0=%s" % [color_1, color_2, color_3, color_0])
		tests_failed += 1

	# Test 13: Serialize returns excavated_cells array
	print("\nTest 13: Serialize returns excavated_cells array")
	var serialized := wall_system.serialize()
	if serialized.has("excavated_cells") and serialized["excavated_cells"] is Array:
		print("  PASS: Serialized data has excavated_cells array")
		tests_passed += 1
	else:
		print("  FAIL: Missing or invalid excavated_cells in serialized data")
		tests_failed += 1

	# --- Negative Tests ---

	print("\n--- Negative Tests ---")

	# Test 14: NEGATIVE - Surface cells have no excavation cost
	print("\nTest 14: NEGATIVE - Above ground never has cost")
	var above_ground_cost := ExcavationSystemScript.calculate_excavation_cost(5)
	if above_ground_cost == 0:
		print("  PASS: Y=5 (above ground) cost = $0")
		tests_passed += 1
	else:
		print("  FAIL: Expected $0, got $%d" % above_ground_cost)
		tests_failed += 1

	# Test 15: NEGATIVE - Multiplier for surface is 0
	print("\nTest 15: NEGATIVE - get_depth_multiplier returns 0 for surface")
	var mult_surface := ExcavationSystemScript.get_depth_multiplier(0)
	var mult_above := ExcavationSystemScript.get_depth_multiplier(10)
	if mult_surface == 0.0 and mult_above == 0.0:
		print("  PASS: Surface multipliers are 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0.0, got Y=0:%.1f, Y=10:%.1f" % [mult_surface, mult_above])
		tests_failed += 1

	# Test 16: NEGATIVE - Empty cell array has zero total cost
	print("\nTest 16: NEGATIVE - Empty cell array has zero total cost")
	var empty_cells: Array[Vector3i] = []
	var empty_total := ExcavationSystemScript.calculate_total_cost(empty_cells)
	if empty_total == 0:
		print("  PASS: Empty array total = $0")
		tests_passed += 1
	else:
		print("  FAIL: Expected $0, got $%d" % empty_total)
		tests_failed += 1

	# Test 17: Wall system clear removes all walls
	print("\nTest 17: Wall system clear_all_walls works")
	var wall_system2 := UndergroundWallScript.new()
	wall_system2.clear_all_walls()
	if wall_system2.get_wall_count() == 0:
		print("  PASS: clear_all_walls results in 0 walls")
		tests_passed += 1
	else:
		print("  FAIL: Expected 0, got %d" % wall_system2.get_wall_count())
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
