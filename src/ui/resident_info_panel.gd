class_name ResidentInfoPanel
extends InfoPanel
## Info panel displayed when a resident is selected
## Shows flourishing score, needs breakdown, activity, relationships, employment
## See: documentation/ui/info-panels.md#resident-info-panel

# Need satisfaction symbols
const NEED_SATISFIED := "✓"     # >70%
const NEED_PARTIAL := "~"       # 40-70%
const NEED_UNMET := "✗"         # <40%

const NEED_COLOR_SATISFIED := Color("#4ecdc4")
const NEED_COLOR_PARTIAL := Color("#f9ca24")
const NEED_COLOR_UNMET := Color("#e94560")

# Cached UI elements
var _flourishing_bar: HBoxContainer
var _need_bars: Dictionary = {}  # name -> HBoxContainer
var _relationships_container: VBoxContainer
var _activity_label: Label
var _next_activity_label: Label

# Current resident data
var _resident_id: String
var _is_notable: bool = true


func _init() -> void:
	super._init()


## Build the panel UI for a resident
func setup(resident_id: String, resident_data: Dictionary) -> void:
	clear()
	_resident_id = resident_id
	_is_notable = resident_data.get("is_notable", true)

	if _is_notable:
		_setup_notable_resident(resident_data)
	else:
		_setup_statistical_resident(resident_data)


## Setup panel for a notable (fully simulated) resident
func _setup_notable_resident(data: Dictionary) -> void:
	# Header section
	var header_section := add_section("Header", "")

	# Create header with portrait
	var name_str: String = data.get("name", "Unknown Resident")
	var age: int = data.get("age", 0)
	var residence_years: int = data.get("residence_years", 0)
	var residence_str: String = "%d year%s" % [residence_years, "s" if residence_years != 1 else ""]
	var location: String = data.get("location", "Unknown")

	var subtitle := "Age: %d | Resident: %s" % [age, residence_str]

	# Portrait texture (placeholder for now)
	var portrait_texture: Texture2D = null
	var portrait_path: String = data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_texture = load(portrait_path)

	var header := create_header(portrait_texture, name_str, subtitle, true, true)
	header_section.add_child(header)

	# Location row
	var location_row := create_stat_row("Location", location)
	header_section.add_child(location_row)

	# Flourishing section
	var flour_section := add_section("Flourishing", "FLOURISHING")

	var flourishing: float = data.get("flourishing", 0.0)
	var trend: String = data.get("flourishing_trend", "stable")
	var trend_symbol := _get_trend_symbol(trend)

	var flour_row := HBoxContainer.new()
	flour_row.add_theme_constant_override("separation", 8)

	var flour_label := Label.new()
	flour_label.text = "Flourishing"
	flour_label.custom_minimum_size = Vector2(100, 0)
	flour_row.add_child(flour_label)

	_flourishing_bar = create_bar("", flourishing, 100.0, get_bar_color_by_value(flourishing))
	# Remove the label from bar (we have our own)
	if _flourishing_bar.get_child_count() > 0:
		_flourishing_bar.get_child(0).queue_free()
	flour_row.add_child(_flourishing_bar)

	var trend_label := Label.new()
	trend_label.text = "%d %s" % [int(flourishing), trend_symbol]
	trend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	trend_label.custom_minimum_size = Vector2(50, 0)
	flour_row.add_child(trend_label)

	flour_section.add_child(flour_row)

	# Needs section
	var needs_section := add_section("Needs", "NEEDS", true)

	var needs: Dictionary = data.get("needs", {})
	var survival: float = needs.get("survival", 50.0)
	var safety: float = needs.get("safety", 50.0)
	var belonging: float = needs.get("belonging", 50.0)
	var esteem: float = needs.get("esteem", 50.0)
	var purpose: float = needs.get("purpose", 50.0)

	_need_bars["survival"] = _create_need_bar("Survival", survival)
	_need_bars["safety"] = _create_need_bar("Safety", safety)
	_need_bars["belonging"] = _create_need_bar("Belonging", belonging)
	_need_bars["esteem"] = _create_need_bar("Esteem", esteem)
	_need_bars["purpose"] = _create_need_bar("Purpose", purpose)

	for bar in _need_bars.values():
		needs_section.add_child(bar)

	# Current activity section
	var activity_section := add_section("Activity", "CURRENT ACTIVITY")

	var activity: String = data.get("current_activity", "Idle")
	var next_activity: String = data.get("next_activity", "Unknown")
	var next_time: String = data.get("next_time", "")

	_activity_label = Label.new()
	_activity_label.text = activity
	_activity_label.add_theme_color_override("font_color", COLOR_TEXT)
	activity_section.add_child(_activity_label)

	_next_activity_label = Label.new()
	if next_time != "":
		_next_activity_label.text = "Next: %s (%s)" % [next_activity, next_time]
	else:
		_next_activity_label.text = "Next: %s" % next_activity
	_next_activity_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_next_activity_label.add_theme_font_size_override("font_size", 12)
	activity_section.add_child(_next_activity_label)

	# Relationships section
	var rel_section := add_section("Relationships", "RELATIONSHIPS", true)
	_relationships_container = rel_section

	var relationships: Array = data.get("relationships", [])
	if relationships.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No relationships"
		empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		rel_section.add_child(empty_label)
	else:
		for rel in relationships:
			_add_relationship_row(rel_section, rel)

	# Employment section
	var emp_section := add_section("Employment", "EMPLOYMENT")

	var employment: Dictionary = data.get("employment", {})
	var job_title: String = employment.get("title", "Unemployed")
	var workplace: String = employment.get("workplace", "")
	var income: int = employment.get("income", 0)

	var job_label := Label.new()
	if workplace != "":
		job_label.text = "%s (%s)" % [workplace, job_title]
	else:
		job_label.text = job_title
	emp_section.add_child(job_label)

	if income > 0:
		var income_row := create_stat_row("Income", format_money(income) + "/mo", COLOR_TEXT_POSITIVE)
		emp_section.add_child(income_row)

	# Actions section
	var actions_section := add_section("Actions", "ACTIONS")

	var actions: Array[Dictionary] = [
		{"text": "Follow", "action": "follow", "tooltip": "Follow this resident"},
		{"text": "History", "action": "history", "tooltip": "View life history"},
		{"text": "Complaints", "action": "complaints", "tooltip": "View complaints"}
	]

	var action_bar := create_action_bar(actions)
	actions_section.add_child(action_bar)


