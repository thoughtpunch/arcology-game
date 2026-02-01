## Interior mesh system for block cutaway visualization.
##
## Generates procedural furniture/fixture meshes inside blocks so that
## cutaway mode reveals meaningful interior content rather than empty space.
## Each block category has a distinct interior layout.
##
## Interior meshes are placed inside the block volume (below the exterior
## panels) and become visible when the exterior is cut away or made transparent.
##
## Spec reference: 3D refactor Section 3.3 — dual mesh per block:
##   exterior_mesh (outer shell) + interior_mesh (furniture/fixtures for cutaway)

const FaceScript = preload("res://src/game/face.gd")
const GridUtilsScript = preload("res://src/game/grid_utils.gd")

const CELL_SIZE: float = 6.0
const WALL_THICKNESS: float = 0.15  # Match BLOCK_INSET from sandbox_main
const FLOOR_HEIGHT: float = 0.12  # Interior floor slab thickness
const FURNITURE_INSET: float = 0.4  # Gap between furniture and cell walls

## Interior color palette — muted, warm tones that read well in cutaway.
const CATEGORY_COLORS: Dictionary = {
	"residential": Color(0.72, 0.58, 0.42),   # Warm wood
	"commercial": Color(0.85, 0.78, 0.65),    # Light wood/counter
	"transit": Color(0.55, 0.55, 0.60),       # Concrete gray
	"civic": Color(0.50, 0.45, 0.55),         # Muted purple-gray
	"industrial": Color(0.45, 0.48, 0.50),    # Steel gray
	"infrastructure": Color(0.50, 0.55, 0.52),# Green-gray pipe
	"green": Color(0.35, 0.55, 0.30),         # Living green
	"entertainment": Color(0.65, 0.45, 0.50), # Warm mauve
}

## Floor color (slightly darker than walls).
const FLOOR_COLOR := Color(0.50, 0.48, 0.45)

## Interior wall color for subdivisions.
const WALL_COLOR := Color(0.70, 0.68, 0.65)


static func create_interior_meshes_for_block(
	block_node: Node3D,
	occupied_cells: Array[Vector3i],
	origin: Vector3i,
	category: String,
	block_color: Color,
	block_size: Vector3i = Vector3i(1, 1, 1)
) -> Node3D:
	## Creates interior furniture/fixture meshes for a block.
	## For multi-height blocks (block_size.y > 1), generates tall-space interiors
	## instead of repeating per-cell furniture on every floor.
	## Returns the "Interiors" container node (already added as child of block_node).
	var container := Node3D.new()
	container.name = "Interiors"

	var height: int = block_size.y
	if height > 1:
		# Multi-height block: generate height-aware interiors
		for cell in occupied_cells:
			var local_y: int = cell.y - origin.y
			_create_multi_height_cell_interior(
				container, cell, origin, category, block_color, local_y, height
			)
	else:
		# Standard single-height block: existing per-cell logic
		for cell in occupied_cells:
			_create_cell_interior(container, cell, origin, category, block_color)

	block_node.add_child(container)
	return container


static func update_interior_meshes_for_block(
	block_node: Node3D,
	occupied_cells: Array[Vector3i],
	origin: Vector3i,
	category: String,
	block_color: Color,
	block_size: Vector3i = Vector3i(1, 1, 1)
) -> void:
	## Removes existing interiors and regenerates them.
	var existing: Node3D = block_node.get_node_or_null("Interiors")
	if existing:
		existing.queue_free()

	create_interior_meshes_for_block(
		block_node, occupied_cells, origin, category, block_color, block_size
	)


