## GdUnit4 test suite for Grid class
## Task: arcology-cxg.1 - Migrate tests to GdUnit4 format
class_name TestGrid
extends GdUnitTestSuite

const __source = 'res://src/core/grid.gd'

var _grid: Node


func before_test() -> void:
	_grid = auto_free(load(__source).new())


# === Block Storage Tests ===

func test_set_block_stores_at_position() -> void:
	var mock_block := {"block_type": "test", "grid_position": Vector3i.ZERO}
	_grid.set_block(Vector3i(1, 2, 3), mock_block)

	assert_bool(_grid.has_block(Vector3i(1, 2, 3))).is_true()


func test_get_block_returns_stored_block() -> void:
	var mock_block := {"block_type": "test", "grid_position": Vector3i.ZERO}
	_grid.set_block(Vector3i(1, 2, 3), mock_block)

	assert_that(_grid.get_block(Vector3i(1, 2, 3))).is_equal(mock_block)


func test_has_block_returns_false_for_empty_position() -> void:
	assert_bool(_grid.has_block(Vector3i(99, 99, 99))).is_false()


func test_get_block_returns_null_for_empty_position() -> void:
	assert_object(_grid.get_block(Vector3i(99, 99, 99))).is_null()


# === Block Removal Tests ===

func test_remove_block_removes_stored_block() -> void:
	var mock_block := {"block_type": "test", "grid_position": Vector3i.ZERO}
	_grid.set_block(Vector3i(1, 2, 3), mock_block)

	_grid.remove_block(Vector3i(1, 2, 3))

	assert_bool(_grid.has_block(Vector3i(1, 2, 3))).is_false()


func test_remove_block_on_empty_position_no_error() -> void:
	# Should not throw or crash
	_grid.remove_block(Vector3i(99, 99, 99))
	assert_bool(true).is_true()  # If we reach here, no error occurred


# === Coordinate Conversion Tests ===

func test_grid_to_screen_origin() -> void:
	var screen_pos: Vector2 = _grid.grid_to_screen(Vector3i(0, 0, 0))

	assert_vector(screen_pos).is_equal(Vector2(0, 0))


func test_grid_to_screen_x_positive() -> void:
	# (1, 0, 0) -> x = (1-0) * 32 = 32, y = (1+0) * 16 = 16
	var screen_pos: Vector2 = _grid.grid_to_screen(Vector3i(1, 0, 0))

	assert_vector(screen_pos).is_equal(Vector2(32, 16))


func test_grid_to_screen_y_positive() -> void:
	# (0, 1, 0) -> x = (0-1) * 32 = -32, y = (0+1) * 16 = 16
	var screen_pos: Vector2 = _grid.grid_to_screen(Vector3i(0, 1, 0))

	assert_vector(screen_pos).is_equal(Vector2(-32, 16))


func test_grid_to_screen_z_offset() -> void:
	# (0, 0, 1) -> x = 0, y = 0 - 1*32 = -32
	var screen_pos: Vector2 = _grid.grid_to_screen(Vector3i(0, 0, 1))

	assert_vector(screen_pos).is_equal(Vector2(0, -32))


func test_grid_to_screen_combined() -> void:
	# (1, 1, 0) -> x = (1-1)*32 = 0, y = (1+1)*16 = 32
	var screen_pos: Vector2 = _grid.grid_to_screen(Vector3i(1, 1, 0))

	assert_vector(screen_pos).is_equal(Vector2(0, 32))


# === Round-trip Conversion Tests ===

func test_roundtrip_origin() -> void:
	var pos := Vector3i(0, 0, 0)
	var screen: Vector2 = _grid.grid_to_screen(pos)
	var back: Vector3i = _grid.screen_to_grid(screen, pos.z)

	assert_vector(back).is_equal(pos)


func test_roundtrip_positive_coords() -> void:
	var pos := Vector3i(5, 3, 0)
	var screen: Vector2 = _grid.grid_to_screen(pos)
	var back: Vector3i = _grid.screen_to_grid(screen, pos.z)

	assert_vector(back).is_equal(pos)


func test_roundtrip_with_z_level() -> void:
	var pos := Vector3i(10, 10, 2)
	var screen: Vector2 = _grid.grid_to_screen(pos)
	var back: Vector3i = _grid.screen_to_grid(screen, pos.z)

	assert_vector(back).is_equal(pos)


func test_roundtrip_negative_coords() -> void:
	var pos := Vector3i(-3, 4, 1)
	var screen: Vector2 = _grid.grid_to_screen(pos)
	var back: Vector3i = _grid.screen_to_grid(screen, pos.z)

	assert_vector(back).is_equal(pos)


func test_roundtrip_high_z() -> void:
	var pos := Vector3i(0, 0, 5)
	var screen: Vector2 = _grid.grid_to_screen(pos)
	var back: Vector3i = _grid.screen_to_grid(screen, pos.z)

	assert_vector(back).is_equal(pos)


# === Signal Tests ===

func test_has_block_added_signal() -> void:
	assert_bool(_grid.has_signal("block_added")).is_true()


func test_has_block_removed_signal() -> void:
	assert_bool(_grid.has_signal("block_removed")).is_true()


func test_block_added_signal_emitted() -> void:
	var signal_received := []
	_grid.block_added.connect(func(pos: Vector3i, block: Variant) -> void:
		signal_received.append({"pos": pos, "block": block})
	)

	var mock_block := {"block_type": "test"}
	_grid.set_block(Vector3i(1, 1, 1), mock_block)

	assert_int(signal_received.size()).is_equal(1)
	assert_vector(signal_received[0]["pos"]).is_equal(Vector3i(1, 1, 1))


func test_block_removed_signal_emitted() -> void:
	var signal_received := []
	_grid.block_removed.connect(func(pos: Vector3i) -> void:
		signal_received.append(pos)
	)

	var mock_block := {"block_type": "test"}
	_grid.set_block(Vector3i(1, 1, 1), mock_block)
	_grid.remove_block(Vector3i(1, 1, 1))

	assert_int(signal_received.size()).is_equal(1)
	assert_vector(signal_received[0]).is_equal(Vector3i(1, 1, 1))


# === get_all_blocks Tests ===

func test_get_all_blocks_empty_grid() -> void:
	assert_array(_grid.get_all_blocks()).is_empty()


func test_get_all_blocks_returns_all() -> void:
	_grid.set_block(Vector3i(0, 0, 0), {"type": "test1"})
	_grid.set_block(Vector3i(1, 0, 0), {"type": "test2"})
	_grid.set_block(Vector3i(2, 0, 0), {"type": "test3"})

	assert_int(_grid.get_all_blocks().size()).is_equal(3)


func test_get_all_blocks_after_removal() -> void:
	_grid.set_block(Vector3i(0, 0, 0), {"type": "test1"})
	_grid.set_block(Vector3i(1, 0, 0), {"type": "test2"})
	_grid.remove_block(Vector3i(0, 0, 0))

	assert_int(_grid.get_all_blocks().size()).is_equal(1)
