extends SceneTree

## Tests for ScenarioConfig resource
## Covers: creation, JSON loading, property access, cantilever calculation,
##         build zone checks, serialization round-trip

var _pass_count: int = 0
var _fail_count: int = 0
var _test_count: int = 0

# Load script dynamically to avoid class_name resolution issues in headless
var _script: GDScript


func _init() -> void:
	_script = load("res://src/data/scenario_config.gd") as GDScript

	print("=== ScenarioConfig Tests ===")

	# --- Positive Assertions ---
	_test_default_creation()
	_test_earth_defaults()
	_test_cantilever_calculation_earth()
	_test_cantilever_calculation_lunar()
	_test_cantilever_calculation_mars()
	_test_cantilever_calculation_zero_g()
	_test_cantilever_calculation_high_g()
	_test_is_within_cantilever_limit()
	_test_is_within_build_height()
	_test_is_in_build_zone()
	_test_is_within_ground_depth()
	_test_get_seconds_per_hour()
	_test_from_dict()
	_test_from_dict_cantilever_auto_calc()
	_test_to_dict_roundtrip()
	_test_get_summary()
	_test_load_from_json()
	_test_load_scenario_earth()

	# --- Negative Assertions ---
	_test_invalid_json_path()
	_test_cantilever_limit_exceeded()
	_test_build_height_exceeded()
	_test_outside_build_zone()
	_test_below_ground_depth()
	_test_static_time_seconds_per_hour()
	_test_from_dict_missing_fields()
	_test_zero_g_unlimited_cantilever()

	print("\n=== Results: %d passed, %d failed out of %d ===" % [_pass_count, _fail_count, _test_count])
	if _fail_count > 0:
		print("FAILURES DETECTED")
	else:
		print("ALL TESTS PASSED")
	quit()


func _assert(condition: bool, message: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % message)
	else:
		_fail_count += 1
		print("  FAIL: %s" % message)


func _new_config() -> Resource:
	return _script.new()


func _call_static(method: String, args: Array = []) -> Variant:
	return _script.callv(method, args)


# --- Positive Tests ---

func _test_default_creation() -> void:
	print("\nTest: Default creation")
	var config: Resource = _call_static("create_default")
	_assert(config != null, "Default config should not be null")
	_assert(config is Resource, "Config should be a Resource")


func _test_earth_defaults() -> void:
	print("\nTest: Earth standard defaults")
	var config: Resource = _new_config()
	_assert(is_equal_approx(config.gravity, 1.0), "Default gravity should be 1.0 (Earth)")
	_assert(config.max_cantilever == 2, "Default max_cantilever should be 2")
	_assert(config.max_build_height == -1, "Default max_build_height should be -1 (unlimited)")
	_assert(config.structural_integrity == true, "Default structural_integrity should be true")
	_assert(is_equal_approx(config.day_length_minutes, 0.0), "Default day_length_minutes should be 0 (static)")
	_assert(is_equal_approx(config.default_time_of_day, 8.0), "Default time of day should be 8.0")
	_assert(is_equal_approx(config.sun_energy, 1.0), "Default sun_energy should be 1.0")
	_assert(is_equal_approx(config.ambient_energy, 0.3), "Default ambient_energy should be 0.3")
	_assert(config.ground_depth == 3, "Default ground_depth should be 3")
	_assert(config.ground_type == "earth", "Default ground_type should be 'earth'")
	_assert(config.mode == "sandbox", "Default mode should be 'sandbox'")
	_assert(config.build_zone_origin == Vector2i(-50, -50), "Default build_zone_origin should be (-50, -50)")
	_assert(config.build_zone_size == Vector2i(100, 100), "Default build_zone_size should be (100, 100)")


func _test_cantilever_calculation_earth() -> void:
	print("\nTest: Cantilever calculation - Earth")
	var result: int = _call_static("calculate_cantilever", [1.0])
	_assert(result == 2, "Earth gravity (1.0) cantilever should be 2, got %d" % result)


func _test_cantilever_calculation_lunar() -> void:
	print("\nTest: Cantilever calculation - Lunar")
	var result: int = _call_static("calculate_cantilever", [0.16])
	_assert(result == 12, "Lunar gravity (0.16) cantilever should be 12, got %d" % result)


func _test_cantilever_calculation_mars() -> void:
	print("\nTest: Cantilever calculation - Mars")
	var result: int = _call_static("calculate_cantilever", [0.38])
	_assert(result == 5, "Mars gravity (0.38) cantilever should be 5, got %d" % result)


func _test_cantilever_calculation_zero_g() -> void:
	print("\nTest: Cantilever calculation - Zero-G")
	var result: int = _call_static("calculate_cantilever", [0.0])
	_assert(result == -1, "Zero-G cantilever should be -1 (unlimited), got %d" % result)


func _test_cantilever_calculation_high_g() -> void:
	print("\nTest: Cantilever calculation - High-G")
	var result: int = _call_static("calculate_cantilever", [2.0])
	_assert(result == 1, "High-G (2.0) cantilever should be 1, got %d" % result)


