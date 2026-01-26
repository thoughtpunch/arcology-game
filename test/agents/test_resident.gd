extends SceneTree
## Tests for Resident class
## Run with: godot --headless --script test/agents/test_resident.gd

const ResidentScript: GDScript = preload("res://src/agents/resident.gd")

var _tests_passed := 0
var _tests_failed := 0


func _init() -> void:
	print("=== Resident Tests ===")

	_test_instantiation()
	_test_default_needs()
	_test_need_modification()
	_test_need_clamping()
	_test_critical_need_detection()
	_test_lowest_need()
	_test_flourishing_survival_gate()
	_test_flourishing_all_needs_met()
	_test_mood_updates()
	_test_activity_state()
	_test_movement()
	_test_serialization()
	_test_flight_risk()
	_test_signals()

	print("\n=== Results: %d passed, %d failed ===" % [_tests_passed, _tests_failed])
	quit()


func _create_resident() -> Node2D:
	return ResidentScript.new()


func _pass(test_name: String) -> void:
	print("  ✓ %s" % test_name)
	_tests_passed += 1


func _fail(test_name: String, message: String) -> void:
	print("  ✗ %s: %s" % [test_name, message])
	_tests_failed += 1


func _test_instantiation() -> void:
	var resident: Node2D = _create_resident()
	resident.resident_name = "Test Person"
	resident.age = 30

	assert(resident.resident_name == "Test Person", "Name should be set")
	assert(resident.age == 30, "Age should be set")
	assert(resident.archetype == "young_professional", "Default archetype should be young_professional")

	_pass("instantiation")
	resident.free()


func _test_default_needs() -> void:
	var resident: Node2D = _create_resident()

	assert(resident.get_need("survival") == 80.0, "Default survival should be 80")
	assert(resident.get_need("safety") == 70.0, "Default safety should be 70")
	assert(resident.get_need("belonging") == 60.0, "Default belonging should be 60")
	assert(resident.get_need("esteem") == 50.0, "Default esteem should be 50")
	assert(resident.get_need("purpose") == 50.0, "Default purpose should be 50")

	_pass("default_needs")
	resident.free()


func _test_need_modification() -> void:
	var resident: Node2D = _create_resident()

	resident.set_need("survival", 50.0)
	assert(resident.get_need("survival") == 50.0, "Need should be set to 50")

	resident.modify_need("survival", 10.0)
	assert(resident.get_need("survival") == 60.0, "Need should be 60 after +10")

	resident.modify_need("survival", -20.0)
	assert(resident.get_need("survival") == 40.0, "Need should be 40 after -20")

	_pass("need_modification")
	resident.free()


func _test_need_clamping() -> void:
	var resident: Node2D = _create_resident()

	# Test upper bound
	resident.set_need("survival", 150.0)
	assert(resident.get_need("survival") == 100.0, "Need should clamp to 100")

	# Test lower bound
	resident.set_need("survival", -50.0)
	assert(resident.get_need("survival") == 0.0, "Need should clamp to 0")

	_pass("need_clamping")
	resident.free()


func _test_critical_need_detection() -> void:
	var resident: Node2D = _create_resident()

	# Set one need to critical level
	resident.set_need("survival", 15.0)

	assert(resident.is_need_critical("survival") == true, "Survival should be critical")
	assert(resident.is_need_critical("safety") == false, "Safety should not be critical")

	var critical_needs: Array = resident.get_critical_needs()
	assert(critical_needs.size() == 1, "Should have 1 critical need")
	assert(critical_needs[0] == "survival", "Critical need should be survival")

	_pass("critical_need_detection")
	resident.free()


func _test_lowest_need() -> void:
	var resident: Node2D = _create_resident()

	# Default: purpose and esteem are lowest at 50
	resident.set_need("purpose", 30.0)

	assert(resident.get_lowest_need() == "purpose", "Lowest need should be purpose")

	_pass("lowest_need")
	resident.free()


func _test_flourishing_survival_gate() -> void:
	var resident: Node2D = _create_resident()

	# Low survival should cap flourishing
	resident.set_need("survival", 30.0)
	resident.set_need("safety", 90.0)
	resident.set_need("belonging", 90.0)
	resident.set_need("esteem", 90.0)
	resident.set_need("purpose", 90.0)

	var flourishing: float = resident.calculate_flourishing()
	assert(flourishing < 15, "Flourishing should be gated by low survival (got %.1f)" % flourishing)

	_pass("flourishing_survival_gate")
	resident.free()


func _test_flourishing_all_needs_met() -> void:
	var resident: Node2D = _create_resident()

	# All needs high
	resident.set_need("survival", 90.0)
	resident.set_need("safety", 80.0)
	resident.set_need("belonging", 70.0)
	resident.set_need("esteem", 60.0)
	resident.set_need("purpose", 80.0)

	var flourishing: float = resident.calculate_flourishing()
	assert(flourishing >= 70, "Flourishing should be high when all needs met (got %.1f)" % flourishing)

	_pass("flourishing_all_needs_met")
	resident.free()


