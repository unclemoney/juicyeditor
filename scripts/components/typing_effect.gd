extends Node2D
class_name TypingEffect

# Juicy Editor - Typing Effect Component (Juiced Up)
# Creates big, punchy animated effects when typing characters
# Uses TweenFX for all animations

@export var effect_duration: float = 1.2
@export var fade_duration: float = 0.4
@export var scale_bounce: float = 1.5
@export var color_randomization: bool = true
@export var particle_effects: bool = true
@export var use_sprites: bool = true

# Enhanced animation properties
@export var min_scale: float = 1.2
@export var max_scale: float = 2.5
@export var combo_threshold: int = 15
@export var rhythm_detection: bool = true

# Juice controls
@export var effect_intensity: float = 1.0

var character_typed: String = ""
var destroy_on_complete: bool = true

# Animation state tracking - static to share across instances
static var typing_combo_count: int = 0
static var last_char_time: float = 0.0
static var rhythm_intervals: Array[float] = []
var animation_type: String = "normal"

signal tier_detected(tier: String)

@onready var label: Label
@onready var animated_sprite: AnimatedSprite2D
@onready var particles: GPUParticles2D
@onready var audio_player: AudioStreamPlayer2D
@onready var cleanup_timer: Timer

# Shader materials
var outline_material: ShaderMaterial
var rainbow_material: ShaderMaterial

# Sprite resources
var sparkle_textures: Array[Texture2D] = []
var glow_textures: Array[Texture2D] = []
var combo_textures: Array[Texture2D] = []
var rhythm_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_sprite_resources()
	_setup_shaders()
	_setup_components()
	_start_effect()

func reset_for_pool() -> void:
	"""Reset all state for object pool reuse"""
	TweenFX.stop_all(self)
	if label:
		label.scale = Vector2.ONE
		label.modulate = Color.WHITE
		label.rotation = 0.0
		label.material = outline_material
	if animated_sprite:
		animated_sprite.visible = false
		animated_sprite.scale = Vector2.ONE
		animated_sprite.modulate = Color.WHITE
		animated_sprite.rotation = 0.0
	if particles:
		particles.emitting = false
		particles.visible = false
	animation_type = "normal"
	character_typed = ""

func _load_sprite_resources() -> void:
	for i in range(1, 5):
		var texture_path = "res://effects/sprites/typing/sparkle_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				sparkle_textures.append(texture)
	
	for i in range(1, 9):
		var texture_path = "res://effects/sprites/typing/glow_ring_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				glow_textures.append(texture)
	
	var combo_files = ["combo_2x.png", "combo_3x.png", "combo_text.png", "combo_boom.png"]
	for file_name in combo_files:
		var texture_path = "res://effects/sprites/special/" + file_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				combo_textures.append(texture)
	
	var rhythm_files = ["rythm_beat.png", "rythm_note.png"]
	for file_name in rhythm_files:
		var texture_path = "res://effects/sprites/special/" + file_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				rhythm_textures.append(texture)

func _setup_shaders() -> void:
	"""Preload shader materials"""
	var outline_shader = load("res://shaders/outline.gdshader") as Shader
	if outline_shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = outline_shader
		outline_material.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 0.9))
		outline_material.set_shader_parameter("outline_width", 1.5)
		outline_material.set_shader_parameter("outline_smoothness", 0.1)
	
	var rainbow_shader = load("res://shaders/rainbow_shader.gdshader") as Shader
	if rainbow_shader:
		rainbow_material = ShaderMaterial.new()
		rainbow_material.shader = rainbow_shader

func _setup_components() -> void:
	# Create Label for character display
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", max(8, int(18 * effect_intensity)))
	if outline_material:
		label.material = outline_material
	add_child(label)
	
	# Create AnimatedSprite2D for enhanced visual effects
	if use_sprites:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.visible = false
		add_child(animated_sprite)
		_setup_sprite_animations()
	
	# Create Particles
	if particle_effects:
		particles = GPUParticles2D.new()
		particles.emitting = false
		particles.visible = false
		add_child(particles)
		_setup_particles()
	
	# Create Audio Player
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Create cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = effect_duration + 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(cleanup_timer)

func _setup_particles() -> void:
	var particle_material = ParticleProcessMaterial.new()
	# Radial burst
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0
	particle_material.initial_velocity_min = 60.0 * effect_intensity
	particle_material.initial_velocity_max = 180.0 * effect_intensity
	particle_material.gravity = Vector3(0, 60, 0)
	particle_material.scale_min = 0.3
	particle_material.scale_max = 1.2 * effect_intensity
	particle_material.color = _get_animation_color()
	
	particles.process_material = particle_material
	particles.texture = _load_particle_texture()
	particles.lifetime = 0.8
	particles.amount = int(12 * effect_intensity)
	particles.one_shot = true
	particles.explosiveness = 0.8

