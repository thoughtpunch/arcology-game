class_name InputHandler
extends Node
## Handles mouse input for block placement and removal
## Manages ghost preview and validates placement
## Supports Shift+click auto-stacking on top of existing blocks

signal block_placement_attempted(pos: Vector3i, type: String, success: bool)
signal block_removal_attempted(pos: Vector3i, success: bool)
signal selection_changed(block_type: String)
signal block_selected(pos: Vector3i, block_type: String)

# Mode
enum Mode { BUILD, SELECT, DEMOLISH }

# Ghost modulation colors
const VALID_COLOR := Color(1.0, 1.0, 1.0, 0.6)  # Semi-transparent white
const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.6)  # Semi-transparent red

# Placement cooldown to prevent rapid-fire and make placements feel weighty
const PLACEMENT_COOLDOWN := 0.15  # seconds

# Label styling
const FLOOR_LABEL_OFFSET := Vector2(40, -20)  # Offset from ghost sprite
const COST_LABEL_OFFSET := Vector2(40, 0)  # Below floor label

# References (must be set before use)
var grid: Grid
var camera: Camera2D
var ghost_container: Node2D  # Parent node for ghost sprite

# State
var selected_block_type: String = "corridor"
var current_mode := Mode.BUILD
var block_renderer = null  # Set by main.gd during setup
var construction_queue = null  # Set by main.gd during setup

var _ghost_sprite: Sprite2D
var _floor_label: Label  # Shows Z level near ghost
var _cost_label: Label  # Shows cost near ghost
var _texture_cache: Dictionary = {}
var _last_placement_time := 0.0
var _ready_logged := false


func _ready() -> void:
	_create_ghost_sprite()
	_create_floor_label()
	_create_cost_label()


## Initialize with required references
func setup(p_grid: Grid, p_camera: Camera2D, p_ghost_container: Node2D) -> void:
	grid = p_grid
	camera = p_camera
	ghost_container = p_ghost_container

	if _ghost_sprite and ghost_container:
		# Reparent ghost sprite to container
		if _ghost_sprite.get_parent():
			_ghost_sprite.get_parent().remove_child(_ghost_sprite)
		ghost_container.add_child(_ghost_sprite)
		_update_ghost_texture()

	if _floor_label and ghost_container:
		# Reparent floor label to container
		if _floor_label.get_parent():
			_floor_label.get_parent().remove_child(_floor_label)
		ghost_container.add_child(_floor_label)

	if _cost_label and ghost_container:
		# Reparent cost label to container
		if _cost_label.get_parent():
			_cost_label.get_parent().remove_child(_cost_label)
		ghost_container.add_child(_cost_label)
		_update_cost_label()


func _create_ghost_sprite() -> void:
	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.modulate = VALID_COLOR
	_ghost_sprite.z_index = 1000  # Always on top
	_ghost_sprite.visible = false
	add_child(_ghost_sprite)  # Temporary parent until setup() called


func _create_floor_label() -> void:
	_floor_label = Label.new()
	_floor_label.text = "Z: 0"
	_floor_label.z_index = 1001  # Above ghost
	_floor_label.visible = false
	_floor_label.add_theme_color_override("font_color", Color.WHITE)
	_floor_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_floor_label.add_theme_constant_override("shadow_offset_x", 1)
	_floor_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_floor_label)  # Temporary parent until setup() called


func _create_cost_label() -> void:
	_cost_label = Label.new()
	_cost_label.text = "$0"
	_cost_label.z_index = 1001  # Above ghost
	_cost_label.visible = false
	_cost_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_cost_label.add_theme_constant_override("shadow_offset_x", 1)
	_cost_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_cost_label)  # Temporary parent until setup() called


func _process(_delta: float) -> void:
	if not _is_ready():
		if not _ready_logged:
			print(
				(
					"InputHandler waiting for setup... grid=%s camera=%s ghost=%s"
					% [grid != null, camera != null, ghost_container != null]
				)
			)
		return
	if not _ready_logged:
		print("InputHandler ready!")
		_ready_logged = true
	_update_ghost_position()


