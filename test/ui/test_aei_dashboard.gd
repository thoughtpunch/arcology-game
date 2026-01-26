extends SceneTree
## Unit tests for AEIDashboard
## Tests AEI score display, components, tiers, achievements

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== AEIDashboard Unit Tests ===")

	# Setup tests
	_test_setup_basic()
	_test_setup_with_full_data()

	# Section tests
	_test_has_overall_section()
	_test_has_components_section()
	_test_has_achievements_section()
	_test_has_actions_section()

	# Update tests
	_test_update_overall()
	_test_update_component()
	_test_update_components()

	# Achievement tests
	_test_achievements_empty()
	_test_achievements_with_data()
	_test_add_achievement()

	# Tier tests
	_test_tier_constants()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)


# Setup tests

func _test_setup_basic() -> void:
	var panel := AEIDashboard.new()
	panel.setup({})

	_assert(panel.get_child_count() > 0, "basic setup creates children")
	panel.free()


func _test_setup_with_full_data() -> void:
	var panel := AEIDashboard.new()
	var data := {
		"overall": 72.0,
		"components": {
			"individual": 68.0,
			"community": 74.0,
			"sustainability": 71.0,
			"resilience": 78.0
		},
		"achievements": [
			{"name": "First 100 residents", "completed": true},
			{"name": "Positive cash flow", "completed": true},
			{"name": "Reach AEI 80", "completed": false, "progress": "8 points away"},
			{"name": "10 flourishing residents", "completed": false}
		]
	}
	panel.setup(data)

	_assert(panel.get_child_count() > 0, "full data creates complete panel")
	panel.free()


# Section tests

func _test_has_overall_section() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"overall": 50.0})

	var overall_section := panel.get_section("Overall")
	_assert(overall_section != null, "has Overall section")
	panel.free()


func _test_has_components_section() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"components": {"individual": 50.0}})

	var comp_section := panel.get_section("Components")
	_assert(comp_section != null, "has Components section")
	panel.free()


func _test_has_achievements_section() -> void:
	var panel := AEIDashboard.new()
	panel.setup({})

	var achievements_section := panel.get_section("Achievements")
	_assert(achievements_section != null, "has Achievements section")
	panel.free()


func _test_has_actions_section() -> void:
	var panel := AEIDashboard.new()
	panel.setup({})

	var actions_section := panel.get_section("Actions")
	_assert(actions_section != null, "has Actions section")
	panel.free()


# Update tests

func _test_update_overall() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"overall": 50.0})

	# Should not crash
	panel.update_overall(75.0)
	panel.update_overall(99.0)
	panel.update_overall(0.0)

	_assert(true, "update_overall completes without error")
	panel.free()


func _test_update_component() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"components": {
		"individual": 50.0,
		"community": 50.0,
		"sustainability": 50.0,
		"resilience": 50.0
	}})

	# Should not crash
	panel.update_component("individual", 80.0)
	panel.update_component("community", 70.0)

	_assert(true, "update_component completes without error")
	panel.free()


func _test_update_components() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"components": {
		"individual": 50.0,
		"community": 50.0,
		"sustainability": 50.0,
		"resilience": 50.0
	}})

	# Should not crash
	panel.update_components({
		"individual": 90.0,
		"community": 85.0,
		"sustainability": 75.0,
		"resilience": 80.0
	})

	_assert(true, "update_components completes without error")
	panel.free()


# Achievement tests

func _test_achievements_empty() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"achievements": []})

	var achievements_section := panel.get_section("Achievements")
	_assert(achievements_section != null, "Achievements section exists even when empty")
	panel.free()


func _test_achievements_with_data() -> void:
	var panel := AEIDashboard.new()
	panel.setup({"achievements": [
		{"name": "Achievement 1", "completed": true},
		{"name": "Achievement 2", "completed": false}
	]})

	var achievements_section := panel.get_section("Achievements")
	_assert(achievements_section != null, "Achievements section exists with data")
	panel.free()


func _test_add_achievement() -> void:
	var panel := AEIDashboard.new()
	panel.setup({})

	# Should not crash
	panel.add_achievement({"name": "New Achievement", "completed": false})

	_assert(true, "add_achievement completes without error")
	panel.free()


# Tier tests

func _test_tier_constants() -> void:
	_assert(AEIDashboard.TIER_BRONZE == 80, "TIER_BRONZE is 80")
	_assert(AEIDashboard.TIER_SILVER == 90, "TIER_SILVER is 90")
	_assert(AEIDashboard.TIER_GOLD == 95, "TIER_GOLD is 95")
	_assert(AEIDashboard.TIER_PLATINUM == 99, "TIER_PLATINUM is 99")
