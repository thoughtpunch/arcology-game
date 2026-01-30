extends Node
class_name VisibilityController

## Controls visibility modes for the 3D arcology view.
##
## Modes:
## - NORMAL: All blocks visible
## - CUTAWAY: Blocks above cut height are hidden
## - XRAY: Exterior walls transparent (future)
## - ISOLATE: Single floor visible (future)
## - SECTION: Vertical slice (future)
##
## Integrates with BlockRenderer3D via shader global parameters.

# Visibility modes
enum Mode {
	NORMAL,    # All blocks visible
	CUTAWAY,   # Hide blocks above cut plane
	XRAY,      # Transparent exteriors (future)
	ISOLATE,   # Single floor only (future)
	SECTION    # Vertical slice (future)
}

# Signals
signal mode_changed(new_mode: Mode)
signal cut_height_changed(new_height: float)

# Cell dimensions (must match BlockRenderer3D) — true cube, 6m all axes
const CELL_SIZE: float = 6.0
const CUBE_HEIGHT: float = CELL_SIZE  # Alias for compatibility

# Cut plane settings
const MIN_CUT_HEIGHT: float = 0.0  # Ground level
const MAX_CUT_HEIGHT: float = 100.0  # ~28 floors
const CUT_HEIGHT_STEP: float = CUBE_HEIGHT  # One floor per step

# Default height (just above ground floor)
const DEFAULT_CUT_HEIGHT: float = CUBE_HEIGHT * 2.0

# Current state
var mode: Mode = Mode.NORMAL
var cut_height: float = DEFAULT_CUT_HEIGHT
var _previous_mode: Mode = Mode.NORMAL

# Cut plane indicator (optional visual)
var _cut_plane_indicator: MeshInstance3D = null
var _show_cut_plane: bool = true

# Reference to renderer for direct material updates
var _renderer: Node3D = null


func _ready() -> void:
	# Initialize global shader parameters
	_set_shader_globals()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				# Toggle cutaway mode
				if mode == Mode.CUTAWAY:
					set_mode(Mode.NORMAL)
				else:
					set_mode(Mode.CUTAWAY)
				get_viewport().set_input_as_handled()
			KEY_BRACKETLEFT:
				# Lower cut height (see more floors)
				if mode == Mode.CUTAWAY:
					adjust_cut_height(-CUT_HEIGHT_STEP)
					get_viewport().set_input_as_handled()
			KEY_BRACKETRIGHT:
				# Raise cut height (hide more floors)
				if mode == Mode.CUTAWAY:
					adjust_cut_height(CUT_HEIGHT_STEP)
					get_viewport().set_input_as_handled()


## Set the visibility mode
func set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return

	_previous_mode = mode
	mode = new_mode
	_set_shader_globals()
	_update_cut_plane_visibility()
	mode_changed.emit(new_mode)

	var mode_name := get_mode_name(new_mode)
	print("Visibility mode: %s" % mode_name)


## Get the current mode
func get_mode() -> Mode:
	return mode


## Get mode display name
static func get_mode_name(m: Mode) -> String:
	match m:
		Mode.NORMAL: return "Normal"
		Mode.CUTAWAY: return "Cutaway"
		Mode.XRAY: return "X-Ray"
		Mode.ISOLATE: return "Isolate Floor"
		Mode.SECTION: return "Section"
		_: return "Unknown"


## Set the cut plane height (world Y coordinate)
func set_cut_height(new_height: float) -> void:
	var clamped := clampf(new_height, MIN_CUT_HEIGHT, MAX_CUT_HEIGHT)
	if is_equal_approx(cut_height, clamped):
		return

	cut_height = clamped
	_set_shader_globals()
	_update_cut_plane_position()
	cut_height_changed.emit(cut_height)

	var floor_num := get_cut_floor()
	print("Cut height: %.1fm (floor %d)" % [cut_height, floor_num])


## Get the current cut height
func get_cut_height() -> float:
	return cut_height


## Adjust cut height by delta
func adjust_cut_height(delta: float) -> void:
	set_cut_height(cut_height + delta)


## Get the floor number at current cut height
func get_cut_floor() -> int:
	return int(cut_height / CUBE_HEIGHT)


## Set cut height to show a specific floor (and above)
func set_cut_floor(floor_num: int) -> void:
	var height := (floor_num + 1) * CUBE_HEIGHT
	set_cut_height(height)


## Toggle cutaway mode on/off
func toggle_cutaway() -> void:
	if mode == Mode.CUTAWAY:
		set_mode(_previous_mode if _previous_mode != Mode.CUTAWAY else Mode.NORMAL)
	else:
		set_mode(Mode.CUTAWAY)


## Connect to a BlockRenderer3D for direct updates
func connect_to_renderer(renderer: Node3D) -> void:
	_renderer = renderer
	_update_renderer_visibility()


## Check if a world position is visible in current mode
func is_position_visible(world_y: float) -> bool:
	match mode:
		Mode.CUTAWAY:
			return world_y <= cut_height
		_:
			return true


## Check if a grid floor is visible
func is_floor_visible(floor_z: int) -> bool:
	match mode:
		Mode.CUTAWAY:
			var floor_top := (floor_z + 1) * CUBE_HEIGHT
			return floor_top <= cut_height
		_:
			return true


## Get visibility alpha for a world Y position (for shader)
func get_visibility_alpha(world_y: float) -> float:
	match mode:
		Mode.CUTAWAY:
			if world_y > cut_height:
				return 0.0
			return 1.0
		_:
			return 1.0


## Set whether to show the cut plane indicator
func set_show_cut_plane(show: bool) -> void:
	_show_cut_plane = show
	_update_cut_plane_visibility()


## Create and show the cut plane indicator
func show_cut_plane_indicator(parent: Node3D, size: Vector2 = Vector2(200, 200)) -> void:
	if _cut_plane_indicator:
		_cut_plane_indicator.queue_free()

	_cut_plane_indicator = MeshInstance3D.new()
	_cut_plane_indicator.name = "CutPlaneIndicator"

	# Create a thin plane mesh
	var plane := PlaneMesh.new()
	plane.size = size
	_cut_plane_indicator.mesh = plane

	# Create material with transparency
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.7, 1.0, 0.15)  # Light blue, very transparent
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cut_plane_indicator.material_override = mat

	parent.add_child(_cut_plane_indicator)
	_update_cut_plane_position()
	_update_cut_plane_visibility()


## Hide and remove the cut plane indicator
func hide_cut_plane_indicator() -> void:
	if _cut_plane_indicator:
		_cut_plane_indicator.queue_free()
		_cut_plane_indicator = null


## Update global shader parameters
func _set_shader_globals() -> void:
	RenderingServer.global_shader_parameter_set("visibility_mode", mode)
	RenderingServer.global_shader_parameter_set("cut_height", cut_height)


## Update cut plane indicator position
func _update_cut_plane_position() -> void:
	if _cut_plane_indicator:
		_cut_plane_indicator.position.y = cut_height


## Update cut plane indicator visibility
func _update_cut_plane_visibility() -> void:
	if _cut_plane_indicator:
		_cut_plane_indicator.visible = (mode == Mode.CUTAWAY and _show_cut_plane)


## Notify renderer to update visibility (for non-shader approach)
func _update_renderer_visibility() -> void:
	if _renderer and _renderer.has_method("update_cutaway_visibility"):
		_renderer.update_cutaway_visibility(mode, cut_height)
