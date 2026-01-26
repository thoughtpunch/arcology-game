extends SceneTree
## Tests for NotificationSystem
## Run: godot --headless --script test/ui/test_notification_system.gd

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== NotificationSystem Tests ===\n")

	# Run tests
	_test_create_notification()
	_test_notification_types()
	_test_mark_read()
	_test_mark_all_read()
	_test_dismiss_notification()
	_test_get_active_notifications()
	_test_get_unread_notifications()
	_test_unread_count()
	_test_notification_signals()
	_test_max_notifications_limit()
	_test_relative_time()
	_test_type_icons_and_colors()
	_test_auto_dismiss_times()

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


func _test_create_notification() -> void:
	print("Testing: create notification...")

	var system: Node = _create_system()

	# Create basic notification
	var id: int = system.notify("Test Title", "Test Description")

	assert(id > 0, "Should return positive ID")
	_passed += 1

	var notif: Dictionary = system.get_notification(id)
	assert(notif.title == "Test Title", "Should store title")
	_passed += 1
	assert(notif.description == "Test Description", "Should store description")
	_passed += 1
	assert(notif.read == false, "Should start unread")
	_passed += 1
	assert(notif.dismissed == false, "Should start not dismissed")
	_passed += 1

	print("  ✓ create notification")


func _test_notification_types() -> void:
	print("Testing: notification types...")

	var system: Node = _create_system()

	# Test each notification type
	var info_id: int = system.notify_info("Info", "Info desc")
	var info: Dictionary = system.get_notification(info_id)
	assert(info.type == system.NotificationType.INFO, "Should be INFO type")
	_passed += 1

	var positive_id: int = system.notify_positive("Positive", "Positive desc")
	var positive: Dictionary = system.get_notification(positive_id)
	assert(positive.type == system.NotificationType.POSITIVE, "Should be POSITIVE type")
	_passed += 1

	var news_id: int = system.notify_news("News", "News desc")
	var news: Dictionary = system.get_notification(news_id)
	assert(news.type == system.NotificationType.NEWS, "Should be NEWS type")
	_passed += 1

	var warning_id: int = system.notify_warning("Warning", "Warning desc")
	var warning: Dictionary = system.get_notification(warning_id)
	assert(warning.type == system.NotificationType.WARNING, "Should be WARNING type")
	_passed += 1

	var emergency_id: int = system.notify_emergency("Emergency", "Emergency desc")
	var emergency: Dictionary = system.get_notification(emergency_id)
	assert(emergency.type == system.NotificationType.EMERGENCY, "Should be EMERGENCY type")
	_passed += 1

	print("  ✓ notification types")


func _test_mark_read() -> void:
	print("Testing: mark read...")

	var system: Node = _create_system()

	var id: int = system.notify("Test", "Description")
	assert(system.get_unread_count() == 1, "Should have 1 unread")
	_passed += 1

	system.mark_read(id)

	var notif: Dictionary = system.get_notification(id)
	assert(notif.read == true, "Should be marked read")
	_passed += 1
	assert(system.get_unread_count() == 0, "Should have 0 unread")
	_passed += 1

	print("  ✓ mark read")


func _test_mark_all_read() -> void:
	print("Testing: mark all read...")

	var system: Node = _create_system()

	system.notify("Test 1")
	system.notify("Test 2")
	system.notify("Test 3")

	assert(system.get_unread_count() == 3, "Should have 3 unread")
	_passed += 1

	system.mark_all_read()

	assert(system.get_unread_count() == 0, "Should have 0 unread after mark all")
	_passed += 1

	print("  ✓ mark all read")


func _test_dismiss_notification() -> void:
	print("Testing: dismiss notification...")

	var system: Node = _create_system()

	var id: int = system.notify("Test", "Description")

	system.dismiss(id)

	var notif: Dictionary = system.get_notification(id)
	assert(notif.dismissed == true, "Should be dismissed")
	_passed += 1
	assert(notif.read == true, "Dismissing should also mark as read")
	_passed += 1

	# Dismissed notifications not in active list
	var active: Array = system.get_active_notifications()
	var found := false
	for n: Dictionary in active:
		if n.id == id:
			found = true
			break
	assert(not found, "Dismissed notification should not be in active list")
	_passed += 1

	print("  ✓ dismiss notification")


func _test_get_active_notifications() -> void:
	print("Testing: get active notifications...")

	var system: Node = _create_system()

	var id1: int = system.notify("Test 1")
	var id2: int = system.notify("Test 2")
	var id3: int = system.notify("Test 3")

	var active: Array = system.get_active_notifications()
	assert(active.size() == 3, "Should have 3 active notifications")
	_passed += 1

	# Dismiss one
	system.dismiss(id2)
	active = system.get_active_notifications()
	assert(active.size() == 2, "Should have 2 active after dismiss")
	_passed += 1

	# Silence warnings about unused variables
	if id1 or id3:
		pass

	print("  ✓ get active notifications")


