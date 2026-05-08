shader_type canvas_item;

// Noise-based dissolve with a glowing golden edge — fits the alchemy aesthetic.
// dissolve_amount = 0.0 → fully opaque overlay; 1.0 → fully dissolved/invisible.
uniform float dissolve_amount: hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color: source_color = vec4(1.0, 0.65, 0.1, 1.0);
uniform float edge_width: hint_range(0.0, 0.15) = 0.06;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += smooth_noise(uv) * amp;
		uv *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	float noise_val = fbm(UV * 6.0);
	float alpha = step(dissolve_amount, noise_val);
	float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, noise_val);
	COLOR.rgb = mix(edge_color.rgb, COLOR.rgb, edge);
	COLOR.a = alpha;
}
