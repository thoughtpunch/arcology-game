## Corridor Drag Builder — computes Manhattan-routed paths for drag-to-build.
##
## Given a start and end grid position (same Y level), computes an L-shaped
## path of cells using Manhattan routing (no diagonals). Prefers straight
## lines; when a turn is needed, routes X-first then Z (or vice versa,
## picking the shorter first leg to create a natural-looking path).
##
## Usage:
##   var path = CorridorDragBuilder.compute_path(start, end)
##   # Returns Array[Vector3i] of cells from start to end, inclusive.
##   # Returns empty array if start.y != end.y (horizontal only).

const GridUtilsScript = preload("res://src/phase0/grid_utils.gd")


static func compute_path(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
	## Compute a Manhattan-routed path from start to end on the same Y level.
	## Returns cells in order from start to end (inclusive).
	## Returns empty if Y levels differ.
	var path: Array[Vector3i] = []

	if start.y != end.y:
		return path

	if start == end:
		path.append(start)
		return path

	var dx: int = end.x - start.x
	var dz: int = end.z - start.z

	# Pure straight line (axis-aligned)
	if dx == 0 or dz == 0:
		return _straight_line(start, end)

	# L-shaped path: route along the longer axis first for natural feel
	if absi(dx) >= absi(dz):
		# X first, then Z
		var corner := Vector3i(end.x, start.y, start.z)
		path.append_array(_straight_line(start, corner))
		# Append Z leg without duplicating the corner
		var z_leg := _straight_line(corner, end)
		if z_leg.size() > 1:
			path.append_array(z_leg.slice(1))
	else:
		# Z first, then X
		var corner := Vector3i(start.x, start.y, end.z)
		path.append_array(_straight_line(start, corner))
		var x_leg := _straight_line(corner, end)
		if x_leg.size() > 1:
			path.append_array(x_leg.slice(1))

	return path


static func _straight_line(from: Vector3i, to: Vector3i) -> Array[Vector3i]:
	## Generate cells along a straight axis-aligned line (inclusive).
	var cells: Array[Vector3i] = []
	var dx: int = signi(to.x - from.x) if to.x != from.x else 0
	var dz: int = signi(to.z - from.z) if to.z != from.z else 0
	var current := from
	cells.append(current)
	while current != to:
		current = Vector3i(current.x + dx, current.y, current.z + dz)
		cells.append(current)
	return cells


static func is_drag_buildable(definition: Resource) -> bool:
	## Returns true if this block type supports drag-to-build.
	## Only 1x1x1 blocks with horizontal connectivity (corridors, stairs, etc.)
	## that aren't ground_only (entrance) qualify.
	if definition.ground_only:
		return false
	if definition.size != Vector3i(1, 1, 1):
		return false
	if not definition.connects_horizontal:
		return false
	return true


static func validate_path(
	path: Array[Vector3i],
	definition: Resource,
	cell_occupancy: Dictionary,
	has_entrance: bool,
	build_zone_origin: Vector2i,
	build_zone_size: Vector2i,
	ground_depth: int,
) -> Dictionary:
	## Validate each cell in a corridor drag path.
	## Returns { "valid": Array[Vector3i], "invalid": Array[Vector3i],
	##           "all_valid": bool, "cost": int }
	## Skips cells that are already occupied (auto-junction behavior).
	var valid: Array[Vector3i] = []
	var invalid: Array[Vector3i] = []
	var total_cost: int = 0

	if not has_entrance:
		return {"valid": valid, "invalid": path.duplicate(), "all_valid": false, "cost": 0}

	for cell in path:
		# Skip already-occupied cells (auto-junction: existing blocks stay)
		if cell_occupancy.has(cell):
			continue

		var cell_valid := true

		# Build zone check
		if cell.x < build_zone_origin.x or cell.x >= build_zone_origin.x + build_zone_size.x:
			cell_valid = false
		elif cell.z < build_zone_origin.y or cell.z >= build_zone_origin.y + build_zone_size.y:
			cell_valid = false

		# Below ground depth check
		if cell.y < -ground_depth:
			cell_valid = false

		# Support check: must be face-adjacent to a placed block (occupancy > 0)
		# or to a cell that's earlier in the path (which will be placed before)
		if cell_valid:
			var has_support := false
			var directions: Array[Vector3i] = [
				Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
				Vector3i(0, 1, 0), Vector3i(0, -1, 0),
				Vector3i(0, 0, 1), Vector3i(0, 0, -1),
			]
			for dir in directions:
				var neighbor: Vector3i = cell + dir
				# Existing placed block (not ground)
				if cell_occupancy.has(neighbor) and cell_occupancy[neighbor] > 0:
					has_support = true
					break
				# Earlier cell in our path that will be placed
				if valid.has(neighbor):
					has_support = true
					break
			if not has_support:
				cell_valid = false

		if cell_valid:
			valid.append(cell)
			total_cost += definition.cost
		else:
			invalid.append(cell)

	return {
		"valid": valid,
		"invalid": invalid,
		"all_valid": invalid.size() == 0,
		"cost": total_cost,
	}
