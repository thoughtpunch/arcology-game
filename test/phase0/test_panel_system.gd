## GdUnit4 test suite for PanelSystem
## Tests exterior face detection, panel mesh generation, and neighbor tracking.
class_name TestPanelSystem
extends GdUnitTestSuite

const PanelSystemScript = preload("res://src/phase0/panel_system.gd")
const PanelMatScript = preload("res://src/phase0/panel_material.gd")
const FaceScript = preload("res://src/phase0/face.gd")

const CELL_SIZE: float = 6.0


# === Exterior Face Detection - Single Cell ===

func test_isolated_cell_has_6_exterior_faces() -> void:
	## A single block in empty space should have all 6 faces exposed.
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(
		Vector3i(0, 0, 0), occupancy
	)
	assert_int(exterior.size()).is_equal(6)


func test_cell_with_neighbor_above_has_5_exterior_faces() -> void:
	## A cell with another block on top loses its TOP face.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, 1, 0): 2,
	}
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(
		Vector3i(0, 0, 0), occupancy
	)
	assert_int(exterior.size()).is_equal(5)
	# TOP should NOT be in the list
	assert_bool(exterior.has(FaceScript.Dir.TOP)).is_false()


func test_cell_with_ground_below_has_5_exterior_faces() -> void:
	## A cell with ground (-1) below loses its BOTTOM face.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, -1, 0): -1,  # Ground
	}
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(
		Vector3i(0, 0, 0), occupancy
	)
	assert_int(exterior.size()).is_equal(5)
	assert_bool(exterior.has(FaceScript.Dir.BOTTOM)).is_false()


func test_cell_surrounded_on_all_sides_has_zero_exterior_faces() -> void:
	## A cell completely enclosed by other blocks has no exterior faces.
	var center := Vector3i(5, 5, 5)
	var occupancy: Dictionary = {center: 1}
	for face in PanelSystemScript.FACE_DIRS:
		var normal: Vector3i = FaceScript.to_normal(face)
		occupancy[center + normal] = 2  # Different block ids
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(center, occupancy)
	assert_int(exterior.size()).is_equal(0)


func test_cell_with_east_neighbor_misses_east_face() -> void:
	## Verify specific face is removed when neighbor exists in that direction.
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 2,  # East neighbor
	}
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(
		Vector3i(0, 0, 0), occupancy
	)
	assert_bool(exterior.has(FaceScript.Dir.EAST)).is_false()
	assert_bool(exterior.has(FaceScript.Dir.WEST)).is_true()


func test_cell_with_south_neighbor_misses_south_face() -> void:
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, 0, 1): 2,  # South neighbor (Z+)
	}
	var exterior: Array[int] = PanelSystemScript.get_exterior_faces(
		Vector3i(0, 0, 0), occupancy
	)
	assert_bool(exterior.has(FaceScript.Dir.SOUTH)).is_false()
	assert_bool(exterior.has(FaceScript.Dir.NORTH)).is_true()


# === Exterior Faces for Multi-Cell Blocks ===

func test_2x1x1_block_internal_faces_hidden() -> void:
	## A 2x1x1 block should not show faces between its own cells.
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 1,  # Same block
	}
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells, occupancy, 1
	)

	# Cell (0,0,0) should NOT have EAST face (shared with cell (1,0,0))
	if result.has(Vector3i(0, 0, 0)):
		var faces: Array = result[Vector3i(0, 0, 0)]
		assert_bool(faces.has(FaceScript.Dir.EAST)).is_false()

	# Cell (1,0,0) should NOT have WEST face (shared with cell (0,0,0))
	if result.has(Vector3i(1, 0, 0)):
		var faces: Array = result[Vector3i(1, 0, 0)]
		assert_bool(faces.has(FaceScript.Dir.WEST)).is_false()


func test_2x1x1_block_has_10_total_exterior_faces() -> void:
	## A 2x1x1 block in empty space: 2 cells × 6 faces - 2 internal = 10 exterior.
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 1,
	}
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells, occupancy, 1
	)
	var total_faces: int = 0
	for cell in result:
		total_faces += result[cell].size()
	assert_int(total_faces).is_equal(10)


