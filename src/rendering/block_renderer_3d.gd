class_name BlockRenderer3D
extends Node3D

## 3D block renderer for the arcology
##
## Manages MeshInstance3D nodes for each placed block.
## Connects to Grid signals for reactive rendering.
## Uses ShaderMaterial with global visibility mode support.
##
## Cell dimensions (THE CELL — true cube):
## - All axes: 6m
## - Contains 2 internal residential floors at 3m each
## - Or 1 double-height commercial/civic floor

signal block_added_visual(grid_pos: Vector3i, mesh: MeshInstance3D)
signal block_removed_visual(grid_pos: Vector3i)
signal state_changed(grid_pos: Vector3i, new_state: BlockState)

# Block visual states
enum BlockState {
	NORMAL, SELECTED, GHOST_VALID, GHOST_WARNING, GHOST_INVALID, CONSTRUCTING, DAMAGED, DISCONNECTED
}

# Cell dimensions in meters (Godot units) — true cube
const CELL_SIZE: float = 6.0  # All axes (X, Y, Z)
const CUBE_WIDTH: float = CELL_SIZE  # X axis (alias for compatibility)
const CUBE_DEPTH: float = CELL_SIZE  # Z axis (alias for compatibility)
const CUBE_HEIGHT: float = CELL_SIZE  # Y axis (alias for compatibility)

# Collision layers
const COLLISION_LAYER_BLOCKS: int = 2

# Chunk manager for geometry batching (optional)
const ChunkManagerClass := preload("res://src/rendering/chunk_manager.gd")

# Storage
var _block_meshes: Dictionary = {}  # Vector3i -> MeshInstance3D
var _block_states: Dictionary = {}  # Vector3i -> BlockState
var _grid: Node = null  # Grid reference

# Materials cache
var _base_materials: Dictionary = {}  # block_type -> ShaderMaterial
var _state_materials: Dictionary = {}  # BlockState -> StandardMaterial3D (legacy)

# Shader resource
var _block_shader: Shader = null

# Ghost preview
var _ghost_mesh: MeshInstance3D = null
var _ghost_grid_pos: Vector3i = Vector3i.ZERO
var _ghost_state: BlockState = BlockState.GHOST_VALID
var _chunk_manager: Node3D = null  # ChunkManager instance
var _chunking_enabled: bool = false


func _ready() -> void:
	_load_shader()
	_init_materials()


## Connect to a Grid node to receive block events
func connect_to_grid(grid: Node) -> void:
	if _grid:
		# Disconnect from previous grid
		if _grid.has_signal("block_added"):
			_grid.block_added.disconnect(_on_block_added)
		if _grid.has_signal("block_removed"):
			_grid.block_removed.disconnect(_on_block_removed)
		if _grid.has_signal("connectivity_changed"):
			_grid.connectivity_changed.disconnect(_on_connectivity_changed)

	_grid = grid

	if _grid:
		_grid.block_added.connect(_on_block_added)
		_grid.block_removed.connect(_on_block_removed)
		if _grid.has_signal("connectivity_changed"):
			_grid.connectivity_changed.connect(_on_connectivity_changed)


## Add a visual block at the given grid position
func add_block(grid_pos: Vector3i, block_type: String, rotation: int = 0) -> MeshInstance3D:
	# Remove existing mesh at position
	if _block_meshes.has(grid_pos):
		remove_block(grid_pos)

	# Create mesh instance
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Block_%d_%d_%d" % [grid_pos.x, grid_pos.y, grid_pos.z]

	# Create box mesh (THE CELL)
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
	mesh_instance.mesh = box_mesh

	# Set material
	var material := _get_material_for_type(block_type)
	mesh_instance.material_override = material

	# Position in world
	mesh_instance.position = grid_to_world_center(grid_pos)

	# Apply rotation (0 = north, 1 = east, 2 = south, 3 = west)
	mesh_instance.rotation_degrees.y = rotation * 90.0

	# Add collision for raycasting
	var static_body := StaticBody3D.new()
	static_body.collision_layer = COLLISION_LAYER_BLOCKS
	static_body.collision_mask = 0  # Don't collide, just raycast
	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)

	# Store metadata on the mesh
	mesh_instance.set_meta("grid_pos", grid_pos)
	mesh_instance.set_meta("block_type", block_type)

	add_child(mesh_instance)
	_block_meshes[grid_pos] = mesh_instance
	_block_states[grid_pos] = BlockState.NORMAL

	block_added_visual.emit(grid_pos, mesh_instance)
	return mesh_instance


