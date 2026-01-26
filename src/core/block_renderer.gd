class_name BlockRenderer
extends Node2D
## Renders blocks with isometric positioning and depth sorting
## Listens to Grid signals to add/remove block sprites
## Handles floor-based visibility (cutaway view)

signal view_mode_changed(show_all_floors: bool)

# References
var grid: Grid
var _sprites: Dictionary = {}  # Vector3i -> Sprite2D

# Preloaded textures cache
var _texture_cache: Dictionary = {}

# Audio
var _place_sound: AudioStreamPlayer

# Floor visibility settings
const FLOORS_BELOW_VISIBLE: int = 2
const OPACITY_FALLOFF: float = 0.3  # Opacity reduction per floor below

# Visibility mode
var show_all_floors: bool = false  # When true, show entire structure


func _ready() -> void:
	# Enable Y-sorting for proper isometric depth
	y_sort_enabled = true

	# Setup audio player for placement sounds
	_place_sound = AudioStreamPlayer.new()
	_place_sound.name = "PlaceSound"
	_place_sound.volume_db = -6.0  # Slightly quieter than full volume
	add_child(_place_sound)

	# Try to load placement sound effect
	var sound_path := "res://assets/audio/sfx/place_block.wav"
	if ResourceLoader.exists(sound_path):
		_place_sound.stream = load(sound_path)
	else:
		# Generate a simple procedural "chunk" sound as placeholder
		_place_sound.stream = _generate_place_sound()


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
	# Play placement animation
	_animate_block_placement(pos)


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

	# Show all floors mode - everything visible at full opacity
	if show_all_floors:
		sprite.visible = true
		sprite.modulate = Color(base_color.r, base_color.g, base_color.b, 1.0)
		return

	# Cutaway mode - hide floors above, fade floors below
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


## Toggle between showing all floors and cutaway view
func toggle_show_all_floors() -> void:
	show_all_floors = not show_all_floors
	# Refresh visibility for all sprites
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	var current_floor: int = game_state.current_floor if game_state else 0
	update_visibility(current_floor)
	view_mode_changed.emit(show_all_floors)


## Set show all floors mode
func set_show_all_floors(enabled: bool) -> void:
	if show_all_floors != enabled:
		show_all_floors = enabled
		var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
		var current_floor: int = game_state.current_floor if game_state else 0
		update_visibility(current_floor)
		view_mode_changed.emit(show_all_floors)


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


## Generate a simple procedural "chunk" sound as placeholder
func _generate_place_sound() -> AudioStream:
	# Create a short percussive sound programmatically
	# This is a placeholder until real audio is added
	var sample_rate := 22050
	var duration := 0.15  # 150ms
	var num_samples := int(sample_rate * duration)

	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data := PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / sample_rate
		# Quick attack, fast decay noise burst (like a "chunk")
		var envelope := exp(-t * 30.0)  # Fast decay
		var noise := randf_range(-1.0, 1.0)
		var low_freq := sin(t * 150.0 * TAU)  # Low thump
		var sample := (noise * 0.3 + low_freq * 0.7) * envelope
		# Convert to 8-bit unsigned (0-255, with 128 as center)
		data[i] = int(clamp(sample * 127.0 + 128.0, 0, 255))

	audio.data = data
	return audio


## Play the block placement sound
func _play_place_sound() -> void:
	if _place_sound and _place_sound.stream:
		# Slight pitch variation for variety
		_place_sound.pitch_scale = randf_range(0.9, 1.1)
		_place_sound.play()


## Animate a block being placed with a satisfying heavy "plop"
## Enhanced for heavy prefab module feel
func _animate_block_placement(pos: Vector3i) -> void:
	if not _sprites.has(pos):
		return

	var sprite: Sprite2D = _sprites[pos]
	var final_pos: Vector2 = sprite.position

	# Play the "chunk" sound
	_play_place_sound()

	# Animation constants for heavy feel
	const DROP_HEIGHT := 35.0  # Pixels to drop (increased for weight)
	const DROP_DURATION := 0.14  # Seconds for drop phase
	const BOUNCE_DURATION := 0.14  # Seconds for settle phase
	const IMPACT_OVERSHOOT := 4.0  # Pixels past final position
	const INITIAL_ROTATION := 3.0  # Degrees of initial tilt
	const SQUASH_X := 0.88  # Horizontal squash on impact
	const SQUASH_Y := 1.12  # Vertical stretch on impact

	# Start above final position, slightly larger, with rotation
	sprite.position = final_pos + Vector2(0, -DROP_HEIGHT)
	sprite.scale = Vector2(1.1, 1.1)
	sprite.modulate.a = 0.7
	sprite.rotation_degrees = randf_range(-INITIAL_ROTATION, INITIAL_ROTATION)

	# Create tween for the heavy "plop" animation
	var tween := create_tween()
	tween.set_parallel(true)

	# Phase 1: Drop with acceleration (ease in = accelerate)
	tween.tween_property(sprite, "position", final_pos + Vector2(0, IMPACT_OVERSHOOT), DROP_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", Vector2(SQUASH_X, SQUASH_Y), DROP_DURATION).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 1.0, DROP_DURATION * 0.6)
	tween.tween_property(sprite, "rotation_degrees", 0.0, DROP_DURATION).set_ease(Tween.EASE_OUT)

	# Phase 2: Bounce back and settle (ease out = decelerate)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position", final_pos, BOUNCE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), BOUNCE_DURATION).set_ease(Tween.EASE_OUT)


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
