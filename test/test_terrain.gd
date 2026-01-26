extends SceneTree
## Test script for Terrain class
## Run with: godot --headless --script test/test_terrain.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Terrain Tests ===")

	# Test 1: Default theme is earth
	print("\nTest 1: Default theme is 'earth'")
	var terrain := Terrain.new()
	if terrain.theme == "earth":
		print("  PASS: Default theme is 'earth'")
		tests_passed += 1
	else:
		print("  FAIL: Default theme is '%s', expected 'earth'" % terrain.theme)
		tests_failed += 1

	# Test 2: Theme color for earth
	print("\nTest 2: Earth theme color is grass green (#4a7c4e)")
	var expected_color := Color("#4a7c4e")
	if terrain.get_theme_color() == expected_color:
		print("  PASS: Earth theme color matches")
		tests_passed += 1
	else:
		print("  FAIL: Earth theme color is %s, expected %s" % [terrain.get_theme_color(), expected_color])
		tests_failed += 1

	# Test 3: Set valid theme (mars)
	print("\nTest 3: Set valid theme to 'mars'")
	terrain.theme = "mars"
	if terrain.theme == "mars":
		print("  PASS: Theme changed to 'mars'")
		tests_passed += 1
	else:
		print("  FAIL: Theme is '%s', expected 'mars'" % terrain.theme)
		tests_failed += 1

	# Test 4: Mars theme color
	print("\nTest 4: Mars theme color is rust red (#8b4513)")
	expected_color = Color("#8b4513")
	if terrain.get_theme_color() == expected_color:
		print("  PASS: Mars theme color matches")
		tests_passed += 1
	else:
		print("  FAIL: Mars theme color is %s, expected %s" % [terrain.get_theme_color(), expected_color])
		tests_failed += 1

	# Test 5: Set theme to space
	print("\nTest 5: Space theme has transparent base color")
	terrain.theme = "space"
	expected_color = Color(0, 0, 0, 0)
	if terrain.get_theme_color() == expected_color:
		print("  PASS: Space theme is transparent")
		tests_passed += 1
	else:
		print("  FAIL: Space theme color is %s, expected transparent" % terrain.get_theme_color())
		tests_failed += 1

	# Test 6: Invalid theme falls back to earth
	print("\nTest 6: Invalid theme falls back to 'earth'")
	terrain.theme = "invalid_theme_xyz"
	if terrain.theme == "earth":
		print("  PASS: Invalid theme reverts to 'earth'")
		tests_passed += 1
	else:
		print("  FAIL: Theme is '%s', expected 'earth' after invalid input" % terrain.theme)
		tests_failed += 1

	# Test 7: Static is_valid_theme function
	print("\nTest 7: is_valid_theme() validates correctly")
	var valid_earth := Terrain.is_valid_theme("earth")
	var valid_mars := Terrain.is_valid_theme("mars")
	var valid_space := Terrain.is_valid_theme("space")
	var invalid := Terrain.is_valid_theme("underwater")

	if valid_earth and valid_mars and valid_space and not invalid:
		print("  PASS: is_valid_theme validates themes correctly")
		tests_passed += 1
	else:
		print("  FAIL: is_valid_theme returned wrong values")
		tests_failed += 1

	# Test 8: get_available_themes returns all themes (instance method)
	print("\nTest 8: get_available_themes() returns all themes")
	var terrain_for_themes := Terrain.new()
	var themes := terrain_for_themes.get_available_themes()
	if themes.size() == 3 and "earth" in themes and "mars" in themes and "space" in themes:
		print("  PASS: get_available_themes returns [earth, mars, space]")
		tests_passed += 1
	else:
		print("  FAIL: get_available_themes returned %s" % [themes])
		tests_failed += 1

	# Test 9: Z-index is set to -1000
	print("\nTest 9: Terrain z_index is -1000")
	var terrain2 := Terrain.new()
	if terrain2.z_index == -1000:
		print("  PASS: z_index is -1000")
		tests_passed += 1
	else:
		print("  FAIL: z_index is %d, expected -1000" % terrain2.z_index)
		tests_failed += 1

	# Test 10: Default plane size
	print("\nTest 10: Default plane size is 2000x2000")
	if terrain2.plane_size == Vector2(2000, 2000):
		print("  PASS: Default plane size is 2000x2000")
		tests_passed += 1
	else:
		print("  FAIL: Plane size is %s, expected (2000, 2000)" % terrain2.plane_size)
		tests_failed += 1

	# --- NEGATIVE ASSERTIONS ---

	# Test 11: Empty string theme is invalid
	print("\nTest 11: Empty string theme falls back to earth")
	var terrain3 := Terrain.new()
	terrain3.theme = ""
	if terrain3.theme == "earth":
		print("  PASS: Empty string falls back to earth")
		tests_passed += 1
	else:
		print("  FAIL: Empty string theme set to '%s'" % terrain3.theme)
		tests_failed += 1

	# Test 12: Theme is case-sensitive
	print("\nTest 12: Theme is case-sensitive ('Earth' is invalid)")
	terrain3.theme = "Earth"  # Capital E
	if terrain3.theme == "earth":  # Should fall back to earth
		print("  PASS: 'Earth' is invalid, falls back to 'earth'")
		tests_passed += 1
	else:
		print("  FAIL: 'Earth' was accepted as '%s'" % terrain3.theme)
		tests_failed += 1

	# --- JSON DATA LOADING TESTS ---

	# Test 13: Decoration density for earth
	print("\nTest 13: Earth decoration density is 0.08")
	var terrain4 := Terrain.new()
	terrain4.theme = "earth"
	var density := terrain4.get_decoration_density()
	if is_equal_approx(density, 0.08):
		print("  PASS: Earth decoration density is 0.08")
		tests_passed += 1
	else:
		print("  FAIL: Earth decoration density is %f, expected 0.08" % density)
		tests_failed += 1

	# Test 14: Mars decoration density
	print("\nTest 14: Mars decoration density is 0.12")
	terrain4.theme = "mars"
	density = terrain4.get_decoration_density()
	if is_equal_approx(density, 0.12):
		print("  PASS: Mars decoration density is 0.12")
		tests_passed += 1
	else:
		print("  FAIL: Mars decoration density is %f, expected 0.12" % density)
		tests_failed += 1

	# Test 15: Space has no decorations
	print("\nTest 15: Space decoration density is 0")
	terrain4.theme = "space"
	density = terrain4.get_decoration_density()
	if is_equal_approx(density, 0.0):
		print("  PASS: Space decoration density is 0")
		tests_passed += 1
	else:
		print("  FAIL: Space decoration density is %f, expected 0" % density)
		tests_failed += 1

	# Test 16: Earth has river
	print("\nTest 16: Earth has river")
	terrain4.theme = "earth"
	if terrain4.has_river():
		print("  PASS: Earth has river")
		tests_passed += 1
	else:
		print("  FAIL: Earth should have river")
		tests_failed += 1

	# Test 17: Mars has no river
	print("\nTest 17: Mars has no river")
	terrain4.theme = "mars"
	if not terrain4.has_river():
		print("  PASS: Mars has no river")
		tests_passed += 1
	else:
		print("  FAIL: Mars should not have river")
		tests_failed += 1

	# Test 18: Earth decorations array has expected count
	print("\nTest 18: Earth has 6 decoration types")
	terrain4.theme = "earth"
	var decorations := terrain4.get_decorations_config()
	if decorations.size() == 6:
		print("  PASS: Earth has 6 decoration types")
		tests_passed += 1
	else:
		print("  FAIL: Earth has %d decoration types, expected 6" % decorations.size())
		tests_failed += 1

	# Test 19: Background sprite path for earth
	print("\nTest 19: Earth background sprite path")
	terrain4.theme = "earth"
	var bg_path := terrain4.get_background_sprite()
	if bg_path == "res://assets/sprites/terrain/backgrounds/earth_sky.png":
		print("  PASS: Earth background sprite path is correct")
		tests_passed += 1
	else:
		print("  FAIL: Earth background sprite path is '%s'" % bg_path)
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
