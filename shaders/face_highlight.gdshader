shader_type spatial;
render_mode unshaded, cull_disabled;

const vec3 CYAN = vec3(0.0, 0.9, 0.9);
const float FILL_ALPHA = 0.15;
const float EDGE_ALPHA = 0.6;
const float PULSE_SPEED = 4.2; // ~1.5s cycle
const float PULSE_MIN = 0.8;

void fragment() {
	// Cell border edge lines via UV
	vec2 edge_dist = min(UV, 1.0 - UV);
	float edge_width = fwidth(UV.x) * 2.0 + 0.02;
	float edge = 1.0 - smoothstep(0.0, edge_width, min(edge_dist.x, edge_dist.y));

	float alpha = mix(FILL_ALPHA, EDGE_ALPHA, edge);

	// Gentle sine pulse on overall alpha
	float pulse = mix(PULSE_MIN, 1.0, (sin(TIME * PULSE_SPEED) * 0.5 + 0.5));
	alpha *= pulse;

	ALBEDO = CYAN;
	ALPHA = alpha;
}
