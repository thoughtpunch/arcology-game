## GdUnit4 test suite for Phase 0 BlockRegistry
## Tests JSON loading, category colors, palette ordering, and category queries.
class_name TestBlockRegistryPhase0
extends GdUnitTestSuite

const RegistryScript = preload("res://src/game/block_registry.gd")

var _registry: RefCounted


func before_test() -> void:
	_registry = auto_free(RegistryScript.new())


# === JSON Loading ===

func test_loads_130_block_definitions() -> void:
	var defs: Array = _registry.get_all_definitions()
	assert_int(defs.size()).is_equal(130)


func test_entrance_definition_exists() -> void:
	var def: Resource = _registry.get_definition("entrance")
	assert_object(def).is_not_null()


func test_entrance_display_name() -> void:
	var def: Resource = _registry.get_definition("entrance")
	assert_str(def.display_name).is_equal("Entrance")


func test_entrance_is_ground_only() -> void:
	var def: Resource = _registry.get_definition("entrance")
	assert_bool(def.ground_only).is_true()


func test_entrance_is_transit_category() -> void:
	var def: Resource = _registry.get_definition("entrance")
	assert_str(def.category).is_equal("transit")


func test_entrance_is_public() -> void:
	var def: Resource = _registry.get_definition("entrance")
	assert_str(def.traversability).is_equal("public")


func test_corridor_connects_horizontal() -> void:
	var def: Resource = _registry.get_definition("corridor")
	assert_bool(def.connects_horizontal).is_true()


func test_corridor_not_connects_vertical() -> void:
	var def: Resource = _registry.get_definition("corridor")
	assert_bool(def.connects_vertical).is_false()


func test_stairs_connects_both() -> void:
	var def: Resource = _registry.get_definition("stairs")
	assert_bool(def.connects_horizontal).is_true()
	assert_bool(def.connects_vertical).is_true()


func test_elevator_shaft_vertical_only() -> void:
	var def: Resource = _registry.get_definition("elevator_shaft")
	assert_bool(def.connects_horizontal).is_false()
	assert_bool(def.connects_vertical).is_true()


func test_residential_budget_capacity() -> void:
	var def: Resource = _registry.get_definition("residential_budget")
	assert_int(def.capacity).is_equal(4)


func test_residential_standard_capacity() -> void:
	var def: Resource = _registry.get_definition("residential_standard")
	assert_int(def.capacity).is_equal(2)


func test_residential_premium_capacity() -> void:
	var def: Resource = _registry.get_definition("residential_premium")
	assert_int(def.capacity).is_equal(1)


func test_residential_family_size() -> void:
	var def: Resource = _registry.get_definition("residential_family")
	assert_vector(def.size).is_equal(Vector3i(2, 1, 2))


func test_residential_family_capacity() -> void:
	var def: Resource = _registry.get_definition("residential_family")
	assert_int(def.capacity).is_equal(6)


func test_commercial_shop_jobs() -> void:
	var def: Resource = _registry.get_definition("commercial_shop")
	assert_int(def.jobs).is_equal(2)


func test_commercial_restaurant_jobs() -> void:
	var def: Resource = _registry.get_definition("commercial_restaurant")
	assert_int(def.jobs).is_equal(4)


func test_commercial_office_jobs() -> void:
	var def: Resource = _registry.get_definition("commercial_office")
	assert_int(def.jobs).is_equal(10)


func test_industrial_light_size() -> void:
	var def: Resource = _registry.get_definition("industrial_light")
	assert_vector(def.size).is_equal(Vector3i(2, 1, 2))


func test_industrial_light_jobs() -> void:
	var def: Resource = _registry.get_definition("industrial_light")
	assert_int(def.jobs).is_equal(20)


func test_medium_corridor_size() -> void:
	var def: Resource = _registry.get_definition("corridor_medium")
	assert_vector(def.size).is_equal(Vector3i(2, 1, 1))


func test_unknown_definition_returns_null() -> void:
	var def: Resource = _registry.get_definition("nonexistent_block")
	assert_object(def).is_null()


# === Categories ===

func test_has_8_categories() -> void:
	var cats: Array[String] = _registry.get_categories()
	assert_int(cats.size()).is_equal(8)


func test_category_order() -> void:
	var cats: Array[String] = _registry.get_categories()
	assert_str(cats[0]).is_equal("transit")
	assert_str(cats[1]).is_equal("residential")
	assert_str(cats[2]).is_equal("commercial")
	assert_str(cats[3]).is_equal("industrial")
	assert_str(cats[4]).is_equal("civic")
	assert_str(cats[5]).is_equal("infrastructure")
	assert_str(cats[6]).is_equal("green")
	assert_str(cats[7]).is_equal("entertainment")


func test_transit_has_13_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("transit")
	assert_int(defs.size()).is_equal(13)


func test_residential_has_14_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("residential")
	assert_int(defs.size()).is_equal(14)


func test_commercial_has_21_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("commercial")
	assert_int(defs.size()).is_equal(21)


func test_industrial_has_21_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("industrial")
	assert_int(defs.size()).is_equal(21)


func test_civic_has_28_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("civic")
	assert_int(defs.size()).is_equal(28)


func test_infrastructure_has_13_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("infrastructure")
	assert_int(defs.size()).is_equal(13)


func test_green_has_5_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("green")
	assert_int(defs.size()).is_equal(5)


func test_entertainment_has_15_blocks() -> void:
	var defs: Array = _registry.get_definitions_for_category("entertainment")
	assert_int(defs.size()).is_equal(15)


func test_empty_category_returns_empty() -> void:
	var defs: Array = _registry.get_definitions_for_category("nonexistent")
	assert_int(defs.size()).is_equal(0)


# === Colors ===

func test_entrance_has_gold_color() -> void:
	var def: Resource = _registry.get_definition("entrance")
	# Gold override: (0.85, 0.72, 0.2)
	assert_float(def.color.r).is_equal_approx(0.85, 0.01)
	assert_float(def.color.g).is_equal_approx(0.72, 0.01)
	assert_float(def.color.b).is_equal_approx(0.2, 0.01)


func test_corridor_has_transit_color() -> void:
	var def: Resource = _registry.get_definition("corridor")
	var transit_color: Color = _registry.get_category_color("transit")
	assert_float(def.color.r).is_equal_approx(transit_color.r, 0.01)
	assert_float(def.color.g).is_equal_approx(transit_color.g, 0.01)
	assert_float(def.color.b).is_equal_approx(transit_color.b, 0.01)


func test_residential_has_green_tint() -> void:
	var def: Resource = _registry.get_definition("residential_budget")
	var res_color: Color = _registry.get_category_color("residential")
	assert_float(def.color.r).is_equal_approx(res_color.r, 0.01)


# === Palette Order ===

func test_palette_order_has_130_entries() -> void:
	assert_int(_registry.palette_order.size()).is_equal(130)


func test_palette_order_starts_with_transit() -> void:
	# First blocks in palette should be transit category
	var first_def: Resource = _registry.get_definition(_registry.palette_order[0])
	assert_str(first_def.category).is_equal("transit")


# === Category Display Names ===

func test_category_display_names() -> void:
	assert_str(_registry.get_category_display_name("transit")).is_equal("Transit")
	assert_str(_registry.get_category_display_name("residential")).is_equal("Residential")
	assert_str(_registry.get_category_display_name("infrastructure")).is_equal("Infra")
	assert_str(_registry.get_category_display_name("entertainment")).is_equal("Entertainment")
