extends Node
class_name LODManager

## Manages Level of Detail (LOD) for 3D block rendering.
##
## The LOD system reduces rendering load for distant geometry by switching
## chunks and blocks to simplified meshes based on camera distance.
##
## LOD Levels (from 3D refactor spec Section 3.4):
##   LOD0 (0-50m):    Full detail, interior visible
##   LOD1 (50-150m):  Simplified exterior, no interior
##   LOD2 (150-400m): Block silhouette only
##   LOD3 (400m+):    Merged chunks, impostors
##
## Usage:
##   var lod_manager = LODManager.new()
##   add_child(lod_manager)
##   lod_manager.set_camera(camera)
##   lod_manager.register_chunk(chunk)
##
## The manager automatically updates LOD levels each frame based on camera position.

# LOD level enumeration
enum LODLevel {
	LOD0 = 0,  # Full detail (0-50m)
	LOD1 = 1,  # Simplified exterior (50-150m)
	LOD2 = 2,  # Silhouette only (150-400m)
	LOD3 = 3,  # Merged/impostor (400m+)
}

# Default distance thresholds (meters)
const DEFAULT_LOD0_MAX_DISTANCE: float = 50.0
const DEFAULT_LOD1_MAX_DISTANCE: float = 150.0
const DEFAULT_LOD2_MAX_DISTANCE: float = 400.0
# LOD3 is everything beyond LOD2_MAX_DISTANCE

# Hysteresis margin to prevent rapid LOD switching at boundaries
const LOD_HYSTERESIS: float = 5.0

# Update frequency (process every N frames to reduce overhead)
const UPDATE_INTERVAL_FRAMES: int = 2

# Signals
signal lod_level_changed(chunk: Node3D, old_level: LODLevel, new_level: LODLevel)
signal config_changed()

# Distance thresholds (configurable)
var lod0_max_distance: float = DEFAULT_LOD0_MAX_DISTANCE
var lod1_max_distance: float = DEFAULT_LOD1_MAX_DISTANCE
var lod2_max_distance: float = DEFAULT_LOD2_MAX_DISTANCE

# Camera reference
var _camera: Camera3D = null

# Registered chunks with their current LOD levels
# Key: Chunk node, Value: LODLevel
var _chunk_lods: Dictionary = {}

# Frame counter for update throttling
var _frame_counter: int = 0

# Statistics
var _chunks_at_lod: Array[int] = [0, 0, 0, 0]  # Count per LOD level


func _ready() -> void:
	name = "LODManager"


func _process(_delta: float) -> void:
	_frame_counter += 1
	if _frame_counter >= UPDATE_INTERVAL_FRAMES:
		_frame_counter = 0
		_update_all_lods()


## Set the camera used for distance calculations
func set_camera(camera: Camera3D) -> void:
	_camera = camera


## Get the current camera
func get_camera() -> Camera3D:
	return _camera


## Register a chunk with the LOD manager
func register_chunk(chunk: Node3D) -> void:
	if chunk in _chunk_lods:
		return
	_chunk_lods[chunk] = LODLevel.LOD0
	_update_chunk_lod(chunk)


## Unregister a chunk
func unregister_chunk(chunk: Node3D) -> void:
	if chunk in _chunk_lods:
		var old_lod: LODLevel = _chunk_lods[chunk]
		_chunks_at_lod[old_lod] -= 1
		_chunk_lods.erase(chunk)


## Clear all registered chunks
func clear() -> void:
	_chunk_lods.clear()
	_chunks_at_lod = [0, 0, 0, 0]


## Get the LOD level for a given distance
func get_lod_for_distance(distance: float) -> LODLevel:
	if distance <= lod0_max_distance:
		return LODLevel.LOD0
	elif distance <= lod1_max_distance:
		return LODLevel.LOD1
	elif distance <= lod2_max_distance:
		return LODLevel.LOD2
	else:
		return LODLevel.LOD3


## Get the LOD level for a given distance with hysteresis
## current_lod is used to apply hysteresis in the appropriate direction
func get_lod_for_distance_with_hysteresis(distance: float, current_lod: LODLevel) -> LODLevel:
	# Get thresholds with hysteresis applied
	var lod0_threshold := lod0_max_distance
	var lod1_threshold := lod1_max_distance
	var lod2_threshold := lod2_max_distance

	# Apply hysteresis: add margin when switching to higher detail (closer),
	# subtract margin when switching to lower detail (farther)
	match current_lod:
		LODLevel.LOD0:
			# Currently at highest detail; only switch away if clearly past threshold
			lod0_threshold += LOD_HYSTERESIS
		LODLevel.LOD1:
			# Add hysteresis to prevent oscillation
			lod0_threshold -= LOD_HYSTERESIS  # Switch to LOD0 slightly earlier
			lod1_threshold += LOD_HYSTERESIS  # Switch to LOD2 slightly later
		LODLevel.LOD2:
			lod1_threshold -= LOD_HYSTERESIS
			lod2_threshold += LOD_HYSTERESIS
		LODLevel.LOD3:
			lod2_threshold -= LOD_HYSTERESIS

	if distance <= lod0_threshold:
		return LODLevel.LOD0
	elif distance <= lod1_threshold:
		return LODLevel.LOD1
	elif distance <= lod2_threshold:
		return LODLevel.LOD2
	else:
		return LODLevel.LOD3


