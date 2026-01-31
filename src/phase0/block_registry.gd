## Holds all block definitions for Phase 0 sandbox.
## Loads from data/blocks.json and assigns greybox colors by category.

const BlockDefScript = preload("res://src/phase0/block_definition.gd")

var _definitions: Dictionary = {}

# Explicit ordering for the palette UI, grouped by category.
var palette_order: Array[String] = []

# Category display order
var _category_order: Array[String] = [
	"transit", "residential", "commercial", "industrial",
	"civic", "infrastructure", "green", "entertainment",
]

# Greybox colors per category
var _category_colors: Dictionary = {
	"transit": Color(0.45, 0.55, 0.7),
	"residential": Color(0.45, 0.65, 0.45),
	"commercial": Color(0.75, 0.6, 0.35),
	"industrial": Color(0.55, 0.5, 0.45),
	"civic": Color(0.6, 0.5, 0.65),
	"infrastructure": Color(0.5, 0.55, 0.6),
	"green": Color(0.35, 0.6, 0.35),
	"entertainment": Color(0.7, 0.5, 0.55),
}

# Override colors for specific block IDs
var _id_color_overrides: Dictionary = {
	"entrance": Color(0.85, 0.72, 0.2),
}


func _init() -> void:
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open("res://data/blocks.json", FileAccess.READ)
	if not file:
		push_error("[BlockRegistry] Failed to open data/blocks.json")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("[BlockRegistry] JSON parse error: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data

	# Build definitions grouped by category so palette_order is organized.
	# First pass: create all definitions keyed by id.
	var by_category: Dictionary = {}  # category -> Array[String] of ids
	for id in data:
		var entry: Dictionary = data[id]
		var def: Resource = BlockDefScript.new()
		def.id = id
		def.display_name = entry.get("name", id)
		var s: Array = entry.get("size", [1, 1, 1])
		def.size = Vector3i(int(s[0]), int(s[1]), int(s[2]))
		def.category = entry.get("category", "")
		def.traversability = entry.get("traversability", "")
		def.ground_only = entry.get("ground_only", false)
		def.connects_horizontal = entry.get("connects_horizontal", false)
		def.connects_vertical = entry.get("connects_vertical", false)
		def.capacity = int(entry.get("capacity", 0))
		def.jobs = int(entry.get("jobs", 0))

		# Assign color: id override > category color > fallback grey
		if _id_color_overrides.has(id):
			def.color = _id_color_overrides[id]
		elif _category_colors.has(def.category):
			def.color = _category_colors[def.category]
		else:
			def.color = Color(0.6, 0.6, 0.6)

		_definitions[id] = def

		if not by_category.has(def.category):
			by_category[def.category] = []
		by_category[def.category].append(id)

	# Build palette_order following _category_order
	for cat in _category_order:
		if by_category.has(cat):
			for id in by_category[cat]:
				palette_order.append(id)


func get_definition(id: String) -> Resource:
	return _definitions.get(id)


func get_all_definitions() -> Array:
	var result: Array = []
	for id in palette_order:
		if _definitions.has(id):
			result.append(_definitions[id])
	return result


func get_categories() -> Array[String]:
	var result: Array[String] = []
	for cat in _category_order:
		# Only include categories that have blocks
		for id in palette_order:
			if _definitions.has(id) and _definitions[id].category == cat:
				result.append(cat)
				break
	return result


func get_definitions_for_category(cat: String) -> Array:
	var result: Array = []
	for id in palette_order:
		if _definitions.has(id) and _definitions[id].category == cat:
			result.append(_definitions[id])
	return result


func get_category_color(cat: String) -> Color:
	return _category_colors.get(cat, Color(0.6, 0.6, 0.6))


func get_category_display_name(cat: String) -> String:
	match cat:
		"transit": return "Transit"
		"residential": return "Residential"
		"commercial": return "Commercial"
		"industrial": return "Industrial"
		"civic": return "Civic"
		"infrastructure": return "Infra"
		"green": return "Green"
		"entertainment": return "Entertainment"
		_: return cat.capitalize()
