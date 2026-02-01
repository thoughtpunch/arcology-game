## Underground wall auto-generation system.
##
## When a cell is excavated (removed from ground), this system generates rock/earth
## wall meshes on faces that are adjacent to non-excavated terrain. As more cells
## are excavated, walls are dynamically updated - removed where two excavated cells
## meet, added where excavated cells border solid ground.
##
## Wall materials vary by depth (strata):
##   Y = -1: Topsoil (brown)
##   Y = -2: Subsoil (tan/clay)
##   Y = -3+: Bedrock (gray rock)

const FaceScript = preload("res://src/game/face.gd")
const GridUtilsScript = preload("res://src/game/grid_utils.gd")

const CELL_SIZE: float = 6.0
const WALL_INSET: float = 0.02  # Slight inset to avoid z-fighting with blocks
const WALL_OFFSET: float = 0.005  # Offset from cell boundary

## Strata colors by depth layer
const STRATA_COLORS := {
	-1: Color(0.45, 0.32, 0.22),  # Topsoil - brown
	-2: Color(0.55, 0.45, 0.35),  # Subsoil - tan/clay
	-3: Color(0.40, 0.42, 0.45),  # Bedrock - gray
}

## Wall materials are cached per-depth for efficiency
var _wall_materials: Dictionary = {}  # int (y_level) -> StandardMaterial3D

## Container node for all wall meshes
var _wall_container: Node3D

## Tracks which walls exist: Vector3i (cell) -> Dictionary[int (face_dir) -> MeshInstance3D]
var _wall_meshes: Dictionary = {}

## Reference to the sandbox's cell_occupancy for checking neighbors
var _cell_occupancy: Dictionary

## Reference to the sandbox's ground depth config
var _ground_depth: int = 3


func _init() -> void:
	pass


func setup(wall_container: Node3D, cell_occupancy: Dictionary, ground_depth: int) -> void:
	## Initialize the system with references to sandbox state.
	_wall_container = wall_container
	_cell_occupancy = cell_occupancy
	_ground_depth = ground_depth


func get_strata_color(y_level: int) -> Color:
	## Returns the color for a given Y level (negative = underground).
	if y_level >= 0:
		return Color.TRANSPARENT  # Above ground, no walls
	if y_level >= -1:
		return STRATA_COLORS[-1]
	elif y_level >= -2:
		return STRATA_COLORS[-2]
	else:
		return STRATA_COLORS[-3]


func _get_wall_material(y_level: int) -> StandardMaterial3D:
	## Returns (or creates and caches) the wall material for a given depth.
	if _wall_materials.has(y_level):
		return _wall_materials[y_level]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = get_strata_color(y_level)
	mat.roughness = 0.9  # Rocky/earthy surface
	mat.metallic = 0.0
	# Add slight variation to simulate rock texture
	mat.detail_enabled = false  # Keep simple for performance

	_wall_materials[y_level] = mat
	return mat


func on_cell_excavated(cell: Vector3i) -> void:
	## Called when a ground cell is excavated (removed).
	## Generates walls on faces adjacent to non-excavated terrain and
	## updates neighboring excavated cells' walls.
	if cell.y >= 0:
		return  # Only underground cells get walls

	# Generate walls for this newly excavated cell
	_generate_walls_for_cell(cell)

	# Update walls for neighboring excavated cells (they may have shared a face)
	_update_neighbor_walls(cell)


func on_cell_filled(cell: Vector3i) -> void:
	## Called when a cell is filled back in (rare, but possible for undo/load).
	## Removes any walls for this cell and updates neighbors.
	if cell.y >= 0:
		return

	# Remove all walls for this cell
	_remove_walls_for_cell(cell)

	# Update neighbors (they now border solid ground again)
	_update_neighbor_walls(cell)


func _generate_walls_for_cell(cell: Vector3i) -> void:
	## Creates wall meshes on all faces of an excavated cell that border
	## non-excavated terrain.
	if _wall_container == null:
		return

	var cell_walls: Dictionary = {}  # face_dir -> MeshInstance3D

	for face_dir in [FaceScript.Dir.TOP, FaceScript.Dir.BOTTOM,
					 FaceScript.Dir.NORTH, FaceScript.Dir.SOUTH,
					 FaceScript.Dir.EAST, FaceScript.Dir.WEST]:
		var normal: Vector3i = FaceScript.to_normal(face_dir)
		var neighbor: Vector3i = cell + normal

		# Check if neighbor is non-excavated ground
		if _is_solid_ground(neighbor):
			var wall_mesh := _create_wall_mesh(cell, face_dir)
			_wall_container.add_child(wall_mesh)
			cell_walls[face_dir] = wall_mesh

	if cell_walls.size() > 0:
		_wall_meshes[cell] = cell_walls


