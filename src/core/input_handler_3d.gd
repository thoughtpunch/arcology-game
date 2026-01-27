extends Node3D
class_name InputHandler3D

## 3D raycast-based input handler for block placement and selection
##
## Uses physics raycasting to detect blocks and terrain for:
## - Minecraft-style face-snap block placement
## - Block selection and removal
## - Ghost preview with validity coloring
##
## Collision layers:
## - Layer 1: Terrain (ground plane)
## - Layer 2: Blocks (opaque)
## - Layer 3: Blocks (transparent) - future use
## - Layer 4: Ghost (excluded from raycasts)

# Signals
signal block_placement_attempted(pos: Vector3i, type: String, success: bool)
signal block_removal_attempted(pos: Vector3i, success: bool)
signal selection_changed(block_type: String)
signal block_selected(pos: Vector3i, block_type: String)

# Cube face enum (for placement direction)
enum CubeFace { TOP, BOTTOM, NORTH, SOUTH, EAST, WEST }

# Mode
enum Mode { BUILD, SELECT, DEMOLISH }
var current_mode := Mode.BUILD

# Dependencies
var grid: Node = null  # Grid class
var camera: Camera3D = null  # ArcologyCamera's internal Camera3D
var block_renderer_3d: Node3D = null  # BlockRenderer3D
var placement_validator: RefCounted = null  # PlacementValidator

# Ghost preview (uses GhostPreview3D if available, falls back to BlockRenderer3D)
var ghost_preview: Node3D = null  # GhostPreview3D instance

# State
var selected_block_type: String = "corridor"
var _rotation_index: int = 0  # Block rotation (0-3)

# Raycast settings
const RAY_LENGTH: float = 2000.0
const COLLISION_MASK_TERRAIN: int = 1  # Layer 1
const COLLISION_MASK_BLOCKS: int = 2   # Layer 2
const COLLISION_MASK_ALL: int = 0b11   # Layers 1 and 2

# Placement cooldown
const PLACEMENT_COOLDOWN := 0.15  # seconds
var _last_placement_time := 0.0

# Ghost state
var _ghost_visible := false
var _ghost_grid_pos := Vector3i.ZERO
var _ghost_valid := false

# Construction queue reference (optional)
var construction_queue = null


func _ready() -> void:
	_create_ghost_preview()
	_create_placement_validator()


func _create_ghost_preview() -> void:
	## Create GhostPreview3D instance
	var GhostPreview3DClass = load("res://src/core/ghost_preview_3d.gd")
	if GhostPreview3DClass:
		ghost_preview = GhostPreview3DClass.new()
		ghost_preview.name = "GhostPreview"
		add_child(ghost_preview)


func _create_placement_validator() -> void:
	## Create PlacementValidator instance
	var PlacementValidatorClass = load("res://src/core/placement_validator.gd")
	if PlacementValidatorClass:
		placement_validator = PlacementValidatorClass.new(grid, null)


## Setup with required dependencies
func setup(p_grid: Node, p_camera: Camera3D, p_renderer: Node3D = null) -> void:
	grid = p_grid
	camera = p_camera
	block_renderer_3d = p_renderer
	# Update placement validator with grid reference
	if placement_validator:
		placement_validator.grid = grid
	print("InputHandler3D: Setup complete (grid=%s, camera=%s, renderer=%s, ghost=%s, validator=%s)" % [
		grid != null, camera != null, block_renderer_3d != null, ghost_preview != null, placement_validator != null
	])


