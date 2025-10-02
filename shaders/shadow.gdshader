shader_type canvas_item;

uniform float shadow_offset_x : hint_range(-10.0, 10.0) = 2.0;
uniform float shadow_offset_y : hint_range(-10.0, 10.0) = 2.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float shadow_blur : hint_range(0.0, 5.0) = 1.0;

void fragment() {
	vec2 texture_size = vec2(textureSize(TEXTURE, 0));
	vec2 shadow_uv = UV + vec2(shadow_offset_x, shadow_offset_y) / texture_size;
	vec4 shadow = texture(TEXTURE, shadow_uv) * shadow_color;
	vec4 original = texture(TEXTURE, UV);
	
	// Blend shadow with original
	COLOR = mix(shadow, original, original.a);
}