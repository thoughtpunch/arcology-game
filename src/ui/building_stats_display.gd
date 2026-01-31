class_name BuildingStatsDisplay
extends HBoxContainer
## Compact always-visible building stats display for the main HUD.
## Shows height, volume, and footprint of the current arcology.
## Updates reactively when blocks are placed or removed.

const COLOR_LABEL := Color(0.75, 0.8, 0.85, 0.7)
const COLOR_VALUE := Color(1.0, 1.0, 1.0, 0.9)
const FONT_SIZE := 13

var _height_value: Label
var _volume_value: Label
var _footprint_value: Label

var _grid: Node  # Grid instance


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	add_theme_constant_override("separation", 4)

	_add_stat("H:", "HeightValue")
	_height_value = get_node("HeightValue")

	_add_separator()

	_add_stat("V:", "VolumeValue")
	_volume_value = get_node("VolumeValue")

	_add_separator()

	_add_stat("FP:", "FootprintValue")
	_footprint_value = get_node("FootprintValue")

	# Start hidden until we have data
	visible = false


func _add_stat(label_text: String, value_name: String) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	lbl.add_theme_color_override("font_color", COLOR_LABEL)
	add_child(lbl)

	var val := Label.new()
	val.text = "0"
	val.name = value_name
	val.add_theme_font_size_override("font_size", FONT_SIZE)
	val.add_theme_color_override("font_color", COLOR_VALUE)
	val.custom_minimum_size = Vector2(24, 0)
	add_child(val)


func _add_separator() -> void:
	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_font_size_override("font_size", FONT_SIZE)
	sep.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.5))
	add_child(sep)


## Connect to a Grid instance for reactive updates
func connect_to_grid(grid: Node) -> void:
	_grid = grid
	if grid:
		grid.block_added.connect(_on_block_changed)
		grid.block_removed.connect(_on_block_removed)
		# Initial update
		update_stats_from_grid()


func _on_block_changed(_pos: Vector3i, _block) -> void:
	update_stats_from_grid()


func _on_block_removed(_pos: Vector3i) -> void:
	update_stats_from_grid()


## Update display from current grid state
func update_stats_from_grid() -> void:
	if not _grid:
		update_stats(0, 0, 0)
		return
	var stats: Dictionary = _grid.get_building_stats()
	update_stats(stats.get("height", 0), stats.get("volume", 0), stats.get("footprint", 0))


## Update the display with specific values
func update_stats(height: int, volume: int, footprint: int) -> void:
	var has_blocks := volume > 0
	visible = has_blocks

	if _height_value:
		_height_value.text = str(height)
	if _volume_value:
		_volume_value.text = str(volume)
	if _footprint_value:
		_footprint_value.text = str(footprint)
