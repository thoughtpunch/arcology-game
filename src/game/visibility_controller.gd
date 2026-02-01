## Visibility mode controller for block rendering.
##
## Manages visibility modes (cutaway, x-ray, isolate, section) via global
## shader parameters. Call set_mode() to switch modes, and use the adjust_*
## functions to modify mode-specific parameters.
##
## X-ray mode makes exterior surfaces transparent while keeping interiors opaque.
## Panels (exterior faces) are tagged as exterior via their material.

const CELL_SIZE: float = 6.0
const XRAY_OPACITY_MIN: float = 0.0
const XRAY_OPACITY_MAX: float = 0.5
const XRAY_OPACITY_DEFAULT: float = 0.15
const XRAY_OPACITY_STEP: float = 0.05


enum Mode {
	NORMAL,    ## 0 - Full visibility
	CUTAWAY,   ## 1 - Hide geometry above cut plane
	XRAY,      ## 2 - Transparent exterior, opaque interior
	ISOLATE,   ## 3 - Show single floor only
	SECTION,   ## 4 - Vertical section plane
}


## Current visibility mode
var current_mode: Mode = Mode.NORMAL

## Cutaway mode parameters
var cut_floor: int = 5

## X-ray mode parameters
var xray_opacity: float = XRAY_OPACITY_DEFAULT

## Isolate mode parameters
var isolate_floor: int = 0
var isolate_ghost_alpha: float = 0.08

## Section mode parameters
var section_angle: float = 0.0   # Degrees around Y axis
var section_offset: float = 0.0  # Distance from world origin

## Signals
signal mode_changed(new_mode: Mode)
signal xray_opacity_changed(opacity: float)
signal cut_floor_changed(floor_num: int)
signal isolate_floor_changed(floor_num: int)
signal section_changed(angle: float, offset: float)


func _init() -> void:
	# Initialize global shader parameters
	_apply_parameters()


## Set the visibility mode. Emits mode_changed signal.
func set_mode(new_mode: Mode) -> void:
	if current_mode == new_mode:
		return
	current_mode = new_mode
	RenderingServer.global_shader_parameter_set("visibility_mode", int(current_mode))
	_apply_parameters()
	mode_changed.emit(new_mode)


## Toggle to a specific mode, or back to NORMAL if already in that mode.
func toggle_mode(target_mode: Mode) -> void:
	if current_mode == target_mode:
		set_mode(Mode.NORMAL)
	else:
		set_mode(target_mode)


## Cycle through modes: NORMAL -> CUTAWAY -> XRAY -> ISOLATE -> SECTION -> NORMAL
func cycle_mode() -> void:
	var next := (int(current_mode) + 1) % 5
	set_mode(next as Mode)


## Adjust X-ray opacity by delta. Clamped to [XRAY_OPACITY_MIN, XRAY_OPACITY_MAX].
func adjust_xray_opacity(delta: float) -> void:
	xray_opacity = clampf(xray_opacity + delta, XRAY_OPACITY_MIN, XRAY_OPACITY_MAX)
	if current_mode == Mode.XRAY:
		RenderingServer.global_shader_parameter_set("xray_opacity", xray_opacity)
	xray_opacity_changed.emit(xray_opacity)


## Set X-ray opacity directly. Clamped to valid range.
func set_xray_opacity(value: float) -> void:
	xray_opacity = clampf(value, XRAY_OPACITY_MIN, XRAY_OPACITY_MAX)
	if current_mode == Mode.XRAY:
		RenderingServer.global_shader_parameter_set("xray_opacity", xray_opacity)
	xray_opacity_changed.emit(xray_opacity)


## Adjust cutaway floor by delta. Clamped to >= 0.
func adjust_cut_floor(delta: int) -> void:
	cut_floor = maxi(cut_floor + delta, 0)
	if current_mode == Mode.CUTAWAY:
		var cut_y := float(cut_floor + 1) * CELL_SIZE
		RenderingServer.global_shader_parameter_set("cut_height", cut_y)
	cut_floor_changed.emit(cut_floor)


