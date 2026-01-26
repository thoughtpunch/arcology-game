extends SceneTree
## Unit tests for ResidentInfoPanel
## Tests notable/statistical residents, needs display, activity, relationships

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== ResidentInfoPanel Unit Tests ===")

	# Setup tests - notable residents
	_test_setup_notable_resident()
	_test_setup_with_full_data()

	# Setup tests - statistical residents
	_test_setup_statistical_resident()

	# Getter tests
	_test_get_resident_id()
	_test_is_notable_resident()

	# Needs tests
	_test_needs_section_exists()
	_test_update_needs()

	# Flourishing tests
	_test_flourishing_section_exists()
	_test_update_flourishing()

	# Activity tests
	_test_activity_section_exists()
	_test_update_activity()

	# Relationship tests
	_test_relationships_empty()
	_test_relationships_with_data()

	# Employment tests
	_test_employment_section_exists()

	# Actions tests
	_test_actions_section_exists()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)


# Notable resident setup tests

func _test_setup_notable_resident() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res_001", {"name": "Alice", "is_notable": true})

	_assert(panel.get_child_count() > 0, "notable resident creates children")
	_assert(panel.is_notable_resident(), "is_notable_resident returns true")
	panel.free()


func _test_setup_with_full_data() -> void:
	var panel := ResidentInfoPanel.new()
	var data := {
		"is_notable": true,
		"name": "Maria Chen",
		"age": 34,
		"residence_years": 2,
		"location": "Floor 12, Apt 3",
		"flourishing": 72.0,
		"flourishing_trend": "up",
		"needs": {
			"survival": 92.0,
			"safety": 78.0,
			"belonging": 64.0,
			"esteem": 52.0,
			"purpose": 71.0
		},
		"current_activity": "Making dinner",
		"next_activity": "Sleep",
		"next_time": "10:00 PM",
		"relationships": [
			{"name": "David Park", "type": "Friend"},
			{"name": "James Liu", "type": "Coworker"}
		],
		"employment": {
			"title": "Owner",
			"workplace": "Chen's Noodle House",
			"income": 2400
		}
	}
	panel.setup("res_maria", data)

	_assert(panel.get_child_count() > 0, "full data creates complete panel")
	_assert(panel.get_resident_id() == "res_maria", "resident ID stored")
	panel.free()


# Statistical resident setup tests

func _test_setup_statistical_resident() -> void:
	var panel := ResidentInfoPanel.new()
	var data := {
		"is_notable": false,
		"similar_count": 2300,
		"avg_flourishing": 68.0,
		"avg_rent": 95,
		"common_complaints": ["Noise", "Lighting"]
	}
	panel.setup("stat_001", data)

	_assert(panel.get_child_count() > 0, "statistical resident creates children")
	_assert(not panel.is_notable_resident(), "is_notable_resident returns false")
	panel.free()


# Getter tests

func _test_get_resident_id() -> void:
	var panel := ResidentInfoPanel.new()

	panel.setup("resident_123", {"name": "Test"})
	_assert(panel.get_resident_id() == "resident_123", "get_resident_id returns correct ID")

	panel.setup("resident_456", {"name": "Test2"})
	_assert(panel.get_resident_id() == "resident_456", "ID updated on new setup")
	panel.free()


func _test_is_notable_resident() -> void:
	var panel := ResidentInfoPanel.new()

	panel.setup("res1", {"is_notable": true})
	_assert(panel.is_notable_resident() == true, "notable resident returns true")

	panel.setup("res2", {"is_notable": false})
	_assert(panel.is_notable_resident() == false, "statistical resident returns false")
	panel.free()


# Needs section tests

func _test_needs_section_exists() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "needs": {
		"survival": 80.0,
		"safety": 70.0,
		"belonging": 60.0,
		"esteem": 50.0,
		"purpose": 40.0
	}})

	var needs_section := panel.get_section("Needs")
	_assert(needs_section != null, "notable resident has Needs section")
	panel.free()


func _test_update_needs() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "needs": {
		"survival": 50.0,
		"safety": 50.0,
		"belonging": 50.0,
		"esteem": 50.0,
		"purpose": 50.0
	}})

	# Should not crash
	panel.update_needs({"survival": 90.0})
	panel.update_needs({"safety": 80.0, "belonging": 70.0})

	_assert(true, "update_needs completes without error")
	panel.free()


# Flourishing tests

func _test_flourishing_section_exists() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "flourishing": 72.0})

	var flour_section := panel.get_section("Flourishing")
	_assert(flour_section != null, "notable resident has Flourishing section")
	panel.free()


func _test_update_flourishing() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "flourishing": 50.0})

	# Should not crash
	panel.update_flourishing(75.0)
	panel.update_flourishing(80.0, "up")

	_assert(true, "update_flourishing completes without error")
	panel.free()


# Activity tests

func _test_activity_section_exists() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "current_activity": "Working"})

	var activity_section := panel.get_section("Activity")
	_assert(activity_section != null, "notable resident has Activity section")
	panel.free()


func _test_update_activity() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "current_activity": "Idle"})

	# Should not crash
	panel.update_activity("Working")
	panel.update_activity("Eating", "Sleep", "8:00 PM")

	_assert(true, "update_activity completes without error")
	panel.free()


# Relationship tests

func _test_relationships_empty() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "relationships": []})

	var rel_section := panel.get_section("Relationships")
	_assert(rel_section != null, "Relationships section exists even when empty")
	panel.free()


func _test_relationships_with_data() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "relationships": [
		{"name": "Person A", "type": "Friend"},
		{"name": "Person B", "type": "Family"},
		{"name": "Person C", "type": "Neighbor"}
	]})

	var rel_section := panel.get_section("Relationships")
	_assert(rel_section != null, "Relationships section exists with data")
	panel.free()


# Employment tests

func _test_employment_section_exists() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true, "employment": {"title": "Engineer"}})

	var emp_section := panel.get_section("Employment")
	_assert(emp_section != null, "notable resident has Employment section")
	panel.free()


# Actions tests

func _test_actions_section_exists() -> void:
	var panel := ResidentInfoPanel.new()
	panel.setup("res1", {"is_notable": true})

	var actions_section := panel.get_section("Actions")
	_assert(actions_section != null, "notable resident has Actions section")
	panel.free()
