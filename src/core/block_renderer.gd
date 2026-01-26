class_name BlockRenderer
extends Node2D
## Renders blocks with isometric positioning and depth sorting
## Listens to Grid signals to add/remove block sprites

# References
var grid: Grid
var _sprites: Dictionary = {}  # Vector3i -> Sprite2D

# Preloaded textures cache
var _texture_cache: Dictionary = {}


func _ready() -> void:
	# Enable Y-sorting for proper isometric depth
	y_sort_enabled = true


## Connect to a grid to render its blocks
func connect_to_grid(new_grid: Grid) -> void:
	if grid:
		# Disconnect from old grid
		grid.block_added.disconnect(_on_block_added)
		grid.block_removed.disconnect(_on_block_removed)
		_clear_all_sprites()

	grid = new_grid
	grid.block_added.connect(_on_block_added)
	grid.block_removed.connect(_on_block_removed)

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


func _on_block_removed(pos: Vector3i) -> void:
	_remove_sprite_at(pos)
