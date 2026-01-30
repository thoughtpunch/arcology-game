extends Node3D

## Phase 0 Sandbox — Block stacking playground.
## Builds the entire scene tree in _ready(). The .tscn is just a root Node3D.

const GridUtilsScript = preload("res://src/phase0/grid_utils.gd")
const BlockDefScript = preload("res://src/phase0/block_definition.gd")
const PlacedBlockScript = preload("res://src/phase0/placed_block.gd")
const RegistryScript = preload("res://src/phase0/block_registry.gd")
const CameraScript = preload("res://src/phase0/orbital_camera.gd")
const PaletteScript = preload("res://src/phase0/shape_palette.gd")

const CELL_SIZE: float = 6.0
const GROUND_SIZE: int = 20

# --- State ---
var registry: RefCounted
var current_definition: Resource
var current_rotation: int = 0

# Occupancy
var cell_occupancy: Dictionary = {}  # Vector3i -> int (block_id)
var placed_blocks: Dictionary = {}   # int -> PlacedBlock
var next_block_id: int = 1

# Node references
var _camera: Node3D
var _block_container: Node3D
var _ghost_node: Node3D
var _ghost_mesh: MeshInstance3D
var _ghost_valid_material: StandardMaterial3D
var _ghost_invalid_material: StandardMaterial3D
var _palette: HBoxContainer

# Cached ghost state to avoid unnecessary mesh rebuilds
var _ghost_def_id: String = ""
var _ghost_rotation: int = -1


func _ready() -> void:
	registry = RegistryScript.new()
	current_definition = registry.get_definition("cube")

	_setup_environment()
	_setup_camera()
	_setup_ground()
	_setup_block_container()
	_setup_ghost()
	_setup_ui()


# --- Scene Setup ---

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.6, 0.75, 0.9)
	sky_mat.ground_bottom_color = Color(0.25, 0.35, 0.2)
	sky_mat.ground_horizon_color = Color(0.55, 0.7, 0.5)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)


func _setup_camera() -> void:
	_camera = CameraScript.new()
	_camera.name = "OrbitalCamera"
	var center_offset := float(GROUND_SIZE) * CELL_SIZE / 2.0
	_camera.target = Vector3(center_offset, 0, center_offset)
	_camera._target_target = _camera.target
	add_child(_camera)


func _setup_ground() -> void:
	# Ground is a grid of blocks at y=-1. They participate in occupancy
	# so placement is uniform: always snap to a face.
	var ground_def: Resource = BlockDefScript.new()
	ground_def.id = "ground"
	ground_def.display_name = "Ground"
	ground_def.size = Vector3i(1, 1, 1)
	ground_def.color = Color(0.3, 0.55, 0.2)
	ground_def.is_symmetric = true

	var ground_container := Node3D.new()
	ground_container.name = "Ground"
	add_child(ground_container)

	# Single batched mesh for performance
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ground_def.color

	# Single collision body for the whole ground slab
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.set_meta("is_ground", true)

	var total_size := float(GROUND_SIZE) * CELL_SIZE
	var center := total_size / 2.0

	var col_shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(total_size, CELL_SIZE, total_size)
	col_shape.shape = col_box
	col_shape.position = Vector3(center, -CELL_SIZE / 2.0, center)
	static_body.add_child(col_shape)
	ground_container.add_child(static_body)

	# Visual: single flat box for the whole ground
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(total_size, CELL_SIZE, total_size)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = mat
	mesh_instance.position = Vector3(center, -CELL_SIZE / 2.0, center)
	ground_container.add_child(mesh_instance)

	# Register every ground cell in occupancy at y=-1
	for x in range(GROUND_SIZE):
		for z in range(GROUND_SIZE):
			var cell := Vector3i(x, -1, z)
			cell_occupancy[cell] = -1  # Special ground ID


func _setup_block_container() -> void:
	_block_container = Node3D.new()
	_block_container.name = "BlockContainer"
	add_child(_block_container)