## Remove the visual block at the given grid position
func remove_block(grid_pos: Vector3i) -> void:
	if not _block_meshes.has(grid_pos):
		return

	var mesh: MeshInstance3D = _block_meshes[grid_pos]
	_block_meshes.erase(grid_pos)
	_block_states.erase(grid_pos)

	mesh.queue_free()
	block_removed_visual.emit(grid_pos)


## Update the visual state of a block
func update_block_state(grid_pos: Vector3i, new_state: BlockState) -> void:
	if not _block_meshes.has(grid_pos):
		return

	_block_states[grid_pos] = new_state
	var mesh: MeshInstance3D = _block_meshes[grid_pos]
	_apply_state_to_mesh(mesh, new_state)
	state_changed.emit(grid_pos, new_state)


## Get the mesh at a grid position
func get_mesh_at(grid_pos: Vector3i) -> MeshInstance3D:
	return _block_meshes.get(grid_pos, null)


## Get the block state at a grid position
func get_block_state(grid_pos: Vector3i) -> BlockState:
	return _block_states.get(grid_pos, BlockState.NORMAL)


## Convert grid coordinates to world position (center of block)
static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
	return Vector3(
		grid_pos.x * CUBE_WIDTH,
		grid_pos.z * CUBE_HEIGHT + CUBE_HEIGHT / 2.0,  # z = floor level, Y-up
		grid_pos.y * CUBE_DEPTH  # grid y -> world z
	)


## Convert world position to grid coordinates
static func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		roundi(world_pos.x / CUBE_WIDTH),
		roundi(world_pos.z / CUBE_DEPTH),  # world z -> grid y
		roundi((world_pos.y - CUBE_HEIGHT / 2.0) / CUBE_HEIGHT)  # world y -> grid z (floor)
	)


## Show ghost preview at position
func show_ghost(
	grid_pos: Vector3i, block_type: String, state: BlockState = BlockState.GHOST_VALID
) -> void:
	if not _ghost_mesh:
		_ghost_mesh = MeshInstance3D.new()
		_ghost_mesh.name = "GhostPreview"
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
		_ghost_mesh.mesh = box_mesh
		add_child(_ghost_mesh)

	_ghost_grid_pos = grid_pos
	_ghost_state = state
	_ghost_mesh.position = grid_to_world_center(grid_pos)
	_ghost_mesh.visible = true

	# Apply ghost material based on state
	_apply_ghost_material(block_type, state)


## Hide ghost preview
func hide_ghost() -> void:
	if _ghost_mesh:
		_ghost_mesh.visible = false


## Update ghost position
func update_ghost_position(grid_pos: Vector3i) -> void:
	if _ghost_mesh:
		_ghost_grid_pos = grid_pos
		_ghost_mesh.position = grid_to_world_center(grid_pos)


## Update ghost state (valid/warning/invalid)
func update_ghost_state(state: BlockState, block_type: String = "") -> void:
	if _ghost_mesh:
		_ghost_state = state
		_apply_ghost_material(block_type, state)


## Clear all rendered blocks
func clear() -> void:
	for pos in _block_meshes.keys():
		remove_block(pos)
	_block_meshes.clear()
	_block_states.clear()

	# Clear chunk manager
	if _chunking_enabled and _chunk_manager:
		_chunk_manager.clear()


