extends Node2D
class_name DeletionEffect

# Juicy Editor - Enhanced Deletion Effect Component (Juiced Up)
# Creates explosion effects with TweenFX when text is deleted

@export var effect_duration: float = 1.0
@export var scale_bounce: float = 1.5
@export var destroy_on_complete: bool = true
@export var use_sprites: bool = true
@export var particle_effects: bool = true

# Enhanced deletion scaling properties
@export var min_scale: float = 1.0
@export var max_scale: float = 15.0
@export var scale_increment: float = 0.05
@export var position_variance: float = 15.0
@export var deletion_reset_time: float = 0.5

# Juice controls
@export var effect_intensity: float = 1.0

# Core components
var explosion_sprite: AnimatedSprite2D
var particles: CPUParticles2D
var cleanup_timer: Timer

# Explosion resources
var explosion_textures: Array[Texture2D] = []

# Static variables for tracking repeated deletions across all instances
static var consecutive_deletions: int = 0
static var last_deletion_time: float = 0.0
static var current_deletion_scale: float = 1.0

func _ready() -> void:
	_setup_components()
	_load_explosion_sprites()
	_start_explosion_effect()

func reset_for_pool() -> void:
	"""Reset all state for object pool reuse"""
	TweenFX.stop_all(self)
	if explosion_sprite:
		explosion_sprite.visible = false
		explosion_sprite.scale = Vector2.ONE
		explosion_sprite.modulate = Color.WHITE
		explosion_sprite.rotation = 0.0
	if particles:
		particles.emitting = false
		particles.visible = false
	current_deletion_scale = 1.0

func _setup_components() -> void:
	# Create explosion sprite
	explosion_sprite = AnimatedSprite2D.new()
	explosion_sprite.visible = false
	add_child(explosion_sprite)
	explosion_sprite.position = Vector2.ZERO
	
	# Create particles system
	particles = CPUParticles2D.new()
	particles.visible = false
	add_child(particles)
	_setup_particles()
	
	# Create cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.timeout.connect(_on_cleanup_timeout)
	cleanup_timer.wait_time = effect_duration + 0.1
	cleanup_timer.one_shot = true
	add_child(cleanup_timer)

func _load_explosion_sprites() -> void:
	var explosion_files = [
		"explosion_01.png", "explosion_02.png", "explosion_03.png",
		"explosion_04.png", "explosion_05.png", "explosion_06.png",
		"explosion_07.png", "explosion_08.png", "explosion_09.png"
	]
	
	for file_name in explosion_files:
		var texture_path = "res://effects/sprites/deletion/" + file_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				explosion_textures.append(texture)
	
	if explosion_textures.size() > 0 and explosion_sprite:
		_setup_explosion_animation()
	else:
		_create_fallback_explosion_animation()

func _setup_explosion_animation() -> void:
	if not explosion_sprite or explosion_textures.size() == 0:
		return
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("explode")
	
	for texture in explosion_textures:
		sprite_frames.add_frame("explode", texture)
	
	sprite_frames.set_animation_speed("explode", 75.0)
	sprite_frames.set_animation_loop("explode", false)
	
	explosion_sprite.sprite_frames = sprite_frames

func _create_fallback_explosion_animation() -> void:
	if not explosion_sprite:
		return
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("explode")
	
	var fallback_texture = _create_simple_explosion_texture()
	sprite_frames.add_frame("explode", fallback_texture)
	
	sprite_frames.set_animation_speed("explode", 5.0)
	sprite_frames.set_animation_loop("explode", false)
	
	explosion_sprite.sprite_frames = sprite_frames

func _create_simple_explosion_texture() -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center = Vector2(16, 16)
	var radius = 12
	
	for x in range(32):
		for y in range(32):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1.0, 0.8, 0.2, alpha))
	
	return ImageTexture.create_from_image(image)

func _setup_particles() -> void:
	if not particles:
		return
	
	particles.emitting = false
	particles.one_shot = true
	
	# Emission shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	
	# Movement - radial burst
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 200)
	
	# Scale and rotation
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	
	# Color and transparency
	particles.color = Color.WHITE
	particles.color_ramp = _create_fade_gradient()
	
	# Load particle texture
	particles.texture = _load_debris_particle_texture()

func _create_fade_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.5, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.6, 0.2, 1.0))
	gradient.add_point(0.7, Color(1.0, 0.3, 0.1, 0.5))
	gradient.add_point(1.0, Color.TRANSPARENT)
	return gradient

func _load_debris_particle_texture() -> Texture2D:
	var dust_textures = ["dust_01.png", "dust_02.png", "dust_03.png", "dust_04.png"]
	
	for texture_name in dust_textures:
		var texture_path = "res://effects/sprites/particles/" + texture_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				return texture
	
	return _create_simple_particle_texture()

func _create_simple_particle_texture() -> ImageTexture:
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _start_explosion_effect() -> void:
	_update_deletion_tracking()
	_apply_enhanced_scaling()
	
	# Make sprite visible and play
	if explosion_sprite and use_sprites and explosion_sprite.sprite_frames != null:
		explosion_sprite.visible = true
		if explosion_sprite.sprite_frames.has_animation("explode"):
			explosion_sprite.play("explode")
	
	# TweenFX explosion animation
	if explosion_sprite:
		var explode_scale = 1.8 * current_deletion_scale * effect_intensity
		TweenFX.explode(explosion_sprite, 0.35, explode_scale)
		
		# For heavy deletions, chain a black-hole collapse
		if current_deletion_scale > 5.0:
			TweenFX.delayed_callback(self, 0.3, func():
				TweenFX.black_hole(explosion_sprite, 0.5)
			)
	
	# Flash spotlight on the effect
	TweenFX.spotlight(self, 0.1, Color(1.5, 1.2, 0.5, 1.0))
	
	# Start particles
	_configure_particles_for_scale()
	particles.visible = true
	particles.emitting = true
	
	# Start cleanup timer
	cleanup_timer.start()

func _configure_particles_for_scale() -> void:
	if not particles:
		return
	
	var base_amount = int(20 * current_deletion_scale * effect_intensity)
	particles.amount = clampi(base_amount, 5, 150)
	particles.lifetime = clampf(1.0 + current_deletion_scale * 0.2, 0.5, 2.5)
	
	particles.initial_velocity_min = 50.0 * current_deletion_scale * effect_intensity
	particles.initial_velocity_max = 150.0 * current_deletion_scale * effect_intensity

func _on_cleanup_timeout() -> void:
	if destroy_on_complete:
		queue_free()

func _update_deletion_tracking() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_deletion_time <= deletion_reset_time:
		consecutive_deletions += 1
	else:
		consecutive_deletions = 1
		current_deletion_scale = min_scale
	
	current_deletion_scale = min(
		min_scale + (consecutive_deletions - 1) * scale_increment,
		max_scale
	)
	
	last_deletion_time = current_time
	
	print("Debug: Deletion #", consecutive_deletions, " at scale: ", current_deletion_scale)

func _apply_enhanced_scaling() -> void:
	var final_scale = current_deletion_scale * effect_intensity
	scale = Vector2(final_scale, final_scale)
	
	var random_y_offset = randf_range(-position_variance, position_variance)
	var random_x_offset = randf_range(-position_variance * 0.5, position_variance * 0.5)
	position.y += random_y_offset
	position.x += random_x_offset

static func reset_deletion_scale() -> void:
	consecutive_deletions = 0
	current_deletion_scale = 1.0

static func create_deletion_effect(parent: Node, pos: Vector2) -> DeletionEffect:
	var effect = DeletionEffect.new()
	effect.position = pos
	parent.add_child(effect)
	return effect
