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
var _background_color: ColorRect  # Fallback solid color
var _background_texture: TextureRect  # Sprite-based background
var _decorations_container: Node2D

# Decoration tracking
# Maps grid position (Vector2i) to Sprite2D node
var _decorations: Dictionary = {}

# Area for decoration scatter (grid coordinates)
var _scatter_area: Rect2i = Rect2i(-20, -20, 40, 40)

# River system
var _river_container: Node2D
var _river_positions: Array[Vector2i] = []  # Ordered path of river tiles
var _river_tiles: Dictionary = {}  # Maps Vector2i -> Sprite2D
signal river_generated(positions: Array[Vector2i])


func _init() -> void:
	z_index = Z_INDEX_BASE_PLANE
	_load_terrain_data()


func _ready() -> void:
	_setup_base_plane()
	_setup_decorations_container()
	_setup_river_container()
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
	# Background layer - color fallback
	_background_color = ColorRect.new()
	_background_color.z_index = Z_INDEX_BACKGROUND - Z_INDEX_BASE_PLANE  # Relative to parent
	_background_color.size = plane_size * 2
	_background_color.position = -plane_size
	_background_color.color = _get_background_color("earth")
	add_child(_background_color)

	# Background layer - texture (added after color so it renders on top when visible)
	_background_texture = TextureRect.new()
	_background_texture.z_index = Z_INDEX_BACKGROUND - Z_INDEX_BASE_PLANE + 1  # Just above color
	_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_texture.size = plane_size * 2
	_background_texture.position = -plane_size
	_background_texture.visible = false  # Hidden until texture loaded
	add_child(_background_texture)

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

	# Update background - try texture first, fallback to color
	_update_background()


## Update background layer (texture or color fallback)
func _update_background() -> void:
	var sprite_path := get_background_sprite()
	var texture_loaded := false

	# Try to load texture
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var texture := load(sprite_path) as Texture2D
		if texture and _background_texture:
			_background_texture.texture = texture
			_background_texture.visible = true
			texture_loaded = true

	# Show/hide appropriate background layer
	if _background_texture:
		_background_texture.visible = texture_loaded

	if _background_color:
		# Color always updates (serves as fallback and provides tint for space theme)
		_background_color.color = _get_background_color(theme)
		# Color visible when no texture, or always visible for blending
		_background_color.visible = not texture_loaded


## Check if background texture is loaded
func has_background_texture() -> bool:
	return _background_texture and _background_texture.texture != null and _background_texture.visible


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
	if _background_color:
		_background_color.size = plane_size * 2
		_background_color.position = -plane_size
	if _background_texture:
		_background_texture.size = plane_size * 2
		_background_texture.position = -plane_size


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
			var pos := Vector2i(x, y)

			# Skip positions that are part of river
			if pos in _river_positions:
				continue

			# Use position-seeded random for this cell
			var cell_seed := world_seed + x * 10000 + y
			rng.seed = cell_seed

			if rng.randf() < density:
				var deco_type := _pick_weighted_decoration(rng, decorations_config, total_weight)
				if not deco_type.is_empty():
					_place_decoration(pos, deco_type)


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


# =============================================================================
# RIVER SYSTEM
# =============================================================================

const Z_INDEX_RIVER := -400  # Between decorations (-500) and blocks (0)

## Setup river container node
func _setup_river_container() -> void:
	_river_container = Node2D.new()
	# River is above decorations but below blocks
	_river_container.z_index = Z_INDEX_RIVER - Z_INDEX_BASE_PLANE
	add_child(_river_container)


## Generate river for the terrain
## Call this after scatter_decorations to ensure river doesn't have decorations on it
func generate_river(area: Rect2i) -> void:
	_clear_river()

	if not has_river():
		return

	# Generate river path
	_river_positions = _generate_river_path(area)

	if _river_positions.is_empty():
		return

	# Remove any decorations that would be on the river
	for pos in _river_positions:
		if _decorations.has(pos):
			var sprite: Sprite2D = _decorations[pos]
			if sprite and is_instance_valid(sprite):
				sprite.queue_free()
			_decorations.erase(pos)

	# Create river tile sprites
	_render_river()

	river_generated.emit(_river_positions)


