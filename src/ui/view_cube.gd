class_name ViewCube
extends Control
## View Cube widget for quick camera view switching.
##
## Displays a 3D cube in a SubViewport that mirrors the main camera's rotation.
## Click faces to snap to orthographic views, click edges for 45-degree views,
## click corners for isometric, drag to free-rotate, double-click for free camera.
##
## Place in top-right corner of the screen. Connect to an orbital camera via
## connect_to_camera().

# --- Signals ---
signal view_snapped(azimuth: float, elevation: float)
signal free_camera_requested
signal drag_rotate(delta_azimuth: float, delta_elevation: float)

# --- Constants ---
const WIDGET_SIZE := 150  # Pixels for the viewport
const CUBE_HALF := 0.9  # Half-size of the cube mesh (slightly less than 1.0 for label margins)
const CUBE_CAMERA_DISTANCE := 3.5  # Camera distance from cube center
const DRAG_THRESHOLD := 3.0  # Pixels before click becomes drag
const DOUBLE_CLICK_TIME := 0.4  # Seconds between clicks for double-click
const DRAG_SENSITIVITY := 0.4  # Degrees per pixel of drag

# View angle presets: [azimuth, elevation]
# Azimuth: 0=front(south), 90=right(east), 180=back(north), 270=left(west)
# These match the orbital camera convention
const VIEW_TOP := Vector2(0.0, 89.0)
const VIEW_BOTTOM := Vector2(0.0, -89.0)
const VIEW_FRONT := Vector2(0.0, 0.0)  # South face, looking north
const VIEW_BACK := Vector2(180.0, 0.0)  # North face, looking south
const VIEW_RIGHT := Vector2(90.0, 0.0)  # East
const VIEW_LEFT := Vector2(270.0, 0.0)  # West (same as -90)

# Color palette (matches existing UI dark theme)
const COLOR_CUBE_BG := Color("#1a1a2e")
const COLOR_CUBE_FACE := Color("#2a2a4e")
const COLOR_CUBE_FACE_HOVER := Color("#3a3a6e")
const COLOR_CUBE_EDGE := Color("#0f3460")
const COLOR_CUBE_LABEL := Color("#ffffff")
const COLOR_ACTIVE_FACE := Color("#e94560")
const COLOR_WIDGET_BG := Color(0.1, 0.1, 0.15, 0.6)

# --- Face/Edge/Corner IDs for hit detection ---
# Faces are identified by their normal direction
enum HitZone {
	NONE,
	# Faces
	FACE_TOP, FACE_BOTTOM, FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT,
	# Edges (between two faces)
	EDGE_TOP_FRONT, EDGE_TOP_BACK, EDGE_TOP_RIGHT, EDGE_TOP_LEFT,
	EDGE_BOTTOM_FRONT, EDGE_BOTTOM_BACK, EDGE_BOTTOM_RIGHT, EDGE_BOTTOM_LEFT,
	EDGE_FRONT_RIGHT, EDGE_FRONT_LEFT, EDGE_BACK_RIGHT, EDGE_BACK_LEFT,
	# Corners (between three faces)
	CORNER_TOP_FRONT_RIGHT, CORNER_TOP_FRONT_LEFT,
	CORNER_TOP_BACK_RIGHT, CORNER_TOP_BACK_LEFT,
	CORNER_BOTTOM_FRONT_RIGHT, CORNER_BOTTOM_FRONT_LEFT,
	CORNER_BOTTOM_BACK_RIGHT, CORNER_BOTTOM_BACK_LEFT,
}

# Map HitZone -> [azimuth, elevation] for snap views
var _hit_zone_angles: Dictionary = {}

# --- Node references ---
var _sub_viewport: SubViewport
var _cube_camera: Camera3D
var _cube_root: Node3D  # Parent of the cube mesh, rotated to match main camera
var _cube_mesh: MeshInstance3D
var _face_labels: Dictionary = {}  # face_name -> MeshInstance3D (label quads)
var _edge_lines: Array[MeshInstance3D] = []
var _texture_rect: TextureRect  # Displays the SubViewport
var _bg_panel: ColorRect

# --- Camera reference ---
var _main_camera: Node3D = null  # The orbital camera to mirror