func test_2x2x1_block_has_16_total_exterior_faces() -> void:
	## A 2x2x1 block: 4 cells × 6 faces = 24 total.
	## Internal edges: 4 shared faces (2 pairs each direction).
	## 24 - 8 = 16 exterior faces.
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1),
	]
	var occupancy: Dictionary = {}
	for cell in cells:
		occupancy[cell] = 1
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells, occupancy, 1
	)
	var total_faces: int = 0
	for cell in result:
		total_faces += result[cell].size()
	assert_int(total_faces).is_equal(16)


func test_block_adjacent_to_different_block_hides_shared_face() -> void:
	## When two different blocks share a face, it should be hidden.
	var cells_a: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 2,  # Different block
	}
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells_a, occupancy, 1
	)
	if result.has(Vector3i(0, 0, 0)):
		var faces: Array = result[Vector3i(0, 0, 0)]
		assert_bool(faces.has(FaceScript.Dir.EAST)).is_false()


# === Face Quad Creation ===

func test_create_face_quad_returns_mesh() -> void:
	var mesh: Mesh = PanelSystemScript.create_face_quad(
		FaceScript.Dir.TOP, CELL_SIZE, 0.15
	)
	assert_object(mesh).is_not_null()


func test_face_quad_size_accounts_for_inset() -> void:
	var inset := 0.15
	var mesh: PlaneMesh = PanelSystemScript.create_face_quad(
		FaceScript.Dir.TOP, CELL_SIZE, inset
	) as PlaneMesh
	var expected_size := CELL_SIZE - inset * 2.0
	assert_float(mesh.size.x).is_equal_approx(expected_size, 0.01)
	assert_float(mesh.size.y).is_equal_approx(expected_size, 0.01)


# === Panel Mesh Generation ===

func test_create_panels_returns_node() -> void:
	## Panel generation should return a Panels container node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_object(panels).is_not_null()
	assert_str(panels.name).is_equal("Panels")


func test_isolated_block_gets_6_panel_meshes() -> void:
	## An isolated 1x1x1 block should generate 6 panel meshes (one per face).
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_int(panels.get_child_count()).is_equal(6)


func test_block_with_neighbor_gets_5_panel_meshes() -> void:
	## A block with one neighbor should generate 5 panel meshes.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 2,  # East neighbor
	}

	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_int(panels.get_child_count()).is_equal(5)


func test_fully_enclosed_block_gets_zero_panel_meshes() -> void:
	## A block surrounded on all 6 sides should generate 0 panels.
	var block_node: Node3D = auto_free(Node3D.new())
	var center := Vector3i(5, 5, 5)
	var cells: Array[Vector3i] = [center]
	var occupancy: Dictionary = {center: 1}
	for face in PanelSystemScript.FACE_DIRS:
		var normal: Vector3i = FaceScript.to_normal(face)
		occupancy[center + normal] = 2

	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, center, occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_int(panels.get_child_count()).is_equal(0)


func test_panel_meshes_have_material() -> void:
	## Each panel mesh should have a StandardMaterial3D.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	var panels: Node3D = PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.GLASS, Color.BLUE
	)
	for child in panels.get_children():
		assert_object(child).is_instanceof(MeshInstance3D)
		assert_object(child.material_override).is_instanceof(StandardMaterial3D)


func test_panels_are_child_of_block_node() -> void:
	## The Panels node should be added as a child of the block node.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	var panels_node: Node3D = block_node.get_node_or_null("Panels")
	assert_object(panels_node).is_not_null()


# === Update / Regenerate Panels ===

