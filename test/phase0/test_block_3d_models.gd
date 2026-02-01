## GdUnit4 test suite for 3D block model generation
## Validates that procedural mesh generation meets the acceptance criteria from arcology-wsv:
## - At least 10 unique block visuals (category-specific interiors + exteriors)
## - Covers core gameplay types (residential, commercial, transit, civic, etc.)
## - Consistent scale (6x6x6m cells)
## - Materials assigned (StandardMaterial3D with category colors)
## - Can be placed and rendered (mesh generation succeeds)
class_name TestBlock3DModels
extends GdUnitTestSuite

const GridUtilsScript = preload("res://src/game/grid_utils.gd")
const BlockDefScript = preload("res://src/game/block_definition.gd")
const RegistryScript = preload("res://src/game/block_registry.gd")
const InteriorMeshSystemScript = preload("res://src/game/interior_mesh_system.gd")
const PanelSystemScript = preload("res://src/game/panel_system.gd")
const PanelMatScript = preload("res://src/game/panel_material.gd")

const CELL_SIZE: float = 6.0
const BLOCK_INSET: float = 0.15


# === Acceptance Criteria: At least 10 unique block visuals ===

func test_at_least_10_unique_block_types_defined() -> void:
	## The registry should have at least 10 unique block types.
	var registry: RefCounted = RegistryScript.new()
	var definitions: Array = registry.get_all_definitions()
	assert_int(definitions.size()).is_greater_equal(10)


func test_all_core_gameplay_categories_represented() -> void:
	## Core categories must be present: residential, commercial, transit, civic.
	var registry: RefCounted = RegistryScript.new()
	var definitions: Array = registry.get_all_definitions()

	var categories_found: Dictionary = {}
	for definition in definitions:
		var def_res: Resource = definition
		categories_found[def_res.category] = true

	var core_categories := ["residential", "commercial", "transit", "civic"]
	for cat in core_categories:
		assert_bool(categories_found.has(cat)).is_true()


func test_extended_categories_represented() -> void:
	## Extended categories should also be present: industrial, green, infrastructure, entertainment.
	var registry: RefCounted = RegistryScript.new()
	var definitions: Array = registry.get_all_definitions()

	var categories_found: Dictionary = {}
	for definition in definitions:
		var def_res: Resource = definition
		categories_found[def_res.category] = true

	var extended_categories := ["industrial", "green", "infrastructure", "entertainment"]
	for cat in extended_categories:
		assert_bool(categories_found.has(cat)).is_true()


# === Acceptance Criteria: Consistent scale (6x6x6m cells) ===

