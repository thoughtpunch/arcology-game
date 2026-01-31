class_name BlockInfoPanel
extends InfoPanel
## Info panel displayed when a block is selected
## Shows header, occupants, environment bars, economics, and actions
## See: documentation/ui/info-panels.md#block-info-panel

# Cached UI elements for updates
var _header_title: Label
var _header_subtitle: Label
var _header_status: Label
var _sprite_rect: TextureRect
var _occupants_container: VBoxContainer
var _env_bars: Dictionary = {}  # name -> HBoxContainer
var _econ_rows: Dictionary = {}  # name -> HBoxContainer

# Current block data
var _block_position: Vector3i
var _block_type: String


func _init() -> void:
	super._init()


## Build the panel UI for a block
func setup(block_pos: Vector3i, block_type: String, block_data: Dictionary = {}) -> void:
	clear()
	_block_position = block_pos
	_block_type = block_type

	# Get block definition from registry or use provided data
	var definition := block_data
	if definition.is_empty():
		var registry := _get_block_registry()
		if registry:
			definition = registry.get_definition(block_type)

	# Header section
	var header_section := add_section("Header", "")

	# Create header with sprite
	var sprite_path: String = definition.get(
		"sprite", "res://assets/sprites/blocks/placeholder.png"
	)
	var texture: Texture2D = null
	if ResourceLoader.exists(sprite_path):
		texture = load(sprite_path)

	var block_name: String = definition.get("name", block_type.capitalize())
	var position_str := "Floor %d, Pos (%d, %d)" % [block_pos.z, block_pos.x, block_pos.y]

	var header := create_header(texture, block_name, position_str, true, true)
	header_section.add_child(header)

	# Status label (below subtitle)
	var status: String = block_data.get("status", "Vacant")
	var status_row := create_stat_row("Status", status, get_status_color(status))
	status_row.name = "StatusRow"
	header_section.add_child(status_row)

	# Occupants section (only for residential blocks)
	var category: String = definition.get("category", "")
	if category == "residential":
		var occ_section := add_section("Occupants", "OCCUPANTS", true)
		_occupants_container = occ_section

		var occupants: Array = block_data.get("occupants", [])
		if occupants.is_empty():
			var empty_label := Label.new()
			empty_label.text = "No occupants"
			empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
			occ_section.add_child(empty_label)
		else:
			for occupant in occupants:
				_add_occupant_row(occ_section, occupant)

	# Environment section
	var env_section := add_section("Environment", "ENVIRONMENT", true)

	var env_data: Dictionary = block_data.get("environment", {})
	var light_val: float = env_data.get("light", 50.0)
	var air_val: float = env_data.get("air", 50.0)
	var noise_val: float = env_data.get("noise", 50.0)
	var safety_val: float = env_data.get("safety", 50.0)
	var vibes_val: float = env_data.get("vibes", 50.0)

	_env_bars["light"] = create_bar("Light", light_val, 100.0, get_bar_color_by_value(light_val))
	_env_bars["air"] = create_bar("Air", air_val, 100.0, get_bar_color_by_value(air_val))
	# Noise is inverted (lower is better)
	_env_bars["noise"] = create_bar(
		"Noise", noise_val, 100.0, get_bar_color_by_value(100.0 - noise_val)
	)
	_env_bars["safety"] = create_bar(
		"Safety", safety_val, 100.0, get_bar_color_by_value(safety_val)
	)
	_env_bars["vibes"] = create_bar("Vibes", vibes_val, 100.0, get_bar_color_by_value(vibes_val))

	for bar in _env_bars.values():
		env_section.add_child(bar)

	# Economics section
	var econ_section := add_section("Economics", "ECONOMICS", true)

	var econ_data: Dictionary = block_data.get("economics", {})
	var rent: int = econ_data.get("rent", 0)
	var desirability: float = econ_data.get("desirability", 0.0)
	var maintenance: int = econ_data.get("maintenance", 0)
	var net_income: int = rent - maintenance

	_econ_rows["rent"] = create_stat_row("Rent", format_money(rent) + "/month")
	_econ_rows["desirability"] = create_stat_row("Desirability", "%.2f" % desirability)
	_econ_rows["maintenance"] = create_stat_row("Maintenance", format_money(maintenance) + "/month")

	var net_color := COLOR_TEXT_POSITIVE if net_income >= 0 else COLOR_TEXT_NEGATIVE
	_econ_rows["net_income"] = create_stat_row(
		"Net Income", format_money(net_income) + "/month", net_color
	)

	for row in _econ_rows.values():
		econ_section.add_child(row)

	# Actions section
	var actions_section := add_section("Actions", "ACTIONS")

	var actions: Array[Dictionary] = [
		{"text": "Upgrade", "action": "upgrade", "tooltip": "Upgrade this block"},
		{"text": "Demolish", "action": "demolish", "tooltip": "Remove this block"},
		{"text": "Details", "action": "details", "tooltip": "View detailed info"}
	]

	var action_bar := create_action_bar(actions)
	actions_section.add_child(action_bar)


