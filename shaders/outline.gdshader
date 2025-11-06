shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;
uniform float outline_smoothness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec4 color = texture(TEXTURE, UV);

	if (color.a == 0.0) {
		float alpha = 0.0;
		for (float x = -outline_width; x <= outline_width; x += 1.0) {
			for (float y = -outline_width; y <= outline_width; y += 1.0) {
				vec2 offset = vec2(x, y) / size;
				alpha = max(alpha, texture(TEXTURE, UV + offset).a);
			}
		}
		COLOR = vec4(outline_color.rgb, outline_color.a * alpha);
	} else {
		COLOR = color;
	}
}