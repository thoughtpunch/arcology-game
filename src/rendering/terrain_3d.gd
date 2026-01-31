extends Node3D

## 3D Terrain system — procedural ground plane with theme-specific materials.
## Renders at Y=0 (and below for strata layers), covers scenario area with collision.
##
## Usage:
##   var terrain = Terrain3D.new()
##   terrain.configure(config)  # ScenarioConfig or similar
##   terrain.generate()
##   add_child(terrain)
##
## Supports themes: EARTH (grass), MARS (regolith), SPACE (metal deck)

signal cell_removed(grid_pos: Vector3i)

enum TerrainTheme { EARTH, MARS, SPACE }

const GridUtilsScript = preload("res://src/phase0/grid_utils.gd")
const CELL_SIZE: float = 6.0

# --- Configuration ---
var theme: TerrainTheme = TerrainTheme.EARTH
var grid_size: Vector2i = Vector2i(100, 100)  # cells in X and Z
var ground_depth: int = 5  # number of strata layers below Y=0

# Custom strata colors (optional; defaults based on theme)
var strata_colors: Array[Color] = []

# --- Internal State ---
var _ground_layers: Array[MultiMeshInstance3D] = []
var _ground_cell_indices: Array[Dictionary] = []  # per-layer Vector2i(x,z) -> int
var _collision_body: StaticBody3D
var _cell_occupancy: Dictionary = {}  # Vector3i -> bool (true = exists)


func _ready() -> void:
	# If configure() wasn't called, generate with defaults
	if _ground_layers.is_empty():
		generate()


func configure(config: RefCounted) -> void:
	## Configure terrain from a ScenarioConfig-like object.
	## Expects properties: ground_size (int), ground_depth (int), strata_colors (Array[Color])
	if config.get("ground_size") != null:
		grid_size = Vector2i(config.ground_size, config.ground_size)
	if config.get("ground_depth") != null:
		ground_depth = config.ground_depth
	if config.get("strata_colors") != null and config.strata_colors.size() > 0:
		strata_colors = config.strata_colors


func configure_from_dict(settings: Dictionary) -> void:
	## Configure terrain from a dictionary of settings.
	if settings.has("theme"):
		theme = settings.theme as TerrainTheme
	if settings.has("grid_size"):
		grid_size = settings.grid_size as Vector2i
	if settings.has("ground_depth"):
		ground_depth = settings.ground_depth as int
	if settings.has("strata_colors"):
		strata_colors.assign(settings.strata_colors)


func generate() -> void:
	## Generate the terrain mesh, materials, and collision.
	## Call after configure() or with default settings.
	_clear()
	_generate_strata_layers()
	_generate_collision()


func _clear() -> void:
	## Remove all existing terrain geometry.
	for layer in _ground_layers:
		layer.queue_free()
	_ground_layers.clear()
	_ground_cell_indices.clear()
	_cell_occupancy.clear()
	if _collision_body:
		_collision_body.queue_free()
		_collision_body = null


func _generate_strata_layers() -> void:
	## Create MultiMesh layers for each stratum (y=-1 through y=-ground_depth).
	var colors := _get_strata_colors()
	var cell_count := grid_size.x * grid_size.y
	var mesh := _make_cell_mesh()

	for layer_idx in range(ground_depth):
		var y_level: int = -(layer_idx + 1)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[layer_idx]
		mat.roughness = _get_roughness_for_theme()
		mat.metallic = _get_metallic_for_theme()

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = cell_count
		mm.mesh = mesh

		var cell_index: Dictionary = {}
		var idx := 0
		for x in range(grid_size.x):
			for z in range(grid_size.y):
				var grid_pos := Vector3i(x, y_level, z)
				var center := GridUtilsScript.grid_to_world_center(grid_pos)
				mm.set_instance_transform(idx, Transform3D(Basis(), center))
				cell_index[Vector2i(x, z)] = idx
				_cell_occupancy[grid_pos] = true
				idx += 1

		var mm_instance := MultiMeshInstance3D.new()
		mm_instance.name = "StrataLayer_%d" % layer_idx
		mm_instance.multimesh = mm
		mm_instance.material_override = mat
		add_child(mm_instance)

		_ground_layers.append(mm_instance)
		_ground_cell_indices.append(cell_index)


func _generate_collision() -> void:
	## Create a single StaticBody3D covering the full terrain slab.
	_collision_body = StaticBody3D.new()
	_collision_body.name = "TerrainCollision"
	_collision_body.collision_layer = 1
	_collision_body.set_meta("is_ground", true)
	_collision_body.set_meta("is_terrain", true)

	var total_size_x := float(grid_size.x) * CELL_SIZE
	var total_size_z := float(grid_size.y) * CELL_SIZE
	var total_depth := float(ground_depth) * CELL_SIZE

	var col_shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(total_size_x, total_depth, total_size_z)
	col_shape.shape = col_box
	col_shape.position = Vector3(total_size_x / 2.0, -total_depth / 2.0, total_size_z / 2.0)
	_collision_body.add_child(col_shape)
	add_child(_collision_body)


func _make_cell_mesh() -> Mesh:
	## Create a single cell mesh (6m cube).
	var box := BoxMesh.new()
	box.size = Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE)
	return box


