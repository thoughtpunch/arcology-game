class_name BlockSpawner
extends Node3D

## Spawns test blocks for the spike scene
##
## Manages a grid of Block3D instances for placement testing.

signal block_placed(position: Vector3i, block_type: String)
signal block_removed(position: Vector3i)

# Reference to Block3D script
const Block3DScript = preload("res://src/spike/block_3d.gd")

# Container for spawned blocks
var _blocks: Dictionary = {}  # Key: Vector3i, Value: CSGBox3D (Block3D)


func _ready() -> void:
	# Spawn some test blocks to demonstrate the system
	spawn_test_blocks()


func spawn_test_blocks() -> void:
	## Creates a sample arrangement of blocks for testing
	# Ground floor - entrance and corridors
	place_block(Vector3i(0, 0, 0), "entrance")
	place_block(Vector3i(1, 0, 0), "corridor")
	place_block(Vector3i(2, 0, 0), "corridor")
	place_block(Vector3i(-1, 0, 0), "corridor")

	# Ground floor - residential
	place_block(Vector3i(1, 0, 1), "residential_basic")
	place_block(Vector3i(2, 0, 1), "residential_basic")
	place_block(Vector3i(-1, 0, 1), "commercial_basic")

	# Vertical - stairs
	place_block(Vector3i(0, 0, 1), "stairs")
	place_block(Vector3i(0, 1, 1), "stairs")

	# Second floor
	place_block(Vector3i(0, 1, 0), "corridor")
	place_block(Vector3i(1, 1, 0), "corridor")
	place_block(Vector3i(1, 1, 1), "residential_basic")


func place_block(grid_pos: Vector3i, block_type: String) -> CSGBox3D:
	## Places a block at the given grid position
	## Returns the created block, or null if position already occupied
	if _blocks.has(grid_pos):
		return null

	var block: CSGBox3D = Block3DScript.new()
	block.block_type = block_type
	block.grid_position = grid_pos
	block.name = "Block_%d_%d_%d" % [grid_pos.x, grid_pos.y, grid_pos.z]

	add_child(block)
	_blocks[grid_pos] = block
	block_placed.emit(grid_pos, block_type)

	return block


func remove_block(grid_pos: Vector3i) -> bool:
	## Removes the block at the given grid position
	## Returns true if a block was removed
	if not _blocks.has(grid_pos):
		return false

	var block: Node3D = _blocks[grid_pos]
	_blocks.erase(grid_pos)
	block.queue_free()
	block_removed.emit(grid_pos)

	return true


func get_block_at(grid_pos: Vector3i) -> CSGBox3D:
	## Returns the block at the given position, or null if empty
	return _blocks.get(grid_pos, null)


func has_block_at(grid_pos: Vector3i) -> bool:
	## Returns true if there's a block at the given position
	return _blocks.has(grid_pos)


func get_all_positions() -> Array:
	## Returns all occupied grid positions
	return _blocks.keys()


func get_block_count() -> int:
	## Returns the number of placed blocks
	return _blocks.size()


func clear_all_blocks() -> void:
	## Removes all blocks
	for pos in _blocks.keys():
		remove_block(pos)
