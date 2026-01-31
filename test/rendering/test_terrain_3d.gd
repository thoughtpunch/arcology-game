extends SceneTree
## Test: Terrain3D (arcology-bph)
##
## Verifies:
## - Terrain generation with default settings
## - Theme-specific materials (Earth, Mars, Space)
## - Collision body creation for raycasting
## - Cell occupancy tracking
## - Ground cell removal (excavation)
## - Bedrock protection
## - World size and center calculations
## - find_top_ground_y functionality

var _test_count := 0
var _pass_count := 0

var _Terrain3DClass: GDScript


func _init() -> void:
	print("\n=== Test: Terrain3D ===\n")

	_Terrain3DClass = load("res://src/rendering/terrain_3d.gd")
	assert(_Terrain3DClass != null, "Terrain3D script should load")

	# Run tests
	_test_terrain_creation()
	_test_default_configuration()
	_test_custom_configuration()
	_test_earth_theme_colors()
	_test_mars_theme_colors()
	_test_space_theme_colors()
	_test_cell_occupancy()
	_test_cell_occupancy_invalid()
	_test_find_top_ground_y()
	_test_find_top_ground_y_empty_column()
	_test_collision_body()
	_test_world_size()
	_test_world_center()
	_test_remove_cell()
	_test_remove_cell_invalid()
	_test_bedrock_protection()
	_test_remove_cell_signal()
	_test_clear_terrain()
	_test_regenerate_terrain()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])

	if _pass_count == _test_count:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
		assert(false, "Not all tests passed")

	quit()


func _assert(condition: bool, message: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % message)
	else:
		print("  FAIL: %s" % message)


func _test_terrain_creation() -> void:
	print("\n--- Terrain Creation ---")
	var terrain: Node3D = _Terrain3DClass.new()
	root.add_child(terrain)

	# Process a frame to trigger _ready()
	await process_frame

	_assert(terrain != null, "Terrain should be created")
	_assert(terrain.theme == _Terrain3DClass.TerrainTheme.EARTH, "Default theme should be EARTH")
	_assert(terrain.grid_size == Vector2i(100, 100), "Default grid size should be 100x100")
	_assert(terrain.ground_depth == 5, "Default ground depth should be 5")

	terrain.queue_free()
	await process_frame


func _test_default_configuration() -> void:
	print("\n--- Default Configuration ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.generate()

	_assert(terrain.grid_size.x == 100, "Grid X should be 100")
	_assert(terrain.grid_size.y == 100, "Grid Z should be 100")
	_assert(terrain.ground_depth == 5, "Ground depth should be 5")

	terrain.free()


func _test_custom_configuration() -> void:
	print("\n--- Custom Configuration ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({
		"theme": _Terrain3DClass.TerrainTheme.MARS,
		"grid_size": Vector2i(50, 50),
		"ground_depth": 3
	})
	terrain.generate()

	_assert(terrain.theme == _Terrain3DClass.TerrainTheme.MARS, "Theme should be MARS")
	_assert(terrain.grid_size == Vector2i(50, 50), "Grid size should be 50x50")
	_assert(terrain.ground_depth == 3, "Ground depth should be 3")

	terrain.free()