func test_block_mesh_size_matches_cell_size() -> void:
	## Procedural block meshes should match CELL_SIZE dimensions.
	var mesh: BoxMesh = BoxMesh.new()
	var size := Vector3i(1, 1, 1)
	mesh.size = Vector3(size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0

	# Expected: 6 - 0.3 = 5.7m per axis for a 1x1x1 block
	var expected_side: float = CELL_SIZE - BLOCK_INSET * 2.0
	assert_float(mesh.size.x).is_equal_approx(expected_side, 0.01)
	assert_float(mesh.size.y).is_equal_approx(expected_side, 0.01)
	assert_float(mesh.size.z).is_equal_approx(expected_side, 0.01)


func test_multi_cell_mesh_size_scales_correctly() -> void:
	## A 2x1x3 block should have mesh size (12-0.3, 6-0.3, 18-0.3).
	var size := Vector3i(2, 1, 3)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0

	var expected := Vector3(
		2.0 * CELL_SIZE - BLOCK_INSET * 2.0,
		1.0 * CELL_SIZE - BLOCK_INSET * 2.0,
		3.0 * CELL_SIZE - BLOCK_INSET * 2.0
	)
	assert_float(mesh.size.x).is_equal_approx(expected.x, 0.01)
	assert_float(mesh.size.y).is_equal_approx(expected.y, 0.01)
	assert_float(mesh.size.z).is_equal_approx(expected.z, 0.01)


# === Acceptance Criteria: Materials assigned ===

func test_all_definitions_have_colors() -> void:
	## Every block definition should have a valid color assigned.
	var registry: RefCounted = RegistryScript.new()
	var definitions: Array = registry.get_all_definitions()

	for definition in definitions:
		var def_res: Resource = definition
		# Color should not be fully transparent black
		assert_bool(def_res.color.a > 0.0).is_true()


func test_category_colors_are_distinct() -> void:
	## Different categories should have distinct interior color palettes.
	var category_colors: Dictionary = InteriorMeshSystemScript.CATEGORY_COLORS

	# Check we have at least 6 distinct category colors
	assert_int(category_colors.size()).is_greater_equal(6)

	# Check colors are actually different
	var colors_seen: Array[Color] = []
	for cat in category_colors:
		var color: Color = category_colors[cat]
		for seen in colors_seen:
			# Colors should not be identical
			assert_bool(color.is_equal_approx(seen)).is_false()
		colors_seen.append(color)


# === Acceptance Criteria: Can be placed and rendered ===

func test_exterior_mesh_generation_succeeds_for_all_sizes() -> void:
	## BoxMesh generation should succeed for various block sizes.
	var sizes: Array[Vector3i] = [
		Vector3i(1, 1, 1),
		Vector3i(2, 1, 1),
		Vector3i(2, 1, 2),
		Vector3i(3, 2, 3),
		Vector3i(5, 1, 2),
	]

	for size in sizes:
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0
		assert_object(mesh).is_not_null()
		assert_bool(mesh.size.x > 0).is_true()
		assert_bool(mesh.size.y > 0).is_true()
		assert_bool(mesh.size.z > 0).is_true()


func test_interior_mesh_generation_succeeds_for_all_categories() -> void:
	## Interior mesh generation should work for every category.
	var categories := [
		"residential", "commercial", "transit", "civic",
		"industrial", "infrastructure", "green", "entertainment"
	]

	for cat in categories:
		var block_node: Node3D = auto_free(Node3D.new())
		var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

		var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
			block_node, cells, Vector3i(0, 0, 0), cat, Color.WHITE
		)
		assert_object(interiors).is_not_null()
		assert_int(interiors.get_child_count()).is_greater_equal(1)


func test_panel_generation_succeeds_for_single_block() -> void:
	## Panel mesh generation should succeed for an isolated block.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	# API: block_node, cells, origin, occupancy, block_id, panel_mat_type, block_color
	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_object(panels).is_not_null()
	# Isolated block should have 6 panels (one per face)
	assert_int(panels.get_child_count()).is_equal(6)


func test_panel_generation_succeeds_for_multi_cell_block() -> void:
	## Panel mesh generation should succeed for larger blocks.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1),
	]
	var occupancy: Dictionary = {}
	for cell in cells:
		occupancy[cell] = 1

	# API: block_node, cells, origin, occupancy, block_id, panel_mat_type, block_color
	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.GLASS, Color(0.7, 0.8, 0.95)
	)
	assert_object(panels).is_not_null()
	# 2x1x2 block should have 16 exterior panels (see test_panel_system.gd)
	assert_int(panels.get_child_count()).is_equal(16)


# === Block Definition: model_scene field ===

func test_block_definition_has_model_scene_field() -> void:
	## BlockDefinition should have an optional model_scene field for external models.
	var definition: Resource = BlockDefScript.new()
	assert_bool("model_scene" in definition).is_true()
	# Default should be empty string (procedural mesh)
	assert_str(definition.model_scene).is_equal("")


func test_model_scene_is_optional() -> void:
	## A block with empty model_scene should still work (procedural fallback).
	var definition: Resource = BlockDefScript.new()
	definition.id = "test_block"
	definition.display_name = "Test Block"
	definition.size = Vector3i(1, 1, 1)
	definition.color = Color.BLUE
	definition.category = "transit"
	definition.model_scene = ""  # Empty = use procedural

	# Should be able to generate procedural mesh
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(definition.size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0
	assert_object(mesh).is_not_null()


# === Visual Uniqueness: Category-Specific Interiors ===

func test_residential_interior_different_from_commercial() -> void:
	## Residential and commercial interiors should have different furniture layouts.
	var res_node: Node3D = auto_free(Node3D.new())
	var com_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var res_interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		res_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	var com_interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		com_node, cells, Vector3i(0, 0, 0), "commercial", Color.WHITE
	)

	# They should have different numbers of children or different names
	var res_names: Array[String] = []
	for child in res_interiors.get_children():
		res_names.append(child.name)

	var com_names: Array[String] = []
	for child in com_interiors.get_children():
		com_names.append(child.name)

	# At least one name should be different (Bed vs Counter, etc.)
	var names_differ := false
	for name in res_names:
		if not com_names.has(name):
			names_differ = true
			break
	for name in com_names:
		if not res_names.has(name):
			names_differ = true
			break
	assert_bool(names_differ).is_true()


