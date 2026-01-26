class_name AEIDashboard
extends InfoPanel
## AEI (Arcology Excellence Index) Dashboard
## Shows overall score, components, and achievements
## Accessed via Y key
## See: documentation/ui/info-panels.md#aei-dashboard

# AEI Tier thresholds
const TIER_BRONZE := 80
const TIER_SILVER := 90
const TIER_GOLD := 95
const TIER_PLATINUM := 99

# Component weights (from documentation)
const WEIGHT_INDIVIDUAL := 0.40
const WEIGHT_COMMUNITY := 0.25
const WEIGHT_SUSTAINABILITY := 0.20
const WEIGHT_RESILIENCE := 0.15

# Cached UI elements
var _overall_score_label: Label
var _overall_bar: HBoxContainer
var _target_label: Label
var _component_bars: Dictionary = {}  # name -> {bar: HBoxContainer, label: Label}
var _achievements_container: VBoxContainer


func _init() -> void:
	super._init()


## Build the panel UI with AEI data
func setup(aei_data: Dictionary) -> void:
	clear()

	# Header section with close and help buttons
	var header_section := add_section("Header", "")

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "AEI DASHBOARD"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	# Help button
	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.flat = true
	help_btn.tooltip_text = "What is AEI?"
	help_btn.custom_minimum_size = Vector2(24, 24)
	help_btn.pressed.connect(func(): action_pressed.emit("help"))
	header_row.add_child(help_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.tooltip_text = "Close"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.pressed.connect(func(): close_requested.emit())
	header_row.add_child(close_btn)

	header_section.add_child(header_row)

	# Overall AEI section
	var overall_section := add_section("Overall", "OVERALL AEI")

	var overall_score: float = aei_data.get("overall", 0.0)

	# Large score display
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER

	_overall_score_label = Label.new()
	_overall_score_label.text = "%d" % int(overall_score)
	_overall_score_label.add_theme_font_size_override("font_size", 48)
	_overall_score_label.add_theme_color_override("font_color", _get_tier_color(overall_score))
	score_row.add_child(_overall_score_label)

	overall_section.add_child(score_row)

	# Overall progress bar
	_overall_bar = create_bar("", overall_score, 100.0, _get_tier_color(overall_score))
	# Remove label (we have the big number)
	if _overall_bar.get_child_count() > 0:
		_overall_bar.get_child(0).queue_free()
	overall_section.add_child(_overall_bar)

	# Target tier label
	var next_tier := _get_next_tier(overall_score)
	var points_needed := _get_points_to_tier(overall_score, next_tier)

	_target_label = Label.new()
	if points_needed > 0:
		_target_label.text = "Target: %d for %s (%d points away)" % [next_tier, _get_tier_name(next_tier), points_needed]
	else:
		_target_label.text = "Platinum achieved!"
	_target_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_target_label.add_theme_font_size_override("font_size", 12)
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overall_section.add_child(_target_label)

	# Components section
	var comp_section := add_section("Components", "COMPONENTS")

	var components: Dictionary = aei_data.get("components", {})

	# Individual Wellbeing (40%)
	var individual: float = components.get("individual", 0.0)
	_add_component(comp_section, "individual", "Individual Wellbeing", individual, WEIGHT_INDIVIDUAL,
		"Avg flourishing, needs met")

	# Community Cohesion (25%)
	var community: float = components.get("community", 0.0)
	_add_component(comp_section, "community", "Community Cohesion", community, WEIGHT_COMMUNITY,
		"Relationships, civic participation")

	# Sustainability (20%)
	var sustainability: float = components.get("sustainability", 0.0)
	_add_component(comp_section, "sustainability", "Sustainability", sustainability, WEIGHT_SUSTAINABILITY,
		"Resource efficiency, environment")

	# Resilience (15%)
	var resilience: float = components.get("resilience", 0.0)
	_add_component(comp_section, "resilience", "Resilience", resilience, WEIGHT_RESILIENCE,
		"Emergency readiness, diversity")

	# Achievements section
	var achievements_section := add_section("Achievements", "ACHIEVEMENTS")
	_achievements_container = achievements_section

	var achievements: Array = aei_data.get("achievements", [])
	if achievements.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No achievements yet"
		empty_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		achievements_section.add_child(empty_label)
	else:
		for achievement in achievements:
			_add_achievement(achievements_section, achievement)

	# Actions section
	var actions_section := add_section("Actions", "")

	var actions: Array[Dictionary] = [
		{"text": "Detailed Breakdown", "action": "breakdown", "tooltip": "See full AEI analysis"},
		{"text": "History", "action": "history", "tooltip": "View AEI over time"}
	]

	var action_bar := create_action_bar(actions)
	actions_section.add_child(action_bar)


## Add a component display
func _add_component(container: VBoxContainer, comp_name: String, title: String,
					value: float, weight: float, description: String) -> void:
	var comp_container := VBoxContainer.new()
	comp_container.add_theme_constant_override("separation", 2)

	# Title with weight
	var title_row := HBoxContainer.new()

	var title_label := Label.new()
	title_label.text = "%s (%d%%)" % [title, int(weight * 100)]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_label)

	var value_label := Label.new()
	value_label.text = "%d" % int(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", get_bar_color_by_value(value))
	title_row.add_child(value_label)

	comp_container.add_child(title_row)

	# Progress bar
	var bar := create_bar("", value, 100.0, get_bar_color_by_value(value))
	# Remove label
	if bar.get_child_count() > 0:
		bar.get_child(0).queue_free()
	comp_container.add_child(bar)

	# Description
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	comp_container.add_child(desc_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	comp_container.add_child(spacer)

	container.add_child(comp_container)

	# Cache for updates
	_component_bars[comp_name] = {
		"bar": bar,
		"label": value_label
	}


## Add an achievement row
func _add_achievement(container: VBoxContainer, achievement: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var completed: bool = achievement.get("completed", false)

	# Status icon
	var icon := Label.new()
	icon.text = "✓" if completed else "○"
	icon.custom_minimum_size = Vector2(20, 0)
	var icon_color := COLOR_TEXT_POSITIVE if completed else COLOR_TEXT_SECONDARY
	icon.add_theme_color_override("font_color", icon_color)
	row.add_child(icon)

	# Achievement text
	var text_label := Label.new()
	var text: String = achievement.get("name", "Unknown achievement")

	# Add progress if not completed
	if not completed:
		var progress: String = achievement.get("progress", "")
		if progress != "":
			text += " (%s)" % progress

	text_label.text = text
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text_color := COLOR_TEXT if completed else COLOR_TEXT_SECONDARY
	text_label.add_theme_color_override("font_color", text_color)
	row.add_child(text_label)

	container.add_child(row)


## Get color for tier based on score
func _get_tier_color(score: float) -> Color:
	if score >= TIER_PLATINUM:
		return Color("#e0e0e0")  # Platinum - silvery white
	elif score >= TIER_GOLD:
		return Color("#ffd700")  # Gold
	elif score >= TIER_SILVER:
		return Color("#c0c0c0")  # Silver
	elif score >= TIER_BRONZE:
		return Color("#cd7f32")  # Bronze
	else:
		return get_bar_color_by_value(score)


## Get tier name from threshold
func _get_tier_name(threshold: int) -> String:
	match threshold:
		TIER_PLATINUM:
			return "Platinum"
		TIER_GOLD:
			return "Gold"
		TIER_SILVER:
			return "Silver"
		TIER_BRONZE:
			return "Bronze"
	return "None"


## Get next tier threshold
func _get_next_tier(score: float) -> int:
	if score < TIER_BRONZE:
		return TIER_BRONZE
	elif score < TIER_SILVER:
		return TIER_SILVER
	elif score < TIER_GOLD:
		return TIER_GOLD
	elif score < TIER_PLATINUM:
		return TIER_PLATINUM
	return TIER_PLATINUM


## Get points needed to reach tier
func _get_points_to_tier(score: float, tier: int) -> int:
	var needed := tier - int(score)
	return maxi(0, needed)


## Update overall AEI score
func update_overall(score: float) -> void:
	if _overall_score_label:
		_overall_score_label.text = "%d" % int(score)
		_overall_score_label.add_theme_color_override("font_color", _get_tier_color(score))

	if _overall_bar:
		update_bar(_overall_bar, score, 100.0, _get_tier_color(score))

	if _target_label:
		var next_tier := _get_next_tier(score)
		var points_needed := _get_points_to_tier(score, next_tier)

		if points_needed > 0:
			_target_label.text = "Target: %d for %s (%d points away)" % [next_tier, _get_tier_name(next_tier), points_needed]
		else:
			_target_label.text = "Platinum achieved!"


## Update a component score
func update_component(comp_name: String, value: float) -> void:
	if _component_bars.has(comp_name):
		var data: Dictionary = _component_bars[comp_name]
		var bar: HBoxContainer = data.get("bar")
		var label: Label = data.get("label")

		if bar:
			update_bar(bar, value, 100.0, get_bar_color_by_value(value))

		if label:
			label.text = "%d" % int(value)
			label.add_theme_color_override("font_color", get_bar_color_by_value(value))


## Update all components
func update_components(components: Dictionary) -> void:
	for comp_name in components:
		update_component(comp_name, components[comp_name])


## Add a new achievement
func add_achievement(achievement: Dictionary) -> void:
	if _achievements_container:
		# Remove "No achievements yet" label if present
		for child in _achievements_container.get_children():
			if child is Label and "No achievements" in child.text:
				child.queue_free()
				break

		_add_achievement(_achievements_container, achievement)


## Mark an achievement as completed
func complete_achievement(achievement_name: String) -> void:
	if _achievements_container:
		for child in _achievements_container.get_children():
			if child is HBoxContainer and child.get_child_count() >= 2:
				var text_label := child.get_child(1) as Label
				if text_label and achievement_name in text_label.text:
					# Update icon
					var icon := child.get_child(0) as Label
					if icon:
						icon.text = "✓"
						icon.add_theme_color_override("font_color", COLOR_TEXT_POSITIVE)

					# Update text
					text_label.text = achievement_name
					text_label.add_theme_color_override("font_color", COLOR_TEXT)
					break