## Get count of rendered blocks
func get_block_count() -> int:
	return _block_meshes.size()


## Enable chunk-based geometry batching
func enable_chunking(camera: Camera3D = null) -> Node3D:
	if _chunk_manager:
		return _chunk_manager

	_chunk_manager = ChunkManagerClass.new()
	_chunk_manager.name = "ChunkManager"
	if camera:
		_chunk_manager.set_camera(camera)
	add_child(_chunk_manager)
	_chunking_enabled = true
	return _chunk_manager


## Disable chunking and revert to per-block rendering
func disable_chunking() -> void:
	if _chunk_manager:
		_chunk_manager.clear()
		_chunk_manager.queue_free()
		_chunk_manager = null
	_chunking_enabled = false


## Get the chunk manager (null if chunking not enabled)
func get_chunk_manager() -> Node3D:
	return _chunk_manager


## Check if chunking is enabled
func is_chunking_enabled() -> bool:
	return _chunking_enabled


# --- Grid Signal Handlers ---


func _on_block_added(grid_pos: Vector3i, block) -> void:
	var block_type: String = "corridor"
	if block is Object and "block_type" in block:
		block_type = block.block_type
	elif block is Dictionary:
		block_type = block.get("block_type", "corridor")

	# Add to chunk manager if chunking enabled
	if _chunking_enabled and _chunk_manager:
		var material := _get_material_for_type(block_type)
		_chunk_manager.add_block(grid_pos, block_type, 0, material)

	# Always add individual mesh (needed for selection, state changes, raycasting)
	add_block(grid_pos, block_type)

	# Check if block is connected
	if block is Object and "connected" in block:
		if not block.connected:
			update_block_state(grid_pos, BlockState.DISCONNECTED)


func _on_block_removed(grid_pos: Vector3i) -> void:
	# Remove from chunk manager if chunking enabled
	if _chunking_enabled and _chunk_manager:
		_chunk_manager.remove_block(grid_pos)

	remove_block(grid_pos)


func _on_connectivity_changed() -> void:
	# Update visual state based on connectivity
	if not _grid:
		return

	for grid_pos in _block_meshes.keys():
		var block = _grid.get_block_at(grid_pos)
		if block:
			var is_connected: bool = true
			if block is Object and "connected" in block:
				is_connected = block.connected
			elif block is Dictionary:
				is_connected = block.get("connected", true)

			if is_connected:
				if _block_states.get(grid_pos) == BlockState.DISCONNECTED:
					update_block_state(grid_pos, BlockState.NORMAL)
			else:
				update_block_state(grid_pos, BlockState.DISCONNECTED)


# --- Shader Management ---


func _load_shader() -> void:
	# Load the block material shader for cutaway support
	var shader_path := "res://shaders/block_material.gdshader"
	if ResourceLoader.exists(shader_path):
		_block_shader = load(shader_path)
	else:
		push_warning(
			"BlockRenderer3D: Shader not found at %s, using fallback materials" % shader_path
		)


# --- Material Management ---