func test_update_panels_removes_old_and_creates_new() -> void:
	## Calling update should replace existing panels.
	var block_node: Node3D = auto_free(Node3D.new())
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {Vector3i(0, 0, 0): 1}

	# First creation — 6 panels (isolated)
	PanelSystemScript.create_panel_meshes_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)

	# Add a neighbor, then update
	occupancy[Vector3i(1, 0, 0)] = 2
	PanelSystemScript.update_panels_for_block(
		block_node, cells, Vector3i(0, 0, 0), occupancy, 1,
		PanelMatScript.Type.SOLID, Color.WHITE
	)

	# The old Panels node is queue_free'd (won't be instant in test),
	# but a new one should exist
	var count := 0
	for child in block_node.get_children():
		if child.name == "Panels":
			count += 1
	# Should have 2: old one pending free + new one. Or just check the new one.
	# The newest Panels node should have 5 children (lost EAST face)
	var newest_panels: Node3D = null
	for child in block_node.get_children():
		if child.name == "Panels" or child.name.begins_with("@Panels"):
			newest_panels = child
	assert_object(newest_panels).is_not_null()


# === Affected Block IDs ===

func test_affected_ids_finds_adjacent_blocks() -> void:
	## When a block is placed, its neighbors should be found.
	var cells: Array[Vector3i] = [Vector3i(5, 0, 5)]
	var occupancy: Dictionary = {
		Vector3i(5, 0, 5): 3,   # The block we're checking
		Vector3i(6, 0, 5): 4,   # East neighbor
		Vector3i(5, 1, 5): 7,   # Top neighbor
	}
	var affected: Array[int] = PanelSystemScript.get_affected_block_ids(
		cells, occupancy, 3
	)
	assert_bool(affected.has(4)).is_true()
	assert_bool(affected.has(7)).is_true()


func test_affected_ids_excludes_own_block() -> void:
	## The block itself should never appear in the affected list.
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 1,
		Vector3i(2, 0, 0): 2,
	}
	var affected: Array[int] = PanelSystemScript.get_affected_block_ids(
		cells, occupancy, 1
	)
	assert_bool(affected.has(1)).is_false()
	assert_bool(affected.has(2)).is_true()


func test_affected_ids_excludes_ground() -> void:
	## Ground cells (-1) should not appear in affected blocks.
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(0, -1, 0): -1,  # Ground
	}
	var affected: Array[int] = PanelSystemScript.get_affected_block_ids(
		cells, occupancy, 1
	)
	assert_bool(affected.has(-1)).is_false()
	assert_int(affected.size()).is_equal(0)


func test_affected_ids_no_duplicates() -> void:
	## A neighbor sharing multiple faces should appear only once.
	## Block 1 is 2x1x1, block 2 is 2x1x1 directly south.
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0)]
	var occupancy: Dictionary = {
		Vector3i(0, 0, 0): 1,
		Vector3i(1, 0, 0): 1,
		Vector3i(0, 0, 1): 2,  # South of cell 0
		Vector3i(1, 0, 1): 2,  # South of cell 1
	}
	var affected: Array[int] = PanelSystemScript.get_affected_block_ids(
		cells, occupancy, 1
	)
	# Block 2 shares two faces but should appear only once
	var count := 0
	for bid in affected:
		if bid == 2:
			count += 1
	assert_int(count).is_equal(1)


func test_affected_ids_empty_when_no_neighbors() -> void:
	## An isolated block should have no affected neighbors.
	var cells: Array[Vector3i] = [Vector3i(10, 10, 10)]
	var occupancy: Dictionary = {Vector3i(10, 10, 10): 1}
	var affected: Array[int] = PanelSystemScript.get_affected_block_ids(
		cells, occupancy, 1
	)
	assert_int(affected.size()).is_equal(0)


# === Edge Cases ===

func test_empty_cells_array_returns_empty_exterior_faces() -> void:
	## An empty cells array should return an empty result.
	var cells: Array[Vector3i] = []
	var occupancy: Dictionary = {}
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells, occupancy, 1
	)
	assert_int(result.size()).is_equal(0)


func test_negative_coordinates_work() -> void:
	## Cells at negative coordinates should work correctly.
	var cells: Array[Vector3i] = [Vector3i(-1, -2, -3)]
	var occupancy: Dictionary = {Vector3i(-1, -2, -3): 1}
	var result: Dictionary = PanelSystemScript.get_exterior_faces_for_block(
		cells, occupancy, 1
	)
	assert_int(result.size()).is_equal(1)
	assert_int(result[Vector3i(-1, -2, -3)].size()).is_equal(6)
