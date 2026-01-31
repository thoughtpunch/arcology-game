class_name BlockPlacer
extends Node3D

## Click-to-place system for 3D spike using raycasting
##
## Left-click: Place block at cursor position
## Right-click: Remove block at cursor position
## Ghost preview shows placement position with validity coloring

signal block_placed(position: Vector3i, block_type: String)
signal block_removed(position: Vector3i)

# Dependencies
const Block3DScript = preload("res://src/spike/block_3d.gd")

# Raycast collision mask (layer 2 = blocks, layer 1 = ground)
const RAY_LENGTH: float = 1000.0
const COLLISION_MASK: int = 0b11  # Layers 1 and 2

# Reference to camera (assigned by parent scene)
var camera: Camera3D

# Reference to block spawner (assigned by parent scene)
var spawner: Node3D  # BlockSpawner

# Currently selected block type
var selected_block_type: String = "corridor"

# Ghost preview block
var _ghost: CSGBox3D
var _ghost_material_valid: StandardMaterial3D
var _ghost_material_invalid: StandardMaterial3D

# Current ghost position (grid coordinates)
var _ghost_grid_pos: Vector3i = Vector3i.ZERO
var _ghost_visible: bool = false


func _ready() -> void:
	_create_ghost()


func _process(_delta: float) -> void:
	if not camera or not spawner:
		return

	_update_ghost_position()


func _unhandled_input(event: InputEvent) -> void:
	if not camera or not spawner:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_try_place_block()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_try_remove_block()


func _create_ghost() -> void:
	## Creates the ghost preview block
	_ghost = Block3DScript.new()
	_ghost.block_type = selected_block_type
	_ghost.use_collision = false  # Ghost doesn't collide
	_ghost.visible = false

	# Valid placement material (green, transparent)
	_ghost_material_valid = StandardMaterial3D.new()
	_ghost_material_valid.albedo_color = Color(0.2, 0.8, 0.2, 0.5)
	_ghost_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Invalid placement material (red, transparent)
	_ghost_material_invalid = StandardMaterial3D.new()
	_ghost_material_invalid.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	_ghost_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	add_child(_ghost)


func _update_ghost_position() -> void:
	## Updates ghost position based on mouse cursor raycast
	var result := _raycast_from_mouse()

	if result.is_empty():
		_ghost.visible = false
		_ghost_visible = false
		return

	# Calculate placement position based on hit
	var grid_pos := _calculate_placement_position(result)
	_ghost_grid_pos = grid_pos
	_ghost_visible = true
	_ghost.visible = true

	# Update ghost world position
	_ghost.grid_position = grid_pos

	# Update ghost color based on validity
	var is_valid := _is_valid_placement(grid_pos)
	_ghost.material = _ghost_material_valid if is_valid else _ghost_material_invalid


func _raycast_from_mouse() -> Dictionary:
	## Casts a ray from camera through mouse position
	## Returns raycast result dictionary or empty dict
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := from + dir * RAY_LENGTH

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, COLLISION_MASK)
	return space_state.intersect_ray(query)


func _calculate_placement_position(hit_result: Dictionary) -> Vector3i:
	## Converts raycast hit to grid position for placement
	var hit_pos: Vector3 = hit_result.position
	var hit_normal: Vector3 = hit_result.normal

	# Offset slightly in normal direction to place adjacent to hit surface
	# For ground plane (normal up), place at Y=0
	# For block faces, place adjacent in normal direction
	var offset_pos := hit_pos + hit_normal * 0.1  # Small offset into adjacent cell

	return Block3DScript.world_to_grid(offset_pos)


func _is_valid_placement(grid_pos: Vector3i) -> bool:
	## Returns true if a block can be placed at this position
	# Can't place below ground (for now)
	if grid_pos.y < 0:
		return false

	# Can't place where a block already exists
	if spawner.has_method("has_block_at") and spawner.has_block_at(grid_pos):
		return false

	return true


func _try_place_block() -> void:
	## Attempts to place a block at the current ghost position
	if not _ghost_visible:
		return

	if not _is_valid_placement(_ghost_grid_pos):
		return

	if spawner.has_method("place_block"):
		var block = spawner.place_block(_ghost_grid_pos, selected_block_type)
		if block:
			block_placed.emit(_ghost_grid_pos, selected_block_type)


func _try_remove_block() -> void:
	## Attempts to remove the block at the cursor position (not ghost position)
	var result := _raycast_from_mouse()
	if result.is_empty():
		return

	# For removal, we want the block we hit, not the adjacent space
	var collider = result.collider
	if collider and collider.has_method("grid_position"):
		# Direct hit on a block - remove it
		var grid_pos: Vector3i = collider.grid_position
		if spawner.has_method("remove_block"):
			if spawner.remove_block(grid_pos):
				block_removed.emit(grid_pos)
	else:
		# Hit ground or non-block - check if we're inside a block
		var hit_pos: Vector3 = result.position
		var grid_pos := Block3DScript.world_to_grid(hit_pos)
		if spawner.has_method("has_block_at") and spawner.has_block_at(grid_pos):
			if spawner.has_method("remove_block"):
				if spawner.remove_block(grid_pos):
					block_removed.emit(grid_pos)


func set_selected_block_type(block_type: String) -> void:
	## Sets the block type for placement
	selected_block_type = block_type
	if _ghost:
		_ghost.block_type = block_type


func get_ghost_position() -> Vector3i:
	## Returns the current ghost grid position
	return _ghost_grid_pos


func is_ghost_visible() -> bool:
	## Returns true if the ghost is currently visible
	return _ghost_visible


func is_placement_valid() -> bool:
	## Returns true if current placement position is valid
	return _ghost_visible and _is_valid_placement(_ghost_grid_pos)
