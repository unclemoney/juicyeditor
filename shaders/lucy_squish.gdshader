shader_type canvas_item;

// Squish and bounce animation parameters
uniform float squish_amount : hint_range(0.0, 1.0) = 0.0;
uniform float bounce_offset : hint_range(-1.0, 1.0) = 0.0;
uniform vec2 squish_direction = vec2(1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	
	// Center the UV coordinates for proper scaling
	vec2 centered_uv = uv - vec2(0.5);
	
	// Apply squish effect (compress vertically, expand horizontally or vice versa)
	float horizontal_scale = 1.0 + (squish_amount * (1.0 - squish_direction.x));
	float vertical_scale = 1.0 - (squish_amount * squish_direction.y);
	
	centered_uv.x /= horizontal_scale;
	centered_uv.y /= vertical_scale;
	
	// Apply bounce offset (vertical translation)
	centered_uv.y -= bounce_offset * 0.1;
	
	// Return to normal UV space
	vec2 final_uv = centered_uv + vec2(0.5);
	
	// Sample the texture with the modified UVs
	if (final_uv.x >= 0.0 && final_uv.x <= 1.0 && final_uv.y >= 0.0 && final_uv.y <= 1.0) {
		COLOR = texture(TEXTURE, final_uv);
	} else {
		COLOR = vec4(0.0); // Transparent outside bounds
	}
}
