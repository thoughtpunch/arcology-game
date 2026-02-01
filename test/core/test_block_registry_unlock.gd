extends SceneTree
## Tests for BlockRegistry block unlocking system
## Verifies: unlock/lock, sandbox unlock all, default blocks

var _registry_script = preload("res://src/game/block_registry.gd")


func _init():
	print("=== test_block_registry_unlock.gd ===")
	var passed := 0
	var failed := 0

	# Run all tests
	var results := [
		_test_default_unlocked(),
		_test_is_unlocked(),
		_test_unlock_block(),
		_test_lock_block(),
		_test_unlock_all(),
		_test_lock_all_to_defaults(),
		_test_get_unlocked_types(),
		_test_is_all_unlocked(),
	]

	for result in results:
		if result:
			passed += 1
		else:
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])

	if failed > 0:
		quit(1)
	else:
		quit(0)


func _test_default_unlocked() -> bool:
	print("\nTest: default_unlocked")
	var registry: Node = _registry_script.new()
	# Manually call ready to load blocks
	registry._load_blocks()
	registry._reset_unlocked()

	# Check default unlocked blocks
	assert(registry.is_unlocked("entrance"), "entrance should be unlocked by default")
	assert(registry.is_unlocked("corridor"), "corridor should be unlocked by default")
	assert(registry.is_unlocked("residential_basic"), "residential_basic should be unlocked by default")
	assert(registry.is_unlocked("stairs"), "stairs should be unlocked by default")

	# Non-default blocks should be locked
	assert(registry.is_unlocked("elevator_shaft") == false, "elevator_shaft should be locked by default")
	assert(registry.is_unlocked("commercial_basic") == false, "commercial_basic should be locked by default")

	registry.free()
	print("  PASSED")
	return true


func _test_is_unlocked() -> bool:
	print("\nTest: is_unlocked")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# Default unlocked
	assert(registry.is_unlocked("entrance") == true, "entrance is unlocked")
	assert(registry.is_unlocked("corridor") == true, "corridor is unlocked")

	# Not unlocked
	assert(registry.is_unlocked("elevator_shaft") == false, "elevator_shaft is locked")
	assert(registry.is_unlocked("commercial_basic") == false, "commercial_basic is locked")

	# Non-existent block (should return false)
	assert(registry.is_unlocked("nonexistent") == false, "nonexistent block is locked")

	registry.free()
	print("  PASSED")
	return true


func _test_unlock_block() -> bool:
	print("\nTest: unlock_block")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# Verify initially locked
	assert(registry.is_unlocked("elevator_shaft") == false, "elevator_shaft starts locked")

	# Unlock it
	registry.unlock_block("elevator_shaft")

	# Verify now unlocked
	assert(registry.is_unlocked("elevator_shaft") == true, "elevator_shaft should now be unlocked")

	# Double unlock should be safe
	registry.unlock_block("elevator_shaft")
	assert(registry.is_unlocked("elevator_shaft") == true, "Double unlock should be safe")

	registry.free()
	print("  PASSED")
	return true


func _test_lock_block() -> bool:
	print("\nTest: lock_block")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# Verify initially unlocked
	assert(registry.is_unlocked("corridor") == true, "corridor starts unlocked")

	# Lock it
	registry.lock_block("corridor")

	# Verify now locked
	assert(registry.is_unlocked("corridor") == false, "corridor should now be locked")

	# Double lock should be safe
	registry.lock_block("corridor")
	assert(registry.is_unlocked("corridor") == false, "Double lock should be safe")

	registry.free()
	print("  PASSED")
	return true


func _test_unlock_all() -> bool:
	print("\nTest: unlock_all")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# Verify some blocks are locked
	assert(registry.is_unlocked("elevator_shaft") == false, "elevator_shaft starts locked")
	assert(registry.is_unlocked("commercial_basic") == false, "commercial_basic starts locked")

	# Unlock all
	registry.unlock_all()

	# Now all blocks should be unlocked
	assert(registry.is_unlocked("elevator_shaft") == true, "elevator_shaft should be unlocked")
	assert(registry.is_unlocked("commercial_basic") == true, "commercial_basic should be unlocked")
	assert(registry.is_unlocked("entrance") == true, "entrance still unlocked")

	registry.free()
	print("  PASSED")
	return true


func _test_lock_all_to_defaults() -> bool:
	print("\nTest: lock_all_to_defaults")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# First unlock all
	registry.unlock_all()
	assert(registry.is_unlocked("elevator_shaft") == true, "elevator_shaft unlocked by unlock_all")

	# Then lock to defaults
	registry.lock_all_to_defaults()

	# Defaults should be unlocked
	assert(registry.is_unlocked("entrance") == true, "entrance should be unlocked")
	assert(registry.is_unlocked("corridor") == true, "corridor should be unlocked")

	# Non-defaults should be locked again
	assert(registry.is_unlocked("elevator_shaft") == false, "elevator_shaft should be locked again")
	assert(registry.is_unlocked("commercial_basic") == false, "commercial_basic should be locked again")

	registry.free()
	print("  PASSED")
	return true


func _test_get_unlocked_types() -> bool:
	print("\nTest: get_unlocked_types")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	var unlocked: Array = registry.get_unlocked_types()

	# Should contain defaults
	assert("entrance" in unlocked, "entrance in unlocked types")
	assert("corridor" in unlocked, "corridor in unlocked types")
	assert("residential_basic" in unlocked, "residential_basic in unlocked types")
	assert("stairs" in unlocked, "stairs in unlocked types")

	# Should not contain non-defaults
	assert("elevator_shaft" not in unlocked, "elevator_shaft not in unlocked types")
	assert("commercial_basic" not in unlocked, "commercial_basic not in unlocked types")

	# Unlock all and check again
	registry.unlock_all()
	var all_unlocked: Array = registry.get_unlocked_types()
	assert(all_unlocked.size() >= 6, "Should have all block types")
	assert("elevator_shaft" in all_unlocked, "elevator_shaft in all unlocked")
	assert("commercial_basic" in all_unlocked, "commercial_basic in all unlocked")

	registry.free()
	print("  PASSED")
	return true


func _test_is_all_unlocked() -> bool:
	print("\nTest: is_all_unlocked")
	var registry: Node = _registry_script.new()
	registry._load_blocks()
	registry._reset_unlocked()

	# Initially not all unlocked
	assert(registry.is_all_unlocked() == false, "Should not be all unlocked initially")

	# After unlock_all
	registry.unlock_all()
	assert(registry.is_all_unlocked() == true, "Should be all unlocked after unlock_all")

	# After lock_all_to_defaults
	registry.lock_all_to_defaults()
	assert(registry.is_all_unlocked() == false, "Should not be all unlocked after lock_all_to_defaults")

	registry.free()
	print("  PASSED")
	return true