static func _create_cell_interior(
	container: Node3D,
	cell: Vector3i,
	block_origin: Vector3i,
	category: String,
	block_color: Color
) -> void:
	## Creates interior geometry for a single cell within the block.
	var local_cell := Vector3(cell - block_origin) * CELL_SIZE
	var cell_center := local_cell + Vector3.ONE * (CELL_SIZE / 2.0)

	# Interior floor slab
	_add_floor_slab(container, cell_center, cell, block_origin)

	# Category-specific furniture/fixtures
	match category:
		"residential":
			_add_residential_interior(container, cell_center, cell, block_origin, block_color)
		"commercial":
			_add_commercial_interior(container, cell_center, cell, block_origin, block_color)
		"transit":
			_add_transit_interior(container, cell_center, cell, block_origin, block_color)
		"civic":
			_add_civic_interior(container, cell_center, cell, block_origin, block_color)
		"industrial":
			_add_industrial_interior(container, cell_center, cell, block_origin, block_color)
		"infrastructure":
			_add_infrastructure_interior(container, cell_center, cell, block_origin, block_color)
		"green":
			_add_green_interior(container, cell_center, cell, block_origin, block_color)
		"entertainment":
			_add_entertainment_interior(container, cell_center, cell, block_origin, block_color)
		_:
			_add_generic_interior(container, cell_center, cell, block_origin, block_color)


# --- Multi-Height Cell Interior ---


static func _create_multi_height_cell_interior(
	container: Node3D,
	cell: Vector3i,
	block_origin: Vector3i,
	category: String,
	block_color: Color,
	local_y: int,
	total_height: int
) -> void:
	## Creates interior geometry for a cell within a multi-height block.
	## local_y: 0 = ground floor, 1+ = upper floors within the block.
	## Upper floors in multi-height blocks get open-air content instead of
	## repeating the same per-cell furniture.
	var local_cell := Vector3(cell - block_origin) * CELL_SIZE
	var cell_center := local_cell + Vector3.ONE * (CELL_SIZE / 2.0)

	if local_y == 0:
		# Ground floor: always gets a floor slab
		_add_floor_slab(container, cell_center, cell, block_origin)

	# Category-specific multi-height content
	match category:
		"green":
			_add_green_multi_height_interior(
				container, cell_center, cell, block_origin, block_color,
				local_y, total_height
			)
		"entertainment":
			_add_entertainment_multi_height_interior(
				container, cell_center, cell, block_origin, block_color,
				local_y, total_height
			)
		"transit":
			_add_transit_multi_height_interior(
				container, cell_center, cell, block_origin, block_color,
				local_y, total_height
			)
		"civic":
			_add_civic_multi_height_interior(
				container, cell_center, cell, block_origin, block_color,
				local_y, total_height
			)
		"commercial":
			_add_commercial_multi_height_interior(
				container, cell_center, cell, block_origin, block_color,
				local_y, total_height
			)
		_:
			# Fallback: upper floors get open space, ground floor gets standard interior
			if local_y == 0:
				_create_cell_interior(
					container, cell, block_origin, category, block_color
				)


# --- Multi-Height Green: tall trees + canopy ---


static func _add_green_multi_height_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color,
	local_y: int, total_height: int
) -> void:
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["green"], 0.6)
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT

	if local_y == 0:
		# Ground floor: soil bed + tree trunks
		var soil := BoxMesh.new()
		soil.size = Vector3(CELL_SIZE - WALL_THICKNESS * 4.0, 0.6, CELL_SIZE - WALL_THICKNESS * 4.0)
		var soil_inst := MeshInstance3D.new()
		soil_inst.name = "Soil_%s" % local_id
		soil_inst.mesh = soil
		soil_inst.material_override = _create_material(Color(0.35, 0.25, 0.15))  # Dark earth
		soil_inst.position = Vector3(cell_center.x, base_y + 0.3, cell_center.z)
		soil_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(soil_inst)

		# Tree trunk rising through multiple floors
		var trunk_height: float = float(total_height) * CELL_SIZE * 0.7
		var trunk := BoxMesh.new()
		trunk.size = Vector3(0.6, trunk_height, 0.6)
		var trunk_inst := MeshInstance3D.new()
		trunk_inst.name = "Trunk_%s" % local_id
		trunk_inst.mesh = trunk
		trunk_inst.material_override = _create_material(Color(0.45, 0.3, 0.18))  # Brown bark
		trunk_inst.position = Vector3(cell_center.x, base_y + 0.6 + trunk_height / 2.0, cell_center.z)
		trunk_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(trunk_inst)

	elif local_y < total_height - 1:
		# Middle floors: mid-canopy foliage (sparse)
		var mid_foliage := BoxMesh.new()
		mid_foliage.size = Vector3(3.0, 2.0, 3.0)
		var mid_inst := MeshInstance3D.new()
		mid_inst.name = "MidFoliage_%s" % local_id
		mid_inst.mesh = mid_foliage
		mid_inst.material_override = _create_material(furniture_color.lightened(0.1))
		mid_inst.position = Vector3(cell_center.x, cell_center.y, cell_center.z)
		mid_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(mid_inst)

	else:
		# Top floor: dense canopy
		var canopy := BoxMesh.new()
		canopy.size = Vector3(4.5, 2.5, 4.5)
		var canopy_inst := MeshInstance3D.new()
		canopy_inst.name = "Canopy_%s" % local_id
		canopy_inst.mesh = canopy
		canopy_inst.material_override = _create_material(furniture_color.darkened(0.1))
		canopy_inst.position = Vector3(cell_center.x, cell_center.y - 0.5, cell_center.z)
		canopy_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(canopy_inst)


