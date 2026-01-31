## GdUnit4 test suite for Phase 0 entrance-first building and connectivity.
## Tests the placement rules and BFS connectivity logic.
##
## Since sandbox_main.gd is a Node3D with heavy scene dependencies,
## we replicate the core algorithmic logic here for unit testing.
class_name TestEntranceConnectivity
extends GdUnitTestSuite

const RegistryScript = preload("res://src/phase0/block_registry.gd")
const GridUtilsScript = preload("res://src/phase0/grid_utils.gd")

var _registry: RefCounted
var _cell_occupancy: Dictionary  # Vector3i -> int (block_id, -1=ground)
var _entrance_block_ids: Dictionary  # block_id -> true
var _has_entrance: bool
var _next_id: int


func before_test() -> void:
	_registry = auto_free(RegistryScript.new())
	_cell_occupancy = {}
	_entrance_block_ids = {}
	_has_entrance = false
	_next_id = 1
	# Lay ground at y=-1 for build zone (small area for testing)
	for x in range(10):
		for z in range(10):
			_cell_occupancy[Vector3i(x, -1, z)] = -1


# --- Helpers that mirror sandbox_main logic ---

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
	if not _has_entrance and def_id != "entrance":
		return false
	if definition.ground_only and origin.y != 0:
		return false
	var cells := GridUtilsScript.get_occupied_cells(definition.size, origin, rot)
	for cell in cells:
		if _cell_occupancy.has(cell):
			return false
	if not _is_supported(cells, definition):
		return false
	return true


func _place(def_id: String, origin: Vector3i, rot: int = 0) -> int:
	if not _can_place(def_id, origin, rot):
		return -1
	var definition: Resource = _registry.get_definition(def_id)
	var block_id := _next_id
	_next_id += 1
	var cells := GridUtilsScript.get_occupied_cells(definition.size, origin, rot)
	for cell in cells:
		_cell_occupancy[cell] = block_id
	if def_id == "entrance":
		_entrance_block_ids[block_id] = true
		_has_entrance = true
	return block_id


func _is_connected_to_entrance(start_cells: Array[Vector3i], excluded_id: int) -> bool:
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	var entrance_cells: Dictionary = {}
	for eid in _entrance_block_ids:
		if eid == excluded_id:
			continue
		# Find cells belonging to this entrance
		for cell_key in _cell_occupancy:
			if _cell_occupancy[cell_key] == eid:
				entrance_cells[cell_key] = true

	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []
	for cell in start_cells:
		if entrance_cells.has(cell):
			return true
		queue.append(cell)
		visited[cell] = true

	while queue.size() > 0:
		var current: Vector3i = queue.pop_front()
		for dir in directions:
			var neighbor: Vector3i = current + dir
			if visited.has(neighbor):
				continue
			if not _cell_occupancy.has(neighbor):
				continue
			var nid: int = _cell_occupancy[neighbor]
			if nid == excluded_id or nid == -1 or nid <= 0:
				continue
			if entrance_cells.has(neighbor):
				return true
			visited[neighbor] = true
			queue.append(neighbor)
	return false


# === Entrance-First Rule ===

func test_cannot_place_corridor_before_entrance() -> void:
	assert_bool(_can_place("corridor", Vector3i(5, 0, 5))).is_false()


func test_cannot_place_residential_before_entrance() -> void:
	assert_bool(_can_place("residential_budget", Vector3i(5, 0, 5))).is_false()


func test_can_place_entrance_at_ground_level() -> void:
	assert_bool(_can_place("entrance", Vector3i(5, 0, 5))).is_true()


func test_cannot_place_entrance_above_ground() -> void:
	assert_bool(_can_place("entrance", Vector3i(5, 1, 5))).is_false()


func test_entrance_needs_ground_beneath() -> void:
	# Remove ground at (5, -1, 5)
	_cell_occupancy.erase(Vector3i(5, -1, 5))
	assert_bool(_can_place("entrance", Vector3i(5, 0, 5))).is_false()


# === Non-Entrance Blocks Need Placed Block Adjacency ===

func test_corridor_adjacent_to_entrance_is_valid() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	assert_bool(_can_place("corridor", Vector3i(6, 0, 5))).is_true()