func _unhandled_input(event: InputEvent) -> void:
	# This handles input when NO full-screen HUD is present
	# With full HUD, clicks come through handle_viewport_click() instead
	if not _is_ready():
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if not event.pressed:
		return

	var grid_pos := _get_grid_pos_at_mouse()

	if event.button_index == MOUSE_BUTTON_LEFT:
		match current_mode:
			Mode.BUILD:
				# Only auto-stack if position is occupied AND we're in "show all floors" mode
				# Otherwise, reject placement on occupied positions (build on current floor only)
				if grid.has_block(grid_pos):
					# Check if BlockRenderer is in show_all_floors mode
					if block_renderer and block_renderer.show_all_floors:
						grid_pos = _get_auto_stack_position(grid_pos)
					else:
						# In cutaway mode, don't allow building on occupied positions
						block_placement_attempted.emit(grid_pos, selected_block_type, false)
						return
				_try_place_block(grid_pos)
			Mode.SELECT:
				_try_select_block(grid_pos)
			Mode.DEMOLISH:
				_try_remove_block(grid_pos)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_try_remove_block(grid_pos)


func set_block_renderer(renderer) -> void:
	block_renderer = renderer


func set_construction_queue(queue) -> void:
	construction_queue = queue


## Attempt to place a block at the given grid position
func _try_place_block(pos: Vector3i) -> void:
	# Check cooldown to prevent rapid-fire placement
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_placement_time < PLACEMENT_COOLDOWN:
		return  # Still in cooldown, ignore

	# Validate placement - check for existing block
	if grid.has_block(pos):
		block_placement_attempted.emit(pos, selected_block_type, false)
		return

	# Validate placement - check for active construction
	if construction_queue and construction_queue.has_construction(pos):
		block_placement_attempted.emit(pos, selected_block_type, false)
		return

	# Check ground_only constraint for entrance blocks
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and pos.z != 0:
		block_placement_attempted.emit(pos, selected_block_type, false)
		return

	# TODO: Check and deduct cost from player funds
	# var cost: int = block_data.get("cost", 0)
	# if not GameState.can_afford(cost):
	#     block_placement_attempted.emit(pos, selected_block_type, false)
	#     return
	# GameState.spend(cost)

	# Start construction (or place instantly if no queue or instant mode)
	var success := false
	if construction_queue:
		success = construction_queue.start_construction(pos, selected_block_type)
	else:
		# Fallback: instant placement (for testing or if no queue)
		var block := Block.new(selected_block_type, pos)
		grid.set_block(pos, block)
		success = true

	_last_placement_time = current_time
	block_placement_attempted.emit(pos, selected_block_type, success)


## Attempt to remove a block at the given grid position
func _try_remove_block(pos: Vector3i) -> void:
	if not grid.has_block(pos):
		block_removal_attempted.emit(pos, false)
		return

	grid.remove_block(pos)
	block_removal_attempted.emit(pos, true)


## Attempt to select a block at the given grid position
func _try_select_block(pos: Vector3i) -> void:
	if not grid.has_block(pos):
		return

	var block = grid.get_block_at(pos)
	if block:
		var block_type: String = (
			block.block_type if block is Block else block.get("block_type", "unknown")
		)
		block_selected.emit(pos, block_type)


## Update ghost sprite position to follow mouse
func _update_ghost_position() -> void:
	var grid_pos := _get_grid_pos_at_mouse()

	# Check for Shift key - show auto-stack position preview
	var display_pos := grid_pos
	var is_shift_held := Input.is_key_pressed(KEY_SHIFT)
	if is_shift_held:
		display_pos = _get_auto_stack_position(grid_pos)

	# Position ghost at grid cell
	_ghost_sprite.position = grid.grid_to_screen(display_pos)
	_ghost_sprite.visible = true

	# Update floor label position and text
	_floor_label.position = _ghost_sprite.position + FLOOR_LABEL_OFFSET
	_floor_label.text = "Z: %d" % display_pos.z
	if is_shift_held:
		_floor_label.text += " (auto)"
	_floor_label.visible = true

	# Update cost label position
	_cost_label.position = _ghost_sprite.position + COST_LABEL_OFFSET
	_cost_label.visible = true

	# Update color based on validity (includes affordability check)
	var is_valid := _is_placement_valid(display_pos)
	_ghost_sprite.modulate = VALID_COLOR if is_valid else INVALID_COLOR