# --- Multi-Height Entertainment: tiered seating ---


static func _add_entertainment_multi_height_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color,
	local_y: int, total_height: int
) -> void:
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["entertainment"], 0.6)
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT

	if local_y == 0:
		# Ground floor: stage/arena floor
		var stage := BoxMesh.new()
		stage.size = Vector3(4.5, 0.3, 4.5)
		var stage_inst := MeshInstance3D.new()
		stage_inst.name = "ArenaFloor_%s" % local_id
		stage_inst.mesh = stage
		stage_inst.material_override = _create_material(furniture_color.darkened(0.3))
		stage_inst.position = Vector3(cell_center.x, base_y + 0.15, cell_center.z)
		stage_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(stage_inst)

	elif local_y < total_height - 1:
		# Middle floors: tiered seating (stepped platforms along walls)
		for side in [-1.0, 1.0]:
			var tier := BoxMesh.new()
			var tier_depth: float = 1.5 + float(local_y) * 0.3
			tier.size = Vector3(4.0, 0.4, minf(tier_depth, 2.5))
			var tier_inst := MeshInstance3D.new()
			tier_inst.name = "Tier_%s_%s" % [local_id, "L" if side < 0 else "R"]
			tier_inst.mesh = tier
			tier_inst.material_override = _create_material(furniture_color)
			tier_inst.position = Vector3(
				cell_center.x,
				base_y + 0.2,
				cell_center.z + side * 1.5
			)
			tier_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			container.add_child(tier_inst)

	else:
		# Top floor: overhead rigging/lighting
		var rigging := BoxMesh.new()
		rigging.size = Vector3(4.0, 0.2, 4.0)
		var rig_inst := MeshInstance3D.new()
		rig_inst.name = "Rigging_%s" % local_id
		rig_inst.mesh = rigging
		rig_inst.material_override = _create_material(Color(0.3, 0.3, 0.35))  # Dark steel
		rig_inst.position = Vector3(cell_center.x, cell_center.y + 1.5, cell_center.z)
		rig_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(rig_inst)


# --- Multi-Height Transit: open atrium corridors ---


