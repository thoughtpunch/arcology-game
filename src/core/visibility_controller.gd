class_name VisibilityController
extends Node

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

signal mode_changed(new_mode: Mode)
signal cut_height_changed(new_height: float)
signal section_plane_changed(normal: Vector3, offset: float)

# Visibility modes
# NORMAL: All blocks visible, CUTAWAY: Hide above cut plane, XRAY: Transparent exteriors
# ISOLATE: Single floor only (future), SECTION: Vertical slice (future)
enum Mode { NORMAL, CUTAWAY, XRAY, ISOLATE, SECTION }

# Cell dimensions (must match BlockRenderer3D) — true cube, 6m all axes
const CELL_SIZE: float = 6.0
const CUBE_HEIGHT: float = CELL_SIZE  # Alias for compatibility

# Cut plane settings
const MIN_CUT_HEIGHT: float = 0.0  # Ground level
const MAX_CUT_HEIGHT: float = 100.0  # ~28 floors
const CUT_HEIGHT_STEP: float = CUBE_HEIGHT  # One floor per step

# Section plane settings
const SECTION_ANGLE_STEP: float = 15.0  # Degrees per rotation step
const SECTION_OFFSET_STEP: float = CELL_SIZE  # World units per scroll step

# Default height (just above ground floor)
const DEFAULT_CUT_HEIGHT: float = CUBE_HEIGHT * 2.0

# Current state
var mode: Mode = Mode.NORMAL
var cut_height: float = DEFAULT_CUT_HEIGHT
var _previous_mode: Mode = Mode.NORMAL

# Section plane state
var section_angle: float = 0.0  # Degrees around Y axis
var section_offset: float = 0.0  # Distance from origin along plane normal

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
			KEY_V:
				# Toggle section mode
				if mode == Mode.SECTION:
					set_mode(Mode.NORMAL)
				else:
					set_mode(Mode.SECTION)
				get_viewport().set_input_as_handled()
			KEY_BRACKETLEFT:
				if mode == Mode.CUTAWAY:
					# Lower cut height (see more floors)
					adjust_cut_height(-CUT_HEIGHT_STEP)
					get_viewport().set_input_as_handled()
				elif mode == Mode.SECTION:
					# Rotate section plane counter-clockwise
					adjust_section_angle(-SECTION_ANGLE_STEP)
					get_viewport().set_input_as_handled()
			KEY_BRACKETRIGHT:
				if mode == Mode.CUTAWAY:
					# Raise cut height (hide more floors)
					adjust_cut_height(CUT_HEIGHT_STEP)
					get_viewport().set_input_as_handled()
				elif mode == Mode.SECTION:
					# Rotate section plane clockwise
					adjust_section_angle(SECTION_ANGLE_STEP)
					get_viewport().set_input_as_handled()

	# Scroll to move section plane along its normal
	if event is InputEventMouseButton and mode == Mode.SECTION:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			adjust_section_offset(SECTION_OFFSET_STEP)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			adjust_section_offset(-SECTION_OFFSET_STEP)
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
		Mode.NORMAL:
			return "Normal"
		Mode.CUTAWAY:
			return "Cutaway"
		Mode.XRAY:
			return "X-Ray"
		Mode.ISOLATE:
			return "Isolate Floor"
		Mode.SECTION:
			return "Section"
		_:
			return "Unknown"


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


## Toggle section mode on/off
func toggle_section() -> void:
	if mode == Mode.SECTION:
		set_mode(_previous_mode if _previous_mode != Mode.SECTION else Mode.NORMAL)
	else:
		set_mode(Mode.SECTION)


## Set the section plane angle (degrees around Y axis)
func set_section_angle(angle_degrees: float) -> void:
	section_angle = fmod(angle_degrees, 360.0)
	if section_angle < 0.0:
		section_angle += 360.0
	_set_shader_globals()
	section_plane_changed.emit(get_section_normal(), section_offset)
	print("Section angle: %.0f deg" % section_angle)


## Adjust section plane angle by delta degrees
func adjust_section_angle(delta_degrees: float) -> void:
	set_section_angle(section_angle + delta_degrees)


## Set the section plane offset (distance from origin along normal)
func set_section_offset(offset: float) -> void:
	section_offset = offset
	_set_shader_globals()
	section_plane_changed.emit(get_section_normal(), section_offset)
	print("Section offset: %.1fm" % section_offset)


## Adjust section plane offset by delta
func adjust_section_offset(delta: float) -> void:
	set_section_offset(section_offset + delta)


## Get the section plane normal vector from the current angle
func get_section_normal() -> Vector3:
	var angle_rad := deg_to_rad(section_angle)
	return Vector3(cos(angle_rad), 0.0, sin(angle_rad))


## Connect to a BlockRenderer3D for direct updates
func connect_to_renderer(renderer: Node3D) -> void:
	_renderer = renderer
	_update_renderer_visibility()


## Check if a world position is visible in current mode
## For SECTION mode, use is_position_visible_3d() which takes full Vector3
func is_position_visible(world_y: float) -> bool:
	match mode:
		Mode.CUTAWAY:
			return world_y <= cut_height
		_:
			return true


## Check if a 3D world position is visible (supports section mode)
func is_position_visible_3d(world_pos: Vector3) -> bool:
	match mode:
		Mode.CUTAWAY:
			return world_pos.y <= cut_height
		Mode.SECTION:
			var normal := get_section_normal()
			var dist := world_pos.dot(normal) - section_offset
			return dist <= 0.0
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
	if mode == Mode.SECTION:
		var normal := get_section_normal()
		RenderingServer.global_shader_parameter_set("section_plane_normal", normal)
		RenderingServer.global_shader_parameter_set("section_plane_offset", section_offset)


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
