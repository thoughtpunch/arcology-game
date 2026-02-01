class_name ScenarioConfig
extends Resource

## Data-driven scenario configuration resource.
##
## Defines physics, environment, structural rules, and game mode
## for each game session. Loaded from JSON files in data/scenarios/.
##
## See documentation/ideas_not_implemented/scenario-config.md for full spec.

const BASE_CANTILEVER: int = 2
const JSON_PATH_PREFIX: String = "res://data/scenarios/"

# --- Physics & Structure ---

## Gravity multiplier (0.0 = zero-g, 0.16 = lunar, 1.0 = Earth)
@export var gravity: float = 1.0

## Max unsupported horizontal extension in cells.
## Computed from gravity: floor(BASE_CANTILEVER / gravity), infinite at zero-g.
## -1 = unlimited (zero-g).
@export var max_cantilever: int = 2

## Vertical build limit in cells. -1 = unlimited.
@export var max_build_height: int = -1

## Whether blocks need structural support at all.
@export var structural_integrity: bool = true

# --- Environment ---

## Real-time minutes per full day cycle. 0 = static time (no auto-advance).
@export var day_length_minutes: float = 0.0

## Starting hour (0.0 - 24.0).
@export var default_time_of_day: float = 8.0

## Base sun intensity.
@export var sun_energy: float = 1.0

## Base ambient light intensity.
@export var ambient_energy: float = 0.3

# --- Build Zone ---

## Origin of the build zone (grid coordinates).
@export var build_zone_origin: Vector2i = Vector2i(-50, -50)

## Size of the build zone (grid cells).
@export var build_zone_size: Vector2i = Vector2i(100, 100)

## Layers of diggable ground below Z=0.
@export var ground_depth: int = 3

## Terrain preset ("earth", "mars", "lunar", "space_platform").
@export var ground_type: String = "earth"

# --- Game Mode ---

## Game mode: "sandbox", "scenario", "custom".
@export var mode: String = "sandbox"


## Calculate max_cantilever from gravity.
## Returns -1 for zero-g (unlimited).
static func calculate_cantilever(grav: float) -> int:
	if grav <= 0.0:
		return -1  # Zero-g: unlimited
	return int(floor(float(BASE_CANTILEVER) / grav))


## Check if a cantilever distance is within limits.
## Always returns true if max_cantilever is -1 (unlimited).
func is_within_cantilever_limit(distance: int) -> bool:
	if max_cantilever < 0:
		return true  # Unlimited
	return distance <= max_cantilever


## Check if a build height is within limits.
## Always returns true if max_build_height is -1 (unlimited).
func is_within_build_height(y_level: int) -> bool:
	if max_build_height < 0:
		return true  # Unlimited
	return y_level <= max_build_height


## Check if a position is within the build zone (horizontal only: X and Z).
func is_in_build_zone(pos: Vector3i) -> bool:
	var min_x: int = build_zone_origin.x
	var min_z: int = build_zone_origin.y  # build_zone_origin.y maps to Z axis
	var max_x: int = build_zone_origin.x + build_zone_size.x
	var max_z: int = build_zone_origin.y + build_zone_size.y
	return pos.x >= min_x and pos.x < max_x and pos.z >= min_z and pos.z < max_z


## Check if a Y level is within underground limits.
func is_within_ground_depth(y_level: int) -> bool:
	return y_level >= -ground_depth


## Get the real-time seconds per game hour from day_length_minutes.
## Returns 0.0 if day cycle is disabled (static time).
func get_seconds_per_hour() -> float:
	if day_length_minutes <= 0.0:
		return 0.0
	return (day_length_minutes * 60.0) / 24.0