func _setup_ghost() -> void:
	_ghost_node = Node3D.new()
	_ghost_node.name = "GhostBlock"
	_ghost_mesh = MeshInstance3D.new()
	_ghost_node.add_child(_ghost_mesh)
	add_child(_ghost_node)
	_ghost_node.visible = false

	_ghost_valid_material = StandardMaterial3D.new()
	_ghost_valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_valid_material.albedo_color = Color(0.2, 0.8, 0.2, 0.5)

	_ghost_invalid_material = StandardMaterial3D.new()
	_ghost_invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_invalid_material.albedo_color = Color(0.8, 0.2, 0.2, 0.5)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"

	var margin := MarginContainer.new()
	margin.anchor_bottom = 1.0
	margin.anchor_right = 1.0
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_palette = PaletteScript.new()
	_palette.registry = registry
	_palette.size_flags_vertical = Control.SIZE_SHRINK_END
	_palette.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_palette.shape_selected.connect(_on_shape_selected)

	margin.add_child(_palette)
	canvas.add_child(margin)
	add_child(canvas)


# --- Process ---

func _process(_delta: float) -> void:
	_update_ghost()


# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_remove_block()

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_COMMA: _rotate_ccw()
			KEY_PERIOD: _rotate_cw()
			KEY_1: _select_shape_by_index(0)
			KEY_2: _select_shape_by_index(1)
			KEY_3: _select_shape_by_index(2)
			KEY_4: _select_shape_by_index(3)
			KEY_5: _select_shape_by_index(4)
			KEY_6: _select_shape_by_index(5)
			KEY_7: _select_shape_by_index(6)


# --- Rotation ---

func _rotate_cw() -> void:
	current_rotation = (current_rotation + 90) % 360


func _rotate_ccw() -> void:
	current_rotation = (current_rotation + 270) % 360


# --- Shape Selection ---

func _select_shape_by_index(index: int) -> void:
	var defs: Array = registry.get_all_definitions()
	if index >= 0 and index < defs.size():
		current_definition = defs[index]
		_palette.highlight_definition(current_definition)


func _on_shape_selected(definition: Resource) -> void:
	current_definition = definition


# --- Occupancy ---

func is_cell_occupied(cell: Vector3i) -> bool:
	return cell_occupancy.has(cell)


func is_cell_buildable(cell: Vector3i) -> bool:
	return cell.y >= 0 and not is_cell_occupied(cell)


func _is_supported(cells: Array[Vector3i]) -> bool:
	## At least one cell must share a face with an existing block or ground.
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	for cell in cells:
		for dir in directions:
			var neighbor: Vector3i = cell + dir
			if cell_occupancy.has(neighbor):
				return true
	return false


func can_place_block(definition: Resource, origin: Vector3i, rot: int) -> bool:
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		definition.size, origin, rot,
	)
	for cell in cells:
		if not is_cell_buildable(cell):
			return false
	if not _is_supported(cells):
		return false
	return true


func place_block(definition: Resource, origin: Vector3i, rot: int) -> RefCounted:
	if not can_place_block(definition, origin, rot):
		return null

	var block: RefCounted = PlacedBlockScript.new()
	block.id = next_block_id
	next_block_id += 1
	block.definition = definition
	block.origin = origin
	block.rotation = rot
	block.occupied_cells = GridUtilsScript.get_occupied_cells(
		definition.size, origin, rot,
	)

	for cell in block.occupied_cells:
		cell_occupancy[cell] = block.id

	block.node = _create_block_node(block)
	_block_container.add_child(block.node)

	placed_blocks[block.id] = block
	return block


func remove_block(block_id: int) -> void:
	if not placed_blocks.has(block_id):
		return

	var block: RefCounted = placed_blocks[block_id]

	for cell in block.occupied_cells:
		cell_occupancy.erase(cell)

	block.node.queue_free()
	placed_blocks.erase(block_id)


