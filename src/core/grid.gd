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

# Sparse 3D storage: Vector3i -> Block
var _blocks: Dictionary = {}


## Store a block at the given grid position
func set_block(pos: Vector3i, block) -> void:
	_blocks[pos] = block
	block.grid_position = pos
	block_added.emit(pos, block)


## Get block at position, returns null if empty
func get_block(pos: Vector3i):
	return _blocks.get(pos)


## Remove block at position
func remove_block(pos: Vector3i) -> void:
	if _blocks.has(pos):
		_blocks.erase(pos)
		block_removed.emit(pos)


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
