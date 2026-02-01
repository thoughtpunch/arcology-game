class_name PerformanceMonitor
extends Node

## Tracks rendering performance metrics for the arcology.
##
## Collects FPS, frame time, and chunk/block statistics from the ChunkManager.
## Provides a formatted summary for debug overlays.
##
## Usage:
##   var monitor = PerformanceMonitor.new()
##   add_child(monitor)
##   monitor.set_chunk_manager(chunk_manager)

signal stats_updated(stats: Dictionary)

# Update interval (seconds between stat snapshots)
const UPDATE_INTERVAL: float = 0.5

# Chunk manager reference
var _chunk_manager: Node3D = null

# Timing — start at UPDATE_INTERVAL so first _process triggers an update immediately
var _update_timer: float = UPDATE_INTERVAL

# Rolling FPS average
var _fps_samples: Array[float] = []
const MAX_FPS_SAMPLES: int = 10

# Latest stats
var _current_stats: Dictionary = {}


func _ready() -> void:
	name = "PerformanceMonitor"


func _process(delta: float) -> void:
	# Track FPS
	var fps := 1.0 / maxf(delta, 0.001)
	_fps_samples.append(fps)
	if _fps_samples.size() > MAX_FPS_SAMPLES:
		_fps_samples.remove_at(0)

	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_stats(delta)


## Set the chunk manager to pull stats from
func set_chunk_manager(manager: Node3D) -> void:
	_chunk_manager = manager


## Force an immediate stats update (useful for testing)
func force_update() -> void:
	_update_stats(0.016)  # Approximate 60fps frame time


## Get the latest performance statistics
func get_stats() -> Dictionary:
	return _current_stats


## Get formatted stats string for debug overlay
func get_stats_text() -> String:
	var s := _current_stats
	if s.is_empty():
		return "No stats"

	var lines: Array[String] = []
	lines.append("FPS: %.0f (avg: %.0f)" % [s.get("fps", 0), s.get("fps_avg", 0)])
	lines.append("Frame: %.1fms" % [s.get("frame_ms", 0)])

	if _chunk_manager:
		lines.append("Blocks: %d" % s.get("total_blocks", 0))
		lines.append("Chunks: %d (vis: %d, cull: %d)" % [
			s.get("total_chunks", 0),
			s.get("visible_chunks", 0),
			s.get("culled_chunks", 0),
		])
		lines.append("Dirty: %d" % s.get("dirty_chunks", 0))

		var features: Array[String] = []
		if s.get("frustum_culling", false):
			features.append("frustum")
		if s.get("face_culling", false):
			features.append("face-cull")
		if s.get("instancing", false):
			features.append("instanced")
		if s.get("lod_enabled", false):
			features.append("LOD")
		if features.size() > 0:
			lines.append("Opt: %s" % ", ".join(features))

	return "\n".join(lines)


func _update_stats(delta: float) -> void:
	var fps := 1.0 / maxf(delta, 0.001)
	var fps_avg := 0.0
	if _fps_samples.size() > 0:
		for sample in _fps_samples:
			fps_avg += sample
		fps_avg /= _fps_samples.size()

	_current_stats = {
		"fps": fps,
		"fps_avg": fps_avg,
		"frame_ms": delta * 1000.0,
	}

	# Pull chunk manager stats if available
	if _chunk_manager and _chunk_manager.has_method("get_render_statistics"):
		var render_stats: Dictionary = _chunk_manager.get_render_statistics()
		_current_stats.merge(render_stats)

	stats_updated.emit(_current_stats)