func _init_materials() -> void:
	# Base materials for each block type (using ShaderMaterial if shader available)
	_create_base_material("residential_basic", Color(0.85, 0.75, 0.65))  # Warm beige
	_create_base_material("residential", Color(0.85, 0.75, 0.65))
	_create_base_material("commercial_basic", Color(0.6, 0.7, 0.85))  # Cool blue
	_create_base_material("commercial", Color(0.6, 0.7, 0.85))
	_create_base_material("corridor", Color(0.6, 0.6, 0.6))  # Gray
	_create_base_material("entrance", Color(0.5, 0.75, 0.5))  # Green
	_create_base_material("stairs", Color(0.65, 0.5, 0.35))  # Brown
	_create_base_material("elevator_shaft", Color(0.4, 0.4, 0.45), 0.3)  # Dark gray, metallic
	_create_base_material("default", Color(1.0, 0.0, 1.0))  # Magenta for unknown

	# State materials (overlays/modifiers) - still use StandardMaterial3D for simplicity
	_create_state_material(BlockState.SELECTED, Color(1.0, 1.0, 0.5, 1.0))  # Yellow tint
	_create_state_material(BlockState.GHOST_VALID, Color(0.5, 1.0, 0.5, 0.5))  # Green, transparent
	_create_state_material(BlockState.GHOST_WARNING, Color(1.0, 1.0, 0.5, 0.5))  # Yellow, transparent
	_create_state_material(BlockState.GHOST_INVALID, Color(1.0, 0.3, 0.3, 0.5))  # Red, transparent
	_create_state_material(BlockState.CONSTRUCTING, Color(0.7, 0.7, 0.9, 0.8))  # Blue-gray
	_create_state_material(BlockState.DAMAGED, Color(1.0, 0.6, 0.4, 1.0))  # Orange tint
	_create_state_material(BlockState.DISCONNECTED, Color(1.0, 0.4, 0.4, 1.0))  # Red tint


func _create_base_material(type: String, color: Color, metallic: float = 0.0) -> void:
	if _block_shader:
		# Use ShaderMaterial for cutaway support
		var mat := ShaderMaterial.new()
		mat.shader = _block_shader
		mat.set_shader_parameter("albedo_color", color)
		mat.set_shader_parameter("roughness", 0.7)
		mat.set_shader_parameter("metallic", metallic)
		mat.set_shader_parameter("alpha", 1.0)
		mat.set_shader_parameter("is_ghost", false)
		_base_materials[type] = mat
	else:
		# Fallback to StandardMaterial3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.7
		mat.metallic = metallic
		_base_materials[type] = mat


