extends SceneTree
## Tests for terrain decoration clear zone feature

var _terrain_script: GDScript
var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== Terrain Clear Zone Tests ===")

	# Load the script dynamically
	_terrain_script = load("res://src/core/terrain.gd") as GDScript
	if not _terrain_script:
		print("ERROR: Could not load terrain.gd")
		quit()
		return

	# Run tests
	_test_get_decoration_clear_zone_earth()
	_test_get_decoration_clear_zone_mars()
	_test_get_decoration_clear_zone_space()
	_test_is_in_clear_zone_at_center()
	_test_is_in_clear_zone_at_edge()
	_test_is_in_clear_zone_outside()
	_test_is_in_clear_zone_diagonal()
	_test_no_decorations_in_clear_zone()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


func _create_terrain() -> Node2D:
	return _terrain_script.new()


func _test_get_decoration_clear_zone_earth() -> void:
	var terrain := _create_terrain()
	terrain.theme = "earth"

	var clear_zone: Dictionary = terrain.get_decoration_clear_zone()

	assert(not clear_zone.is_empty(), "Earth theme should have a clear zone")
	assert(clear_zone.has("center"), "Clear zone should have center")
	assert(clear_zone.has("radius"), "Clear zone should have radius")

	var center: Array = clear_zone.get("center", [])
	assert(center.size() == 2, "Center should have 2 elements")
	assert(center[0] == 0, "Center X should be 0")
	assert(center[1] == 0, "Center Y should be 0")
	assert(clear_zone.get("radius", 0.0) == 5.0, "Earth clear zone radius should be 5")

	_pass("get_decoration_clear_zone_earth")
	terrain.free()


func _test_get_decoration_clear_zone_mars() -> void:
	var terrain := _create_terrain()
	terrain.theme = "mars"

	var clear_zone: Dictionary = terrain.get_decoration_clear_zone()

	assert(not clear_zone.is_empty(), "Mars theme should have a clear zone")
	assert(clear_zone.get("radius", 0.0) == 4.0, "Mars clear zone radius should be 4")

	_pass("get_decoration_clear_zone_mars")
	terrain.free()


func _test_get_decoration_clear_zone_space() -> void:
	var terrain := _create_terrain()
	terrain.theme = "space"

	var clear_zone: Dictionary = terrain.get_decoration_clear_zone()

	# Space has no decorations and thus no clear zone
	assert(clear_zone.is_empty(), "Space theme should have empty clear zone (no decorations)")

	_pass("get_decoration_clear_zone_space")
	terrain.free()


func _test_is_in_clear_zone_at_center() -> void:
	var terrain := _create_terrain()

	var center := Vector2i(0, 0)
	var radius := 5.0

	# Position at exact center should be in clear zone
	assert(terrain._is_in_clear_zone(Vector2i(0, 0), center, radius), "Center (0,0) should be in clear zone")

	_pass("is_in_clear_zone_at_center")
	terrain.free()


func _test_is_in_clear_zone_at_edge() -> void:
	var terrain := _create_terrain()

	var center := Vector2i(0, 0)
	var radius := 5.0

	# Position at edge should be in clear zone (distance = 5)
	assert(terrain._is_in_clear_zone(Vector2i(5, 0), center, radius), "(5,0) should be at edge of clear zone")
	assert(terrain._is_in_clear_zone(Vector2i(0, 5), center, radius), "(0,5) should be at edge of clear zone")
	assert(terrain._is_in_clear_zone(Vector2i(-5, 0), center, radius), "(-5,0) should be at edge of clear zone")
	assert(terrain._is_in_clear_zone(Vector2i(0, -5), center, radius), "(0,-5) should be at edge of clear zone")

	_pass("is_in_clear_zone_at_edge")
	terrain.free()


func _test_is_in_clear_zone_outside() -> void:
	var terrain := _create_terrain()

	var center := Vector2i(0, 0)
	var radius := 5.0

	# Position outside clear zone
	assert(not terrain._is_in_clear_zone(Vector2i(6, 0), center, radius), "(6,0) should be outside clear zone")
	assert(not terrain._is_in_clear_zone(Vector2i(0, 6), center, radius), "(0,6) should be outside clear zone")
	assert(not terrain._is_in_clear_zone(Vector2i(10, 10), center, radius), "(10,10) should be outside clear zone")

	_pass("is_in_clear_zone_outside")
	terrain.free()


func _test_is_in_clear_zone_diagonal() -> void:
	var terrain := _create_terrain()

	var center := Vector2i(0, 0)
	var radius := 5.0

	# Diagonal position - distance is sqrt(3^2 + 3^2) = sqrt(18) ≈ 4.24, which is inside
	assert(terrain._is_in_clear_zone(Vector2i(3, 3), center, radius), "(3,3) should be inside (distance ~4.24)")

	# Diagonal position - distance is sqrt(4^2 + 4^2) = sqrt(32) ≈ 5.66, which is outside
	assert(not terrain._is_in_clear_zone(Vector2i(4, 4), center, radius), "(4,4) should be outside (distance ~5.66)")

	_pass("is_in_clear_zone_diagonal")
	terrain.free()


func _test_no_decorations_in_clear_zone() -> void:
	var terrain := _create_terrain()
	terrain.theme = "earth"
	terrain.world_seed = 12345

	# Scatter decorations over a small area that includes clear zone
	var area := Rect2i(-10, -10, 20, 20)
	terrain.scatter_decorations(area)

	# Get all decoration positions
	var positions: Array[Vector2i] = terrain.get_all_decoration_positions()

	# Check that no decorations are within clear zone (radius 5 from 0,0)
	var center := Vector2i(0, 0)
	var radius := 5.0
	var in_clear_zone := 0

	for pos in positions:
		if terrain._is_in_clear_zone(pos, center, radius):
			in_clear_zone += 1
			print("  ERROR: Found decoration at %s which is inside clear zone" % pos)

	assert(in_clear_zone == 0, "No decorations should be inside clear zone")

	# Also verify that decorations do exist outside clear zone (test scatter is working)
	assert(positions.size() > 0, "Should have some decorations outside clear zone")

	_pass("no_decorations_in_clear_zone")
	terrain.free()


func _pass(test_name: String) -> void:
	print("  ✓ %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, message: String) -> void:
	print("  ✗ %s: %s" % [test_name, message])
	_tests_failed += 1
