extends SceneTree
## Unit Tests - Tier 1
## Tests pure logic without rendering
## Run: godot --headless --script res://tests/unit_tests.gd

var passed := 0
var failed := 0

func _init() -> void:
	print("=" .repeat(60))
	print("UNIT TESTS")
	print("=" .repeat(60))

	# Run all tests
	test_isometric_constants()
	test_grid_to_screen()
	test_vector3i_basics()

	# Summary
	print("")
	print("=" .repeat(60))
	print("Results: %d passed, %d failed" % [passed, failed])
	print("=" .repeat(60))

	if failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		print("  ✓ %s" % message)
		passed += 1
	else:
		print("  ✗ %s" % message)
		print("    Expected: %s" % str(expected))
		print("    Actual:   %s" % str(actual))
		failed += 1

func assert_true(condition: bool, message: String) -> void:
	if condition:
		print("  ✓ %s" % message)
		passed += 1
	else:
		print("  ✗ %s" % message)
		failed += 1

# === TESTS ===

func test_isometric_constants() -> void:
	print("")
	print("Testing: Isometric Constants")

	# These should match documentation/quick-reference/isometric-math.md
	const TILE_WIDTH := 64
	const TILE_HEIGHT := 32
	const FLOOR_HEIGHT := 24

	assert_eq(TILE_WIDTH, 64, "TILE_WIDTH is 64")
	assert_eq(TILE_HEIGHT, 32, "TILE_HEIGHT is 32")
	assert_eq(FLOOR_HEIGHT, 24, "FLOOR_HEIGHT is 24")
	assert_eq(TILE_WIDTH / TILE_HEIGHT, 2, "Tile ratio is 2:1")

func test_grid_to_screen() -> void:
	print("")
	print("Testing: Grid to Screen Conversion")

	const TILE_WIDTH := 64
	const TILE_HEIGHT := 32
	const FLOOR_HEIGHT := 24

	# Test function (inline since Grid class may not exist yet)
	var grid_to_screen := func(grid_pos: Vector3i) -> Vector2:
		var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
		var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
		y -= grid_pos.z * FLOOR_HEIGHT
		return Vector2(x, y)

	# Origin
	assert_eq(grid_to_screen.call(Vector3i(0, 0, 0)), Vector2(0, 0), "Origin at (0,0)")

	# Moving +X (East) = right and down
	assert_eq(grid_to_screen.call(Vector3i(1, 0, 0)), Vector2(32, 16), "(1,0,0) is right-down")

	# Moving +Y (South) = left and down
	assert_eq(grid_to_screen.call(Vector3i(0, 1, 0)), Vector2(-32, 16), "(0,1,0) is left-down")

	# Moving +Z (Up) = up on screen
	assert_eq(grid_to_screen.call(Vector3i(0, 0, 1)), Vector2(0, -24), "(0,0,1) is up")

	# Combined
	assert_eq(grid_to_screen.call(Vector3i(1, 1, 0)), Vector2(0, 32), "(1,1,0) is straight down")

func test_vector3i_basics() -> void:
	print("")
	print("Testing: Vector3i Basics")

	var pos := Vector3i(1, 2, 3)
	assert_eq(pos.x, 1, "Vector3i.x works")
	assert_eq(pos.y, 2, "Vector3i.y works")
	assert_eq(pos.z, 3, "Vector3i.z works")

	var neighbors := [
		pos + Vector3i(1, 0, 0),
		pos + Vector3i(-1, 0, 0),
		pos + Vector3i(0, 1, 0),
		pos + Vector3i(0, -1, 0),
		pos + Vector3i(0, 0, 1),
		pos + Vector3i(0, 0, -1),
	]
	assert_eq(neighbors.size(), 6, "6 orthogonal neighbors")
