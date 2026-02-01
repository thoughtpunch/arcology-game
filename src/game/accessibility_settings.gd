extends Node
## AccessibilitySettings autoload - applies accessibility settings
## Listens to SettingsPersistence for changes and applies to:
## - Colorblind mode (shader-based color correction)
## - High contrast UI (theme override)
## - Reduce motion (disable tweens/animations)
## - Screen flash effects (toggle)
## - Font size (theme multiplier)
## - Dyslexia font (OpenDyslexic)
## - Extended tooltips (tooltip system)
## - Slower game speed max (TimeControls)

# Signals for systems to react
signal colorblind_mode_changed(mode: int)
signal high_contrast_changed(enabled: bool)
signal reduce_motion_changed(enabled: bool)
signal screen_flash_changed(enabled: bool)
signal font_size_changed(multiplier: float)
signal extended_tooltips_changed(enabled: bool)
signal max_speed_changed(max_speed: int)

# Colorblind mode options (0=Off, 1=Red-blind, 2=Green-blind, 3=Blue-blind)
const COLORBLIND_MODES := {"Off": 0, "Protanopia": 1, "Deuteranopia": 2, "Tritanopia": 3}

# Font size options
const FONT_SIZES := {"Small": 0.9, "Medium": 1.0, "Large": 1.2, "Extra Large": 1.5}

# Game speed options (slower max for accessibility)
const SLOWER_SPEED_MAX := 2  # Max speed when accessibility option enabled
const NORMAL_SPEED_MAX := 3  # Normal max speed

# State
var _colorblind_mode: int = 0
var _high_contrast_ui: bool = false
var _reduce_motion: bool = false
var _screen_flash_effects: bool = true
var _font_size_multiplier: float = 1.0
var _dyslexia_font: bool = false
var _extended_tooltips: bool = false
var _slower_speed_max: bool = false


func _ready() -> void:
	# Apply initial settings
	call_deferred("_apply_all_settings")

	# Connect to settings changes
	var sp := _get_settings_persistence()
	if sp:
		sp.setting_changed.connect(_on_setting_changed)
		sp.settings_loaded.connect(_apply_all_settings)


## Get SettingsPersistence autoload
func _get_settings_persistence() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/SettingsPersistence")
	return null


## Apply all accessibility settings from SettingsPersistence
func _apply_all_settings() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	_apply_colorblind_mode(sp.get_setting("colorblind_mode", "Off"))
	_apply_high_contrast_ui(sp.get_setting("high_contrast_ui", false))
	_apply_reduce_motion(sp.get_setting("reduce_motion", false))
	_apply_screen_flash_effects(sp.get_setting("screen_flash_effects", true))
	_apply_font_size(sp.get_setting("font_size", "Medium"))
	_apply_dyslexia_font(sp.get_setting("dyslexia_font", false))
	_apply_extended_tooltips(sp.get_setting("extended_tooltips", false))
	_apply_slower_game_speed_max(sp.get_setting("slower_game_speed_max", false))


## Handle individual setting changes
func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"colorblind_mode":
			_apply_colorblind_mode(value)
		"high_contrast_ui":
			_apply_high_contrast_ui(value)
		"reduce_motion":
			_apply_reduce_motion(value)
		"screen_flash_effects":
			_apply_screen_flash_effects(value)
		"font_size":
			_apply_font_size(value)
		"dyslexia_font":
			_apply_dyslexia_font(value)
		"extended_tooltips":
			_apply_extended_tooltips(value)
		"slower_game_speed_max":
			_apply_slower_game_speed_max(value)


## Apply colorblind mode setting
func _apply_colorblind_mode(mode: Variant) -> void:
	var mode_str: String = str(mode)
	var mode_id: int = COLORBLIND_MODES.get(mode_str, 0)
	_colorblind_mode = mode_id
	colorblind_mode_changed.emit(mode_id)


## Apply high contrast UI setting
func _apply_high_contrast_ui(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_high_contrast_ui = enable
	high_contrast_changed.emit(enable)


## Apply reduce motion setting
func _apply_reduce_motion(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_reduce_motion = enable
	reduce_motion_changed.emit(enable)


## Apply screen flash effects setting
func _apply_screen_flash_effects(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_screen_flash_effects = enable
	screen_flash_changed.emit(enable)


## Apply font size setting
func _apply_font_size(size: Variant) -> void:
	var size_str: String = str(size)
	var multiplier: float = FONT_SIZES.get(size_str, 1.0)
	_font_size_multiplier = multiplier
	font_size_changed.emit(multiplier)


## Apply dyslexia font setting
func _apply_dyslexia_font(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_dyslexia_font = enable
	# Font loading would happen here if font resource is available


## Apply extended tooltips setting
func _apply_extended_tooltips(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_extended_tooltips = enable
	extended_tooltips_changed.emit(enable)


## Apply slower game speed max setting
func _apply_slower_game_speed_max(enabled: Variant) -> void:
	var enable: bool = enabled if enabled is bool else bool(enabled)
	_slower_speed_max = enable
	var max_speed: int = SLOWER_SPEED_MAX if enable else NORMAL_SPEED_MAX
	max_speed_changed.emit(max_speed)


## Get current colorblind mode (0=off, 1=protanopia, 2=deuteranopia, 3=tritanopia)
func get_colorblind_mode() -> int:
	return _colorblind_mode


## Check if high contrast UI is enabled
func is_high_contrast_enabled() -> bool:
	return _high_contrast_ui


## Check if motion should be reduced
func should_reduce_motion() -> bool:
	return _reduce_motion


## Check if screen flash effects are enabled
func are_screen_flash_effects_enabled() -> bool:
	return _screen_flash_effects


## Get font size multiplier (0.9 to 1.5)
func get_font_size_multiplier() -> float:
	return _font_size_multiplier


## Check if dyslexia font is enabled
func is_dyslexia_font_enabled() -> bool:
	return _dyslexia_font


## Check if extended tooltips are enabled
func are_extended_tooltips_enabled() -> bool:
	return _extended_tooltips


## Get max game speed (2 or 3)
func get_max_game_speed() -> int:
	return SLOWER_SPEED_MAX if _slower_speed_max else NORMAL_SPEED_MAX


## Check if a tween should be instant (when reduce motion enabled)
func should_instant_tween() -> bool:
	return _reduce_motion


## Get tween duration adjusted for accessibility
func get_adjusted_duration(base_duration: float) -> float:
	if _reduce_motion:
		return 0.0  # Instant
	return base_duration


## Get colorblind mode name
func get_colorblind_mode_name() -> String:
	for mode_name in COLORBLIND_MODES:
		if COLORBLIND_MODES[mode_name] == _colorblind_mode:
			return mode_name
	return "Off"