func _load_particle_texture() -> Texture2D:
	var particle_textures = ["particle_dot.png", "particle_star.png", "particle_square.png"]
	var valid_textures: Array[Texture2D] = []
	for texture_name in particle_textures:
		var texture_path = "res://effects/sprites/particles/" + texture_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				valid_textures.append(texture)
	if valid_textures.size() > 0:
		return valid_textures[randi() % valid_textures.size()]
	return _create_fallback_texture()

func _create_fallback_texture() -> ImageTexture:
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _setup_sprite_animations() -> void:
	if not animated_sprite:
		return
	
	var sprite_frames = SpriteFrames.new()
	
	if sparkle_textures.size() > 0:
		sprite_frames.add_animation("sparkle")
		sprite_frames.set_animation_speed("sparkle", 10.0)
		sprite_frames.set_animation_loop("sparkle", false)
		for texture in sparkle_textures:
			sprite_frames.add_frame("sparkle", texture)
	
	if glow_textures.size() > 0:
		sprite_frames.add_animation("glow")
		sprite_frames.set_animation_speed("glow", 8.0)
		sprite_frames.set_animation_loop("glow", false)
		for texture in glow_textures:
			sprite_frames.add_frame("glow", texture)
	
	if combo_textures.size() > 0:
		sprite_frames.add_animation("combo")
		sprite_frames.set_animation_speed("combo", 12.0)
		sprite_frames.set_animation_loop("combo", false)
		for texture in combo_textures:
			sprite_frames.add_frame("combo", texture)
	
	if rhythm_textures.size() > 0:
		sprite_frames.add_animation("rhythm")
		sprite_frames.set_animation_speed("rhythm", 6.0)
		sprite_frames.set_animation_loop("rhythm", false)
		for texture in rhythm_textures:
			sprite_frames.add_frame("rhythm", texture)
	
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.scale = Vector2(0.5, 0.5)
	animated_sprite.modulate.a = 0.8

func _start_effect() -> void:
	_detect_animation_type()
	
	label.text = character_typed
	
	# Apply random scaling
	var random_scale = randf_range(min_scale, max_scale) * effect_intensity
	scale = Vector2(random_scale, random_scale)
	
	# Random angular offset for variety
	rotation = randf_range(-0.2, 0.2)
	
	# Set random color if enabled
	if color_randomization:
		var random_color = _get_animation_color()
		label.modulate = random_color
		if animated_sprite:
			animated_sprite.modulate = random_color
		if particles and particles.process_material:
			particles.process_material.color = random_color
	
	# Apply shader upgrades for higher tiers
	if animation_type == "combo" or animation_type == "special":
		if rainbow_material:
			label.material = rainbow_material
			# Boost shader params for extra intensity (rainbow shader auto-animates via TIME)
			rainbow_material.set_shader_parameter("glow_base", 0.7)
			rainbow_material.set_shader_parameter("wave_speed", 4.0)
	
	# Start sprite animation
	if animated_sprite and use_sprites:
		_play_special_sprite_effect()
	
	# Run the main TweenFX animation based on type
	_run_tweenfx_animation()
	
	# Character-specific micro-effects
	_apply_character_micro_effect()
	
	# Start particles
	if particles and particle_effects:
		_configure_particles_for_animation()
		particles.visible = true
		particles.emitting = true
	
	# Emit tier so manager can trigger audio and screen shake
	tier_detected.emit(animation_type)
	
	# Start cleanup timer
	cleanup_timer.start()

func _run_tweenfx_animation() -> void:
	"""Play the main TweenFX animation based on animation_type"""
	match animation_type:
		"special":
			TweenFX.tada(label, 0.6)
			if animated_sprite:
				TweenFX.explode(animated_sprite, 0.3, 1.5 * effect_intensity)
		"combo":
			TweenFX.critical_hit(label, 0.5)
			if animated_sprite:
				TweenFX.punch_in(animated_sprite, 0.15, 0.3)
		"rhythm":
			TweenFX.upgrade(label, 0.6, Color(0.2, 1.0, 0.8))
			if animated_sprite:
				TweenFX.glow_pulse(animated_sprite, 0.8, 0.1 * effect_intensity)
		_:
			# Normal - big pop-in with overshoot
			TweenFX.pop_in(label, 0.25, 0.25 * effect_intensity)
			if animated_sprite:
				animated_sprite.visible = true
				TweenFX.pop_in(animated_sprite, 0.2, 0.15)
	
	# Fade out after main animation
	var fade_delay = effect_duration - fade_duration
	if fade_delay > 0:
		TweenFX.delayed_callback(self, fade_delay, func():
			TweenFX.fade_out(label, fade_duration)
			if animated_sprite:
				TweenFX.fade_out(animated_sprite, fade_duration)
		)

