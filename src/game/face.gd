## Face direction utilities for block surfaces.
## Loaded via preload — no class_name needed.
##
## Directions follow Godot convention:
##   NORTH = -Z, SOUTH = +Z, EAST = +X, WEST = -X

enum Dir { TOP, BOTTOM, NORTH, SOUTH, EAST, WEST }

const _NORMALS := {
	Dir.TOP: Vector3i(0, 1, 0),
	Dir.BOTTOM: Vector3i(0, -1, 0),
	Dir.NORTH: Vector3i(0, 0, -1),
	Dir.SOUTH: Vector3i(0, 0, 1),
	Dir.EAST: Vector3i(1, 0, 0),
	Dir.WEST: Vector3i(-1, 0, 0),
}

const _LABELS := {
	Dir.TOP: "Top",
	Dir.BOTTOM: "Bottom",
	Dir.NORTH: "North",
	Dir.SOUTH: "South",
	Dir.EAST: "East",
	Dir.WEST: "West",
}


static func from_normal(normal: Vector3) -> int:
	## Classify a raycast hit normal into a Dir value.
	var rounded := Vector3i(
		int(round(normal.x)),
		int(round(normal.y)),
		int(round(normal.z)),
	)
	for dir in _NORMALS:
		if _NORMALS[dir] == rounded:
			return dir
	return Dir.TOP


static func to_normal(face: int) -> Vector3i:
	## Dir enum value → unit normal vector.
	return _NORMALS.get(face, Vector3i(0, 1, 0))


static func to_label(face: int) -> String:
	## Dir enum value → human-readable label.
	return _LABELS.get(face, "Unknown")


static func rotate_cw(face: int, steps: int) -> int:
	## Rotate a horizontal face direction CW around Y by the given number of
	## 90-degree steps. TOP and BOTTOM are unaffected.
	if face == Dir.TOP or face == Dir.BOTTOM:
		return face
	var order := [Dir.NORTH, Dir.EAST, Dir.SOUTH, Dir.WEST]
	var idx := order.find(face)
	if idx == -1:
		return face
	return order[(idx + steps) % 4]


static func get_face_transform(face: int, cell_center: Vector3, cell_size: float) -> Transform3D:
	## Returns a Transform3D that positions and orients a PlaneMesh
	## (default normal = +Y) on the specified face of a cell.
	var n := Vector3(to_normal(face))
	var offset := n * (cell_size / 2.0 + 0.02)  # z-fight avoidance
	var origin := cell_center + offset

	# Build a basis that rotates the plane's +Y normal to align with the face normal.
	var basis: Basis
	match face:
		Dir.TOP:
			basis = Basis.IDENTITY
		Dir.BOTTOM:
			basis = Basis(Vector3.RIGHT, PI)
		Dir.NORTH:
			basis = Basis(Vector3.RIGHT, -PI / 2.0)
		Dir.SOUTH:
			basis = Basis(Vector3.RIGHT, PI / 2.0)
		Dir.EAST:
			basis = Basis(Vector3.FORWARD, PI / 2.0)
		Dir.WEST:
			basis = Basis(Vector3.FORWARD, -PI / 2.0)
		_:
			basis = Basis.IDENTITY

	return Transform3D(basis, origin)
