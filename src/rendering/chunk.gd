class_name Chunk
extends Node3D

## A spatial chunk of 8x8x8 cells (48m x 48m x 48m) containing merged block geometry.
##
## Chunks batch nearby blocks into fewer draw calls by merging
## their meshes into per-layer MeshInstance3D nodes.
## Each chunk manages its own AABB for frustum culling.
##
## Layers:
## - Opaque exterior: Main solid geometry
## - Transparent: Glass panels (future)
## - Dynamic: Unmerged blocks (doors, elevators - future)
##
## LOD Levels (from 3D refactor spec Section 3.4):
##   LOD0 (0-50m):    Full detail, interior visible
##   LOD1 (50-150m):  Simplified exterior, no interior
##   LOD2 (150-400m): Block silhouette only
##   LOD3 (400m+):    Merged chunks, impostors

signal lod_changed(old_level: LODLevel, new_level: LODLevel)

# LOD level enumeration (matches LODManager.LODLevel)
enum LODLevel {
	LOD0 = 0,  # Full detail (0-50m)
	LOD1 = 1,  # Simplified exterior (50-150m)
	LOD2 = 2,  # Silhouette only (150-400m)
	LOD3 = 3,  # Merged/impostor (400m+)
}

# Chunk size in grid cells per axis
const CHUNK_SIZE: int = 8

# Cell dimensions (must match BlockRenderer3D) — true cube, 6m all axes
const CELL_SIZE: float = 6.0
const CUBE_WIDTH: float = CELL_SIZE  # Alias for compatibility
const CUBE_DEPTH: float = CELL_SIZE  # Alias for compatibility
const CUBE_HEIGHT: float = CELL_SIZE  # Alias for compatibility

# LOD mesh reduction factors (triangle reduction per LOD)
const LOD_FACE_REDUCTION: Dictionary = {
	LODLevel.LOD0: 1.0,  # Full detail: all 6 faces
	LODLevel.LOD1: 1.0,  # Simplified: all faces but simpler material
	LODLevel.LOD2: 0.5,  # Silhouette: only visible faces (roughly half)
	LODLevel.LOD3: 0.25,  # Impostor: single quad or merged bounding box
}

# Collision layer for blocks
const COLLISION_LAYER_BLOCKS: int = 2

# Chunk coordinate (grid-space, not world-space)
var chunk_coord: Vector3i = Vector3i.ZERO

# Block data stored in this chunk
# Key: Vector3i (grid position), Value: Dictionary with "type", "rotation", "material"
var _blocks: Dictionary = {}

# Mesh instances for each layer
var _opaque_mesh: MeshInstance3D = null
var _transparent_mesh: MeshInstance3D = null

# LOD mesh instances (for different detail levels)
var _lod_meshes: Array[MeshInstance3D] = []

# Collision body for raycasting all blocks in chunk
var _static_body: StaticBody3D = null

# State tracking
var _dirty: bool = true
var _block_count: int = 0

# Current LOD level
var _current_lod: LODLevel = LODLevel.LOD0

# AABB for frustum culling (world space)
var _aabb: AABB = AABB()

# Shader reference (passed from manager)
var _block_shader: Shader = null

# Material cache (passed from manager)
var _material_cache: Dictionary = {}


func _init(coord: Vector3i = Vector3i.ZERO) -> void:
	chunk_coord = coord


func _ready() -> void:
	name = "Chunk_%d_%d_%d" % [chunk_coord.x, chunk_coord.y, chunk_coord.z]

	# Set chunk world position
	position = _chunk_to_world_origin()

	# Create layer nodes
	_opaque_mesh = MeshInstance3D.new()
	_opaque_mesh.name = "OpaqueMesh"
	add_child(_opaque_mesh)

	_transparent_mesh = MeshInstance3D.new()
	_transparent_mesh.name = "TransparentMesh"
	add_child(_transparent_mesh)

	# Create static body for raycasting
	_static_body = StaticBody3D.new()
	_static_body.name = "ChunkCollision"
	_static_body.collision_layer = COLLISION_LAYER_BLOCKS
	_static_body.collision_mask = 0
	add_child(_static_body)


## Convert chunk coordinate to world origin position
func _chunk_to_world_origin() -> Vector3:
	return Vector3(
		chunk_coord.x * CHUNK_SIZE * CUBE_WIDTH,
		chunk_coord.z * CHUNK_SIZE * CUBE_HEIGHT,
		chunk_coord.y * CHUNK_SIZE * CUBE_DEPTH
	)