## Add an occupant row to the occupants section
func _add_occupant_row(container: VBoxContainer, occupant: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Portrait placeholder
	var portrait := ColorRect.new()
	portrait.custom_minimum_size = Vector2(24, 24)
	portrait.color = Color("#4ecdc4")
	row.add_child(portrait)

	# Info
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = occupant.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 12)
	info.add_child(name_label)

	var flourishing: int = occupant.get("flourishing", 0)
	var flour_label := Label.new()
	flour_label.text = "Flourishing: %d" % flourishing
	flour_label.add_theme_font_size_override("font_size", 10)
	flour_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	info.add_child(flour_label)

	row.add_child(info)
	container.add_child(row)


## Update environment bars with new values
func update_environment(env_data: Dictionary) -> void:
	if env_data.has("light"):
		var val: float = env_data.get("light")
		update_bar(_env_bars.get("light"), val, 100.0, get_bar_color_by_value(val))

	if env_data.has("air"):
		var val: float = env_data.get("air")
		update_bar(_env_bars.get("air"), val, 100.0, get_bar_color_by_value(val))

	if env_data.has("noise"):
		var val: float = env_data.get("noise")
		update_bar(_env_bars.get("noise"), val, 100.0, get_bar_color_by_value(100.0 - val))

	if env_data.has("safety"):
		var val: float = env_data.get("safety")
		update_bar(_env_bars.get("safety"), val, 100.0, get_bar_color_by_value(val))

	if env_data.has("vibes"):
		var val: float = env_data.get("vibes")
		update_bar(_env_bars.get("vibes"), val, 100.0, get_bar_color_by_value(val))


## Update economics with new values
func update_economics(econ_data: Dictionary) -> void:
	if _econ_rows.has("rent") and econ_data.has("rent"):
		var row := _econ_rows.get("rent") as HBoxContainer
		if row and row.get_child_count() >= 2:
			var label := row.get_child(1) as Label
			if label:
				label.text = format_money(econ_data.get("rent")) + "/month"

	if _econ_rows.has("desirability") and econ_data.has("desirability"):
		var row := _econ_rows.get("desirability") as HBoxContainer
		if row and row.get_child_count() >= 2:
			var label := row.get_child(1) as Label
			if label:
				label.text = "%.2f" % econ_data.get("desirability")

	if _econ_rows.has("maintenance") and econ_data.has("maintenance"):
		var row := _econ_rows.get("maintenance") as HBoxContainer
		if row and row.get_child_count() >= 2:
			var label := row.get_child(1) as Label
			if label:
				label.text = format_money(econ_data.get("maintenance")) + "/month"

	# Update net income
	if _econ_rows.has("net_income"):
		var rent: int = econ_data.get("rent", 0)
		var maintenance: int = econ_data.get("maintenance", 0)
		var net_income: int = rent - maintenance

		var row := _econ_rows.get("net_income") as HBoxContainer
		if row and row.get_child_count() >= 2:
			var label := row.get_child(1) as Label
			if label:
				label.text = format_money(net_income) + "/month"
				var color := COLOR_TEXT_POSITIVE if net_income >= 0 else COLOR_TEXT_NEGATIVE
				label.add_theme_color_override("font_color", color)


## Get the block position this panel is showing
func get_block_position() -> Vector3i:
	return _block_position


## Get the block type this panel is showing
func get_block_type() -> String:
	return _block_type


## Helper to get block registry
func _get_block_registry() -> Node:
	var tree := get_tree()
	if tree:
		return tree.get_root().get_node_or_null("/root/BlockRegistry")
	return null
