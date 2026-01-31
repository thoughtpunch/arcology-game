class_name GhostPreview3D
extends Node3D

## 3D ghost preview for block placement
##
## Shows semi-transparent preview of block being placed.
## Features:
## - Follows cursor position (snaps to grid)
## - Green/yellow/red state coloring
## - R key to rotate 90°
## - Floor level indicator (Label3D)
## - Excluded from raycasts (collision layer 4)

signal rotation_changed(rotation_index: int)
signal state_changed(new_state: GhostState)

# Visual states
enum GhostState { HIDDEN, VALID, WARNING, INVALID }

# Cell dimensions (same as BlockRenderer3D) — true cube, 6m all axes
const CELL_SIZE: float = 6.0
const CUBE_WIDTH: float = CELL_SIZE  # Alias for compatibility
const CUBE_DEPTH: float = CELL_SIZE  # Alias for compatibility
const CUBE_HEIGHT: float = CELL_SIZE  # Alias for compatibility

# Collision layer for ghost (excluded from normal raycasts)
const COLLISION_LAYER_GHOST: int = 8  # Layer 4 (bit 3)

# Current state
var _state: GhostState = GhostState.HIDDEN
var _grid_pos: Vector3i = Vector3i.ZERO
var _block_type: String = "corridor"
var _rotation_index: int = 0  # 0=north, 1=east, 2=south, 3=west

# Node references
var _mesh_instance: MeshInstance3D
var _floor_label: Label3D
var _static_body: StaticBody3D

# Materials for each state
var _material_valid: StandardMaterial3D
var _material_warning: StandardMaterial3D
var _material_invalid: StandardMaterial3D
var _current_base_material: StandardMaterial3D


func _ready() -> void:
	_create_mesh()
	_create_floor_label()
	_create_materials()
	_create_collision_exclusion()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			rotate_ghost()


func _create_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "GhostMesh"

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
	_mesh_instance.mesh = box_mesh

	# Disable shadows for ghost
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(_mesh_instance)


func _create_floor_label() -> void:
	_floor_label = Label3D.new()
	_floor_label.name = "FloorLabel"
	_floor_label.text = "Floor 0"
	_floor_label.font_size = 24
	_floor_label.modulate = Color.WHITE
	_floor_label.outline_modulate = Color.BLACK
	_floor_label.outline_size = 4
	_floor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_floor_label.no_depth_test = true  # Always visible

	# Position above the ghost
	_floor_label.position = Vector3(0, CUBE_HEIGHT + 1.0, 0)

	add_child(_floor_label)


func _create_materials() -> void:
	# Valid state - green, transparent
	_material_valid = StandardMaterial3D.new()
	_material_valid.albedo_color = Color(0.3, 0.9, 0.3, 0.5)
	_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_valid.emission_enabled = true
	_material_valid.emission = Color(0.0, 0.5, 0.0)
	_material_valid.emission_energy_multiplier = 0.3
	_material_valid.cull_mode = BaseMaterial3D.CULL_DISABLED  # See from inside

	# Warning state - yellow, transparent
	_material_warning = StandardMaterial3D.new()
	_material_warning.albedo_color = Color(0.9, 0.9, 0.3, 0.5)
	_material_warning.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_warning.emission_enabled = true
	_material_warning.emission = Color(0.5, 0.5, 0.0)
	_material_warning.emission_energy_multiplier = 0.3
	_material_warning.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Invalid state - red, transparent
	_material_invalid = StandardMaterial3D.new()
	_material_invalid.albedo_color = Color(0.9, 0.3, 0.3, 0.5)
	_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_invalid.emission_enabled = true
	_material_invalid.emission = Color(0.5, 0.0, 0.0)
	_material_invalid.emission_energy_multiplier = 0.3
	_material_invalid.cull_mode = BaseMaterial3D.CULL_DISABLED


func _create_collision_exclusion() -> void:
	## Create a static body on layer 4 (ghost) so raycasts can exclude it
	_static_body = StaticBody3D.new()
	_static_body.name = "GhostCollision"
	_static_body.collision_layer = COLLISION_LAYER_GHOST
	_static_body.collision_mask = 0  # Don't collide with anything

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(CUBE_WIDTH, CUBE_HEIGHT, CUBE_DEPTH)
	collision_shape.shape = box_shape

	_static_body.add_child(collision_shape)
	add_child(_static_body)


# --- Public API ---


func set_state(new_state: GhostState) -> void:
	## Set the ghost visual state
	if _state == new_state:
		return

	_state = new_state
	_apply_state()
	state_changed.emit(new_state)


func get_state() -> GhostState:
	return _state


func set_grid_position(grid_pos: Vector3i) -> void:
	## Set ghost position in grid coordinates
	_grid_pos = grid_pos
	position = grid_to_world_center(grid_pos)
	_update_floor_label()


func get_grid_position() -> Vector3i:
	return _grid_pos


func set_block_type(block_type: String) -> void:
	## Set the block type being placed
	_block_type = block_type
	# Could load different mesh for different block types here
	# For now, all blocks use the same cube


func get_block_type() -> String:
	return _block_type


func set_rotation_index(rot_index: int) -> void:
	## Set rotation index (0-3 = N/E/S/W)
	_rotation_index = rot_index % 4
	_mesh_instance.rotation_degrees.y = _rotation_index * 90.0
	rotation_changed.emit(_rotation_index)


func get_rotation_index() -> int:
	return _rotation_index


func rotate_ghost() -> void:
	## Rotate ghost 90° clockwise
	set_rotation_index(_rotation_index + 1)


func show_at(grid_pos: Vector3i, state: GhostState = GhostState.VALID) -> void:
	## Show ghost at grid position with state
	set_grid_position(grid_pos)
	set_state(state)
	visible = true


func hide_ghost() -> void:
	## Hide the ghost
	_state = GhostState.HIDDEN
	visible = false


func update_from_hit(hit: Dictionary, is_valid: bool, has_warnings: bool = false) -> void:
	## Convenience method to update ghost from raycast hit
	if not hit.get("hit", false):
		hide_ghost()
		return

	var place_pos: Vector3i = hit.get("place_pos", Vector3i.ZERO)
	set_grid_position(place_pos)

	if not is_valid:
		set_state(GhostState.INVALID)
	elif has_warnings:
		set_state(GhostState.WARNING)
	else:
		set_state(GhostState.VALID)

	visible = true


# --- Internal ---


func _apply_state() -> void:
	match _state:
		GhostState.HIDDEN:
			visible = false
		GhostState.VALID:
			visible = true
			_mesh_instance.material_override = _material_valid
		GhostState.WARNING:
			visible = true
			_mesh_instance.material_override = _material_warning
		GhostState.INVALID:
			visible = true
			_mesh_instance.material_override = _material_invalid


func _update_floor_label() -> void:
	if _floor_label:
		_floor_label.text = "Floor %d" % _grid_pos.z


# --- Static Helpers ---


static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
	## Convert grid position to world center (same as BlockRenderer3D)
	return Vector3(
		grid_pos.x * CUBE_WIDTH,
		grid_pos.z * CUBE_HEIGHT + CUBE_HEIGHT / 2.0,  # z = floor level
		grid_pos.y * CUBE_DEPTH  # grid y -> world z
	)