## Set cutaway floor directly.
func set_cut_floor(floor_num: int) -> void:
	cut_floor = maxi(floor_num, 0)
	if current_mode == Mode.CUTAWAY:
		var cut_y := float(cut_floor + 1) * CELL_SIZE
		RenderingServer.global_shader_parameter_set("cut_height", cut_y)
	cut_floor_changed.emit(cut_floor)


## Adjust isolate floor by delta. Clamped to >= 0.
func adjust_isolate_floor(delta: int) -> void:
	isolate_floor = maxi(isolate_floor + delta, 0)
	if current_mode == Mode.ISOLATE:
		_apply_isolate_params()
	isolate_floor_changed.emit(isolate_floor)


## Set isolate floor directly.
func set_isolate_floor(floor_num: int) -> void:
	isolate_floor = maxi(floor_num, 0)
	if current_mode == Mode.ISOLATE:
		_apply_isolate_params()
	isolate_floor_changed.emit(isolate_floor)


## Adjust section plane angle by delta degrees.
func adjust_section_angle(delta: float) -> void:
	section_angle = fmod(section_angle + delta, 360.0)
	if section_angle < 0.0:
		section_angle += 360.0
	if current_mode == Mode.SECTION:
		_apply_section_params()
	section_changed.emit(section_angle, section_offset)


## Adjust section plane offset by delta.
func adjust_section_offset(delta: float) -> void:
	section_offset += delta
	if current_mode == Mode.SECTION:
		_apply_section_params()
	section_changed.emit(section_angle, section_offset)


## Get mode name for display.
static func get_mode_name(mode: Mode) -> String:
	match mode:
		Mode.NORMAL:
			return "Normal"
		Mode.CUTAWAY:
			return "Cutaway"
		Mode.XRAY:
			return "X-Ray"
		Mode.ISOLATE:
			return "Isolate"
		Mode.SECTION:
			return "Section"
		_:
			return "Unknown"


## Get display string for current mode and parameters.
func get_status_string() -> String:
	match current_mode:
		Mode.NORMAL:
			return ""
		Mode.CUTAWAY:
			return "CUTAWAY  Floor %d  [E/C adjust]" % cut_floor
		Mode.XRAY:
			return "X-RAY  Opacity: %d%%  [scroll adjust]" % int(xray_opacity * 100.0 / XRAY_OPACITY_MAX)
		Mode.ISOLATE:
			return "ISOLATE  Floor %d  [E/C adjust]" % isolate_floor
		Mode.SECTION:
			return "SECTION  Angle: %d°  [scroll rotate]" % int(section_angle)
		_:
			return ""


func _apply_parameters() -> void:
	match current_mode:
		Mode.NORMAL:
			# No special params needed
			pass
		Mode.CUTAWAY:
			var cut_y := float(cut_floor + 1) * CELL_SIZE
			RenderingServer.global_shader_parameter_set("cut_height", cut_y)
		Mode.XRAY:
			RenderingServer.global_shader_parameter_set("xray_opacity", xray_opacity)
		Mode.ISOLATE:
			_apply_isolate_params()
		Mode.SECTION:
			_apply_section_params()


func _apply_isolate_params() -> void:
	var floor_y := float(isolate_floor) * CELL_SIZE
	RenderingServer.global_shader_parameter_set("isolate_floor_y", floor_y)
	RenderingServer.global_shader_parameter_set("isolate_floor_top", floor_y + CELL_SIZE)
	RenderingServer.global_shader_parameter_set("isolate_ghost_alpha", isolate_ghost_alpha)


func _apply_section_params() -> void:
	var rad := deg_to_rad(section_angle)
	var normal := Vector3(cos(rad), 0.0, sin(rad))
	RenderingServer.global_shader_parameter_set("section_plane_normal", normal)
	RenderingServer.global_shader_parameter_set("section_plane_offset", section_offset)