static func _add_transit_multi_height_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color,
	local_y: int, _total_height: int
) -> void:
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["transit"], 0.6)
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT

	if local_y == 0:
		# Ground floor: standard transit interior
		_add_transit_interior(container, cell_center, cell, block_origin, block_color)
	else:
		# Upper floors: walkway bridges and railings
		var walkway := BoxMesh.new()
		walkway.size = Vector3(CELL_SIZE - WALL_THICKNESS * 4.0, 0.15, 1.5)
		var walk_inst := MeshInstance3D.new()
		walk_inst.name = "Walkway_%s" % local_id
		walk_inst.mesh = walkway
		walk_inst.material_override = _create_material(furniture_color)
		walk_inst.position = Vector3(cell_center.x, base_y + 0.075, cell_center.z)
		walk_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(walk_inst)

		# Railings along the walkway
		for side in [-1.0, 1.0]:
			var rail := BoxMesh.new()
			rail.size = Vector3(CELL_SIZE - WALL_THICKNESS * 4.0, 1.0, 0.06)
			var rail_inst := MeshInstance3D.new()
			rail_inst.name = "WalkRail_%s_%s" % [local_id, "L" if side < 0 else "R"]
			rail_inst.mesh = rail
			rail_inst.material_override = _create_material(furniture_color.darkened(0.3))
			rail_inst.position = Vector3(
				cell_center.x,
				base_y + 0.65,
				cell_center.z + side * 0.72
			)
			rail_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			container.add_child(rail_inst)


# --- Multi-Height Civic: grand hall ---


static func _add_civic_multi_height_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color,
	local_y: int, total_height: int
) -> void:
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["civic"], 0.6)
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT

	if local_y == 0:
		# Ground floor: standard civic interior with desk rows
		_add_civic_interior(container, cell_center, cell, block_origin, block_color)
	elif local_y == total_height - 1:
		# Top floor: decorative ceiling elements
		var ceiling_beam := BoxMesh.new()
		ceiling_beam.size = Vector3(CELL_SIZE - WALL_THICKNESS * 4.0, 0.3, 0.3)
		var beam_inst := MeshInstance3D.new()
		beam_inst.name = "CeilingBeam_%s" % local_id
		beam_inst.mesh = ceiling_beam
		beam_inst.material_override = _create_material(furniture_color.darkened(0.2))
		beam_inst.position = Vector3(cell_center.x, cell_center.y + 1.5, cell_center.z)
		beam_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(beam_inst)
	# Middle floors: open gallery space (no furniture, just empty volume)


# --- Multi-Height Commercial: multi-story retail ---


static func _add_commercial_multi_height_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color,
	local_y: int, total_height: int
) -> void:
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["commercial"], 0.6)
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT

	if local_y == 0:
		# Ground floor: standard commercial interior
		_add_commercial_interior(container, cell_center, cell, block_origin, block_color)
	else:
		# Upper floors: mezzanine with railing
		_add_floor_slab(container, cell_center, cell, block_origin)

		# Mezzanine railing
		var railing := BoxMesh.new()
		railing.size = Vector3(CELL_SIZE - WALL_THICKNESS * 4.0, 1.0, 0.08)
		var rail_inst := MeshInstance3D.new()
		rail_inst.name = "Mezzanine_%s" % local_id
		rail_inst.mesh = railing
		rail_inst.material_override = _create_material(furniture_color.darkened(0.2))
		rail_inst.position = Vector3(cell_center.x, base_y + 0.5, cell_center.z - 2.0)
		rail_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(rail_inst)

		# Display shelves on upper floors
		var shelf := BoxMesh.new()
		shelf.size = Vector3(3.0, 2.0, 0.4)
		var shelf_inst := MeshInstance3D.new()
		shelf_inst.name = "UpperShelf_%s" % local_id
		shelf_inst.mesh = shelf
		shelf_inst.material_override = _create_material(furniture_color.darkened(0.15))
		shelf_inst.position = Vector3(cell_center.x, base_y + 1.0, cell_center.z + 2.2)
		shelf_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(shelf_inst)


# --- Floor Slab (all categories) ---

static func _add_floor_slab(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i
) -> void:
	## Thin floor slab at the bottom of the cell interior.
	var floor_mesh := BoxMesh.new()
	var inner := CELL_SIZE - WALL_THICKNESS * 2.0
	floor_mesh.size = Vector3(inner, FLOOR_HEIGHT, inner)

	var inst := MeshInstance3D.new()
	inst.name = "Floor_%s" % Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	inst.mesh = floor_mesh
	inst.material_override = _create_material(FLOOR_COLOR)
	# Position at bottom of cell, shifted up by half floor thickness
	inst.position = Vector3(cell_center.x, cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT / 2.0, cell_center.z)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(inst)


