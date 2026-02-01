shader_type spatial;

// Block material shader with visibility mode support
// Supports cutaway, x-ray, and other visibility modes

// Global shader parameters (set by VisibilityController)
global uniform int visibility_mode;  // 0=normal, 1=cutaway, 2=xray, 3=isolate, 4=section
global uniform float cut_height;     // Y coordinate of cut plane
global uniform vec3 section_plane_normal;   // Normal of section plane (horizontal)
global uniform float section_plane_offset;  // Distance from origin along normal
global uniform float xray_opacity;   // X-ray exterior transparency (0.0 = invisible, 1.0 = opaque)

// Instance parameters (per-block)
uniform vec4 albedo_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

// Exterior flag for X-ray mode (1.0 = exterior surface, 0.0 = interior)
uniform float is_exterior : hint_range(0.0, 1.0) = 0.0;

// Selection/state effects
uniform bool emission_enabled = false;
uniform vec4 emission_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float emission_energy = 0.3;

// Transparency for ghost preview
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform bool is_ghost = false;

// Cutaway fade margin (smooth transition at cut edge)
const float CUT_FADE_MARGIN = 0.5;  // World units to fade over


// Get world position from vertex
varying vec3 world_position;


void vertex() {
    // Calculate world position
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
    // Start with base albedo
    vec4 color = albedo_color;
    float final_alpha = alpha;

    // Apply visibility mode
    if (visibility_mode == 1) {
        // CUTAWAY mode: discard geometry above cut height
        if (world_position.y > cut_height) {
            discard;
        }

        // Optional: fade near cut plane for softer edge
        float dist_to_cut = cut_height - world_position.y;
        if (dist_to_cut < CUT_FADE_MARGIN && dist_to_cut > 0.0) {
            // Slight darkening near cut edge to indicate slice
            float fade = dist_to_cut / CUT_FADE_MARGIN;
            color.rgb *= mix(0.7, 1.0, fade);
        }
    }
    else if (visibility_mode == 2) {
        // XRAY mode: exterior surfaces become transparent
        // is_exterior is set per-instance by the game logic
        if (is_exterior > 0.5) {
            final_alpha = xray_opacity;
        }
        // Interior meshes (is_exterior = 0) remain fully opaque
    }
    else if (visibility_mode == 3) {
        // ISOLATE mode: placeholder for future implementation
        // Would need floor number comparison
    }
    else if (visibility_mode == 4) {
        // SECTION mode: vertical slice along a plane defined by normal + offset
        float dist = dot(world_position, section_plane_normal) - section_plane_offset;
        if (dist > 0.0) {
            discard;
        }
        // Fade near section edge for softer visual
        if (dist > -CUT_FADE_MARGIN) {
            float fade = -dist / CUT_FADE_MARGIN;
            color.rgb *= mix(0.7, 1.0, fade);
        }
    }

    // Apply final color
    ALBEDO = color.rgb;
    ROUGHNESS = roughness;
    METALLIC = metallic;

    // Apply transparency
    if (final_alpha < 1.0 || is_ghost) {
        ALPHA = final_alpha;
    }

    // Apply emission for selection/state effects
    if (emission_enabled) {
        EMISSION = emission_color.rgb * emission_energy;
    }
}
