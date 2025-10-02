extends Node
#class_name VisualEffectsManager

# Juicy Editor - Visual Effects Manager
# Handles visual effects like shadows, outlines, gradients, and animations

signal effects_updated

@export var enable_text_shadows: bool = true
@export var enable_outline_effects: bool = true
@export var enable_gradient_backgrounds: bool = false
@export var enable_particle_effects: bool = true

var text_shadow_material: ShaderMaterial
var outline_material: ShaderMaterial
var gradient_material: ShaderMaterial

# Effect configurations
var text_shadow_config: Dictionary = {
	"enabled": true,
	"color": Color(0, 0, 0, 0.5),
	"offset": Vector2(2, 2),
	"blur_radius": 1.0
}

var outline_config: Dictionary = {
	"enabled": true,
	"color": Color(1, 1, 1, 0.8),
	"width": 1.0,
	"smoothness": 0.1
}

var gradient_config: Dictionary = {
	"enabled": false,
	"start_color": Color(0.1, 0.1, 0.1, 1.0),
	"end_color": Color(0.05, 0.05, 0.05, 1.0),
	"direction": Vector2(0, 1)
}

func _ready() -> void:
	_initialize_materials()

func _initialize_materials() -> void:
	# Create shader materials for various effects
	_create_text_shadow_material()
	_create_outline_material()
	_create_gradient_material()

func _create_text_shadow_material() -> void:
	# Create a simple text shadow shader
	var shader_code = """
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
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	text_shadow_material = ShaderMaterial.new()
	text_shadow_material.shader = shader
	_update_text_shadow_material()

func _create_outline_material() -> void:
	# Create an outline shader
	var shader_code = """
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
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	outline_material = ShaderMaterial.new()
	outline_material.shader = shader
	_update_outline_material()

func _create_gradient_material() -> void:
	# Create a gradient background shader
	var shader_code = """
shader_type canvas_item;

uniform vec4 start_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
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
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	gradient_material = ShaderMaterial.new()
	gradient_material.shader = shader
	_update_gradient_material()

func _update_text_shadow_material() -> void:
	if text_shadow_material and text_shadow_material.shader:
		text_shadow_material.set_shader_parameter("shadow_offset_x", text_shadow_config.offset.x)
		text_shadow_material.set_shader_parameter("shadow_offset_y", text_shadow_config.offset.y)
		text_shadow_material.set_shader_parameter("shadow_color", text_shadow_config.color)
		text_shadow_material.set_shader_parameter("shadow_blur", text_shadow_config.blur_radius)

func _update_outline_material() -> void:
	if outline_material and outline_material.shader:
		outline_material.set_shader_parameter("outline_color", outline_config.color)
		outline_material.set_shader_parameter("outline_width", outline_config.width)
		outline_material.set_shader_parameter("outline_smoothness", outline_config.smoothness)

func _update_gradient_material() -> void:
	if gradient_material and gradient_material.shader:
		gradient_material.set_shader_parameter("start_color", gradient_config.start_color)
		gradient_material.set_shader_parameter("end_color", gradient_config.end_color)
		gradient_material.set_shader_parameter("gradient_direction_x", gradient_config.direction.x)
		gradient_material.set_shader_parameter("gradient_direction_y", gradient_config.direction.y)

func apply_text_shadow(control: Control, enabled: bool = true) -> void:
	if not control:
		return
	
	if enabled and enable_text_shadows and text_shadow_config.enabled:
		control.material = text_shadow_material
	else:
		control.material = null

func apply_outline(control: Control, enabled: bool = true) -> void:
	if not control:
		return
	
	if enabled and enable_outline_effects and outline_config.enabled:
		control.material = outline_material
	else:
		control.material = null

func apply_gradient_background(control: Control, enabled: bool = true) -> void:
	if not control:
		return
	
	if enabled and enable_gradient_backgrounds and gradient_config.enabled:
		control.material = gradient_material
	else:
		control.material = null

func configure_text_shadow(color: Color, offset: Vector2, blur: float) -> void:
	text_shadow_config.color = color
	text_shadow_config.offset = offset
	text_shadow_config.blur_radius = blur
	_update_text_shadow_material()
	effects_updated.emit()

func configure_outline(color: Color, width: float, smoothness: float) -> void:
	outline_config.color = color
	outline_config.width = width
	outline_config.smoothness = smoothness
	_update_outline_material()
	effects_updated.emit()

func configure_gradient(start_color: Color, end_color: Color, direction: Vector2) -> void:
	gradient_config.start_color = start_color
	gradient_config.end_color = end_color
	gradient_config.direction = direction
	_update_gradient_material()
	effects_updated.emit()

func enable_effect(effect_name: String, enabled: bool) -> void:
	match effect_name:
		"text_shadow":
			text_shadow_config.enabled = enabled
		"outline":
			outline_config.enabled = enabled
		"gradient":
			gradient_config.enabled = enabled
	
	effects_updated.emit()

func get_effect_config(effect_name: String) -> Dictionary:
	match effect_name:
		"text_shadow":
			return text_shadow_config
		"outline":
			return outline_config
		"gradient":
			return gradient_config
		_:
			return {}

func apply_theme_effects(theme_config: Dictionary) -> void:
	# Apply effects based on theme configuration
	if "text_shadow" in theme_config:
		var shadow_config = theme_config.text_shadow
		configure_text_shadow(
			shadow_config.get("color", Color.BLACK),
			shadow_config.get("offset", Vector2(2, 2)),
			shadow_config.get("blur", 1.0)
		)
		enable_effect("text_shadow", shadow_config.get("enabled", false))
	
	if "outline" in theme_config:
		var outline_cfg = theme_config.outline
		configure_outline(
			outline_cfg.get("color", Color.WHITE),
			outline_cfg.get("width", 1.0),
			outline_cfg.get("smoothness", 0.1)
		)
		enable_effect("outline", outline_cfg.get("enabled", false))
	
	if "gradient" in theme_config:
		var gradient_cfg = theme_config.gradient
		configure_gradient(
			gradient_cfg.get("start_color", Color(0.1, 0.1, 0.1)),
			gradient_cfg.get("end_color", Color(0.05, 0.05, 0.05)),
			gradient_cfg.get("direction", Vector2(0, 1))
		)
		enable_effect("gradient", gradient_cfg.get("enabled", false))

func create_pulse_effect(control: Control, duration: float = 0.3, intensity: float = 1.2) -> void:
	if not control:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale up then back down
	tween.tween_property(control, "scale", Vector2.ONE * intensity, duration * 0.5)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.5)

func create_glow_effect(control: Control, glow_color: Color = Color.CYAN, duration: float = 1.0) -> void:
	if not control:
		return
	
	# Create a simple glow by modulating the control's color
	var original_modulate = control.modulate
	var tween = create_tween()
	tween.set_loops()
	
	var glow_modulate = Color(
		original_modulate.r + glow_color.r * 0.3,
		original_modulate.g + glow_color.g * 0.3,
		original_modulate.b + glow_color.b * 0.3,
		original_modulate.a
	)
	
	tween.tween_property(control, "modulate", glow_modulate, duration * 0.5)
	tween.tween_property(control, "modulate", original_modulate, duration * 0.5)

func stop_glow_effect(control: Control) -> void:
	if not control:
		return
	
	# Reset modulate to normal
	control.modulate = Color.WHITE