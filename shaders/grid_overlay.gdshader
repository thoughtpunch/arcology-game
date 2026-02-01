shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float cell_size = 6.0;
uniform vec4 line_color : source_color = vec4(0.0, 0.8, 0.8, 0.6);
uniform vec4 origin_x_color : source_color = vec4(1.0, 0.3, 0.3, 0.9);  // Red for X=0 axis
uniform vec4 origin_z_color : source_color = vec4(0.3, 0.3, 1.0, 0.9);  // Blue for Z=0 axis
uniform float line_width = 0.04;
uniform float origin_line_width = 0.08;  // Thicker origin axes

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

	// Check for origin axes (X=0 and Z=0)
	float dist_to_x_origin = abs(world_pos.x);
	float dist_to_z_origin = abs(world_pos.z);
	float origin_threshold = origin_line_width * cell_size;

	// Origin axis line factors (thicker, separate from grid)
	float x_origin_line = 1.0 - smoothstep(0.0, origin_threshold, dist_to_x_origin);
	float z_origin_line = 1.0 - smoothstep(0.0, origin_threshold, dist_to_z_origin);

	// Blend colors: origin axes override regular grid lines
	vec3 final_color = line_color.rgb;
	float final_alpha = line_color.a * line_factor;

	// Z=0 axis (runs along X direction) - blue
	if (z_origin_line > 0.01) {
		final_color = mix(final_color, origin_z_color.rgb, z_origin_line);
		final_alpha = max(final_alpha, origin_z_color.a * z_origin_line);
	}

	// X=0 axis (runs along Z direction) - red
	if (x_origin_line > 0.01) {
		final_color = mix(final_color, origin_x_color.rgb, x_origin_line);
		final_alpha = max(final_alpha, origin_x_color.a * x_origin_line);
	}

	ALBEDO = final_color;
	ALPHA = final_alpha;
}
