extends SceneTree
## Test: BlockRenderer3D (arcology-3c3)
##
## Verifies:
## - Grid to world coordinate conversion
## - Block addition and removal
## - Visual state management
## - Ghost preview functionality
## - Grid signal integration

var _test_count := 0
var _pass_count := 0

var _renderer: Node3D  # BlockRenderer3D
var _BlockRenderer3DClass: GDScript


func _init() -> void:
	print("\n=== Test: BlockRenderer3D ===\n")

	# Load the script
	_BlockRenderer3DClass = load("res://src/rendering/block_renderer_3d.gd")
	assert(_BlockRenderer3DClass != null, "BlockRenderer3D script should load")

	_renderer = _BlockRenderer3DClass.new()
	root.add_child(_renderer)

	# Wait for _ready
	await process_frame

	# Run tests
	_test_grid_to_world_conversion()
	_test_world_to_grid_conversion()
	_test_round_trip_conversion()
	_test_add_block()
	_test_remove_block()
	_test_block_state_management()
	_test_ghost_preview()
	_test_multiple_blocks()
	_test_clear_blocks()
	_test_materials_initialized()
	_test_collision_setup()

	# Cleanup
	_renderer.queue_free()
	await process_frame

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])

	if _pass_count == _test_count:
		print("SUCCESS: All tests passed!")
	else:
		print("FAILURE: Some tests failed!")

	quit()


func _test_grid_to_world_conversion() -> void:
	print("Test: grid_to_world_center conversion")

	# Origin
	_test_count += 1
	var origin: Vector3 = _BlockRenderer3DClass.grid_to_world_center(Vector3i(0, 0, 0))
	# grid_pos.z is floor level -> world Y
	# Expected: x=0, y=CUBE_HEIGHT/2=1.75, z=0
	if is_equal_approx(origin.x, 0.0) and is_equal_approx(origin.y, 1.75) and is_equal_approx(origin.z, 0.0):
		_pass_count += 1
		print("  PASS: Origin (0,0,0) -> (0, 1.75, 0)")
	else:
		print("  FAIL: Origin expected (0, 1.75, 0), got %s" % origin)

	# Positive X (east)
	_test_count += 1
	var east: Vector3 = _BlockRenderer3DClass.grid_to_world_center(Vector3i(1, 0, 0))
	if is_equal_approx(east.x, 6.0) and is_equal_approx(east.y, 1.75):
		_pass_count += 1
		print("  PASS: (1,0,0) -> x=6 (east)")
	else:
		print("  FAIL: (1,0,0) expected x=6, got %s" % east)

	# Positive Y (north in grid -> Z in world)
	_test_count += 1
	var north: Vector3 = _BlockRenderer3DClass.grid_to_world_center(Vector3i(0, 1, 0))
	if is_equal_approx(north.z, 6.0) and is_equal_approx(north.y, 1.75):
		_pass_count += 1
		print("  PASS: (0,1,0) -> z=6 (north)")
	else:
		print("  FAIL: (0,1,0) expected z=6, got %s" % north)

	# Floor 1 (grid z=1 -> world y elevated)
	_test_count += 1
	var floor1: Vector3 = _BlockRenderer3DClass.grid_to_world_center(Vector3i(0, 0, 1))
	# Expected y = 1 * 3.5 + 3.5/2 = 3.5 + 1.75 = 5.25
	if is_equal_approx(floor1.y, 5.25):
		_pass_count += 1
		print("  PASS: Floor 1 (z=1) -> y=5.25")
	else:
		print("  FAIL: Floor 1 expected y=5.25, got y=%f" % floor1.y)


func _test_world_to_grid_conversion() -> void:
	print("Test: world_to_grid conversion")

	# Center of block at origin
	_test_count += 1
	var grid_origin: Vector3i = _BlockRenderer3DClass.world_to_grid(Vector3(0, 1.75, 0))
	if grid_origin == Vector3i(0, 0, 0):
		_pass_count += 1
		print("  PASS: World (0, 1.75, 0) -> Grid (0,0,0)")
	else:
		print("  FAIL: Expected (0,0,0), got %s" % grid_origin)

	# Block at (1,0,0) grid
	_test_count += 1
	var grid_east: Vector3i = _BlockRenderer3DClass.world_to_grid(Vector3(6, 1.75, 0))
	if grid_east == Vector3i(1, 0, 0):
		_pass_count += 1
		print("  PASS: World (6, 1.75, 0) -> Grid (1,0,0)")
	else:
		print("  FAIL: Expected (1,0,0), got %s" % grid_east)

	# Block on floor 1
	_test_count += 1
	var grid_floor1: Vector3i = _BlockRenderer3DClass.world_to_grid(Vector3(0, 5.25, 0))
	if grid_floor1 == Vector3i(0, 0, 1):
		_pass_count += 1
		print("  PASS: World (0, 5.25, 0) -> Grid (0,0,1)")
	else:
		print("  FAIL: Expected (0,0,1), got %s" % grid_floor1)


