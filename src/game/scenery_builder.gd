## SceneryBuilder - Procedural scenery generation for the sandbox environment.
## Extracted from sandbox_main.gd to reduce file size.
## Handles: skyline buildings, mountains, river, compass markers.
class_name SceneryBuilder
extends RefCounted

const CELL_SIZE: float = 6.0
const LOG_PREFIX := "[Scenery] "


static func _log(msg: String) -> void:
	if OS.is_debug_build():
		print(LOG_PREFIX + msg)


## Build the skyline of distant buildings around the play area.
## Uses MultiMesh for efficient rendering of many buildings.
static func build_skyline(parent: Node3D, config: RefCounted) -> void:
	if config.skyline_type == config.SkylineType.NONE:
		_log("Skyline skipped (type=NONE)")
		return
	if config.skyline_building_count <= 0:
		_log("Skyline skipped (building_count=0)")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = config.skyline_seed

	var center_offset := float(config.ground_size) * CELL_SIZE / 2.0
	var center := Vector3(center_offset, 0, center_offset)

	# Distribute building count across rings proportionally
	var bc: int = config.skyline_building_count
	var near_count := int(bc * 0.4)
	var mid_count := int(bc * 0.33)
	var far_count := bc - near_count - mid_count

	var rings := [
		# [count, min_radius, max_radius, min_height, max_height, min_width, max_width]
		[near_count, 80.0, 250.0, 8.0, 60.0, 6.0, 18.0],  # Near: small/medium, dense
		[mid_count, 200.0, 500.0, 15.0, 120.0, 8.0, 24.0],  # Mid: medium, some tall
		[far_count, 400.0, 1000.0, 30.0, 250.0, 10.0, 30.0],  # Far: tall skyline
	]

	var total_count := 0
	for ring in rings:
		total_count += ring[0]

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = total_count

	var box := BoxMesh.new()
	box.size = Vector3.ONE
	mm.mesh = box

	var idx := 0
	for ring in rings:
		var count: int = ring[0]
		var r_min: float = ring[1]
		var r_max: float = ring[2]
		var h_min: float = ring[3]
		var h_max: float = ring[4]
		var w_min: float = ring[5]
		var w_max: float = ring[6]

		for _i in range(count):
			var angle := rng.randf() * TAU
			var radius := rng.randf_range(r_min, r_max)
			var pos := center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)

			var width := rng.randf_range(w_min, w_max)
			var depth := rng.randf_range(w_min, w_max)
			var height := rng.randf_range(h_min, h_max) * pow(rng.randf(), 0.8)
			height = maxf(height, h_min)

			var basis := Basis.IDENTITY.scaled(Vector3(width, height, depth))
			var t := Transform3D(basis, pos + Vector3(0, height / 2.0, 0))
			mm.set_instance_transform(idx, t)

			# Near buildings are warmer/darker, far buildings are cooler/lighter (aerial perspective)
			var dist_t := clampf((radius - r_min) / maxf(r_max - r_min, 1.0), 0.0, 1.0)
			var grey := rng.randf_range(0.25, 0.42)
			var blue_shift := lerpf(0.01, 0.1, dist_t) + rng.randf_range(0.0, 0.03)
			var fade := lerpf(0.0, 0.08, dist_t)  # Slight lightening with distance
			mm.set_instance_color(
				idx,
				Color(
					grey - blue_shift + fade,
					grey + fade,
					grey + blue_shift + fade,
				)
			)
			idx += 1

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "Skyline"
	mm_instance.multimesh = mm
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	parent.add_child(mm_instance)
	_log("Skyline ready: %d buildings in 3 rings" % total_count)


