## GdUnit4 test suite for Block class
## Task: arcology-cxg.1 - Migrate tests to GdUnit4 format
class_name TestBlock
extends GdUnitTestSuite

const __source = 'res://src/blocks/block.gd'


# === Instantiation Tests ===

func test_instantiation_with_type_and_position() -> void:
	var block: RefCounted = auto_free(Block.new("corridor", Vector3i(5, 3, 1)))

	assert_str(block.block_type).is_equal("corridor")
	assert_vector(block.grid_position).is_equal(Vector3i(5, 3, 1))


func test_instantiation_with_type_only() -> void:
	var block: RefCounted = auto_free(Block.new("residential"))

	assert_str(block.block_type).is_equal("residential")
	assert_vector(block.grid_position).is_equal(Vector3i.ZERO)


# === Default Values Tests ===

func test_default_block_type_is_empty() -> void:
	var block: RefCounted = auto_free(Block.new())

	assert_str(block.block_type).is_equal("")


func test_default_grid_position_is_zero() -> void:
	var block: RefCounted = auto_free(Block.new())

	assert_vector(block.grid_position).is_equal(Vector3i.ZERO)


func test_default_connected_is_false() -> void:
	var block: RefCounted = auto_free(Block.new())

	assert_bool(block.connected).is_false()


# === Connected Property Tests ===

func test_connected_can_be_set_true() -> void:
	var block: RefCounted = auto_free(Block.new("corridor", Vector3i.ZERO))

	block.connected = true

	assert_bool(block.connected).is_true()


func test_connected_can_be_set_false() -> void:
	var block: RefCounted = auto_free(Block.new("corridor", Vector3i.ZERO))
	block.connected = true

	block.connected = false

	assert_bool(block.connected).is_false()


# === Signal Tests ===

func test_has_property_changed_signal() -> void:
	var block: RefCounted = auto_free(Block.new())

	assert_bool(block.has_signal("property_changed")).is_true()


# === get_definition Tests ===
# NOTE: Tests that call get_definition(), get_traversability(), get_sprite_path()
# require BlockRegistry autoload to be available. In GdUnit4 headless mode,
# Engine.get_main_loop() returns a different context where has_node() fails.
# These tests are left for integration testing with full scene tree.
# See: test/core/test_block_registry.gd for BlockRegistry integration tests


# === String Representation Tests ===

func test_to_string_includes_type() -> void:
	var block: RefCounted = auto_free(Block.new("corridor", Vector3i(5, 3, 1)))

	var str_repr: String = str(block)

	assert_str(str_repr).contains("corridor")


func test_to_string_includes_position() -> void:
	var block: RefCounted = auto_free(Block.new("corridor", Vector3i(5, 3, 1)))

	var str_repr: String = str(block)

	assert_str(str_repr).contains("5")