## Convert grid position to local position within chunk
func _grid_to_local(grid_pos: Vector3i) -> Vector3:
	var local_grid := grid_pos - _chunk_grid_origin()
	return Vector3(
		local_grid.x * CUBE_WIDTH,
		local_grid.z * CUBE_HEIGHT + CUBE_HEIGHT / 2.0,
		local_grid.y * CUBE_DEPTH
	)


## Get the grid origin of this chunk (minimum grid coordinate)
func _chunk_grid_origin() -> Vector3i:
	return Vector3i(
		chunk_coord.x * CHUNK_SIZE, chunk_coord.y * CHUNK_SIZE, chunk_coord.z * CHUNK_SIZE
	)


## Add a block to this chunk
func add_block(
	grid_pos: Vector3i, block_type: String, rotation: int = 0, material: Material = null
) -> void:
	_blocks[grid_pos] = {"type": block_type, "rotation": rotation, "material": material}
	_block_count = _blocks.size()
	_dirty = true


## Remove a block from this chunk
func remove_block(grid_pos: Vector3i) -> bool:
	if not _blocks.has(grid_pos):
		return false

	_blocks.erase(grid_pos)
	_block_count = _blocks.size()
	_dirty = true
	return true


## Check if this chunk contains a specific grid position
func has_block(grid_pos: Vector3i) -> bool:
	return _blocks.has(grid_pos)


## Get block data at a grid position
func get_block_data(grid_pos: Vector3i) -> Dictionary:
	return _blocks.get(grid_pos, {})


## Get all block positions in this chunk
func get_block_positions() -> Array:
	return _blocks.keys()


## Get the number of blocks in this chunk
func get_block_count() -> int:
	return _block_count


## Check if this chunk has no blocks
func is_empty() -> bool:
	return _block_count == 0


## Check if this chunk needs rebuilding
func is_dirty() -> bool:
	return _dirty


## Mark this chunk as needing rebuild
func mark_dirty() -> void:
	_dirty = true


## Rebuild the merged mesh for this chunk.
## Creates individual BoxMesh per block merged into an ArrayMesh.
func rebuild() -> void:
	_dirty = false

	if is_empty():
		_clear_meshes()
		return

	# Build merged mesh from all blocks
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var collision_shapes: Array[BoxShape3D] = []
	var collision_transforms: Array[Transform3D] = []

	for grid_pos in _blocks:
		var block_data: Dictionary = _blocks[grid_pos]
		var local_pos := _grid_to_local(grid_pos)
		var block_type: String = block_data.get("type", "corridor")
		var rotation: int = block_data.get("rotation", 0)

		# Set material color as vertex color for merged mesh
		var color := _get_color_for_type(block_type)

		# Create box vertices for this block
		_add_box_to_surface(
			surface_tool, local_pos, Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH), color, rotation
		)

		# Track collision shapes
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
		collision_shapes.append(box_shape)
		collision_transforms.append(Transform3D(Basis(), local_pos))

	# Generate the merged mesh
	surface_tool.generate_normals()
	var array_mesh := surface_tool.commit()

	# Apply material (guard for when _ready hasn't been called)
	if _opaque_mesh:
		if array_mesh and array_mesh.get_surface_count() > 0:
			var mat := _create_chunk_material()
			if mat:
				_opaque_mesh.material_override = mat
		_opaque_mesh.mesh = array_mesh

	# Rebuild collision shapes
	_rebuild_collision(collision_shapes, collision_transforms)

	# Update AABB
	_update_aabb()


## Clear all mesh data
func _clear_meshes() -> void:
	if _opaque_mesh:
		_opaque_mesh.mesh = null
	if _transparent_mesh:
		_transparent_mesh.mesh = null

	# Clear collision shapes
	if _static_body:
		for child in _static_body.get_children():
			child.queue_free()

	_aabb = AABB()


