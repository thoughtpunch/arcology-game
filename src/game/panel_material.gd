## Panel material types for exterior block faces.
## Defines the 6 panel material types from the 3D refactor spec (Section 3.6).
## Each material has distinct visual properties applied via StandardMaterial3D.

enum Type {
	SOLID,       ## Concrete — matte, AO in crevices
	GLASS,       ## Framed panes — reflective, slight blue tint, transparency
	METAL,       ## Brushed panels — subtle reflection, visible seams
	SOLAR,       ## Grid of cells — dark blue, subtle glow
	GARDEN,      ## Organic foliage — green, subsurface scattering
	FORCE_FIELD, ## Energy shader — animated edge glow
}

## Default panel material per block category.
## Individual blocks can override via their definition.
const CATEGORY_DEFAULTS: Dictionary = {
	"transit": Type.SOLID,
	"residential": Type.SOLID,
	"commercial": Type.GLASS,
	"industrial": Type.METAL,
	"civic": Type.SOLID,
	"infrastructure": Type.METAL,
	"green": Type.GARDEN,
	"entertainment": Type.GLASS,
}

## Human-readable names for each panel material type.
const LABELS: Dictionary = {
	Type.SOLID: "Solid",
	Type.GLASS: "Glass",
	Type.METAL: "Metal",
	Type.SOLAR: "Solar",
	Type.GARDEN: "Garden",
	Type.FORCE_FIELD: "Force Field",
}

## Base material properties for each panel type.
## Used by PanelSystem to create StandardMaterial3D instances.
const MATERIAL_PROPS: Dictionary = {
	Type.SOLID: {
		"albedo_color": Color(0.65, 0.63, 0.60),
		"metallic": 0.0,
		"roughness": 0.85,
	},
	Type.GLASS: {
		"albedo_color": Color(0.7, 0.82, 0.92, 0.4),
		"metallic": 0.3,
		"roughness": 0.1,
		"transparency": true,
	},
	Type.METAL: {
		"albedo_color": Color(0.6, 0.62, 0.65),
		"metallic": 0.7,
		"roughness": 0.35,
	},
	Type.SOLAR: {
		"albedo_color": Color(0.12, 0.15, 0.35),
		"metallic": 0.5,
		"roughness": 0.2,
		"emission_color": Color(0.05, 0.1, 0.3),
		"emission_energy": 0.15,
	},
	Type.GARDEN: {
		"albedo_color": Color(0.3, 0.55, 0.25),
		"metallic": 0.0,
		"roughness": 0.9,
	},
	Type.FORCE_FIELD: {
		"albedo_color": Color(0.3, 0.6, 1.0, 0.3),
		"metallic": 0.0,
		"roughness": 0.0,
		"transparency": true,
		"emission_color": Color(0.2, 0.5, 1.0),
		"emission_energy": 0.8,
	},
}


static func get_label(mat_type: int) -> String:
	return LABELS.get(mat_type, "Unknown")


static func get_default_for_category(category: String) -> int:
	return CATEGORY_DEFAULTS.get(category, Type.SOLID)


static func create_material(mat_type: int, block_color: Color) -> StandardMaterial3D:
	## Create a StandardMaterial3D for a panel face.
	## The block_color is blended with the panel material properties
	## so blocks retain their category color identity while gaining
	## distinct face material characteristics.
	var props: Dictionary = MATERIAL_PROPS.get(mat_type, MATERIAL_PROPS[Type.SOLID])
	var mat := StandardMaterial3D.new()

	# Blend block color with panel material color (60% block, 40% panel)
	var panel_color: Color = props.get("albedo_color", Color.WHITE)
	var blended := block_color.lerp(panel_color, 0.4)

	# Preserve alpha from panel material (for glass/force field)
	if props.get("transparency", false):
		blended.a = panel_color.a
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	mat.albedo_color = blended
	mat.metallic = props.get("metallic", 0.0)
	mat.roughness = props.get("roughness", 0.5)

	# Emission (for selection glow support)
	mat.emission_enabled = true
	var emit_color: Color = props.get("emission_color", Color.WHITE)
	mat.emission = emit_color
	mat.emission_energy_multiplier = props.get("emission_energy", 0.0)

	return mat
