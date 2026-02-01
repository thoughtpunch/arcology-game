## GdUnit4 test suite for panel system integration
## Tests that BlockDefinition and BlockRegistry correctly handle panel_material,
## and that the panel system integrates with the block registry.
class_name TestPanelIntegration
extends GdUnitTestSuite

const BlockDefScript = preload("res://src/game/block_definition.gd")
const RegistryScript = preload("res://src/game/block_registry.gd")
const PanelMatScript = preload("res://src/game/panel_material.gd")

var _registry: RefCounted


func before_test() -> void:
	_registry = auto_free(RegistryScript.new())


# === BlockDefinition panel_material field ===

func test_block_definition_panel_material_defaults_to_negative_one() -> void:
	## New BlockDefinitions should have panel_material = -1 (use category default).
	var def: Resource = auto_free(BlockDefScript.new())
	assert_int(def.panel_material).is_equal(-1)


func test_block_definition_panel_material_can_be_set() -> void:
	var def: Resource = auto_free(BlockDefScript.new())
	def.panel_material = PanelMatScript.Type.GLASS
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.GLASS)


# === BlockRegistry loads panel_material ===

func test_entrance_has_transit_panel_material() -> void:
	## Entrance is transit category — should default to SOLID.
	var def: Resource = _registry.get_definition("entrance")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLID)


func test_corridor_has_solid_panel_material() -> void:
	var def: Resource = _registry.get_definition("corridor")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLID)


func test_residential_budget_has_solid_panel_material() -> void:
	var def: Resource = _registry.get_definition("residential_budget")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLID)


func test_commercial_shop_has_glass_panel_material() -> void:
	var def: Resource = _registry.get_definition("commercial_shop")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.GLASS)


func test_industrial_light_has_metal_panel_material() -> void:
	var def: Resource = _registry.get_definition("industrial_light")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.METAL)


func test_green_planter_has_garden_panel_material() -> void:
	var def: Resource = _registry.get_definition("green_planter")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.GARDEN)


func test_entertainment_gym_has_glass_panel_material() -> void:
	var def: Resource = _registry.get_definition("entertainment_gym")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.GLASS)


func test_civic_security_has_solid_panel_material() -> void:
	var def: Resource = _registry.get_definition("civic_security")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLID)


func test_infrastructure_hvac_has_metal_panel_material() -> void:
	var def: Resource = _registry.get_definition("infra_hvac")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.METAL)


# === JSON override panel_material ===

func test_solar_collector_has_solar_panel_material() -> void:
	## solar_collector has panel_material: "solar" in blocks.json.
	var def: Resource = _registry.get_definition("solar_collector")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLAR)


func test_power_plant_solar_has_solar_panel_material() -> void:
	## power_plant_solar has panel_material: "solar" in blocks.json.
	var def: Resource = _registry.get_definition("power_plant_solar")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.SOLAR)


func test_atrium_has_glass_panel_material() -> void:
	## atrium has panel_material: "glass" in blocks.json (overrides green default).
	var def: Resource = _registry.get_definition("atrium")
	assert_int(def.panel_material).is_equal(PanelMatScript.Type.GLASS)


# === All blocks have valid panel_material ===

func test_all_blocks_have_non_negative_panel_material() -> void:
	## After loading, all blocks should have a resolved panel_material >= 0.
	var all_defs: Array = _registry.get_all_definitions()
	for def in all_defs:
		assert_int(def.panel_material).is_greater_equal(0)
