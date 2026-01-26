extends Node
## NotificationSystem autoload - centralized notification management
## Note: No class_name since this is an autoload singleton
## Centralized notification management system
## Handles notification creation, storage, and game state integration
## See: documentation/ui/sidebars.md#notification-tray

# Notification types with priority levels
enum NotificationType {
	INFO,       # Gray - tips, reminders (lowest priority)
	POSITIVE,   # Green - achievements, milestones
	NEWS,       # Blue - new residents, events
	WARNING,    # Orange - capacity issues, declining stats
	EMERGENCY   # Red - fires, critical failures (highest, auto-pause)
}

# Icons for each notification type
const TYPE_ICONS := {
	NotificationType.INFO: "ℹ️",
	NotificationType.POSITIVE: "✅",
	NotificationType.NEWS: "📰",
	NotificationType.WARNING: "⚠",
	NotificationType.EMERGENCY: "🔴"
}

# Colors for each notification type
const TYPE_COLORS := {
	NotificationType.INFO: Color("#9e9e9e"),      # Gray
	NotificationType.POSITIVE: Color("#4caf50"),  # Green
	NotificationType.NEWS: Color("#2196f3"),      # Blue
	NotificationType.WARNING: Color("#ff9800"),   # Orange
	NotificationType.EMERGENCY: Color("#f44336")  # Red
}

# Auto-dismiss times (in seconds, 0 = never auto-dismiss)
const TYPE_AUTO_DISMISS := {
	NotificationType.INFO: 5.0,
	NotificationType.POSITIVE: 5.0,
	NotificationType.NEWS: 5.0,
	NotificationType.WARNING: 0.0,    # Don't auto-dismiss warnings
	NotificationType.EMERGENCY: 0.0   # Don't auto-dismiss emergencies
}

# Signals
signal notification_added(notification: Dictionary)
signal notification_dismissed(notification_id: int)
signal notification_read(notification_id: int)
signal unread_count_changed(count: int)

# Storage
var _notifications: Array[Dictionary] = []
var _next_id: int = 1
var _unread_count: int = 0

# Maximum notifications to keep in history
const MAX_NOTIFICATIONS: int = 100


func _ready() -> void:
	name = "NotificationSystem"


## Create a new notification
## Returns the notification ID
func notify(title: String, description: String = "", type: NotificationType = NotificationType.INFO, action_data: Dictionary = {}) -> int:
	var notification := {
		"id": _next_id,
		"title": title,
		"description": description,
		"type": type,
		"icon": TYPE_ICONS[type],
		"color": TYPE_COLORS[type],
		"timestamp": Time.get_unix_time_from_system(),
		"read": false,
		"dismissed": false,
		"action_data": action_data,
		"auto_dismiss_time": TYPE_AUTO_DISMISS[type]
	}

	_next_id += 1
	_notifications.push_front(notification)  # Newest first
	_unread_count += 1

	# Trim old notifications if over limit
	while _notifications.size() > MAX_NOTIFICATIONS:
		var removed: Dictionary = _notifications.pop_back()
		if not removed.read:
			_unread_count -= 1

	notification_added.emit(notification)
	unread_count_changed.emit(_unread_count)

	# Emergency notifications pause the game
	if type == NotificationType.EMERGENCY:
		_emergency_pause()

	return notification.id


## Convenience methods for each notification type
func notify_info(title: String, description: String = "", action_data: Dictionary = {}) -> int:
	return notify(title, description, NotificationType.INFO, action_data)


func notify_positive(title: String, description: String = "", action_data: Dictionary = {}) -> int:
	return notify(title, description, NotificationType.POSITIVE, action_data)


func notify_news(title: String, description: String = "", action_data: Dictionary = {}) -> int:
	return notify(title, description, NotificationType.NEWS, action_data)


func notify_warning(title: String, description: String = "", action_data: Dictionary = {}) -> int:
	return notify(title, description, NotificationType.WARNING, action_data)


func notify_emergency(title: String, description: String = "", action_data: Dictionary = {}) -> int:
	return notify(title, description, NotificationType.EMERGENCY, action_data)


## Mark a notification as read
func mark_read(notification_id: int) -> void:
	for notif in _notifications:
		if notif.id == notification_id and not notif.read:
			notif.read = true
			_unread_count = maxi(0, _unread_count - 1)
			notification_read.emit(notification_id)
			unread_count_changed.emit(_unread_count)
			break


## Mark all notifications as read
func mark_all_read() -> void:
	for notif in _notifications:
		notif.read = true
	_unread_count = 0
	unread_count_changed.emit(_unread_count)


## Dismiss a notification (remove from active list but keep in history)
func dismiss(notification_id: int) -> void:
	for notif in _notifications:
		if notif.id == notification_id:
			notif.dismissed = true
			if not notif.read:
				notif.read = true
				_unread_count = maxi(0, _unread_count - 1)
				unread_count_changed.emit(_unread_count)
			notification_dismissed.emit(notification_id)
			break


## Get all active (non-dismissed) notifications
func get_active_notifications() -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for notif in _notifications:
		if not notif.dismissed:
			active.append(notif)
	return active


## Get unread notifications only
func get_unread_notifications() -> Array[Dictionary]:
	var unread: Array[Dictionary] = []
	for notif in _notifications:
		if not notif.read and not notif.dismissed:
			unread.append(notif)
	return unread


## Get unread count
func get_unread_count() -> int:
	return _unread_count


## Get notification by ID
func get_notification(notification_id: int) -> Dictionary:
	for notif in _notifications:
		if notif.id == notification_id:
			return notif
	return {}


## Clear all notifications
func clear_all() -> void:
	_notifications.clear()
	_unread_count = 0
	unread_count_changed.emit(_unread_count)


## Get relative time string (e.g., "2m ago", "1h ago")
static func get_relative_time(timestamp: float) -> String:
	var now := Time.get_unix_time_from_system()
	var diff: int = int(now - timestamp)

	if diff < 60:
		return "now"
	elif diff < 3600:
		var minutes: int = diff / 60
		return "%dm" % minutes
	elif diff < 86400:
		var hours: int = diff / 3600
		return "%dh" % hours
	else:
		var days: int = diff / 86400
		return "%dd" % days


## Pause game for emergency notification
func _emergency_pause() -> void:
	var tree := get_tree()
	if not tree:
		return

	var game_state = tree.get_root().get_node_or_null("/root/GameState")
	if game_state and not game_state.is_paused():
		game_state.toggle_pause()


## Get icon for notification type
static func get_type_icon(type: NotificationType) -> String:
	return TYPE_ICONS.get(type, "ℹ️")


## Get color for notification type
static func get_type_color(type: NotificationType) -> Color:
	return TYPE_COLORS.get(type, Color.WHITE)


## Check if notification type should auto-pause
static func should_auto_pause(type: NotificationType) -> bool:
	return type == NotificationType.EMERGENCY
