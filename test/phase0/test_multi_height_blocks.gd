## GdUnit4 test suite for multi-height block support
## Tests placement validation, interior generation, and panel handling
## for blocks taller than 1 cell (e.g., indoor_forest, arena, atrium).
class_name TestMultiHeightBlocks
extends GdUnitTestSuite

const GridUtilsScript = preload("res://src/game/grid_utils.gd")
const InteriorMeshSystemScript = preload("res://src/game/interior_mesh_system.gd")
const PanelSystemScript = preload("res://src/game/panel_system.gd")
const FaceScript = preload("res://src/game/face.gd")
const BlockDefScript = preload("res://src/game/block_definition.gd")

const CELL_SIZE: float = 6.0


# === get_occupied_cells: Multi-Height Expansion ===


func test_1x2x1_block_expands_vertically() -> void:
	## A block with size (1,2,1) should occupy 2 cells stacked vertically.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(1, 2, 1), Vector3i(0, 0, 0), 0
	)
	assert_int(cells.size()).is_equal(2)
	assert_bool(cells.has(Vector3i(0, 0, 0))).is_true()
	assert_bool(cells.has(Vector3i(0, 1, 0))).is_true()


func test_1x3x1_block_expands_3_floors() -> void:
	## A block with size (1,3,1) should occupy 3 cells vertically.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(1, 3, 1), Vector3i(5, 0, 5), 0
	)
	assert_int(cells.size()).is_equal(3)
	assert_bool(cells.has(Vector3i(5, 0, 5))).is_true()
	assert_bool(cells.has(Vector3i(5, 1, 5))).is_true()
	assert_bool(cells.has(Vector3i(5, 2, 5))).is_true()


func test_indoor_forest_5x3x5_occupies_75_cells() -> void:
	## Indoor forest (5×3×5) should occupy 5*3*5 = 75 cells.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(5, 3, 5), Vector3i(0, 0, 0), 0
	)
	assert_int(cells.size()).is_equal(75)


func test_arena_6x3x6_occupies_108_cells() -> void:
	## Arena (6×3×6) should occupy 6*3*6 = 108 cells.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(6, 3, 6), Vector3i(0, 0, 0), 0
	)
	assert_int(cells.size()).is_equal(108)


func test_atrium_3x5x3_occupies_45_cells() -> void:
	## Atrium (3×5×3) should occupy 3*5*3 = 45 cells.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(3, 5, 3), Vector3i(0, 0, 0), 0
	)
	assert_int(cells.size()).is_equal(45)


func test_cinema_2x2x2_occupies_8_cells() -> void:
	## Cinema (2×2×2) should occupy 2*2*2 = 8 cells.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(2, 2, 2), Vector3i(10, 0, 10), 0
	)
	assert_int(cells.size()).is_equal(8)


func test_multi_height_block_at_offset_origin() -> void:
	## Verify cells are offset from origin correctly for tall blocks.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(1, 3, 1), Vector3i(10, 5, 20), 0
	)
	assert_int(cells.size()).is_equal(3)
	assert_bool(cells.has(Vector3i(10, 5, 20))).is_true()
	assert_bool(cells.has(Vector3i(10, 6, 20))).is_true()
	assert_bool(cells.has(Vector3i(10, 7, 20))).is_true()


# === Rotation of Multi-Height Blocks ===


func test_3x2x1_rotated_90_becomes_1x2x3() -> void:
	## Rotating a 3×2×1 block 90° swaps X and Z: becomes 1×2×3.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(3, 2, 1), Vector3i(0, 0, 0), 90
	)
	assert_int(cells.size()).is_equal(6)
	# Should expand 1 in X, 2 in Y, 3 in Z
	assert_bool(cells.has(Vector3i(0, 0, 0))).is_true()
	assert_bool(cells.has(Vector3i(0, 1, 0))).is_true()
	assert_bool(cells.has(Vector3i(0, 0, 2))).is_true()
	assert_bool(cells.has(Vector3i(0, 1, 2))).is_true()