func remove_block_at_cell(cell: Vector3i) -> void:
	if cell_occupancy.has(cell):
		remove_block(cell_occupancy[cell])


# --- Block Node Creation ---

func _create_block_node(block: RefCounted) -> Node3D:
	var definition: Resource = block.definition
	var rotation_deg: int = block.rotation
	var effective_size: Vector3i = definition.size
	if rotation_deg == 90 or rotation_deg == 270:
		effective_size = Vector3i(
			definition.size.z, definition.size.y, definition.size.x,
		)

	var root := Node3D.new()
	root.name = "Block_%d" % block.id

	# Mesh
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _create_mesh_for(definition, effective_size)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = definition.color
	mesh_instance.material_override = mat

	var center_offset := Vector3(effective_size) * CELL_SIZE / 2.0
	mesh_instance.position = center_offset
	root.add_child(mesh_instance)

	# Collision for raycasting
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.set_meta("block_id", block.id)

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(effective_size) * CELL_SIZE
	collision.shape = box_shape
	collision.position = center_offset

	static_body.add_child(collision)
	root.add_child(static_body)

	# Position at grid corner
	root.global_position = GridUtilsScript.grid_to_world(block.origin)

	return root


func _create_mesh_for(_definition: Resource, effective_size: Vector3i) -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(effective_size) * CELL_SIZE
	return box


# --- Ghost Preview ---

func _update_ghost() -> void:
	var hit := _raycast_from_mouse()

	if hit.is_empty() or not hit.get("hit", false):
		_ghost_node.visible = false
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)),
		int(round(hit.normal.y)),
		int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	# Rebuild mesh only when definition or rotation changes
	if _ghost_def_id != current_definition.id or _ghost_rotation != current_rotation:
		_ghost_def_id = current_definition.id
		_ghost_rotation = current_rotation
		_rebuild_ghost_mesh()

	_ghost_node.global_position = GridUtilsScript.grid_to_world(place_origin)

	var valid := can_place_block(current_definition, place_origin, current_rotation)
	if valid:
		_ghost_mesh.material_override = _ghost_valid_material
	else:
		_ghost_mesh.material_override = _ghost_invalid_material

	_ghost_node.visible = true


func _rebuild_ghost_mesh() -> void:
	var def_size: Vector3i = current_definition.size
	var effective_size: Vector3i = def_size
	if current_rotation == 90 or current_rotation == 270:
		effective_size = Vector3i(def_size.z, def_size.y, def_size.x)

	_ghost_mesh.mesh = _create_mesh_for(current_definition, effective_size)
	_ghost_mesh.position = Vector3(effective_size) * CELL_SIZE / 2.0


# --- Raycast ---

func _raycast_from_mouse() -> Dictionary:
	var viewport := get_viewport()
	if not viewport:
		return {}
	var camera := viewport.get_camera_3d()
	if not camera:
		return {}

	var mouse_pos := viewport.get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := from + dir * 1000.0

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1

	var result := space.intersect_ray(query)

	if result:
		var hit_pos: Vector3 = result.position
		var hit_normal: Vector3 = result.normal
		return {
			"hit": true,
			"position": hit_pos,
			"normal": hit_normal,
			"collider": result.collider,
			"grid_pos": GridUtilsScript.world_to_grid(
				hit_pos - hit_normal * 0.01,
			)
		}

	return {"hit": false}


# --- Placement / Removal ---

func _try_place_block() -> void:
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)),
		int(round(hit.normal.y)),
		int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	place_block(current_definition, place_origin, current_rotation)


func _try_remove_block() -> void:
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		return

	var collider = hit.collider
	if collider and collider.has_meta("is_ground"):
		return

	if collider and collider.has_meta("block_id"):
		remove_block(collider.get_meta("block_id"))
	elif hit.has("grid_pos") and cell_occupancy.has(hit.grid_pos):
		remove_block(cell_occupancy[hit.grid_pos])