## Generate a deterministic river path that crosses the map
## Returns array of Vector2i positions in order from start to end
func _generate_river_path(area: Rect2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	# Use world_seed for deterministic generation
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed + 999999  # Offset from decoration seed

	# Determine which edges to connect (prefer N-S or diagonal paths)
	# Pick random Y position on left edge as start
	var start_y := rng.randi_range(area.position.y + 2, area.end.y - 3)
	var start_pos := Vector2i(area.position.x, start_y)

	# Pick random Y position on right edge as end
	var end_y := rng.randi_range(area.position.y + 2, area.end.y - 3)
	var end_pos := Vector2i(area.end.x - 1, end_y)

	# Generate winding path from start to end
	path = _generate_winding_path(start_pos, end_pos, area, rng)

	return path


## Generate a winding path between two points
func _generate_winding_path(start: Vector2i, end: Vector2i, area: Rect2i, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start

	path.append(current)

	# Move towards end with occasional wandering
	var max_iterations := (area.size.x + area.size.y) * 3  # Prevent infinite loops
	var iterations := 0

	while current != end and iterations < max_iterations:
		iterations += 1

		var direction := end - current
		var candidates: Array[Vector2i] = []

		# Prefer moving towards end
		if direction.x > 0:
			candidates.append(Vector2i(current.x + 1, current.y))  # East
		elif direction.x < 0:
			candidates.append(Vector2i(current.x - 1, current.y))  # West

		if direction.y > 0:
			candidates.append(Vector2i(current.x, current.y + 1))  # South
		elif direction.y < 0:
			candidates.append(Vector2i(current.x, current.y - 1))  # North

		# Add some randomness - occasionally move perpendicular
		if rng.randf() < 0.3:
			if direction.x != 0:
				# Add vertical options
				if current.y > area.position.y + 1:
					candidates.append(Vector2i(current.x, current.y - 1))
				if current.y < area.end.y - 2:
					candidates.append(Vector2i(current.x, current.y + 1))

		# Filter out positions already in path or out of bounds
		var valid_candidates: Array[Vector2i] = []
		for pos in candidates:
			if pos not in path and _is_in_bounds(pos, area):
				valid_candidates.append(pos)

		if valid_candidates.is_empty():
			# Stuck - try to find any adjacent valid position
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					if abs(dx) + abs(dy) != 1:  # Only orthogonal
						continue
					var try_pos := Vector2i(current.x + dx, current.y + dy)
					if try_pos not in path and _is_in_bounds(try_pos, area):
						valid_candidates.append(try_pos)

		if valid_candidates.is_empty():
			break  # Truly stuck

		# Pick from valid candidates (weighted towards direction to end)
		var best_candidate := valid_candidates[0]
		var best_dist := _manhattan_distance(valid_candidates[0], end)

		for candidate in valid_candidates:
			var dist := _manhattan_distance(candidate, end)
			if dist < best_dist or (dist == best_dist and rng.randf() < 0.5):
				best_dist = dist
				best_candidate = candidate

		current = best_candidate
		path.append(current)

	return path


## Check if position is within area bounds
func _is_in_bounds(pos: Vector2i, area: Rect2i) -> bool:
	return pos.x >= area.position.x and pos.x < area.end.x and pos.y >= area.position.y and pos.y < area.end.y


## Manhattan distance between two positions
func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## Render river tiles based on generated path
func _render_river() -> void:
	if _river_positions.is_empty():
		return

	if not _river_container:
		_setup_river_container()

	var river_config: Dictionary = _get_river_config()
	var sprite_path: String = river_config.get("sprite_path", "res://assets/sprites/terrain/earth/river_tiles/")
	var tiles: Dictionary = river_config.get("tiles", {})

	for i in range(_river_positions.size()):
		var pos := _river_positions[i]
		var tile_name := _get_river_tile_type(i)
		var tile_file: String = tiles.get(tile_name, "")

		if tile_file.is_empty():
			tile_file = tile_name + ".png"

		var full_path: String = sprite_path + tile_file
		if not ResourceLoader.exists(full_path):
			continue

		var texture := load(full_path) as Texture2D
		if texture == null:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = _grid_to_screen(pos)
		sprite.z_index = pos.x + pos.y  # Y-sorting within river layer

		_river_container.add_child(sprite)
		_river_tiles[pos] = sprite


## Get river configuration from theme data
func _get_river_config() -> Dictionary:
	var data := _get_theme_data(theme)
	return data.get("river", {})


## Determine which river tile type to use based on neighbors in path
func _get_river_tile_type(path_index: int) -> String:
	if path_index < 0 or path_index >= _river_positions.size():
		return "end_n"

	var pos := _river_positions[path_index]

	# Get previous and next positions in path
	var has_prev := path_index > 0
	var has_next := path_index < _river_positions.size() - 1

	var prev_dir := Vector2i.ZERO
	var next_dir := Vector2i.ZERO

	if has_prev:
		prev_dir = pos - _river_positions[path_index - 1]
	if has_next:
		next_dir = _river_positions[path_index + 1] - pos

	# Determine tile type based on directions
	# Direction vectors: (+1, 0) = East, (-1, 0) = West, (0, +1) = South, (0, -1) = North

	# End tiles (only one connection)
	if not has_prev and has_next:
		return _get_end_tile(next_dir)
	if has_prev and not has_next:
		return _get_end_tile(-prev_dir)  # Face away from incoming

	# Straight or corner (two connections)
	if has_prev and has_next:
		# Check if it's straight
		if prev_dir.x != 0 and next_dir.x != 0 and prev_dir.y == 0 and next_dir.y == 0:
			return "straight_ew"  # East-West aligned
		if prev_dir.y != 0 and next_dir.y != 0 and prev_dir.x == 0 and next_dir.x == 0:
			return "straight_ns"  # North-South aligned

		# It's a corner - determine which one
		return _get_corner_tile(prev_dir, next_dir)

	return "straight_ns"  # Default


## Get end tile based on direction river faces
func _get_end_tile(dir: Vector2i) -> String:
	if dir.x > 0:
		return "end_e"
	if dir.x < 0:
		return "end_w"
	if dir.y > 0:
		return "end_s"
	if dir.y < 0:
		return "end_n"
	return "end_n"


## Get corner tile based on incoming and outgoing directions
func _get_corner_tile(prev_dir: Vector2i, next_dir: Vector2i) -> String:
	# prev_dir is direction FROM previous TO current
	# next_dir is direction FROM current TO next

	# Corner NE: comes from S or W, goes to N or E
	# Corner NW: comes from S or E, goes to N or W
	# Corner SE: comes from N or W, goes to S or E
	# Corner SW: comes from N or E, goes to S or W

	# Determine which quadrant the corner is in
	# based on the two directions involved

	var from_north := prev_dir.y > 0  # Coming from north means prev_dir.y > 0 (moved south to get here)
	var from_south := prev_dir.y < 0
	var from_east := prev_dir.x < 0
	var from_west := prev_dir.x > 0

	var to_north := next_dir.y < 0
	var to_south := next_dir.y > 0
	var to_east := next_dir.x > 0
	var to_west := next_dir.x < 0

	# NE corner: from south + to east, or from west + to north
	if (from_south and to_east) or (from_west and to_north):
		return "corner_ne"
	# NW corner: from south + to west, or from east + to north
	if (from_south and to_west) or (from_east and to_north):
		return "corner_nw"
	# SE corner: from north + to east, or from west + to south
	if (from_north and to_east) or (from_west and to_south):
		return "corner_se"
	# SW corner: from north + to west, or from east + to south
	if (from_north and to_west) or (from_east and to_south):
		return "corner_sw"

	return "straight_ns"  # Fallback


## Clear all river tiles
func _clear_river() -> void:
	for pos in _river_tiles:
		var sprite: Sprite2D = _river_tiles[pos]
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	_river_tiles.clear()
	_river_positions.clear()


## Get all river positions (for pathfinding/grid integration)
func get_river_positions() -> Array[Vector2i]:
	return _river_positions.duplicate()


## Check if position is part of river
func is_river_at(pos: Vector2i) -> bool:
	return pos in _river_positions


## Get river tile count
func get_river_tile_count() -> int:
	return _river_tiles.size()


## Hide river tile at position (when block placed on top)
func hide_river_at(grid_pos: Vector2i) -> void:
	if _river_tiles.has(grid_pos):
		var sprite: Sprite2D = _river_tiles[grid_pos]
		if sprite and is_instance_valid(sprite):
			sprite.visible = false


## Show river tile at position (when block removed)
func show_river_at(grid_pos: Vector2i) -> void:
	if _river_tiles.has(grid_pos):
		var sprite: Sprite2D = _river_tiles[grid_pos]
		if sprite and is_instance_valid(sprite):
			sprite.visible = true