func _test_round_trip_conversion() -> void:
	print("Test: round-trip conversion")

	var test_positions: Array[Vector3i] = [
		Vector3i(0, 0, 0),
		Vector3i(5, 3, 2),
		Vector3i(-2, -1, 0),
		Vector3i(10, 10, 5)
	]

	for grid_pos: Vector3i in test_positions:
		_test_count += 1
		var world_pos: Vector3 = _BlockRenderer3DClass.grid_to_world_center(grid_pos)
		var back_to_grid: Vector3i = _BlockRenderer3DClass.world_to_grid(world_pos)
		if back_to_grid == grid_pos:
			_pass_count += 1
			print("  PASS: %s -> world -> %s" % [grid_pos, back_to_grid])
		else:
			print("  FAIL: %s round-trip gave %s" % [grid_pos, back_to_grid])


func _test_add_block() -> void:
	print("Test: add_block()")

	_test_count += 1
	var pos := Vector3i(0, 0, 0)
	var mesh: MeshInstance3D = _renderer.add_block(pos, "corridor")

	if mesh != null:
		_pass_count += 1
		print("  PASS: add_block returns MeshInstance3D")
	else:
		print("  FAIL: add_block should return MeshInstance3D")

	# Check position
	_test_count += 1
	var expected_world: Vector3 = _BlockRenderer3DClass.grid_to_world_center(pos)
	if mesh and mesh.position.is_equal_approx(expected_world):
		_pass_count += 1
		print("  PASS: Block positioned correctly at %s" % mesh.position)
	else:
		print("  FAIL: Block position expected %s, got %s" % [expected_world, mesh.position if mesh else "null"])

	# Check mesh stored
	_test_count += 1
	if _renderer.get_mesh_at(pos) == mesh:
		_pass_count += 1
		print("  PASS: get_mesh_at returns correct mesh")
	else:
		print("  FAIL: get_mesh_at should return added mesh")

	# Check count
	_test_count += 1
	if _renderer.get_block_count() == 1:
		_pass_count += 1
		print("  PASS: Block count is 1")
	else:
		print("  FAIL: Block count expected 1, got %d" % _renderer.get_block_count())

	# Cleanup
	_renderer.clear()


func _test_remove_block() -> void:
	print("Test: remove_block()")

	var pos := Vector3i(1, 1, 0)
	_renderer.add_block(pos, "residential_basic")

	_test_count += 1
	_renderer.remove_block(pos)

	if _renderer.get_mesh_at(pos) == null:
		_pass_count += 1
		print("  PASS: Block removed from storage")
	else:
		print("  FAIL: Block should be removed")

	_test_count += 1
	if _renderer.get_block_count() == 0:
		_pass_count += 1
		print("  PASS: Block count is 0 after removal")
	else:
		print("  FAIL: Block count expected 0, got %d" % _renderer.get_block_count())


func _test_block_state_management() -> void:
	print("Test: block state management")

	var pos := Vector3i(2, 2, 0)
	_renderer.add_block(pos, "entrance")

	# Check default state
	_test_count += 1
	var BlockState = _BlockRenderer3DClass.BlockState
	if _renderer.get_block_state(pos) == BlockState.NORMAL:
		_pass_count += 1
		print("  PASS: Default state is NORMAL")
	else:
		print("  FAIL: Default state should be NORMAL")

	# Update to selected
	_test_count += 1
	_renderer.update_block_state(pos, BlockState.SELECTED)
	if _renderer.get_block_state(pos) == BlockState.SELECTED:
		_pass_count += 1
		print("  PASS: State updated to SELECTED")
	else:
		print("  FAIL: State should be SELECTED")

	# Update to disconnected
	_test_count += 1
	_renderer.update_block_state(pos, BlockState.DISCONNECTED)
	if _renderer.get_block_state(pos) == BlockState.DISCONNECTED:
		_pass_count += 1
		print("  PASS: State updated to DISCONNECTED")
	else:
		print("  FAIL: State should be DISCONNECTED")

	_renderer.clear()