func _test_earth_theme_colors() -> void:
	print("\n--- Earth Theme Colors ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.theme = _Terrain3DClass.TerrainTheme.EARTH
	var colors: Array[Color] = terrain._get_earth_colors()

	_assert(colors.size() >= 5, "Earth theme should have at least 5 colors")
	# Grass should be greenish
	_assert(colors[0].g > colors[0].r, "Earth topsoil should be greenish")
	# Bedrock should be grayish (R ≈ G ≈ B)
	_assert(abs(colors[4].r - colors[4].g) < 0.1, "Bedrock should be grayish")

	terrain.free()


func _test_mars_theme_colors() -> void:
	print("\n--- Mars Theme Colors ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.theme = _Terrain3DClass.TerrainTheme.MARS
	var colors: Array[Color] = terrain._get_mars_colors()

	_assert(colors.size() >= 5, "Mars theme should have at least 5 colors")
	# Mars surface should be reddish (R > G and R > B)
	_assert(colors[0].r > colors[0].g, "Mars surface should be reddish")
	_assert(colors[0].r > colors[0].b, "Mars surface should have more red than blue")

	terrain.free()


func _test_space_theme_colors() -> void:
	print("\n--- Space Theme Colors ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.theme = _Terrain3DClass.TerrainTheme.SPACE
	var colors: Array[Color] = terrain._get_space_colors()

	_assert(colors.size() >= 5, "Space theme should have at least 5 colors")
	# Space deck should be grayish/metallic (similar RGB values)
	_assert(abs(colors[0].r - colors[0].g) < 0.1, "Space deck should be grayish")
	# Metal roughness should be low
	_assert(terrain._get_roughness_for_theme() < 0.5, "Space theme should have low roughness")
	_assert(terrain._get_metallic_for_theme() > 0.5, "Space theme should be metallic")

	terrain.free()


func _test_cell_occupancy() -> void:
	print("\n--- Cell Occupancy ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Cells at y=-1 through y=-3 should exist
	_assert(terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell at y=-1 should exist")
	_assert(terrain.is_cell_occupied(Vector3i(0, -2, 0)), "Cell at y=-2 should exist")
	_assert(terrain.is_cell_occupied(Vector3i(0, -3, 0)), "Cell at y=-3 should exist")
	_assert(terrain.is_cell_occupied(Vector3i(5, -1, 5)), "Cell at (5,-1,5) should exist")

	terrain.free()


func _test_cell_occupancy_invalid() -> void:
	print("\n--- Cell Occupancy Invalid Positions ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Positions that should NOT exist
	_assert(not terrain.is_cell_occupied(Vector3i(0, 0, 0)), "Cell at y=0 should NOT exist")
	_assert(not terrain.is_cell_occupied(Vector3i(0, 1, 0)), "Cell at y=1 should NOT exist")
	_assert(not terrain.is_cell_occupied(Vector3i(0, -4, 0)), "Cell at y=-4 should NOT exist (depth=3)")
	_assert(not terrain.is_cell_occupied(Vector3i(-1, -1, 0)), "Cell at x=-1 should NOT exist")
	_assert(not terrain.is_cell_occupied(Vector3i(100, -1, 0)), "Cell at x=100 should NOT exist (size=10)")

	terrain.free()


func _test_find_top_ground_y() -> void:
	print("\n--- Find Top Ground Y ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Top ground should be y=-1
	var top_y: int = terrain.find_top_ground_y(0, 0)
	_assert(top_y == -1, "Top ground Y should be -1")

	top_y = terrain.find_top_ground_y(5, 5)
	_assert(top_y == -1, "Top ground Y at (5,5) should be -1")

	terrain.free()


func _test_find_top_ground_y_empty_column() -> void:
	print("\n--- Find Top Ground Y Empty Column ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Out of bounds column
	var top_y: int = terrain.find_top_ground_y(100, 100)
	_assert(top_y < -3, "Out of bounds column should return below ground depth")

	# Remove all cells in a column and check
	terrain.remove_cell(Vector3i(2, -1, 2))
	terrain.remove_cell(Vector3i(2, -2, 2))
	# Can't remove y=-3 (bedrock), so top_y should now be -3
	top_y = terrain.find_top_ground_y(2, 2)
	_assert(top_y == -3, "After removing upper layers, top should be bedrock at -3")

	terrain.free()


func _test_collision_body() -> void:
	print("\n--- Collision Body ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()
	root.add_child(terrain)
	await process_frame

	# Find collision body
	var collision_body: StaticBody3D = null
	for child in terrain.get_children():
		if child is StaticBody3D:
			collision_body = child
			break

	_assert(collision_body != null, "Terrain should have a StaticBody3D")
	_assert(collision_body.collision_layer == 1, "Collision layer should be 1")
	_assert(collision_body.has_meta("is_ground"), "Should have is_ground meta")
	_assert(collision_body.has_meta("is_terrain"), "Should have is_terrain meta")

	# Check collision shape
	var has_shape := false
	for child in collision_body.get_children():
		if child is CollisionShape3D:
			has_shape = true
			var shape: BoxShape3D = child.shape as BoxShape3D
			_assert(shape != null, "Collision shape should be BoxShape3D")
			if shape:
				# 10 cells * 6m = 60m
				_assert(shape.size.x == 60.0, "Collision box X should be 60m")
				_assert(shape.size.z == 60.0, "Collision box Z should be 60m")
				# 3 layers * 6m = 18m
				_assert(shape.size.y == 18.0, "Collision box Y should be 18m")

	_assert(has_shape, "Collision body should have a CollisionShape3D")

	terrain.queue_free()
	await process_frame


func _test_world_size() -> void:
	print("\n--- World Size ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	var size: Vector3 = terrain.get_world_size()
	_assert(size.x == 60.0, "World X size should be 60m (10 * 6)")
	_assert(size.z == 60.0, "World Z size should be 60m (10 * 6)")
	_assert(size.y == 18.0, "World Y size should be 18m (3 * 6)")

	terrain.free()


func _test_world_center() -> void:
	print("\n--- World Center ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	var center: Vector3 = terrain.get_world_center()
	_assert(center.x == 30.0, "World center X should be 30m")
	_assert(center.z == 30.0, "World center Z should be 30m")
	_assert(center.y == 0.0, "World center Y should be 0 (at surface)")

	terrain.free()


func _test_remove_cell() -> void:
	print("\n--- Remove Cell ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Initial state
	_assert(terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell should exist before removal")

	# Remove cell
	var result: bool = terrain.remove_cell(Vector3i(0, -1, 0))
	_assert(result, "remove_cell should return true for valid cell")
	_assert(not terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell should not exist after removal")

	terrain.free()


func _test_remove_cell_invalid() -> void:
	print("\n--- Remove Cell Invalid ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Try to remove non-existent cell
	var result: bool = terrain.remove_cell(Vector3i(100, -1, 100))
	_assert(not result, "remove_cell should return false for non-existent cell")

	# Try to remove cell at y=0 (above ground)
	result = terrain.remove_cell(Vector3i(0, 0, 0))
	_assert(not result, "remove_cell should return false for y=0")

	# Try to remove already-removed cell
	terrain.remove_cell(Vector3i(1, -1, 1))
	result = terrain.remove_cell(Vector3i(1, -1, 1))
	_assert(not result, "remove_cell should return false for already-removed cell")

	terrain.free()


func _test_bedrock_protection() -> void:
	print("\n--- Bedrock Protection ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	# Bedrock is at y=-3 (ground_depth = 3)
	_assert(terrain.is_bedrock(Vector3i(0, -3, 0)), "y=-3 should be bedrock")
	_assert(not terrain.is_bedrock(Vector3i(0, -2, 0)), "y=-2 should NOT be bedrock")
	_assert(not terrain.is_bedrock(Vector3i(0, -1, 0)), "y=-1 should NOT be bedrock")

	# Try to remove bedrock
	var result: bool = terrain.remove_cell(Vector3i(0, -3, 0))
	_assert(not result, "remove_cell should return false for bedrock")
	_assert(terrain.is_cell_occupied(Vector3i(0, -3, 0)), "Bedrock should still exist after removal attempt")

	terrain.free()


func _test_remove_cell_signal() -> void:
	print("\n--- Remove Cell Signal ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()

	var signal_received: Array = [false, Vector3i()]
	terrain.cell_removed.connect(func(pos: Vector3i):
		signal_received[0] = true
		signal_received[1] = pos
	)

	terrain.remove_cell(Vector3i(5, -1, 5))

	_assert(signal_received[0], "cell_removed signal should be emitted")
	_assert(signal_received[1] == Vector3i(5, -1, 5), "Signal should include correct position")

	# Signal should NOT be emitted for failed removal
	signal_received[0] = false
	terrain.remove_cell(Vector3i(5, -3, 5))  # Bedrock, should fail
	_assert(not signal_received[0], "Signal should NOT be emitted for failed removal")

	terrain.free()


func _test_clear_terrain() -> void:
	print("\n--- Clear Terrain ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()
	root.add_child(terrain)
	await process_frame

	# Verify terrain was generated
	_assert(terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell should exist after generate")

	# Clear terrain
	terrain._clear()

	_assert(not terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell should not exist after clear")

	terrain.queue_free()
	await process_frame


func _test_regenerate_terrain() -> void:
	print("\n--- Regenerate Terrain ---")
	var terrain: Node3D = _Terrain3DClass.new()
	terrain.configure_from_dict({"grid_size": Vector2i(10, 10), "ground_depth": 3})
	terrain.generate()
	root.add_child(terrain)
	await process_frame

	# Remove some cells
	terrain.remove_cell(Vector3i(0, -1, 0))
	terrain.remove_cell(Vector3i(1, -1, 1))
	_assert(not terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Removed cell should not exist")

	# Regenerate
	terrain.generate()

	# Cells should be back
	_assert(terrain.is_cell_occupied(Vector3i(0, -1, 0)), "Cell should exist after regenerate")
	_assert(terrain.is_cell_occupied(Vector3i(1, -1, 1)), "Cell should exist after regenerate")

	terrain.queue_free()
	await process_frame
