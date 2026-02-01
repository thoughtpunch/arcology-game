extends Node3D

## Arcology — Block stacking city builder.
## Builds the entire scene tree in _ready(). The .tscn is just a root Node3D.

const GridUtilsScript = preload("res://src/game/grid_utils.gd")
const BlockDefScript = preload("res://src/game/block_definition.gd")
const PlacedBlockScript = preload("res://src/game/placed_block.gd")
const RegistryScript = preload("res://src/game/block_registry.gd")
const CameraScript = preload("res://src/game/orbital_camera.gd")
const PaletteScript = preload("res://src/game/shape_palette.gd")
const PauseMenuScript = preload("res://src/game/sandbox_pause_menu.gd")
const DebugPanelScript = preload("res://src/game/sandbox_debug_panel.gd")
const HelpOverlayScript = preload("res://src/game/sandbox_help_overlay.gd")
const FaceScript = preload("res://src/game/face.gd")
const ScenarioConfigScript = preload("res://src/game/visual_scenario_config.gd")
const ScenarioPickerScript = preload("res://src/game/scenario_picker.gd")
const SelectionManagerScript = preload("res://src/game/selection_manager.gd")
const PanelSystemScript = preload("res://src/game/panel_system.gd")
const PanelMatScript = preload("res://src/game/panel_material.gd")
const InteriorMeshSystemScript = preload("res://src/game/interior_mesh_system.gd")
const CorridorDragScript = preload("res://src/game/corridor_drag_builder.gd")
const PlacementValidatorScript = preload("res://src/game/placement_validator.gd")
const CoreScenarioConfigScript = preload("res://src/game/structural_scenario_config.gd")
const ViewCubeScript = preload("res://src/ui/view_cube.gd")
const LODManagerScript = preload("res://src/game/lod_manager.gd")
const VisibilityControllerScript = preload("res://src/game/visibility_controller.gd")
const UndergroundWallScript = preload("res://src/game/underground_wall_system.gd")
const ExcavationSystemScript = preload("res://src/game/excavation_system.gd")
const CELL_SIZE: float = 6.0
const PLACE_INTERVAL: float = 0.1  # 100ms = 10 blocks/sec
const BLOCK_INSET: float = 0.15  # Visual gap between adjacent blocks (per side)
const LOG_PREFIX := "[Sandbox] "
const SELECTION_EMISSION_ENERGY: float = 0.35
const SELECTION_OUTLINE_COLOR := Color(0.2, 0.7, 1.0)  # Cyan highlight for selected blocks

# --- Build Zone ---
# Initialized from _config when scenario is selected.
var build_zone_origin: Vector2i = Vector2i(40, 40)
var build_zone_size: Vector2i = Vector2i(20, 20)

# --- State ---
var registry: RefCounted
var current_definition: Resource
var current_rotation: int = 0
var selection: RefCounted  # SelectionManager instance

# Occupancy
var cell_occupancy: Dictionary = {}  # Vector3i -> int (block_id)
var placed_blocks: Dictionary = {}  # int -> PlacedBlock
var next_block_id: int = 1

# --- Scenario Config ---
var _config: RefCounted = null

# --- GameState reference (autoload) ---
var _game_state: Node = null

# --- Core Placement Validator ---
var _placement_validator: RefCounted = null

# --- LOD Manager ---
var _lod_manager: RefCounted = null

# --- Visibility Controller ---
var _visibility_controller: RefCounted = null
var _visibility_label: Label

# --- Underground Wall System ---
var _underground_wall_system: RefCounted = null
var _underground_wall_container: Node3D

# Node references
var _camera: Node3D
var _block_container: Node3D
var _ghost_node: Node3D
var _ghost_mesh: MeshInstance3D
var _ghost_material: ShaderMaterial
var _palette: Control
var _ground_layers: Array[MultiMeshInstance3D] = []  # index 0 = y=-1, index 4 = y=-5
var _ground_cell_indices: Array[Dictionary] = []  # per-layer Vector2i(x,z) -> int (multimesh index)
var _grid_overlays: Dictionary = {}  # y_level (int) -> MeshInstance3D
var _pause_menu: Control
var _debug_panel: Control
var _warning_label: Label
var _place_audio: AudioStreamPlayer
var _face_highlight: MeshInstance3D
var _face_material: ShaderMaterial
var _face_label: Label
var _controls_label: Label
var _help_overlay: Control
var _view_cube: Control
var _ghost_face_labels: Dictionary = {}  # FaceScript.Dir -> Label3D
var _ui_hidden: bool = false
var _stats_blocks_label: Label
var _stats_camera_label: Label
var _stats_mouse_label: Label
var _stats_occupancy_label: Label
var _stats_height_label: Label
var _stats_volume_label: Label
var _stats_footprint_label: Label
var _building_height: int = 0
var _building_volume: int = 0
var _building_footprint: int = 0
var _building_stats_hud: Label
var _entrance_block_ids: Dictionary = {}  # block_id -> true
var _has_entrance: bool = false
var _selection_label: Label
var _prompt_label: Label
var _sun: DirectionalLight3D
var _sky_material: ProceduralSkyMaterial
var _environment: Environment

# Rapid-fire placement (hold LMB + sweep to keep placing)
var _placing: bool = false
var _place_cooldown: float = 0.0
var _last_place_origin: Vector3i = Vector3i(-9999, -9999, -9999)

# Corridor drag-to-build state
var _corridor_drag_active: bool = false
var _corridor_drag_start: Vector3i = Vector3i.ZERO
var _corridor_drag_end: Vector3i = Vector3i.ZERO
var _corridor_drag_path: Array[Vector3i] = []
var _corridor_drag_ghosts: Array[MeshInstance3D] = []
var _corridor_drag_ghost_container: Node3D
var _corridor_drag_label: Label  # HUD label showing path length + cost

# Cached ghost state to avoid unnecessary mesh rebuilds
var _ghost_def_id: String = ""
var _ghost_rotation: int = -1


static func _log(msg: String) -> void:
	if OS.is_debug_build():
		print(LOG_PREFIX + msg)


func _ready() -> void:
	_log("Initializing Phase 0 sandbox")
	# Get GameState autoload reference
	_game_state = get_node_or_null("/root/GameState")
	registry = RegistryScript.new()
	current_definition = registry.get_definition("entrance")
	selection = SelectionManagerScript.new()
	selection.block_selected.connect(_on_block_selected)
	selection.block_deselected.connect(_on_block_deselected)
	_show_scenario_picker()


func _show_scenario_picker() -> void:
	var picker_canvas := CanvasLayer.new()
	picker_canvas.name = "PickerCanvas"
	picker_canvas.layer = 10
	var picker: Control = ScenarioPickerScript.new()
	picker.name = "ScenarioPicker"
	picker.scenario_selected.connect(_on_scenario_selected.bind(picker_canvas))
	picker_canvas.add_child(picker)
	add_child(picker_canvas)


func _on_scenario_selected(config: RefCounted, picker_canvas: CanvasLayer) -> void:
	_config = config
	build_zone_origin = _config.build_zone_origin
	build_zone_size = _config.build_zone_size
	picker_canvas.queue_free()
	_setup_placement_validator()
	_build_world()


func _setup_placement_validator() -> void:
	var core_config: Resource = CoreScenarioConfigScript.new()
	core_config.gravity = _config.gravity if "gravity" in _config else 1.0
	core_config.max_cantilever = CoreScenarioConfigScript.calculate_cantilever(core_config.gravity)
	core_config.structural_integrity = true
	core_config.ground_depth = _config.ground_depth if "ground_depth" in _config else 3
	core_config.build_zone_origin = build_zone_origin
	core_config.build_zone_size = build_zone_size
	_placement_validator = PlacementValidatorScript.new(self, registry, core_config)
	_log("PlacementValidator initialized (gravity=%.2f, max_cantilever=%d)" % [
		core_config.gravity, core_config.max_cantilever
	])


func _build_world() -> void:
	_setup_environment()
	_setup_camera()
	_setup_ground()
	_setup_grid_overlay()
	_setup_skyline()
	_setup_mountains()
	_setup_river()
	_setup_block_container()
	_setup_ghost()
	_setup_corridor_drag()
	_setup_face_highlight()
	_setup_compass_markers()
	_setup_ui()
	_setup_audio()
	_setup_lod()
	_setup_visibility_controller()
	_log(
		(
			"=== Sandbox ready: %d block types, build zone %s+%s, scenario=%s ==="
			% [
				registry.get_all_definitions().size(),
				build_zone_origin,
				build_zone_size,
				_config.id,
			]
		)
	)


# --- Scene Setup ---


func _setup_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_material = ProceduralSkyMaterial.new()
	_sky_material.sky_top_color = _config.sky_top_color
	_sky_material.sky_horizon_color = _config.sky_horizon_color
	_sky_material.ground_bottom_color = _config.ground_bottom_color
	_sky_material.ground_horizon_color = _config.ground_horizon_color
	sky.sky_material = _sky_material
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = _config.ambient_energy

	_environment.fog_enabled = true
	_environment.fog_light_color = _config.fog_color
	_environment.fog_density = _config.fog_density

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = _environment
	add_child(world_env)

	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.rotation_degrees = Vector3(-45, 30, 0)
	_sun.light_energy = _config.sun_energy
	_sun.shadow_enabled = true
	add_child(_sun)
	_log("Environment ready (sky, fog, sun)")


func _setup_camera() -> void:
	_camera = CameraScript.new()
	_camera.name = "OrbitalCamera"
	var zone_center_x := (float(build_zone_origin.x) + float(build_zone_size.x) / 2.0) * CELL_SIZE
	var zone_center_z := (float(build_zone_origin.y) + float(build_zone_size.y) / 2.0) * CELL_SIZE
	_camera.target = Vector3(zone_center_x, 0, zone_center_z)
	_camera._target_target = _camera.target
	add_child(_camera)
	_log("Camera ready at target (%.0f, 0, %.0f)" % [zone_center_x, zone_center_z])


func _setup_ground() -> void:
	# Ground is N layers of individually-destroyable cells (y=-1 through y=-N).
	# Each layer is a separate MultiMeshInstance3D with its own strata color.
	var ground_container := Node3D.new()
	ground_container.name = "Ground"
	add_child(ground_container)

	var gs: int = _config.ground_size
	var gd: int = _config.ground_depth
	var cell_count := gs * gs
	var mesh := _make_ground_cell_mesh()

	for layer_idx in range(gd):
		var y_level: int = -(layer_idx + 1)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = _config.strata_colors[layer_idx]

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = cell_count
		mm.mesh = mesh

		var cell_index: Dictionary = {}
		var idx := 0
		for x in range(gs):
			for z in range(gs):
				var center := (
					GridUtilsScript
					. grid_to_world_center(
						Vector3i(x, y_level, z),
					)
				)
				mm.set_instance_transform(idx, Transform3D(Basis(), center))
				cell_index[Vector2i(x, z)] = idx
				cell_occupancy[Vector3i(x, y_level, z)] = -1
				idx += 1

		var mm_instance := MultiMeshInstance3D.new()
		mm_instance.multimesh = mm
		mm_instance.material_override = mat
		ground_container.add_child(mm_instance)

		_ground_layers.append(mm_instance)
		_ground_cell_indices.append(cell_index)

	# Single collision body covers the full ground slab for raycasting.
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.set_meta("is_ground", true)

	var total_size := float(gs) * CELL_SIZE
	var half := total_size / 2.0
	var total_depth := float(gd) * CELL_SIZE

	var col_shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(total_size, total_depth, total_size)
	col_shape.shape = col_box
	col_shape.position = Vector3(half, -total_depth / 2.0, half)
	static_body.add_child(col_shape)
	ground_container.add_child(static_body)

	# Setup underground wall system
	_underground_wall_container = Node3D.new()
	_underground_wall_container.name = "UndergroundWalls"
	ground_container.add_child(_underground_wall_container)
	_underground_wall_system = UndergroundWallScript.new()
	_underground_wall_system.setup(_underground_wall_container, cell_occupancy, gd)

	_log(
		(
			"Ground ready: %d layers, %dx%d cells, %d total ground cells"
			% [
				gd,
				gs,
				gs,
				cell_occupancy.size(),
			]
		)
	)


