## Static grid constants and coordinate conversion utilities.


const CELL_SIZE: float = 6.0


static func grid_to_world(grid_pos: Vector3i) -> Vector3:
	return Vector3(grid_pos) * CELL_SIZE


static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
	return Vector3(grid_pos) * CELL_SIZE + Vector3.ONE * (CELL_SIZE / 2.0)


static func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(world_pos.x / CELL_SIZE)),
		int(floor(world_pos.y / CELL_SIZE)),
		int(floor(world_pos.z / CELL_SIZE))
	)


static func get_occupied_cells(size: Vector3i, origin: Vector3i, rotation: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var effective_size := size
	if rotation == 90 or rotation == 270:
		effective_size = Vector3i(size.z, size.y, size.x)

	for x in range(effective_size.x):
		for y in range(effective_size.y):
			for z in range(effective_size.z):
				cells.append(origin + Vector3i(x, y, z))

	return cells
