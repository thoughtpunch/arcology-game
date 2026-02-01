extends RefCounted

## LOD (Level of Detail) Manager
##
## Manages level of detail for blocks based on camera distance.
## 4 LOD levels with configurable thresholds:
##   LOD0 (0-50m): Full detail, interior visible
##   LOD1 (50-150m): Simplified exterior, no interior
##   LOD2 (150-400m): Block silhouette only
##   LOD3 (400m+): Merged impostors (simplified box)
##
## Usage:
##   const LODManagerScript = preload("res://src/game/lod_manager.gd")
##   var lod_manager = LODManagerScript.new()
##   lod_manager.set_camera(camera_node)
##   lod_manager.register_block(block_id, block_node, world_position)
##   # In _process():
##   lod_manager.update()

# --- LOD Level Constants ---
enum LODLevel { LOD0 = 0, LOD1 = 1, LOD2 = 2, LOD3 = 3 }

# --- Default Thresholds (meters) ---
const DEFAULT_LOD0_MAX: float = 50.0   # 0-50m: Full detail
const DEFAULT_LOD1_MAX: float = 150.0  # 50-150m: Simplified
const DEFAULT_LOD2_MAX: float = 400.0  # 150-400m: Silhouette
# Beyond LOD2_MAX: LOD3 (impostors)

# --- Hysteresis to prevent rapid LOD switching ---
const HYSTERESIS: float = 5.0  # Buffer zone in meters

# --- Configurable thresholds ---
var lod0_max: float = DEFAULT_LOD0_MAX
var lod1_max: float = DEFAULT_LOD1_MAX
var lod2_max: float = DEFAULT_LOD2_MAX

# --- State ---
var _camera: Node3D = null
var _enabled: bool = false
var _blocks: Dictionary = {}  # block_id -> { node: Node3D, position: Vector3, current_lod: int }

# --- Signals ---
signal lod_changed(block_id: int, old_lod: int, new_lod: int)


func _init() -> void:
	pass


func set_camera(camera: Node3D) -> void:
	## Set the camera used for distance calculations.
	_camera = camera


func enable() -> void:
	## Enable LOD processing.
	_enabled = true


func disable() -> void:
	## Disable LOD processing (all blocks remain at current LOD).
	_enabled = false


func is_enabled() -> bool:
	return _enabled


func set_thresholds(lod0: float, lod1: float, lod2: float) -> void:
	## Configure LOD distance thresholds.
	## lod0: max distance for LOD0 (full detail)
	## lod1: max distance for LOD1 (simplified)
	## lod2: max distance for LOD2 (silhouette)
	## Beyond lod2: LOD3 (impostors)
	lod0_max = lod0
	lod1_max = lod1
	lod2_max = lod2


func get_thresholds() -> Dictionary:
	## Get current LOD thresholds.
	return {
		"lod0_max": lod0_max,
		"lod1_max": lod1_max,
		"lod2_max": lod2_max,
	}


func register_block(block_id: int, block_node: Node3D, world_position: Vector3) -> void:
	## Register a block for LOD management.
	## block_node: The root Node3D of the block (contains MeshInstance3D child)
	## world_position: World-space center position of the block
	_blocks[block_id] = {
		"node": block_node,
		"position": world_position,
		"current_lod": LODLevel.LOD0,
	}


func unregister_block(block_id: int) -> void:
	## Remove a block from LOD management.
	_blocks.erase(block_id)


func get_block_lod(block_id: int) -> int:
	## Get the current LOD level for a block.
	## Returns -1 if block not registered.
	if _blocks.has(block_id):
		return _blocks[block_id]["current_lod"]
	return -1


func get_registered_count() -> int:
	## Get the number of registered blocks.
	return _blocks.size()


func update() -> void:
	## Update LOD for all registered blocks based on camera distance.
	## Call this in _process() or at a desired frequency.
	if not _enabled or _camera == null:
		return

	# Use global_position if in scene tree, otherwise fall back to position
	var camera_pos: Vector3
	if _camera.is_inside_tree():
		camera_pos = _camera.global_position
	else:
		camera_pos = _camera.position

	for block_id in _blocks:
		var data: Dictionary = _blocks[block_id]
		var block_pos: Vector3 = data["position"]
		var current_lod: int = data["current_lod"]

		var distance: float = camera_pos.distance_to(block_pos)
		var new_lod: int = _get_lod_for_distance(distance, current_lod)

		if new_lod != current_lod:
			_apply_lod(block_id, data, new_lod)
			data["current_lod"] = new_lod
			lod_changed.emit(block_id, current_lod, new_lod)


