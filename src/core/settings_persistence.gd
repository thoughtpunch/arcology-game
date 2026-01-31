extends Node
## SettingsPersistence autoload - saves/loads settings to user://settings.json
## Provides centralized settings management with persistence

signal setting_changed(key: String, value: Variant)
signal settings_loaded
signal settings_saved

const SETTINGS_PATH := "user://settings.json"

# Default settings values (copied from SettingsMenu)
const DEFAULT_SETTINGS := {
	# Game tab
	"auto_save_interval": 10,  # minutes
	"edge_scrolling": true,
	"scroll_speed": 50,  # percentage
	"pause_on_lost_focus": true,
	"tutorial_hints": false,
	"show_news_popups": true,
	"auto_pause_emergencies": true,
	"notification_sound": true,
	# Graphics tab
	"resolution": "1920x1080",
	"display_mode": "Fullscreen",
	"vsync": true,
	"frame_rate_limit": 60,
	"sprite_quality": "High",
	"shadow_quality": "Medium",
	"animation_quality": "High",
	"particle_effects": true,
	"ui_scale": 100,
	"show_fps": false,
	# Audio tab
	"master_volume": 80,
	"music_volume": 60,
	"sfx_volume": 80,
	"ambient_volume": 40,
	"ui_volume": 100,
	"mute_when_minimized": true,
	"dynamic_music": true,
	# Controls tab
	"invert_scroll_zoom": false,
	"mouse_sensitivity": 50,
	# Keybindings (stored as InputMap action -> key string)
	"keybindings": {},
	# Accessibility tab
	"colorblind_mode": "Off",
	"high_contrast_ui": false,
	"reduce_motion": false,
	"screen_flash_effects": true,
	"font_size": "Medium",
	"dyslexia_font": false,
	"extended_tooltips": false,
	"slower_game_speed_max": false
}

# Current settings (loaded from file or defaults)
var _settings: Dictionary = {}

# Track if settings have been modified since last save
var _dirty: bool = false


func _ready() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	load_settings()


## Get a setting value by key
func get_setting(key: String, default_value: Variant = null) -> Variant:
	if key in _settings:
		return _settings[key]
	if key in DEFAULT_SETTINGS:
		return DEFAULT_SETTINGS[key]
	return default_value


## Set a setting value by key
func set_setting(key: String, value: Variant) -> void:
	var old_value = _settings.get(key)
	if old_value != value:
		_settings[key] = value
		_dirty = true
		setting_changed.emit(key, value)
		# Auto-save on change
		save_settings()


## Get all settings as a dictionary
func get_all_settings() -> Dictionary:
	return _settings.duplicate(true)


## Set multiple settings at once
func set_all_settings(settings: Dictionary) -> void:
	for key in settings:
		if key in DEFAULT_SETTINGS or key == "keybindings":
			var old_value = _settings.get(key)
			if old_value != settings[key]:
				_settings[key] = settings[key]
				_dirty = true
				setting_changed.emit(key, settings[key])
	if _dirty:
		save_settings()


## Reset all settings to defaults
func reset_to_defaults() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	_dirty = true
	save_settings()
	settings_loaded.emit()


## Reset a specific setting to default
func reset_setting(key: String) -> void:
	if key in DEFAULT_SETTINGS:
		set_setting(key, DEFAULT_SETTINGS[key])


## Check if a setting exists
func has_setting(key: String) -> bool:
	return key in _settings or key in DEFAULT_SETTINGS


## Check if settings are different from defaults
func is_modified() -> bool:
	for key in DEFAULT_SETTINGS:
		if key in _settings and _settings[key] != DEFAULT_SETTINGS[key]:
			return true
	return false


## Load settings from file
func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		# No settings file, use defaults
		_settings = DEFAULT_SETTINGS.duplicate(true)
		settings_loaded.emit()
		return true

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_warning(
			"SettingsPersistence: Failed to open settings file: %s" % FileAccess.get_open_error()
		)
		_settings = DEFAULT_SETTINGS.duplicate(true)
		settings_loaded.emit()
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_warning(
			(
				"SettingsPersistence: Failed to parse settings JSON: %s at line %d"
				% [json.get_error_message(), json.get_error_line()]
			)
		)
		_settings = DEFAULT_SETTINGS.duplicate(true)
		settings_loaded.emit()
		return false

	var data = json.get_data()
	if not data is Dictionary:
		push_warning("SettingsPersistence: Settings file is not a dictionary")
		_settings = DEFAULT_SETTINGS.duplicate(true)
		settings_loaded.emit()
		return false

	# Start with defaults and overlay loaded values
	_settings = DEFAULT_SETTINGS.duplicate(true)
	for key in data:
		# Only accept known keys (prevents stale/malformed data)
		if key in DEFAULT_SETTINGS or key == "keybindings":
			_settings[key] = data[key]

	_dirty = false
	settings_loaded.emit()
	return true


## Save settings to file
func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning(
			"SettingsPersistence: Failed to create settings file: %s" % FileAccess.get_open_error()
		)
		return false

	var json_string := JSON.stringify(_settings, "\t")
	file.store_string(json_string)
	file.close()

	_dirty = false
	settings_saved.emit()
	return true


## Get the default value for a setting
func get_default_value(key: String) -> Variant:
	return DEFAULT_SETTINGS.get(key)


## Check if a specific setting differs from default
func is_setting_modified(key: String) -> bool:
	if key not in DEFAULT_SETTINGS:
		return false
	return _settings.get(key) != DEFAULT_SETTINGS[key]