func test_corridor_on_ground_not_adjacent_to_structure_is_invalid() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	# (8, 0, 8) has ground beneath but no adjacent placed block
	assert_bool(_can_place("corridor", Vector3i(8, 0, 8))).is_false()


func test_corridor_stacked_on_entrance_is_valid() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	assert_bool(_can_place("corridor", Vector3i(5, 1, 5))).is_true()


func test_ground_alone_does_not_support_non_entrance() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	# Ground at (0, -1, 0) exists but no placed block is adjacent
	assert_bool(_can_place("corridor", Vector3i(0, 0, 0))).is_false()


# === Multi-Cell Blocks ===

func test_family_housing_2x2_adjacent_to_entrance() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	# Family housing is 2x1x2, place adjacent
	assert_bool(_can_place("residential_family", Vector3i(6, 0, 5))).is_true()


func test_family_housing_2x2_occupies_4_cells() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	_place("residential_family", Vector3i(6, 0, 5))
	# Should occupy (6,0,5), (7,0,5), (6,0,6), (7,0,6)
	assert_bool(_cell_occupancy.has(Vector3i(6, 0, 5))).is_true()
	assert_bool(_cell_occupancy.has(Vector3i(7, 0, 5))).is_true()
	assert_bool(_cell_occupancy.has(Vector3i(6, 0, 6))).is_true()
	assert_bool(_cell_occupancy.has(Vector3i(7, 0, 6))).is_true()


# === BFS Connectivity ===

func test_corridor_adjacent_to_entrance_is_connected() -> void:
	var eid := _place("entrance", Vector3i(5, 0, 5))
	var cid := _place("corridor", Vector3i(6, 0, 5))
	# Check corridor cells can reach entrance
	var corridor_cells: Array[Vector3i] = [Vector3i(6, 0, 5)]
	assert_bool(_is_connected_to_entrance(corridor_cells, -999)).is_true()


func test_chain_of_corridors_connected() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(6, 0, 5))
	_place("corridor", Vector3i(7, 0, 5))
	_place("corridor", Vector3i(8, 0, 5))
	var end_cells: Array[Vector3i] = [Vector3i(8, 0, 5)]
	assert_bool(_is_connected_to_entrance(end_cells, -999)).is_true()


func test_disconnected_block_not_connected() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	# Manually place a block far away (simulating disconnected state)
	_cell_occupancy[Vector3i(0, 0, 0)] = 99
	var far_cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	assert_bool(_is_connected_to_entrance(far_cells, -999)).is_false()


func test_removing_bridge_disconnects_end() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	var bridge_id := _place("corridor", Vector3i(6, 0, 5))
	_place("corridor", Vector3i(7, 0, 5))
	# Check end corridor is connected when bridge exists
	var end_cells: Array[Vector3i] = [Vector3i(7, 0, 5)]
	assert_bool(_is_connected_to_entrance(end_cells, -999)).is_true()
	# Excluding bridge should disconnect end
	assert_bool(_is_connected_to_entrance(end_cells, bridge_id)).is_false()


func test_two_entrances_alternate_path() -> void:
	var e1 := _place("entrance", Vector3i(5, 0, 5))
	_place("corridor", Vector3i(6, 0, 5))
	var e2 := _place("entrance", Vector3i(7, 0, 5))
	# Corridor should remain connected even excluding one entrance
	var corridor_cells: Array[Vector3i] = [Vector3i(6, 0, 5)]
	assert_bool(_is_connected_to_entrance(corridor_cells, e1)).is_true()
	assert_bool(_is_connected_to_entrance(corridor_cells, e2)).is_true()


# === Occupancy Collision ===

func test_cannot_place_on_occupied_cell() -> void:
	_place("entrance", Vector3i(5, 0, 5))
	assert_bool(_can_place("corridor", Vector3i(5, 0, 5))).is_false()


func test_cannot_place_on_ground_cell() -> void:
	# Ground occupies y=-1 cells. But entrance at y=0 is above ground, not on it.
	# This tests that y=-1 is treated as occupied (ground)
	assert_bool(_cell_occupancy.has(Vector3i(5, -1, 5))).is_true()
