## GdUnit4 test suite for PanelMaterial
## Tests panel material types, category defaults, label lookup, and material creation.
class_name TestPanelMaterial
extends GdUnitTestSuite

const PanelMatScript = preload("res://src/game/panel_material.gd")


# === Type Constants ===

func test_solid_type_is_zero() -> void:
	assert_int(PanelMatScript.Type.SOLID).is_equal(0)


func test_all_six_types_exist() -> void:
	# Verify all 6 material types are defined
	assert_int(PanelMatScript.Type.SOLID).is_equal(0)
	assert_int(PanelMatScript.Type.GLASS).is_equal(1)
	assert_int(PanelMatScript.Type.METAL).is_equal(2)
	assert_int(PanelMatScript.Type.SOLAR).is_equal(3)
	assert_int(PanelMatScript.Type.GARDEN).is_equal(4)
	assert_int(PanelMatScript.Type.FORCE_FIELD).is_equal(5)


# === Labels ===

func test_solid_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.SOLID)).is_equal("Solid")


func test_glass_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.GLASS)).is_equal("Glass")


func test_metal_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.METAL)).is_equal("Metal")


func test_solar_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.SOLAR)).is_equal("Solar")


func test_garden_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.GARDEN)).is_equal("Garden")


func test_force_field_label() -> void:
	assert_str(PanelMatScript.get_label(PanelMatScript.Type.FORCE_FIELD)).is_equal("Force Field")


func test_invalid_type_label_returns_unknown() -> void:
	assert_str(PanelMatScript.get_label(99)).is_equal("Unknown")


# === Category Defaults ===

func test_transit_defaults_to_solid() -> void:
	assert_int(PanelMatScript.get_default_for_category("transit")).is_equal(PanelMatScript.Type.SOLID)


func test_residential_defaults_to_solid() -> void:
	assert_int(PanelMatScript.get_default_for_category("residential")).is_equal(PanelMatScript.Type.SOLID)


func test_commercial_defaults_to_glass() -> void:
	assert_int(PanelMatScript.get_default_for_category("commercial")).is_equal(PanelMatScript.Type.GLASS)


func test_industrial_defaults_to_metal() -> void:
	assert_int(PanelMatScript.get_default_for_category("industrial")).is_equal(PanelMatScript.Type.METAL)


func test_civic_defaults_to_solid() -> void:
	assert_int(PanelMatScript.get_default_for_category("civic")).is_equal(PanelMatScript.Type.SOLID)


func test_infrastructure_defaults_to_metal() -> void:
	assert_int(PanelMatScript.get_default_for_category("infrastructure")).is_equal(PanelMatScript.Type.METAL)


func test_green_defaults_to_garden() -> void:
	assert_int(PanelMatScript.get_default_for_category("green")).is_equal(PanelMatScript.Type.GARDEN)


func test_entertainment_defaults_to_glass() -> void:
	assert_int(PanelMatScript.get_default_for_category("entertainment")).is_equal(PanelMatScript.Type.GLASS)


func test_unknown_category_defaults_to_solid() -> void:
	assert_int(PanelMatScript.get_default_for_category("nonexistent")).is_equal(PanelMatScript.Type.SOLID)


func test_empty_category_defaults_to_solid() -> void:
	assert_int(PanelMatScript.get_default_for_category("")).is_equal(PanelMatScript.Type.SOLID)


# === Material Creation ===

func test_create_solid_material_returns_standard_material() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_object(mat).is_not_null()
	assert_object(mat).is_instanceof(StandardMaterial3D)


func test_solid_material_is_opaque() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_int(mat.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_DISABLED)


func test_glass_material_has_transparency() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.GLASS, Color.WHITE
	)
	assert_int(mat.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)


func test_force_field_material_has_transparency() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.FORCE_FIELD, Color.WHITE
	)
	assert_int(mat.transparency).is_equal(BaseMaterial3D.TRANSPARENCY_ALPHA)


func test_metal_material_has_high_metallic() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.METAL, Color.WHITE
	)
	assert_float(mat.metallic).is_greater(0.5)


func test_solid_material_has_low_metallic() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_float(mat.metallic).is_less(0.1)


func test_solar_material_has_emission() -> void:
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLAR, Color.WHITE
	)
	assert_bool(mat.emission_enabled).is_true()
	assert_float(mat.emission_energy_multiplier).is_greater(0.0)


func test_material_blends_block_color() -> void:
	## The material should blend the block color with the panel color.
	## With a red block and solid panel, the result should not be pure red.
	var block_color := Color(1.0, 0.0, 0.0)
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLID, block_color
	)
	# 60% red + 40% panel grey = not pure red anymore
	assert_float(mat.albedo_color.r).is_less(1.0)
	assert_float(mat.albedo_color.g).is_greater(0.0)


func test_material_has_emission_enabled() -> void:
	## All materials should have emission enabled (for selection glow support).
	var mat: StandardMaterial3D = PanelMatScript.create_material(
		PanelMatScript.Type.SOLID, Color.WHITE
	)
	assert_bool(mat.emission_enabled).is_true()


# === Material Properties Table Consistency ===

func test_all_types_have_material_props() -> void:
	## Every defined type should have an entry in MATERIAL_PROPS.
	for type_val in [
		PanelMatScript.Type.SOLID,
		PanelMatScript.Type.GLASS,
		PanelMatScript.Type.METAL,
		PanelMatScript.Type.SOLAR,
		PanelMatScript.Type.GARDEN,
		PanelMatScript.Type.FORCE_FIELD,
	]:
		assert_bool(PanelMatScript.MATERIAL_PROPS.has(type_val)).is_true()


func test_all_types_have_labels() -> void:
	## Every defined type should have an entry in LABELS.
	for type_val in [
		PanelMatScript.Type.SOLID,
		PanelMatScript.Type.GLASS,
		PanelMatScript.Type.METAL,
		PanelMatScript.Type.SOLAR,
		PanelMatScript.Type.GARDEN,
		PanelMatScript.Type.FORCE_FIELD,
	]:
		assert_bool(PanelMatScript.LABELS.has(type_val)).is_true()
