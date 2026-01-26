class_name Terrain
extends Node2D
## Base terrain layer beneath the arcology grid
## Renders decorative ground surface and background at Z=0
## Loads theme configuration from data/terrain.json

# Path to terrain configuration file
const TERRAIN_DATA_PATH := "res://data/terrain.json"

# Z-index layers from terrain.md
const Z_INDEX_BACKGROUND := -2000
const Z_INDEX_BASE_PLANE := -1000
const Z_INDEX_DECORATIONS_MIN := -500
const Z_INDEX_DECORATIONS_MAX := -100

# Fallback colors if JSON loading fails
const FALLBACK_THEME_COLORS := {
	"earth": Color("#4a7c4e"),
	"mars": Color("#8b4513"),
	"space": Color(0, 0, 0, 0),
}

const FALLBACK_BACKGROUND_COLORS := {
	"earth": Color("#87ceeb"),
	"mars": Color("#d4856a"),
	"space": Color("#0a0a1a"),
}

# Loaded terrain data from JSON
var _terrain_data: Dictionary = {}

# Current scenario theme
var theme: String = "earth":
	set(value):
		if _is_valid_theme(value):
			theme = value
			_update_theme()
		else:
			push_warning("Terrain: Invalid theme '%s', using 'earth'" % value)
			theme = "earth"
			_update_theme()

# Visual size of the terrain plane (in screen pixels)
var plane_size := Vector2(2000, 2000)

# Internal nodes
var _base_plane: ColorRect
var _background: ColorRect


func _init() -> void:
	z_index = Z_INDEX_BASE_PLANE
	_load_terrain_data()


func _ready() -> void:
	_setup_base_plane()
	_update_theme()


## Load terrain configuration from JSON
func _load_terrain_data() -> void:
	if not FileAccess.file_exists(TERRAIN_DATA_PATH):
		push_warning("Terrain: '%s' not found, using fallback colors" % TERRAIN_DATA_PATH)
		return

	var file := FileAccess.open(TERRAIN_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Terrain: Failed to open '%s'" % TERRAIN_DATA_PATH)
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("Terrain: JSON parse error in '%s': %s" % [TERRAIN_DATA_PATH, json.get_error_message()])
		return

	_terrain_data = json.get_data()


## Check if theme is valid
func _is_valid_theme(theme_name: String) -> bool:
	if _terrain_data.has("themes"):
		return theme_name in _terrain_data.themes
	return theme_name in FALLBACK_THEME_COLORS


## Get theme data from JSON (or empty dict)
func _get_theme_data(theme_name: String) -> Dictionary:
	if _terrain_data.has("themes") and _terrain_data.themes.has(theme_name):
		return _terrain_data.themes[theme_name]
	return {}


## Get base color for a theme
func _get_base_color(theme_name: String) -> Color:
	var data := _get_theme_data(theme_name)
	if data.has("base_color") and data.base_color != null:
		return Color(data.base_color)
	return FALLBACK_THEME_COLORS.get(theme_name, FALLBACK_THEME_COLORS["earth"])


## Get background color for a theme
func _get_background_color(theme_name: String) -> Color:
	var data := _get_theme_data(theme_name)
	if data.has("background_color"):
		return Color(data.background_color)
	return FALLBACK_BACKGROUND_COLORS.get(theme_name, FALLBACK_BACKGROUND_COLORS["earth"])


## Setup the base plane ColorRect
func _setup_base_plane() -> void:
	# Background layer (sky/starfield)
	_background = ColorRect.new()
	_background.z_index = Z_INDEX_BACKGROUND - Z_INDEX_BASE_PLANE  # Relative to parent
	_background.size = plane_size * 2
	_background.position = -plane_size
	_background.color = _get_background_color("earth")
	add_child(_background)

	# Base terrain plane
	_base_plane = ColorRect.new()
	_base_plane.z_index = 0  # Same as parent (z_index -1000)
	_base_plane.size = plane_size
	_base_plane.position = -plane_size / 2
	_base_plane.color = _get_base_color("earth")
	add_child(_base_plane)


## Update visuals based on current theme
func _update_theme() -> void:
	if not is_inside_tree():
		return

	# Update base plane color
	if _base_plane:
		_base_plane.color = _get_base_color(theme)

	# Update background
	if _background:
		_background.color = _get_background_color(theme)
		_background.visible = true


## Get the current theme color (base plane)
func get_theme_color() -> Color:
	return _get_base_color(theme)


## Check if theme is valid (static version for external use)
static func is_valid_theme(theme_name: String) -> bool:
	# Static version can only check fallback themes
	return theme_name in FALLBACK_THEME_COLORS


## Get list of available themes
func get_available_themes() -> PackedStringArray:
	if _terrain_data.has("themes"):
		return PackedStringArray(_terrain_data.themes.keys())
	return PackedStringArray(FALLBACK_THEME_COLORS.keys())


## Set plane size (for different map sizes)
func set_plane_size(size: Vector2) -> void:
	plane_size = size
	if _base_plane:
		_base_plane.size = plane_size
		_base_plane.position = -plane_size / 2
	if _background:
		_background.size = plane_size * 2
		_background.position = -plane_size


## Get theme data for decorations (for use by decoration system)
func get_decorations_config() -> Array:
	var data := _get_theme_data(theme)
	return data.get("decorations", [])


## Get decoration density for current theme
func get_decoration_density() -> float:
	var data := _get_theme_data(theme)
	return data.get("decoration_density", 0.0)


## Check if current theme has a river
func has_river() -> bool:
	var data := _get_theme_data(theme)
	return data.get("has_river", false)


## Get background sprite path for current theme
func get_background_sprite() -> String:
	var data := _get_theme_data(theme)
	var bg: String = data.get("background", "")
	if bg.is_empty():
		return ""
	return "res://assets/sprites/terrain/backgrounds/" + bg