func _remove_walls_for_cell(cell: Vector3i) -> void:
	## Removes all wall meshes for a cell.
	if not _wall_meshes.has(cell):
		return

	var cell_walls: Dictionary = _wall_meshes[cell]
	for face_dir in cell_walls:
		var mesh: MeshInstance3D = cell_walls[face_dir]
		if is_instance_valid(mesh):
			mesh.queue_free()

	_wall_meshes.erase(cell)


func _update_neighbor_walls(center_cell: Vector3i) -> void:
	## Updates walls for all 6 neighboring cells of center_cell.
	for face_dir in [FaceScript.Dir.TOP, FaceScript.Dir.BOTTOM,
					 FaceScript.Dir.NORTH, FaceScript.Dir.SOUTH,
					 FaceScript.Dir.EAST, FaceScript.Dir.WEST]:
		var normal: Vector3i = FaceScript.to_normal(face_dir)
		var neighbor: Vector3i = center_cell + normal

		# Only update excavated cells (cells with walls)
		if not _is_excavated(neighbor):
			continue

		# Check if the face between neighbor and center_cell needs a wall
		var opposite_face: int = _get_opposite_face(face_dir)

		if _is_solid_ground(center_cell):
			# center_cell is solid, neighbor needs a wall on this face
			_ensure_wall_exists(neighbor, opposite_face)
		else:
			# center_cell is excavated, remove wall between them
			_ensure_wall_removed(neighbor, opposite_face)


func _ensure_wall_exists(cell: Vector3i, face_dir: int) -> void:
	## Ensures a wall exists on the given face of the cell.
	if not _wall_meshes.has(cell):
		_wall_meshes[cell] = {}

	var cell_walls: Dictionary = _wall_meshes[cell]
	if cell_walls.has(face_dir):
		return  # Wall already exists

	var wall_mesh := _create_wall_mesh(cell, face_dir)
	_wall_container.add_child(wall_mesh)
	cell_walls[face_dir] = wall_mesh


func _ensure_wall_removed(cell: Vector3i, face_dir: int) -> void:
	## Ensures no wall exists on the given face of the cell.
	if not _wall_meshes.has(cell):
		return

	var cell_walls: Dictionary = _wall_meshes[cell]
	if not cell_walls.has(face_dir):
		return

	var mesh: MeshInstance3D = cell_walls[face_dir]
	if is_instance_valid(mesh):
		mesh.queue_free()
	cell_walls.erase(face_dir)

	# Clean up empty entries
	if cell_walls.is_empty():
		_wall_meshes.erase(cell)


func _create_wall_mesh(cell: Vector3i, face_dir: int) -> MeshInstance3D:
	## Creates a single wall mesh for one face of a cell.
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Wall_%d_%d_%d_%s" % [cell.x, cell.y, cell.z, FaceScript.to_label(face_dir)]

	# Create plane mesh
	var quad := PlaneMesh.new()
	quad.size = Vector2(CELL_SIZE - WALL_INSET * 2.0, CELL_SIZE - WALL_INSET * 2.0)
	mesh_inst.mesh = quad

	# Material based on depth
	mesh_inst.material_override = _get_wall_material(cell.y)

	# Position and orient the mesh
	var cell_world := GridUtilsScript.grid_to_world_center(cell)
	var face_normal := Vector3(FaceScript.to_normal(face_dir))
	var face_center := cell_world + face_normal * (CELL_SIZE / 2.0 - WALL_OFFSET)

	# Orient the PlaneMesh (default normal = +Y) to align with the face normal
	var basis: Basis
	match face_dir:
		FaceScript.Dir.TOP:
			basis = Basis.IDENTITY
		FaceScript.Dir.BOTTOM:
			basis = Basis(Vector3.RIGHT, PI)
		FaceScript.Dir.NORTH:
			basis = Basis(Vector3.RIGHT, -PI / 2.0)
		FaceScript.Dir.SOUTH:
			basis = Basis(Vector3.RIGHT, PI / 2.0)
		FaceScript.Dir.EAST:
			basis = Basis(Vector3.FORWARD, PI / 2.0)
		FaceScript.Dir.WEST:
			basis = Basis(Vector3.FORWARD, -PI / 2.0)
		_:
			basis = Basis.IDENTITY

	mesh_inst.transform = Transform3D(basis, face_center)
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	return mesh_inst


