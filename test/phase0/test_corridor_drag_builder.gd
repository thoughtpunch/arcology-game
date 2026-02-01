## GdUnit4 test suite for CorridorDragBuilder — Manhattan routing for drag-to-build.
## Tests path computation, validation, and the is_drag_buildable check.
class_name TestCorridorDragBuilder
extends GdUnitTestSuite

const CorridorDragScript = preload("res://src/phase0/corridor_drag_builder.gd")
const RegistryScript = preload("res://src/phase0/block_registry.gd")
const GridUtilsScript = preload("res://src/phase0/grid_utils.gd")

var _registry: RefCounted


func before_test() -> void:
	_registry = auto_free(RegistryScript.new())


# --- compute_path: basic cases ---


func test_same_start_and_end() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(5, 0, 5), Vector3i(5, 0, 5))
	assert_int(path.size()).is_equal(1)
	assert_object(path[0]).is_equal(Vector3i(5, 0, 5))


func test_straight_line_east() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(3, 0, 0))
	assert_int(path.size()).is_equal(4)
	assert_object(path[0]).is_equal(Vector3i(0, 0, 0))
	assert_object(path[1]).is_equal(Vector3i(1, 0, 0))
	assert_object(path[2]).is_equal(Vector3i(2, 0, 0))
	assert_object(path[3]).is_equal(Vector3i(3, 0, 0))


func test_straight_line_west() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(3, 0, 0), Vector3i(0, 0, 0))
	assert_int(path.size()).is_equal(4)
	assert_object(path[0]).is_equal(Vector3i(3, 0, 0))
	assert_object(path[3]).is_equal(Vector3i(0, 0, 0))


func test_straight_line_north() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(0, 0, 4))
	assert_int(path.size()).is_equal(5)
	assert_object(path[0]).is_equal(Vector3i(0, 0, 0))
	assert_object(path[4]).is_equal(Vector3i(0, 0, 4))


func test_straight_line_south() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 4), Vector3i(0, 0, 0))
	assert_int(path.size()).is_equal(5)
	assert_object(path[0]).is_equal(Vector3i(0, 0, 4))
	assert_object(path[4]).is_equal(Vector3i(0, 0, 0))


# --- compute_path: L-shaped (Manhattan routing) ---


func test_l_shape_x_dominant() -> void:
	# X distance (5) > Z distance (2): should go X first, then Z
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(5, 0, 2))
	# Total cells: 5 (X) + 2 (Z) + 1 (start) = 8
	assert_int(path.size()).is_equal(8)
	# First cell is start
	assert_object(path[0]).is_equal(Vector3i(0, 0, 0))
	# Last cell is end
	assert_object(path[7]).is_equal(Vector3i(5, 0, 2))
	# Corner should be at (5, 0, 0) - end of X leg
	assert_object(path[5]).is_equal(Vector3i(5, 0, 0))
	# All cells should be at y=0
	for cell in path:
		assert_int(cell.y).is_equal(0)
	# No diagonals: each step should differ by exactly 1 in x or z
	for i in range(1, path.size()):
		var dx: int = absi(path[i].x - path[i - 1].x)
		var dz: int = absi(path[i].z - path[i - 1].z)
		assert_int(dx + dz).is_equal(1)


func test_l_shape_z_dominant() -> void:
	# Z distance (5) > X distance (2): should go Z first, then X
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(2, 0, 5))
	assert_int(path.size()).is_equal(8)
	assert_object(path[0]).is_equal(Vector3i(0, 0, 0))
	assert_object(path[7]).is_equal(Vector3i(2, 0, 5))
	# Corner should be at (0, 0, 5) — end of Z leg
	assert_object(path[5]).is_equal(Vector3i(0, 0, 5))


func test_l_shape_equal_distance() -> void:
	# Equal X and Z distance: X dominant (>=), so X first
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(3, 0, 3))
	assert_int(path.size()).is_equal(7)
	assert_object(path[0]).is_equal(Vector3i(0, 0, 0))
	assert_object(path[6]).is_equal(Vector3i(3, 0, 3))
	# Corner at (3, 0, 0)
	assert_object(path[3]).is_equal(Vector3i(3, 0, 0))


func test_l_shape_negative_direction() -> void:
	# Going southwest: negative X and Z
	var path := CorridorDragScript.compute_path(Vector3i(5, 0, 5), Vector3i(0, 0, 3))
	assert_int(path.size()).is_equal(8)
	assert_object(path[0]).is_equal(Vector3i(5, 0, 5))
	assert_object(path[7]).is_equal(Vector3i(0, 0, 3))
	# No diagonals
	for i in range(1, path.size()):
		var dx: int = absi(path[i].x - path[i - 1].x)
		var dz: int = absi(path[i].z - path[i - 1].z)
		assert_int(dx + dz).is_equal(1)


# --- compute_path: different Y levels (should fail) ---


func test_different_y_returns_empty() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(3, 1, 0))
	assert_int(path.size()).is_equal(0)


# --- compute_path: no duplicate cells ---


func test_no_duplicate_cells() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 0, 0), Vector3i(4, 0, 3))
	var seen: Dictionary = {}
	for cell in path:
		assert_bool(seen.has(cell)).is_false()
		seen[cell] = true


# --- compute_path: elevated Y level ---


func test_elevated_y_level() -> void:
	var path := CorridorDragScript.compute_path(Vector3i(0, 5, 0), Vector3i(3, 5, 0))
	assert_int(path.size()).is_equal(4)
	for cell in path:
		assert_int(cell.y).is_equal(5)