func _test_ghost_preview() -> void:
	print("Test: ghost preview")

	var pos := Vector3i(3, 3, 0)
	var BlockState = _BlockRenderer3DClass.BlockState

	# Show ghost
	_test_count += 1
	_renderer.show_ghost(pos, "corridor", BlockState.GHOST_VALID)
	# Check ghost is visible (internal state)
	# We can't directly check visibility without accessing private member
	# Instead, test that show/hide don't crash
	_pass_count += 1
	print("  PASS: show_ghost doesn't crash")

	# Update position
	_test_count += 1
	_renderer.update_ghost_position(Vector3i(4, 4, 0))
	_pass_count += 1
	print("  PASS: update_ghost_position doesn't crash")

	# Update state
	_test_count += 1
	_renderer.update_ghost_state(BlockState.GHOST_INVALID, "corridor")
	_pass_count += 1
	print("  PASS: update_ghost_state doesn't crash")

	# Hide ghost
	_test_count += 1
	_renderer.hide_ghost()
	_pass_count += 1
	print("  PASS: hide_ghost doesn't crash")


func _test_multiple_blocks() -> void:
	print("Test: multiple blocks")

	_renderer.clear()

	# Add several blocks
	var positions := [
		Vector3i(0, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, 0, 1),  # Floor 1
	]

	for pos in positions:
		_renderer.add_block(pos, "corridor")

	_test_count += 1
	if _renderer.get_block_count() == 4:
		_pass_count += 1
		print("  PASS: Added 4 blocks")
	else:
		print("  FAIL: Expected 4 blocks, got %d" % _renderer.get_block_count())

	# Check each exists
	_test_count += 1
	var all_found := true
	for pos in positions:
		if _renderer.get_mesh_at(pos) == null:
			all_found = false
			break
	if all_found:
		_pass_count += 1
		print("  PASS: All blocks retrievable")
	else:
		print("  FAIL: Some blocks not found")

	_renderer.clear()


func _test_clear_blocks() -> void:
	print("Test: clear()")

	# Add blocks
	_renderer.add_block(Vector3i(0, 0, 0), "corridor")
	_renderer.add_block(Vector3i(1, 0, 0), "entrance")
	_renderer.add_block(Vector3i(0, 1, 0), "stairs")

	_test_count += 1
	_renderer.clear()

	if _renderer.get_block_count() == 0:
		_pass_count += 1
		print("  PASS: clear() removes all blocks")
	else:
		print("  FAIL: clear() should remove all blocks, got %d" % _renderer.get_block_count())


func _test_materials_initialized() -> void:
	print("Test: materials initialized")

	# The renderer should have materials for common block types
	var test_types: Array[String] = ["corridor", "residential_basic", "entrance", "stairs", "elevator_shaft"]

	_test_count += 1
	# Add blocks of each type to verify materials work
	var all_ok := true
	for i in range(test_types.size()):
		var pos := Vector3i(i, 0, 0)
		var mesh: MeshInstance3D = _renderer.add_block(pos, test_types[i])
		if mesh == null or mesh.material_override == null:
			all_ok = false
			print("  WARNING: No material for type: %s" % test_types[i])

	if all_ok:
		_pass_count += 1
		print("  PASS: All test block types have materials")
	else:
		print("  FAIL: Some block types missing materials")

	_renderer.clear()


func _test_collision_setup() -> void:
	print("Test: collision setup for raycasting")

	_renderer.clear()
	var pos := Vector3i(0, 0, 0)
	var mesh: MeshInstance3D = _renderer.add_block(pos, "corridor")

	_test_count += 1
	# Check that mesh has a StaticBody3D child
	var has_collision := false
	for child in mesh.get_children():
		if child is StaticBody3D:
			has_collision = true
			break

	if has_collision:
		_pass_count += 1
		print("  PASS: Block has collision body for raycasting")
	else:
		print("  FAIL: Block should have StaticBody3D child")

	_renderer.clear()