func _create_state_material(state: BlockState, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_state_materials[state] = mat


func _get_material_for_type(block_type: String) -> Material:
	if _base_materials.has(block_type):
		return _base_materials[block_type]
	return _base_materials.get("default", null)


func _apply_state_to_mesh(mesh: MeshInstance3D, state: BlockState) -> void:
	var block_type: String = mesh.get_meta("block_type", "default")
	var base_mat := _get_material_for_type(block_type)

	if base_mat is ShaderMaterial:
		# Using shader material - modify shader parameters
		match state:
			BlockState.NORMAL:
				mesh.material_override = base_mat
			BlockState.SELECTED:
				var mat: ShaderMaterial = base_mat.duplicate()
				mat.set_shader_parameter("emission_enabled", true)
				mat.set_shader_parameter("emission_color", Color(1.0, 1.0, 0.5))
				mat.set_shader_parameter("emission_energy", 0.3)
				mesh.material_override = mat
			BlockState.DISCONNECTED:
				var mat: ShaderMaterial = base_mat.duplicate()
				var base_color: Color = mat.get_shader_parameter("albedo_color")
				mat.set_shader_parameter("albedo_color", base_color.lerp(Color.RED, 0.4))
				mesh.material_override = mat
			BlockState.CONSTRUCTING:
				var mat: ShaderMaterial = base_mat.duplicate()
				var base_color: Color = mat.get_shader_parameter("albedo_color")
				mat.set_shader_parameter("albedo_color", base_color.lerp(Color(0.7, 0.7, 1.0), 0.5))
				mat.set_shader_parameter("alpha", 0.7)
				mesh.material_override = mat
			BlockState.DAMAGED:
				var mat: ShaderMaterial = base_mat.duplicate()
				var base_color: Color = mat.get_shader_parameter("albedo_color")
				mat.set_shader_parameter("albedo_color", base_color.lerp(Color.ORANGE, 0.4))
				mesh.material_override = mat
			_:
				mesh.material_override = base_mat
	else:
		# Fallback StandardMaterial3D
		match state:
			BlockState.NORMAL:
				mesh.material_override = base_mat
			BlockState.SELECTED:
				var mat: StandardMaterial3D = base_mat.duplicate()
				mat.emission_enabled = true
				mat.emission = Color(1.0, 1.0, 0.5)
				mat.emission_energy_multiplier = 0.3
				mesh.material_override = mat
			BlockState.DISCONNECTED:
				var mat: StandardMaterial3D = base_mat.duplicate()
				mat.albedo_color = mat.albedo_color.lerp(Color.RED, 0.4)
				mesh.material_override = mat
			BlockState.CONSTRUCTING:
				var mat: StandardMaterial3D = base_mat.duplicate()
				mat.albedo_color = mat.albedo_color.lerp(Color(0.7, 0.7, 1.0), 0.5)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = 0.7
				mesh.material_override = mat
			BlockState.DAMAGED:
				var mat: StandardMaterial3D = base_mat.duplicate()
				mat.albedo_color = mat.albedo_color.lerp(Color.ORANGE, 0.4)
				mesh.material_override = mat
			_:
				mesh.material_override = base_mat


func _apply_ghost_material(block_type: String, state: BlockState) -> void:
	if not _ghost_mesh:
		return

	var base_mat := _get_material_for_type(block_type if block_type != "" else "corridor")

	if base_mat is ShaderMaterial:
		# Using shader material
		var ghost_mat: ShaderMaterial = base_mat.duplicate()
		ghost_mat.set_shader_parameter("is_ghost", true)

		match state:
			BlockState.GHOST_VALID:
				ghost_mat.set_shader_parameter("alpha", 0.5)
				ghost_mat.set_shader_parameter("emission_enabled", true)
				ghost_mat.set_shader_parameter("emission_color", Color(0.3, 1.0, 0.3))
				ghost_mat.set_shader_parameter("emission_energy", 0.2)
			BlockState.GHOST_WARNING:
				ghost_mat.set_shader_parameter("albedo_color", Color(1.0, 1.0, 0.3))
				ghost_mat.set_shader_parameter("alpha", 0.5)
				ghost_mat.set_shader_parameter("emission_enabled", true)
				ghost_mat.set_shader_parameter("emission_color", Color(1.0, 1.0, 0.0))
				ghost_mat.set_shader_parameter("emission_energy", 0.3)
			BlockState.GHOST_INVALID:
				ghost_mat.set_shader_parameter("albedo_color", Color(1.0, 0.3, 0.3))
				ghost_mat.set_shader_parameter("alpha", 0.5)
				ghost_mat.set_shader_parameter("emission_enabled", true)
				ghost_mat.set_shader_parameter("emission_color", Color(1.0, 0.0, 0.0))
				ghost_mat.set_shader_parameter("emission_energy", 0.3)
			_:
				ghost_mat.set_shader_parameter("alpha", 0.5)

		_ghost_mesh.material_override = ghost_mat
	else:
		# Fallback StandardMaterial3D
		var ghost_mat: StandardMaterial3D = base_mat.duplicate()
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		match state:
			BlockState.GHOST_VALID:
				ghost_mat.albedo_color.a = 0.5
				ghost_mat.emission_enabled = true
				ghost_mat.emission = Color(0.3, 1.0, 0.3)
				ghost_mat.emission_energy_multiplier = 0.2
			BlockState.GHOST_WARNING:
				ghost_mat.albedo_color = Color(1.0, 1.0, 0.3, 0.5)
				ghost_mat.emission_enabled = true
				ghost_mat.emission = Color(1.0, 1.0, 0.0)
				ghost_mat.emission_energy_multiplier = 0.3
			BlockState.GHOST_INVALID:
				ghost_mat.albedo_color = Color(1.0, 0.3, 0.3, 0.5)
				ghost_mat.emission_enabled = true
				ghost_mat.emission = Color(1.0, 0.0, 0.0)
				ghost_mat.emission_energy_multiplier = 0.3
			_:
				ghost_mat.albedo_color.a = 0.5

		_ghost_mesh.material_override = ghost_mat
