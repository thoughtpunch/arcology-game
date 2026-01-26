class_name Grid
extends Node
## 3D grid storage for all blocks in the arcology
## Uses sparse dictionary with Vector3i keys

# Isometric rendering constants
const TILE_WIDTH: int = 64    # Diamond width (hexagon horizontal extent)
const TILE_DEPTH: int = 32    # Diamond height (top face only)
const WALL_HEIGHT: int = 32   # Height of side faces
const FLOOR_HEIGHT: int = 32  # Visual offset per Z level

# Signals
signal block_added(pos: Vector3i, block)
signal block_removed(pos: Vector3i)
signal entrances_changed(entrance_positions: Array[Vector3i])

# Sparse 3D storage: Vector3i -> Block
var _blocks: Dictionary = {}

# Entrance positions (seed points for connectivity flood-fill)
var _entrance_positions: Array[Vector3i] = []


## Store a block at the given grid position
func set_block(pos: Vector3i, block) -> void:
	_blocks[pos] = block
	block.grid_position = pos
	block_added.emit(pos, block)
	_track_entrance(pos, block)
	# Recalculate connectivity after block is added
	call_deferred("calculate_connectivity")


## Get block at position, returns null if empty
func get_block(pos: Vector3i):
	return _blocks.get(pos)


## Remove block at position
func remove_block(pos: Vector3i) -> void:
	if _blocks.has(pos):
		var block = _blocks[pos]
		_blocks.erase(pos)
		block_removed.emit(pos)
		_untrack_entrance(pos, block)
		# Recalculate connectivity after block is removed
		call_deferred("calculate_connectivity")


## Check if position contains a block
func has_block(pos: Vector3i) -> bool:
	return _blocks.has(pos)


## Get all blocks as an array
func get_all_blocks() -> Array:
	return _blocks.values()


## Get all occupied positions as an array
func get_all_positions() -> Array:
	return _blocks.keys()


## Get total block count
func get_block_count() -> int:
	return _blocks.size()


## Clear all blocks from the grid
func clear() -> void:
	for pos in _blocks.keys():
		block_removed.emit(pos)
	_blocks.clear()
	if _entrance_positions.size() > 0:
		_entrance_positions.clear()
		entrances_changed.emit(_entrance_positions)


## Convert grid position to screen coordinates (isometric)
func grid_to_screen(grid_pos: Vector3i) -> Vector2:
	var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
	var y = (grid_pos.x + grid_pos.y) * (TILE_DEPTH / 2)
	y -= grid_pos.z * FLOOR_HEIGHT  # Higher Z = higher on screen
	return Vector2(x, y)


## Convert screen coordinates to grid position (requires known Z level)
func screen_to_grid(screen_pos: Vector2, z_level: int) -> Vector3i:
	# Adjust for current Z level
	var adjusted_y = screen_pos.y + z_level * FLOOR_HEIGHT

	var grid_x = (screen_pos.x / (TILE_WIDTH / 2.0) + adjusted_y / (TILE_DEPTH / 2.0)) / 2.0
	var grid_y = (adjusted_y / (TILE_DEPTH / 2.0) - screen_pos.x / (TILE_WIDTH / 2.0)) / 2.0

	return Vector3i(roundi(grid_x), roundi(grid_y), z_level)


## Get 6 cardinal neighbors of a position (±X, ±Y, ±Z)
func get_neighbors(pos: Vector3i) -> Array[Vector3i]:
	return [
		pos + Vector3i(1, 0, 0),   # +X
		pos + Vector3i(-1, 0, 0),  # -X
		pos + Vector3i(0, 1, 0),   # +Y
		pos + Vector3i(0, -1, 0),  # -Y
		pos + Vector3i(0, 0, 1),   # +Z (up)
		pos + Vector3i(0, 0, -1),  # -Z (down)
	]


## Get horizontal neighbors only (same Z level)
func get_horizontal_neighbors(pos: Vector3i) -> Array[Vector3i]:
	return [
		pos + Vector3i(1, 0, 0),   # +X
		pos + Vector3i(-1, 0, 0),  # -X
		pos + Vector3i(0, 1, 0),   # +Y
		pos + Vector3i(0, -1, 0),  # -Y
	]


## Calculate depth sort key for isometric rendering
## Higher value = drawn later (in front)
func get_sort_key(pos: Vector3i) -> int:
	return pos.x + pos.y - pos.z * 1000


## Manhattan distance between two grid positions
static func manhattan_distance(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)


## Get neighbors that contain blocks (not empty positions)
func get_occupied_neighbors(pos: Vector3i) -> Array[Vector3i]:
	var occupied: Array[Vector3i] = []
	for neighbor_pos in get_neighbors(pos):
		if has_block(neighbor_pos):
			occupied.append(neighbor_pos)
	return occupied


## Get neighbors that contain blocks on the same floor
func get_occupied_horizontal_neighbors(pos: Vector3i) -> Array[Vector3i]:
	var occupied: Array[Vector3i] = []
	for neighbor_pos in get_horizontal_neighbors(pos):
		if has_block(neighbor_pos):
			occupied.append(neighbor_pos)
	return occupied