## Build distant mountains around the play area.
## Uses hexagonal cones via MultiMesh.
static func build_mountains(parent: Node3D, config: RefCounted) -> void:
	if not config.mountains_enabled or config.mountain_count <= 0:
		_log("Mountains skipped (disabled or count=0)")
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = config.mountain_seed

	var center_offset := float(config.ground_size) * CELL_SIZE / 2.0
	var center := Vector3(center_offset, 0, center_offset)

	var count: int = config.mountain_count
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count

	# Hexagonal cone — CylinderMesh with top_radius=0
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 0
	mm.mesh = cone

	for i in range(count):
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(500.0, 1200.0)
		var pos := center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)

		var height := rng.randf_range(config.mountain_min_height, config.mountain_max_height)
		var base_radius := rng.randf_range(config.mountain_min_radius, config.mountain_max_radius)
		# Scale: x/z = base diameter, y = height
		var basis := Basis.IDENTITY.scaled(Vector3(base_radius * 2.0, height, base_radius * 2.0))
		var t := Transform3D(basis, pos + Vector3(0, height / 2.0, 0))
		mm.set_instance_transform(i, t)

		# Aerial perspective: near = green/dark, far = blue/light
		var dist_t := clampf((radius - 500.0) / 700.0, 0.0, 1.0)
		var col: Color = config.mountain_base_color.lerp(config.mountain_peak_color, dist_t)
		col = col.lerp(Color(0.6, 0.65, 0.75), dist_t * 0.3)  # Atmospheric haze
		mm.set_instance_color(i, col)

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "Mountains"
	mm_instance.multimesh = mm
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mm_instance)
	_log("Mountains ready: %d cones" % count)


## Build a river plane through the landscape.
static func build_river(parent: Node3D, config: RefCounted) -> void:
	if not config.river_enabled or config.river_width <= 0.0:
		_log("River skipped (disabled or width=0)")
		return

	var gs := float(config.ground_size) * CELL_SIZE
	var river_length := gs * 1.5  # Extends past visible edges

	var plane := PlaneMesh.new()
	plane.size = Vector2(river_length, config.river_width)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.river_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "River"
	mesh_inst.mesh = plane
	mesh_inst.material_override = mat
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Position at center of ground, offset perpendicular to flow direction
	var center := gs / 2.0
	var angle_rad := deg_to_rad(config.river_flow_angle)
	var offset_x: float = sin(angle_rad) * config.river_offset
	var offset_z: float = cos(angle_rad) * config.river_offset
	mesh_inst.position = Vector3(center + offset_x, 0.02, center + offset_z)
	mesh_inst.rotation_degrees = Vector3(0, config.river_flow_angle, 0)

	parent.add_child(mesh_inst)
	_log(
		"River ready: width=%.0f angle=%.0f offset=%.0f"
		% [config.river_width, config.river_flow_angle, config.river_offset]
	)


## Build N/S/E/W compass markers around the build zone.
static func build_compass_markers(
	parent: Node3D,
	build_zone_origin: Vector2i,
	build_zone_size: Vector2i
) -> void:
	# Place N/S/E/W labels on the ground at the edges of the build zone.
	# Godot convention: NORTH = -Z, SOUTH = +Z, EAST = +X, WEST = -X
	var zone_center_x := (float(build_zone_origin.x) + float(build_zone_size.x) / 2.0) * CELL_SIZE
	var zone_center_z := (float(build_zone_origin.y) + float(build_zone_size.y) / 2.0) * CELL_SIZE
	var half_x := float(build_zone_size.x) / 2.0 * CELL_SIZE
	var half_z := float(build_zone_size.y) / 2.0 * CELL_SIZE
	var marker_y := 2.0  # Slightly above ground

	var markers := {
		"N": Vector3(zone_center_x, marker_y, zone_center_z - half_z - 8.0),
		"S": Vector3(zone_center_x, marker_y, zone_center_z + half_z + 8.0),
		"E": Vector3(zone_center_x + half_x + 8.0, marker_y, zone_center_z),
		"W": Vector3(zone_center_x - half_x - 8.0, marker_y, zone_center_z),
	}

	for text in markers:
		var label := Label3D.new()
		label.text = text
		label.font_size = 72
		label.pixel_size = 0.1
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = Color(0.0, 0.9, 0.9, 0.7)
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		label.outline_size = 12
		label.position = markers[text]
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)

	_log("Compass markers ready: N/S/E/W")