func _test_mood_updates() -> void:
	var resident: Node2D = _create_resident()

	# Set needs for high flourishing
	resident.set_need("survival", 90.0)
	resident.set_need("safety", 80.0)
	resident.set_need("belonging", 70.0)
	resident.set_need("esteem", 60.0)
	resident.set_need("purpose", 80.0)

	# Get mood enum values from script constants
	var mood_happy: int = ResidentScript.Mood.HAPPY
	var mood_content: int = ResidentScript.Mood.CONTENT
	var mood_miserable: int = ResidentScript.Mood.MISERABLE

	assert(resident.get_mood() == mood_happy or resident.get_mood() == mood_content,
		   "Mood should be happy or content with high flourishing")

	# Drop survival
	resident.set_need("survival", 10.0)
	assert(resident.get_mood() == mood_miserable,
		   "Mood should be miserable with critical survival")

	_pass("mood_updates")
	resident.free()


func _test_activity_state() -> void:
	var resident: Node2D = _create_resident()

	var activity_idle: int = ResidentScript.Activity.IDLE
	var activity_working: int = ResidentScript.Activity.WORKING

	assert(resident.get_activity() == activity_idle, "Default activity should be IDLE")

	resident.set_activity(activity_working)
	assert(resident.get_activity() == activity_working, "Activity should be WORKING")
	assert(resident.get_activity_string() == "working", "Activity string should be 'working'")

	_pass("activity_state")
	resident.free()


func _test_movement() -> void:
	var resident: Node2D = _create_resident()
	resident.current_position = Vector3i(0, 0, 0)
	resident.home_block = Vector3i(0, 0, 0)
	resident.workplace_block = Vector3i(5, 5, 1)

	var activity_traveling: int = ResidentScript.Activity.TRAVELING
	var activity_idle: int = ResidentScript.Activity.IDLE

	assert(resident.is_at_home() == true, "Should be at home")
	assert(resident.is_at_work() == false, "Should not be at work")
	assert(resident.has_job() == true, "Should have a job")

	resident.move_to(Vector3i(5, 5, 1))
	assert(resident.get_activity() == activity_traveling, "Should be traveling")

	resident.arrive_at(Vector3i(5, 5, 1))
	resident.current_position = Vector3i(5, 5, 1)
	assert(resident.is_at_work() == true, "Should be at work")
	assert(resident.get_activity() == activity_idle, "Should be idle after arrival")

	_pass("movement")
	resident.free()


func _test_serialization() -> void:
	var resident: Node2D = _create_resident()
	resident.resident_name = "Test Person"
	resident.age = 35
	resident.home_block = Vector3i(1, 2, 3)
	resident.set_need("survival", 75.0)
	resident.openness = 80

	var data: Dictionary = resident.to_dict()
	var restored: Node2D = ResidentScript.from_dict(data)

	assert(restored.resident_name == "Test Person", "Name should be restored")
	assert(restored.age == 35, "Age should be restored")
	assert(restored.home_block == Vector3i(1, 2, 3), "Home block should be restored")
	assert(restored.get_need("survival") == 75.0, "Need should be restored")
	assert(restored.openness == 80, "Personality should be restored")

	_pass("serialization")
	resident.free()
	restored.free()


func _test_flight_risk() -> void:
	var resident: Node2D = _create_resident()

	# Good conditions - low risk
	resident.set_need("survival", 90.0)
	resident.set_need("safety", 80.0)
	resident.set_need("belonging", 70.0)
	resident.set_need("esteem", 60.0)
	resident.set_need("purpose", 80.0)
	resident._residence_months = 24
	resident._calculate_flight_risk()

	assert(resident.get_flight_risk() < 30, "Flight risk should be low with good conditions")

	# Poor conditions - high risk
	resident.set_need("survival", 15.0)
	resident.set_need("safety", 20.0)
	resident._residence_months = 1
	resident._calculate_flight_risk()

	assert(resident.get_flight_risk() > 50, "Flight risk should be high with poor conditions")

	_pass("flight_risk")
	resident.free()


func _test_signals() -> void:
	var resident: Node2D = _create_resident()
	var signal_received := []

	resident.needs_changed.connect(func(need_name: String, old_value: float, new_value: float) -> void:
		signal_received.append({"need": need_name, "old": old_value, "new": new_value})
	)

	resident.set_need("survival", 50.0)

	assert(signal_received.size() == 1, "Should receive needs_changed signal")
	assert(signal_received[0]["need"] == "survival", "Signal should contain need name")
	assert(signal_received[0]["new"] == 50.0, "Signal should contain new value")

	_pass("signals")
	resident.free()
