extends SceneTree
## Unit tests for AutoSave class

var _tests_run := 0
var _tests_passed := 0


func _init() -> void:
	print("=== AutoSave Tests ===")

	# Basic construction tests
	_test_creates_without_error()
	_test_enabled_by_default()
	_test_default_interval()

	# Enable/disable tests
	_test_can_disable()
	_test_can_enable()
	_test_is_enabled_returns_state()

	# Interval tests
	_test_can_set_interval()
	_test_get_interval()
	_test_minimum_interval()

	# Save state tests
	_test_not_saving_initially()
	_test_last_save_time_zero_initially()

	# Signal tests (basic - can't fully test without game running)
	_test_has_signals()

	# Cleanup tests
	_test_max_auto_saves_constant()

	# Negative tests
	_test_interval_minimum_enforced()
	_test_no_double_save()

	print("\n=== Results: %d/%d tests passed ===" % [_tests_passed, _tests_run])

	if _tests_passed < _tests_run:
		quit(1)
	else:
		quit(0)


func _test_creates_without_error() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save != null, "AutoSave should create without error")
	auto_save.queue_free()


func _test_enabled_by_default() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.is_enabled() == true, "Should be enabled by default")
	auto_save.queue_free()


func _test_default_interval() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.get_interval() == AutoSave.DEFAULT_INTERVAL_MINUTES, "Should have default interval of 10 minutes")
	auto_save.queue_free()


func _test_can_disable() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_enabled(false)
	_assert(auto_save.is_enabled() == false, "Should be able to disable")
	auto_save.queue_free()


func _test_can_enable() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_enabled(false)
	auto_save.set_enabled(true)
	_assert(auto_save.is_enabled() == true, "Should be able to re-enable")
	auto_save.queue_free()


func _test_is_enabled_returns_state() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.is_enabled() == true, "is_enabled should return true when enabled")
	auto_save.set_enabled(false)
	_assert(auto_save.is_enabled() == false, "is_enabled should return false when disabled")
	auto_save.queue_free()


func _test_can_set_interval() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_interval(15)
	_assert(auto_save.get_interval() == 15, "Should be able to set interval to 15 minutes")
	auto_save.queue_free()


func _test_get_interval() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_interval(30)
	_assert(auto_save.get_interval() == 30, "get_interval should return current interval")
	auto_save.queue_free()


func _test_minimum_interval() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_interval(1)
	_assert(auto_save.get_interval() >= 1, "Interval should be at least 1 minute")
	auto_save.queue_free()


func _test_not_saving_initially() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.is_saving() == false, "Should not be saving initially")
	auto_save.queue_free()


func _test_last_save_time_zero_initially() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.get_last_save_time() == 0.0, "Last save time should be 0 initially")
	auto_save.queue_free()


func _test_has_signals() -> void:
	var auto_save := AutoSave.new()
	_assert(auto_save.has_signal("auto_save_started"), "Should have auto_save_started signal")
	_assert(auto_save.has_signal("auto_save_completed"), "Should have auto_save_completed signal")
	_assert(auto_save.has_signal("auto_save_failed"), "Should have auto_save_failed signal")
	auto_save.queue_free()


func _test_max_auto_saves_constant() -> void:
	_assert(AutoSave.MAX_AUTO_SAVES == 3, "MAX_AUTO_SAVES should be 3")


func _test_interval_minimum_enforced() -> void:
	var auto_save := AutoSave.new()
	auto_save.set_interval(0)
	_assert(auto_save.get_interval() >= 1, "Interval should not be less than 1")
	auto_save.set_interval(-5)
	_assert(auto_save.get_interval() >= 1, "Negative interval should be clamped to 1")
	auto_save.queue_free()


func _test_no_double_save() -> void:
	var auto_save := AutoSave.new()
	# Can't fully test without scene tree, but verify the flag exists
	_assert(auto_save.is_saving() == false, "Should not be in save state")
	# If we call trigger_auto_save when already saving, it should be a no-op
	# This is mainly a design verification test
	auto_save.queue_free()


func _assert(condition: bool, message: String) -> void:
	_tests_run += 1
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		print("  ✗ %s" % message)
