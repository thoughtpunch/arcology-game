class_name InputHandler
extends Node
## Handles mouse input for block placement and removal
## Manages ghost preview and validates placement

signal block_placement_attempted(pos: Vector3i, type: String, success: bool)
signal block_removal_attempted(pos: Vector3i, success: bool)
signal selection_changed(block_type: String)

# References (must be set before use)
var grid: Grid
var camera: Camera2D
var ghost_container: Node2D  # Parent node for ghost sprite

# State
var current_floor: int = 0
var selected_block_type: String = "corridor"
var _ghost_sprite: Sprite2D
var _texture_cache: Dictionary = {}

# Ghost modulation colors
const VALID_COLOR := Color(1.0, 1.0, 1.0, 0.6)    # Semi-transparent white
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.6)  # Semi-transparent red


func _ready() -> void:
	_create_ghost_sprite()


## Initialize with required references
func setup(p_grid: Grid, p_camera: Camera2D, p_ghost_container: Node2D) -> void:
	grid = p_grid
	camera = p_camera
	ghost_container = p_ghost_container

	if _ghost_sprite and ghost_container:
		# Reparent ghost sprite to container
		if _ghost_sprite.get_parent():
			_ghost_sprite.get_parent().remove_child(_ghost_sprite)
		ghost_container.add_child(_ghost_sprite)
		_update_ghost_texture()


func _create_ghost_sprite() -> void:
	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.modulate = VALID_COLOR
	_ghost_sprite.z_index = 1000  # Always on top
	_ghost_sprite.visible = false
	add_child(_ghost_sprite)  # Temporary parent until setup() called


func _process(_delta: float) -> void:
	if not _is_ready():
		return
	_update_ghost_position()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_ready():
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if not event.pressed:
		return

	var grid_pos := _get_grid_pos_at_mouse()

	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_block(grid_pos)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_try_remove_block(grid_pos)


## Attempt to place a block at the given grid position
func _try_place_block(pos: Vector3i) -> void:
	# Validate placement
	if grid.has_block(pos):
		block_placement_attempted.emit(pos, selected_block_type, false)
		return

	# Check ground_only constraint for entrance blocks
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and pos.z != 0:
		block_placement_attempted.emit(pos, selected_block_type, false)
		return

	# Create and place block
	var block := Block.new(selected_block_type, pos)
	grid.set_block(pos, block)

	block_placement_attempted.emit(pos, selected_block_type, true)


## Attempt to remove a block at the given grid position
func _try_remove_block(pos: Vector3i) -> void:
	if not grid.has_block(pos):
		block_removal_attempted.emit(pos, false)
		return

	grid.remove_block(pos)
	block_removal_attempted.emit(pos, true)


## Update ghost sprite position to follow mouse
func _update_ghost_position() -> void:
	var grid_pos := _get_grid_pos_at_mouse()

	# Position ghost at grid cell
	_ghost_sprite.position = grid.grid_to_screen(grid_pos)
	_ghost_sprite.visible = true

	# Update color based on validity
	var is_valid := _is_placement_valid(grid_pos)
	_ghost_sprite.modulate = VALID_COLOR if is_valid else INVALID_COLOR


## Check if placement would be valid at this position
func _is_placement_valid(pos: Vector3i) -> bool:
	# Can't place on occupied cell
	if grid.has_block(pos):
		return false

	# Check ground_only constraint
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and pos.z != 0:
		return false

	return true


## Get the grid position under the mouse cursor
func _get_grid_pos_at_mouse() -> Vector3i:
	var mouse_pos := get_viewport().get_mouse_position()

	# Convert screen position to world position (accounting for camera transform)
	var world_pos := camera.get_canvas_transform().affine_inverse() * mouse_pos

	# Convert to grid
	return grid.screen_to_grid(world_pos, current_floor)


## Check if all required references are set
func _is_ready() -> bool:
	return grid != null and camera != null and ghost_container != null


## Change the currently selected block type
func set_selected_block_type(type: String) -> void:
	if selected_block_type != type:
		selected_block_type = type
		_update_ghost_texture()
		selection_changed.emit(type)


## Change the current floor for placement
func set_current_floor(floor_num: int) -> void:
	current_floor = floor_num


## Update ghost sprite texture to match selected block type
func _update_ghost_texture() -> void:
	if _ghost_sprite == null:
		return

	var texture := _get_block_texture(selected_block_type)
	if texture:
		_ghost_sprite.texture = texture


## Get texture for a block type, with caching
func _get_block_texture(block_type: String) -> Texture2D:
	if _texture_cache.has(block_type):
		return _texture_cache[block_type]

	var block_data := _get_block_data(block_type)
	var sprite_path: String = block_data.get("sprite", "")

	if sprite_path.is_empty():
		return null

	var texture = load(sprite_path)
	if texture:
		_texture_cache[block_type] = texture
	return texture


## Get block data from BlockRegistry
func _get_block_data(block_type: String) -> Dictionary:
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		return {}
	return registry.get_block_data(block_type)
