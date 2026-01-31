extends RefCounted

## Scenario configuration — holds all tunable parameters for a sandbox scenario.
## No class_name; loaded via preload like other Phase 0 scripts.
##
## Three factory methods provide built-in presets:
##   blank_slate()   — mountains + river, no city skyline
##   megastructure() — city skyline, no mountains/river (current default)
##   custom_default() — same as megastructure, id="custom"

enum SkylineType { NONE, CITY_BUILDINGS }

# --- Identity ---
var id: String = "megastructure"
var display_name: String = "Megastructure"
var description: String = ""

# --- Terrain ---
var ground_size: int = 100
var ground_depth: int = 5
var strata_colors: Array[Color] = [
	Color(0.3, 0.55, 0.2),   # y=-1: Grass/topsoil
	Color(0.55, 0.35, 0.2),  # y=-2: Soil
	Color(0.4, 0.25, 0.15),  # y=-3: Clay
	Color(0.5, 0.5, 0.5),    # y=-4: Rock
	Color(0.3, 0.3, 0.3),    # y=-5: Bedrock
]

# --- Build Zone ---
var build_zone_origin: Vector2i = Vector2i(40, 40)
var build_zone_size: Vector2i = Vector2i(20, 20)

# --- Skyline ---
var skyline_type: SkylineType = SkylineType.CITY_BUILDINGS
var skyline_seed: int = 42
var skyline_building_count: int = 300

# --- Mountains ---
var mountains_enabled: bool = false
var mountain_seed: int = 123
var mountain_count: int = 60
var mountain_min_height: float = 80.0
var mountain_max_height: float = 350.0
var mountain_min_radius: float = 30.0
var mountain_max_radius: float = 80.0
var mountain_base_color: Color = Color(0.25, 0.45, 0.2)
var mountain_peak_color: Color = Color(0.55, 0.6, 0.7)

# --- River ---
var river_enabled: bool = false
var river_width: float = 30.0
var river_color: Color = Color(0.2, 0.4, 0.65, 0.7)
var river_flow_angle: float = 30.0
var river_offset: float = 0.0  # Perpendicular offset from ground center (keeps river out of build zone)

# --- Sky ---
var sky_top_color: Color = Color(0.35, 0.55, 0.85)
var sky_horizon_color: Color = Color(0.6, 0.75, 0.9)
var ground_bottom_color: Color = Color(0.25, 0.35, 0.2)
var ground_horizon_color: Color = Color(0.55, 0.7, 0.5)

# --- Lighting ---
var sun_energy: float = 1.2
var ambient_energy: float = 0.5

# --- Fog ---
var fog_density: float = 0.001
var fog_color: Color = Color(0.55, 0.62, 0.72)


# --- Factory Methods ---

static func blank_slate() -> RefCounted:
	var cfg = new()
	cfg.id = "blank_slate"
	cfg.display_name = "Blank Slate"
	cfg.description = "Open terrain with distant mountains and a river. A pastoral canvas for your first structure."

	# Skyline
	cfg.skyline_type = SkylineType.NONE

	# Mountains
	cfg.mountains_enabled = true
	cfg.mountain_seed = 123
	cfg.mountain_count = 60
	cfg.mountain_min_height = 80.0
	cfg.mountain_max_height = 350.0
	cfg.mountain_min_radius = 30.0
	cfg.mountain_max_radius = 80.0

	# River
	cfg.river_enabled = true
	cfg.river_width = 30.0
	cfg.river_flow_angle = 30.0
	cfg.river_offset = 180.0  # Push river well outside the build zone

	# Slightly warmer sky
	cfg.sky_top_color = Color(0.4, 0.58, 0.82)
	cfg.sky_horizon_color = Color(0.65, 0.78, 0.88)
	cfg.ground_bottom_color = Color(0.28, 0.38, 0.22)
	cfg.ground_horizon_color = Color(0.58, 0.72, 0.52)

	# Lower fog so mountains are more visible
	cfg.fog_density = 0.0005
	cfg.fog_color = Color(0.58, 0.65, 0.72)

	return cfg


static func megastructure() -> RefCounted:
	var cfg = new()
	cfg.id = "megastructure"
	cfg.display_name = "Megastructure"
	cfg.description = "An urban sprawl surrounds your build site. 300 city buildings form the skyline."

	# Defaults match current hardcoded sandbox behavior
	cfg.skyline_type = SkylineType.CITY_BUILDINGS
	cfg.mountains_enabled = false
	cfg.river_enabled = false

	return cfg


static func custom_default() -> RefCounted:
	var cfg = megastructure()
	cfg.id = "custom"
	cfg.display_name = "Custom Game"
	cfg.description = "Tune every parameter to create your own scenario."
	return cfg