func _is_solid_ground(pos: Vector3i) -> bool:
	## Returns true if the position is solid (non-excavated) ground.
	## Solid ground is:
	##   - Y < 0 (underground)
	##   - Either has occupancy == -1 (ground) OR has no entry but is within ground_depth
	if pos.y >= 0:
		return false  # Above ground is never solid

	if pos.y < -_ground_depth:
		return false  # Below bedrock

	# Check cell_occupancy
	if _cell_occupancy.has(pos):
		return _cell_occupancy[pos] == -1  # -1 = ground, >0 = block

	# No entry means it could be:
	#   - Outside the initialized ground area (not solid)
	#   - Never touched (treat as solid within ground_depth)
	# For safety, treat no-entry cells within ground_depth as solid
	return true


func _is_excavated(pos: Vector3i) -> bool:
	## Returns true if the position is excavated (empty underground space).
	## A cell is excavated if it's underground (Y < 0) and has no entry in
	## cell_occupancy (was removed) or has a block (occupancy > 0, which
	## means something was built there after excavation).
	if pos.y >= 0:
		return true  # Above ground is always "excavated" (open air)

	if pos.y < -_ground_depth:
		return false  # Below bedrock is never excavated

	if not _cell_occupancy.has(pos):
		# No entry = was removed = excavated
		return true

	var occupancy: int = _cell_occupancy[pos]
	return occupancy != -1  # -1 = ground (not excavated), >0 = block (was excavated)


func _get_opposite_face(face_dir: int) -> int:
	## Returns the opposite face direction.
	match face_dir:
		FaceScript.Dir.TOP:
			return FaceScript.Dir.BOTTOM
		FaceScript.Dir.BOTTOM:
			return FaceScript.Dir.TOP
		FaceScript.Dir.NORTH:
			return FaceScript.Dir.SOUTH
		FaceScript.Dir.SOUTH:
			return FaceScript.Dir.NORTH
		FaceScript.Dir.EAST:
			return FaceScript.Dir.WEST
		FaceScript.Dir.WEST:
			return FaceScript.Dir.EAST
		_:
			return FaceScript.Dir.TOP


func get_wall_count() -> int:
	## Returns the total number of wall meshes (for debugging).
	var count := 0
	for cell in _wall_meshes:
		count += _wall_meshes[cell].size()
	return count


func clear_all_walls() -> void:
	## Removes all wall meshes (for scene cleanup).
	for cell in _wall_meshes:
		var cell_walls: Dictionary = _wall_meshes[cell]
		for face_dir in cell_walls:
			var mesh: MeshInstance3D = cell_walls[face_dir]
			if is_instance_valid(mesh):
				mesh.queue_free()
	_wall_meshes.clear()


func serialize() -> Dictionary:
	## Serializes the excavated cells for save/load.
	## Returns a dict with excavated cell positions.
	var excavated_cells: Array = []

	# Find all excavated cells by checking which cells have walls
	# (or check cell_occupancy for cells that were ground but are now missing)
	for cell in _wall_meshes:
		excavated_cells.append({"x": cell.x, "y": cell.y, "z": cell.z})

	return {"excavated_cells": excavated_cells}


func deserialize(data: Dictionary) -> void:
	## Restores excavated cells from save data.
	## Call this AFTER ground is set up but BEFORE blocks are placed.
	if not data.has("excavated_cells"):
		return

	var cells: Array = data["excavated_cells"]
	for cell_data in cells:
		var cell := Vector3i(cell_data["x"], cell_data["y"], cell_data["z"])
		# Mark as excavated in cell_occupancy (remove ground marker)
		if _cell_occupancy.has(cell) and _cell_occupancy[cell] == -1:
			_cell_occupancy.erase(cell)
		# Generate walls for this cell
		_generate_walls_for_cell(cell)
