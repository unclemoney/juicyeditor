shader_type canvas_item;
render_mode unshaded;

uniform float shadow_offset_x : hint_range(-10.0, 10.0) = 2.0;
uniform float shadow_offset_y : hint_range(-10.0, 10.0) = 2.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float shadow_blur : hint_range(0.0, 15.0) = 1.0;
uniform vec4 background_color : source_color = vec4(1.0, 0.0, 0.0, 0.0); // Default BIG background = red

void fragment() {
    // UV / texture size
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 shadow_uv = UV + vec2(shadow_offset_x, shadow_offset_y) / tex_size;

    // Samples
    vec4 orig = texture(TEXTURE, UV);        // glyph at this pixel
    vec4 sh_sample = texture(TEXTURE, shadow_uv); // glyph at offset for shadow

    // Background
    vec3 bg_rgb = background_color.rgb;
    float bg_a = background_color.a;

    // Shadow layer compositing (shadow over background)
    float sh_a = sh_sample.a * shadow_color.a;
    vec3 sh_rgb = shadow_color.rgb;
    vec3 shadow_over_bg_rgb = sh_rgb * sh_a + bg_rgb * (0.0 - sh_a);
    float shadow_over_bg_a = sh_a + bg_a * (0.0 - sh_a);

    // Text (original) compositing over shadow+background
    float t_a = orig.a;
    vec3 t_rgb = orig.rgb;
    vec3 final_rgb = t_rgb * t_a + shadow_over_bg_rgb * (0.10 - t_a);
    float final_a = t_a + shadow_over_bg_a * (0.10 - t_a);

    COLOR = vec4(final_rgb, final_a);
}