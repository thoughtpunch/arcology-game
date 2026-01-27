extends Node3D
class_name ChunkManager

## Manages spatial chunks for geometry batching in the 3D arcology.
##
## Chunks are 8x8x8 grid cells that merge block meshes to reduce draw calls.
## Dirty chunks are rebuilt during idle time with a frame budget to prevent stutter.
##
## Usage:
##   var manager = ChunkManager.new()
##   add_child(manager)
##   manager.add_block(Vector3i(0, 0, 0), "corridor")
##   # Chunks rebuild automatically during _process

const ChunkClass := preload("res://src/rendering/chunk.gd")

# Chunk size in grid cells per axis (must match Chunk.CHUNK_SIZE)
const CHUNK_SIZE: int = 8

# Maximum chunks to rebuild per frame (prevents stutter)
const MAX_REBUILDS_PER_FRAME: int = 2

# Maximum rebuild time budget per frame in microseconds
const REBUILD_TIME_BUDGET_USEC: int = 4000  # 4ms budget

# Signals
signal chunk_created(chunk_coord: Vector3i)
signal chunk_removed(chunk_coord: Vector3i)
signal chunk_rebuilt(chunk_coord: Vector3i)

# Chunk storage: Vector3i (chunk coord) -> Chunk node
var _chunks: Dictionary = {}

# Dirty chunks queue (ordered for priority rebuild)
var _dirty_queue: Array[Vector3i] = []

# Camera reference for frustum culling priority
var _camera: Camera3D = null

# Shader for chunk materials
var _block_shader: Shader = null

# Material cache (shared across chunks)
var _material_cache: Dictionary = {}

# Statistics
var _total_blocks: int = 0
var _total_chunks: int = 0
var _rebuilds_this_frame: int = 0


func _ready() -> void:
	name = "ChunkManager"
	_load_shader()


func _process(_delta: float) -> void:
	_rebuild_dirty_chunks()


## Set camera reference for frustum culling priority
func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Add a block to the appropriate chunk
func add_block(grid_pos: Vector3i, block_type: String, rotation: int = 0, material: Material = null) -> void:
	var chunk_coord := get_chunk_coord(grid_pos)
	var chunk := _get_or_create_chunk(chunk_coord)
	chunk.add_block(grid_pos, block_type, rotation, material)

	_enqueue_dirty(chunk_coord)
	_total_blocks += 1


## Remove a block from its chunk
func remove_block(grid_pos: Vector3i) -> void:
	var chunk_coord := get_chunk_coord(grid_pos)
	var chunk: Node3D = _chunks.get(chunk_coord, null)
	if not chunk:
		return

	if chunk.remove_block(grid_pos):
		_total_blocks -= 1

		if chunk.is_empty():
			_remove_chunk(chunk_coord)
		else:
			_enqueue_dirty(chunk_coord)


## Check if a block exists at the given position
func has_block(grid_pos: Vector3i) -> bool:
	var chunk_coord := get_chunk_coord(grid_pos)
	var chunk: Node3D = _chunks.get(chunk_coord, null)
	if not chunk:
		return false
	return chunk.has_block(grid_pos)


## Get block data at a position
func get_block_data(grid_pos: Vector3i) -> Dictionary:
	var chunk_coord := get_chunk_coord(grid_pos)
	var chunk: Node3D = _chunks.get(chunk_coord, null)
	if not chunk:
		return {}
	return chunk.get_block_data(grid_pos)


## Convert a grid position to its chunk coordinate
func get_chunk_coord(grid_pos: Vector3i) -> Vector3i:
	return Vector3i(
		_floor_div(grid_pos.x, CHUNK_SIZE),
		_floor_div(grid_pos.y, CHUNK_SIZE),
		_floor_div(grid_pos.z, CHUNK_SIZE)
	)


## Get all chunk coordinates
func get_chunk_coords() -> Array:
	return _chunks.keys()


## Get the chunk at a coordinate (or null)
func get_chunk(chunk_coord: Vector3i) -> Node3D:
	return _chunks.get(chunk_coord, null)


## Get total block count across all chunks
func get_total_block_count() -> int:
	return _total_blocks


## Get total chunk count
func get_chunk_count() -> int:
	return _total_chunks


## Get count of dirty chunks awaiting rebuild
func get_dirty_count() -> int:
	return _dirty_queue.size()


## Force immediate rebuild of all dirty chunks (useful for tests)
func rebuild_all_dirty() -> void:
	while not _dirty_queue.is_empty():
		var chunk_coord: Vector3i = _dirty_queue.pop_front()
		var chunk: Node3D = _chunks.get(chunk_coord, null)
		if chunk and chunk.is_dirty():
			chunk.rebuild()
			chunk_rebuilt.emit(chunk_coord)


## Clear all chunks and blocks
func clear() -> void:
	for chunk_coord in _chunks.keys():
		_remove_chunk(chunk_coord)
	_chunks.clear()
	_dirty_queue.clear()
	_total_blocks = 0
	_total_chunks = 0


