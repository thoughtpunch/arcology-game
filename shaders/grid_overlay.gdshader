shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float cell_size = 6.0;
uniform vec4 line_color : source_color = vec4(0.0, 0.8, 0.8, 0.6);
uniform float line_width = 0.04;

void fragment() {
	// World-space position from vertex
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Grid lines on XZ plane at cell_size intervals
	vec2 grid_uv = world_pos.xz / cell_size;
	vec2 grid_frac = fract(grid_uv);
	vec2 dist_to_line = min(grid_frac, 1.0 - grid_frac);

	// Anti-aliased lines using fwidth
	vec2 fw = fwidth(grid_uv);
	vec2 aa_line = smoothstep(vec2(0.0), fw * 1.5, dist_to_line - line_width);
	float line_factor = 1.0 - min(aa_line.x, aa_line.y);

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * line_factor;
}
