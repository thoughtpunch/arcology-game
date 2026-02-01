## GdUnit4 test suite for cantilever enforcement in Phase 0 sandbox.
## Tests that the core PlacementValidator correctly enforces cantilever limits
## when wired into sandbox_main's placement flow.
##
## Since sandbox_main.gd is a Node3D with heavy scene dependencies,
## we replicate the core placement logic here and wire in PlacementValidator.
class_name TestSandboxCantilever
extends GdUnitTestSuite

const RegistryScript = preload("res://src/game/block_registry.gd")
const GridUtilsScript = preload("res://src/game/grid_utils.gd")
const PlacementValidatorScript = preload("res://src/game/placement_validator.gd")
const CoreScenarioConfigScript = preload("res://src/game/structural_scenario_config.gd")

var _registry: RefCounted
var _cell_occupancy: Dictionary  # Vector3i -> int (block_id, -1=ground)
var _placed_blocks: Dictionary  # block_id -> {definition, occupied_cells}
var _entrance_block_ids: Dictionary  # block_id -> true
var _has_entrance: bool
var _next_id: int
var _placement_validator: RefCounted


func before_test() -> void:
	_registry = auto_free(RegistryScript.new())
	_cell_occupancy = {}
	_placed_blocks = {}
	_entrance_block_ids = {}
	_has_entrance = false
	_next_id = 1

	# Lay ground at y=-1 for build zone (small area for testing)
	for x in range(20):
		for z in range(20):
			_cell_occupancy[Vector3i(x, -1, z)] = -1

	# Set up PlacementValidator with Earth gravity (max_cantilever=2)
	var core_config: Resource = CoreScenarioConfigScript.new()
	core_config.gravity = 1.0
	core_config.max_cantilever = 2
	core_config.structural_integrity = true
	core_config.ground_depth = 3
	_placement_validator = PlacementValidatorScript.new(self, _registry, core_config)


# --- Grid-compatible API (mirrors sandbox_main) ---


func has_block(pos: Vector3i) -> bool:
	return _cell_occupancy.has(pos) and _cell_occupancy[pos] > 0


func get_block_at(pos: Vector3i) -> Variant:
	if not _cell_occupancy.has(pos):
		return null
	var bid: int = _cell_occupancy[pos]
	if bid <= 0:
		return null
	if not _placed_blocks.has(bid):
		return null
	var block: Dictionary = _placed_blocks[bid]
	return {
		"block_type": block.definition.id,
		"grid_position": pos,
		"traversability": block.definition.traversability,
	}


func get_all_positions() -> Array:
	var positions: Array = []
	for pos in _cell_occupancy:
		if _cell_occupancy[pos] > 0:
			positions.append(pos)
	return positions


func get_entrance_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	for eid in _entrance_block_ids:
		if _placed_blocks.has(eid):
			for cell in _placed_blocks[eid].occupied_cells:
				positions.append(cell)
	return positions


# --- Placement helpers ---


func _is_supported(cells: Array[Vector3i], definition: Resource) -> bool:
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	if definition.ground_only:
		for cell in cells:
			var below := Vector3i(cell.x, cell.y - 1, cell.z)
			if _cell_occupancy.has(below) and _cell_occupancy[below] == -1:
				return true
		return false
	else:
		for cell in cells:
			for dir in directions:
				var neighbor: Vector3i = cell + dir
				if _cell_occupancy.has(neighbor) and _cell_occupancy[neighbor] > 0:
					return true
		return false


func _can_place(def_id: String, origin: Vector3i, rot: int = 0) -> bool:
	var definition: Resource = _registry.get_definition(def_id)
	if definition == null:
		return false
	if not _has_entrance and def_id != "entrance":
		return false
	if definition.ground_only and origin.y != 0:
		return false
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(definition.size, origin, rot)
	for cell in cells:
		if _cell_occupancy.has(cell) and _cell_occupancy[cell] != -1:
			return false

	# Entrance: needs ground below
	if definition.ground_only:
		var has_ground := false
		for cell in cells:
			var below := Vector3i(cell.x, cell.y - 1, cell.z)
			if _cell_occupancy.has(below) and _cell_occupancy[below] == -1:
				has_ground = true
				break
		return has_ground

	# Non-entrance: adjacency + cantilever validation
	if not _is_supported(cells, definition):
		return false
	if _placement_validator:
		var result = _placement_validator.validate_multi_cell_placement(cells, def_id)
		if not result.valid:
			return false
	return true


func _place(def_id: String, origin: Vector3i, rot: int = 0) -> int:
	if not _can_place(def_id, origin, rot):
		return -1
	var definition: Resource = _registry.get_definition(def_id)
	var block_id := _next_id
	_next_id += 1
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(definition.size, origin, rot)
	for cell in cells:
		_cell_occupancy[cell] = block_id
	_placed_blocks[block_id] = {
		"definition": definition,
		"occupied_cells": cells,
	}
	if def_id == "entrance":
		_entrance_block_ids[block_id] = true
		_has_entrance = true
	return block_id


# ============================================================
# Tests
# ============================================================


func test_entrance_placement_at_ground() -> void:
	# Entrance at ground level should work
	var bid := _place("entrance", Vector3i(5, 0, 5))
	assert_int(bid).is_greater(0)
	assert_bool(has_block(Vector3i(5, 0, 5))).is_true()