## Get all block positions across all chunks
func get_all_block_positions() -> Array:
	var positions: Array = []
	for chunk in _chunks.values():
		positions.append_array(chunk.get_block_positions())
	return positions


## Check if a chunk coordinate has a chunk
func has_chunk(chunk_coord: Vector3i) -> bool:
	return _chunks.has(chunk_coord)


## Get chunks visible to the camera (frustum culling)
func get_visible_chunks() -> Array:
	if not _camera:
		# No camera = all chunks visible
		var all_chunks: Array = []
		for chunk in _chunks.values():
			all_chunks.append(chunk)
		return all_chunks

	var visible: Array = []
	var frustum := _camera.get_frustum()

	for chunk in _chunks.values():
		var aabb: AABB = chunk.get_aabb()
		if aabb.size == Vector3.ZERO:
			continue

		# Check if AABB intersects all frustum planes
		if _aabb_in_frustum(aabb, frustum):
			visible.append(chunk)

	return visible


# --- Internal Methods ---

## Get or create a chunk at the given coordinate
func _get_or_create_chunk(chunk_coord: Vector3i) -> Node3D:
	if _chunks.has(chunk_coord):
		return _chunks[chunk_coord]

	var chunk: Node3D = ChunkClass.new(chunk_coord)
	chunk.set_shader(_block_shader)
	_chunks[chunk_coord] = chunk
	add_child(chunk)
	_total_chunks += 1
	chunk_created.emit(chunk_coord)
	return chunk


## Remove a chunk
func _remove_chunk(chunk_coord: Vector3i) -> void:
	var chunk: Node3D = _chunks.get(chunk_coord, null)
	if not chunk:
		return

	_chunks.erase(chunk_coord)
	_total_chunks -= 1

	# Remove from dirty queue
	var idx := _dirty_queue.find(chunk_coord)
	if idx >= 0:
		_dirty_queue.remove_at(idx)

	chunk.queue_free()
	chunk_removed.emit(chunk_coord)


## Enqueue a chunk for rebuild
func _enqueue_dirty(chunk_coord: Vector3i) -> void:
	if chunk_coord not in _dirty_queue:
		_dirty_queue.append(chunk_coord)


## Rebuild dirty chunks within the frame budget
func _rebuild_dirty_chunks() -> void:
	if _dirty_queue.is_empty():
		return

	_rebuilds_this_frame = 0
	var start_usec := Time.get_ticks_usec()

	# Sort by priority (visible chunks first if camera available)
	if _camera:
		_sort_dirty_by_priority()

	while not _dirty_queue.is_empty():
		# Check frame budget
		if _rebuilds_this_frame >= MAX_REBUILDS_PER_FRAME:
			break

		var elapsed := Time.get_ticks_usec() - start_usec
		if elapsed >= REBUILD_TIME_BUDGET_USEC and _rebuilds_this_frame > 0:
			break

		var chunk_coord: Vector3i = _dirty_queue.pop_front()
		var chunk: Node3D = _chunks.get(chunk_coord, null)
		if chunk and chunk.is_dirty():
			chunk.rebuild()
			_rebuilds_this_frame += 1
			chunk_rebuilt.emit(chunk_coord)


## Sort dirty queue by distance to camera (closest first)
func _sort_dirty_by_priority() -> void:
	if not _camera or _dirty_queue.size() <= 1:
		return

	var cam_pos := _camera.global_position

	_dirty_queue.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		var chunk_a: Node3D = _chunks.get(a, null)
		var chunk_b: Node3D = _chunks.get(b, null)
		if not chunk_a or not chunk_b:
			return false
		var dist_a := cam_pos.distance_squared_to(chunk_a.position)
		var dist_b := cam_pos.distance_squared_to(chunk_b.position)
		return dist_a < dist_b
	)


## Check if an AABB is inside/intersects the camera frustum
func _aabb_in_frustum(aabb: AABB, frustum: Array[Plane]) -> bool:
	for plane in frustum:
		# Get the positive vertex (furthest along plane normal)
		var positive := Vector3(
			aabb.end.x if plane.normal.x >= 0 else aabb.position.x,
			aabb.end.y if plane.normal.y >= 0 else aabb.position.y,
			aabb.end.z if plane.normal.z >= 0 else aabb.position.z,
		)
		# If the positive vertex is behind this plane, AABB is outside frustum
		if plane.distance_to(positive) < 0:
			return false
	return true


## Floor division that handles negative numbers correctly
func _floor_div(a: int, b: int) -> int:
	# GDScript integer division truncates toward zero
	# We need floor division (toward negative infinity)
	if a >= 0:
		return a / b
	else:
		return (a - b + 1) / b


## Load shader for chunk materials
func _load_shader() -> void:
	var shader_path := "res://shaders/block_material.gdshader"
	if ResourceLoader.exists(shader_path):
		_block_shader = load(shader_path)