func _make_ground_cell_mesh() -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE)
	return box


func _find_top_ground_y(x: int, z: int) -> int:
	## Scans y=-1 to y=-ground_depth, returns topmost occupied ground cell Y.
	## Returns a value below all layers if no ground exists at this column.
	var gd: int = _config.ground_depth
	for y in range(-1, -(gd + 1), -1):
		if cell_occupancy.has(Vector3i(x, y, z)) and cell_occupancy[Vector3i(x, y, z)] == -1:
			return y
	return -(gd + 1)


func _remove_ground_cell(grid_pos: Vector3i) -> void:
	var layer_idx: int = -(grid_pos.y + 1)
	if layer_idx < 0 or layer_idx >= _config.ground_depth:
		push_warning(
			"[Sandbox] _remove_ground_cell: layer %d out of range for %s" % [layer_idx, grid_pos]
		)
		return

	var key := Vector2i(grid_pos.x, grid_pos.z)
	if not _ground_cell_indices[layer_idx].has(key):
		push_warning(
			"[Sandbox] _remove_ground_cell: no cell index for %s in layer %d" % [key, layer_idx]
		)
		return

	cell_occupancy.erase(grid_pos)
	var idx: int = _ground_cell_indices[layer_idx][key]
	# Hide by moving far off-screen
	(
		_ground_layers[layer_idx]
		. multimesh
		. set_instance_transform(
			idx,
			Transform3D(Basis(), Vector3(0, -10000, 0)),
		)
	)
	_ground_cell_indices[layer_idx].erase(key)

	# Add a grid overlay at the newly exposed floor level
	_add_grid_at_y(grid_pos.y)

	# Generate underground walls for this excavated cell
	if _underground_wall_system:
		_underground_wall_system.on_cell_excavated(grid_pos)


func _setup_grid_overlay() -> void:
	_add_grid_at_y(0)


func _add_grid_at_y(y_level: int) -> void:
	if _grid_overlays.has(y_level):
		return

	var grid_shader := load("res://shaders/grid_overlay.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = grid_shader
	mat.set_shader_parameter("cell_size", CELL_SIZE)
	mat.set_shader_parameter("line_color", Color(0.0, 0.8, 0.8, 0.6))
	mat.render_priority = 1

	var zone_world_size := Vector2(build_zone_size) * CELL_SIZE
	var plane := PlaneMesh.new()
	plane.size = zone_world_size

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = plane
	mesh_inst.material_override = mat
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_inst.transparency = 0.5

	var zone_center_x := (float(build_zone_origin.x) + float(build_zone_size.x) / 2.0) * CELL_SIZE
	var zone_center_z := (float(build_zone_origin.y) + float(build_zone_size.y) / 2.0) * CELL_SIZE
	mesh_inst.position = Vector3(zone_center_x, float(y_level) * CELL_SIZE + 0.01, zone_center_z)

	add_child(mesh_inst)
	_grid_overlays[y_level] = mesh_inst


func _setup_skyline() -> void:
	if _config.skyline_type == ScenarioConfigScript.SkylineType.NONE:
		_log("Skyline skipped (type=NONE)")
		return
	if _config.skyline_building_count <= 0:
		_log("Skyline skipped (building_count=0)")
		return

	# Three rings of buildings: near (just outside build zone), mid, far.
	# Near buildings are smaller and denser, blending into the play area.
	# Far buildings are taller and sparser, forming a dramatic skyline.
	var rng := RandomNumberGenerator.new()
	rng.seed = _config.skyline_seed

	var center_offset := float(_config.ground_size) * CELL_SIZE / 2.0
	var center := Vector3(center_offset, 0, center_offset)

	# Distribute building count across rings proportionally
	var bc: int = _config.skyline_building_count
	var near_count := int(bc * 0.4)
	var mid_count := int(bc * 0.33)
	var far_count := bc - near_count - mid_count

	var rings := [
		# [count, min_radius, max_radius, min_height, max_height, min_width, max_width]
		[near_count, 80.0, 250.0, 8.0, 60.0, 6.0, 18.0],  # Near: small/medium, dense
		[mid_count, 200.0, 500.0, 15.0, 120.0, 8.0, 24.0],  # Mid: medium, some tall
		[far_count, 400.0, 1000.0, 30.0, 250.0, 10.0, 30.0],  # Far: tall skyline
	]

	var total_count := 0
	for ring in rings:
		total_count += ring[0]

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = total_count

	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mm.mesh = box

	var idx := 0
	for ring in rings:
		var count: int = ring[0]
		var r_min: float = ring[1]
		var r_max: float = ring[2]
		var h_min: float = ring[3]
		var h_max: float = ring[4]
		var w_min: float = ring[5]
		var w_max: float = ring[6]

		for _i in range(count):
			var angle := rng.randf() * TAU
			var radius := rng.randf_range(r_min, r_max)
			var pos := center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)

			var width := rng.randf_range(w_min, w_max)
			var depth := rng.randf_range(w_min, w_max)
			var height := rng.randf_range(h_min, h_max) * pow(rng.randf(), 0.8)
			height = maxf(height, h_min)

			var basis := Basis.IDENTITY.scaled(Vector3(width, height, depth))
			var t := Transform3D(basis, pos + Vector3(0, height / 2.0, 0))
			mm.set_instance_transform(idx, t)

			# Near buildings are warmer/darker, far buildings are cooler/lighter (aerial perspective)
			var dist_t := clampf((radius - r_min) / maxf(r_max - r_min, 1.0), 0.0, 1.0)
			var grey := rng.randf_range(0.25, 0.42)
			var blue_shift := lerpf(0.01, 0.1, dist_t) + rng.randf_range(0.0, 0.03)
			var fade := lerpf(0.0, 0.08, dist_t)  # Slight lightening with distance
			(
				mm
				. set_instance_color(
					idx,
					Color(
						grey - blue_shift + fade,
						grey + fade,
						grey + blue_shift + fade,
					)
				)
			)
			idx += 1

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "Skyline"
	mm_instance.multimesh = mm
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(mm_instance)
	_log("Skyline ready: %d buildings in 3 rings" % total_count)


func _setup_mountains() -> void:
	if not _config.mountains_enabled or _config.mountain_count <= 0:
		_log("Mountains skipped (disabled or count=0)")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = _config.mountain_seed

	var center_offset := float(_config.ground_size) * CELL_SIZE / 2.0
	var center := Vector3(center_offset, 0, center_offset)

	var count: int = _config.mountain_count
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count

	# Hexagonal cone — CylinderMesh with top_radius=0
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 0
	mm.mesh = cone

	for i in range(count):
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(500.0, 1200.0)
		var pos := center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)

		var height := rng.randf_range(_config.mountain_min_height, _config.mountain_max_height)
		var base_radius := rng.randf_range(_config.mountain_min_radius, _config.mountain_max_radius)
		# Scale: x/z = base diameter, y = height
		var basis := Basis.IDENTITY.scaled(Vector3(base_radius * 2.0, height, base_radius * 2.0))
		var t := Transform3D(basis, pos + Vector3(0, height / 2.0, 0))
		mm.set_instance_transform(i, t)

		# Aerial perspective: near = green/dark, far = blue/light
		var dist_t := clampf((radius - 500.0) / 700.0, 0.0, 1.0)
		var col: Color = _config.mountain_base_color.lerp(_config.mountain_peak_color, dist_t)
		col = col.lerp(Color(0.6, 0.65, 0.75), dist_t * 0.3)  # Atmospheric haze
		mm.set_instance_color(i, col)

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "Mountains"
	mm_instance.multimesh = mm
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mm_instance)
	_log("Mountains ready: %d cones" % count)


func _setup_river() -> void:
	if not _config.river_enabled or _config.river_width <= 0.0:
		_log("River skipped (disabled or width=0)")
		return

	var gs := float(_config.ground_size) * CELL_SIZE
	var river_length := gs * 1.5  # Extends past visible edges

	var plane := PlaneMesh.new()
	plane.size = Vector2(river_length, _config.river_width)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _config.river_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "River"
	mesh_inst.mesh = plane
	mesh_inst.material_override = mat
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Position at center of ground, offset perpendicular to flow direction
	var center := gs / 2.0
	var angle_rad := deg_to_rad(_config.river_flow_angle)
	var offset_x: float = sin(angle_rad) * _config.river_offset
	var offset_z: float = cos(angle_rad) * _config.river_offset
	mesh_inst.position = Vector3(center + offset_x, 0.02, center + offset_z)
	mesh_inst.rotation_degrees = Vector3(0, _config.river_flow_angle, 0)

	add_child(mesh_inst)
	_log(
		(
			"River ready: width=%.0f angle=%.0f offset=%.0f"
			% [
				_config.river_width,
				_config.river_flow_angle,
				_config.river_offset,
			]
		)
	)


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

	var shader := load("res://shaders/ghost_preview.gdshader") as Shader
	_ghost_material = ShaderMaterial.new()
	_ghost_material.shader = shader
	_ghost_material.set_shader_parameter("is_valid", true)

	# Face direction labels on the ghost block (N/S/E/W/Top)
	var face_dirs := [
		FaceScript.Dir.TOP,
		FaceScript.Dir.NORTH,
		FaceScript.Dir.SOUTH,
		FaceScript.Dir.EAST,
		FaceScript.Dir.WEST,
	]
	for dir in face_dirs:
		var lbl := Label3D.new()
		lbl.text = FaceScript.to_label(dir)
		lbl.font_size = 48
		lbl.pixel_size = 0.04
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.no_depth_test = true
		lbl.modulate = Color(1.0, 1.0, 1.0, 0.85)
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.outline_size = 8
		lbl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost_node.add_child(lbl)
		_ghost_face_labels[dir] = lbl


func _setup_corridor_drag() -> void:
	_corridor_drag_ghost_container = Node3D.new()
	_corridor_drag_ghost_container.name = "CorridorDragGhosts"
	_corridor_drag_ghost_container.visible = false
	add_child(_corridor_drag_ghost_container)


func _setup_face_highlight() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(CELL_SIZE, CELL_SIZE)

	_face_highlight = MeshInstance3D.new()
	_face_highlight.name = "FaceHighlight"
	_face_highlight.mesh = plane
	_face_highlight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var shader := load("res://shaders/face_highlight.gdshader") as Shader
	_face_material = ShaderMaterial.new()
	_face_material.shader = shader
	_face_highlight.material_override = _face_material

	_face_highlight.visible = false
	add_child(_face_highlight)