func _get_lod_for_distance(distance: float, current_lod: int) -> int:
	## Determine LOD level for a given distance.
	## Uses hysteresis based on current LOD to prevent rapid switching.

	# Apply hysteresis: when moving away, require passing threshold + hysteresis
	# when moving closer, require passing threshold - hysteresis
	var h := HYSTERESIS

	match current_lod:
		LODLevel.LOD0:
			# Currently LOD0, check if should move to LOD1
			if distance > lod0_max + h:
				if distance > lod1_max + h:
					if distance > lod2_max + h:
						return LODLevel.LOD3
					return LODLevel.LOD2
				return LODLevel.LOD1
			return LODLevel.LOD0

		LODLevel.LOD1:
			# Currently LOD1
			if distance < lod0_max - h:
				return LODLevel.LOD0
			if distance > lod1_max + h:
				if distance > lod2_max + h:
					return LODLevel.LOD3
				return LODLevel.LOD2
			return LODLevel.LOD1

		LODLevel.LOD2:
			# Currently LOD2
			if distance < lod1_max - h:
				if distance < lod0_max - h:
					return LODLevel.LOD0
				return LODLevel.LOD1
			if distance > lod2_max + h:
				return LODLevel.LOD3
			return LODLevel.LOD2

		LODLevel.LOD3:
			# Currently LOD3
			if distance < lod2_max - h:
				if distance < lod1_max - h:
					if distance < lod0_max - h:
						return LODLevel.LOD0
					return LODLevel.LOD1
				return LODLevel.LOD2
			return LODLevel.LOD3

	# Fallback: determine without hysteresis
	if distance <= lod0_max:
		return LODLevel.LOD0
	elif distance <= lod1_max:
		return LODLevel.LOD1
	elif distance <= lod2_max:
		return LODLevel.LOD2
	else:
		return LODLevel.LOD3


func _apply_lod(block_id: int, data: Dictionary, new_lod: int) -> void:
	## Apply visual changes for a LOD transition.
	var node: Node3D = data["node"]
	if not is_instance_valid(node):
		return

	# Get the MeshInstance3D (first child of block node)
	var mesh_instance: MeshInstance3D = null
	if node.get_child_count() > 0 and node.get_child(0) is MeshInstance3D:
		mesh_instance = node.get_child(0) as MeshInstance3D

	if mesh_instance == null:
		return

	# Apply LOD-specific visibility and detail
	match new_lod:
		LODLevel.LOD0:
			# Full detail: show everything
			_set_node_visibility(node, "Panels", true)
			_set_node_visibility(node, "Interiors", true)
			mesh_instance.visible = true

		LODLevel.LOD1:
			# Simplified: hide interiors, keep panels
			_set_node_visibility(node, "Panels", true)
			_set_node_visibility(node, "Interiors", false)
			mesh_instance.visible = true

		LODLevel.LOD2:
			# Silhouette: hide panels and interiors, keep core mesh
			_set_node_visibility(node, "Panels", false)
			_set_node_visibility(node, "Interiors", false)
			mesh_instance.visible = true

		LODLevel.LOD3:
			# Impostor: simplified rendering (same as LOD2 for now)
			# Future: could merge multiple blocks into single mesh
			_set_node_visibility(node, "Panels", false)
			_set_node_visibility(node, "Interiors", false)
			mesh_instance.visible = true


func _set_node_visibility(parent: Node3D, child_name: String, visible: bool) -> void:
	## Set visibility of a named child node.
	var child: Node3D = parent.get_node_or_null(child_name)
	if child:
		child.visible = visible


func force_lod(block_id: int, lod_level: int) -> void:
	## Force a specific LOD level for a block (ignores distance).
	## Useful for debugging or cutaway views.
	if not _blocks.has(block_id):
		return

	var data: Dictionary = _blocks[block_id]
	var current_lod: int = data["current_lod"]

	if lod_level != current_lod:
		_apply_lod(block_id, data, lod_level)
		data["current_lod"] = lod_level
		lod_changed.emit(block_id, current_lod, lod_level)


func get_lod_stats() -> Dictionary:
	## Get statistics about current LOD distribution.
	## Returns count of blocks at each LOD level.
	var stats := {
		"lod0": 0,
		"lod1": 0,
		"lod2": 0,
		"lod3": 0,
		"total": _blocks.size(),
	}

	for block_id in _blocks:
		var lod: int = _blocks[block_id]["current_lod"]
		match lod:
			LODLevel.LOD0:
				stats["lod0"] += 1
			LODLevel.LOD1:
				stats["lod1"] += 1
			LODLevel.LOD2:
				stats["lod2"] += 1
			LODLevel.LOD3:
				stats["lod3"] += 1

	return stats


func update_block_position(block_id: int, new_position: Vector3) -> void:
	## Update the stored position for a block.
	## Call this if a block moves (rare in Arcology).
	if _blocks.has(block_id):
		_blocks[block_id]["position"] = new_position