## Add a box's triangles to the SurfaceTool
func _add_box_to_surface(
	st: SurfaceTool, center: Vector3, size: Vector3, color: Color, rotation: int = 0
) -> void:
	var half := size / 2.0
	st.set_color(color)

	# Apply rotation around Y axis
	var rot_basis := Basis()
	if rotation != 0:
		rot_basis = Basis(Vector3.UP, deg_to_rad(rotation * 90.0))

	# Define the 8 corners of the box (before rotation)
	var corners := [
		Vector3(-half.x, -half.y, -half.z),  # 0: left-bottom-back
		Vector3(half.x, -half.y, -half.z),  # 1: right-bottom-back
		Vector3(half.x, half.y, -half.z),  # 2: right-top-back
		Vector3(-half.x, half.y, -half.z),  # 3: left-top-back
		Vector3(-half.x, -half.y, half.z),  # 4: left-bottom-front
		Vector3(half.x, -half.y, half.z),  # 5: right-bottom-front
		Vector3(half.x, half.y, half.z),  # 6: right-top-front
		Vector3(-half.x, half.y, half.z),  # 7: left-top-front
	]

	# Apply rotation and offset
	for i in range(corners.size()):
		corners[i] = rot_basis * corners[i] + center

	# Define 6 faces as quads (2 triangles each), with normals
	var faces := [
		# Front face (+Z)
		{"verts": [4, 5, 6, 7], "normal": rot_basis * Vector3.BACK},
		# Back face (-Z)
		{"verts": [1, 0, 3, 2], "normal": rot_basis * Vector3.FORWARD},
		# Right face (+X)
		{"verts": [5, 1, 2, 6], "normal": rot_basis * Vector3.RIGHT},
		# Left face (-X)
		{"verts": [0, 4, 7, 3], "normal": rot_basis * Vector3.LEFT},
		# Top face (+Y)
		{"verts": [7, 6, 2, 3], "normal": Vector3.UP},
		# Bottom face (-Y)
		{"verts": [0, 1, 5, 4], "normal": Vector3.DOWN},
	]

	for face in faces:
		var v: Array = face.verts
		var n: Vector3 = face.normal

		st.set_normal(n)

		# Triangle 1: v[0], v[1], v[2]
		st.add_vertex(corners[v[0]])
		st.add_vertex(corners[v[1]])
		st.add_vertex(corners[v[2]])

		# Triangle 2: v[0], v[2], v[3]
		st.add_vertex(corners[v[0]])
		st.add_vertex(corners[v[2]])
		st.add_vertex(corners[v[3]])


## Create material for the merged chunk mesh
func _create_chunk_material() -> Material:
	if _block_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _block_shader
		mat.set_shader_parameter("albedo_color", Color.WHITE)  # Use vertex colors
		mat.set_shader_parameter("roughness", 0.7)
		mat.set_shader_parameter("metallic", 0.0)
		mat.set_shader_parameter("alpha", 1.0)
		mat.set_shader_parameter("is_ghost", false)
		return mat

	# Fallback to StandardMaterial3D with vertex colors
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.7
	return mat


## Rebuild collision shapes for all blocks
func _rebuild_collision(shapes: Array[BoxShape3D], transforms: Array[Transform3D]) -> void:
	if not _static_body:
		return

	# Clear existing shapes
	for child in _static_body.get_children():
		child.queue_free()

	# Add new shapes
	for i in range(shapes.size()):
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = shapes[i]
		collision_shape.transform = transforms[i]
		# Store grid position metadata on collision shape
		_static_body.add_child(collision_shape)


## Update the world-space AABB for frustum culling
func _update_aabb() -> void:
	if is_empty():
		_aabb = AABB()
		return

	var origin := _chunk_to_world_origin()
	var chunk_world_size := Vector3(
		CHUNK_SIZE * CUBE_WIDTH, CHUNK_SIZE * CUBE_HEIGHT, CHUNK_SIZE * CUBE_DEPTH
	)

	_aabb = AABB(origin, chunk_world_size)


## Get the world-space AABB
func get_aabb() -> AABB:
	return _aabb


## Get color for a block type (matches BlockRenderer3D colors)
func _get_color_for_type(block_type: String) -> Color:
	match block_type:
		"residential_basic", "residential":
			return Color(0.85, 0.75, 0.65)
		"commercial_basic", "commercial":
			return Color(0.6, 0.7, 0.85)
		"corridor":
			return Color(0.6, 0.6, 0.6)
		"entrance":
			return Color(0.5, 0.75, 0.5)
		"stairs":
			return Color(0.65, 0.5, 0.35)
		"elevator_shaft":
			return Color(0.4, 0.4, 0.45)
		_:
			return Color(1.0, 0.0, 1.0)  # Magenta for unknown