# --- is_drag_buildable ---


func test_corridor_is_drag_buildable() -> void:
	var def = _registry.get_definition("corridor")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_true()


func test_stairs_is_drag_buildable() -> void:
	var def = _registry.get_definition("stairs")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_true()


func test_entrance_not_drag_buildable() -> void:
	# ground_only blocks cannot be drag-built
	var def = _registry.get_definition("entrance")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_false()


func test_elevator_shaft_not_drag_buildable() -> void:
	# elevator_shaft has connects_horizontal=false
	var def = _registry.get_definition("elevator_shaft")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_false()


func test_residential_not_drag_buildable() -> void:
	var def = _registry.get_definition("residential_standard")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_false()


func test_multisize_corridor_not_drag_buildable() -> void:
	# corridor_medium is 2x1x1, so not 1x1x1
	var def = _registry.get_definition("corridor_medium")
	assert_bool(CorridorDragScript.is_drag_buildable(def)).is_false()


# --- validate_path ---


func test_validate_path_all_valid() -> void:
	# Setup: ground at y=-1, entrance at (0,0,0), corridor path from (1,0,0) to (3,0,0)
	var occupancy: Dictionary = {}
	for x in range(10):
		for z in range(10):
			occupancy[Vector3i(x, -1, z)] = -1
	occupancy[Vector3i(0, 0, 0)] = 1  # entrance block

	var corridor_def = _registry.get_definition("corridor")
	var path: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, true,
		Vector2i(0, 0), Vector2i(10, 10), 5
	)

	assert_bool(result.all_valid).is_true()
	assert_int(result.valid.size()).is_equal(3)
	assert_int(result.invalid.size()).is_equal(0)
	assert_int(result.cost).is_equal(300)  # 3 corridors at 100 each


func test_validate_path_skips_occupied() -> void:
	# Setup: ground + entrance + existing corridor at (1,0,0)
	var occupancy: Dictionary = {}
	for x in range(10):
		for z in range(10):
			occupancy[Vector3i(x, -1, z)] = -1
	occupancy[Vector3i(0, 0, 0)] = 1  # entrance
	occupancy[Vector3i(1, 0, 0)] = 2  # existing corridor

	var corridor_def = _registry.get_definition("corridor")
	var path: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, true,
		Vector2i(0, 0), Vector2i(10, 10), 5
	)

	# (0,0,0) and (1,0,0) are occupied — skipped. Only (2,0,0) is new and valid.
	assert_int(result.valid.size()).is_equal(1)
	assert_object(result.valid[0]).is_equal(Vector3i(2, 0, 0))
	assert_int(result.cost).is_equal(100)


func test_validate_path_outside_build_zone() -> void:
	var occupancy: Dictionary = {}
	for x in range(10):
		for z in range(10):
			occupancy[Vector3i(x, -1, z)] = -1
	occupancy[Vector3i(0, 0, 0)] = 1  # entrance

	var corridor_def = _registry.get_definition("corridor")
	# Path goes outside build zone (0,0)-(5,5)
	var path: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(6, 0, 0)]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, true,
		Vector2i(0, 0), Vector2i(5, 5), 5
	)

	# (6,0,0) is outside build zone
	assert_int(result.invalid.size()).is_greater(0)
	assert_bool(result.all_valid).is_false()


func test_validate_path_no_entrance() -> void:
	var occupancy: Dictionary = {}
	var corridor_def = _registry.get_definition("corridor")
	var path: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, false,  # no entrance
		Vector2i(0, 0), Vector2i(10, 10), 5
	)

	assert_bool(result.all_valid).is_false()
	assert_int(result.valid.size()).is_equal(0)


func test_validate_path_chain_support() -> void:
	# Path cells support each other: first cell adjacent to entrance,
	# subsequent cells adjacent to earlier valid cells.
	var occupancy: Dictionary = {}
	for x in range(10):
		for z in range(10):
			occupancy[Vector3i(x, -1, z)] = -1
	occupancy[Vector3i(0, 0, 0)] = 1  # entrance

	var corridor_def = _registry.get_definition("corridor")
	# Long chain from entrance
	var path: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0),
		Vector3i(4, 0, 0), Vector3i(5, 0, 0),
	]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, true,
		Vector2i(0, 0), Vector2i(10, 10), 5
	)

	# All cells should chain-support from the entrance
	assert_bool(result.all_valid).is_true()
	assert_int(result.valid.size()).is_equal(5)


func test_validate_path_unsupported_island() -> void:
	# A path that starts far from any placed block should be invalid
	var occupancy: Dictionary = {}
	for x in range(20):
		for z in range(20):
			occupancy[Vector3i(x, -1, z)] = -1
	occupancy[Vector3i(0, 0, 0)] = 1  # entrance at (0,0,0)

	var corridor_def = _registry.get_definition("corridor")
	# Path starting far from entrance with no adjacent blocks
	var path: Array[Vector3i] = [Vector3i(10, 0, 10), Vector3i(11, 0, 10)]

	var result := CorridorDragScript.validate_path(
		path, corridor_def, occupancy, true,
		Vector2i(0, 0), Vector2i(20, 20), 5
	)

	# First cell has no adjacent placed block → invalid
	# Second cell could chain from first, but first is invalid → also invalid
	assert_int(result.valid.size()).is_equal(0)
	assert_int(result.invalid.size()).is_equal(2)
