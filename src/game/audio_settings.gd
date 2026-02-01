extends Node
## AudioSettings autoload - applies audio settings to AudioServer
## Listens to SettingsPersistence for changes and applies to audio buses

# Bus indices (must match default_bus_layout.tres order)
const BUS_MASTER := 0
const BUS_MUSIC := 1
const BUS_SFX := 2
const BUS_AMBIENT := 3
const BUS_UI := 4

# Setting key to bus index mapping
const VOLUME_SETTINGS := {
	"master_volume": BUS_MASTER,
	"music_volume": BUS_MUSIC,
	"sfx_volume": BUS_SFX,
	"ambient_volume": BUS_AMBIENT,
	"ui_volume": BUS_UI
}

# Track if window is focused (for mute when minimized)
var _window_focused: bool = true


func _ready() -> void:
	# Apply initial settings
	_apply_all_settings()

	# Connect to settings changes
	var sp := _get_settings_persistence()
	if sp:
		sp.setting_changed.connect(_on_setting_changed)
		sp.settings_loaded.connect(_apply_all_settings)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_window_focused = true
			_apply_mute_when_minimized()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_window_focused = false
			_apply_mute_when_minimized()


## Get SettingsPersistence autoload
func _get_settings_persistence() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/SettingsPersistence")
	return null


## Apply all audio settings from SettingsPersistence
func _apply_all_settings() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	# Apply volume settings
	for setting_key in VOLUME_SETTINGS:
		var bus_idx: int = VOLUME_SETTINGS[setting_key]
		var volume: int = sp.get_setting(setting_key, 80)
		_set_bus_volume(bus_idx, volume)

	# Apply mute when minimized
	_apply_mute_when_minimized()


## Handle individual setting changes
func _on_setting_changed(key: String, value: Variant) -> void:
	if key in VOLUME_SETTINGS:
		var bus_idx: int = VOLUME_SETTINGS[key]
		var volume: int = value if value is int else int(value)
		_set_bus_volume(bus_idx, volume)
	elif key == "mute_when_minimized":
		_apply_mute_when_minimized()


## Set volume for a bus (0-100 percentage to dB conversion)
func _set_bus_volume(bus_idx: int, volume_percent: int) -> void:
	if bus_idx < 0 or bus_idx >= AudioServer.bus_count:
		push_warning("AudioSettings: Invalid bus index %d" % bus_idx)
		return

	# Convert percentage to dB
	# 0% = -80 dB (effectively muted)
	# 100% = 0 dB (full volume)
	var volume_linear: float = clampf(volume_percent / 100.0, 0.0, 1.0)
	var volume_db: float = linear_to_db(volume_linear)

	# Clamp to reasonable range
	volume_db = clampf(volume_db, -80.0, 0.0)

	AudioServer.set_bus_volume_db(bus_idx, volume_db)


## Apply mute when minimized setting
func _apply_mute_when_minimized() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	var mute_when_minimized: bool = sp.get_setting("mute_when_minimized", true)

	# If setting is enabled and window is not focused, mute Master
	# Otherwise, restore Master volume from settings
	if mute_when_minimized and not _window_focused:
		AudioServer.set_bus_mute(BUS_MASTER, true)
	else:
		AudioServer.set_bus_mute(BUS_MASTER, false)


## Get current volume for a bus as percentage
func get_bus_volume_percent(bus_idx: int) -> int:
	if bus_idx < 0 or bus_idx >= AudioServer.bus_count:
		return 0
	var volume_db: float = AudioServer.get_bus_volume_db(bus_idx)
	var volume_linear: float = db_to_linear(volume_db)
	return int(volume_linear * 100.0)


## Check if a bus is muted
func is_bus_muted(bus_idx: int) -> bool:
	if bus_idx < 0 or bus_idx >= AudioServer.bus_count:
		return false
	return AudioServer.is_bus_mute(bus_idx)


## Get bus index by name
func get_bus_index(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


## Set dynamic music enabled (placeholder for future music system)
func set_dynamic_music_enabled(_enabled: bool) -> void:
	# TODO: Connect to music system when implemented
	pass