func test_rotation_preserves_height() -> void:
	## Height (Y component) should be unchanged by rotation.
	var cells_0: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(2, 3, 1), Vector3i(0, 0, 0), 0
	)
	var cells_90: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(2, 3, 1), Vector3i(0, 0, 0), 90
	)
	# Both should occupy 3 Y levels
	var max_y_0: int = 0
	for c in cells_0:
		max_y_0 = maxi(max_y_0, c.y)
	var max_y_90: int = 0
	for c in cells_90:
		max_y_90 = maxi(max_y_90, c.y)
	assert_int(max_y_0).is_equal(2)
	assert_int(max_y_90).is_equal(2)


# === Multi-Height Interior Mesh Generation ===


func test_multi_height_green_generates_tree_on_ground_floor() -> void:
	## Green multi-height blocks should generate soil + trunk on ground floor.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	# Should have meshes — ground floor has floor_slab + soil + trunk
	assert_int(interiors.get_child_count()).is_greater_equal(3)

	# Verify there's a trunk mesh
	var has_trunk := false
	for child in interiors.get_children():
		if child.name.begins_with("Trunk_"):
			has_trunk = true
			break
	assert_bool(has_trunk).is_true()


func test_multi_height_green_generates_canopy_on_top_floor() -> void:
	## Top floor of multi-height green block should have canopy.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	var has_canopy := false
	for child in interiors.get_children():
		if child.name.begins_with("Canopy_"):
			has_canopy = true
			break
	assert_bool(has_canopy).is_true()


func test_multi_height_green_middle_floor_has_foliage() -> void:
	## Middle floors of multi-height green blocks should have mid-canopy foliage.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	var has_mid_foliage := false
	for child in interiors.get_children():
		if child.name.begins_with("MidFoliage_"):
			has_mid_foliage = true
			break
	assert_bool(has_mid_foliage).is_true()


func test_multi_height_entertainment_ground_has_arena_floor() -> void:
	## Ground floor of multi-height entertainment block should have arena floor.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "entertainment", Color(0.70, 0.50, 0.55),
		Vector3i(1, 3, 1)
	)
	var has_arena_floor := false
	for child in interiors.get_children():
		if child.name.begins_with("ArenaFloor_"):
			has_arena_floor = true
			break
	assert_bool(has_arena_floor).is_true()


func test_multi_height_entertainment_top_has_rigging() -> void:
	## Top floor of multi-height entertainment block should have rigging.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "entertainment", Color(0.70, 0.50, 0.55),
		Vector3i(1, 3, 1)
	)
	var has_rigging := false
	for child in interiors.get_children():
		if child.name.begins_with("Rigging_"):
			has_rigging = true
			break
	assert_bool(has_rigging).is_true()


func test_multi_height_transit_upper_has_walkway() -> void:
	## Upper floors of multi-height transit blocks should have walkways.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "transit", Color(0.55, 0.55, 0.60),
		Vector3i(1, 2, 1)
	)
	var has_walkway := false
	for child in interiors.get_children():
		if child.name.begins_with("Walkway_"):
			has_walkway = true
			break
	assert_bool(has_walkway).is_true()


func test_multi_height_commercial_upper_has_mezzanine() -> void:
	## Upper floors of multi-height commercial blocks should have mezzanine.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "commercial", Color(0.85, 0.78, 0.65),
		Vector3i(1, 2, 1)
	)
	var has_mezzanine := false
	for child in interiors.get_children():
		if child.name.begins_with("Mezzanine_"):
			has_mezzanine = true
			break
	assert_bool(has_mezzanine).is_true()


func test_multi_height_civic_ground_has_desks() -> void:
	## Ground floor of multi-height civic block should have civic desks.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "civic", Color(0.50, 0.45, 0.55),
		Vector3i(1, 2, 1)
	)
	var has_desk := false
	for child in interiors.get_children():
		if child.name.begins_with("CivicDesk_"):
			has_desk = true
			break
	assert_bool(has_desk).is_true()