# --- Residential: bed + small table ---

static func _add_residential_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["residential"], 0.6)

	# Bed (lower floor) — rectangular box
	var bed := BoxMesh.new()
	bed.size = Vector3(2.0, 0.5, 1.2)
	var bed_inst := MeshInstance3D.new()
	bed_inst.name = "Bed_%s" % local_id
	bed_inst.mesh = bed
	bed_inst.material_override = _create_material(furniture_color)
	bed_inst.position = Vector3(cell_center.x - 1.0, base_y + 0.25, cell_center.z - 1.2)
	bed_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(bed_inst)

	# Bedside table — small cube
	var table := BoxMesh.new()
	table.size = Vector3(0.5, 0.55, 0.5)
	var table_inst := MeshInstance3D.new()
	table_inst.name = "Table_%s" % local_id
	table_inst.mesh = table
	table_inst.material_override = _create_material(furniture_color.darkened(0.15))
	table_inst.position = Vector3(cell_center.x + 0.5, base_y + 0.275, cell_center.z - 1.2)
	table_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(table_inst)

	# Internal divider wall (separating lower and upper floor within the cell)
	var divider := BoxMesh.new()
	var inner := CELL_SIZE - WALL_THICKNESS * 2.0
	divider.size = Vector3(inner, 0.1, inner)
	var divider_inst := MeshInstance3D.new()
	divider_inst.name = "Divider_%s" % local_id
	divider_inst.mesh = divider
	divider_inst.material_override = _create_material(WALL_COLOR)
	divider_inst.position = Vector3(cell_center.x, cell_center.y, cell_center.z)
	divider_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(divider_inst)

	# Upper floor: desk
	var desk := BoxMesh.new()
	desk.size = Vector3(1.5, 0.45, 0.8)
	var desk_inst := MeshInstance3D.new()
	desk_inst.name = "Desk_%s" % local_id
	desk_inst.mesh = desk
	desk_inst.material_override = _create_material(furniture_color.darkened(0.1))
	desk_inst.position = Vector3(cell_center.x + 0.5, cell_center.y + 0.1 + 0.225, cell_center.z + 1.0)
	desk_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(desk_inst)


# --- Commercial: counter + shelving ---

static func _add_commercial_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["commercial"], 0.6)

	# Service counter — runs along one wall
	var counter := BoxMesh.new()
	counter.size = Vector3(4.0, 1.1, 0.7)
	var counter_inst := MeshInstance3D.new()
	counter_inst.name = "Counter_%s" % local_id
	counter_inst.mesh = counter
	counter_inst.material_override = _create_material(furniture_color)
	counter_inst.position = Vector3(cell_center.x, base_y + 0.55, cell_center.z - 1.8)
	counter_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(counter_inst)

	# Shelving unit — against opposite wall
	var shelf := BoxMesh.new()
	shelf.size = Vector3(3.5, 2.5, 0.4)
	var shelf_inst := MeshInstance3D.new()
	shelf_inst.name = "Shelf_%s" % local_id
	shelf_inst.mesh = shelf
	shelf_inst.material_override = _create_material(furniture_color.darkened(0.2))
	shelf_inst.position = Vector3(cell_center.x, base_y + 1.25, cell_center.z + 2.2)
	shelf_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(shelf_inst)


# --- Transit: floor markings + handrails ---