## Check if placement would be valid at this position
func _is_placement_valid(pos: Vector3i) -> bool:
	# Can't place on occupied cell
	if grid.has_block(pos):
		return false

	# Can't place where construction is active
	if construction_queue and construction_queue.has_construction(pos):
		return false

	# Check ground_only constraint
	var block_data := _get_block_data(selected_block_type)
	if block_data.get("ground_only", false) and pos.z != 0:
		return false

	return true


## Get the grid position under the mouse cursor
func _get_grid_pos_at_mouse() -> Vector3i:
	var mouse_pos := get_viewport().get_mouse_position()

	# Convert screen position to world position (accounting for camera transform)
	var world_pos := camera.get_canvas_transform().affine_inverse() * mouse_pos

	# Get current floor from GameState
	var current_floor := _get_current_floor()

	# Convert to grid
	return grid.screen_to_grid(world_pos, current_floor)


## Get the auto-stack position for a given base position
## Returns position on top of highest block at that X,Y column, or Z=0 if empty
func _get_auto_stack_position(base_pos: Vector3i) -> Vector3i:
	var highest_z := grid.get_highest_z_at(base_pos.x, base_pos.y)
	var target_z: int
	if highest_z < 0:
		# No blocks at this column, place at Z=0
		target_z = 0
	else:
		# Place on top of highest block
		target_z = highest_z + 1

	# Clamp to max floor (if GameState available)
	var tree := get_tree()
	if tree:
		var game_state = tree.get_root().get_node_or_null("/root/GameState")
		if game_state:
			target_z = mini(target_z, game_state.MAX_FLOOR)

	return Vector3i(base_pos.x, base_pos.y, target_z)


## Get current floor from GameState autoload
func _get_current_floor() -> int:
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	if game_state:
		return game_state.current_floor
	return 0


## Check if all required references are set
func _is_ready() -> bool:
	return grid != null and camera != null and ghost_container != null


## Change the currently selected block type
func set_selected_block_type(type: String) -> void:
	if selected_block_type != type:
		selected_block_type = type
		_update_ghost_texture()
		_update_cost_label()
		selection_changed.emit(type)


## Update ghost sprite texture to match selected block type
func _update_ghost_texture() -> void:
	if _ghost_sprite == null:
		return

	var texture := _get_block_texture(selected_block_type)
	if texture:
		_ghost_sprite.texture = texture


## Update cost label to show selected block's cost
func _update_cost_label() -> void:
	if _cost_label == null:
		return

	var block_data := _get_block_data(selected_block_type)
	var cost: int = block_data.get("cost", 0)

	# Format cost
	_cost_label.text = _format_cost(cost)

	# Color based on affordability (green if affordable, red if not)
	var game_state = get_tree().get_root().get_node_or_null("/root/GameState")
	var can_afford := true
	if game_state and game_state.has_method("can_afford"):
		can_afford = game_state.can_afford(cost)

	if can_afford:
		_cost_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))  # Green
	else:
		_cost_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))  # Red


## Format cost for display
func _format_cost(cost: int) -> String:
	if cost >= 1000:
		return "$%.1fK" % (cost / 1000.0)
	return "$%d" % cost


## Get texture for a block type, with caching
func _get_block_texture(block_type: String) -> Texture2D:
	if _texture_cache.has(block_type):
		return _texture_cache[block_type]

	var block_data := _get_block_data(block_type)
	var sprite_path: String = block_data.get("sprite", "")

	if sprite_path.is_empty():
		return null

	var texture = load(sprite_path)
	if texture:
		_texture_cache[block_type] = texture
	return texture


## Get block data from BlockRegistry
func _get_block_data(block_type: String) -> Dictionary:
	var registry = get_tree().get_root().get_node_or_null("/root/BlockRegistry")
	if registry == null:
		return {}
	return registry.get_block_data(block_type)


## Handle a click forwarded from the HUD viewport area
func handle_viewport_click(event: InputEventMouseButton) -> void:
	if not _is_ready():
		return
	_handle_mouse_button(event)


## Set input mode
func set_mode(mode: Mode) -> void:
	current_mode = mode
	# Update ghost visibility based on mode
	if _ghost_sprite:
		_ghost_sprite.visible = (mode == Mode.BUILD)
	if _floor_label:
		_floor_label.visible = (mode == Mode.BUILD)
	if _cost_label:
		_cost_label.visible = (mode == Mode.BUILD)


## Get current mode
func get_mode() -> Mode:
	return current_mode
