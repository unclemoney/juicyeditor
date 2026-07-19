shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;
uniform float outline_smoothness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec4 color = texture(TEXTURE, UV);

	if (color.a == 0.0) {
		// Fixed 8-tap ring kernel: constant cost regardless of outline_width.
		// The old nested loop sampled (2*w+1)^2 texels per pixel (121 at
		// width 5), which could stall the GPU/driver on large controls.
		float alpha = 0.0;
		for (int i = 0; i < 8; i++) {
			float angle = float(i) * 0.78539816;  // TAU / 8
			vec2 offset = vec2(cos(angle), sin(angle)) * outline_width / size;
			alpha = max(alpha, texture(TEXTURE, UV + offset).a);
		}
		COLOR = vec4(outline_color.rgb, outline_color.a * alpha);
	} else {
		COLOR = color;
	}
}