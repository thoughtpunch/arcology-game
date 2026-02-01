## GdUnit4 test suite for InteriorMeshSystem
## Tests interior furniture/fixture generation for all block categories.
class_name TestInteriorMeshSystem
extends GdUnitTestSuite

const InteriorMeshSystemScript = preload("res://src/phase0/interior_mesh_system.gd")
const FaceScript = preload("res://src/phase0/face.gd")

const CELL_SIZE: float = 6.0


# === Container Creation ===

func test_create_interior_returns_node() -> void:
	## Interior generation should return an "Interiors" container node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	assert_object(interiors).is_not_null()
	assert_str(interiors.name).is_equal("Interiors")


func test_interiors_are_child_of_block_node() -> void:
	## The Interiors node should be added as a child of the block node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	var interiors_node: Node3D = block_node.get_node_or_null("Interiors")
	assert_object(interiors_node).is_not_null()


# === Per-Category Generation (Positive) ===

func test_residential_generates_furniture() -> void:
	## Residential blocks should generate bed, table, divider, desk.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color(0.45, 0.65, 0.45)
	)
	# Should have: floor + bed + table + divider + desk = 5 children
	assert_int(interiors.get_child_count()).is_greater_equal(4)
	# All children should be MeshInstance3D
	for child in interiors.get_children():
		assert_object(child).is_instanceof(MeshInstance3D)


func test_commercial_generates_counter_and_shelf() -> void:
	## Commercial blocks should generate counter and shelving.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "commercial", Color(0.75, 0.60, 0.35)
	)
	# floor + counter + shelf = 3
	assert_int(interiors.get_child_count()).is_greater_equal(3)


func test_transit_generates_lane_and_rails() -> void:
	## Transit blocks should generate lane marking and handrails.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "transit", Color(0.45, 0.55, 0.70)
	)
	# floor + lane + 2 rails = 4
	assert_int(interiors.get_child_count()).is_greater_equal(3)


func test_civic_generates_desks() -> void:
	## Civic blocks should generate desk rows.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "civic", Color(0.60, 0.50, 0.65)
	)
	# floor + 2 desks = 3
	assert_int(interiors.get_child_count()).is_greater_equal(3)


func test_industrial_generates_machinery() -> void:
	## Industrial blocks should generate machine and auxiliary unit.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "industrial", Color(0.55, 0.50, 0.45)
	)
	# floor + machine + aux = 3
	assert_int(interiors.get_child_count()).is_greater_equal(3)


func test_infrastructure_generates_pipes() -> void:
	## Infrastructure blocks should generate pipe, duct, and control panel.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "infrastructure", Color(0.50, 0.55, 0.60)
	)
	# floor + pipe + duct + panel = 4
	assert_int(interiors.get_child_count()).is_greater_equal(4)


func test_green_generates_planter_and_foliage() -> void:
	## Green blocks should generate planter and foliage.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35)
	)
	# floor + planter + foliage = 3
	assert_int(interiors.get_child_count()).is_greater_equal(3)


func test_entertainment_generates_seating() -> void:
	## Entertainment blocks should generate benches and stage.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "entertainment", Color(0.70, 0.50, 0.55)
	)
	# floor + 2 benches + stage = 4
	assert_int(interiors.get_child_count()).is_greater_equal(4)


func test_unknown_category_uses_generic_fallback() -> void:
	## Unknown categories should still generate interior geometry.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "mystery_category", Color.WHITE
	)
	# floor + generic box = 2
	assert_int(interiors.get_child_count()).is_greater_equal(2)


# === Multi-Cell Blocks ===

func test_2x1x1_block_generates_interiors_for_both_cells() -> void:
	## A 2x1x1 block should generate interior meshes for each cell.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	# Each residential cell: floor + bed + table + divider + desk = 5
	# 2 cells × 5 = 10
	assert_int(interiors.get_child_count()).is_greater_equal(8)


func test_3x2x1_block_generates_interiors_for_all_cells() -> void:
	## A larger multi-cell block should generate interiors for every cell.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = []
	for x in range(3):
		for z in range(2):
			cells.append(Vector3i(x, 0, z))

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "commercial", Color.WHITE
	)
	# 6 cells, each with at least floor + counter + shelf = 3 minimum per cell
	assert_int(interiors.get_child_count()).is_greater_equal(18)


# === Material Properties ===

func test_all_meshes_have_standard_material() -> void:
	## Every interior mesh should have a StandardMaterial3D.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	for child in interiors.get_children():
		assert_object(child).is_instanceof(MeshInstance3D)
		var mi: MeshInstance3D = child
		assert_object(mi.material_override).is_instanceof(StandardMaterial3D)


