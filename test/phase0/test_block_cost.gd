## GdUnit4 test suite for block construction costs (arcology-gi6.2).
## Tests cost field on BlockDefinition, cost loading from registry,
## and cost deduction/refund integration with GameState.
class_name TestBlockCost
extends GdUnitTestSuite

const BlockDefScript = preload("res://src/phase0/block_definition.gd")
const RegistryScript = preload("res://src/phase0/block_registry.gd")


# --- BlockDefinition cost field ---


func test_block_definition_has_cost_field() -> void:
	var def: Resource = auto_free(BlockDefScript.new())
	assert_int(def.cost).is_equal(0)


func test_block_definition_cost_can_be_set() -> void:
	var def: Resource = auto_free(BlockDefScript.new())
	def.cost = 500
	assert_int(def.cost).is_equal(500)


# --- Registry loads costs ---


func test_registry_loads_entrance_cost_zero() -> void:
	## Entrance is free (cost = 0) since it's required to start.
	var reg = auto_free(RegistryScript.new())
	var def: Resource = reg.get_definition("entrance")
	assert_object(def).is_not_null()
	assert_int(def.cost).is_equal(0)


func test_registry_loads_corridor_cost() -> void:
	## Corridor is a 1x1x1 transit block — should have cost > 0.
	var reg = auto_free(RegistryScript.new())
	var def: Resource = reg.get_definition("corridor")
	assert_object(def).is_not_null()
	assert_int(def.cost).is_greater(0)


func test_registry_loads_residential_cost() -> void:
	## Residential blocks should have cost > 0.
	var reg = auto_free(RegistryScript.new())
	var def: Resource = reg.get_definition("residential_standard")
	assert_object(def).is_not_null()
	assert_int(def.cost).is_greater(0)


func test_larger_blocks_cost_more() -> void:
	## A department store (3x2x3 = 18 cells) should cost more than a shop (1x1x1).
	var reg = auto_free(RegistryScript.new())
	var shop: Resource = reg.get_definition("commercial_shop")
	var dept: Resource = reg.get_definition("department_store")
	assert_object(shop).is_not_null()
	assert_object(dept).is_not_null()
	assert_bool(dept.cost > shop.cost).is_true()


# --- GameState treasury integration ---


func test_gamestate_can_afford() -> void:
	GameState.money = 10000
	assert_bool(GameState.can_afford(5000)).is_true()
	assert_bool(GameState.can_afford(10000)).is_true()
	assert_bool(GameState.can_afford(10001)).is_false()


func test_gamestate_spend_deducts() -> void:
	GameState.money = 10000
	var ok: bool = GameState.spend_money(3000)
	assert_bool(ok).is_true()
	assert_int(GameState.money).is_equal(7000)


func test_gamestate_spend_rejects_insufficient() -> void:
	GameState.money = 1000
	GameState.unlimited_money = false
	var ok: bool = GameState.spend_money(5000)
	assert_bool(ok).is_false()
	assert_int(GameState.money).is_equal(1000)  # Unchanged


func test_gamestate_unlimited_always_affords() -> void:
	GameState.money = 0
	GameState.unlimited_money = true
	assert_bool(GameState.can_afford(999999)).is_true()
	var ok: bool = GameState.spend_money(999999)
	assert_bool(ok).is_true()
	# Reset
	GameState.unlimited_money = false
	GameState.money = 50000


func test_gamestate_add_money_refund() -> void:
	GameState.money = 5000
	GameState.add_money(2000)
	assert_int(GameState.money).is_equal(7000)