# === Single-Height Backward Compatibility ===


func test_single_height_block_uses_standard_interior() -> void:
	## A block with size (1,1,1) should still use the standard per-cell interior.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "residential", Color.WHITE,
		Vector3i(1, 1, 1)
	)
	# Should have standard residential: floor + bed + table + divider + desk = 5
	assert_int(interiors.get_child_count()).is_greater_equal(4)
	# Should have a Bed (standard residential interior)
	var has_bed := false
	for child in interiors.get_children():
		if child.name.begins_with("Bed_"):
			has_bed = true
			break
	assert_bool(has_bed).is_true()


func test_default_size_parameter_uses_standard_interior() -> void:
	## Calling without block_size should default to (1,1,1) and use standard interiors.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35)
	)
	# Standard green: floor + planter + foliage = 3
	var has_planter := false
	for child in interiors.get_children():
		if child.name.begins_with("Planter_"):
			has_planter = true
			break
	assert_bool(has_planter).is_true()


# === Multi-Height Ground Floor Gets Floor Slab ===


func test_multi_height_ground_floor_has_floor_slab() -> void:
	## Ground floor (y=0) of multi-height block should have a floor slab.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	var has_ground_floor := false
	for child in interiors.get_children():
		if child.name == "Floor_(0, 0, 0)":
			has_ground_floor = true
			break
	assert_bool(has_ground_floor).is_true()


func test_multi_height_upper_floor_no_floor_slab_for_green() -> void:
	## Upper floors of multi-height green block should NOT have floor slabs
	## (they are open vertical space).
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	var has_upper_floor_slab := false
	for child in interiors.get_children():
		if child.name == "Floor_(0, 1, 0)" or child.name == "Floor_(0, 2, 0)":
			has_upper_floor_slab = true
			break
	assert_bool(has_upper_floor_slab).is_false()


# === Panel System: Multi-Height Exterior Faces ===


func test_multi_height_block_interior_faces_hidden() -> void:
	## Interior faces between vertically adjacent cells of the same block
	## should not be exterior.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, 1, 0): 1,  # Same block above
		Vector3i(0, 2, 0): 1,  # Same block above that
	}
	var occupied: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var exterior := PanelSystemScript.get_exterior_faces_for_block(
		occupied, occupancy, 1
	)
	# Bottom cell should not have TOP face (it's internal)
	var bottom_faces: Array = exterior.get(Vector3i(0, 0, 0), [])
	assert_bool(bottom_faces.has(FaceScript.Dir.TOP)).is_false()

	# Middle cell should not have TOP or BOTTOM (both internal)
	var mid_faces: Array = exterior.get(Vector3i(0, 1, 0), [])
	assert_bool(mid_faces.has(FaceScript.Dir.TOP)).is_false()
	assert_bool(mid_faces.has(FaceScript.Dir.BOTTOM)).is_false()

	# Top cell should not have BOTTOM face (internal)
	var top_faces: Array = exterior.get(Vector3i(0, 2, 0), [])
	assert_bool(top_faces.has(FaceScript.Dir.BOTTOM)).is_false()


func test_multi_height_block_exterior_faces_exposed() -> void:
	## Exterior faces of a multi-height block should be properly identified.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, 1, 0): 1,
		Vector3i(0, 2, 0): 1,
	}
	var occupied: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var exterior := PanelSystemScript.get_exterior_faces_for_block(
		occupied, occupancy, 1
	)
	# Bottom cell should have BOTTOM face (exposed to air below)
	var bottom_faces: Array = exterior.get(Vector3i(0, 0, 0), [])
	assert_bool(bottom_faces.has(FaceScript.Dir.BOTTOM)).is_true()
	# All cells should have N/S/E/W (no horizontal neighbors)
	assert_bool(bottom_faces.has(FaceScript.Dir.NORTH)).is_true()
	assert_bool(bottom_faces.has(FaceScript.Dir.SOUTH)).is_true()

	# Top cell should have TOP face (exposed to air above)
	var top_faces: Array = exterior.get(Vector3i(0, 2, 0), [])
	assert_bool(top_faces.has(FaceScript.Dir.TOP)).is_true()


