extends Node2D
class_name DeletionEffect

# Juicy Editor - Enhanced Deletion Effect Component
# Creates explosion effects with animated sprites and particles when text is deleted

@export var effect_duration: float = 1.0
@export var scale_bounce: float = 1.5
@export var destroy_on_complete: bool = true
@export var use_sprites: bool = true
@export var particle_effects: bool = true

# Enhanced deletion scaling properties
@export var min_scale: float = 1.0
@export var max_scale: float = 15.0
@export var scale_increment: float = 0.05
@export var position_variance: float = 15.0  # Random Y position variance
@export var deletion_reset_time: float = 0.5  # Time before resetting scale

# Core components
var explosion_sprite: AnimatedSprite2D
var particles: CPUParticles2D
var animation_player: AnimationPlayer
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

func _setup_components() -> void:
	"""Initialize all effect components"""
	# Create explosion sprite
	explosion_sprite = AnimatedSprite2D.new()
	add_child(explosion_sprite)
	explosion_sprite.position = Vector2.ZERO
	
	# Create particles system
	particles = CPUParticles2D.new()
	add_child(particles)
	_setup_particles()
	
	# Create animation player
	animation_player = AnimationPlayer.new()
	add_child(animation_player)
	
	# Create cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.timeout.connect(_on_cleanup_timeout)
	cleanup_timer.wait_time = 0.35 #effect_duration + 0.05  # Cleanup right after fade completes
	cleanup_timer.one_shot = true
	add_child(cleanup_timer)

func _load_explosion_sprites() -> void:
	"""Load explosion sprite textures"""
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
	
	# Setup sprite frames if we have textures
	if explosion_textures.size() > 0 and explosion_sprite:
		_setup_explosion_animation()
	else:
		print("Warning: No explosion textures found, creating fallback animation")
		_create_fallback_explosion_animation()

func _setup_explosion_animation() -> void:
	"""Setup animated sprite with explosion frames"""
	if not explosion_sprite or explosion_textures.size() == 0:
		return
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("explode")
	
	# Add all explosion textures as frames
	for texture in explosion_textures:
		sprite_frames.add_frame("explode", texture)
	
	# Configure animation
	sprite_frames.set_animation_speed("explode", 75.0)  # Fast explosion
	sprite_frames.set_animation_loop("explode", false)  # Play once
	
	explosion_sprite.sprite_frames = sprite_frames

func _create_fallback_explosion_animation() -> void:
	"""Create a simple fallback explosion animation when no textures are available"""
	if not explosion_sprite:
		return
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("explode")
	
	# Create a simple white circle texture as fallback
	var fallback_texture = _create_simple_explosion_texture()
	sprite_frames.add_frame("explode", fallback_texture)
	
	# Configure animation
	sprite_frames.set_animation_speed("explode", 5.0)
	sprite_frames.set_animation_loop("explode", false)
	
	explosion_sprite.sprite_frames = sprite_frames

func _create_simple_explosion_texture() -> ImageTexture:
	"""Create a simple explosion texture as fallback"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Create a simple circle
	var center = Vector2(16, 16)
	var radius = 12
	
	for x in range(32):
		for y in range(32):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1.0, 0.8, 0.2, alpha))  # Orange explosion color
	
	return ImageTexture.create_from_image(image)

func _setup_particles() -> void:
	"""Configure particle system for debris effect"""
	if not particles:
		return
	
	# Particle configuration
	particles.emitting = false
	particles.amount = 15
	particles.lifetime = 1.5
	particles.one_shot = true
	
	# Emission shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	
	# Movement
	particles.direction = Vector2(0, -1)
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
	"""Create a gradient that fades particles over time"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(0.7, Color.WHITE)
	gradient.add_point(1.0, Color.TRANSPARENT)
	return gradient

func _load_debris_particle_texture() -> Texture2D:
	"""Load debris particle texture or create fallback"""
	var dust_textures = ["dust_01.png", "dust_02.png", "dust_03.png", "dust_04.png"]
	
	for texture_name in dust_textures:
		var texture_path = "res://effects/sprites/particles/" + texture_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				return texture
	
	# Fallback: create simple texture
	return _create_simple_particle_texture()

func _create_simple_particle_texture() -> ImageTexture:
	"""Create a simple particle texture as fallback"""
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _start_explosion_effect() -> void:
	"""Start the explosion effect with progressive scaling"""
	# Update deletion tracking
	_update_deletion_tracking()
	
	# Apply progressive scaling and random positioning
	_apply_enhanced_scaling()
	
	# Setup explosion sprite animation
	if explosion_sprite and use_sprites and explosion_sprite.sprite_frames != null:
		if explosion_sprite.sprite_frames.has_animation("explode"):
			explosion_sprite.play("explode")
		else:
			print("Warning: 'explode' animation not found in sprite frames")
	elif explosion_sprite and use_sprites:
		print("Warning: No sprite frames available for explosion animation")
	
	# Create the scale animation first
	_create_explosion_scale_animation()
	
	# Start particles with enhanced effects
	_configure_particles_for_scale()
	particles.emitting = true
	
	# Play scale animation
	if animation_player and animation_player.has_animation_library("default"):
		var library = animation_player.get_animation_library("default")
		if library.has_animation("explosion_scale"):
			print("Debug: Playing explosion_scale animation at scale: ", current_deletion_scale)
			animation_player.play("default/explosion_scale")
		else:
			print("Warning: explosion_scale animation not found in default library")
	elif animation_player:
		print("Warning: default animation library not found")
		print("Debug: Available animations: ", animation_player.get_animation_list())
	
	# Start cleanup timer
	cleanup_timer.start()