# --- Interaction state ---
var _hovered_zone: int = HitZone.NONE
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _mouse_press_pos: Vector2 = Vector2.ZERO
var _mouse_pressed: bool = false
var _last_click_time: float = 0.0
var _last_click_zone: int = HitZone.NONE

# --- Face materials (for hover highlighting) ---
var _face_materials: Dictionary = {}  # HitZone -> StandardMaterial3D
var _label_materials: Dictionary = {}  # face_name -> StandardMaterial3D


func _ready() -> void:
	initialize()


func initialize() -> void:
	## Build the widget. Called automatically from _ready(), or manually in tests.
	if _sub_viewport != null:
		return  # Already initialized
	_init_hit_zone_angles()
	_setup_widget()
	_setup_sub_viewport()
	_setup_cube()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _init_hit_zone_angles() -> void:
	# Faces
	_hit_zone_angles[HitZone.FACE_TOP] = VIEW_TOP
	_hit_zone_angles[HitZone.FACE_BOTTOM] = VIEW_BOTTOM
	_hit_zone_angles[HitZone.FACE_FRONT] = VIEW_FRONT
	_hit_zone_angles[HitZone.FACE_BACK] = VIEW_BACK
	_hit_zone_angles[HitZone.FACE_RIGHT] = VIEW_RIGHT
	_hit_zone_angles[HitZone.FACE_LEFT] = VIEW_LEFT

	# Edges (midpoints between two faces)
	_hit_zone_angles[HitZone.EDGE_TOP_FRONT] = Vector2(0.0, 45.0)
	_hit_zone_angles[HitZone.EDGE_TOP_BACK] = Vector2(180.0, 45.0)
	_hit_zone_angles[HitZone.EDGE_TOP_RIGHT] = Vector2(90.0, 45.0)
	_hit_zone_angles[HitZone.EDGE_TOP_LEFT] = Vector2(270.0, 45.0)
	_hit_zone_angles[HitZone.EDGE_BOTTOM_FRONT] = Vector2(0.0, -45.0)
	_hit_zone_angles[HitZone.EDGE_BOTTOM_BACK] = Vector2(180.0, -45.0)
	_hit_zone_angles[HitZone.EDGE_BOTTOM_RIGHT] = Vector2(90.0, -45.0)
	_hit_zone_angles[HitZone.EDGE_BOTTOM_LEFT] = Vector2(270.0, -45.0)
	_hit_zone_angles[HitZone.EDGE_FRONT_RIGHT] = Vector2(45.0, 0.0)
	_hit_zone_angles[HitZone.EDGE_FRONT_LEFT] = Vector2(315.0, 0.0)
	_hit_zone_angles[HitZone.EDGE_BACK_RIGHT] = Vector2(135.0, 0.0)
	_hit_zone_angles[HitZone.EDGE_BACK_LEFT] = Vector2(225.0, 0.0)

	# Corners (isometric-like, 45° azimuth + ~35° elevation)
	var iso_el := 35.264  # arctan(1/sqrt(2)) — true isometric elevation
	_hit_zone_angles[HitZone.CORNER_TOP_FRONT_RIGHT] = Vector2(45.0, iso_el)
	_hit_zone_angles[HitZone.CORNER_TOP_FRONT_LEFT] = Vector2(315.0, iso_el)
	_hit_zone_angles[HitZone.CORNER_TOP_BACK_RIGHT] = Vector2(135.0, iso_el)
	_hit_zone_angles[HitZone.CORNER_TOP_BACK_LEFT] = Vector2(225.0, iso_el)
	_hit_zone_angles[HitZone.CORNER_BOTTOM_FRONT_RIGHT] = Vector2(45.0, -iso_el)
	_hit_zone_angles[HitZone.CORNER_BOTTOM_FRONT_LEFT] = Vector2(315.0, -iso_el)
	_hit_zone_angles[HitZone.CORNER_BOTTOM_BACK_RIGHT] = Vector2(135.0, -iso_el)
	_hit_zone_angles[HitZone.CORNER_BOTTOM_BACK_LEFT] = Vector2(225.0, -iso_el)