static func _add_transit_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["transit"], 0.6)

	# Center lane marking (thin strip on floor)
	var lane := BoxMesh.new()
	lane.size = Vector3(0.15, 0.02, CELL_SIZE - WALL_THICKNESS * 2.0)
	var lane_inst := MeshInstance3D.new()
	lane_inst.name = "Lane_%s" % local_id
	lane_inst.mesh = lane
	lane_inst.material_override = _create_material(Color(0.9, 0.85, 0.3))  # Yellow lane
	lane_inst.position = Vector3(cell_center.x, base_y + 0.01, cell_center.z)
	lane_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(lane_inst)

	# Side handrails (two thin vertical bars)
	for side in [-1.0, 1.0]:
		var rail := BoxMesh.new()
		rail.size = Vector3(0.06, 1.0, CELL_SIZE - WALL_THICKNESS * 2.0 - 0.5)
		var rail_inst := MeshInstance3D.new()
		rail_inst.name = "Rail_%s_%s" % [local_id, "L" if side < 0 else "R"]
		rail_inst.mesh = rail
		rail_inst.material_override = _create_material(furniture_color.darkened(0.3))
		rail_inst.position = Vector3(
			cell_center.x + side * (CELL_SIZE / 2.0 - WALL_THICKNESS - 0.3),
			base_y + 0.5,
			cell_center.z
		)
		rail_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(rail_inst)


# --- Civic: desk rows ---

static func _add_civic_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["civic"], 0.6)

	# Two desk rows
	for row_i in range(2):
		var desk := BoxMesh.new()
		desk.size = Vector3(3.5, 0.75, 0.8)
		var desk_inst := MeshInstance3D.new()
		desk_inst.name = "CivicDesk_%s_%d" % [local_id, row_i]
		desk_inst.mesh = desk
		desk_inst.material_override = _create_material(furniture_color)
		var z_offset: float = -1.2 + row_i * 2.4
		desk_inst.position = Vector3(cell_center.x, base_y + 0.375, cell_center.z + z_offset)
		desk_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(desk_inst)


# --- Industrial: machinery ---

static func _add_industrial_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["industrial"], 0.6)

	# Large machine block
	var machine := BoxMesh.new()
	machine.size = Vector3(2.5, 2.0, 2.5)
	var machine_inst := MeshInstance3D.new()
	machine_inst.name = "Machine_%s" % local_id
	machine_inst.mesh = machine
	machine_inst.material_override = _create_material(furniture_color)
	machine_inst.position = Vector3(cell_center.x - 0.5, base_y + 1.0, cell_center.z)
	machine_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(machine_inst)

	# Smaller auxiliary unit
	var aux := BoxMesh.new()
	aux.size = Vector3(1.2, 1.5, 1.0)
	var aux_inst := MeshInstance3D.new()
	aux_inst.name = "Auxiliary_%s" % local_id
	aux_inst.mesh = aux
	aux_inst.material_override = _create_material(furniture_color.darkened(0.15))
	aux_inst.position = Vector3(cell_center.x + 1.8, base_y + 0.75, cell_center.z + 1.2)
	aux_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(aux_inst)


# --- Infrastructure: pipes/ducts ---

static func _add_infrastructure_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["infrastructure"], 0.6)

	# Horizontal pipe run (cylinder approximated as thin box for now)
	var pipe := BoxMesh.new()
	pipe.size = Vector3(CELL_SIZE - WALL_THICKNESS * 2.0, 0.4, 0.4)
	var pipe_inst := MeshInstance3D.new()
	pipe_inst.name = "Pipe_%s" % local_id
	pipe_inst.mesh = pipe
	pipe_inst.material_override = _create_material(furniture_color)
	pipe_inst.position = Vector3(cell_center.x, base_y + 3.5, cell_center.z - 1.0)
	pipe_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(pipe_inst)

	# Vertical duct
	var duct := BoxMesh.new()
	duct.size = Vector3(0.6, CELL_SIZE - WALL_THICKNESS * 2.0 - FLOOR_HEIGHT, 0.6)
	var duct_inst := MeshInstance3D.new()
	duct_inst.name = "Duct_%s" % local_id
	duct_inst.mesh = duct
	duct_inst.material_override = _create_material(furniture_color.darkened(0.1))
	var half_h: float = (CELL_SIZE - WALL_THICKNESS * 2.0 - FLOOR_HEIGHT) / 2.0
	duct_inst.position = Vector3(cell_center.x + 2.0, base_y + half_h, cell_center.z + 1.5)
	duct_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(duct_inst)

	# Control panel
	var panel := BoxMesh.new()
	panel.size = Vector3(1.2, 1.8, 0.3)
	var panel_inst := MeshInstance3D.new()
	panel_inst.name = "CtrlPanel_%s" % local_id
	panel_inst.mesh = panel
	panel_inst.material_override = _create_material(Color(0.3, 0.35, 0.4))
	panel_inst.position = Vector3(cell_center.x - 1.5, base_y + 0.9, cell_center.z + 2.3)
	panel_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(panel_inst)