func _setup_compass_markers() -> void:
	# Place N/S/E/W labels on the ground at the edges of the build zone.
	# Godot convention: NORTH = -Z, SOUTH = +Z, EAST = +X, WEST = -X
	var zone_center_x := (float(build_zone_origin.x) + float(build_zone_size.x) / 2.0) * CELL_SIZE
	var zone_center_z := (float(build_zone_origin.y) + float(build_zone_size.y) / 2.0) * CELL_SIZE
	var half_x := float(build_zone_size.x) / 2.0 * CELL_SIZE
	var half_z := float(build_zone_size.y) / 2.0 * CELL_SIZE
	var marker_y := 2.0  # Slightly above ground

	var markers := {
		"N": Vector3(zone_center_x, marker_y, zone_center_z - half_z - 8.0),
		"S": Vector3(zone_center_x, marker_y, zone_center_z + half_z + 8.0),
		"E": Vector3(zone_center_x + half_x + 8.0, marker_y, zone_center_z),
		"W": Vector3(zone_center_x - half_x - 8.0, marker_y, zone_center_z),
	}

	for text in markers:
		var label := Label3D.new()
		label.text = text
		label.font_size = 72
		label.pixel_size = 0.1
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = Color(0.0, 0.9, 0.9, 0.7)
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		label.outline_size = 12
		label.position = markers[text]
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(label)


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

	_warning_label = Label.new()
	_warning_label.name = "WarningLabel"
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_warning_label.offset_top = 20
	_warning_label.add_theme_font_size_override("font_size", 20)
	_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_warning_label.visible = false
	canvas.add_child(_warning_label)

	# Visibility mode label (below warning label)
	_visibility_label = Label.new()
	_visibility_label.name = "VisibilityLabel"
	_visibility_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_visibility_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_visibility_label.offset_top = 48
	_visibility_label.add_theme_font_size_override("font_size", 18)
	_visibility_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	_visibility_label.visible = false
	canvas.add_child(_visibility_label)

	_face_label = Label.new()
	_face_label.name = "FaceLabel"
	_face_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_face_label.offset_left = 20
	_face_label.offset_top = 20
	_face_label.add_theme_font_size_override("font_size", 16)
	_face_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9))
	_face_label.visible = false
	canvas.add_child(_face_label)

	# Corridor drag info label (top-left, below face label)
	_corridor_drag_label = Label.new()
	_corridor_drag_label.name = "CorridorDragLabel"
	_corridor_drag_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_corridor_drag_label.offset_left = 20
	_corridor_drag_label.offset_top = 42
	_corridor_drag_label.add_theme_font_size_override("font_size", 16)
	_corridor_drag_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_corridor_drag_label.visible = false
	canvas.add_child(_corridor_drag_label)

	_controls_label = Label.new()
	_controls_label.name = "ControlsLabel"
	_controls_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_controls_label.offset_left = 20
	_controls_label.offset_bottom = -60
	_controls_label.add_theme_font_size_override("font_size", 13)
	_controls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_controls_label.text = (
		"LMB: Place  |  RMB: Remove  |  Double-click: Focus  |  ,/.: Rotate\n"
		+ "LMB Drag (corridors): Draw path  |  RMB/ESC: Cancel drag\n"
		+ "Ctrl+LMB: Select  |  Shift+LMB: Add to selection  |  Ctrl+Shift+LMB: Deselect\n"
		+ "WASD: Pan  |  Q/E: Up/Down  |  Scroll: Zoom  |  Shift+RMB: Zoom  |  RMB: Orbit\n"
		+ "Alt+LMB: Orbit around cursor  |  Shift: Precision  |  Ctrl: Boost\n"
		+ "F: Frame  |  H: Home  |  `: Hide UI  |  Tab: Cycle Category  |  1-9: Select Block\n"
		+ "Ctrl+1-9: Save bookmark  |  Alt+1-9: Recall bookmark\n"
		+ "X: X-ray mode  |  [/]: Adjust opacity  |  0/ESC: Normal mode\n"
		+ "F1/?: Help  |  F3: Debug  |  ESC: Pause"
	)
	canvas.add_child(_controls_label)

	# Building stats HUD (top-right, always visible when blocks exist)
	_building_stats_hud = Label.new()
	_building_stats_hud.name = "BuildingStatsHUD"
	_building_stats_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_building_stats_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_building_stats_hud.offset_right = -20
	_building_stats_hud.offset_top = 20
	_building_stats_hud.add_theme_font_size_override("font_size", 15)
	_building_stats_hud.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.85))
	_building_stats_hud.visible = false
	canvas.add_child(_building_stats_hud)

	# Selection label (top-right, below building stats)
	_selection_label = Label.new()
	_selection_label.name = "SelectionLabel"
	_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_selection_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_selection_label.offset_right = -20
	_selection_label.offset_top = 42
	_selection_label.add_theme_font_size_override("font_size", 14)
	_selection_label.add_theme_color_override("font_color", SELECTION_OUTLINE_COLOR)
	_selection_label.visible = false
	canvas.add_child(_selection_label)

	# Entrance prompt label
	_prompt_label = Label.new()
	_prompt_label.name = "EntrancePrompt"
	_prompt_label.text = "Place your entrance to begin building"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt_label.offset_top = -80
	_prompt_label.add_theme_font_size_override("font_size", 28)
	_prompt_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.2))
	_prompt_label.visible = true
	canvas.add_child(_prompt_label)

	_debug_panel = DebugPanelScript.new()
	_debug_panel.name = "DebugPanel"
	_debug_panel.time_changed.connect(_update_sun_for_time)
	_debug_panel.sun_energy_changed.connect(_on_sun_energy_changed)
	_debug_panel.ambient_energy_changed.connect(_on_ambient_energy_changed)
	canvas.add_child(_debug_panel)

	_help_overlay = HelpOverlayScript.new()
	_help_overlay.name = "HelpOverlay"
	canvas.add_child(_help_overlay)

	_pause_menu = PauseMenuScript.new()
	_pause_menu.name = "PauseMenu"
	canvas.add_child(_pause_menu)

	_view_cube = ViewCubeScript.new()
	_view_cube.name = "ViewCube"
	_view_cube.connect_to_camera(_camera)
	canvas.add_child(_view_cube)

	add_child(canvas)

	# Stats section — must come after add_child(canvas) so _ready() has fired
	_debug_panel.add_section("Stats")
	_stats_blocks_label = _debug_panel.add_info_label("Blocks")
	_stats_occupancy_label = _debug_panel.add_info_label("Cells")
	_stats_height_label = _debug_panel.add_info_label("Height")
	_stats_volume_label = _debug_panel.add_info_label("Volume")
	_stats_footprint_label = _debug_panel.add_info_label("Footprint")
	_stats_camera_label = _debug_panel.add_info_label("Camera")
	_stats_mouse_label = _debug_panel.add_info_label("Mouse")
	_log("UI ready (palette, debug panel, help overlay, pause menu)")


func _setup_audio() -> void:
	_place_audio = AudioStreamPlayer.new()
	_place_audio.name = "PlaceAudio"
	_place_audio.volume_db = -6.0
	add_child(_place_audio)

	# Generate a simple procedural click/thud sound
	var sample_rate := 22050
	var duration := 0.08
	var sample_count := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var env := exp(-t * 60.0)  # Fast decay envelope
		var wave := sin(t * 180.0 * TAU) * env  # Low thud at ~180Hz
		wave += sin(t * 400.0 * TAU) * env * 0.3  # Click overtone
		var sample_val := int(clampf(wave, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	audio.data = data
	_place_audio.stream = audio
	_log("Audio ready (procedural click/thud)")


func _setup_lod() -> void:
	_lod_manager = LODManagerScript.new()
	_lod_manager.set_camera(_camera.camera)
	_lod_manager.enable()
	_log("LOD manager ready (thresholds: LOD0<50m, LOD1<150m, LOD2<400m)")


func _setup_visibility_controller() -> void:
	_visibility_controller = VisibilityControllerScript.new()
	_visibility_controller.mode_changed.connect(_on_visibility_mode_changed)
	_visibility_controller.xray_opacity_changed.connect(_on_xray_opacity_changed)
	_visibility_controller.isolate_floor_changed.connect(_on_isolate_floor_changed)
	_log("Visibility controller ready")


func _on_visibility_mode_changed(new_mode: int) -> void:
	_update_visibility_label()
	# When entering X-ray mode, mark all panels as exterior
	if new_mode == VisibilityControllerScript.Mode.XRAY:
		_apply_xray_to_panels(true)
	else:
		_apply_xray_to_panels(false)

	# Update floor navigator for isolate mode
	var floor_nav: Node = _find_floor_navigator()
	if floor_nav:
		if new_mode == VisibilityControllerScript.Mode.ISOLATE:
			floor_nav.set_isolate_mode(true, _visibility_controller.isolate_floor)
		else:
			floor_nav.set_isolate_mode(false)


func _on_xray_opacity_changed(_opacity: float) -> void:
	_update_visibility_label()
	# Update panel transparency if in X-ray mode
	if _visibility_controller.current_mode == VisibilityControllerScript.Mode.XRAY:
		_apply_xray_to_panels(true)


func _on_isolate_floor_changed(floor_num: int) -> void:
	_update_visibility_label()
	# Update floor navigator with new isolated floor
	var floor_nav: Node = _find_floor_navigator()
	if floor_nav and _visibility_controller.current_mode == VisibilityControllerScript.Mode.ISOLATE:
		floor_nav.set_isolate_floor(floor_num)


func _find_floor_navigator() -> Node:
	## Find the FloorNavigator in the scene tree.
	var tree := get_tree()
	if not tree:
		return null
	# Look for FloorNavigator which is typically in the HUD
	var floor_navs := tree.get_nodes_in_group("floor_navigator")
	if floor_navs.size() > 0:
		return floor_navs[0]
	# Fallback: search by name in the tree
	for node in tree.root.get_children():
		var found: Node = _find_node_by_class(node, "FloorNavigator")
		if found:
			return found
	return null


func _find_node_by_class(parent: Node, class_name_str: String) -> Node:
	if parent.get_class() == class_name_str or (parent.has_method("get_floor_text")):
		return parent
	for child in parent.get_children():
		var found: Node = _find_node_by_class(child, class_name_str)
		if found:
			return found
	return null


func _apply_xray_to_panels(enable: bool) -> void:
	## Apply X-ray transparency to all panel materials.
	## Panels are exterior faces by definition.
	var opacity: float = _visibility_controller.xray_opacity if enable else 1.0
	for block_id in placed_blocks:
		var block: RefCounted = placed_blocks[block_id]
		var block_node: Node3D = block.node
		if not block_node:
			continue
		var panels: Node3D = block_node.get_node_or_null("Panels")
		if not panels:
			continue
		for child in panels.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = child.material_override
				if enable:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.albedo_color.a = opacity
				else:
					# Restore original alpha and transparency mode
					var original_alpha: float = mat.get_meta("original_alpha", 1.0)
					var original_transparency: int = mat.get_meta(
						"original_transparency",
						BaseMaterial3D.TRANSPARENCY_DISABLED
					)
					mat.albedo_color.a = original_alpha
					mat.transparency = original_transparency


func _update_visibility_label() -> void:
	if not _visibility_label:
		return
	if not _visibility_controller:
		return
	var status: String = _visibility_controller.get_status_string()
	_visibility_label.text = status
	_visibility_label.visible = status.length() > 0


# --- Process ---


func _process(delta: float) -> void:
	if _config == null:
		return  # Picker showing, world not built yet
	_update_debug_stats()
	if _lod_manager:
		_lod_manager.update()
	var blocked := (
		(_pause_menu and _pause_menu.visible) or (_help_overlay and _help_overlay.visible)
	)
	if blocked:
		_ghost_node.visible = false
		_face_highlight.visible = false
		_face_label.visible = false
		_placing = false
		if _corridor_drag_active:
			_cancel_corridor_drag()
		return
	if _corridor_drag_active:
		_update_corridor_drag_preview()
	else:
		_update_ghost()
		_handle_rapid_fire(delta)


func _update_debug_stats() -> void:
	if not _debug_panel or not _debug_panel.visible:
		return
	_stats_blocks_label.text = "Blocks: %d" % placed_blocks.size()
	_stats_occupancy_label.text = "Cells: %d occupied" % cell_occupancy.size()
	_stats_height_label.text = "Height: %d cells" % _building_height
	_stats_volume_label.text = "Volume: %d cells" % _building_volume
	_stats_footprint_label.text = "Footprint: %d columns" % _building_footprint
	if _camera:
		_stats_camera_label.text = (
			"Cam: (%.0f, %.0f, %.0f) d=%.0f az=%.0f el=%.0f"
			% [
				_camera.target.x,
				_camera.target.y,
				_camera.target.z,
				_camera.distance,
				_camera.azimuth,
				_camera.elevation,
			]
		)


func _handle_rapid_fire(delta: float) -> void:
	if not _placing:
		return
	_place_cooldown -= delta
	if _place_cooldown > 0.0:
		return

	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)), int(round(hit.normal.y)), int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	var collider = hit.get("collider")
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth):
			place_origin = Vector3i(hit.grid_pos.x, top_y + 1, hit.grid_pos.z)

	# Only place if cursor moved to a new cell
	if place_origin == _last_place_origin:
		return

	if place_block(current_definition, place_origin, current_rotation):
		_last_place_origin = place_origin
	_place_cooldown = PLACE_INTERVAL