func _test_is_within_cantilever_limit() -> void:
	print("\nTest: is_within_cantilever_limit")
	var config: Resource = _new_config()
	# max_cantilever defaults to 2
	_assert(config.is_within_cantilever_limit(0), "Distance 0 should be within limit 2")
	_assert(config.is_within_cantilever_limit(1), "Distance 1 should be within limit 2")
	_assert(config.is_within_cantilever_limit(2), "Distance 2 should be within limit 2")
	_assert(not config.is_within_cantilever_limit(3), "Distance 3 should exceed limit 2")


func _test_is_within_build_height() -> void:
	print("\nTest: is_within_build_height")
	var config: Resource = _new_config()
	# max_build_height defaults to -1 (unlimited)
	_assert(config.is_within_build_height(0), "Height 0 should be within unlimited")
	_assert(config.is_within_build_height(100), "Height 100 should be within unlimited")
	_assert(config.is_within_build_height(999), "Height 999 should be within unlimited")

	# Set explicit limit
	config.max_build_height = 10
	_assert(config.is_within_build_height(10), "Height 10 should be within limit 10")
	_assert(not config.is_within_build_height(11), "Height 11 should exceed limit 10")


func _test_is_in_build_zone() -> void:
	print("\nTest: is_in_build_zone")
	var config: Resource = _new_config()
	# Default: origin (-50, -50), size (100, 100) -> covers -50 to 49
	_assert(config.is_in_build_zone(Vector3i(0, 0, 0)), "Origin should be in build zone")
	_assert(config.is_in_build_zone(Vector3i(-50, -50, 5)), "Min corner should be in build zone")
	_assert(config.is_in_build_zone(Vector3i(49, 49, 0)), "Max-1 corner should be in build zone")


func _test_is_within_ground_depth() -> void:
	print("\nTest: is_within_ground_depth")
	var config: Resource = _new_config()
	# Default ground_depth = 3
	_assert(config.is_within_ground_depth(0), "Z=0 should be within ground depth 3")
	_assert(config.is_within_ground_depth(-1), "Z=-1 should be within ground depth 3")
	_assert(config.is_within_ground_depth(-3), "Z=-3 should be within ground depth 3")


func _test_get_seconds_per_hour() -> void:
	print("\nTest: get_seconds_per_hour")
	var config: Resource = _new_config()
	config.day_length_minutes = 24.0  # 24 real minutes per day
	var sph: float = config.get_seconds_per_hour()
	# 24 minutes * 60 seconds / 24 hours = 60 seconds per hour
	_assert(is_equal_approx(sph, 60.0), "24-minute day: 60 seconds per hour, got %.1f" % sph)


func _test_from_dict() -> void:
	print("\nTest: from_dict with explicit values")
	var data := {
		"gravity": 0.16,
		"max_cantilever": 12,
		"max_build_height": 50,
		"structural_integrity": true,
		"day_length_minutes": 48.0,
		"default_time_of_day": 12.0,
		"sun_energy": 1.2,
		"ambient_energy": 0.1,
		"build_zone_origin": [-50, -50],
		"build_zone_size": [100, 100],
		"ground_depth": 5,
		"ground_type": "lunar",
		"mode": "sandbox"
	}
	var config: Resource = _call_static("from_dict", [data])
	_assert(config != null, "from_dict should return non-null config")
	_assert(is_equal_approx(config.gravity, 0.16), "Gravity should be 0.16")
	_assert(config.max_cantilever == 12, "max_cantilever should be 12")
	_assert(config.max_build_height == 50, "max_build_height should be 50")
	_assert(config.ground_depth == 5, "ground_depth should be 5")
	_assert(config.ground_type == "lunar", "ground_type should be 'lunar'")
	_assert(is_equal_approx(config.sun_energy, 1.2), "sun_energy should be 1.2")


func _test_from_dict_cantilever_auto_calc() -> void:
	print("\nTest: from_dict auto-calculates cantilever when not provided")
	var data := {
		"gravity": 0.38  # Mars - should calculate cantilever = floor(2/0.38) = 5
	}
	var config: Resource = _call_static("from_dict", [data])
	_assert(config.max_cantilever == 5, "Mars cantilever should auto-calculate to 5, got %d" % config.max_cantilever)


func _test_to_dict_roundtrip() -> void:
	print("\nTest: to_dict / from_dict round-trip")
	var original: Resource = _new_config()
	original.gravity = 0.16
	original.max_cantilever = 12
	original.max_build_height = 50
	original.ground_type = "lunar"
	original.mode = "custom"

	var dict: Dictionary = original.to_dict()
	var restored: Resource = _call_static("from_dict", [dict])

	_assert(is_equal_approx(restored.gravity, original.gravity), "Gravity should round-trip")
	_assert(restored.max_cantilever == original.max_cantilever, "max_cantilever should round-trip")
	_assert(restored.max_build_height == original.max_build_height, "max_build_height should round-trip")
	_assert(restored.ground_type == original.ground_type, "ground_type should round-trip")
	_assert(restored.mode == original.mode, "mode should round-trip")