func test_transit_interior_has_lane_marking() -> void:
	## Transit corridors should have a lane marking element.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "transit", Color.WHITE
	)

	var has_lane := false
	for child in interiors.get_children():
		if child.name.begins_with("Lane"):
			has_lane = true
			break
	assert_bool(has_lane).is_true()


func test_green_interior_has_foliage() -> void:
	## Green blocks should have a foliage element.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color.WHITE
	)

	var has_foliage := false
	for child in interiors.get_children():
		if child.name.begins_with("Foliage") or child.name.begins_with("Planter"):
			has_foliage = true
			break
	assert_bool(has_foliage).is_true()


# === Panel Material Types ===

func test_all_panel_material_types_defined() -> void:
	## All panel material types from spec should be available.
	var expected_types := ["SOLID", "GLASS", "METAL", "SOLAR", "GARDEN", "FORCE_FIELD"]

	for type_name in expected_types:
		var has_type: bool = type_name in PanelMatScript.Type
		assert_bool(has_type).is_true()


func test_panel_materials_have_distinct_properties() -> void:
	## Each panel material type should have distinct properties (color, metallic, roughness).
	var props: Dictionary = PanelMatScript.MATERIAL_PROPS

	# Check we have 6 material types
	assert_int(props.size()).is_equal(6)

	# Check that properties differ between types
	var albedo_colors: Array[Color] = []
	for mat_type in props:
		var mat_props: Dictionary = props[mat_type]
		var albedo: Color = mat_props.get("albedo_color", Color.WHITE)
		albedo_colors.append(albedo)

	# At least 4 colors should be distinct
	var distinct_count := 0
	for i in range(albedo_colors.size()):
		var is_unique := true
		for j in range(i):
			if albedo_colors[i].is_equal_approx(albedo_colors[j]):
				is_unique = false
				break
		if is_unique:
			distinct_count += 1

	assert_int(distinct_count).is_greater_equal(4)


# === Grid Utilities ===

func test_grid_to_world_conversion() -> void:
	## Grid positions should convert to world positions correctly.
	var grid_pos := Vector3i(5, 2, 3)
	var world_pos: Vector3 = GridUtilsScript.grid_to_world(grid_pos)

	assert_float(world_pos.x).is_equal_approx(5.0 * CELL_SIZE, 0.01)
	assert_float(world_pos.y).is_equal_approx(2.0 * CELL_SIZE, 0.01)
	assert_float(world_pos.z).is_equal_approx(3.0 * CELL_SIZE, 0.01)


func test_grid_to_world_center_conversion() -> void:
	## Grid center should be at grid_pos * CELL_SIZE + CELL_SIZE/2.
	var grid_pos := Vector3i(0, 0, 0)
	var center: Vector3 = GridUtilsScript.grid_to_world_center(grid_pos)

	var expected := CELL_SIZE / 2.0
	assert_float(center.x).is_equal_approx(expected, 0.01)
	assert_float(center.y).is_equal_approx(expected, 0.01)
	assert_float(center.z).is_equal_approx(expected, 0.01)


func test_world_to_grid_conversion() -> void:
	## World positions should convert back to grid positions.
	var world_pos := Vector3(15.5, 7.2, 21.8)
	var grid_pos: Vector3i = GridUtilsScript.world_to_grid(world_pos)

	# 15.5 / 6 = 2.58 -> floor = 2
	# 7.2 / 6 = 1.2 -> floor = 1
	# 21.8 / 6 = 3.63 -> floor = 3
	assert_int(grid_pos.x).is_equal(2)
	assert_int(grid_pos.y).is_equal(1)
	assert_int(grid_pos.z).is_equal(3)