func _recompute_building_stats() -> void:
	## Recompute height, volume, and footprint from placed blocks.
	## Called on every place/remove — not per-frame.
	if placed_blocks.is_empty():
		_building_height = 0
		_building_volume = 0
		_building_footprint = 0
		_update_building_stats_hud()
		return

	var max_y: int = 0
	var total_cells: int = 0
	var columns: Dictionary = {}  # Vector2i -> true

	for block_id in placed_blocks:
		var block: RefCounted = placed_blocks[block_id]
		for cell in block.occupied_cells:
			# Height: top of the highest cell (cell.y + 1 = top face)
			if cell.y + 1 > max_y:
				max_y = cell.y + 1
			total_cells += 1
			columns[Vector2i(cell.x, cell.z)] = true

	_building_height = max_y
	_building_volume = total_cells
	_building_footprint = columns.size()
	_update_building_stats_hud()
	_log(
		(
			"Building stats: height=%d volume=%d footprint=%d"
			% [
				_building_height,
				_building_volume,
				_building_footprint,
			]
		)
	)


func _update_building_stats_hud() -> void:
	if not _building_stats_hud:
		return
	if placed_blocks.is_empty():
		_building_stats_hud.visible = false
		return
	_building_stats_hud.text = (
		"Blocks: %d  |  Height: %d  |  Volume: %d  |  Footprint: %d"
		% [
			placed_blocks.size(),
			_building_height,
			_building_volume,
			_building_footprint,
		]
	)
	_building_stats_hud.visible = not _ui_hidden


# --- Input ---


func _unhandled_input(event: InputEvent) -> void:
	if _config == null:
		return  # Picker showing, world not built yet
	if (_pause_menu and _pause_menu.visible) or (_help_overlay and _help_overlay.visible):
		return

	if event is InputEventMouseButton:
		# Scroll wheel adjusts X-ray opacity when in X-ray mode
		if _visibility_controller and _visibility_controller.current_mode == VisibilityControllerScript.Mode.XRAY:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				_visibility_controller.adjust_xray_opacity(VisibilityControllerScript.XRAY_OPACITY_STEP)
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				_visibility_controller.adjust_xray_opacity(-VisibilityControllerScript.XRAY_OPACITY_STEP)
				get_viewport().set_input_as_handled()
				return

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Alt+LMB without Ctrl is handled by the camera for orbit-around-cursor
			if event.alt_pressed and not event.ctrl_pressed:
				return
			if event.pressed:
				_log("LMB press at screen %s (double=%s, ctrl=%s, shift=%s, alt=%s)" % [
					event.position, event.double_click, event.ctrl_pressed,
					event.shift_pressed, event.alt_pressed])
				if event.double_click:
					_focus_camera_on_cursor()
				elif event.ctrl_pressed or event.shift_pressed:
					# Selection mode: Ctrl/Shift + click
					_try_select_block(event.ctrl_pressed, event.shift_pressed, event.alt_pressed)
					get_viewport().set_input_as_handled()
				elif CorridorDragScript.is_drag_buildable(current_definition):
					# Corridor drag mode: start drag
					_try_start_corridor_drag()
				else:
					_try_place_block()
					_placing = true
					_place_cooldown = PLACE_INTERVAL
			else:
				if _corridor_drag_active:
					_finish_corridor_drag()
				_placing = false
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _corridor_drag_active:
				_finish_corridor_drag()
			_placing = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			if _corridor_drag_active:
				# Right-click cancels corridor drag
				_cancel_corridor_drag()
				return
			# Right-click release — only arrives here if the camera didn't
			# consume it (meaning it was a tap, not an orbit drag).
			_log("RMB tap at screen %s" % event.position)
			_try_remove_block()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _corridor_drag_active:
			_cancel_corridor_drag()
			get_viewport().set_input_as_handled()
			return
		_log("Key: %s" % OS.get_keycode_string(event.keycode))
		match event.keycode:
			KEY_COMMA:
				_rotate_ccw()
			KEY_PERIOD:
				_rotate_cw()
			KEY_F:
				_focus_camera_on_cursor()
				get_viewport().set_input_as_handled()
			KEY_TAB:
				if event.shift_pressed:
					_palette.cycle_category(-1)
				else:
					_palette.cycle_category(1)
				get_viewport().set_input_as_handled()
			KEY_QUOTELEFT:
				_toggle_ui()
				get_viewport().set_input_as_handled()
			KEY_X:
				# X toggles X-ray visibility mode
				if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
					_visibility_controller.toggle_mode(VisibilityControllerScript.Mode.XRAY)
					get_viewport().set_input_as_handled()
			KEY_I:
				# I toggles floor isolate visibility mode
				if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
					_visibility_controller.toggle_mode(VisibilityControllerScript.Mode.ISOLATE)
					get_viewport().set_input_as_handled()
			KEY_BRACKETLEFT:
				# [ adjusts visibility mode parameter (decrease opacity in X-ray)
				if _visibility_controller.current_mode == VisibilityControllerScript.Mode.XRAY:
					_visibility_controller.adjust_xray_opacity(-VisibilityControllerScript.XRAY_OPACITY_STEP)
					get_viewport().set_input_as_handled()
			KEY_BRACKETRIGHT:
				# ] adjusts visibility mode parameter (increase opacity in X-ray)
				if _visibility_controller.current_mode == VisibilityControllerScript.Mode.XRAY:
					_visibility_controller.adjust_xray_opacity(VisibilityControllerScript.XRAY_OPACITY_STEP)
					get_viewport().set_input_as_handled()
			KEY_0, KEY_ESCAPE:
				# 0 or ESC returns to normal visibility mode (if in a mode)
				if _visibility_controller.current_mode != VisibilityControllerScript.Mode.NORMAL:
					_visibility_controller.set_mode(VisibilityControllerScript.Mode.NORMAL)
					get_viewport().set_input_as_handled()
			KEY_E:
				# E adjusts floor up in visibility modes (cutaway/isolate)
				if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
					if _visibility_controller.current_mode == VisibilityControllerScript.Mode.CUTAWAY:
						_visibility_controller.adjust_cut_floor(1)
						get_viewport().set_input_as_handled()
					elif _visibility_controller.current_mode == VisibilityControllerScript.Mode.ISOLATE:
						_visibility_controller.adjust_isolate_floor(1)
						get_viewport().set_input_as_handled()
			KEY_C:
				# C adjusts floor down in visibility modes (cutaway/isolate)
				if not event.ctrl_pressed and not event.shift_pressed and not event.alt_pressed:
					if _visibility_controller.current_mode == VisibilityControllerScript.Mode.CUTAWAY:
						_visibility_controller.adjust_cut_floor(-1)
						get_viewport().set_input_as_handled()
					elif _visibility_controller.current_mode == VisibilityControllerScript.Mode.ISOLATE:
						_visibility_controller.adjust_isolate_floor(-1)
						get_viewport().set_input_as_handled()
			KEY_PAGEUP:
				# Page Up adjusts floor up in visibility modes
				if _visibility_controller.current_mode == VisibilityControllerScript.Mode.CUTAWAY:
					_visibility_controller.adjust_cut_floor(1)
					get_viewport().set_input_as_handled()
				elif _visibility_controller.current_mode == VisibilityControllerScript.Mode.ISOLATE:
					_visibility_controller.adjust_isolate_floor(1)
					get_viewport().set_input_as_handled()
			KEY_PAGEDOWN:
				# Page Down adjusts floor down in visibility modes
				if _visibility_controller.current_mode == VisibilityControllerScript.Mode.CUTAWAY:
					_visibility_controller.adjust_cut_floor(-1)
					get_viewport().set_input_as_handled()
				elif _visibility_controller.current_mode == VisibilityControllerScript.Mode.ISOLATE:
					_visibility_controller.adjust_isolate_floor(-1)
					get_viewport().set_input_as_handled()
			KEY_1:
				_select_shape_by_index(0)
			KEY_2:
				_select_shape_by_index(1)
			KEY_3:
				_select_shape_by_index(2)
			KEY_4:
				_select_shape_by_index(3)
			KEY_5:
				_select_shape_by_index(4)
			KEY_6:
				_select_shape_by_index(5)
			KEY_7:
				_select_shape_by_index(6)
			KEY_8:
				_select_shape_by_index(7)
			KEY_9:
				_select_shape_by_index(8)


# --- Rotation ---


func _rotate_cw() -> void:
	current_rotation = (current_rotation + 90) % 360
	_log("Rotate CW → %d°" % current_rotation)


func _rotate_ccw() -> void:
	current_rotation = (current_rotation + 270) % 360
	_log("Rotate CCW → %d°" % current_rotation)


# --- Shape Selection ---


func _select_shape_by_index(index: int) -> void:
	# Select block within the current palette category
	var defs: Array = _palette.get_current_category_definitions()
	if index >= 0 and index < defs.size():
		current_definition = defs[index]
		_palette.highlight_definition(current_definition)
		_log("Selected shape: %s" % current_definition.id)


func _on_shape_selected(definition: Resource) -> void:
	current_definition = definition
	_log("Selected shape: %s" % definition.id)


# --- Focus / UI Toggle ---


func _focus_camera_on_cursor() -> void:
	var hit := _raycast_from_mouse()
	if hit.get("hit", false):
		_camera.focus_on(hit.position)
		_log("Focus camera on %s" % hit.position)


