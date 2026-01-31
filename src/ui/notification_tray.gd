class_name NotificationTray
extends Control
## Notification tray UI component - badge button + expandable notification list
## See: documentation/ui/sidebars.md#notification-tray

signal notification_clicked(notification_id: int)
signal view_action_pressed(notification_id: int)
signal dismiss_pressed(notification_id: int)

# Notification types (mirrored from NotificationSystem autoload)
const TYPE_INFO := 0
const TYPE_POSITIVE := 1
const TYPE_NEWS := 2
const TYPE_WARNING := 3
const TYPE_EMERGENCY := 4

# Color constants (from HUD)
const COLOR_BUTTON := Color("#0f3460")
const COLOR_BUTTON_HOVER := Color("#e94560")
const COLOR_PANEL_BG := Color("#1a1a2e")
const COLOR_PANEL_BORDER := Color("#0f3460")
const COLOR_TEXT := Color("#ffffff")
const COLOR_TEXT_SECONDARY := Color("#a0a0a0")
const COLOR_BADGE := Color("#e94560")

# Size constants
const BADGE_SIZE := Vector2(40, 32)
const PANEL_WIDTH := 320
const PANEL_MAX_HEIGHT := 400
const NOTIFICATION_HEIGHT := 80

# Animation constants
const ANIM_DURATION := 0.15

# UI elements
var _badge_button: Button
var _badge_count: Label
var _panel: PanelContainer
var _notification_list: VBoxContainer
var _scroll_container: ScrollContainer

# State
var _is_expanded := false
var _notification_system: Node = null


func _ready() -> void:
	_setup_ui()
	_connect_notification_system()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_ui() -> void:
	name = "NotificationTray"
	custom_minimum_size = BADGE_SIZE

	# Badge button (always visible)
	_badge_button = Button.new()
	_badge_button.text = "🔔"
	_badge_button.tooltip_text = "Notifications"
	_badge_button.custom_minimum_size = BADGE_SIZE
	_badge_button.name = "BadgeButton"
	_badge_button.pressed.connect(_on_badge_pressed)
	_style_button(_badge_button)
	add_child(_badge_button)

	# Badge count overlay
	_badge_count = Label.new()
	_badge_count.name = "BadgeCount"
	_badge_count.text = ""
	_badge_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_count.custom_minimum_size = Vector2(18, 18)
	_badge_count.position = Vector2(BADGE_SIZE.x - 14, -4)
	_badge_count.visible = false
	_badge_count.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Badge count background
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = COLOR_BADGE
	badge_style.corner_radius_top_left = 9
	badge_style.corner_radius_top_right = 9
	badge_style.corner_radius_bottom_left = 9
	badge_style.corner_radius_bottom_right = 9
	_badge_count.add_theme_stylebox_override("normal", badge_style)
	_badge_count.add_theme_font_size_override("font_size", 10)
	add_child(_badge_count)

	# Expanded panel (hidden by default)
	_panel = _create_panel()
	_panel.visible = false
	add_child(_panel)


func _create_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "NotificationPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.position = Vector2(-PANEL_WIDTH + BADGE_SIZE.x, BADGE_SIZE.y + 8)

	# Panel styling
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.border_color = COLOR_PANEL_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "NOTIFICATIONS"
	title.name = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 12)
	header.add_child(title)

	var mark_read_btn := Button.new()
	mark_read_btn.text = "Mark All Read"
	mark_read_btn.name = "MarkReadButton"
	mark_read_btn.custom_minimum_size = Vector2(0, 24)
	mark_read_btn.pressed.connect(_on_mark_all_read)
	_style_small_button(mark_read_btn)
	header.add_child(mark_read_btn)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.name = "CloseButton"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(_on_close_pressed)
	_style_small_button(close_btn)
	header.add_child(close_btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Scroll container for notification list
	_scroll_container = ScrollContainer.new()
	_scroll_container.custom_minimum_size = Vector2(0, 100)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll_container)

	_notification_list = VBoxContainer.new()
	_notification_list.name = "NotificationList"
	_notification_list.add_theme_constant_override("separation", 4)
	_notification_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_notification_list)

	# Empty state label
	var empty_label := Label.new()
	empty_label.text = "No notifications"
	empty_label.name = "EmptyLabel"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_notification_list.add_child(empty_label)

	return panel


