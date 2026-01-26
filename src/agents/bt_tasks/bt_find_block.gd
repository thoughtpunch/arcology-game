@tool
class_name BTFindBlock
extends BTAction
## LimboAI action task: Find a block of given type and store destination
## Searches the grid for the nearest block matching criteria

## The block type to find (e.g., "grocery", "clinic", "food_hall")
@export var block_type: String = ""

## The category to find (e.g., "residential", "commercial", "civic")
## If set, finds any block in this category
@export var block_category: String = ""

## Blackboard variable to store the found block position
@export var output_var: StringName = &"target_block"

## Maximum search radius (in grid units)
@export var max_distance: int = 50


func _generate_name() -> String:
	if block_type != "":
		return "FindBlock: %s" % block_type
	elif block_category != "":
		return "FindBlock: category=%s" % block_category
	else:
		return "FindBlock: (not configured)"


func _tick(_delta: float) -> Status:
	var resident: Resident = _get_resident()
	if not resident:
		return FAILURE

	var grid: Node = _get_grid()
	if not grid:
		return FAILURE

	var found_pos: Vector3i = _find_nearest_block(grid, resident.current_position)

	if found_pos.x < 0:
		return FAILURE

	# Store result in blackboard
	var bb: Blackboard = get_blackboard()
	if bb:
		bb.set_var(output_var, found_pos)

	return SUCCESS


func _find_nearest_block(grid: Node, from_pos: Vector3i) -> Vector3i:
	## Search for the nearest matching block
	var all_blocks: Array = grid.get_all_blocks()
	var nearest_pos := Vector3i(-1, -1, -1)
	var nearest_dist: float = INF

	for block in all_blocks:
		# Check type match
		var matches := false
		if block_type != "" and block.block_type == block_type:
			matches = true
		elif block_category != "" and block.get_category() == block_category:
			matches = true

		if not matches:
			continue

		# Calculate distance
		var block_pos: Vector3i = block.grid_position
		var dist := _manhattan_distance(from_pos, block_pos)

		if dist <= max_distance and dist < nearest_dist:
			nearest_dist = dist
			nearest_pos = block_pos

	return nearest_pos


func _manhattan_distance(a: Vector3i, b: Vector3i) -> float:
	return absf(a.x - b.x) + absf(a.y - b.y) + absf(a.z - b.z)


func _get_resident() -> Resident:
	var agent = get_agent()
	if agent is Resident:
		return agent

	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var("resident"):
		return bb.get_var("resident")

	return null


func _get_grid() -> Node:
	## Get the Grid from the scene tree or blackboard
	var bb: Blackboard = get_blackboard()
	if bb and bb.has_var("grid"):
		return bb.get_var("grid")

	# Try to find in scene tree
	var tree := Engine.get_main_loop()
	if tree and tree.has_node("/root/Grid"):
		return tree.get_node("/root/Grid")

	return null