func _toggle_ui() -> void:
	_ui_hidden = not _ui_hidden
	_palette.visible = not _ui_hidden
	_controls_label.visible = not _ui_hidden
	if _prompt_label:
		_prompt_label.visible = not _ui_hidden and not _has_entrance
	if _building_stats_hud:
		_building_stats_hud.visible = not _ui_hidden and not placed_blocks.is_empty()
	if _selection_label:
		_selection_label.visible = not _ui_hidden and selection.get_selected_count() > 0
	if _view_cube:
		_view_cube.visible = not _ui_hidden
	_log("UI hidden: %s" % _ui_hidden)


func _update_entrance_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = not _has_entrance and not _ui_hidden


# --- Occupancy ---


func is_cell_occupied(cell: Vector3i) -> bool:
	return cell_occupancy.has(cell)


func is_in_build_zone(x: int, z: int) -> bool:
	return (
		x >= build_zone_origin.x
		and x < build_zone_origin.x + build_zone_size.x
		and z >= build_zone_origin.y
		and z < build_zone_origin.y + build_zone_size.y
	)


func is_cell_buildable(cell: Vector3i) -> bool:
	if is_cell_occupied(cell):
		return false
	if not is_in_build_zone(cell.x, cell.z):
		return false
	return cell.y >= -_config.ground_depth


# --- Grid-compatible API (used by PlacementValidator) ---


func has_block(pos: Vector3i) -> bool:
	## Returns true if a placed block occupies pos (not ground, not empty).
	return cell_occupancy.has(pos) and cell_occupancy[pos] > 0


func get_block_at(pos: Vector3i) -> Variant:
	## Returns block info dict if a placed block occupies pos, null otherwise.
	if not cell_occupancy.has(pos):
		return null
	var bid: int = cell_occupancy[pos]
	if bid <= 0:
		return null
	if not placed_blocks.has(bid):
		return null
	var block: RefCounted = placed_blocks[bid]
	return {
		"block_type": block.definition.id,
		"grid_position": pos,
		"traversability": block.definition.traversability,
	}


func get_all_positions() -> Array:
	## Returns all positions occupied by placed blocks (not ground).
	var positions: Array = []
	for pos in cell_occupancy:
		if cell_occupancy[pos] > 0:
			positions.append(pos)
	return positions


func get_entrance_positions() -> Array[Vector3i]:
	## Returns all cell positions occupied by entrance blocks.
	var positions: Array[Vector3i] = []
	for eid in _entrance_block_ids:
		if placed_blocks.has(eid):
			for cell in placed_blocks[eid].occupied_cells:
				positions.append(cell)
	return positions


func get_excavation_data() -> Dictionary:
	## Returns excavation state for save/load.
	## Includes underground wall system state and excavated cell positions.
	if _underground_wall_system:
		return _underground_wall_system.serialize()
	return {"excavated_cells": []}


func load_excavation_data(data: Dictionary) -> void:
	## Restores excavation state from save data.
	## Call this AFTER ground is set up but BEFORE blocks are placed.
	if _underground_wall_system and data.has("excavated_cells"):
		_underground_wall_system.deserialize(data)


func _is_supported(cells: Array[Vector3i], definition: Resource) -> bool:
	## Entrance blocks: need ground (occupancy -1) directly below at least one cell.
	## All other blocks: need face-adjacency to a placed block (occupancy > 0).
	## Ground does NOT count as support for non-entrance blocks.
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]
	if definition.ground_only:
		# Entrance: needs ground beneath at least one cell
		for cell in cells:
			var below := Vector3i(cell.x, cell.y - 1, cell.z)
			if cell_occupancy.has(below) and cell_occupancy[below] == -1:
				return true
		return false
	# All other blocks: must be face-adjacent to a placed block (not ground)
	for cell in cells:
		for dir in directions:
			var neighbor: Vector3i = cell + dir
			if cell_occupancy.has(neighbor) and cell_occupancy[neighbor] > 0:
				return true
	return false


func can_place_block(definition: Resource, origin: Vector3i, rot: int) -> bool:
	# Entrance-first: must place an entrance before any other block
	if not _has_entrance and definition.id != "entrance":
		_log("  can_place: no entrance placed yet")
		return false
	# Ground-only blocks must be at y=0
	if definition.ground_only and origin.y != 0:
		_log("  can_place: ground_only block at y=%d (must be 0)" % origin.y)
		return false
	var cells: Array[Vector3i] = (
		GridUtilsScript
		. get_occupied_cells(
			definition.size,
			origin,
			rot,
		)
	)
	for cell in cells:
		if is_cell_occupied(cell):
			_log("  can_place: cell %s already occupied" % cell)
			return false
		if not is_in_build_zone(cell.x, cell.z):
			_log("  can_place: cell %s outside build zone" % cell)
			return false
		if cell.y < -_config.ground_depth:
			_log("  can_place: cell %s below ground depth" % cell)
			return false
	# Entrance blocks need ground beneath (Phase 0 rule — ground = occupancy -1)
	if definition.ground_only:
		var has_ground_below := false
		for cell in cells:
			var below := Vector3i(cell.x, cell.y - 1, cell.z)
			if cell_occupancy.has(below) and cell_occupancy[below] == -1:
				has_ground_below = true
				break
		if not has_ground_below:
			_log("  can_place: entrance needs ground beneath")
			return false
		return true
	# Structural validation via core PlacementValidator (cantilever + support)
	if _placement_validator:
		# Non-entrance blocks at ground level still need adjacency to existing blocks
		# (the validator treats y<=0 as always supported structurally, but we need
		# connectivity to the entrance-connected structure)
		if not _is_supported(cells, definition):
			_log("  can_place: no adjacent support for cells %s" % [cells])
			return false
		var result = _placement_validator.validate_multi_cell_placement(cells, definition.id)
		if not result.valid:
			_log("  can_place: validator rejected — %s" % result.reason)
			return false
		return true
	# Fallback: legacy adjacency check (no cantilever enforcement)
	if not _is_supported(cells, definition):
		_log("  can_place: no adjacent support for cells %s" % [cells])
		return false
	return true


func place_block(definition: Resource, origin: Vector3i, rot: int) -> RefCounted:
	if not can_place_block(definition, origin, rot):
		_log(
			(
				"place_block FAILED: %s at %s rot=%d (see reasons above)"
				% [
					definition.id,
					origin,
					rot,
				]
			)
		)
		return null

	# Cost check: deduct from treasury (skip if cost is 0)
	var block_cost: int = definition.cost
	if block_cost > 0 and _game_state and not _game_state.spend_money(block_cost):
		var current_funds: int = _game_state.get_money() if _game_state else 0
		_log("place_block FAILED: cannot afford %s (cost=%d, funds=%d)" % [definition.id, block_cost, current_funds])
		_show_removal_warning("Not enough funds ($%d needed)" % block_cost)
		return null

	var block: RefCounted = PlacedBlockScript.new()
	block.id = next_block_id
	next_block_id += 1
	block.definition = definition
	block.origin = origin
	block.rotation = rot
	block.occupied_cells = (
		GridUtilsScript
		. get_occupied_cells(
			definition.size,
			origin,
			rot,
		)
	)

	for cell in block.occupied_cells:
		cell_occupancy[cell] = block.id

	block.node = _create_block_node(block)
	_block_container.add_child(block.node)

	# Generate panels on exterior faces
	_generate_panels_for_block(block)
	# Generate interior furniture/fixtures (visible in cutaway mode)
	_generate_interiors_for_block(block)
	# Update neighbor blocks' panels (their faces may now be interior)
	_update_neighbor_panels(block)

	_animate_placement(block.node)

	placed_blocks[block.id] = block

	# Register with LOD manager
	if _lod_manager:
		var block_center: Vector3 = GridUtilsScript.grid_to_world_center(block.origin)
		_lod_manager.register_block(block.id, block.node, block_center)

	# Track entrance blocks
	if definition.id == "entrance":
		_entrance_block_ids[block.id] = true
		_has_entrance = true
		_update_entrance_prompt()

	_recompute_building_stats()
	_log(
		(
			"Placed block #%d (%s) at %s rot=%d size=%s — cells: %s"
			% [
				block.id,
				definition.id,
				origin,
				rot,
				definition.size,
				block.occupied_cells,
			]
		)
	)
	return block


func remove_block(block_id: int) -> void:
	if not placed_blocks.has(block_id):
		push_warning("[Sandbox] remove_block: block #%d does not exist" % block_id)
		return

	var block: RefCounted = placed_blocks[block_id]
	_log("Removing block #%d (%s) at %s" % [block_id, block.definition.id, block.origin])

	# Find neighbor blocks that need panel updates BEFORE erasing occupancy
	var affected_ids: Array[int] = PanelSystemScript.get_affected_block_ids(
		block.occupied_cells, cell_occupancy, block_id
	)

	# Refund block cost
	var refund: int = block.definition.cost
	if refund > 0 and _game_state:
		_game_state.add_money(refund)

	for cell in block.occupied_cells:
		cell_occupancy.erase(cell)

	# Update affected neighbors' panels (their faces may now be exterior)
	for nid in affected_ids:
		if placed_blocks.has(nid):
			var neighbor: RefCounted = placed_blocks[nid]
			if is_instance_valid(neighbor.node):
				_regenerate_panels(neighbor)

	# Track entrance removal
	if _entrance_block_ids.has(block_id):
		_entrance_block_ids.erase(block_id)
		_has_entrance = _entrance_block_ids.size() > 0
		_update_entrance_prompt()

	# Unregister from LOD manager
	if _lod_manager:
		_lod_manager.unregister_block(block_id)

	selection.on_block_removed(block_id)
	_animate_removal(block.node)
	placed_blocks.erase(block_id)
	_recompute_building_stats()


func remove_block_at_cell(cell: Vector3i) -> void:
	if cell_occupancy.has(cell):
		remove_block(cell_occupancy[cell])


# --- Structural Integrity ---


func _would_orphan_blocks(block_id: int) -> bool:
	## Check if removing block_id would leave any neighbor blocks disconnected
	## from an entrance. Returns true if removal should be rejected.
	if not placed_blocks.has(block_id):
		return false

	# If this is the only entrance and other blocks exist, reject
	if _entrance_block_ids.has(block_id) and _entrance_block_ids.size() == 1:
		# Allow removal only if no other blocks exist
		if placed_blocks.size() > 1:
			return true

	var block: RefCounted = placed_blocks[block_id]
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]

	# Find all unique neighbor block IDs
	var neighbor_ids: Dictionary = {}
	for cell in block.occupied_cells:
		for dir in directions:
			var neighbor_cell: Vector3i = cell + dir
			if cell_occupancy.has(neighbor_cell):
				var nid: int = cell_occupancy[neighbor_cell]
				if nid != block_id and nid != -1:  # -1 is ground
					neighbor_ids[nid] = true

	# For each neighbor, check if it can still reach an entrance without block_id
	for nid in neighbor_ids:
		if not placed_blocks.has(nid):
			continue
		var neighbor_block: RefCounted = placed_blocks[nid]
		if not _is_connected_to_entrance(neighbor_block.occupied_cells, block_id):
			return true

	return false


