## Panel auto-generation system for exterior block faces.
##
## Detects which faces of a placed block are "exterior" (adjacent cell is empty
## or outside the structure) and generates per-face quad meshes with distinct
## materials based on the block's panel_material type.
##
## Interior faces (shared between two blocks) are hidden to avoid overdraw and
## to visually communicate the structure's connectivity.

const FaceScript = preload("res://src/game/face.gd")
const PanelMatScript = preload("res://src/game/panel_material.gd")
const GridUtilsScript = preload("res://src/game/grid_utils.gd")

const CELL_SIZE: float = 6.0
const PANEL_INSET: float = 0.15  # Match BLOCK_INSET from sandbox_main
const PANEL_OFFSET: float = 0.01  # Slight offset from block surface to avoid z-fighting

## All 6 face directions with their grid offsets.
const FACE_DIRS: Array[int] = [
	FaceScript.Dir.TOP,
	FaceScript.Dir.BOTTOM,
	FaceScript.Dir.NORTH,
	FaceScript.Dir.SOUTH,
	FaceScript.Dir.EAST,
	FaceScript.Dir.WEST,
]


static func get_exterior_faces(cell: Vector3i, cell_occupancy: Dictionary) -> Array[int]:
	## Returns the list of face directions that are exterior (not touching another block).
	## A face is exterior if the adjacent cell in that direction is either:
	##   - not in cell_occupancy at all (empty air)
	##   - OR has occupancy value <= 0 but NOT -1 (ground is considered interior for bottom faces)
	## Ground cells (value -1) count as "occupied" for adjacency purposes.
	var exterior: Array[int] = []
	for face in FACE_DIRS:
		var normal: Vector3i = FaceScript.to_normal(face)
		var neighbor: Vector3i = cell + normal
		if not cell_occupancy.has(neighbor):
			exterior.append(face)
		# Ground (-1) is considered a neighbor that blocks the face
		# Other block IDs (>0) block the face
		# Only truly empty (no entry) counts as exterior
	return exterior


static func get_exterior_faces_for_block(
	occupied_cells: Array[Vector3i],
	cell_occupancy: Dictionary,
	block_id: int
) -> Dictionary:
	## Returns a Dictionary mapping Vector3i (cell) -> Array[int] (exterior face dirs)
	## for all cells of a block. Only faces adjacent to cells NOT belonging to the
	## same block (or empty) are considered exterior.
	var result: Dictionary = {}  # Vector3i -> Array[int]
	for cell in occupied_cells:
		var exterior: Array[int] = []
		for face in FACE_DIRS:
			var normal: Vector3i = FaceScript.to_normal(face)
			var neighbor: Vector3i = cell + normal
			if not cell_occupancy.has(neighbor):
				# Adjacent to air/void — exterior
				exterior.append(face)
			else:
				var neighbor_id: int = cell_occupancy[neighbor]
				if neighbor_id == block_id:
					# Same block — interior (multi-cell blocks)
					pass
				# else: different block or ground — face is hidden (shared wall)
		if exterior.size() > 0:
			result[cell] = exterior
	return result


static func create_face_quad(face_dir: int, cell_size: float, inset: float) -> Mesh:
	## Creates a single-face quad mesh for the given face direction.
	## The mesh is a PlaneMesh oriented to match the face normal.
	## Returns a mesh positioned at the origin — the caller offsets it.
	var quad := PlaneMesh.new()
	quad.size = Vector2(cell_size - inset * 2.0, cell_size - inset * 2.0)
	return quad


static func create_panel_meshes_for_block(
	block_node: Node3D,
	occupied_cells: Array[Vector3i],
	origin: Vector3i,
	cell_occupancy: Dictionary,
	block_id: int,
	panel_mat_type: int,
	block_color: Color
) -> Node3D:
	## Creates a Node3D containing panel mesh instances for all exterior faces
	## of the given block. Returns the panels container node (already added as
	## child of block_node).
	var panels_container := Node3D.new()
	panels_container.name = "Panels"

	var exterior_faces: Dictionary = get_exterior_faces_for_block(
		occupied_cells, cell_occupancy, block_id
	)

	for cell in exterior_faces:
		var faces: Array = exterior_faces[cell]
		for face_dir in faces:
			var mesh_inst := _create_panel_mesh_instance(
				cell, origin, face_dir, panel_mat_type, block_color
			)
			panels_container.add_child(mesh_inst)

	block_node.add_child(panels_container)
	return panels_container


static func _create_panel_mesh_instance(
	cell: Vector3i,
	block_origin: Vector3i,
	face_dir: int,
	panel_mat_type: int,
	block_color: Color
) -> MeshInstance3D:
	## Creates a single panel MeshInstance3D for one face of one cell.
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Panel_%s_%s" % [
		Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z),
		FaceScript.to_label(face_dir)
	]

	# Create the quad mesh
	mesh_inst.mesh = create_face_quad(face_dir, CELL_SIZE, PANEL_INSET)

	# Create material
	mesh_inst.material_override = PanelMatScript.create_material(panel_mat_type, block_color)

	# Position relative to block origin
	var local_cell := Vector3(cell - block_origin) * CELL_SIZE
	var cell_center := local_cell + Vector3.ONE * (CELL_SIZE / 2.0)

	# Use the face transform utility to orient the quad
	var face_normal := Vector3(FaceScript.to_normal(face_dir))
	var face_center := cell_center + face_normal * (CELL_SIZE / 2.0 - PANEL_INSET + PANEL_OFFSET)

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


static func update_panels_for_block(
	block_node: Node3D,
	occupied_cells: Array[Vector3i],
	origin: Vector3i,
	cell_occupancy: Dictionary,
	block_id: int,
	panel_mat_type: int,
	block_color: Color
) -> void:
	## Removes existing panels and regenerates them.
	## Called when a neighbor block is placed/removed, changing which faces are exterior.
	var existing_panels: Node3D = block_node.get_node_or_null("Panels")
	if existing_panels:
		existing_panels.queue_free()

	create_panel_meshes_for_block(
		block_node, occupied_cells, origin,
		cell_occupancy, block_id, panel_mat_type, block_color
	)


static func get_affected_block_ids(
	occupied_cells: Array[Vector3i],
	cell_occupancy: Dictionary,
	own_block_id: int
) -> Array[int]:
	## Returns the IDs of blocks that share a face with the given cells.
	## Used to determine which blocks need panel updates when a block is placed/removed.
	var affected: Dictionary = {}  # block_id -> true
	for cell in occupied_cells:
		for face in FACE_DIRS:
			var normal: Vector3i = FaceScript.to_normal(face)
			var neighbor: Vector3i = cell + normal
			if cell_occupancy.has(neighbor):
				var nid: int = cell_occupancy[neighbor]
				if nid > 0 and nid != own_block_id:
					affected[nid] = true
	var result: Array[int] = []
	for bid in affected:
		result.append(bid)
	return result
