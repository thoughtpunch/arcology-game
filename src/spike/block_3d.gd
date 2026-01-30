extends CSGBox3D
class_name Block3D

## 3D block for spike testing using CSGBox3D
##
## Cell dimensions (THE CELL — true cube):
## - All axes: 6m
## - Contains 2 internal residential floors at 3m each

# Cell dimensions in meters (Godot units) — true cube
const CELL_SIZE: float = 6.0     # All axes
const BLOCK_WIDTH: float = CELL_SIZE   # X axis (alias)
const BLOCK_DEPTH: float = CELL_SIZE   # Z axis (alias)
const BLOCK_HEIGHT: float = CELL_SIZE  # Y axis (alias)

# Grid position in block coordinates
var grid_position: Vector3i = Vector3i.ZERO:
	set(value):
		grid_position = value
		_update_world_position()

# Block type identifier
var block_type: String = "corridor":
	set(value):
		block_type = value
		_update_material()

# Materials for each block type
static var _materials: Dictionary = {}

# Collision layer for blocks (layer 2)
const COLLISION_LAYER: int = 2


func _init() -> void:
	# Set CSG box size
	size = Vector3(BLOCK_WIDTH, BLOCK_HEIGHT, BLOCK_DEPTH)

	# Enable collision
	use_collision = true
	collision_layer = COLLISION_LAYER
	collision_mask = 0  # Don't collide with anything, just for raycasting


func _ready() -> void:
	_update_material()
	_update_world_position()


func _update_world_position() -> void:
	# Convert grid position to world position
	# Grid center is at world origin
	# Y is up (height), grid_position.y represents floor level
	position = grid_to_world(grid_position)


func _update_material() -> void:
	var mat := _get_material_for_type(block_type)
	if mat:
		material = mat


static func grid_to_world(grid_pos: Vector3i) -> Vector3:
	## Convert grid coordinates to world position (center of block)
	return Vector3(
		grid_pos.x * BLOCK_WIDTH,
		grid_pos.y * BLOCK_HEIGHT + BLOCK_HEIGHT / 2.0,  # Center vertically
		grid_pos.z * BLOCK_DEPTH
	)


static func world_to_grid(world_pos: Vector3) -> Vector3i:
	## Convert world position to grid coordinates
	return Vector3i(
		roundi(world_pos.x / BLOCK_WIDTH),
		roundi((world_pos.y - BLOCK_HEIGHT / 2.0) / BLOCK_HEIGHT),
		roundi(world_pos.z / BLOCK_DEPTH)
	)


static func _get_material_for_type(type: String) -> StandardMaterial3D:
	# Initialize materials on first access
	if _materials.is_empty():
		_init_materials()

	if _materials.has(type):
		return _materials[type]
	return _materials.get("default", null)


static func _init_materials() -> void:
	# Residential - warm beige
	var residential := StandardMaterial3D.new()
	residential.albedo_color = Color(0.85, 0.75, 0.65)  # Warm beige
	residential.roughness = 0.7
	_materials["residential"] = residential
	_materials["residential_basic"] = residential

	# Commercial - cool blue
	var commercial := StandardMaterial3D.new()
	commercial.albedo_color = Color(0.6, 0.7, 0.85)  # Cool blue
	commercial.roughness = 0.6
	_materials["commercial"] = commercial
	_materials["commercial_basic"] = commercial

	# Corridor - gray
	var corridor := StandardMaterial3D.new()
	corridor.albedo_color = Color(0.6, 0.6, 0.6)  # Gray
	corridor.roughness = 0.8
	_materials["corridor"] = corridor

	# Entrance - green
	var entrance := StandardMaterial3D.new()
	entrance.albedo_color = Color(0.5, 0.75, 0.5)  # Green
	entrance.roughness = 0.6
	_materials["entrance"] = entrance

	# Stairs - brown
	var stairs := StandardMaterial3D.new()
	stairs.albedo_color = Color(0.65, 0.5, 0.35)  # Brown
	stairs.roughness = 0.75
	_materials["stairs"] = stairs

	# Elevator - dark gray
	var elevator := StandardMaterial3D.new()
	elevator.albedo_color = Color(0.4, 0.4, 0.45)  # Dark gray-blue
	elevator.roughness = 0.5
	elevator.metallic = 0.3
	_materials["elevator_shaft"] = elevator

	# Default - magenta for visibility
	var default := StandardMaterial3D.new()
	default.albedo_color = Color(1.0, 0.0, 1.0)  # Magenta (obvious)
	default.roughness = 0.5
	_materials["default"] = default


static func get_available_types() -> Array[String]:
	## Returns list of block types with materials defined
	if _materials.is_empty():
		_init_materials()
	var types: Array[String] = []
	for key in _materials.keys():
		if key != "default":
			types.append(key)
	return types