func _is_connected_to_entrance(start_cells: Array[Vector3i], excluded_id: int) -> bool:
	## BFS from start_cells through placed blocks (occupancy > 0, skipping excluded_id).
	## Returns true if we can reach any cell belonging to an entrance block.
	var directions: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]

	# Collect all cells belonging to entrance blocks (excluding the one being removed)
	var entrance_cells: Dictionary = {}
	for eid in _entrance_block_ids:
		if eid == excluded_id:
			continue
		if placed_blocks.has(eid):
			for cell in placed_blocks[eid].occupied_cells:
				entrance_cells[cell] = true

	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []

	for cell in start_cells:
		# If this start cell IS an entrance cell, we're connected
		if entrance_cells.has(cell):
			return true
		queue.append(cell)
		visited[cell] = true

	while queue.size() > 0:
		var current: Vector3i = queue.pop_front()

		for dir in directions:
			var neighbor: Vector3i = current + dir
			if visited.has(neighbor):
				continue
			if not cell_occupancy.has(neighbor):
				continue
			var nid: int = cell_occupancy[neighbor]
			if nid == excluded_id or nid == -1 or nid <= 0:
				continue
			# Found an entrance cell
			if entrance_cells.has(neighbor):
				return true
			visited[neighbor] = true
			queue.append(neighbor)

	return false


func _would_orphan_ground_removal(grid_pos: Vector3i) -> bool:
	## Check if removing a ground cell would unseat an entrance block above it.
	## Only entrance blocks sit on ground, so only they can be orphaned by digging.
	var above := Vector3i(grid_pos.x, grid_pos.y + 1, grid_pos.z)
	if not cell_occupancy.has(above):
		return false

	var above_id: int = cell_occupancy[above]
	if above_id == -1:
		return false
	if not placed_blocks.has(above_id):
		return false

	# Only entrance blocks depend on ground for support
	if not _entrance_block_ids.has(above_id):
		return false

	# Check if this entrance has other ground cells beneath it
	var entrance_block: RefCounted = placed_blocks[above_id]
	for cell in entrance_block.occupied_cells:
		var below := Vector3i(cell.x, cell.y - 1, cell.z)
		if below != grid_pos and cell_occupancy.has(below) and cell_occupancy[below] == -1:
			return false  # Still has another ground cell

	return true


func _show_removal_warning(msg: String) -> void:
	_warning_label.text = msg
	_warning_label.visible = true
	_warning_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_warning_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): _warning_label.visible = false)


# --- Block Node Creation ---


func _create_block_node(block: RefCounted) -> Node3D:
	var definition: Resource = block.definition
	var rotation_deg: int = block.rotation
	var effective_size: Vector3i = definition.size
	if rotation_deg == 90 or rotation_deg == 270:
		effective_size = Vector3i(
			definition.size.z,
			definition.size.y,
			definition.size.x,
		)

	var root := Node3D.new()
	root.name = "Block_%d" % block.id

	# Mesh
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _create_mesh_for(definition, effective_size)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = definition.color
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.0
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

	# Top-face name label — fit text within block's top face (5% margin)
	var name_label := Label3D.new()
	name_label.text = definition.display_name
	name_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	name_label.no_depth_test = false
	name_label.render_priority = 10
	name_label.modulate = Color(1.0, 1.0, 1.0, 0.95)
	name_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	name_label.outline_size = 8
	name_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Compute pixel_size so text fits within block's top face.
	# Use the smaller face dimension to constrain pixel_size (ensures height fits).
	# Map the larger dimension to pixel width for word wrapping.
	var face_x: float = float(effective_size.x) * CELL_SIZE
	var face_z: float = float(effective_size.z) * CELL_SIZE
	var available_x: float = face_x * 0.9
	var available_z: float = face_z * 0.9
	var fit_dim: float = minf(available_x, available_z)
	var layout_px: float = 300.0
	name_label.font_size = 64
	name_label.pixel_size = fit_dim / layout_px
	name_label.width = available_x / name_label.pixel_size
	# Position centered on top face, offset above surface to avoid z-fighting
	name_label.position = Vector3(
		center_offset.x,
		float(effective_size.y) * CELL_SIZE + 0.3,
		center_offset.z,
	)
	name_label.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(name_label)

	# Position at grid corner (use position, not global_position, since node isn't in tree yet)
	root.position = GridUtilsScript.grid_to_world(block.origin)

	return root


func _create_mesh_for(_definition: Resource, effective_size: Vector3i) -> Mesh:
	var box := BoxMesh.new()
	box.size = Vector3(effective_size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0
	return box


# --- Panel System ---


func _get_panel_material_type(definition: Resource) -> int:
	## Get the panel material type for a block, using the definition's override
	## or falling back to the category default.
	if definition.panel_material >= 0:
		return definition.panel_material
	return PanelMatScript.get_default_for_category(definition.category)


func _generate_panels_for_block(block: RefCounted) -> void:
	## Generate panel meshes for all exterior faces of a block.
	var panel_mat_type: int = _get_panel_material_type(block.definition)
	PanelSystemScript.create_panel_meshes_for_block(
		block.node,
		block.occupied_cells,
		block.origin,
		cell_occupancy,
		block.id,
		panel_mat_type,
		block.definition.color,
	)


func _generate_interiors_for_block(block: RefCounted) -> void:
	## Generate interior furniture/fixture meshes for cutaway visualization.
	## Passes block size so multi-height blocks get appropriate tall-space interiors.
	var effective_size: Vector3i = block.definition.size
	if block.rotation == 90 or block.rotation == 270:
		effective_size = Vector3i(
			block.definition.size.z,
			block.definition.size.y,
			block.definition.size.x,
		)
	InteriorMeshSystemScript.create_interior_meshes_for_block(
		block.node,
		block.occupied_cells,
		block.origin,
		block.definition.category,
		block.definition.color,
		effective_size,
	)


func _update_neighbor_panels(block: RefCounted) -> void:
	## After placing a block, update panels on all neighboring blocks
	## whose faces may now be interior (shared with the new block).
	var affected_ids: Array[int] = PanelSystemScript.get_affected_block_ids(
		block.occupied_cells, cell_occupancy, block.id
	)
	for nid in affected_ids:
		if placed_blocks.has(nid):
			var neighbor: RefCounted = placed_blocks[nid]
			if is_instance_valid(neighbor.node):
				_regenerate_panels(neighbor)


func _regenerate_panels(block: RefCounted) -> void:
	## Regenerate panels for a block (removing old ones first).
	var panel_mat_type: int = _get_panel_material_type(block.definition)
	PanelSystemScript.update_panels_for_block(
		block.node,
		block.occupied_cells,
		block.origin,
		cell_occupancy,
		block.id,
		panel_mat_type,
		block.definition.color,
	)


func _set_panel_selection_emission(block_node: Node3D, color: Color, energy: float) -> void:
	## Set emission on all panel and interior materials in a block for selection highlight.
	for container_name in ["Panels", "Interiors"]:
		var container: Node3D = block_node.get_node_or_null(container_name)
		if not container:
			continue
		for child in container.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = child.material_override
				mat.emission = color
				mat.emission_energy_multiplier = energy


func _reset_panel_selection_emission(block_node: Node3D) -> void:
	## Reset panel and interior materials to their default emission values after deselection.
	for container_name in ["Panels", "Interiors"]:
		var container: Node3D = block_node.get_node_or_null(container_name)
		if not container:
			continue
		for child in container.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var mat: StandardMaterial3D = child.material_override
				# Restore to default emission (may be non-zero for solar/force_field panels)
				mat.emission = Color.WHITE
				mat.emission_energy_multiplier = 0.0


# --- Placement / Removal Animation ---


func _animate_placement(block_node: Node3D) -> void:
	# Drop-in: start scaled to 0 and offset up, tween to final position
	var final_pos := block_node.position
	block_node.position = final_pos + Vector3(0, CELL_SIZE * 2.0, 0)
	block_node.scale = Vector3(0.01, 0.01, 0.01)

	var tween := create_tween().set_parallel(true)
	(
		tween
		. tween_property(
			block_node,
			"scale",
			Vector3.ONE,
			0.15,
		)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	(
		tween
		. tween_property(
			block_node,
			"position",
			final_pos,
			0.15,
		)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_QUAD)
	)

	# Emission flash on the mesh material
	var mesh_inst: MeshInstance3D = block_node.get_child(0)
	if mesh_inst and mesh_inst.material_override:
		var mat: StandardMaterial3D = mesh_inst.material_override
		mat.emission_energy_multiplier = 0.5
		var flash_tween := create_tween()
		(
			flash_tween
			. tween_property(
				mat,
				"emission_energy_multiplier",
				0.0,
				0.2,
			)
		)

	# Flash panel materials too
	var panels: Node3D = block_node.get_node_or_null("Panels")
	if panels:
		for child in panels.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var pmat: StandardMaterial3D = child.material_override
				pmat.emission_energy_multiplier = 0.5
				var ptween := create_tween()
				ptween.tween_property(pmat, "emission_energy_multiplier", 0.0, 0.2)

	# Play audio
	if _place_audio and _place_audio.stream:
		_place_audio.play()


func _animate_removal(block_node: Node3D) -> void:
	# Disable collision immediately so raycasts don't hit it
	for child in block_node.get_children():
		if child is StaticBody3D:
			child.collision_layer = 0

	# Shrink and drop slightly before freeing
	var tween := create_tween().set_parallel(true)
	(
		tween
		. tween_property(
			block_node,
			"scale",
			Vector3.ZERO,
			0.15,
		)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_BACK)
	)
	(
		tween
		. tween_property(
			block_node,
			"position",
			block_node.position + Vector3(0, -CELL_SIZE, 0),
			0.15,
		)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_QUAD)
	)
	tween.chain().tween_callback(block_node.queue_free)


# --- Ghost Preview ---


func _update_ghost() -> void:
	var hit := _raycast_from_mouse()

	if hit.is_empty() or not hit.get("hit", false):
		_ghost_node.visible = false
		_face_highlight.visible = false
		_face_label.visible = false
		if _stats_mouse_label:
			_stats_mouse_label.text = "Mouse: (no hit)"
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)), int(round(hit.normal.y)), int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	# When hitting ground, snap to the actual top surface
	var collider = hit.get("collider")
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth):
			place_origin = Vector3i(hit.grid_pos.x, top_y + 1, hit.grid_pos.z)

	# Rebuild mesh only when definition or rotation changes
	if _ghost_def_id != current_definition.id or _ghost_rotation != current_rotation:
		_ghost_def_id = current_definition.id
		_ghost_rotation = current_rotation
		_rebuild_ghost_mesh()

	_ghost_node.global_position = GridUtilsScript.grid_to_world(place_origin)

	var valid := can_place_block(current_definition, place_origin, current_rotation)
	_ghost_material.set_shader_parameter("is_valid", valid)
	_ghost_mesh.material_override = _ghost_material

	_ghost_node.visible = true

	# Face highlight — show on the hit surface
	var face: int = hit.get("face", FaceScript.Dir.TOP)
	var cell_center := GridUtilsScript.grid_to_world_center(hit.grid_pos)
	_face_highlight.transform = FaceScript.get_face_transform(face, cell_center, CELL_SIZE)
	_face_highlight.visible = true
	# Show excavation cost preview when hovering over ground
	var excavation_info := ""
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth) and top_y > -_config.ground_depth:
			var excavation_cost: int = ExcavationSystemScript.calculate_excavation_cost(top_y)
			var can_afford: bool = _game_state.can_afford(excavation_cost) if _game_state else true
			var cost_str: String = ExcavationSystemScript.format_cost(excavation_cost)
			var depth_cat: String = ExcavationSystemScript.get_depth_category(top_y)
			excavation_info = "  |  RMB to excavate %s (%s)%s" % [
				depth_cat, cost_str, "" if can_afford else " [Can't afford]"
			]

	_face_label.text = (
		"Face: %s  |  Rotation: %d\u00b0  |  %s%s"
		% [
			FaceScript.to_label(face),
			current_rotation,
			current_definition.display_name,
			excavation_info,
		]
	)
	_face_label.visible = true

	if _stats_mouse_label:
		_stats_mouse_label.text = "Mouse: %s face=%s" % [hit.grid_pos, FaceScript.to_label(face)]