func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BUTTON
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _style_small_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.content_margin_left = 4
	normal.content_margin_right = 4
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2

	var hover := normal.duplicate()
	hover.bg_color = COLOR_BUTTON_HOVER.darkened(0.3)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_font_size_override("font_size", 11)


func _connect_notification_system() -> void:
	var tree := get_tree()
	if not tree:
		return

	_notification_system = tree.get_root().get_node_or_null("/root/NotificationSystem")
	if _notification_system:
		_notification_system.notification_added.connect(_on_notification_added)
		_notification_system.notification_dismissed.connect(_on_notification_dismissed)
		_notification_system.unread_count_changed.connect(_on_unread_count_changed)

		# Initialize with current state
		_update_badge_count(_notification_system.get_unread_count())
		_refresh_notification_list()


## Set the notification system directly (for testing)
func set_notification_system(system: Node) -> void:
	_notification_system = system
	if _notification_system:
		if _notification_system.has_signal("notification_added"):
			_notification_system.notification_added.connect(_on_notification_added)
		if _notification_system.has_signal("notification_dismissed"):
			_notification_system.notification_dismissed.connect(_on_notification_dismissed)
		if _notification_system.has_signal("unread_count_changed"):
			_notification_system.unread_count_changed.connect(_on_unread_count_changed)


func _on_badge_pressed() -> void:
	if _is_expanded:
		collapse()
	else:
		expand()


func _on_close_pressed() -> void:
	collapse()


func _on_mark_all_read() -> void:
	if _notification_system:
		_notification_system.mark_all_read()
	_refresh_notification_list()


func _on_notification_added(notification: Dictionary) -> void:
	_add_notification_item(notification)
	_update_empty_state()


func _on_notification_dismissed(notification_id: int) -> void:
	_remove_notification_item(notification_id)
	_update_empty_state()


func _on_unread_count_changed(count: int) -> void:
	_update_badge_count(count)


func _update_badge_count(count: int) -> void:
	if count <= 0:
		_badge_count.visible = false
		_badge_count.text = ""
	else:
		_badge_count.visible = true
		if count > 99:
			_badge_count.text = "99+"
		else:
			_badge_count.text = str(count)


func _refresh_notification_list() -> void:
	# Clear existing items (except empty label)
	for child in _notification_list.get_children():
		if child.name != "EmptyLabel":
			child.queue_free()

	# Add active notifications
	if _notification_system:
		var notifications: Array[Dictionary] = _notification_system.get_active_notifications()
		for notif in notifications:
			_add_notification_item(notif)

	_update_empty_state()

	# Update panel height based on content
	_update_panel_height()


func _add_notification_item(notification: Dictionary) -> void:
	var item := _create_notification_item(notification)
	# Insert after empty label (which is first child)
	_notification_list.add_child(item)
	_notification_list.move_child(item, 1)
	_update_panel_height()


func _remove_notification_item(notification_id: int) -> void:
	for child in _notification_list.get_children():
		if (
			child.has_meta("notification_id")
			and child.get_meta("notification_id") == notification_id
		):
			child.queue_free()
			break
	_update_panel_height()