## Set the shader to use for chunk materials
func set_shader(shader: Shader) -> void:
	_block_shader = shader
	if not is_empty():
		mark_dirty()


## Set material cache reference
func set_material_cache(cache: Dictionary) -> void:
	_material_cache = cache


# --- LOD Methods ---


## Set the LOD level for this chunk
func set_lod(lod: LODLevel) -> void:
	if lod == _current_lod:
		return

	var old_lod := _current_lod
	_current_lod = lod

	_apply_lod_level()
	lod_changed.emit(old_lod, lod)


## Get the current LOD level
func get_lod() -> LODLevel:
	return _current_lod


## Apply visual changes based on current LOD level
func _apply_lod_level() -> void:
	if not _opaque_mesh:
		return

	match _current_lod:
		LODLevel.LOD0:
			# Full detail: show opaque mesh with full material
			_opaque_mesh.visible = true
			_set_lod0_material()
		LODLevel.LOD1:
			# Simplified exterior: show opaque mesh with simplified material
			_opaque_mesh.visible = true
			_set_lod1_material()
		LODLevel.LOD2:
			# Silhouette only: show opaque mesh with flat shading
			_opaque_mesh.visible = true
			_set_lod2_material()
		LODLevel.LOD3:
			# Impostor: hide detailed mesh, show simplified representation
			_opaque_mesh.visible = true
			_set_lod3_material()


## Set material for LOD0 (full detail)
func _set_lod0_material() -> void:
	if not _opaque_mesh:
		return

	var mat := _create_chunk_material()
	if mat:
		_opaque_mesh.material_override = mat


## Set material for LOD1 (simplified exterior)
func _set_lod1_material() -> void:
	if not _opaque_mesh:
		return

	# LOD1: Same geometry but simpler material (no specular, reduced roughness detail)
	if _block_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _block_shader
		mat.set_shader_parameter("albedo_color", Color.WHITE)
		mat.set_shader_parameter("roughness", 0.9)  # More matte
		mat.set_shader_parameter("metallic", 0.0)
		mat.set_shader_parameter("alpha", 1.0)
		mat.set_shader_parameter("is_ghost", false)
		_opaque_mesh.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.9
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		_opaque_mesh.material_override = mat


## Set material for LOD2 (silhouette)
func _set_lod2_material() -> void:
	if not _opaque_mesh:
		return

	# LOD2: Flat shading, single color based on average chunk color
	var avg_color := _get_average_block_color()

	if _block_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _block_shader
		mat.set_shader_parameter("albedo_color", avg_color)
		mat.set_shader_parameter("roughness", 1.0)  # Fully matte
		mat.set_shader_parameter("metallic", 0.0)
		mat.set_shader_parameter("alpha", 1.0)
		mat.set_shader_parameter("is_ghost", false)
		_opaque_mesh.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = avg_color
		mat.roughness = 1.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_opaque_mesh.material_override = mat


## Set material for LOD3 (impostor)
func _set_lod3_material() -> void:
	if not _opaque_mesh:
		return

	# LOD3: Simple flat color, possibly tinted to indicate distance
	var avg_color := _get_average_block_color()
	# Slightly desaturate and darken for distant objects (atmospheric perspective)
	avg_color = avg_color.lerp(Color(0.7, 0.75, 0.8), 0.3)

	if _block_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _block_shader
		mat.set_shader_parameter("albedo_color", avg_color)
		mat.set_shader_parameter("roughness", 1.0)
		mat.set_shader_parameter("metallic", 0.0)
		mat.set_shader_parameter("alpha", 1.0)
		mat.set_shader_parameter("is_ghost", false)
		_opaque_mesh.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = avg_color
		mat.roughness = 1.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_opaque_mesh.material_override = mat


## Calculate average color of all blocks in chunk
func _get_average_block_color() -> Color:
	if _blocks.is_empty():
		return Color(0.6, 0.6, 0.6)  # Default gray

	var total_color := Color(0, 0, 0)
	var count := 0

	for block_data in _blocks.values():
		var block_type: String = block_data.get("type", "corridor")
		total_color += _get_color_for_type(block_type)
		count += 1

	if count > 0:
		return Color(total_color.r / count, total_color.g / count, total_color.b / count)

	return Color(0.6, 0.6, 0.6)


## Get the LOD reduction factor for current level
func get_lod_reduction_factor() -> float:
	return LOD_FACE_REDUCTION.get(_current_lod, 1.0)