func _rebuild_ghost_mesh() -> void:
	var def_size: Vector3i = current_definition.size
	var effective_size: Vector3i = def_size
	if current_rotation == 90 or current_rotation == 270:
		effective_size = Vector3i(def_size.z, def_size.y, def_size.x)

	_ghost_mesh.mesh = _create_mesh_for(current_definition, effective_size)
	_ghost_mesh.position = Vector3(effective_size) * CELL_SIZE / 2.0

	# Reposition face labels on ghost surfaces.
	# Labels represent the block's LOCAL faces (N/S/E/W/Top at rotation=0).
	# When the block rotates, each label moves to whichever world-space face
	# the block's original face now occupies — so pressing ,/. visibly moves
	# the labels around the block.
	var sx := float(effective_size.x) * CELL_SIZE
	var sy := float(effective_size.y) * CELL_SIZE
	var sz := float(effective_size.z) * CELL_SIZE
	var cx := sx / 2.0
	var cy := sy / 2.0
	var cz := sz / 2.0
	var off := 0.05  # Slight offset from surface
	var rotation_steps := current_rotation / 90

	for local_dir in _ghost_face_labels:
		var lbl: Label3D = _ghost_face_labels[local_dir]
		var world_dir: int = FaceScript.rotate_cw(local_dir, rotation_steps)
		match world_dir:
			FaceScript.Dir.TOP:
				lbl.position = Vector3(cx, sy + off, cz)
				lbl.rotation_degrees = Vector3(-90, 0, 0)
			FaceScript.Dir.NORTH:
				lbl.position = Vector3(cx, cy, -off)
				lbl.rotation_degrees = Vector3(0, 180, 0)
			FaceScript.Dir.SOUTH:
				lbl.position = Vector3(cx, cy, sz + off)
				lbl.rotation_degrees = Vector3(0, 0, 0)
			FaceScript.Dir.EAST:
				lbl.position = Vector3(sx + off, cy, cz)
				lbl.rotation_degrees = Vector3(0, -90, 0)
			FaceScript.Dir.WEST:
				lbl.position = Vector3(-off, cy, cz)
				lbl.rotation_degrees = Vector3(0, 90, 0)


# --- Raycast ---


func _raycast_from_mouse() -> Dictionary:
	var viewport := get_viewport()
	if not viewport:
		push_warning("[Sandbox] Raycast failed: no viewport")
		return {}
	var camera := viewport.get_camera_3d()
	if not camera:
		push_warning("[Sandbox] Raycast failed: no camera")
		return {}

	var mouse_pos := viewport.get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := from + dir * 2000.0

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
			"grid_pos":
			(
				GridUtilsScript
				. world_to_grid(
					hit_pos - hit_normal * 0.01,
				)
			),
			"face": FaceScript.from_normal(hit_normal),
		}

	return {"hit": false}


func _raycast_from_mouse_excluding(exclude_rids: Array[RID]) -> Dictionary:
	## Raycast from mouse position, excluding specific physics bodies.
	## Used for select-through (Alt+click) to ignore the topmost hit.
	var viewport := get_viewport()
	if not viewport:
		return {}
	var camera := viewport.get_camera_3d()
	if not camera:
		return {}

	var mouse_pos := viewport.get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := from + dir * 2000.0

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = exclude_rids

	var result := space.intersect_ray(query)

	if result:
		var hit_pos: Vector3 = result.position
		var hit_normal: Vector3 = result.normal
		return {
			"hit": true,
			"position": hit_pos,
			"normal": hit_normal,
			"collider": result.collider,
			"grid_pos":
			(
				GridUtilsScript
				. world_to_grid(
					hit_pos - hit_normal * 0.01,
				)
			),
			"face": FaceScript.from_normal(hit_normal),
		}

	return {"hit": false}


# --- Placement / Removal ---


func _try_place_block() -> void:
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		_log("Place attempt: no raycast hit")
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)), int(round(hit.normal.y)), int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	# When hitting ground, snap to the actual top surface
	var collider = hit.get("collider")
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth):
			place_origin = Vector3i(hit.grid_pos.x, top_y + 1, hit.grid_pos.z)

	_log(
		(
			"Place attempt: %s at %s rot=%d (hit_grid=%s normal=%s)"
			% [
				current_definition.id,
				place_origin,
				current_rotation,
				hit.grid_pos,
				hit.normal,
			]
		)
	)

	# Show contextual warnings before placement attempt
	if not _has_entrance and current_definition.id != "entrance":
		_show_removal_warning("Place an entrance first!")
		_log("Place REJECTED: no entrance yet")
		return
	if current_definition.ground_only and place_origin.y != 0:
		_show_removal_warning("Entrances must be placed at ground level")
		_log("Place REJECTED: ground_only at y=%d" % place_origin.y)
		return

	var result := place_block(current_definition, place_origin, current_rotation)
	if result == null:
		_log(
			(
				"Place REJECTED: %s at %s rot=%d"
				% [current_definition.id, place_origin, current_rotation]
			)
		)


func _try_remove_block() -> void:
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		_log("Remove attempt: no raycast hit")
		return

	_log("Remove attempt: hit_grid=%s normal=%s" % [hit.grid_pos, hit.normal])

	var collider = hit.collider
	if collider and collider.has_meta("is_ground"):
		if not is_in_build_zone(hit.grid_pos.x, hit.grid_pos.z):
			_log("Remove REJECTED: ground cell %s outside build zone" % hit.grid_pos)
			return
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y < -(_config.ground_depth):
			_log(
				(
					"Remove REJECTED: no ground left at column (%d, %d)"
					% [hit.grid_pos.x, hit.grid_pos.z]
				)
			)
			return
		var cell := Vector3i(hit.grid_pos.x, top_y, hit.grid_pos.z)
		if top_y == -_config.ground_depth:
			_log("Remove REJECTED: bedrock at %s" % cell)
			_show_removal_warning("Cannot remove bedrock")
			return
		if cell_occupancy.has(cell) and cell_occupancy[cell] == -1:
			if _would_orphan_ground_removal(cell):
				_log("Remove REJECTED: ground %s would orphan blocks above" % cell)
				_show_removal_warning("Cannot remove: would leave blocks unsupported")
				return
			# Check excavation cost
			var excavation_cost: int = ExcavationSystemScript.calculate_excavation_cost(cell.y)
			if excavation_cost > 0 and _game_state and not _game_state.can_afford(excavation_cost):
				_log("Excavate REJECTED: cannot afford %d for cell %s" % [excavation_cost, cell])
				_show_removal_warning("Cannot afford excavation (%s)" % ExcavationSystemScript.format_cost(excavation_cost))
				return
			# Deduct cost and excavate
			if excavation_cost > 0 and _game_state:
				_game_state.spend_money(excavation_cost)
				_log("Excavation cost: %s for %s" % [ExcavationSystemScript.format_cost(excavation_cost), cell])
			_log("Removing ground cell %s" % cell)
			_remove_ground_cell(cell)
		return

	var block_id: int = -1
	if collider and collider.has_meta("block_id"):
		block_id = collider.get_meta("block_id")
	elif hit.has("grid_pos") and cell_occupancy.has(hit.grid_pos):
		block_id = cell_occupancy[hit.grid_pos]

	if block_id > 0:
		if _would_orphan_blocks(block_id):
			# Give specific warning for entrance vs generic block
			if _entrance_block_ids.has(block_id) and _entrance_block_ids.size() == 1:
				_log("Remove REJECTED: block #%d is the only entrance" % block_id)
				_show_removal_warning("Cannot remove the only entrance")
			else:
				_log("Remove REJECTED: block #%d would disconnect blocks from entrance" % block_id)
				_show_removal_warning("Cannot remove: would disconnect blocks from entrance")
			return
		# Cantilever orphan check via PlacementValidator
		if _placement_validator and placed_blocks.has(block_id):
			var block: RefCounted = placed_blocks[block_id]
			for cell in block.occupied_cells:
				if _placement_validator.would_orphan_blocks(cell):
					_log("Remove REJECTED: block #%d would leave blocks without structural support" % block_id)
					_show_removal_warning("Cannot remove: would leave blocks unsupported")
					return
		remove_block(block_id)
	else:
		_log("Remove: no block found at hit position")


# --- Corridor Drag-to-Build ---


func _try_start_corridor_drag() -> void:
	## Start a corridor drag from the current mouse raycast position.
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		_log("Corridor drag: no raycast hit — falling back to single placement")
		_try_place_block()
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)), int(round(hit.normal.y)), int(round(hit.normal.z))
	)
	var place_origin: Vector3i = hit.grid_pos + normal_offset

	# When hitting ground, snap to the actual top surface
	var collider = hit.get("collider")
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth):
			place_origin = Vector3i(hit.grid_pos.x, top_y + 1, hit.grid_pos.z)

	_corridor_drag_active = true
	_corridor_drag_start = place_origin
	_corridor_drag_end = place_origin
	_corridor_drag_path = [place_origin]
	_ghost_node.visible = false
	_corridor_drag_ghost_container.visible = true
	_update_corridor_drag_ghosts()
	_log("Corridor drag started at %s" % place_origin)


func _update_corridor_drag_preview() -> void:
	## Called every frame during corridor drag. Updates the path based on current mouse pos.
	var hit := _raycast_from_mouse()
	if hit.is_empty() or not hit.get("hit", false):
		return

	var normal_offset := Vector3i(
		int(round(hit.normal.x)), int(round(hit.normal.y)), int(round(hit.normal.z))
	)
	var drag_end: Vector3i = hit.grid_pos + normal_offset

	# When hitting ground, snap to the actual top surface
	var collider = hit.get("collider")
	if collider and collider.has_meta("is_ground"):
		var top_y := _find_top_ground_y(hit.grid_pos.x, hit.grid_pos.z)
		if top_y >= -(_config.ground_depth):
			drag_end = Vector3i(hit.grid_pos.x, top_y + 1, hit.grid_pos.z)

	# Force same Y as start (horizontal only)
	drag_end.y = _corridor_drag_start.y

	if drag_end == _corridor_drag_end:
		return  # No change

	_corridor_drag_end = drag_end
	_corridor_drag_path = CorridorDragScript.compute_path(_corridor_drag_start, _corridor_drag_end)
	_update_corridor_drag_ghosts()


func _update_corridor_drag_ghosts() -> void:
	## Rebuild the ghost preview meshes for the current drag path.
	# Clear existing ghosts
	for ghost in _corridor_drag_ghosts:
		ghost.queue_free()
	_corridor_drag_ghosts.clear()

	if _corridor_drag_path.is_empty():
		_corridor_drag_ghost_container.visible = false
		_update_corridor_drag_label(0, 0, 0)
		return

	# Validate the path
	var validation := CorridorDragScript.validate_path(
		_corridor_drag_path,
		current_definition,
		cell_occupancy,
		_has_entrance,
		build_zone_origin,
		build_zone_size,
		_config.ground_depth,
	)

	var valid_cells: Array = validation.valid
	var invalid_cells: Array = validation.invalid
	var cost: int = validation.cost

	var ghost_shader := load("res://shaders/ghost_preview.gdshader") as Shader

	# Create ghost mesh for each cell in the path
	for cell in _corridor_drag_path:
		# Skip occupied cells (auto-junction: they'll be left as-is)
		if cell_occupancy.has(cell):
			continue

		var ghost := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0
		ghost.mesh = box

		var mat := ShaderMaterial.new()
		mat.shader = ghost_shader
		var is_valid: bool = valid_cells.has(cell)
		mat.set_shader_parameter("is_valid", is_valid)
		ghost.material_override = mat

		ghost.position = GridUtilsScript.grid_to_world_center(cell)
		_corridor_drag_ghost_container.add_child(ghost)
		_corridor_drag_ghosts.append(ghost)

	_corridor_drag_ghost_container.visible = true
	var skipped: int = 0
	for cell in _corridor_drag_path:
		if cell_occupancy.has(cell):
			skipped += 1
	_update_corridor_drag_label(valid_cells.size(), invalid_cells.size(), cost)