func _test_get_unread_notifications() -> void:
	print("Testing: get unread notifications...")

	var system: Node = _create_system()

	var id1: int = system.notify("Test 1")
	var id2: int = system.notify("Test 2")
	var id3: int = system.notify("Test 3")

	var unread: Array = system.get_unread_notifications()
	assert(unread.size() == 3, "Should have 3 unread notifications")
	_passed += 1

	# Mark one as read
	system.mark_read(id2)
	unread = system.get_unread_notifications()
	assert(unread.size() == 2, "Should have 2 unread after mark read")
	_passed += 1

	# Silence warnings about unused variables
	if id1 or id3:
		pass

	print("  ✓ get unread notifications")


func _test_unread_count() -> void:
	print("Testing: unread count...")

	var system: Node = _create_system()

	assert(system.get_unread_count() == 0, "Should start with 0 unread")
	_passed += 1

	system.notify("Test 1")
	assert(system.get_unread_count() == 1, "Should have 1 unread")
	_passed += 1

	system.notify("Test 2")
	system.notify("Test 3")
	assert(system.get_unread_count() == 3, "Should have 3 unread")
	_passed += 1

	print("  ✓ unread count")


func _test_notification_signals() -> void:
	print("Testing: notification signals...")

	var system: Node = _create_system()

	# Test that signals exist
	assert(system.has_signal("notification_added"), "Should have notification_added signal")
	_passed += 1
	assert(system.has_signal("notification_dismissed"), "Should have notification_dismissed signal")
	_passed += 1
	assert(system.has_signal("notification_read"), "Should have notification_read signal")
	_passed += 1
	assert(system.has_signal("unread_count_changed"), "Should have unread_count_changed signal")
	_passed += 1

	print("  ✓ notification signals")


func _test_max_notifications_limit() -> void:
	print("Testing: max notifications limit...")

	var system: Node = _create_system()

	# Create more than MAX_NOTIFICATIONS
	for i in range(105):
		system.notify("Test %d" % i)

	var active: Array = system.get_active_notifications()
	assert(active.size() <= system.MAX_NOTIFICATIONS, "Should not exceed MAX_NOTIFICATIONS")
	_passed += 1

	print("  ✓ max notifications limit")


func _test_relative_time() -> void:
	print("Testing: relative time...")

	var system: Node = _create_system()

	var now := Time.get_unix_time_from_system()

	# Just now
	var result: String = system.get_relative_time(now)
	assert(result == "now", "Should return 'now' for current time")
	_passed += 1

	# 5 minutes ago
	result = system.get_relative_time(now - 300)
	assert(result == "5m", "Should return '5m' for 5 minutes ago")
	_passed += 1

	# 2 hours ago
	result = system.get_relative_time(now - 7200)
	assert(result == "2h", "Should return '2h' for 2 hours ago")
	_passed += 1

	# 3 days ago
	result = system.get_relative_time(now - 259200)
	assert(result == "3d", "Should return '3d' for 3 days ago")
	_passed += 1

	print("  ✓ relative time")


func _test_type_icons_and_colors() -> void:
	print("Testing: type icons and colors...")

	var system: Node = _create_system()

	# Test icons
	assert(system.get_type_icon(system.NotificationType.INFO) == "ℹ️", "INFO should have ℹ️ icon")
	_passed += 1
	assert(system.get_type_icon(system.NotificationType.POSITIVE) == "✅", "POSITIVE should have ✅ icon")
	_passed += 1
	assert(system.get_type_icon(system.NotificationType.EMERGENCY) == "🔴", "EMERGENCY should have 🔴 icon")
	_passed += 1

	# Test colors exist
	var info_color: Color = system.get_type_color(system.NotificationType.INFO)
	assert(info_color is Color, "Should return Color for INFO")
	_passed += 1

	var emergency_color: Color = system.get_type_color(system.NotificationType.EMERGENCY)
	assert(emergency_color is Color, "Should return Color for EMERGENCY")
	_passed += 1

	print("  ✓ type icons and colors")


func _test_auto_dismiss_times() -> void:
	print("Testing: auto dismiss times...")

	var system: Node = _create_system()

	# INFO should auto-dismiss
	var info_time: float = system.TYPE_AUTO_DISMISS[system.NotificationType.INFO]
	assert(info_time > 0, "INFO should have auto-dismiss time")
	_passed += 1

	# WARNING should not auto-dismiss
	var warning_time: float = system.TYPE_AUTO_DISMISS[system.NotificationType.WARNING]
	assert(warning_time == 0.0, "WARNING should not auto-dismiss")
	_passed += 1

	# EMERGENCY should not auto-dismiss
	var emergency_time: float = system.TYPE_AUTO_DISMISS[system.NotificationType.EMERGENCY]
	assert(emergency_time == 0.0, "EMERGENCY should not auto-dismiss")
	_passed += 1

	print("  ✓ auto dismiss times")


## Create a fresh NotificationSystem instance for testing
func _create_system() -> Node:
	# Load and instantiate the notification system script
	var script: GDScript = load("res://src/ui/notification_system.gd")
	var system := Node.new()
	system.set_script(script)
	return system