func _test_get_summary() -> void:
	print("\nTest: get_summary")
	var config: Resource = _new_config()
	var summary: String = config.get_summary()
	_assert(summary.contains("Earth"), "Summary should contain 'Earth'")
	_assert(summary.contains("1.00"), "Summary should contain gravity '1.00'")
	_assert(summary.contains("earth"), "Summary should contain ground type 'earth'")


func _test_load_from_json() -> void:
	print("\nTest: load_from_json with earth_standard")
	var config: Resource = _call_static("load_from_json", ["res://data/scenarios/earth_standard.json"])
	if config == null:
		_assert(false, "earth_standard.json should load successfully")
		return
	_assert(is_equal_approx(config.gravity, 1.0), "Earth standard gravity should be 1.0")
	_assert(config.max_cantilever == 2, "Earth standard cantilever should be 2")
	_assert(config.ground_type == "earth", "Earth standard ground_type should be 'earth'")


func _test_load_scenario_earth() -> void:
	print("\nTest: load_scenario('earth_standard')")
	var config: Resource = _call_static("load_scenario", ["earth_standard"])
	if config == null:
		_assert(false, "earth_standard scenario should load")
		return
	_assert(is_equal_approx(config.gravity, 1.0), "Earth gravity should be 1.0")
	_assert(config.mode == "sandbox", "Earth mode should be sandbox")


# --- Negative Tests ---

func _test_invalid_json_path() -> void:
	print("\nTest: load_from_json with invalid path (negative)")
	var config: Resource = _call_static("load_from_json", ["res://data/scenarios/nonexistent.json"])
	_assert(config == null, "Nonexistent JSON should return null")


func _test_cantilever_limit_exceeded() -> void:
	print("\nTest: Cantilever limit exceeded (negative)")
	var config: Resource = _new_config()
	config.max_cantilever = 2
	_assert(not config.is_within_cantilever_limit(3), "Distance 3 should exceed cantilever limit 2")
	_assert(not config.is_within_cantilever_limit(10), "Distance 10 should exceed cantilever limit 2")
	_assert(not config.is_within_cantilever_limit(999), "Distance 999 should exceed cantilever limit 2")


func _test_build_height_exceeded() -> void:
	print("\nTest: Build height exceeded (negative)")
	var config: Resource = _new_config()
	config.max_build_height = 10
	_assert(not config.is_within_build_height(11), "Height 11 should exceed limit 10")
	_assert(not config.is_within_build_height(100), "Height 100 should exceed limit 10")


func _test_outside_build_zone() -> void:
	print("\nTest: Outside build zone (negative)")
	var config: Resource = _new_config()
	# Default: origin (-50, -50), size (100, 100) -> x range [-50, 50), y range [-50, 50)
	_assert(not config.is_in_build_zone(Vector3i(50, 0, 0)), "x=50 should be outside build zone")
	_assert(not config.is_in_build_zone(Vector3i(0, 50, 0)), "y=50 should be outside build zone")
	_assert(not config.is_in_build_zone(Vector3i(-51, 0, 0)), "x=-51 should be outside build zone")
	_assert(not config.is_in_build_zone(Vector3i(0, -51, 0)), "y=-51 should be outside build zone")


func _test_below_ground_depth() -> void:
	print("\nTest: Below ground depth (negative)")
	var config: Resource = _new_config()
	# Default ground_depth = 3
	_assert(not config.is_within_ground_depth(-4), "Z=-4 should be below ground depth 3")
	_assert(not config.is_within_ground_depth(-10), "Z=-10 should be below ground depth 3")


func _test_static_time_seconds_per_hour() -> void:
	print("\nTest: Static time returns 0 seconds per hour (negative/edge)")
	var config: Resource = _new_config()
	# day_length_minutes = 0.0 (static time)
	var sph: float = config.get_seconds_per_hour()
	_assert(is_equal_approx(sph, 0.0), "Static time should return 0 seconds per hour")


func _test_from_dict_missing_fields() -> void:
	print("\nTest: from_dict with empty dictionary uses defaults (edge)")
	var config: Resource = _call_static("from_dict", [{}])
	_assert(config != null, "Empty dict should still create config")
	_assert(is_equal_approx(config.gravity, 1.0), "Missing gravity should default to 1.0")
	_assert(config.max_cantilever == 2, "Missing fields should auto-calc cantilever from gravity=1.0")
	_assert(config.ground_type == "earth", "Missing ground_type should default to 'earth'")


func _test_zero_g_unlimited_cantilever() -> void:
	print("\nTest: Zero-G unlimited cantilever allows any distance")
	var config: Resource = _new_config()
	config.max_cantilever = -1  # Unlimited (zero-g)
	_assert(config.is_within_cantilever_limit(0), "Distance 0 should pass with unlimited")
	_assert(config.is_within_cantilever_limit(100), "Distance 100 should pass with unlimited")
	_assert(config.is_within_cantilever_limit(999999), "Distance 999999 should pass with unlimited")