func _setup_widget() -> void:
	# Position in top-right corner
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -(WIDGET_SIZE + 10)
	offset_right = -10
	offset_top = 10
	offset_bottom = WIDGET_SIZE + 10
	custom_minimum_size = Vector2(WIDGET_SIZE, WIDGET_SIZE)

	# Semi-transparent background
	_bg_panel = ColorRect.new()
	_bg_panel.color = COLOR_WIDGET_BG
	_bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_panel)


func _setup_sub_viewport() -> void:
	# Create SubViewport to render the mini cube
	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "CubeViewport"
	_sub_viewport.size = Vector2i(WIDGET_SIZE, WIDGET_SIZE)
	_sub_viewport.transparent_bg = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.world_3d = World3D.new()
	_sub_viewport.own_world_3d = true
	# Disable physics in the SubViewport
	_sub_viewport.physics_object_picking = false
	add_child(_sub_viewport)

	# Camera looking at origin from +Z (default forward is -Z, so no rotation needed)
	_cube_camera = Camera3D.new()
	_cube_camera.name = "CubeCamera"
	_cube_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cube_camera.size = 3.0
	_cube_camera.position = Vector3(0, 0, CUBE_CAMERA_DISTANCE)
	# Camera faces -Z by default, which points at the origin — no rotation needed
	_cube_camera.current = true
	_sub_viewport.add_child(_cube_camera)

	# Key light from upper-right-front
	var light := DirectionalLight3D.new()
	light.name = "CubeLight"
	# Point light toward origin from (2, 3, 2) — compute rotation manually
	light.rotation = Vector3(deg_to_rad(-40), deg_to_rad(30), 0)
	light.light_energy = 0.8
	light.shadow_enabled = false
	_sub_viewport.add_child(light)

	# Fill light from opposite side
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation = Vector3(deg_to_rad(20), deg_to_rad(-150), 0)
	fill_light.light_energy = 0.3
	fill_light.shadow_enabled = false
	_sub_viewport.add_child(fill_light)

	# TextureRect to display the viewport
	_texture_rect = TextureRect.new()
	_texture_rect.name = "CubeDisplay"
	_texture_rect.texture = _sub_viewport.get_texture()
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)


func _setup_cube() -> void:
	# Root node that gets rotated to match camera
	_cube_root = Node3D.new()
	_cube_root.name = "CubeRoot"
	_sub_viewport.add_child(_cube_root)

	# Build cube from 6 individual face quads (for per-face hover)
	_build_face_quads()
	# Add edge wireframe
	_build_edge_wireframe()
	# Add face labels
	_build_face_labels()


func _build_face_quads() -> void:
	## Create 6 PlaneMesh quads for the cube faces, each with its own material.
	var face_data := {
		HitZone.FACE_TOP: {"pos": Vector3(0, CUBE_HALF, 0), "rot": Vector3(0, 0, 0), "label": "TOP"},
		HitZone.FACE_BOTTOM: {"pos": Vector3(0, -CUBE_HALF, 0), "rot": Vector3(PI, 0, 0), "label": "BOT"},
		HitZone.FACE_FRONT: {"pos": Vector3(0, 0, CUBE_HALF), "rot": Vector3(PI / 2, 0, 0), "label": "S"},
		HitZone.FACE_BACK: {"pos": Vector3(0, 0, -CUBE_HALF), "rot": Vector3(-PI / 2, 0, 0), "label": "N"},
		HitZone.FACE_RIGHT: {"pos": Vector3(CUBE_HALF, 0, 0), "rot": Vector3(0, 0, -PI / 2), "label": "E"},
		HitZone.FACE_LEFT: {"pos": Vector3(-CUBE_HALF, 0, 0), "rot": Vector3(0, 0, PI / 2), "label": "W"},
	}

	for zone_id in face_data:
		var data: Dictionary = face_data[zone_id]
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Face_%s" % data.label

		var plane := PlaneMesh.new()
		plane.size = Vector2(CUBE_HALF * 2, CUBE_HALF * 2)
		mesh_inst.mesh = plane

		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_CUBE_FACE
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_inst.material_override = mat
		_face_materials[zone_id] = mat

		mesh_inst.position = data.pos
		mesh_inst.rotation = data.rot
		_cube_root.add_child(mesh_inst)


