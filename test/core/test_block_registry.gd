extends SceneTree
## Test script for BlockRegistry autoload
## Run with: godot --headless --script test/test_block_registry.gd

func _init() -> void:
	var tests_passed := 0
	var tests_failed := 0

	print("=== BlockRegistry Tests ===")

	# Wait for autoload to be ready
	await process_frame

	# Test 1: BlockRegistry singleton exists
	print("\nTest 1: Singleton accessible")
	var registry = get_root().get_node_or_null("/root/BlockRegistry")
	if registry != null:
		print("  PASS: BlockRegistry is accessible at /root/BlockRegistry")
		tests_passed += 1
	else:
		print("  FAIL: BlockRegistry not found")
		tests_failed += 1
		_finish(tests_passed, tests_failed)
		return

	# Test 2: blocks.json loaded without errors
	print("\nTest 2: Blocks loaded")
	var types = registry.get_all_types()
	if types.size() >= 6:
		print("  PASS: Loaded %d block types (>= 6)" % types.size())
		tests_passed += 1
	else:
		print("  FAIL: Only loaded %d block types" % types.size())
		tests_failed += 1

	# Test 3: get_block_data returns correct dictionary
	print("\nTest 3: get_block_data returns correct data")
	var corridor_data = registry.get_block_data("corridor")
	if corridor_data.has("name") and corridor_data.name == "Corridor":
		print("  PASS: corridor.name = 'Corridor'")
		tests_passed += 1
	else:
		print("  FAIL: corridor data incorrect: %s" % corridor_data)
		tests_failed += 1

	if corridor_data.get("cost", -1) == 50:
		print("  PASS: corridor.cost = 50")
		tests_passed += 1
	else:
		print("  FAIL: corridor.cost = %s" % corridor_data.get("cost", "missing"))
		tests_failed += 1

	# Test 4: Returns empty for unknown types
	print("\nTest 4: Unknown type returns empty")
	var unknown_data = registry.get_block_data("nonexistent_block")
	if unknown_data.is_empty():
		print("  PASS: Unknown type returns empty dictionary")
		tests_passed += 1
	else:
		print("  FAIL: Unknown type returned: %s" % unknown_data)
		tests_failed += 1

	# Test 5: has_type works
	print("\nTest 5: has_type")
	if registry.has_type("corridor"):
		print("  PASS: has_type('corridor') = true")
		tests_passed += 1
	else:
		print("  FAIL: has_type('corridor') = false")
		tests_failed += 1

	if not registry.has_type("nonexistent"):
		print("  PASS: has_type('nonexistent') = false")
		tests_passed += 1
	else:
		print("  FAIL: has_type('nonexistent') = true")
		tests_failed += 1

	# Test 6: get_all_types returns expected types
	print("\nTest 6: Expected block types exist")
	var expected_types = ["corridor", "entrance", "stairs", "elevator_shaft", "residential_basic", "commercial_basic"]
	var all_found = true
	for type_id in expected_types:
		if not registry.has_type(type_id):
			print("  FAIL: Missing type '%s'" % type_id)
			all_found = false
	if all_found:
		print("  PASS: All 6 expected block types found")
		tests_passed += 1
	else:
		tests_failed += 1

	# Test 7: Traversability lookup
	print("\nTest 7: Traversability lookup")
	if registry.get_traversability("corridor") == "public":
		print("  PASS: corridor traversability = 'public'")
		tests_passed += 1
	else:
		print("  FAIL: corridor traversability = '%s'" % registry.get_traversability("corridor"))
		tests_failed += 1

	if registry.get_traversability("residential_basic") == "private":
		print("  PASS: residential_basic traversability = 'private'")
		tests_passed += 1
	else:
		print("  FAIL: residential_basic traversability = '%s'" % registry.get_traversability("residential_basic"))
		tests_failed += 1

	# Test 8: ground_only property
	print("\nTest 8: ground_only property")
	if registry.is_ground_only("entrance"):
		print("  PASS: entrance is ground_only")
		tests_passed += 1
	else:
		print("  FAIL: entrance should be ground_only")
		tests_failed += 1

	if not registry.is_ground_only("corridor"):
		print("  PASS: corridor is NOT ground_only")
		tests_passed += 1
	else:
		print("  FAIL: corridor should not be ground_only")
		tests_failed += 1

	# Test 9: connects_vertical property
	print("\nTest 9: connects_vertical property")
	if registry.connects_vertical("stairs"):
		print("  PASS: stairs connects_vertical")
		tests_passed += 1
	else:
		print("  FAIL: stairs should connect vertically")
		tests_failed += 1

	if registry.connects_vertical("elevator_shaft"):
		print("  PASS: elevator_shaft connects_vertical")
		tests_passed += 1
	else:
		print("  FAIL: elevator_shaft should connect vertically")
		tests_failed += 1

	if not registry.connects_vertical("corridor"):
		print("  PASS: corridor does NOT connect vertically")
		tests_passed += 1
	else:
		print("  FAIL: corridor should not connect vertically")
		tests_failed += 1

	_finish(tests_passed, tests_failed)


func _finish(passed: int, failed: int) -> void:
	print("\n=== Results ===")
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)

	if failed > 0:
		quit(1)
	else:
		quit(0)