func _update_corridor_drag_label(valid_count: int, invalid_count: int, cost: int) -> void:
	## Update the HUD label showing corridor drag info.
	if not _corridor_drag_label:
		return
	if not _corridor_drag_active:
		_corridor_drag_label.visible = false
		return
	var total: int = valid_count + invalid_count
	if total == 0:
		_corridor_drag_label.text = "Drag to draw corridor path"
	elif invalid_count > 0:
		_corridor_drag_label.text = "Corridor: %d cells ($%d) — %d invalid" % [total, cost, invalid_count]
	else:
		_corridor_drag_label.text = "Corridor: %d cells ($%d)" % [total, cost]
	_corridor_drag_label.visible = not _ui_hidden


func _finish_corridor_drag() -> void:
	## Place all valid cells in the corridor drag path and clean up.
	if not _corridor_drag_active:
		return

	_log("Corridor drag finished: %d cells in path" % _corridor_drag_path.size())

	if _corridor_drag_path.size() <= 1:
		# Single cell — just do a normal placement
		if _corridor_drag_path.size() == 1:
			var origin: Vector3i = _corridor_drag_path[0]
			if can_place_block(current_definition, origin, current_rotation):
				place_block(current_definition, origin, current_rotation)
		_cancel_corridor_drag()
		return

	# Validate and place
	var validation := CorridorDragScript.validate_path(
		_corridor_drag_path,
		current_definition,
		cell_occupancy,
		_has_entrance,
		build_zone_origin,
		build_zone_size,
		_config.ground_depth,
	)

	var placed_count: int = 0
	for cell in validation.valid:
		# Double-check cell is still free (earlier placements in this loop may affect it)
		if cell_occupancy.has(cell):
			continue
		var result := place_block(current_definition, cell, 0)
		if result != null:
			placed_count += 1

	_log("Corridor drag placed %d blocks" % placed_count)
	_cancel_corridor_drag()


func _cancel_corridor_drag() -> void:
	## Cancel corridor drag and clean up preview.
	_corridor_drag_active = false
	_corridor_drag_path.clear()

	for ghost in _corridor_drag_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_corridor_drag_ghosts.clear()
	_corridor_drag_ghost_container.visible = false

	if _corridor_drag_label:
		_corridor_drag_label.visible = false
	_log("Corridor drag cancelled/ended")


# --- Selection ---


func _try_select_block(ctrl: bool, shift: bool, alt: bool) -> void:
	## Handle selection click with modifier keys.
	## Ctrl+click = select/toggle single block
	## Shift+click = add to selection
	## Ctrl+Shift+click = explicitly remove from selection
	## Ctrl+Alt+click = select-through (ignore topmost, pick block behind)
	var hit: Dictionary
	if alt:
		# Select-through: first raycast to find topmost, then exclude it
		var first_hit := _raycast_from_mouse()
		if first_hit.is_empty() or not first_hit.get("hit", false):
			_log("Select-through: no first hit")
			selection.clear()
			return
		var exclude_collider = first_hit.get("collider")
		if exclude_collider and exclude_collider is CollisionObject3D:
			hit = _raycast_from_mouse_excluding([exclude_collider.get_rid()])
		else:
			hit = first_hit
	else:
		hit = _raycast_from_mouse()

	if hit.is_empty() or not hit.get("hit", false):
		_log("Select: no hit — clearing selection")
		selection.clear()
		return

	var collider = hit.get("collider")

	# Clicking on ground or empty space = clear selection
	if not collider or (collider and collider.has_meta("is_ground")):
		_log("Select: hit ground — clearing selection")
		selection.clear()
		return

	# Find the block_id from the collider
	var block_id: int = -1
	if collider.has_meta("block_id"):
		block_id = collider.get_meta("block_id")
	elif hit.has("grid_pos") and cell_occupancy.has(hit.grid_pos):
		block_id = cell_occupancy[hit.grid_pos]

	if block_id <= 0:
		_log("Select: no valid block at hit — clearing selection")
		selection.clear()
		return

	if ctrl and shift:
		# Ctrl+Shift+click = explicitly remove from selection
		_log("Select: Ctrl+Shift+click — removing block #%d from selection" % block_id)
		selection.remove_from_selection(block_id)
	elif shift:
		# Shift+click = add to selection
		_log("Select: Shift+click — adding block #%d to selection" % block_id)
		selection.add_to_selection(block_id)
	elif ctrl:
		# Ctrl+click = toggle (select if not selected, deselect if selected)
		if selection.is_selected(block_id):
			_log("Select: Ctrl+click — toggling OFF block #%d" % block_id)
			selection.remove_from_selection(block_id)
		else:
			_log("Select: Ctrl+click — selecting block #%d" % block_id)
			selection.select(block_id)


func _on_block_selected(block_id: int) -> void:
	## Apply selection highlight to a block.
	if not placed_blocks.has(block_id):
		return
	var block: RefCounted = placed_blocks[block_id]
	if not is_instance_valid(block.node):
		return
	var mesh_inst: MeshInstance3D = block.node.get_child(0)
	if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh_inst.material_override
		mat.emission = SELECTION_OUTLINE_COLOR
		mat.emission_energy_multiplier = SELECTION_EMISSION_ENERGY
	# Also highlight panel materials
	_set_panel_selection_emission(block.node, SELECTION_OUTLINE_COLOR, SELECTION_EMISSION_ENERGY)
	_update_selection_label()


func _on_block_deselected(block_id: int) -> void:
	## Remove selection highlight from a block.
	if not placed_blocks.has(block_id):
		return
	var block: RefCounted = placed_blocks[block_id]
	if not is_instance_valid(block.node):
		return
	var mesh_inst: MeshInstance3D = block.node.get_child(0)
	if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh_inst.material_override
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 0.0
	# Reset panel emission to their default values
	_reset_panel_selection_emission(block.node)
	_update_selection_label()


func _update_selection_label() -> void:
	## Update the selection count HUD label.
	if not _selection_label:
		return
	var count: int = selection.get_selected_count()
	if count == 0:
		_selection_label.visible = false
	else:
		_selection_label.visible = not _ui_hidden
		if count == 1:
			var ids: Array[int] = selection.get_selected_ids()
			var block: RefCounted = placed_blocks.get(ids[0])
			if block:
				_selection_label.text = "Selected: %s (#%d)" % [block.definition.display_name, block.id]
			else:
				_selection_label.text = "Selected: 1 block"
		else:
			_selection_label.text = "Selected: %d blocks" % count


# --- Debug Panel / Time of Day ---


func _update_sun_for_time(hour: float) -> void:
	# Sun elevation: sine curve — noon (12) is highest, dawn (6) and dusk (18) at horizon.
	# Night hours (before 6, after 18) push sun below horizon.
	var day_progress := (hour - 6.0) / 12.0  # 0 at dawn, 1 at dusk
	var elevation: float
	if hour >= 6.0 and hour <= 18.0:
		elevation = -75.0 * sin(day_progress * PI)
	else:
		elevation = 5.0  # Below horizon

	# Azimuth: east at dawn → south at noon → west at dusk
	var azimuth := lerpf(90.0, -90.0, clampf(day_progress, 0.0, 1.0)) + 30.0

	_sun.rotation_degrees = Vector3(elevation, azimuth, 0.0)

	# Sun energy fades near horizon, zero at night
	var sun_energy: float
	if hour < 6.0 or hour > 18.0:
		sun_energy = 0.0
	elif hour < 7.0:
		sun_energy = (hour - 6.0) * 1.2  # Fade in over first hour
	elif hour > 17.0:
		sun_energy = (18.0 - hour) * 1.2  # Fade out over last hour
	else:
		sun_energy = 1.2
	_sun.light_energy = sun_energy

	# Ambient energy: lower at night
	var ambient: float
	if hour < 6.0 or hour > 18.0:
		ambient = 0.1
	elif hour < 7.0:
		ambient = lerpf(0.1, 0.5, hour - 6.0)
	elif hour > 17.0:
		ambient = lerpf(0.5, 0.1, hour - 17.0)
	else:
		ambient = 0.5
	_environment.ambient_light_energy = ambient

	# Sky color palette: day, dawn/dusk, night
	var day_top := Color(0.35, 0.55, 0.85)
	var day_horizon := Color(0.6, 0.75, 0.9)
	var dawn_top := Color(0.3, 0.25, 0.5)
	var dawn_horizon := Color(0.85, 0.5, 0.3)
	var night_top := Color(0.05, 0.05, 0.15)
	var night_horizon := Color(0.1, 0.1, 0.2)

	var sky_top: Color
	var sky_horizon: Color
	if hour < 6.0 or hour > 18.0:
		sky_top = night_top
		sky_horizon = night_horizon
	elif hour < 7.5:
		var t := (hour - 6.0) / 1.5
		sky_top = dawn_top.lerp(day_top, t)
		sky_horizon = dawn_horizon.lerp(day_horizon, t)
	elif hour > 16.5:
		var t := (hour - 16.5) / 1.5
		sky_top = day_top.lerp(dawn_top, t)
		sky_horizon = day_horizon.lerp(dawn_horizon, t)
	else:
		sky_top = day_top
		sky_horizon = day_horizon

	_sky_material.sky_top_color = sky_top
	_sky_material.sky_horizon_color = sky_horizon

	# Ground colors follow a similar shift
	var day_ground_bottom := Color(0.25, 0.35, 0.2)
	var day_ground_horizon := Color(0.55, 0.7, 0.5)
	var night_ground := Color(0.05, 0.08, 0.05)
	if hour < 6.0 or hour > 18.0:
		_sky_material.ground_bottom_color = night_ground
		_sky_material.ground_horizon_color = night_ground
	elif hour < 7.5:
		var t := (hour - 6.0) / 1.5
		_sky_material.ground_bottom_color = night_ground.lerp(day_ground_bottom, t)
		_sky_material.ground_horizon_color = night_ground.lerp(day_ground_horizon, t)
	elif hour > 16.5:
		var t := (hour - 16.5) / 1.5
		_sky_material.ground_bottom_color = day_ground_bottom.lerp(night_ground, t)
		_sky_material.ground_horizon_color = day_ground_horizon.lerp(night_ground, t)
	else:
		_sky_material.ground_bottom_color = day_ground_bottom
		_sky_material.ground_horizon_color = day_ground_horizon

	# Fog color shifts with sky
	_environment.fog_light_color = sky_horizon.lerp(Color(0.55, 0.62, 0.72), 0.5)


func _on_sun_energy_changed(energy: float) -> void:
	_sun.light_energy = energy


func _on_ambient_energy_changed(energy: float) -> void:
	_environment.ambient_light_energy = energy