func _process(_delta: float) -> void:
	if not _is_ready():
		return

	if current_mode == Mode.BUILD:
		_update_ghost_position()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_ready():
		return

	if event is InputEventMouseButton:
		if event.pressed:
			_handle_mouse_button(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			match current_mode:
				Mode.BUILD:
					_try_place_block()
				Mode.SELECT:
					_try_select_block()
				Mode.DEMOLISH:
					_try_remove_block()
		MOUSE_BUTTON_RIGHT:
			_try_remove_block()


# --- Raycasting ---

func _raycast_from_mouse() -> Dictionary:
	## Cast ray from camera through mouse position
	## Returns raycast result dictionary or empty dict
	if not camera:
		return {}

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := from + dir * RAY_LENGTH

	var space := get_world_3d()
	if not space:
		return {}
	var space_state := space.direct_space_state
	if not space_state:
		return {}

	var query := PhysicsRayQueryParameters3D.create(from, to, COLLISION_MASK_ALL)
	return space_state.intersect_ray(query)


func get_world_hit_at_cursor() -> Dictionary:
	## Get detailed hit information at cursor position
	## Returns: { hit: bool, position: Vector3, normal: Vector3,
	##            collider: Node, grid_pos: Vector3i, face: CubeFace }
	var result := _raycast_from_mouse()

	if result.is_empty():
		return { "hit": false }

	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var collider = result.collider

	# Calculate grid position of the hit block
	# Offset slightly back along normal to get the block we hit
	var block_pos := hit_pos - hit_normal * 0.1
	var grid_pos := _world_to_grid(block_pos)

	# Detect face from normal
	var face := _normal_to_face(hit_normal)

	return {
		"hit": true,
		"position": hit_pos,
		"normal": hit_normal,
		"collider": collider,
		"grid_pos": grid_pos,
		"face": face
	}


func get_placement_position(hit: Dictionary) -> Vector3i:
	## Calculate where to place a new block based on hit data
	## Returns grid position adjacent to hit face
	if not hit.get("hit", false):
		return Vector3i.ZERO

	var grid_pos: Vector3i = hit.grid_pos
	var normal: Vector3 = hit.normal

	# Offset by normal direction to place adjacent to hit surface
	var offset := Vector3i(
		roundi(normal.x),
		roundi(normal.z),  # normal Y -> grid Z (floor level)
		roundi(normal.y)   # normal Y -> grid Z
	)

	# For ground plane (Y+ normal), place at Z=0
	# For block faces, place adjacent
	if absf(normal.y) > 0.5:
		# Hit top or bottom face - adjust floor level
		return Vector3i(grid_pos.x, grid_pos.y, grid_pos.z + roundi(normal.y))
	else:
		# Hit side face - adjust X or Y (grid horizontal)
		return Vector3i(
			grid_pos.x + roundi(normal.x),
			grid_pos.y + roundi(normal.z),
			grid_pos.z
		)


func _normal_to_face(normal: Vector3) -> CubeFace:
	## Convert hit normal to CubeFace enum
	if normal.y > 0.5:
		return CubeFace.TOP
	if normal.y < -0.5:
		return CubeFace.BOTTOM
	if normal.z > 0.5:
		return CubeFace.NORTH
	if normal.z < -0.5:
		return CubeFace.SOUTH
	if normal.x > 0.5:
		return CubeFace.EAST
	return CubeFace.WEST


# --- Grid Coordinate Conversion ---

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	## Convert world position to grid coordinates
	## Uses BlockRenderer3D constants for consistency
	const CUBE_WIDTH: float = 6.0
	const CUBE_DEPTH: float = 6.0
	const CUBE_HEIGHT: float = 3.5

	return Vector3i(
		roundi(world_pos.x / CUBE_WIDTH),
		roundi(world_pos.z / CUBE_DEPTH),  # world z -> grid y
		roundi((world_pos.y - CUBE_HEIGHT / 2.0) / CUBE_HEIGHT)  # world y -> grid z
	)


func _grid_to_world_center(grid_pos: Vector3i) -> Vector3:
	## Convert grid position to world center
	const CUBE_WIDTH: float = 6.0
	const CUBE_DEPTH: float = 6.0
	const CUBE_HEIGHT: float = 3.5

	return Vector3(
		grid_pos.x * CUBE_WIDTH,
		grid_pos.z * CUBE_HEIGHT + CUBE_HEIGHT / 2.0,
		grid_pos.y * CUBE_DEPTH
	)


# --- Ghost Preview ---

func _update_ghost_position() -> void:
	## Update ghost preview based on cursor raycast
	var hit := get_world_hit_at_cursor()

	if not hit.get("hit", false):
		_hide_ghost()
		return

	# Get placement position
	var place_pos := get_placement_position(hit)
	_ghost_grid_pos = place_pos
	_ghost_visible = true

	# Get full validation result
	var validation_result = _get_validation_result(place_pos)
	var has_warnings := false

	if validation_result:
		_ghost_valid = validation_result.valid
		has_warnings = validation_result.has_warnings()
	else:
		_ghost_valid = _is_placement_valid(place_pos)

	# Update ghost preview (prefer GhostPreview3D, fall back to BlockRenderer3D)
	if ghost_preview:
		ghost_preview.set_block_type(selected_block_type)
		ghost_preview.set_grid_position(place_pos)
		if not _ghost_valid:
			ghost_preview.set_state(ghost_preview.GhostState.INVALID)
		elif has_warnings:
			ghost_preview.set_state(ghost_preview.GhostState.WARNING)
		else:
			ghost_preview.set_state(ghost_preview.GhostState.VALID)
	elif block_renderer_3d:
		var state: int
		if not _ghost_valid:
			state = 4  # BlockState.GHOST_INVALID
		elif has_warnings:
			state = 3  # BlockState.GHOST_WARNING (if supported)
		else:
			state = 2  # BlockState.GHOST_VALID
		block_renderer_3d.show_ghost(place_pos, selected_block_type, state)


func _hide_ghost() -> void:
	_ghost_visible = false
	if ghost_preview:
		ghost_preview.hide_ghost()
	elif block_renderer_3d:
		block_renderer_3d.hide_ghost()


# --- Placement Logic ---

func _try_place_block() -> void:
	## Attempt to place block at ghost position
	if not _ghost_visible:
		return

	# Check cooldown
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_placement_time < PLACEMENT_COOLDOWN:
		return

	if not _is_placement_valid(_ghost_grid_pos):
		block_placement_attempted.emit(_ghost_grid_pos, selected_block_type, false)
		return

	# Check ground_only constraint
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and _ghost_grid_pos.z != 0:
		block_placement_attempted.emit(_ghost_grid_pos, selected_block_type, false)
		return

	# Place block
	var success := false
	if construction_queue:
		success = construction_queue.start_construction(_ghost_grid_pos, selected_block_type)
	else:
		# Direct placement (no construction queue)
		var BlockClass = load("res://src/blocks/block.gd")
		if BlockClass:
			var block = BlockClass.new(selected_block_type, _ghost_grid_pos)
			grid.set_block(_ghost_grid_pos, block)
			success = true

	_last_placement_time = current_time
	block_placement_attempted.emit(_ghost_grid_pos, selected_block_type, success)


func _is_placement_valid(pos: Vector3i) -> bool:
	## Check if placement is valid at position using PlacementValidator
	# Use placement validator if available
	if placement_validator:
		return placement_validator.is_valid_placement(pos, selected_block_type)

	# Fallback to basic checks if validator not available
	# Can't place below minimum floor
	if pos.z < -3:  # MIN_FLOOR
		return false

	# Can't place on occupied cell
	if grid.has_block(pos):
		return false

	# Can't place where construction is active
	if construction_queue and construction_queue.has_method("has_construction"):
		if construction_queue.has_construction(pos):
			return false

	# Check ground_only constraint
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and pos.z != 0:
		return false

	return true


func _get_validation_result(pos: Vector3i):
	## Get full validation result for ghost state updates
	if placement_validator:
		return placement_validator.validate_placement(pos, selected_block_type)
	return null


# --- Removal Logic ---

func _try_remove_block() -> void:
	## Attempt to remove block at cursor position
	var hit := get_world_hit_at_cursor()

	if not hit.get("hit", false):
		return

	var grid_pos: Vector3i = hit.grid_pos

	if not grid.has_block(grid_pos):
		block_removal_attempted.emit(grid_pos, false)
		return

	grid.remove_block(grid_pos)
	block_removal_attempted.emit(grid_pos, true)


# --- Selection Logic ---

func _try_select_block() -> void:
	## Select block at cursor position
	var hit := get_world_hit_at_cursor()

	if not hit.get("hit", false):
		return

	var grid_pos: Vector3i = hit.grid_pos

	if not grid.has_block(grid_pos):
		return

	var block = grid.get_block_at(grid_pos)
	if block:
		var block_type: String
		if block is Object and "block_type" in block:
			block_type = block.block_type
		elif block is Dictionary:
			block_type = block.get("block_type", "unknown")
		else:
			block_type = "unknown"

		block_selected.emit(grid_pos, block_type)


# --- Block Data ---

func _get_block_data(block_type: String) -> Dictionary:
	## Get block definition from BlockRegistry
	var tree := get_tree()
	if not tree:
		return {}
	var registry = tree.get_root().get_node_or_null("/root/BlockRegistry")
	if not registry:
		return {}
	return registry.get_block_data(block_type)


# --- Public API ---

func _is_ready() -> bool:
	return grid != null and camera != null


func set_selected_block_type(type: String) -> void:
	if selected_block_type != type:
		selected_block_type = type
		selection_changed.emit(type)


func get_selected_block_type() -> String:
	return selected_block_type


func set_mode(mode: Mode) -> void:
	current_mode = mode
	# Hide ghost when not in build mode
	if mode != Mode.BUILD:
		_hide_ghost()


func get_mode() -> Mode:
	return current_mode


func set_construction_queue(queue) -> void:
	construction_queue = queue


func get_ghost_position() -> Vector3i:
	return _ghost_grid_pos


func is_ghost_visible() -> bool:
	return _ghost_visible


func is_placement_valid() -> bool:
	return _ghost_visible and _ghost_valid


func get_rotation_index() -> int:
	## Get current rotation index (0-3)
	if ghost_preview:
		return ghost_preview.get_rotation_index()
	return _rotation_index


func set_rotation_index(rotation_idx: int) -> void:
	## Set rotation index (0-3 = N/E/S/W)
	_rotation_index = rotation_idx % 4
	if ghost_preview:
		ghost_preview.set_rotation_index(_rotation_index)


## Handle click forwarded from HUD (for compatibility with existing UI)
func handle_viewport_click(event: InputEventMouseButton) -> void:
	if not _is_ready():
		return
	_handle_mouse_button(event)


func get_validation_result(pos: Vector3i, block_type: String = ""):
	## Get full validation result for a position
	## Returns PlacementValidator.ValidationResult or null
	if placement_validator:
		var type := block_type if not block_type.is_empty() else selected_block_type
		return placement_validator.validate_placement(pos, type)
	return null


func get_current_validation_result():
	## Get validation result for current ghost position
	## Returns PlacementValidator.ValidationResult or null
	if not _ghost_visible:
		return null
	return get_validation_result(_ghost_grid_pos)


func has_placement_warnings() -> bool:
	## Check if current placement has warnings (but is still valid)
	var result = get_current_validation_result()
	if result == null:
		return false
	return result.valid and result.has_warnings()


func get_placement_warnings() -> Array[String]:
	## Get list of warnings for current placement
	var result = get_current_validation_result()
	if result == null:
		return []
	if result.has_warnings():
		return result.warnings
	return []


func get_placement_error() -> String:
	## Get error message if placement is invalid
	var result = get_current_validation_result()
	if result == null:
		return ""
	if not result.valid:
		return result.reason
	return ""
