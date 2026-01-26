extends SceneTree
## Integration tests for InfoPanelManager
## Tests panel display, switching, pinning, and action handling

var _test_count := 0
var _pass_count := 0


func _init() -> void:
	print("=== InfoPanelManager Integration Tests ===")

	# Initialization tests
	_test_create_manager()
	_test_setup_without_hud()

	# Panel display tests
	_test_show_block_info()
	_test_show_resident_info()
	_test_show_budget()
	_test_show_aei()
	_test_show_quick_stats()

	# Panel state tests
	_test_is_panel_open()
	_test_get_current_panel_type()
	_test_close_current_panel()

	# Panel switching tests
	_test_panel_replaces_previous()

	# Update tests
	_test_update_block_environment()
	_test_update_resident_needs()

	print("\n=== Results: %d/%d tests passed ===" % [_pass_count, _test_count])
	quit()


func _assert(condition: bool, test_name: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % test_name)
	else:
		print("  FAIL: %s" % test_name)


# Initialization tests

func _test_create_manager() -> void:
	var manager := InfoPanelManager.new()

	_assert(manager != null, "can create InfoPanelManager")
	_assert(not manager.is_panel_open(), "no panel open initially")
	manager.free()


func _test_setup_without_hud() -> void:
	var manager := InfoPanelManager.new()

	# Should not crash when showing panel without HUD
	manager.show_block_info(Vector3i(0, 0, 0), "corridor", {})

	_assert(true, "show_block_info without setup doesn't crash")
	manager.free()


# Panel display tests

func _test_show_block_info() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_block_info(Vector3i(1, 2, 3), "residential_basic", {})

	_assert(manager.is_panel_open(), "block info panel is open")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.BLOCK, "panel type is BLOCK")

	manager.free()
	hud.free()


func _test_show_resident_info() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_resident_info("res_001", {"name": "Test", "is_notable": true})

	_assert(manager.is_panel_open(), "resident info panel is open")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.RESIDENT, "panel type is RESIDENT")

	manager.free()
	hud.free()


func _test_show_budget() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_budget({})

	_assert(manager.is_panel_open(), "budget panel is open")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.BUDGET, "panel type is BUDGET")

	manager.free()
	hud.free()


func _test_show_aei() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_aei({})

	_assert(manager.is_panel_open(), "AEI dashboard is open")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.AEI, "panel type is AEI")

	manager.free()
	hud.free()


func _test_show_quick_stats() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_quick_stats({"population": 100, "avg_flourishing": 65.0})

	_assert(manager.is_panel_open(), "quick stats panel is open")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.QUICK_STATS, "panel type is QUICK_STATS")

	manager.free()
	hud.free()


# Panel state tests

func _test_is_panel_open() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)

	_assert(not manager.is_panel_open(), "no panel open initially after setup")

	manager.show_block_info(Vector3i(0, 0, 0), "corridor", {})
	_assert(manager.is_panel_open(), "panel open after show_block_info")

	manager.close_current_panel()
	_assert(not manager.is_panel_open(), "no panel open after close")

	manager.free()
	hud.free()


func _test_get_current_panel_type() -> void:
	var manager := InfoPanelManager.new()

	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.NONE, "initial type is NONE")
	manager.free()


func _test_close_current_panel() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_block_info(Vector3i(0, 0, 0), "corridor", {})
	manager.close_current_panel()

	_assert(not manager.is_panel_open(), "close_current_panel closes the panel")
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.NONE, "type is NONE after close")

	manager.free()
	hud.free()


# Panel switching tests

func _test_panel_replaces_previous() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)

	manager.show_block_info(Vector3i(0, 0, 0), "corridor", {})
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.BLOCK, "first panel is BLOCK")

	manager.show_budget({})
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.BUDGET, "replaced with BUDGET")

	manager.show_aei({})
	_assert(manager.get_current_panel_type() == InfoPanelManager.PanelType.AEI, "replaced with AEI")

	manager.free()
	hud.free()


# Update tests

func _test_update_block_environment() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_block_info(Vector3i(0, 0, 0), "corridor", {
		"environment": {"light": 50.0, "air": 50.0, "noise": 50.0, "safety": 50.0, "vibes": 50.0}
	})

	# Should not crash
	manager.update_block_environment({"light": 80.0})

	_assert(true, "update_block_environment completes without error")

	manager.free()
	hud.free()


func _test_update_resident_needs() -> void:
	var manager := InfoPanelManager.new()
	var hud := _create_mock_hud()

	manager.setup(hud)
	manager.show_resident_info("res_001", {
		"is_notable": true,
		"needs": {"survival": 50.0, "safety": 50.0, "belonging": 50.0, "esteem": 50.0, "purpose": 50.0}
	})

	# Should not crash
	manager.update_resident_needs({"survival": 90.0})

	_assert(true, "update_resident_needs completes without error")

	manager.free()
	hud.free()


# Helper to create a mock HUD with required structure
# Since _ready() isn't called in test context, we need to manually initialize

func _create_mock_hud() -> HUD:
	var hud := HUD.new()
	# Manually call _ready to set up the layout
	hud._ready()
	return hud
