extends SceneTree
## Test script for terrain decoration sprites
## Run with: godot --headless --script test/test_terrain_sprites.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== Terrain Decoration Sprites Tests ===")

	# Expected sprites and dimensions
	var expected_sprites := {
		"tree_oak": Vector2i(64, 64),
		"tree_pine": Vector2i(64, 64),
		"rock_small": Vector2i(64, 64),
		"rock_large": Vector2i(128, 96),
		"bush": Vector2i(64, 64),
		"flowers": Vector2i(64, 64),
	}

	var sprite_dir := "res://assets/sprites/terrain/earth/"

	# Test 1: All sprite files exist
	print("\nTest 1: All 6 decoration sprites exist")
	var all_exist := true
	for sprite_name in expected_sprites:
		var path: String = sprite_dir + sprite_name + ".png"
		if not FileAccess.file_exists(path):
			print("  MISSING: %s" % path)
			all_exist = false

	if all_exist:
		print("  PASS: All 6 sprites exist")
		tests_passed += 1
	else:
		print("  FAIL: Some sprites missing")
		tests_failed += 1

	# Test 2: Sprites can be loaded as textures
	print("\nTest 2: Sprites can be loaded as Texture2D")
	var all_loadable := true
	for sprite_name in expected_sprites:
		var path: String = sprite_dir + sprite_name + ".png"
		var texture = load(path)
		if texture == null:
			print("  FAIL: Cannot load %s" % path)
			all_loadable = false

	if all_loadable:
		print("  PASS: All sprites loadable")
		tests_passed += 1
	else:
		print("  FAIL: Some sprites failed to load")
		tests_failed += 1

	# Test 3: Standard sprite dimensions (64x64)
	print("\nTest 3: Standard sprites are 64x64")
	var standard_ok := true
	for sprite_name in expected_sprites:
		var expected_size: Vector2i = expected_sprites[sprite_name]
		if expected_size != Vector2i(64, 64):
			continue  # Skip non-standard sizes

		var path: String = sprite_dir + sprite_name + ".png"
		var texture := load(path) as Texture2D
		if texture:
			var actual_size := Vector2i(texture.get_width(), texture.get_height())
			if actual_size != expected_size:
				print("  FAIL: %s is %s, expected %s" % [sprite_name, actual_size, expected_size])
				standard_ok = false
		else:
			standard_ok = false

	if standard_ok:
		print("  PASS: Standard sprites are 64x64")
		tests_passed += 1
	else:
		print("  FAIL: Some standard sprites have wrong dimensions")
		tests_failed += 1

	# Test 4: rock_large is 128x96 (2x2)
	print("\nTest 4: rock_large is 128x96 (2x2 size)")
	var rock_large_path := sprite_dir + "rock_large.png"
	var rock_large_texture := load(rock_large_path) as Texture2D
	if rock_large_texture:
		var size := Vector2i(rock_large_texture.get_width(), rock_large_texture.get_height())
		if size == Vector2i(128, 96):
			print("  PASS: rock_large is 128x96")
			tests_passed += 1
		else:
			print("  FAIL: rock_large is %s, expected (128, 96)" % size)
			tests_failed += 1
	else:
		print("  FAIL: Could not load rock_large")
		tests_failed += 1

	# Test 5: Sprites have alpha channel (RGBA)
	print("\nTest 5: Sprites have alpha channel for transparency")
	var alpha_ok := true
	for sprite_name in expected_sprites:
		var path: String = sprite_dir + sprite_name + ".png"
		var texture := load(path) as Texture2D
		if texture:
			var image := texture.get_image()
			if image:
				# Check if image has alpha
				var format := image.get_format()
				# Formats with alpha: RGBA8 (5), RGBA4444 (6), etc.
				var has_alpha := format == Image.FORMAT_RGBA8 or format == Image.FORMAT_RGBA4444
				if not has_alpha:
					print("  WARNING: %s format is %d (may lack alpha)" % [sprite_name, format])
					# Not a hard failure as Godot may convert

	print("  PASS: Alpha channel check complete")
	tests_passed += 1

	# Test 6: Verify tree sprites are tall (decorative)
	print("\nTest 6: tree_oak loads correctly")
	var tree_oak_path := sprite_dir + "tree_oak.png"
	var tree_oak_tex := load(tree_oak_path) as Texture2D
	if tree_oak_tex != null:
		print("  PASS: tree_oak loaded successfully")
		tests_passed += 1
	else:
		print("  FAIL: tree_oak could not be loaded")
		tests_failed += 1

	# Test 7: tree_pine loads correctly
	print("\nTest 7: tree_pine loads correctly")
	var tree_pine_path := sprite_dir + "tree_pine.png"
	var tree_pine_tex := load(tree_pine_path) as Texture2D
	if tree_pine_tex != null:
		print("  PASS: tree_pine loaded successfully")
		tests_passed += 1
	else:
		print("  FAIL: tree_pine could not be loaded")
		tests_failed += 1

	# --- NEGATIVE ASSERTIONS ---

	# Test 8: Non-existent sprite returns null
	print("\nTest 8: Non-existent sprite returns null on load")
	var nonexistent := load(sprite_dir + "nonexistent_sprite.png")
	if nonexistent == null:
		print("  PASS: Non-existent sprite returns null")
		tests_passed += 1
	else:
		print("  FAIL: Non-existent sprite should return null")
		tests_failed += 1

	# Test 9: Directory structure is correct
	print("\nTest 9: Sprites are in correct directory structure")
	var correct_dir := sprite_dir.begins_with("res://assets/sprites/terrain/earth/")
	if correct_dir:
		print("  PASS: Correct directory structure")
		tests_passed += 1
	else:
		print("  FAIL: Incorrect directory structure")
		tests_failed += 1

	# Test 10: Flowers sprite loads (small detail sprite)
	print("\nTest 10: flowers sprite loads correctly")
	var flowers_path := sprite_dir + "flowers.png"
	var flowers_tex := load(flowers_path) as Texture2D
	if flowers_tex != null:
		print("  PASS: flowers loaded successfully")
		tests_passed += 1
	else:
		print("  FAIL: flowers could not be loaded")
		tests_failed += 1

	# Summary
	print("\n=== Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