func test_materials_have_emission_enabled() -> void:
	## Interior materials should have emission enabled (for selection glow support).
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "commercial", Color.WHITE
	)
	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		var mat: StandardMaterial3D = mi.material_override
		assert_bool(mat.emission_enabled).is_true()
		# Default emission energy should be 0 (activated only on selection)
		assert_float(mat.emission_energy_multiplier).is_equal_approx(0.0, 0.01)


func test_materials_are_matte() -> void:
	## Interior materials should be matte (high roughness, low metallic).
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		var mat: StandardMaterial3D = mi.material_override
		assert_float(mat.roughness).is_greater_equal(0.5)
		assert_float(mat.metallic).is_less_equal(0.5)


# === Position / Geometry ===

func test_furniture_within_cell_bounds() -> void:
	## All interior meshes should be positioned within the cell volume.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	var cell_min := Vector3(0, 0, 0)
	var cell_max := Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE)

	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		var pos := mi.position
		# Allow some tolerance for mesh extents
		assert_float(pos.x).is_between(-0.5, cell_max.x + 0.5)
		assert_float(pos.y).is_between(-0.5, cell_max.y + 0.5)
		assert_float(pos.z).is_between(-0.5, cell_max.z + 0.5)


func test_offset_cell_has_correct_local_position() -> void:
	## Interior meshes for cell (1,0,0) with origin (0,0,0) should be
	## offset by CELL_SIZE in the X direction.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(1, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "transit", Color.WHITE
	)
	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		# All X positions should be in [CELL_SIZE, 2*CELL_SIZE] range
		assert_float(mi.position.x).is_greater_equal(CELL_SIZE - 0.5)
		assert_float(mi.position.x).is_less_equal(CELL_SIZE * 2.0 + 0.5)


func test_shadows_disabled_on_interior_meshes() -> void:
	## Interior meshes should not cast shadows (reduces rendering cost).
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "civic", Color.WHITE
	)
	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		assert_int(mi.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


# === Update / Regenerate ===

func test_update_removes_old_interiors() -> void:
	## Calling update should create a fresh Interiors node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]

	# First creation
	InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)

	# Update (regenerate)
	InteriorMeshSystemScript.update_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "commercial", Color.WHITE
	)

	# Should still have an Interiors node (old one queue_free'd, new one exists)
	var found := false
	for child in block_node.get_children():
		if child.name == "Interiors" or child.name.begins_with("@Interiors"):
			found = true
			break
	assert_bool(found).is_true()


# === Edge Cases (Negative) ===

func test_empty_cells_array_returns_empty_container() -> void:
	## An empty cells array should return an empty Interiors node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = []

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE
	)
	assert_int(interiors.get_child_count()).is_equal(0)


func test_negative_coordinates_work() -> void:
	## Cells at negative coordinates should work correctly.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(-1, -2, -3)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(-1, -2, -3), "industrial", Color.WHITE
	)
	assert_int(interiors.get_child_count()).is_greater_equal(1)


func test_large_offset_origin_works() -> void:
	## Blocks with origin far from (0,0,0) should position correctly.
	var block_node: Node3D = auto_free(Node3D.new())
	var origin := Vector3i(50, 10, 30)
	var cells: Array[Vector3i] = [origin, origin + Vector3i(1, 0, 0)]

	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, origin, "green", Color.WHITE
	)
	# Should have interiors for both cells
	assert_int(interiors.get_child_count()).is_greater_equal(4)


# === Color Helpers ===

func test_get_furniture_color_blends_with_category() -> void:
	## Furniture color should blend block color with category color.
	var block_color := Color(1.0, 1.0, 1.0)
	var result := InteriorMeshSystemScript.get_furniture_color("residential", block_color)
	# Should be closer to warm wood than pure white
	assert_float(result.r).is_less(1.0)
	assert_float(result.g).is_less(1.0)
	assert_float(result.b).is_less(1.0)


func test_get_furniture_color_unknown_category_returns_block_color() -> void:
	## Unknown category should blend toward block_color (since fallback is block_color).
	var block_color := Color(0.5, 0.5, 0.5)
	var result := InteriorMeshSystemScript.get_furniture_color("nonexistent", block_color)
	# With lerp(block_color, block_color, 0.6) = block_color
	assert_float(result.r).is_equal_approx(0.5, 0.01)
	assert_float(result.g).is_equal_approx(0.5, 0.01)
	assert_float(result.b).is_equal_approx(0.5, 0.01)


# === Category Coverage ===

func test_all_defined_categories_generate_without_error() -> void:
	## Every known category should generate interior meshes without errors.
	var categories := [
		"residential", "commercial", "transit", "civic",
		"industrial", "infrastructure", "green", "entertainment",
	]
	for cat in categories:
		var block_node: Node3D = auto_free(Node3D.new())
		var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
		var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
			block_node, cells, Vector3i(0, 0, 0), cat, Color.WHITE
		)
		assert_int(interiors.get_child_count()).is_greater_equal(1)