## Check if two adjacent blocks can connect (for walkability/pathfinding)
## Requires BlockRegistry autoload
## Horizontal: connects if at least one block is public (traversable)
## Vertical: only connects if both blocks support vertical connections (stairs/elevator)
func can_connect(from_pos: Vector3i, to_pos: Vector3i) -> bool:
	var from_block = get_block(from_pos)
	var to_block = get_block(to_pos)

	# Both positions must have blocks
	if from_block == null or to_block == null:
		return false

	var direction := to_pos - from_pos

	# Must be orthogonally adjacent
	var dist: int = abs(direction.x) + abs(direction.y) + abs(direction.z)
	if dist != 1:
		return false

	# Get BlockRegistry for traversability checks
	var registry = _get_block_registry()
	if registry == null:
		# Without registry, assume public
		return true

	# Horizontal connection (same floor)
	if direction.z == 0:
		# At least one must be public (traversable)
		var from_public: bool = registry.is_public(from_block.block_type)
		var to_public: bool = registry.is_public(to_block.block_type)
		return from_public or to_public

	# Vertical connection (different floor)
	if abs(direction.z) == 1:
		# Both must support vertical connections
		var from_connects: bool = registry.connects_vertical(from_block.block_type)
		var to_connects: bool = registry.connects_vertical(to_block.block_type)
		return from_connects and to_connects

	return false


## Get walkable neighbors (blocks that can be reached from this position)
func get_walkable_neighbors(pos: Vector3i) -> Array[Vector3i]:
	var walkable: Array[Vector3i] = []
	for neighbor_pos in get_neighbors(pos):
		if can_connect(pos, neighbor_pos):
			walkable.append(neighbor_pos)
	return walkable


## Helper to get BlockRegistry autoload
## Can be set directly for testing or looked up from scene tree
var block_registry = null

func _get_block_registry():
	# Return direct reference if set
	if block_registry:
		return block_registry

	# Try to find via scene tree
	var tree := get_tree()
	if tree != null:
		var registry = tree.get_root().get_node_or_null("/root/BlockRegistry")
		if registry:
			block_registry = registry
			return registry

	# Not found
	return null


# --- Entrance Tracking ---

## Get all entrance positions (seed points for connectivity)
func get_entrance_positions() -> Array[Vector3i]:
	return _entrance_positions


## Check if there is at least one entrance
func has_entrance() -> bool:
	return _entrance_positions.size() > 0


## Track entrance when block is added
func _track_entrance(pos: Vector3i, block) -> void:
	# Handle both Block objects and dictionaries (for test compatibility)
	var block_type: String = ""
	if block is Object and "block_type" in block:
		block_type = block.block_type
	elif block is Dictionary and block.has("block_type"):
		block_type = block.block_type

	if block_type == "entrance":
		if pos not in _entrance_positions:
			_entrance_positions.append(pos)
			entrances_changed.emit(_entrance_positions)


## Untrack entrance when block is removed
func _untrack_entrance(pos: Vector3i, block) -> void:
	# Handle both Block objects and dictionaries (for test compatibility)
	var block_type: String = ""
	if block is Object and "block_type" in block:
		block_type = block.block_type
	elif block is Dictionary and block.has("block_type"):
		block_type = block.block_type

	if block_type == "entrance":
		var idx := _entrance_positions.find(pos)
		if idx >= 0:
			_entrance_positions.remove_at(idx)
			entrances_changed.emit(_entrance_positions)


# --- Connectivity Flood-Fill ---

signal connectivity_changed()

## Calculate connectivity from all entrance positions using BFS flood-fill
## Marks blocks as connected=true if reachable from any entrance
func calculate_connectivity() -> void:
	# Reset all blocks to disconnected
	for block in get_all_blocks():
		_set_block_connected(block, false)

	# If no entrances, nothing is connected
	if _entrance_positions.is_empty():
		connectivity_changed.emit()
		return

	# BFS flood-fill from all entrance positions
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []

	# Start from all entrances
	for entrance_pos in _entrance_positions:
		if has_block(entrance_pos):
			queue.append(entrance_pos)
			visited[entrance_pos] = true

	while not queue.is_empty():
		var current_pos: Vector3i = queue.pop_front()
		var current_block = get_block(current_pos)

		if current_block:
			_set_block_connected(current_block, true)

			# Only expand from this block if it's PUBLIC (can route through)
			# Private blocks are destinations only - they don't contribute neighbors
			if _is_block_public(current_block):
				# Add walkable neighbors to queue
				for neighbor_pos in get_walkable_neighbors(current_pos):
					if not visited.has(neighbor_pos):
						visited[neighbor_pos] = true
						queue.append(neighbor_pos)

	connectivity_changed.emit()


## Helper to set connected property on block (handles both Block objects and dictionaries)
func _set_block_connected(block, value: bool) -> void:
	if block is Object and "connected" in block:
		block.connected = value
	elif block is Dictionary:
		block["connected"] = value


## Helper to check if a block is public (traversable)
## Public blocks can route through; private blocks are destinations only
func _is_block_public(block) -> bool:
	var block_type: String = ""
	if block is Object and "block_type" in block:
		block_type = block.block_type
	elif block is Dictionary and block.has("block_type"):
		block_type = block.block_type
		# For dictionary blocks (tests), check explicit traversability field
		if block.has("traversability"):
			return block.traversability == "public"

	if block_type.is_empty():
		return false

	var registry = _get_block_registry()
	if registry == null:
		# Without registry and no explicit traversability, assume public
		# (allows basic unit tests to work without registry)
		return true

	return registry.is_public(block_type)


## Recalculate connectivity (call after block changes)
## Use this to manually trigger recalculation if auto-recalc is disabled
func recalculate_connectivity() -> void:
	calculate_connectivity()


## Get the highest Z level that has a block at the given X,Y column
## Returns -1 if no blocks exist at that column
func get_highest_z_at(x: int, y: int) -> int:
	var highest_z: int = -1
	for pos in _blocks.keys():
		if pos.x == x and pos.y == y:
			if pos.z > highest_z:
				highest_z = pos.z
	return highest_z
