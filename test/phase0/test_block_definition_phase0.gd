## GdUnit4 test suite for Phase 0 BlockDefinition
## Tests that the Resource has all expected fields.
class_name TestBlockDefinitionPhase0
extends GdUnitTestSuite

const BlockDefScript = preload("res://src/phase0/block_definition.gd")


func test_has_id_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.id = "test_block"
	assert_str(def.id).is_equal("test_block")


func test_has_display_name_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.display_name = "Test Block"
	assert_str(def.display_name).is_equal("Test Block")


func test_has_size_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.size = Vector3i(2, 1, 3)
	assert_vector(def.size).is_equal(Vector3i(2, 1, 3))


func test_has_color_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.color = Color.RED
	assert_float(def.color.r).is_equal(1.0)


func test_has_category_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.category = "transit"
	assert_str(def.category).is_equal("transit")


func test_has_traversability_field() -> void:
	var def := auto_free(BlockDefScript.new())
	def.traversability = "public"
	assert_str(def.traversability).is_equal("public")


func test_ground_only_defaults_false() -> void:
	var def := auto_free(BlockDefScript.new())
	assert_bool(def.ground_only).is_false()


func test_ground_only_can_be_set_true() -> void:
	var def := auto_free(BlockDefScript.new())
	def.ground_only = true
	assert_bool(def.ground_only).is_true()


func test_connects_horizontal_defaults_false() -> void:
	var def := auto_free(BlockDefScript.new())
	assert_bool(def.connects_horizontal).is_false()


func test_connects_vertical_defaults_false() -> void:
	var def := auto_free(BlockDefScript.new())
	assert_bool(def.connects_vertical).is_false()


func test_capacity_defaults_zero() -> void:
	var def := auto_free(BlockDefScript.new())
	assert_int(def.capacity).is_equal(0)


func test_jobs_defaults_zero() -> void:
	var def := auto_free(BlockDefScript.new())
	assert_int(def.jobs).is_equal(0)


func test_capacity_and_jobs_set() -> void:
	var def := auto_free(BlockDefScript.new())
	def.capacity = 6
	def.jobs = 10
	assert_int(def.capacity).is_equal(6)
	assert_int(def.jobs).is_equal(10)