func _get_strata_colors() -> Array[Color]:
	## Get strata colors for the current theme. Uses custom colors if set.
	if strata_colors.size() >= ground_depth:
		return strata_colors

	match theme:
		TerrainTheme.EARTH:
			return _get_earth_colors()
		TerrainTheme.MARS:
			return _get_mars_colors()
		TerrainTheme.SPACE:
			return _get_space_colors()
		_:
			return _get_earth_colors()


func _get_earth_colors() -> Array[Color]:
	## Earth theme: grass -> soil -> clay -> rock -> bedrock
	var colors: Array[Color] = [
		Color(0.3, 0.55, 0.2),  # y=-1: Grass/topsoil
		Color(0.55, 0.35, 0.2),  # y=-2: Soil
		Color(0.4, 0.25, 0.15),  # y=-3: Clay
		Color(0.5, 0.5, 0.5),  # y=-4: Rock
		Color(0.3, 0.3, 0.3),  # y=-5: Bedrock
	]
	# Extend if more depth needed
	while colors.size() < ground_depth:
		colors.append(Color(0.25, 0.25, 0.25))
	return colors


func _get_mars_colors() -> Array[Color]:
	## Mars theme: red-brown regolith with rocky underlayers
	var colors: Array[Color] = [
		Color(0.6, 0.3, 0.2),  # y=-1: Surface regolith (rust red)
		Color(0.5, 0.28, 0.18),  # y=-2: Subsurface (darker red-brown)
		Color(0.45, 0.25, 0.15),  # y=-3: Deep regolith
		Color(0.4, 0.35, 0.3),  # y=-4: Rocky layer (grey-brown)
		Color(0.35, 0.3, 0.28),  # y=-5: Bedrock (dark grey)
	]
	while colors.size() < ground_depth:
		colors.append(Color(0.3, 0.28, 0.25))
	return colors


func _get_space_colors() -> Array[Color]:
	## Space theme: metal deck with industrial underlayers
	var colors: Array[Color] = [
		Color(0.45, 0.48, 0.5),  # y=-1: Surface deck (brushed steel)
		Color(0.35, 0.38, 0.4),  # y=-2: Secondary deck
		Color(0.3, 0.32, 0.35),  # y=-3: Infrastructure layer
		Color(0.25, 0.27, 0.3),  # y=-4: Hull plating
		Color(0.2, 0.22, 0.25),  # y=-5: Hull core
	]
	while colors.size() < ground_depth:
		colors.append(Color(0.18, 0.2, 0.22))
	return colors


func _get_roughness_for_theme() -> float:
	match theme:
		TerrainTheme.EARTH:
			return 0.9  # Matte natural surface
		TerrainTheme.MARS:
			return 0.85  # Slightly dusty
		TerrainTheme.SPACE:
			return 0.4  # Metallic sheen
		_:
			return 0.9


func _get_metallic_for_theme() -> float:
	match theme:
		TerrainTheme.EARTH:
			return 0.0
		TerrainTheme.MARS:
			return 0.05  # Slight iron oxide reflection
		TerrainTheme.SPACE:
			return 0.6  # Metal deck
		_:
			return 0.0


# --- Cell Query API ---


func is_cell_occupied(grid_pos: Vector3i) -> bool:
	## Returns true if a terrain cell exists at the given position.
	return _cell_occupancy.has(grid_pos)


func get_cell_at(grid_pos: Vector3i) -> bool:
	## Alias for is_cell_occupied.
	return is_cell_occupied(grid_pos)


func find_top_ground_y(x: int, z: int) -> int:
	## Scans y=-1 to y=-ground_depth, returns topmost occupied ground cell Y.
	## Returns a value below all layers if no ground exists at this column.
	for y in range(-1, -(ground_depth + 1), -1):
		if _cell_occupancy.has(Vector3i(x, y, z)):
			return y
	return -(ground_depth + 1)


func get_world_size() -> Vector3:
	## Returns the total world-space size of the terrain.
	return Vector3(
		float(grid_size.x) * CELL_SIZE,
		float(ground_depth) * CELL_SIZE,
		float(grid_size.y) * CELL_SIZE
	)


func get_world_center() -> Vector3:
	## Returns the world-space center of the terrain surface (at Y=0).
	return Vector3(float(grid_size.x) * CELL_SIZE / 2.0, 0.0, float(grid_size.y) * CELL_SIZE / 2.0)


# --- Cell Removal (Excavation) ---


func remove_cell(grid_pos: Vector3i) -> bool:
	## Remove a terrain cell (for excavation). Returns true if removed.
	## Does NOT remove bedrock (bottom layer).
	var layer_idx: int = -(grid_pos.y + 1)
	if layer_idx < 0 or layer_idx >= ground_depth:
		return false

	# Bedrock protection: cannot remove bottom layer
	if layer_idx == ground_depth - 1:
		return false

	var key := Vector2i(grid_pos.x, grid_pos.z)
	if not _ground_cell_indices[layer_idx].has(key):
		return false

	if not _cell_occupancy.has(grid_pos):
		return false

	# Remove from occupancy
	_cell_occupancy.erase(grid_pos)

	# Hide by moving far off-screen
	var idx: int = _ground_cell_indices[layer_idx][key]
	_ground_layers[layer_idx].multimesh.set_instance_transform(
		idx, Transform3D(Basis(), Vector3(0, -10000, 0))
	)
	_ground_cell_indices[layer_idx].erase(key)

	cell_removed.emit(grid_pos)
	return true


func is_bedrock(grid_pos: Vector3i) -> bool:
	## Returns true if the position is at the bedrock (bottom) layer.
	return grid_pos.y == -ground_depth
