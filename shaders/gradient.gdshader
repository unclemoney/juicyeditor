shader_type canvas_item;

uniform vec4 start_color : source_color = vec4(0.91, 0.91, 0.1, 1.0);
uniform vec4 end_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform float gradient_direction_x : hint_range(-1.0, 1.0) = 0.0;
uniform float gradient_direction_y : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
	vec2 normalized_uv = UV;
	vec2 gradient_direction = vec2(gradient_direction_x, gradient_direction_y);
	float gradient_factor = dot(normalized_uv, normalize(gradient_direction));
	gradient_factor = clamp(gradient_factor, 0.0, 1.0);
	
	COLOR = mix(start_color, end_color, gradient_factor);
}