func _build_edge_wireframe() -> void:
	## Draw thin box edges for visual clarity.
	var h := CUBE_HALF
	# 12 edges of a cube
	var edges := [
		# Top face edges
		[Vector3(-h, h, -h), Vector3(h, h, -h)],
		[Vector3(h, h, -h), Vector3(h, h, h)],
		[Vector3(h, h, h), Vector3(-h, h, h)],
		[Vector3(-h, h, h), Vector3(-h, h, -h)],
		# Bottom face edges
		[Vector3(-h, -h, -h), Vector3(h, -h, -h)],
		[Vector3(h, -h, -h), Vector3(h, -h, h)],
		[Vector3(h, -h, h), Vector3(-h, -h, h)],
		[Vector3(-h, -h, h), Vector3(-h, -h, -h)],
		# Vertical edges
		[Vector3(-h, -h, -h), Vector3(-h, h, -h)],
		[Vector3(h, -h, -h), Vector3(h, h, -h)],
		[Vector3(h, -h, h), Vector3(h, h, h)],
		[Vector3(-h, -h, h), Vector3(-h, h, h)],
	]

	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = COLOR_CUBE_EDGE
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for edge_pair in edges:
		var from_pt: Vector3 = edge_pair[0]
		var to_pt: Vector3 = edge_pair[1]
		var mesh_inst := _create_edge_cylinder(from_pt, to_pt, 0.02, edge_mat)
		_cube_root.add_child(mesh_inst)
		_edge_lines.append(mesh_inst)


