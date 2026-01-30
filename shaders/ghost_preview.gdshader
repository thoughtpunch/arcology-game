shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, unshaded;

uniform bool is_valid = true;

// Cyan (valid) vs red (invalid)
const vec3 CYAN = vec3(0.0, 0.9, 0.9);
const vec3 RED = vec3(0.9, 0.15, 0.1);

const float FILL_ALPHA = 0.12;
const float EDGE_ALPHA = 0.7;
const float FRESNEL_POWER = 2.5;

void fragment() {
	vec3 color = is_valid ? CYAN : RED;

	// Fresnel edge glow: brighter on silhouette edges
	float fresnel = 1.0 - abs(dot(NORMAL, VIEW));
	fresnel = pow(fresnel, FRESNEL_POWER);

	// World-space cell-boundary edge detection
	// Highlight edges where any world-space coordinate is near a cell boundary
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float cell_size = 6.0;
	vec3 cell_frac = fract(world_pos / cell_size);
	vec3 edge_dist = min(cell_frac, 1.0 - cell_frac);
	float edge_width = 0.04;
	vec3 edge_aa = smoothstep(vec3(0.0), vec3(edge_width), edge_dist);
	float edge_factor = 1.0 - min(edge_aa.x, min(edge_aa.y, edge_aa.z));

	float alpha = mix(FILL_ALPHA, EDGE_ALPHA, max(fresnel, edge_factor));

	ALBEDO = color;
	ALPHA = alpha;
}