func test_multi_height_block_with_neighbor_hides_shared_face() -> void:
	## When a multi-height block has a neighbor, the shared face should be hidden.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, 1, 0): 1,
		Vector3i(1, 0, 0): 2,  # Different block to the east, only on ground floor
	}
	var occupied: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0),
	]
	var exterior := PanelSystemScript.get_exterior_faces_for_block(
		occupied, occupancy, 1
	)
	# Ground cell's EAST face should be hidden (neighbor block)
	var ground_faces: Array = exterior.get(Vector3i(0, 0, 0), [])
	assert_bool(ground_faces.has(FaceScript.Dir.EAST)).is_false()

	# Upper cell's EAST face should be exposed (no neighbor at that height)
	var upper_faces: Array = exterior.get(Vector3i(0, 1, 0), [])
	assert_bool(upper_faces.has(FaceScript.Dir.EAST)).is_true()


# === Negative / Edge Cases ===


func test_multi_height_block_single_cell_column() -> void:
	## A block that is only 1 wide and 1 deep but 5 tall should work.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(1, 5, 1), Vector3i(0, 0, 0), 0
	)
	assert_int(cells.size()).is_equal(5)
	for i in range(5):
		assert_bool(cells.has(Vector3i(0, i, 0))).is_true()


func test_multi_height_block_all_cells_are_unique() -> void:
	## No cell should appear twice in occupied_cells.
	var cells: Array[Vector3i] = GridUtilsScript.get_occupied_cells(
		Vector3i(3, 3, 3), Vector3i(0, 0, 0), 0
	)
	var seen: Dictionary = {}
	for c in cells:
		assert_bool(seen.has(c)).is_false()
		seen[c] = true
	assert_int(cells.size()).is_equal(27)


func test_multi_height_interior_all_meshes_have_material() -> void:
	## All interior meshes for multi-height blocks should have materials.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color(0.35, 0.60, 0.35),
		Vector3i(1, 3, 1)
	)
	for child in interiors.get_children():
		assert_object(child).is_instanceof(MeshInstance3D)
		var mi: MeshInstance3D = child
		assert_object(mi.material_override).is_not_null()


func test_multi_height_interior_shadows_disabled() -> void:
	## Interior meshes for multi-height blocks should not cast shadows.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
	]
	var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "entertainment", Color(0.70, 0.50, 0.55),
		Vector3i(1, 3, 1)
	)
	for child in interiors.get_children():
		var mi: MeshInstance3D = child
		assert_int(mi.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func test_multi_height_all_categories_generate_without_error() -> void:
	## Every category should generate multi-height interiors without errors.
	var categories := [
		"residential", "commercial", "transit", "civic",
		"industrial", "infrastructure", "green", "entertainment",
	]
	for cat in categories:
		var block_node: Node3D = auto_free(Node3D.new())
		var cells: Array[Vector3i] = [
			Vector3i(0, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 2, 0),
		]
		var interiors: Node3D = InteriorMeshSystemScript.create_interior_meshes_for_block(
			block_node, cells, Vector3i(0, 0, 0), cat, Color.WHITE,
			Vector3i(1, 3, 1)
		)
		assert_int(interiors.get_child_count()).is_greater_equal(1)


func test_multi_height_update_regenerates_interiors() -> void:
	## Updating a multi-height block should create a fresh Interiors node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(0, 1, 0),
	]

	# First creation
	InteriorMeshSystemScript.create_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "green", Color.WHITE,
		Vector3i(1, 2, 1)
	)

	# Update
	InteriorMeshSystemScript.update_interior_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), "entertainment", Color.WHITE,
		Vector3i(1, 2, 1)
	)

	# Should still have Interiors node
	var found := false
	for child in block_node.get_children():
		if child.name == "Interiors" or child.name.begins_with("@Interiors"):
			found = true
			break
	assert_bool(found).is_true()