func _create_edge_cylinder(from_pt: Vector3, to_pt: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	## Create a thin cylinder between two points to represent a cube edge.
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var length := from_pt.distance_to(to_pt)
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 4
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat

	# Position at midpoint, orient along the edge direction
	var midpoint := (from_pt + to_pt) / 2.0
	mesh_inst.position = midpoint

	var direction := (to_pt - from_pt).normalized()
	# CylinderMesh is aligned along Y, so rotate to match direction
	if direction.is_equal_approx(Vector3.UP) or direction.is_equal_approx(Vector3.DOWN):
		pass  # Already aligned
	else:
		var up := Vector3.UP
		var axis := up.cross(direction).normalized()
		var angle := up.angle_to(direction)
		if axis.length() > 0.001:
			mesh_inst.rotation = Basis(axis, angle).get_euler()

	return mesh_inst


func _build_face_labels() -> void:
	## Create text labels on each face using Label3D nodes.
	var label_data := {
		"TOP": {"pos": Vector3(0, CUBE_HALF + 0.01, 0), "rot": Vector3(-PI / 2, 0, 0)},
		"BOT": {"pos": Vector3(0, -(CUBE_HALF + 0.01), 0), "rot": Vector3(PI / 2, 0, 0)},
		"S": {"pos": Vector3(0, 0, CUBE_HALF + 0.01), "rot": Vector3(0, 0, 0)},
		"N": {"pos": Vector3(0, 0, -(CUBE_HALF + 0.01)), "rot": Vector3(0, PI, 0)},
		"E": {"pos": Vector3(CUBE_HALF + 0.01, 0, 0), "rot": Vector3(0, PI / 2, 0)},
		"W": {"pos": Vector3(-(CUBE_HALF + 0.01), 0, 0), "rot": Vector3(0, -PI / 2, 0)},
	}

	for label_name in label_data:
		var data: Dictionary = label_data[label_name]
		var label_3d := Label3D.new()
		label_3d.name = "Label_%s" % label_name
		label_3d.text = label_name
		label_3d.font_size = 48
		label_3d.pixel_size = 0.01
		label_3d.modulate = COLOR_CUBE_LABEL
		label_3d.outline_size = 4
		label_3d.outline_modulate = Color(0, 0, 0, 0.8)
		label_3d.position = data.pos
		label_3d.rotation = data.rot
		label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label_3d.double_sided = true
		label_3d.no_depth_test = true
		_cube_root.add_child(label_3d)
		_face_labels[label_name] = label_3d


func _process(_delta: float) -> void:
	if _main_camera == null:
		return

	# Mirror the main camera's rotation onto the cube.
	# The orbital camera uses azimuth (horizontal) and elevation (vertical).
	# We rotate the cube root inversely so it appears as if the camera orbits the cube.
	var az := deg_to_rad(_main_camera.azimuth)
	var el := deg_to_rad(_main_camera.elevation)

	# Build rotation: first elevate, then rotate azimuth (inverse of camera)
	# Camera looks FROM spherical coords, cube shows WHAT the camera sees
	_cube_root.transform.basis = Basis.IDENTITY
	_cube_root.rotate_y(-az)
	_cube_root.rotate_x(el)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_mouse_pressed = true
		_mouse_press_pos = event.position
		_drag_start_pos = event.position
		_is_dragging = false
		accept_event()
	else:
		if _is_dragging:
			_is_dragging = false
			_mouse_pressed = false
			accept_event()
			return

		_mouse_pressed = false

		# Check for double-click
		var now := Time.get_ticks_msec() / 1000.0
		var zone := _get_hit_zone(event.position)

		if now - _last_click_time < DOUBLE_CLICK_TIME and zone == _last_click_zone:
			# Double-click → return to free camera
			free_camera_requested.emit()
			_last_click_time = 0.0
			accept_event()
			return

		_last_click_time = now
		_last_click_zone = zone

		# Single click → snap to view
		if zone != HitZone.NONE and _hit_zone_angles.has(zone):
			var angles: Vector2 = _hit_zone_angles[zone]
			view_snapped.emit(angles.x, angles.y)

		accept_event()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_pressed:
		var dist := event.position.distance_to(_mouse_press_pos)
		if not _is_dragging and dist > DRAG_THRESHOLD:
			_is_dragging = true

		if _is_dragging:
			# Emit drag rotation delta
			var delta_az := -event.relative.x * DRAG_SENSITIVITY
			var delta_el := event.relative.y * DRAG_SENSITIVITY
			drag_rotate.emit(delta_az, delta_el)
			accept_event()
			return

	# Hover detection
	var zone := _get_hit_zone(event.position)
	_update_hover(zone)


func _get_hit_zone(local_pos: Vector2) -> int:
	## Determine which part of the cube the mouse is over by projecting
	## the 2D position into the cube's 3D space using the SubViewport camera.
	if not _cube_camera or not _cube_root:
		return HitZone.NONE

	# Convert local widget position to SubViewport coordinates
	var vp_pos := local_pos

	# Cast a ray from the SubViewport camera
	var ray_from := _cube_camera.project_ray_origin(vp_pos)
	var ray_dir := _cube_camera.project_ray_normal(vp_pos)

	# Test intersection with each face plane of the cube
	var best_zone: int = HitZone.NONE
	var best_t: float = INF

	# We test against an axis-aligned cube in the cube_root's local space
	# First, transform the ray into cube_root's local space
	var inv_transform := _cube_root.global_transform.affine_inverse()
	var local_from := inv_transform * ray_from
	var local_dir := (inv_transform.basis * ray_dir).normalized()

	# AABB intersection for a cube centered at origin with half-extent CUBE_HALF
	var h := CUBE_HALF
	var hit_result := _ray_aabb_hit(local_from, local_dir, h)
	if hit_result.zone != HitZone.NONE:
		return hit_result.zone

	return HitZone.NONE


func _ray_aabb_hit(ray_origin: Vector3, ray_dir: Vector3, half: float) -> Dictionary:
	## Cast ray against axis-aligned cube. Returns {zone: HitZone, point: Vector3}.
	## Classifies the hit point as face, edge, or corner based on proximity.
	var result := {"zone": HitZone.NONE, "point": Vector3.ZERO}

	# Slab test for AABB [-half, half] on each axis
	var tmin := -INF
	var tmax := INF
	var tmin_axis := -1
	var tmax_axis := -1
	var tmin_side := 1.0  # +1 or -1 for which side of the slab

	for axis in range(3):
		var origin_comp: float = [ray_origin.x, ray_origin.y, ray_origin.z][axis]
		var dir_comp: float = [ray_dir.x, ray_dir.y, ray_dir.z][axis]

		if absf(dir_comp) < 1e-8:
			# Ray parallel to slab
			if origin_comp < -half or origin_comp > half:
				return result  # Miss
			continue

		var t1 := (-half - origin_comp) / dir_comp
		var t2 := (half - origin_comp) / dir_comp
		var side := -1.0  # t1 hits the -half side

		if t1 > t2:
			var tmp := t1
			t1 = t2
			t2 = tmp
			side = 1.0

		if t1 > tmin:
			tmin = t1
			tmin_axis = axis
			tmin_side = side
		if t2 < tmax:
			tmax = t2
			tmax_axis = axis

		if tmin > tmax:
			return result  # Miss

	if tmin < 0:
		return result  # Behind camera

	var hit_point := ray_origin + ray_dir * tmin
	result.point = hit_point

	# Classify the hit point
	result.zone = _classify_hit_point(hit_point, half)
	return result


func _classify_hit_point(point: Vector3, half: float) -> int:
	## Given a point on the cube surface, classify it as face, edge, or corner.
	## Uses distance from face centers/edges/corners to determine zone.

	# Edge/corner threshold: how close to an edge before it counts as edge zone
	var edge_threshold := half * 0.3

	# Count how many axes are near the cube boundary
	var near_axes: Array[int] = []
	var axis_signs: Array[float] = []
	for axis in range(3):
		var comp: float = [point.x, point.y, point.z][axis]
		if absf(absf(comp) - half) < 0.01:  # On a face
			near_axes.append(axis)
			axis_signs.append(signf(comp))

	if near_axes.size() == 0:
		return HitZone.NONE

	# The primary face is the axis we're on
	var primary_axis: int = near_axes[0]
	var primary_sign: float = axis_signs[0]

	# Check proximity to edges and corners on this face
	# Get the two other axes
	var other_axes: Array[int] = []
	for a in range(3):
		if a != primary_axis:
			other_axes.append(a)

	var comp0: float = [point.x, point.y, point.z][other_axes[0]]
	var comp1: float = [point.x, point.y, point.z][other_axes[1]]

	var near_edge0 := absf(absf(comp0) - half) < edge_threshold
	var near_edge1 := absf(absf(comp1) - half) < edge_threshold

	if near_edge0 and near_edge1:
		# Corner
		return _get_corner_zone(primary_axis, primary_sign, other_axes, comp0, comp1)
	elif near_edge0 or near_edge1:
		# Edge
		var edge_axis: int = other_axes[0] if near_edge0 else other_axes[1]
		var edge_comp: float = comp0 if near_edge0 else comp1
		return _get_edge_zone(primary_axis, primary_sign, edge_axis, signf(edge_comp))
	else:
		# Face center
		return _get_face_zone(primary_axis, primary_sign)


func _get_face_zone(axis: int, side: float) -> int:
	# axis: 0=X, 1=Y, 2=Z. side: +1 or -1
	match axis:
		0:
			return HitZone.FACE_RIGHT if side > 0 else HitZone.FACE_LEFT
		1:
			return HitZone.FACE_TOP if side > 0 else HitZone.FACE_BOTTOM
		2:
			return HitZone.FACE_FRONT if side > 0 else HitZone.FACE_BACK
	return HitZone.NONE


func _get_edge_zone(face_axis: int, face_sign: float, edge_axis: int, edge_sign: float) -> int:
	## Map two face identities to an edge zone.
	var face_a := _get_face_zone(face_axis, face_sign)
	var face_b := _get_face_zone(edge_axis, edge_sign)
	return _edge_from_faces(face_a, face_b)


func _edge_from_faces(a: int, b: int) -> int:
	## Given two face zones, return the edge between them.
	# Sort so lookup is order-independent
	var lo := mini(a, b)
	var hi := maxi(a, b)

	# Top edges
	if lo == HitZone.FACE_TOP and hi == HitZone.FACE_FRONT:
		return HitZone.EDGE_TOP_FRONT
	if lo == HitZone.FACE_TOP and hi == HitZone.FACE_BACK:
		return HitZone.EDGE_TOP_BACK
	if lo == HitZone.FACE_TOP and hi == HitZone.FACE_RIGHT:
		return HitZone.EDGE_TOP_RIGHT
	if lo == HitZone.FACE_TOP and hi == HitZone.FACE_LEFT:
		return HitZone.EDGE_TOP_LEFT

	# Bottom edges
	if lo == HitZone.FACE_BOTTOM and hi == HitZone.FACE_FRONT:
		return HitZone.EDGE_BOTTOM_FRONT
	if lo == HitZone.FACE_BOTTOM and hi == HitZone.FACE_BACK:
		return HitZone.EDGE_BOTTOM_BACK
	if lo == HitZone.FACE_BOTTOM and hi == HitZone.FACE_RIGHT:
		return HitZone.EDGE_BOTTOM_RIGHT
	if lo == HitZone.FACE_BOTTOM and hi == HitZone.FACE_LEFT:
		return HitZone.EDGE_BOTTOM_LEFT

	# Horizontal edges
	if lo == HitZone.FACE_FRONT and hi == HitZone.FACE_RIGHT:
		return HitZone.EDGE_FRONT_RIGHT
	if lo == HitZone.FACE_FRONT and hi == HitZone.FACE_LEFT:
		return HitZone.EDGE_FRONT_LEFT
	if lo == HitZone.FACE_BACK and hi == HitZone.FACE_RIGHT:
		return HitZone.EDGE_BACK_RIGHT
	if lo == HitZone.FACE_BACK and hi == HitZone.FACE_LEFT:
		return HitZone.EDGE_BACK_LEFT

	# Fallback: return the first face
	return a


func _get_corner_zone(face_axis: int, face_sign: float, other_axes: Array[int], comp0: float, comp1: float) -> int:
	## Map three axis signs to a corner zone.
	# Determine sign for each axis
	var signs := [0.0, 0.0, 0.0]
	signs[face_axis] = face_sign
	signs[other_axes[0]] = signf(comp0)
	signs[other_axes[1]] = signf(comp1)

	var y_pos: bool = signs[1] > 0
	var z_pos: bool = signs[2] > 0
	var x_pos: bool = signs[0] > 0

	if y_pos:
		if z_pos:
			return HitZone.CORNER_TOP_FRONT_RIGHT if x_pos else HitZone.CORNER_TOP_FRONT_LEFT
		else:
			return HitZone.CORNER_TOP_BACK_RIGHT if x_pos else HitZone.CORNER_TOP_BACK_LEFT
	else:
		if z_pos:
			return HitZone.CORNER_BOTTOM_FRONT_RIGHT if x_pos else HitZone.CORNER_BOTTOM_FRONT_LEFT
		else:
			return HitZone.CORNER_BOTTOM_BACK_RIGHT if x_pos else HitZone.CORNER_BOTTOM_BACK_LEFT


func _update_hover(zone: int) -> void:
	if zone == _hovered_zone:
		return

	# Reset previous hover
	_reset_all_face_colors()

	_hovered_zone = zone

	# Highlight hovered face(s)
	if zone != HitZone.NONE:
		var faces_to_highlight := _get_faces_for_zone(zone)
		for face_zone in faces_to_highlight:
			if _face_materials.has(face_zone):
				_face_materials[face_zone].albedo_color = COLOR_CUBE_FACE_HOVER


func _get_faces_for_zone(zone: int) -> Array[int]:
	## Return which face zones to highlight for a given hit zone.
	# Faces → just that face
	if zone >= HitZone.FACE_TOP and zone <= HitZone.FACE_LEFT:
		return [zone]

	# Edges → two faces
	match zone:
		HitZone.EDGE_TOP_FRONT: return [HitZone.FACE_TOP, HitZone.FACE_FRONT]
		HitZone.EDGE_TOP_BACK: return [HitZone.FACE_TOP, HitZone.FACE_BACK]
		HitZone.EDGE_TOP_RIGHT: return [HitZone.FACE_TOP, HitZone.FACE_RIGHT]
		HitZone.EDGE_TOP_LEFT: return [HitZone.FACE_TOP, HitZone.FACE_LEFT]
		HitZone.EDGE_BOTTOM_FRONT: return [HitZone.FACE_BOTTOM, HitZone.FACE_FRONT]
		HitZone.EDGE_BOTTOM_BACK: return [HitZone.FACE_BOTTOM, HitZone.FACE_BACK]
		HitZone.EDGE_BOTTOM_RIGHT: return [HitZone.FACE_BOTTOM, HitZone.FACE_RIGHT]
		HitZone.EDGE_BOTTOM_LEFT: return [HitZone.FACE_BOTTOM, HitZone.FACE_LEFT]
		HitZone.EDGE_FRONT_RIGHT: return [HitZone.FACE_FRONT, HitZone.FACE_RIGHT]
		HitZone.EDGE_FRONT_LEFT: return [HitZone.FACE_FRONT, HitZone.FACE_LEFT]
		HitZone.EDGE_BACK_RIGHT: return [HitZone.FACE_BACK, HitZone.FACE_RIGHT]
		HitZone.EDGE_BACK_LEFT: return [HitZone.FACE_BACK, HitZone.FACE_LEFT]

	# Corners → three faces
	match zone:
		HitZone.CORNER_TOP_FRONT_RIGHT: return [HitZone.FACE_TOP, HitZone.FACE_FRONT, HitZone.FACE_RIGHT]
		HitZone.CORNER_TOP_FRONT_LEFT: return [HitZone.FACE_TOP, HitZone.FACE_FRONT, HitZone.FACE_LEFT]
		HitZone.CORNER_TOP_BACK_RIGHT: return [HitZone.FACE_TOP, HitZone.FACE_BACK, HitZone.FACE_RIGHT]
		HitZone.CORNER_TOP_BACK_LEFT: return [HitZone.FACE_TOP, HitZone.FACE_BACK, HitZone.FACE_LEFT]
		HitZone.CORNER_BOTTOM_FRONT_RIGHT: return [HitZone.FACE_BOTTOM, HitZone.FACE_FRONT, HitZone.FACE_RIGHT]
		HitZone.CORNER_BOTTOM_FRONT_LEFT: return [HitZone.FACE_BOTTOM, HitZone.FACE_FRONT, HitZone.FACE_LEFT]
		HitZone.CORNER_BOTTOM_BACK_RIGHT: return [HitZone.FACE_BOTTOM, HitZone.FACE_BACK, HitZone.FACE_RIGHT]
		HitZone.CORNER_BOTTOM_BACK_LEFT: return [HitZone.FACE_BOTTOM, HitZone.FACE_BACK, HitZone.FACE_LEFT]

	return []


func _reset_all_face_colors() -> void:
	for zone_id in _face_materials:
		_face_materials[zone_id].albedo_color = COLOR_CUBE_FACE


func _mouse_exited() -> void:
	_update_hover(HitZone.NONE)
	_mouse_pressed = false
	_is_dragging = false


# --- Public API ---


func connect_to_camera(cam: Node3D) -> void:
	## Connect the ViewCube to an orbital camera.
	## The camera must have: azimuth, elevation (float properties),
	## _target_azimuth, _target_elevation (target properties),
	## _snap_to_view(az, el), and _toggle_orthographic().
	_main_camera = cam

	# Connect our signals to camera actions
	if not view_snapped.is_connected(_on_view_snapped):
		view_snapped.connect(_on_view_snapped)
	if not free_camera_requested.is_connected(_on_free_camera_requested):
		free_camera_requested.connect(_on_free_camera_requested)
	if not drag_rotate.is_connected(_on_drag_rotate):
		drag_rotate.connect(_on_drag_rotate)


func _on_view_snapped(az: float, el: float) -> void:
	if _main_camera == null:
		return
	_main_camera._snap_to_view(az, el)


func _on_free_camera_requested() -> void:
	if _main_camera == null:
		return
	if _main_camera.is_orthographic:
		_main_camera._toggle_orthographic()


func _on_drag_rotate(delta_az: float, delta_el: float) -> void:
	if _main_camera == null:
		return
	_main_camera._target_azimuth += delta_az
	var new_el: float = _main_camera._target_elevation + delta_el
	_main_camera._target_elevation = clampf(new_el, _main_camera.MIN_ELEVATION, _main_camera.MAX_ELEVATION)


func get_hovered_zone() -> int:
	## Returns the currently hovered HitZone for testing/debugging.
	return _hovered_zone


func get_cube_root() -> Node3D:
	## Returns the cube root node for testing rotation.
	return _cube_root


func get_sub_viewport() -> SubViewport:
	## Returns the SubViewport for testing.
	return _sub_viewport