# --- Green: planter boxes ---

static func _add_green_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["green"], 0.6)

	# Central raised planter bed
	var planter := BoxMesh.new()
	planter.size = Vector3(3.5, 0.8, 3.5)
	var planter_inst := MeshInstance3D.new()
	planter_inst.name = "Planter_%s" % local_id
	planter_inst.mesh = planter
	planter_inst.material_override = _create_material(Color(0.4, 0.3, 0.2))  # Soil/terracotta
	planter_inst.position = Vector3(cell_center.x, base_y + 0.4, cell_center.z)
	planter_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(planter_inst)

	# Foliage volume (greenery on top of planter)
	var foliage := BoxMesh.new()
	foliage.size = Vector3(3.0, 1.5, 3.0)
	var foliage_inst := MeshInstance3D.new()
	foliage_inst.name = "Foliage_%s" % local_id
	foliage_inst.mesh = foliage
	foliage_inst.material_override = _create_material(furniture_color)
	foliage_inst.position = Vector3(cell_center.x, base_y + 0.8 + 0.75, cell_center.z)
	foliage_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(foliage_inst)


# --- Entertainment: seating rows ---

static func _add_entertainment_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)
	var furniture_color: Color = block_color.lerp(CATEGORY_COLORS["entertainment"], 0.6)

	# Two rows of seats (benches)
	for row_i in range(2):
		var bench := BoxMesh.new()
		bench.size = Vector3(4.0, 0.5, 0.6)
		var bench_inst := MeshInstance3D.new()
		bench_inst.name = "Bench_%s_%d" % [local_id, row_i]
		bench_inst.mesh = bench
		bench_inst.material_override = _create_material(furniture_color)
		var z_offset: float = -1.0 + row_i * 2.0
		bench_inst.position = Vector3(cell_center.x, base_y + 0.25, cell_center.z + z_offset)
		bench_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		container.add_child(bench_inst)

	# Stage/screen platform
	var stage := BoxMesh.new()
	stage.size = Vector3(3.0, 0.3, 1.5)
	var stage_inst := MeshInstance3D.new()
	stage_inst.name = "Stage_%s" % local_id
	stage_inst.mesh = stage
	stage_inst.material_override = _create_material(furniture_color.darkened(0.25))
	stage_inst.position = Vector3(cell_center.x, base_y + 0.15, cell_center.z - 2.0)
	stage_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(stage_inst)


# --- Generic fallback ---

static func _add_generic_interior(
	container: Node3D, cell_center: Vector3,
	cell: Vector3i, block_origin: Vector3i, block_color: Color
) -> void:
	var base_y: float = cell_center.y - CELL_SIZE / 2.0 + WALL_THICKNESS + FLOOR_HEIGHT
	var local_id := Vector3i(cell.x - block_origin.x, cell.y - block_origin.y, cell.z - block_origin.z)

	# Simple placeholder box
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 1.0, 2.0)
	var box_inst := MeshInstance3D.new()
	box_inst.name = "Generic_%s" % local_id
	box_inst.mesh = box
	box_inst.material_override = _create_material(block_color.darkened(0.2))
	box_inst.position = Vector3(cell_center.x, base_y + 0.5, cell_center.z)
	box_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	container.add_child(box_inst)


# --- Material Helpers ---

static func _create_material(color: Color) -> StandardMaterial3D:
	## Creates a simple matte material for interior furniture.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.roughness = 0.8
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.0
	return mat


static func get_furniture_color(category: String, block_color: Color) -> Color:
	## Returns the blended furniture color for a given category.
	var cat_color: Color = CATEGORY_COLORS.get(category, block_color)
	return block_color.lerp(cat_color, 0.6)