func _create_explosion_scale_animation() -> void:
	"""Create scaling animation for explosion sprite"""
	if not animation_player or not explosion_sprite:
		return
	
	var animation = Animation.new()
	animation.length = effect_duration
	
	# Scale track for explosion growth - use actual node name
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	var sprite_path = explosion_sprite.name if explosion_sprite else "AnimatedSprite2D"
	animation.track_set_path(scale_track, NodePath(sprite_path + ":scale"))
	
	# Explosion animation: start tiny, grow quickly, then shrink
	animation.track_insert_key(scale_track, 0.0, Vector2(0.1, 0.1))
	animation.track_insert_key(scale_track, 0.2, Vector2(scale_bounce, scale_bounce))
	animation.track_insert_key(scale_track, 0.6, Vector2(1.0, 1.0))
	animation.track_insert_key(scale_track, effect_duration, Vector2(0.1, 0.1))
	
	# Alpha track for fade out - use actual node name
	var alpha_track = animation.add_track(Animation.TYPE_VALUE)
	var sprite_path_mod = explosion_sprite.name if explosion_sprite else "AnimatedSprite2D"
	animation.track_set_path(alpha_track, NodePath(sprite_path_mod + ":modulate"))
	
	animation.track_insert_key(alpha_track, 0.0, Color.WHITE)
	animation.track_insert_key(alpha_track, 0.7, Color.WHITE)
	animation.track_insert_key(alpha_track, effect_duration, Color.TRANSPARENT)
	
	# Add animation to player - Check if library exists first
	if not animation_player.has_animation_library("default"):
		var animation_library = AnimationLibrary.new()
		animation_player.add_animation_library("default", animation_library)
	
	var library = animation_player.get_animation_library("default")
	if library:
		library.add_animation("explosion_scale", animation)
		print("Debug: Added explosion_scale animation to deletion_effect")
	else:
		print("Error: Could not get animation library in deletion_effect")

func _on_cleanup_timeout() -> void:
	if destroy_on_complete:
		queue_free()

func _update_deletion_tracking() -> void:
	"""Update tracking for consecutive deletions"""
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Check if this deletion is part of a sequence
	if current_time - last_deletion_time <= deletion_reset_time:
		consecutive_deletions += 1
	else:
		consecutive_deletions = 1
		current_deletion_scale = min_scale
	
	# Update scale based on consecutive deletions
	current_deletion_scale = min(
		min_scale + (consecutive_deletions - 1) * scale_increment,
		max_scale
	)
	
	last_deletion_time = current_time
	
	print("Debug: Deletion #", consecutive_deletions, " at scale: ", current_deletion_scale)

func _apply_enhanced_scaling() -> void:
	"""Apply progressive scaling and random positioning"""
	# Apply scale to the entire effect
	scale = Vector2(current_deletion_scale, current_deletion_scale)
	
	# Apply random Y position variance
	var random_y_offset = randf_range(-position_variance, position_variance)
	position.y += random_y_offset
	
	# Slightly adjust X as well for more natural variation
	var random_x_offset = randf_range(-position_variance * 0.5, position_variance * 0.5)
	position.x += random_x_offset
	
	print("Debug: Applied scaling: ", current_deletion_scale, " position offset: ", Vector2(random_x_offset, random_y_offset))

func _configure_particles_for_scale() -> void:
	"""Configure particle effects based on current deletion scale"""
	if not particles or not particles.material:
		return
	
	var particle_material = particles.material as ParticleProcessMaterial
	if not particle_material:
		return
	
	# Scale particle properties based on deletion scale
	particles.amount = int(20 * current_deletion_scale)
	
	# Enhanced particle effects for larger explosions
	if current_deletion_scale > 2.0:
		particles.lifetime = 2.0
		if particle_material:
			particle_material.initial_velocity_min = 60.0 * current_deletion_scale
			particle_material.initial_velocity_max = 120.0 * current_deletion_scale
	elif current_deletion_scale > 1.5:
		particles.lifetime = 1.5
		if particle_material:
			particle_material.initial_velocity_min = 40.0 * current_deletion_scale
			particle_material.initial_velocity_max = 80.0 * current_deletion_scale
	else:
		particles.lifetime = 1.0
		if particle_material:
			particle_material.initial_velocity_min = 30.0
			particle_material.initial_velocity_max = 60.0

# Static method to reset deletion tracking (called when typing stops)
static func reset_deletion_scale() -> void:
	consecutive_deletions = 0
	current_deletion_scale = 1.0
	print("Debug: Deletion scale reset")

# Static factory method
static func create_deletion_effect(parent: Node, pos: Vector2) -> DeletionEffect:
	var effect = DeletionEffect.new()
	effect.position = pos
	parent.add_child(effect)
	return effect