func _create_notification_item(notification: Dictionary) -> PanelContainer:
	var item := PanelContainer.new()
	item.set_meta("notification_id", notification.id)
	item.custom_minimum_size = Vector2(0, NOTIFICATION_HEIGHT)

	# Item styling
	var type: int = notification.get("type", TYPE_INFO)
	var color: Color = notification.get("color", Color.WHITE)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG.lightened(0.1)
	style.border_color = color
	style.border_width_left = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	item.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	item.add_child(vbox)

	# Title row (icon + title + time)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	vbox.add_child(title_row)

	var icon_label := Label.new()
	icon_label.text = notification.get("icon", "ℹ️")
	title_row.add_child(icon_label)

	var title_label := Label.new()
	title_label.text = notification.get("title", "Notification")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 13)

	# Bold if unread
	if not notification.get("read", false):
		title_label.add_theme_color_override("font_color", COLOR_TEXT)
	else:
		title_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	title_row.add_child(title_label)

	var time_label := Label.new()
	time_label.text = _get_relative_time(notification.get("timestamp", 0.0))
	time_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	time_label.add_theme_font_size_override("font_size", 11)
	title_row.add_child(time_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = notification.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	desc_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_label)

	# Action buttons row
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	action_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(action_row)

	var view_btn := Button.new()
	view_btn.text = "View"
	view_btn.name = "ViewButton"
	view_btn.custom_minimum_size = Vector2(50, 22)
	view_btn.pressed.connect(_on_view_pressed.bind(notification.id))
	_style_small_button(view_btn)
	action_row.add_child(view_btn)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Dismiss"
	dismiss_btn.name = "DismissButton"
	dismiss_btn.custom_minimum_size = Vector2(60, 22)
	dismiss_btn.pressed.connect(_on_dismiss_pressed.bind(notification.id))
	_style_small_button(dismiss_btn)
	action_row.add_child(dismiss_btn)

	return item


func _on_view_pressed(notification_id: int) -> void:
	if _notification_system:
		_notification_system.mark_read(notification_id)
	view_action_pressed.emit(notification_id)
	notification_clicked.emit(notification_id)
	_refresh_notification_list()


func _on_dismiss_pressed(notification_id: int) -> void:
	if _notification_system:
		_notification_system.dismiss(notification_id)
	dismiss_pressed.emit(notification_id)


func _update_empty_state() -> void:
	var empty_label: Label = _notification_list.get_node_or_null("EmptyLabel")
	if empty_label:
		var has_notifications := false
		for child in _notification_list.get_children():
			if child.name != "EmptyLabel":
				has_notifications = true
				break
		empty_label.visible = not has_notifications


func _update_panel_height() -> void:
	if not _scroll_container:
		return

	# Count notification items
	var item_count := 0
	for child in _notification_list.get_children():
		if child.name != "EmptyLabel":
			item_count += 1

	# Calculate height (header ~60px + items)
	var content_height: int = 60 + item_count * (NOTIFICATION_HEIGHT + 4)
	content_height = mini(content_height, PANEL_MAX_HEIGHT)
	content_height = maxi(content_height, 150)

	_scroll_container.custom_minimum_size.y = content_height - 60


## Expand the notification panel
func expand() -> void:
	if _is_expanded:
		return

	_is_expanded = true
	_refresh_notification_list()
	_panel.visible = true

	# Animate in
	_panel.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, ANIM_DURATION)


## Collapse the notification panel
func collapse() -> void:
	if not _is_expanded:
		return

	_is_expanded = false

	# Animate out
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, ANIM_DURATION)
	tween.tween_callback(func(): _panel.visible = false)


## Toggle expanded state
func toggle() -> void:
	if _is_expanded:
		collapse()
	else:
		expand()


## Check if panel is expanded
func is_expanded() -> bool:
	return _is_expanded


## Get current unread count (for external access)
func get_unread_count() -> int:
	if _notification_system:
		return _notification_system.get_unread_count()
	return 0


## Get relative time string (e.g., "2m ago", "1h ago")
static func _get_relative_time(timestamp: float) -> String:
	var now := Time.get_unix_time_from_system()
	var diff: int = int(now - timestamp)

	if diff < 60:
		return "now"
	if diff < 3600:
		var minutes: int = diff / 60
		return "%dm" % minutes
	if diff < 86400:
		var hours: int = diff / 3600
		return "%dh" % hours
	var days: int = diff / 86400
	return "%dd" % days


## Handle clicks outside panel to close
func _input(event: InputEvent) -> void:
	if not _is_expanded:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is outside panel and badge
			var local_pos := get_local_mouse_position()
			var badge_rect := Rect2(Vector2.ZERO, BADGE_SIZE)
			var panel_rect := Rect2(_panel.position, _panel.size)

			if not badge_rect.has_point(local_pos) and not panel_rect.has_point(local_pos):
				collapse()