## Get the current LOD level for a chunk
func get_chunk_lod(chunk: Node3D) -> LODLevel:
	return _chunk_lods.get(chunk, LODLevel.LOD0)


## Get distance from camera to a world position
func get_distance_to(world_pos: Vector3) -> float:
	if not _camera:
		return 0.0
	return _camera.global_position.distance_to(world_pos)


## Get distance from camera to a chunk's center
func get_chunk_distance(chunk: Node3D) -> float:
	if not _camera or not chunk:
		return 0.0

	# Use chunk's AABB center if available
	if chunk.has_method("get_aabb"):
		var aabb: AABB = chunk.get_aabb()
		if aabb.size != Vector3.ZERO:
			var center := aabb.position + aabb.size / 2.0
			return _camera.global_position.distance_to(center)

	# Fall back to chunk position
	return _camera.global_position.distance_to(chunk.global_position)


## Set custom distance thresholds
func set_thresholds(lod0_max: float, lod1_max: float, lod2_max: float) -> void:
	lod0_max_distance = lod0_max
	lod1_max_distance = lod1_max
	lod2_max_distance = lod2_max
	config_changed.emit()
	# Force update all chunks
	_update_all_lods(true)


## Reset to default thresholds
func reset_thresholds() -> void:
	set_thresholds(DEFAULT_LOD0_MAX_DISTANCE, DEFAULT_LOD1_MAX_DISTANCE, DEFAULT_LOD2_MAX_DISTANCE)


## Get statistics about LOD distribution
func get_statistics() -> Dictionary:
	return {
		"total_chunks": _chunk_lods.size(),
		"lod0_count": _chunks_at_lod[0],
		"lod1_count": _chunks_at_lod[1],
		"lod2_count": _chunks_at_lod[2],
		"lod3_count": _chunks_at_lod[3],
	}


## Get the maximum distance threshold for a given LOD level
func get_max_distance_for_lod(lod: LODLevel) -> float:
	match lod:
		LODLevel.LOD0:
			return lod0_max_distance
		LODLevel.LOD1:
			return lod1_max_distance
		LODLevel.LOD2:
			return lod2_max_distance
		LODLevel.LOD3:
			return INF
	return INF


## Force an immediate update of all LOD levels
func force_update() -> void:
	_update_all_lods(true)


# --- Internal Methods ---

## Update LOD levels for all registered chunks
func _update_all_lods(force: bool = false) -> void:
	if not _camera:
		return

	for chunk in _chunk_lods.keys():
		if is_instance_valid(chunk):
			_update_chunk_lod(chunk, force)
		else:
			# Clean up invalid references
			_chunk_lods.erase(chunk)


## Update LOD level for a single chunk
func _update_chunk_lod(chunk: Node3D, force: bool = false) -> void:
	if not _camera:
		return

	var distance := get_chunk_distance(chunk)
	var current_lod: LODLevel = _chunk_lods.get(chunk, LODLevel.LOD0)
	var new_lod: LODLevel

	if force:
		new_lod = get_lod_for_distance(distance)
	else:
		new_lod = get_lod_for_distance_with_hysteresis(distance, current_lod)

	if new_lod != current_lod:
		_chunk_lods[chunk] = new_lod

		# Update statistics
		_chunks_at_lod[current_lod] -= 1
		_chunks_at_lod[new_lod] += 1

		# Notify chunk if it has a set_lod method
		if chunk.has_method("set_lod"):
			chunk.set_lod(new_lod)

		lod_level_changed.emit(chunk, current_lod, new_lod)


## Get a human-readable name for an LOD level
static func lod_level_name(lod: LODLevel) -> String:
	match lod:
		LODLevel.LOD0:
			return "LOD0 (Full Detail)"
		LODLevel.LOD1:
			return "LOD1 (Simplified)"
		LODLevel.LOD2:
			return "LOD2 (Silhouette)"
		LODLevel.LOD3:
			return "LOD3 (Impostor)"
	return "Unknown"
