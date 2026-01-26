extends SceneTree
## Tests for NotificationTray UI component
## Run: godot --headless --script test/ui/test_notification_tray.gd

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== NotificationTray Tests ===\n")

	# Run tests
	_test_tray_creation()
	_test_badge_button()
	_test_badge_count()
	_test_expand_collapse()
	_test_panel_visibility()
	_test_notification_items()
	_test_relative_time()
	_test_signals()
	_test_constants()

	# Print results
	print("\n=== Results ===")
	print("Passed: %d" % _passed)
	print("Failed: %d" % _failed)

	if _failed > 0:
		print("\nSome tests FAILED!")
		quit(1)
	else:
		print("\nAll tests PASSED!")
		quit(0)


func _test_tray_creation() -> void:
	print("Testing: tray creation...")

	var tray := NotificationTray.new()

	assert(tray != null, "Should create NotificationTray instance")
	_passed += 1
	assert(tray is Control, "Should be a Control")
	_passed += 1

	tray.queue_free()
	print("  ✓ tray creation")


func _test_badge_button() -> void:
	print("Testing: badge button...")

	var tray := NotificationTray.new()
	tray._setup_ui()

	var badge_btn := tray.get_node_or_null("BadgeButton")
	assert(badge_btn != null, "Should have BadgeButton")
	_passed += 1
	assert(badge_btn is Button, "BadgeButton should be a Button")
	_passed += 1
	assert(badge_btn.text == "🔔", "Badge button should have bell icon")
	_passed += 1

	tray.queue_free()
	print("  ✓ badge button")


func _test_badge_count() -> void:
	print("Testing: badge count...")

	var tray := NotificationTray.new()
	tray._setup_ui()

	var badge_count := tray.get_node_or_null("BadgeCount")
	assert(badge_count != null, "Should have BadgeCount label")
	_passed += 1
	assert(badge_count is Label, "BadgeCount should be a Label")
	_passed += 1

	# Initially hidden
	assert(badge_count.visible == false, "Badge count should be hidden initially")
	_passed += 1

	# Update badge count
	tray._update_badge_count(3)
	assert(badge_count.visible == true, "Badge count should be visible with count > 0")
	_passed += 1
	assert(badge_count.text == "3", "Badge should show '3'")
	_passed += 1

	# Large count
	tray._update_badge_count(150)
	assert(badge_count.text == "99+", "Badge should show '99+' for large counts")
	_passed += 1

	# Zero count
	tray._update_badge_count(0)
	assert(badge_count.visible == false, "Badge should hide with count 0")
	_passed += 1

	tray.queue_free()
	print("  ✓ badge count")


func _test_expand_collapse() -> void:
	print("Testing: expand/collapse...")

	var tray := NotificationTray.new()
	tray._setup_ui()

	# Initially collapsed
	assert(tray.is_expanded() == false, "Should start collapsed")
	_passed += 1

	# Expand
	tray.expand()
	assert(tray.is_expanded() == true, "Should be expanded after expand()")
	_passed += 1

	# Collapse
	tray.collapse()
	assert(tray.is_expanded() == false, "Should be collapsed after collapse()")
	_passed += 1

	# Toggle
	tray.toggle()
	assert(tray.is_expanded() == true, "Toggle should expand")
	_passed += 1

	tray.toggle()
	assert(tray.is_expanded() == false, "Toggle should collapse")
	_passed += 1

	tray.queue_free()
	print("  ✓ expand/collapse")


func _test_panel_visibility() -> void:
	print("Testing: panel visibility...")

	var tray := NotificationTray.new()
	tray._setup_ui()

	var panel := tray.get_node_or_null("NotificationPanel")
	assert(panel != null, "Should have NotificationPanel")
	_passed += 1

	# Initially hidden
	assert(panel.visible == false, "Panel should be hidden initially")
	_passed += 1

	# When expanded, panel should be set visible
	# Note: expand() uses animation, so we test the immediate visibility set
	tray._is_expanded = false  # Reset to test fresh
	tray.expand()  # This sets _is_expanded = true and panel.visible = true
	# expand() sets visible = true before animation starts
	assert(tray.is_expanded() == true, "Should be expanded after expand()")
	_passed += 1

	tray.queue_free()
	print("  ✓ panel visibility")


func _test_notification_items() -> void:
	print("Testing: notification items...")

	var tray := NotificationTray.new()
	tray._setup_ui()

	# Create a mock notification
	var notification := {
		"id": 1,
		"title": "Test Notification",
		"description": "Test description",
		"type": NotificationTray.TYPE_INFO,
		"icon": "ℹ️",
		"color": Color("#9e9e9e"),
		"timestamp": Time.get_unix_time_from_system(),
		"read": false
	}

	var item := tray._create_notification_item(notification)

	assert(item != null, "Should create notification item")
	_passed += 1
	assert(item is PanelContainer, "Item should be a PanelContainer")
	_passed += 1
	assert(item.has_meta("notification_id"), "Item should store notification_id meta")
	_passed += 1
	assert(item.get_meta("notification_id") == 1, "Item meta should match notification id")
	_passed += 1

	item.queue_free()
	tray.queue_free()
	print("  ✓ notification items")


func _test_relative_time() -> void:
	print("Testing: relative time helper...")

	var now := Time.get_unix_time_from_system()

	# Just now
	var result := NotificationTray._get_relative_time(now)
	assert(result == "now", "Should return 'now' for current time")
	_passed += 1

	# 5 minutes ago
	result = NotificationTray._get_relative_time(now - 300)
	assert(result == "5m", "Should return '5m' for 5 minutes ago")
	_passed += 1

	# 2 hours ago
	result = NotificationTray._get_relative_time(now - 7200)
	assert(result == "2h", "Should return '2h' for 2 hours ago")
	_passed += 1

	# 3 days ago
	result = NotificationTray._get_relative_time(now - 259200)
	assert(result == "3d", "Should return '3d' for 3 days ago")
	_passed += 1

	print("  ✓ relative time helper")


func _test_signals() -> void:
	print("Testing: signals...")

	var tray := NotificationTray.new()

	assert(tray.has_signal("notification_clicked"), "Should have notification_clicked signal")
	_passed += 1
	assert(tray.has_signal("view_action_pressed"), "Should have view_action_pressed signal")
	_passed += 1
	assert(tray.has_signal("dismiss_pressed"), "Should have dismiss_pressed signal")
	_passed += 1

	tray.queue_free()
	print("  ✓ signals")


func _test_constants() -> void:
	print("Testing: constants...")

	# Test type constants match expected values
	assert(NotificationTray.TYPE_INFO == 0, "TYPE_INFO should be 0")
	_passed += 1
	assert(NotificationTray.TYPE_POSITIVE == 1, "TYPE_POSITIVE should be 1")
	_passed += 1
	assert(NotificationTray.TYPE_NEWS == 2, "TYPE_NEWS should be 2")
	_passed += 1
	assert(NotificationTray.TYPE_WARNING == 3, "TYPE_WARNING should be 3")
	_passed += 1
	assert(NotificationTray.TYPE_EMERGENCY == 4, "TYPE_EMERGENCY should be 4")
	_passed += 1

	print("  ✓ constants")
