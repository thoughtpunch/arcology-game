class_name Terrain
extends Node2D
## Base terrain layer beneath the arcology grid
## Renders decorative ground surface and background at Z=0

# Theme colors from documentation/game-design/environment/terrain.md
const THEME_COLORS := {
	"earth": Color("#4a7c4e"),  # Grass green
	"mars": Color("#8b4513"),   # Rust red
	"space": Color(0, 0, 0, 0), # Transparent (uses starfield background)
}

# Z-index layers from terrain.md
const Z_INDEX_BACKGROUND := -2000
const Z_INDEX_BASE_PLANE := -1000
const Z_INDEX_DECORATIONS_MIN := -500
const Z_INDEX_DECORATIONS_MAX := -100

# Current scenario theme
var theme: String = "earth":
	set(value):
		if value in THEME_COLORS:
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


func _ready() -> void:
	_setup_base_plane()
	_update_theme()


## Setup the base plane ColorRect
func _setup_base_plane() -> void:
	# Background layer (sky/starfield)
	_background = ColorRect.new()
	_background.z_index = Z_INDEX_BACKGROUND - Z_INDEX_BASE_PLANE  # Relative to parent
	_background.size = plane_size * 2
	_background.position = -plane_size
	_background.color = Color("#87ceeb")  # Default sky blue
	add_child(_background)

	# Base terrain plane
	_base_plane = ColorRect.new()
	_base_plane.z_index = 0  # Same as parent (z_index -1000)
	_base_plane.size = plane_size
	_base_plane.position = -plane_size / 2
	_base_plane.color = THEME_COLORS["earth"]
	add_child(_base_plane)


## Update visuals based on current theme
func _update_theme() -> void:
	if not is_inside_tree():
		return

	# Update base plane color
	if _base_plane:
		_base_plane.color = THEME_COLORS.get(theme, THEME_COLORS["earth"])

	# Update background based on theme
	if _background:
		match theme:
			"earth":
				_background.color = Color("#87ceeb")  # Sky blue
				_background.visible = true
			"mars":
				_background.color = Color("#d4856a")  # Orange-pink Mars sky
				_background.visible = true
			"space":
				# Space has transparent base plane, dark background
				_background.color = Color("#0a0a1a")  # Dark space
				_background.visible = true
				if _base_plane:
					_base_plane.color = Color(0, 0, 0, 0)  # Transparent


## Get the current theme color
func get_theme_color() -> Color:
	return THEME_COLORS.get(theme, THEME_COLORS["earth"])


## Check if theme is valid
static func is_valid_theme(theme_name: String) -> bool:
	return theme_name in THEME_COLORS


## Get list of available themes
static func get_available_themes() -> PackedStringArray:
	return PackedStringArray(THEME_COLORS.keys())


## Set plane size (for different map sizes)
func set_plane_size(size: Vector2) -> void:
	plane_size = size
	if _base_plane:
		_base_plane.size = plane_size
		_base_plane.position = -plane_size / 2
	if _background:
		_background.size = plane_size * 2
		_background.position = -plane_size
