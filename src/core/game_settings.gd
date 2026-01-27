extends Node
## GameSettings autoload - applies game tab settings to gameplay systems
## Listens to SettingsPersistence for changes and applies to:
## - AutoSave: interval
## - CameraController: edge_scrolling, scroll_speed
## - Window focus: pause_on_lost_focus
## - NotificationSystem: show_news_popups, notification_sound

# Auto-save interval mappings (from dropdown strings to minutes)
const AUTO_SAVE_INTERVALS := {
	"5 minutes": 5,
	"10 minutes": 10,
	"15 minutes": 15,
	"30 minutes": 30,
	"Disabled": 0
}

# Window focus handling
var _window_focused: bool = true


func _ready() -> void:
	# Apply initial settings
	call_deferred("_apply_all_settings")

	# Connect to settings changes
	var sp := _get_settings_persistence()
	if sp:
		sp.setting_changed.connect(_on_setting_changed)
		sp.settings_loaded.connect(_apply_all_settings)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_window_focused = true
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_window_focused = false
			_handle_focus_lost()


## Get SettingsPersistence autoload
func _get_settings_persistence() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/SettingsPersistence")
	return null


## Apply all game settings from SettingsPersistence
func _apply_all_settings() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	# Apply auto-save interval
	_apply_auto_save_interval(sp.get_setting("auto_save_interval", 10))

	# Apply notification settings
	_apply_show_news_popups(sp.get_setting("show_news_popups", true))
	_apply_notification_sound(sp.get_setting("notification_sound", true))

	# Camera settings would need CameraController reference
	# These are applied via main.gd when CameraController is set up


## Handle individual setting changes
func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"auto_save_interval":
			_apply_auto_save_interval(value)
		"show_news_popups":
			_apply_show_news_popups(value)
		"notification_sound":
			_apply_notification_sound(value)
		"edge_scrolling", "scroll_speed":
			# These need CameraController - notify any listeners
			camera_setting_changed.emit(key, value)


# Signals for systems that need to react
signal camera_setting_changed(key: String, value: Variant)


## Apply auto-save interval setting
func _apply_auto_save_interval(interval: Variant) -> void:
	var minutes: int

	if interval is String:
		# Handle dropdown option strings like "10 minutes"
		minutes = AUTO_SAVE_INTERVALS.get(interval, 10)
	elif interval is int:
		minutes = interval
	else:
		minutes = 10

	# Find AutoSave node and set interval
	var auto_save := _get_auto_save()
	if auto_save:
		if minutes == 0:
			auto_save.set_enabled(false)
		else:
			auto_save.set_enabled(true)
			auto_save.set_interval(minutes)


## Apply show news popups setting
func _apply_show_news_popups(show: Variant) -> void:
	var show_news: bool = show if show is bool else bool(show)

	# Store in a property for NotificationSystem to check
	_show_news_popups = show_news

	# NotificationSystem can check this before showing NEWS type notifications


## Apply notification sound setting
func _apply_notification_sound(enabled: Variant) -> void:
	var play_sound: bool = enabled if enabled is bool else bool(enabled)

	# Store in a property for NotificationSystem to check
	_notification_sound_enabled = play_sound


## Handle window focus lost
func _handle_focus_lost() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	var pause_on_lost_focus: bool = sp.get_setting("pause_on_lost_focus", true)
	if pause_on_lost_focus:
		var game_state := _get_game_state()
		if game_state and not game_state.is_paused():
			game_state.toggle_pause()


## Get AutoSave node
func _get_auto_save() -> Node:
	var tree := get_tree()
	if not tree:
		return null

	# AutoSave might be a child of Main or an autoload
	var main := tree.root.get_node_or_null("/root/Main")
	if main:
		var auto_save := main.get_node_or_null("AutoSave")
		if auto_save:
			return auto_save

	# Try as autoload
	return tree.root.get_node_or_null("/root/AutoSave")


## Get GameState autoload
func _get_game_state() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/GameState")
	return null


# Properties for other systems to check

var _show_news_popups: bool = true
var _notification_sound_enabled: bool = true
var _auto_pause_emergencies: bool = true


## Check if news popups should be shown
func should_show_news_popups() -> bool:
	return _show_news_popups


## Check if notification sounds should play
func should_play_notification_sound() -> bool:
	return _notification_sound_enabled


## Check if game should auto-pause on emergencies
func should_auto_pause_emergencies() -> bool:
	return _auto_pause_emergencies


## Get scroll speed multiplier (0.0 to 1.0)
func get_scroll_speed_multiplier() -> float:
	var sp := _get_settings_persistence()
	if sp:
		var speed: int = sp.get_setting("scroll_speed", 50)
		return clampf(speed / 100.0, 0.0, 1.0)
	return 0.5


## Check if edge scrolling is enabled
func is_edge_scrolling_enabled() -> bool:
	var sp := _get_settings_persistence()
	if sp:
		return sp.get_setting("edge_scrolling", true)
	return true


## Check if window is focused
func is_window_focused() -> bool:
	return _window_focused
