shader_type canvas_item;

uniform float wave_strength : hint_range(0.0, 0.1) = 0.03;
uniform float wave_speed : hint_range(0.0, 15.0) = 1.2;
uniform float outline_size : hint_range(0.0, 4.0) = 2.5;
uniform float shimmer_width : hint_range(0.0, 0.3) = 0.15;
uniform float glow_base : hint_range(0.0, 1.0) = 0.35;

vec3 rainbow(float t) {
	return vec3(
		0.5 + 0.5 * sin(6.28318 * (t + 0.0)),
		0.5 + 0.5 * sin(6.28318 * (t + 0.33)),
		0.5 + 0.5 * sin(6.28318 * (t + 0.66))
	);
}

void fragment() {
	vec2 uv = UV;

	uv.y += sin((uv.x * 10.0) + TIME * wave_speed) * wave_strength;
	float alpha = texture(TEXTURE, uv).a;
	float outline = 0.0;
	float off_scale = outline_size / 100.0;
	for (int dx = -2; dx <= 2; dx++) {
		for (int dy = -2; dy <= 2; dy++) {
			vec2 off = vec2(float(dx), float(dy)) * off_scale;
			outline = max(outline, texture(TEXTURE, uv + off).a);
		}
	}
	outline = clamp(outline, 0.0, 1.0);

	vec3 base_color = rainbow(uv.y * 0.6 + TIME * 0.15);
	float shimmer_center = fract(TIME * 0.25);
	float shimmer = smoothstep(0.0, 1.0, 1.0 - abs(uv.x - shimmer_center) / shimmer_width);
	shimmer *= 0.6;
	float pulse = 0.5 + 0.5 * sin(TIME * 2.5);
	float glow_strength = glow_base * pulse;

	vec3 fill = base_color + shimmer * vec3(1.0);
	vec3 outline_color = mix(vec3(0.02, 0.02, 0.05), fill, 0.4);
	vec3 color = mix(outline_color, fill, alpha);
	float final_alpha = max(alpha, outline * 0.6);
	float glow = smoothstep(0.0, 1.0, final_alpha + glow_strength * alpha);

	COLOR = vec4(color, final_alpha) * glow;
}