func test_corridor_adjacent_to_entrance() -> void:
	# Corridor adjacent to entrance should work
	_place("entrance", Vector3i(5, 0, 5))
	var bid := _place("corridor", Vector3i(6, 0, 5))
	assert_int(bid).is_greater(0)


func test_corridor_on_top_of_supported_column() -> void:
	# Build a column: entrance + corridor above
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(6, 0, 5))
	# Stack up: floor 1 on top of entrance
	var bid := _place("corridor", Vector3i(5, 1, 5))
	assert_int(bid).is_greater(0)


func test_cantilever_1_cell_ok() -> void:
	# Build supported column, then 1 cell cantilever
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(5, 1, 5))  # column: floor 1
	# 1 cell cantilever east
	var bid := _place("corridor", Vector3i(6, 1, 5))
	assert_int(bid).is_greater(0)


func test_cantilever_2_cells_at_limit() -> void:
	# Build supported column, then 2 cells cantilever (at limit for Earth)
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(5, 1, 5))
	_place("corridor", Vector3i(6, 1, 5))  # cant=1
	var bid := _place("corridor", Vector3i(7, 1, 5))  # cant=2
	assert_int(bid).is_greater(0)


func test_cantilever_3_cells_rejected() -> void:
	# Build supported column + 2 cantilever, 3rd should fail
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(5, 1, 5))
	_place("corridor", Vector3i(6, 1, 5))
	_place("corridor", Vector3i(7, 1, 5))
	# 3rd cantilever should be rejected
	var bid := _place("corridor", Vector3i(8, 1, 5))
	assert_int(bid).is_equal(-1)


func test_two_columns_bridge() -> void:
	# Two columns 4 apart, bridge between them
	# Build ground-level path for connectivity first
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(6, 0, 5))
	_place("corridor", Vector3i(7, 0, 5))
	_place("corridor", Vector3i(8, 0, 5))
	_place("corridor", Vector3i(9, 0, 5))
	# Now build up columns at x=5 and x=9
	_place("corridor", Vector3i(5, 1, 5))
	_place("corridor", Vector3i(9, 1, 5))

	# Bridge from x=5 column: 6,7 are cant=1,2 from left
	_place("corridor", Vector3i(6, 1, 5))
	_place("corridor", Vector3i(7, 1, 5))
	# x=8 is cant=1 from right column at x=9
	var bid := _place("corridor", Vector3i(8, 1, 5))
	assert_int(bid).is_greater(0)


func test_floating_block_rejected() -> void:
	# Isolated block above ground with no support should fail
	_place("entrance", Vector3i(5, 0, 5))
	# Try to place at floor 3 with nothing below
	var bid := _place("corridor", Vector3i(10, 3, 10))
	assert_int(bid).is_equal(-1)


func test_cantilever_diagonal_rejected() -> void:
	# Diagonal path: (5,1,5) -> (6,1,5) -> (6,1,6) = 2 cells Manhattan from column
	# Then (7,1,6) would be 3 cells from column = rejected
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(5, 1, 5))
	_place("corridor", Vector3i(6, 1, 5))
	_place("corridor", Vector3i(6, 1, 6))
	# (7,1,6) is manhattan 3 from (5,1,5) through the chain
	var bid := _place("corridor", Vector3i(7, 1, 6))
	assert_int(bid).is_equal(-1)


func test_multi_cell_block_cantilever() -> void:
	# Place a large block (e.g., department_store 3x2x3) and check cantilever
	_place("entrance", Vector3i(5, 0, 5))
	# Build support columns for a large block origin at (6,0,5)
	_place("corridor", Vector3i(6, 0, 5))
	_place("corridor", Vector3i(7, 0, 5))
	_place("corridor", Vector3i(8, 0, 5))
	# The department_store at ground level should be fine (y=0 = always supported)
	var def: Resource = _registry.get_definition("department_store")
	if def != null:
		_place("department_store", Vector3i(6, 0, 5))
		# Whether this works depends on adjacency and occupancy; just verify no crash
		# The key test is cantilever enforcement, not large-block placement at ground


func test_ground_level_always_supported() -> void:
	# Ground-level corridors don't need cantilever support
	_place("entrance", Vector3i(5, 0, 5))
	var bid := _place("corridor", Vector3i(6, 0, 5))
	assert_int(bid).is_greater(0)
	var bid2 := _place("corridor", Vector3i(7, 0, 5))
	assert_int(bid2).is_greater(0)
	# Even far from column, ground level is always structurally OK
	var bid3 := _place("corridor", Vector3i(8, 0, 5))
	assert_int(bid3).is_greater(0)


func test_validator_result_details() -> void:
	# Directly test validate_multi_cell_placement returns good error messages
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(5, 1, 5))
	_place("corridor", Vector3i(6, 1, 5))
	_place("corridor", Vector3i(7, 1, 5))
	# Try 3rd cantilever
	var cells: Array[Vector3i] = [Vector3i(8, 1, 5)]
	var result = _placement_validator.validate_multi_cell_placement(cells, "corridor")
	assert_bool(result.valid).is_false()
	assert_str(result.reason).contains("cantilever")
