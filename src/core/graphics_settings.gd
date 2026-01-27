extends Node
## GraphicsSettings autoload - applies graphics settings to DisplayServer/Engine
## Listens to SettingsPersistence for changes and applies to rendering

# Resolution presets (matching SettingsMenu dropdown)
const RESOLUTION_PRESETS := {
	"1280x720": Vector2i(1280, 720),
	"1920x1080": Vector2i(1920, 1080),
	"2560x1440": Vector2i(2560, 1440),
	"3840x2160": Vector2i(3840, 2160)
}

# Display modes (matching SettingsMenu dropdown)
const DISPLAY_MODES := {
	"Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
	"Fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"Borderless": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
}

# Frame rate limits
const FRAME_RATE_LIMITS := {
	"30 FPS": 30,
	"60 FPS": 60,
	"120 FPS": 120,
	"Unlimited": 0
}

# VSync modes
const VSYNC_MODES := {
	true: DisplayServer.VSYNC_ENABLED,
	false: DisplayServer.VSYNC_DISABLED
}

# FPS counter overlay
var _fps_label: Label


func _ready() -> void:
	# Apply initial settings
	call_deferred("_apply_all_settings")

	# Connect to settings changes
	var sp := _get_settings_persistence()
	if sp:
		sp.setting_changed.connect(_on_setting_changed)
		sp.settings_loaded.connect(_apply_all_settings)


func _process(_delta: float) -> void:
	# Update FPS counter if enabled
	if _fps_label and _fps_label.visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


## Get SettingsPersistence autoload
func _get_settings_persistence() -> Node:
	var tree := get_tree()
	if tree:
		return tree.root.get_node_or_null("/root/SettingsPersistence")
	return null


## Apply all graphics settings from SettingsPersistence
func _apply_all_settings() -> void:
	var sp := _get_settings_persistence()
	if not sp:
		return

	# Apply each setting
	_apply_resolution(sp.get_setting("resolution", "1920x1080"))
	_apply_display_mode(sp.get_setting("display_mode", "Fullscreen"))
	_apply_vsync(sp.get_setting("vsync", true))
	_apply_frame_rate_limit(sp.get_setting("frame_rate_limit", 60))
	_apply_ui_scale(sp.get_setting("ui_scale", 100))
	_apply_show_fps(sp.get_setting("show_fps", false))


## Handle individual setting changes
func _on_setting_changed(key: String, value: Variant) -> void:
	match key:
		"resolution":
			_apply_resolution(value)
		"display_mode":
			_apply_display_mode(value)
		"vsync":
			_apply_vsync(value)
		"frame_rate_limit":
			_apply_frame_rate_limit(value)
		"ui_scale":
			_apply_ui_scale(value)
		"show_fps":
			_apply_show_fps(value)


## Apply resolution setting
func _apply_resolution(resolution_str: Variant) -> void:
	var res_string: String = str(resolution_str)
	if res_string in RESOLUTION_PRESETS:
		var size: Vector2i = RESOLUTION_PRESETS[res_string]
		DisplayServer.window_set_size(size)


## Apply display mode setting
func _apply_display_mode(mode_str: Variant) -> void:
	var mode_string: String = str(mode_str)
	if mode_string in DISPLAY_MODES:
		var mode: int = DISPLAY_MODES[mode_string]
		DisplayServer.window_set_mode(mode)


## Apply VSync setting
func _apply_vsync(enabled: Variant) -> void:
	var vsync_on: bool = enabled if enabled is bool else bool(enabled)
	var mode: int = VSYNC_MODES[vsync_on]
	DisplayServer.window_set_vsync_mode(mode)


## Apply frame rate limit setting
func _apply_frame_rate_limit(limit: Variant) -> void:
	var fps_limit: int
	if limit is String:
		# Handle dropdown option strings like "60 FPS"
		fps_limit = FRAME_RATE_LIMITS.get(limit, 60)
	elif limit is int:
		fps_limit = limit
	else:
		fps_limit = 60

	Engine.max_fps = fps_limit


## Apply UI scale setting
func _apply_ui_scale(scale_percent: Variant) -> void:
	var scale: int = scale_percent if scale_percent is int else int(scale_percent)
	var scale_factor: float = clampf(scale / 100.0, 0.5, 2.0)

	var tree := get_tree()
	if tree and tree.root:
		tree.root.content_scale_factor = scale_factor


## Apply show FPS setting
func _apply_show_fps(show: Variant) -> void:
	var show_fps: bool = show if show is bool else bool(show)

	if show_fps:
		if not _fps_label:
			_create_fps_label()
		_fps_label.visible = true
	else:
		if _fps_label:
			_fps_label.visible = false


## Create FPS counter label
func _create_fps_label() -> void:
	_fps_label = Label.new()
	_fps_label.name = "FPSLabel"
	_fps_label.text = "FPS: --"

	# Position in top-right corner
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left = -100
	_fps_label.offset_right = -10
	_fps_label.offset_top = 10
	_fps_label.offset_bottom = 30
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Style for visibility
	_fps_label.add_theme_font_size_override("font_size", 14)
	_fps_label.add_theme_color_override("font_color", Color.WHITE)
	_fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_fps_label.add_theme_constant_override("shadow_offset_x", 1)
	_fps_label.add_theme_constant_override("shadow_offset_y", 1)

	# Add to UI layer
	var tree := get_tree()
	if tree and tree.root:
		# Create a CanvasLayer for HUD elements
		var canvas := CanvasLayer.new()
		canvas.name = "FPSOverlay"
		canvas.layer = 100  # Above most UI
		tree.root.add_child(canvas)
		canvas.add_child(_fps_label)


## Get current resolution as string
func get_current_resolution() -> String:
	var size: Vector2i = DisplayServer.window_get_size()
	return "%dx%d" % [size.x, size.y]


## Get current display mode as string
func get_current_display_mode() -> String:
	var mode: int = DisplayServer.window_get_mode()
	for mode_name in DISPLAY_MODES:
		if DISPLAY_MODES[mode_name] == mode:
			return mode_name
	return "Windowed"


## Get current vsync state
func is_vsync_enabled() -> bool:
	return DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED


## Get current frame rate limit
func get_frame_rate_limit() -> int:
	return Engine.max_fps


## Get current UI scale as percentage
func get_ui_scale_percent() -> int:
	var tree := get_tree()
	if tree and tree.root:
		return int(tree.root.content_scale_factor * 100)
	return 100


## Check if FPS counter is visible
func is_fps_visible() -> bool:
	return _fps_label != null and _fps_label.visible
