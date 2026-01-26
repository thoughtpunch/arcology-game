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

# World seed for deterministic decoration placement
var world_seed: int = 0:
	set(value):
		world_seed = value
		# Regenerate decorations when seed changes
		if is_inside_tree() and _decorations_container:
			_clear_decorations()
			scatter_decorations(_scatter_area)

# Internal nodes
var _base_plane: ColorRect
var _background: ColorRect
var _decorations_container: Node2D

# Decoration tracking
# Maps grid position (Vector2i) to Sprite2D node
var _decorations: Dictionary = {}

# Area for decoration scatter (grid coordinates)
var _scatter_area: Rect2i = Rect2i(-20, -20, 40, 40)


func _init() -> void:
	z_index = Z_INDEX_BASE_PLANE
	_load_terrain_data()


func _ready() -> void:
	_setup_base_plane()
	_setup_decorations_container()
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


## Setup the decorations container
func _setup_decorations_container() -> void:
	_decorations_container = Node2D.new()
	# Decorations are between base plane and blocks
	# z_index relative to parent (-1000), so +500 puts us at -500 absolute
	_decorations_container.z_index = Z_INDEX_DECORATIONS_MIN - Z_INDEX_BASE_PLANE
	add_child(_decorations_container)


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


# =============================================================================
# DECORATION SCATTER SYSTEM
# =============================================================================

## Scatter decorations across the terrain area
## Uses world_seed for deterministic placement
func scatter_decorations(area: Rect2i) -> void:
	_scatter_area = area
	_clear_decorations()

	# Ensure decorations container exists
	if not _decorations_container:
		_decorations_container = Node2D.new()
		_decorations_container.z_index = Z_INDEX_DECORATIONS_MIN - Z_INDEX_BASE_PLANE
		add_child(_decorations_container)

	var density := get_decoration_density()
	if density <= 0:
		return

	var decorations_config := get_decorations_config()
	if decorations_config.is_empty():
		return

	# Calculate total weight for normalization
	var total_weight := 0.0
	for config in decorations_config:
		total_weight += config.get("weight", 0.0)

	if total_weight <= 0:
		return

	# Create deterministic RNG
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed

	# Iterate over area and place decorations based on density
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			# Use position-seeded random for this cell
			var cell_seed := world_seed + x * 10000 + y
			rng.seed = cell_seed

			if rng.randf() < density:
				var deco_type := _pick_weighted_decoration(rng, decorations_config, total_weight)
				if not deco_type.is_empty():
					_place_decoration(Vector2i(x, y), deco_type)


## Pick a decoration type based on weights
func _pick_weighted_decoration(rng: RandomNumberGenerator, configs: Array, total_weight: float) -> String:
	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for config in configs:
		cumulative += config.get("weight", 0.0)
		if roll <= cumulative:
			return config.get("type", "")

	# Fallback to last type
	if not configs.is_empty():
		return configs[-1].get("type", "")
	return ""


## Place a decoration sprite at grid position
func _place_decoration(grid_pos: Vector2i, deco_type: String) -> void:
	if not _decorations_container:
		return

	# Check if position already has a decoration
	if _decorations.has(grid_pos):
		return

	# Load sprite texture
	var sprite_path := _get_decoration_sprite_path(deco_type)
	if sprite_path.is_empty():
		return

	var texture := load(sprite_path) as Texture2D
	if texture == null:
		return

	# Create sprite
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = _grid_to_screen(grid_pos)

	# Calculate z_index for proper sorting within decorations layer
	# Higher x+y = further back = lower z_index within decorations range
	var sort_value := grid_pos.x + grid_pos.y
	# Map sort value to z_index range (Z_INDEX_DECORATIONS_MIN to MAX relative to container)
	sprite.z_index = sort_value

	_decorations_container.add_child(sprite)
	_decorations[grid_pos] = sprite


## Get sprite path for decoration type
func _get_decoration_sprite_path(deco_type: String) -> String:
	# Theme-specific path
	var theme_dir := theme
	if theme == "space":
		return ""  # No decorations in space

	return "res://assets/sprites/terrain/%s/%s.png" % [theme_dir, deco_type]


## Convert grid position to screen position for decoration placement
func _grid_to_screen(grid_pos: Vector2i) -> Vector2:
	# Use same isometric conversion as blocks
	const TILE_WIDTH := 64
	const TILE_DEPTH := 32

	var x := (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
	var y := (grid_pos.x + grid_pos.y) * (TILE_DEPTH / 2)
	return Vector2(x, y)


## Clear all decorations
func _clear_decorations() -> void:
	for pos in _decorations:
		var sprite: Sprite2D = _decorations[pos]
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	_decorations.clear()


## Hide decoration at grid position (when block placed)
func hide_decoration_at(grid_pos: Vector2i) -> void:
	if _decorations.has(grid_pos):
		var sprite: Sprite2D = _decorations[grid_pos]
		if sprite and is_instance_valid(sprite):
			sprite.visible = false


## Show decoration at grid position (when block removed)
func show_decoration_at(grid_pos: Vector2i) -> void:
	if _decorations.has(grid_pos):
		var sprite: Sprite2D = _decorations[grid_pos]
		if sprite and is_instance_valid(sprite):
			sprite.visible = true


## Check if there's a decoration at position
func has_decoration_at(grid_pos: Vector2i) -> bool:
	return _decorations.has(grid_pos)


## Get decoration type at position (or empty string)
func get_decoration_type_at(grid_pos: Vector2i) -> String:
	# We don't store type, but can check if decoration exists
	if _decorations.has(grid_pos):
		return "decoration"  # Generic - could enhance to track types
	return ""


## Get all decoration positions
func get_all_decoration_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in _decorations.keys():
		positions.append(pos as Vector2i)
	return positions


## Get decoration count
func get_decoration_count() -> int:
	return _decorations.size()


## Set scatter area and regenerate decorations
func set_scatter_area(area: Rect2i) -> void:
	if area != _scatter_area:
		scatter_decorations(area)