## Load a ScenarioConfig from a JSON file.
## Returns null if the file doesn't exist or can't be parsed.
static func load_from_json(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		push_warning("ScenarioConfig: File not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("ScenarioConfig: Failed to open: %s" % path)
		return null

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("ScenarioConfig: Parse error in %s: %s" % [path, json.get_error_message()])
		return null

	var data: Dictionary = json.get_data()
	return from_dict(data)


## Load a named scenario from data/scenarios/<name>.json.
static func load_scenario(scenario_name: String) -> Resource:
	var path := JSON_PATH_PREFIX + scenario_name + ".json"
	return load_from_json(path)


## Create a ScenarioConfig from a Dictionary.
static func from_dict(data: Dictionary) -> Resource:
	var script = load("res://src/game/structural_scenario_config.gd")
	var config = script.new()

	# Physics & Structure
	config.gravity = data.get("gravity", 1.0)
	config.structural_integrity = data.get("structural_integrity", true)
	config.max_build_height = data.get("max_build_height", -1)

	# Cantilever: use explicit value if provided, otherwise compute from gravity
	if data.has("max_cantilever"):
		config.max_cantilever = data.get("max_cantilever", 2)
	else:
		config.max_cantilever = calculate_cantilever(config.gravity)

	# Environment
	config.day_length_minutes = data.get("day_length_minutes", 0.0)
	config.default_time_of_day = data.get("default_time_of_day", 8.0)
	config.sun_energy = data.get("sun_energy", 1.0)
	config.ambient_energy = data.get("ambient_energy", 0.3)

	# Build Zone
	var origin: Variant = data.get("build_zone_origin", null)
	if origin is Array and origin.size() >= 2:
		config.build_zone_origin = Vector2i(int(origin[0]), int(origin[1]))
	elif origin is Dictionary:
		config.build_zone_origin = Vector2i(int(origin.get("x", -50)), int(origin.get("y", -50)))

	var bz_size: Variant = data.get("build_zone_size", null)
	if bz_size is Array and bz_size.size() >= 2:
		config.build_zone_size = Vector2i(int(bz_size[0]), int(bz_size[1]))
	elif bz_size is Dictionary:
		config.build_zone_size = Vector2i(int(bz_size.get("x", 100)), int(bz_size.get("y", 100)))

	config.ground_depth = data.get("ground_depth", 3)
	config.ground_type = data.get("ground_type", "earth")

	# Game Mode
	config.mode = data.get("mode", "sandbox")

	return config


## Serialize to Dictionary (for saving/sharing).
func to_dict() -> Dictionary:
	return {
		"gravity": gravity,
		"max_cantilever": max_cantilever,
		"max_build_height": max_build_height,
		"structural_integrity": structural_integrity,
		"day_length_minutes": day_length_minutes,
		"default_time_of_day": default_time_of_day,
		"sun_energy": sun_energy,
		"ambient_energy": ambient_energy,
		"build_zone_origin": [build_zone_origin.x, build_zone_origin.y],
		"build_zone_size": [build_zone_size.x, build_zone_size.y],
		"ground_depth": ground_depth,
		"ground_type": ground_type,
		"mode": mode
	}


## Create a default Earth scenario config.
static func create_default() -> Resource:
	var script = load("res://src/game/structural_scenario_config.gd")
	return script.new()  # Defaults are already Earth-standard


## Get a human-readable summary of the config.
func get_summary() -> String:
	var gravity_name := "Earth"
	if gravity <= 0.0:
		gravity_name = "Zero-G"
	elif gravity <= 0.2:
		gravity_name = "Lunar"
	elif gravity <= 0.5:
		gravity_name = "Mars"
	elif gravity > 1.5:
		gravity_name = "High-G"

	var cantilever_str := "unlimited" if max_cantilever < 0 else str(max_cantilever)
	var height_str := "unlimited" if max_build_height < 0 else str(max_build_height)

	return (
		"Scenario: %s | Gravity: %.2f (%s) | Cantilever: %s | Height: %s | Terrain: %s"
		% [mode, gravity, gravity_name, cantilever_str, height_str, ground_type]
	)
