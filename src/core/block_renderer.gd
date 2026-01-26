class_name BlockRenderer
extends Node2D
## Renders blocks with isometric positioning and depth sorting
## Listens to Grid signals to add/remove block sprites
## Handles floor-based visibility (cutaway view)

# References
var grid: Grid
var _sprites: Dictionary = {}  # Vector3i -> Sprite2D

# Preloaded textures cache
var _texture_cache: Dictionary = {}

# Floor visibility settings
const FLOORS_BELOW_VISIBLE: int = 2
const OPACITY_FALLOFF: float = 0.3  # Opacity reduction per floor below


func _ready() -> void:
	# Enable Y-sorting for proper isometric depth
	y_sort_enabled = true


## Connect to a grid to render its blocks
func connect_to_grid(new_grid: Grid) -> void:
	if grid:
		# Disconnect from old grid
		grid.block_added.disconnect(_on_block_added)
		grid.block_removed.disconnect(_on_block_removed)
		if grid.has_signal("connectivity_changed"):
			grid.connectivity_changed.disconnect(_on_connectivity_changed)
		_clear_all_sprites()

	grid = new_grid
	grid.block_added.connect(_on_block_added)
	grid.block_removed.connect(_on_block_removed)
	if grid.has_signal("connectivity_changed"):
		grid.connectivity_changed.connect(_on_connectivity_changed)

	# Render existing blocks
	for block in grid.get_all_blocks():
		_create_sprite_for_block(block)


## Create a sprite for a block and position it correctly
func _create_sprite_for_block(block) -> void:
	var pos: Vector3i = block.grid_position

	# Get sprite texture from BlockRegistry
	var texture := _get_block_texture(block.block_type)
	if texture == null:
		push_warning("BlockRenderer: No texture for block type '%s'" % block.block_type)
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture

	# Position using isometric conversion
	sprite.position = grid.grid_to_screen(pos)

	# Z-index for floor stacking (higher Z = in front)
	# Also factor in X+Y for proper Y-sorting within a floor
	sprite.z_index = _calculate_z_index(pos)

	# Sprite origin is center by default, which works for our hexagonal sprites
	# The sprite center aligns with the grid position

	add_child(sprite)
	_sprites[pos] = sprite

	# Store sprite reference on block for later updates
	block.sprite = sprite


## Remove a sprite for a block position
func _remove_sprite_at(pos: Vector3i) -> void:
	if _sprites.has(pos):
		var sprite: Sprite2D = _sprites[pos]
		sprite.queue_free()
		_sprites.erase(pos)


## Clear all sprites
func _clear_all_sprites() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()


## Get texture for a block type, with caching
func _get_block_texture(block_type: String) -> Texture2D:
	if _texture_cache.has(block_type):
		return _texture_cache[block_type]

	# Get sprite path from BlockRegistry
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		return null

	var block_data: Dictionary = registry.get_block_data(block_type)
	var sprite_path: String = block_data.get("sprite", "")

	if sprite_path.is_empty():
		return null

	var texture = load(sprite_path)
	if texture:
		_texture_cache[block_type] = texture
	return texture


## Calculate z_index for proper depth sorting
## Higher Z (floors) should render in front
## Within a floor, higher Y should render behind (smaller z_index)
func _calculate_z_index(pos: Vector3i) -> int:
	# Floor stacking: multiply Z by a large number to ensure floors don't overlap
	# Within a floor: use X + Y for isometric depth (larger = more in front)
	return pos.x + pos.y + pos.z * 100


## Update a single sprite's position (for when blocks move)
func update_sprite_position(pos: Vector3i) -> void:
	if _sprites.has(pos):
		var sprite: Sprite2D = _sprites[pos]
		sprite.position = grid.grid_to_screen(pos)
		sprite.z_index = _calculate_z_index(pos)


# Signal handlers
func _on_block_added(pos: Vector3i, block) -> void:
	_create_sprite_for_block(block)
	# Apply visibility for newly added block
	_apply_visibility_to_sprite(pos)


func _on_block_removed(pos: Vector3i) -> void:
	_remove_sprite_at(pos)


## Update visibility for all blocks based on current floor
## Call this when floor changes or after initial setup
func update_visibility(current_floor: int) -> void:
	for pos in _sprites.keys():
		_update_sprite_visibility(pos, current_floor)


## Update visibility for a single sprite
func _update_sprite_visibility(pos: Vector3i, current_floor: int) -> void:
	if not _sprites.has(pos):
		return

	var sprite: Sprite2D = _sprites[pos]
	var block = grid.get_block(pos) if grid else null

	# Determine base color (connected = white, disconnected = red tint)
	var base_color := CONNECTED_TINT
	if block and not block.connected:
		base_color = DISCONNECTED_TINT

	if pos.z > current_floor:
		# Above current floor - hide completely
		sprite.visible = false
	elif pos.z == current_floor:
		# Current floor - full opacity
		sprite.visible = true
		sprite.modulate = Color(base_color.r, base_color.g, base_color.b, 1.0)
	elif pos.z >= current_floor - FLOORS_BELOW_VISIBLE:
		# Below but within visible range - fade based on depth
		sprite.visible = true
		var depth: int = current_floor - pos.z
		var alpha := 1.0 - (depth * OPACITY_FALLOFF)
		sprite.modulate = Color(base_color.r, base_color.g, base_color.b, alpha)
	else:
		# Too far below - hide completely
		sprite.visible = false


## Apply visibility to a single sprite based on current GameState floor
func _apply_visibility_to_sprite(pos: Vector3i) -> void:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		_update_sprite_visibility(pos, game_state.current_floor)


# --- Connectivity Visual Feedback ---

# Color for disconnected blocks (red tint)
const DISCONNECTED_TINT := Color(1.0, 0.5, 0.5)
const CONNECTED_TINT := Color.WHITE


## Update connectivity visuals for all blocks
func _on_connectivity_changed() -> void:
	for pos in _sprites.keys():
		var block = grid.get_block(pos)
		if block:
			_update_connectivity_visual(block)


## Update connectivity visual for a single block
func _update_connectivity_visual(block) -> void:
	if not block.sprite:
		return

	# Get current alpha (from floor visibility)
	var current_alpha: float = block.sprite.modulate.a

	if block.connected:
		block.sprite.modulate = Color(CONNECTED_TINT.r, CONNECTED_TINT.g, CONNECTED_TINT.b, current_alpha)
	else:
		block.sprite.modulate = Color(DISCONNECTED_TINT.r, DISCONNECTED_TINT.g, DISCONNECTED_TINT.b, current_alpha)
