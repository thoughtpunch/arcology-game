class_name ToastNotification
extends Control
## Toast notification manager - shows slide-in notifications from top-right
## See: documentation/ui/sidebars.md#notification-tray

# Notification types (mirrored from NotificationSystem autoload)
const TYPE_INFO := 0
const TYPE_POSITIVE := 1
const TYPE_NEWS := 2
const TYPE_WARNING := 3
const TYPE_EMERGENCY := 4

# Type icons
const TYPE_ICONS := {
	TYPE_INFO: "ℹ️",
	TYPE_POSITIVE: "✅",
	TYPE_NEWS: "📰",
	TYPE_WARNING: "⚠",
	TYPE_EMERGENCY: "🔴"
}

# Type colors
const TYPE_COLORS := {
	TYPE_INFO: Color("#9e9e9e"),
	TYPE_POSITIVE: Color("#4caf50"),
	TYPE_NEWS: Color("#2196f3"),
	TYPE_WARNING: Color("#ff9800"),
	TYPE_EMERGENCY: Color("#f44336")
}

# Auto-dismiss times (in seconds, 0 = never auto-dismiss)
const TYPE_AUTO_DISMISS := {
	TYPE_INFO: 5.0,
	TYPE_POSITIVE: 5.0,
	TYPE_NEWS: 5.0,
	TYPE_WARNING: 0.0,
	TYPE_EMERGENCY: 0.0
}

# Toast constants
const TOAST_WIDTH := 300
const TOAST_HEIGHT := 80
const TOAST_MARGIN := 16
const TOAST_SPACING := 8
const SLIDE_DURATION := 0.25
const DEFAULT_DISPLAY_TIME := 5.0

# Colors (from HUD)
const COLOR_PANEL_BG := Color("#1a1a2e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#a0a0a0")

# Signals
signal toast_clicked(notification_id: int)
signal toast_dismissed(notification_id: int)

# State
var _active_toasts: Array[Control] = []
var _notification_system: Node = null
var _max_visible_toasts := 5


func _ready() -> void:
	name = "ToastNotification"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position in top-right corner
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_connect_notification_system()


func _connect_notification_system() -> void:
	var tree := get_tree()
	if not tree:
		return

	_notification_system = tree.get_root().get_node_or_null("/root/NotificationSystem")
	if _notification_system:
		_notification_system.notification_added.connect(_on_notification_added)


## Set the notification system directly (for testing)
func set_notification_system(system: Node) -> void:
	_notification_system = system
	if _notification_system and _notification_system.has_signal("notification_added"):
		_notification_system.notification_added.connect(_on_notification_added)


func _on_notification_added(notification: Dictionary) -> void:
	_show_toast(notification)


## Show a toast notification
func _show_toast(notification: Dictionary) -> void:
	# Limit visible toasts
	while _active_toasts.size() >= _max_visible_toasts:
		_dismiss_oldest_toast()

	var toast := _create_toast(notification)
	add_child(toast)
	_active_toasts.append(toast)

	# Position off-screen to the right
	var y_pos: float = TOAST_MARGIN + (_active_toasts.size() - 1) * (TOAST_HEIGHT + TOAST_SPACING)
	toast.position = Vector2(TOAST_MARGIN, y_pos)  # Start visible position
	toast.modulate.a = 0

	# Slide in animation
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, SLIDE_DURATION)

	# Auto-dismiss based on notification type
	var auto_dismiss_time: float = notification.get("auto_dismiss_time", DEFAULT_DISPLAY_TIME)
	if auto_dismiss_time > 0:
		var timer := get_tree().create_timer(auto_dismiss_time)
		timer.timeout.connect(_on_toast_timeout.bind(toast, notification.id))


func _create_toast(notification: Dictionary) -> PanelContainer:
	var toast := PanelContainer.new()
	toast.set_meta("notification_id", notification.id)
	toast.custom_minimum_size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	toast.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	toast.mouse_filter = Control.MOUSE_FILTER_STOP

	# Styling with colored left border
	var type: int = notification.get("type", TYPE_INFO)
	var color: Color = notification.get("color", Color.WHITE)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.border_color = color
	style.border_width_left = 4
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	toast.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	toast.add_child(hbox)

	# Icon
	var icon := Label.new()
	icon.text = notification.get("icon", "ℹ️")
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(icon)

	# Content
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	hbox.add_child(content)

	var title := Label.new()
	title.text = notification.get("title", "Notification")
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	content.add_child(title)

	var desc := Label.new()
	desc.text = notification.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	content.add_child(desc)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(_on_close_pressed.bind(toast, notification.id))
	_style_close_button(close_btn)
	hbox.add_child(close_btn)

	# Click to view details
	toast.gui_input.connect(_on_toast_clicked.bind(toast, notification.id))

	return toast


func _style_close_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.content_margin_left = 4
	normal.content_margin_right = 4
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2

	var hover := normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _on_toast_clicked(event: InputEvent, toast: Control, notification_id: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Mark as read and emit signal
			if _notification_system:
				_notification_system.mark_read(notification_id)
			toast_clicked.emit(notification_id)
			_dismiss_toast(toast, notification_id)


func _on_close_pressed(toast: Control, notification_id: int) -> void:
	if _notification_system:
		_notification_system.dismiss(notification_id)
	_dismiss_toast(toast, notification_id)


func _on_toast_timeout(toast: Control, notification_id: int) -> void:
	# Only dismiss if toast still exists and is not emergency
	if is_instance_valid(toast) and toast.is_inside_tree():
		_dismiss_toast(toast, notification_id)


func _dismiss_toast(toast: Control, notification_id: int) -> void:
	if not is_instance_valid(toast):
		return

	# Remove from active list
	var index := _active_toasts.find(toast)
	if index >= 0:
		_active_toasts.remove_at(index)

	# Slide out animation
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, SLIDE_DURATION)
	tween.tween_callback(toast.queue_free)

	# Reposition remaining toasts
	_reposition_toasts()

	toast_dismissed.emit(notification_id)


func _dismiss_oldest_toast() -> void:
	if _active_toasts.is_empty():
		return

	var oldest := _active_toasts[0]
	if oldest.has_meta("notification_id"):
		var notification_id: int = oldest.get_meta("notification_id")
		_dismiss_toast(oldest, notification_id)


func _reposition_toasts() -> void:
	for i in range(_active_toasts.size()):
		var toast := _active_toasts[i]
		if is_instance_valid(toast):
			var target_y: float = TOAST_MARGIN + i * (TOAST_HEIGHT + TOAST_SPACING)
			var tween := create_tween()
			tween.tween_property(toast, "position:y", target_y, SLIDE_DURATION * 0.5)


## Show a toast directly (for testing or manual use)
func show_toast(title: String, description: String = "", type: int = 0) -> void:
	var notification := {
		"id": Time.get_ticks_msec(),  # Simple unique ID
		"title": title,
		"description": description,
		"type": type,
		"icon": TYPE_ICONS.get(type, "ℹ️"),
		"color": TYPE_COLORS.get(type, Color.WHITE),
		"auto_dismiss_time": TYPE_AUTO_DISMISS.get(type, DEFAULT_DISPLAY_TIME)
	}
	_show_toast(notification)


## Clear all active toasts
func clear_all() -> void:
	for toast in _active_toasts.duplicate():
		if is_instance_valid(toast):
			toast.queue_free()
	_active_toasts.clear()


## Get count of active toasts
func get_active_count() -> int:
	return _active_toasts.size()


## Set maximum visible toasts
func set_max_visible(count: int) -> void:
	_max_visible_toasts = maxi(1, count)