## Setup panel for a statistical (aggregated) resident
func _setup_statistical_resident(data: Dictionary) -> void:
	# Header section
	var header_section := add_section("Header", "STATISTICAL RESIDENT")

	var count: int = data.get("similar_count", 1)
	var info_label := Label.new()
	info_label.text = "Generic Resident\n(1 of ~%s similar)" % format_number(count)
	info_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	header_section.add_child(info_label)

	# Aggregate stats section
	var stats_section := add_section("AggregateStats", "AGGREGATE STATS")

	var avg_flourishing: float = data.get("avg_flourishing", 0.0)
	var avg_rent: int = data.get("avg_rent", 0)
	var common_complaints: Array = data.get("common_complaints", [])

	var flour_row := create_stat_row("Avg Flourishing", "%d" % int(avg_flourishing))
	stats_section.add_child(flour_row)

	var rent_row := create_stat_row("Avg Rent Paid", format_money(avg_rent) + "/mo")
	stats_section.add_child(rent_row)

	if not common_complaints.is_empty():
		var complaints_str := ", ".join(common_complaints)
		var complaints_row := create_stat_row("Common Complaints", complaints_str)
		stats_section.add_child(complaints_row)


## Create a need bar with satisfaction symbol
func _create_need_bar(label_text: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Label
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)

	# Progress bar
	var bar_color := get_bar_color_by_value(value)
	var bar := create_bar("", value, 100.0, bar_color)
	# Remove the label from the bar
	if bar.get_child_count() > 0:
		bar.get_child(0).queue_free()
	row.add_child(bar)

	# Satisfaction symbol
	var symbol := _get_satisfaction_symbol(value)
	var symbol_color := _get_satisfaction_color(value)

	var symbol_label := Label.new()
	symbol_label.text = symbol
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.custom_minimum_size = Vector2(20, 0)
	symbol_label.add_theme_color_override("font_color", symbol_color)
	row.add_child(symbol_label)

	return row


## Get satisfaction symbol based on value
func _get_satisfaction_symbol(value: float) -> String:
	if value >= 70.0:
		return NEED_SATISFIED
	elif value >= 40.0:
		return NEED_PARTIAL
	else:
		return NEED_UNMET


## Get satisfaction color based on value
func _get_satisfaction_color(value: float) -> Color:
	if value >= 70.0:
		return NEED_COLOR_SATISFIED
	elif value >= 40.0:
		return NEED_COLOR_PARTIAL
	else:
		return NEED_COLOR_UNMET


## Get trend symbol
func _get_trend_symbol(trend: String) -> String:
	match trend.to_lower():
		"up", "rising", "improving":
			return "▲"
		"down", "falling", "declining":
			return "▼"
		_:
			return "●"


## Add a relationship row
func _add_relationship_row(container: VBoxContainer, relationship: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := Label.new()
	icon.text = "👤"
	icon.custom_minimum_size = Vector2(20, 0)
	row.add_child(icon)

	var name_label := Label.new()
	var name_str: String = relationship.get("name", "Unknown")
	var rel_type: String = relationship.get("type", "Acquaintance")
	name_label.text = "%s - %s" % [name_str, rel_type]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	container.add_child(row)


## Update needs with new values
func update_needs(needs: Dictionary) -> void:
	for need_name in needs:
		if _need_bars.has(need_name):
			var value: float = needs[need_name]
			var bar := _need_bars[need_name] as HBoxContainer

			# Update bar color and fill
			if bar and bar.get_child_count() >= 2:
				var bar_container := bar.get_child(1) as HBoxContainer
				if bar_container:
					update_bar(bar_container, value, 100.0, get_bar_color_by_value(value))

				# Update symbol
				if bar.get_child_count() >= 3:
					var symbol_label := bar.get_child(2) as Label
					if symbol_label:
						symbol_label.text = _get_satisfaction_symbol(value)
						symbol_label.add_theme_color_override("font_color", _get_satisfaction_color(value))


## Update flourishing score
func update_flourishing(value: float, trend: String = "stable") -> void:
	if _flourishing_bar:
		update_bar(_flourishing_bar, value, 100.0, get_bar_color_by_value(value))


## Update current activity
func update_activity(activity: String, next_activity: String = "", next_time: String = "") -> void:
	if _activity_label:
		_activity_label.text = activity

	if _next_activity_label:
		if next_time != "":
			_next_activity_label.text = "Next: %s (%s)" % [next_activity, next_time]
		else:
			_next_activity_label.text = "Next: %s" % next_activity


## Get the resident ID this panel is showing
func get_resident_id() -> String:
	return _resident_id


## Check if showing a notable resident
func is_notable_resident() -> bool:
	return _is_notable