func _apply_character_micro_effect() -> void:
	"""Apply bonus flair for specific characters"""
	match character_typed:
		"!":
			if animated_sprite:
				animated_sprite.visible = true
				TweenFX.explode(animated_sprite, 0.3, 1.5)
		".":
			TweenFX.drop_out(label, 0.3, 30.0 * effect_intensity)
		"?":
			TweenFX.spin(label, 0.4, 0.5)
		" ":
			TweenFX.breathe(label, 1.0, 0.1 * effect_intensity)
		"\n", "\r", "⏎":
			TweenFX.drop_in(label, 0.4, 20.0 * effect_intensity)

func _play_special_sprite_effect() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var animation_name = ""
	match animation_type:
		"special", "combo":
			if combo_textures.size() > 0:
				animation_name = "combo"
			elif sparkle_textures.size() > 0:
				animation_name = "sparkle"
		"rhythm":
			if rhythm_textures.size() > 0:
				animation_name = "rhythm"
			elif glow_textures.size() > 0:
				animation_name = "glow"
		_:
			var available = []
			if sparkle_textures.size() > 0:
				available.append("sparkle")
			if glow_textures.size() > 0:
				available.append("glow")
			if available.size() > 0:
				animation_name = available[randi() % available.size()]
	
	if not animation_name.is_empty() and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.visible = true
		var sprite_scale = randf_range(min_scale, max_scale) * effect_intensity
		animated_sprite.scale = Vector2(sprite_scale, sprite_scale)
		animated_sprite.play(animation_name)

func _detect_animation_type() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if last_char_time > 0.0:
		var time_since_last_char = current_time - last_char_time
		if time_since_last_char > 0.5:
			typing_combo_count = 0
			rhythm_intervals.clear()
	
	if rhythm_detection and last_char_time > 0.0:
		var interval = current_time - last_char_time
		rhythm_intervals.append(interval)
		if rhythm_intervals.size() > 10:
			rhythm_intervals.pop_front()
		if _is_rhythmic_typing():
			animation_type = "rhythm"
			typing_combo_count += 2
		elif interval < 0.15:
			typing_combo_count += 1
		else:
			typing_combo_count = max(0, typing_combo_count - 1)
	
	if typing_combo_count >= combo_threshold * 2:
		animation_type = "special"
	elif typing_combo_count >= combo_threshold:
		animation_type = "combo"
	elif animation_type != "rhythm":
		animation_type = "normal"
	
	last_char_time = current_time

func _is_rhythmic_typing() -> bool:
	if rhythm_intervals.size() < 3:
		return false
	
	var avg_interval = 0.0
	for interval in rhythm_intervals:
		avg_interval += interval
	avg_interval /= rhythm_intervals.size()
	
	var consistent_count = 0
	for interval in rhythm_intervals:
		if abs(interval - avg_interval) < avg_interval * 0.3:
			consistent_count += 1
	
	return consistent_count >= rhythm_intervals.size() * 0.7

func _get_animation_color() -> Color:
	match animation_type:
		"special":
			return Color(1.0, 0.8, 0.2, 1.0)
		"combo":
			return Color(0.8, 0.2, 1.0, 1.0)
		"rhythm":
			return Color(0.2, 1.0, 0.8, 1.0)
		_:
			return Color(
				randf_range(0.5, 1.0),
				randf_range(0.5, 1.0),
				randf_range(0.5, 1.0),
				1.0
			)

func _configure_particles_for_animation() -> void:
	if not particles or not particles.process_material:
		return
	
	var particle_material = particles.process_material as ParticleProcessMaterial
	
	match animation_type:
		"special":
			particles.amount = int(40 * effect_intensity)
			particle_material.initial_velocity_max = 200.0 * effect_intensity
			particle_material.scale_max = 2.0 * effect_intensity
		"combo":
			particles.amount = int(25 * effect_intensity)
			particle_material.initial_velocity_max = 150.0 * effect_intensity
			particle_material.scale_max = 1.5 * effect_intensity
		"rhythm":
			particles.amount = int(20 * effect_intensity)
			particle_material.initial_velocity_max = 120.0 * effect_intensity
			particle_material.scale_max = 1.2 * effect_intensity
		_:
			particles.amount = int(12 * effect_intensity)
			particle_material.initial_velocity_max = 120.0 * effect_intensity
			particle_material.scale_max = 1.0 * effect_intensity

func _on_cleanup_timer_timeout() -> void:
	if destroy_on_complete:
		queue_free()

static func reset_typing_combo() -> void:
	typing_combo_count = 0
	last_char_time = 0.0
	rhythm_intervals.clear()

static func create_typing_effect(parent: Node, pos: Vector2, character: String) -> TypingEffect:
	var effect = TypingEffect.new()
	var typing_effect_offset: Vector2 = Vector2(888, -88)
	effect.character_typed = character
	effect.position = pos + typing_effect_offset
	parent.add_child(effect)
	return effect
