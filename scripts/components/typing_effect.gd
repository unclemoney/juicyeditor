extends Node2D
class_name TypingEffect

# Juicy Editor - Typing Effect Component
# Creates fun animated effects when typing characters
# Inspired by ridiculous_coding plugin but simplified for Juicy Editor

@export var effect_duration: float = 1.5
@export var fade_duration: float = 0.5
@export var scale_bounce: float = 1.2
@export var color_randomization: bool = true
@export var particle_effects: bool = true
@export var use_sprites: bool = true  # Toggle between sprites and text effects

var character_typed: String = ""
var destroy_on_complete: bool = true

@onready var label: Label
@onready var animated_sprite: AnimatedSprite2D  # New sprite component
@onready var animation_player: AnimationPlayer
@onready var particles: GPUParticles2D
@onready var audio_player: AudioStreamPlayer2D
@onready var cleanup_timer: Timer

# Sprite resources
var sparkle_textures: Array[Texture2D] = []
var glow_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_sprite_resources()
	_setup_components()
	_start_effect()

func _load_sprite_resources() -> void:
	"""Load sprite textures from the effects folder"""
	# Load sparkle textures
	for i in range(1, 7):  # Assuming sparkle_01.png to sparkle_06.png
		var texture_path = "res://effects/sprites/typing/sparkle_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				sparkle_textures.append(texture)
	
	# Load glow textures
	for i in range(1, 5):  # Assuming glow_ring_01.png to glow_ring_04.png
		var texture_path = "res://effects/sprites/typing/glow_ring_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				glow_textures.append(texture)
	
	print("Loaded ", sparkle_textures.size(), " sparkle textures and ", glow_textures.size(), " glow textures")

func _setup_components() -> void:
	# Create Label for character display (fallback or combined with sprites)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	
	# Create AnimatedSprite2D for enhanced visual effects
	if use_sprites:
		animated_sprite = AnimatedSprite2D.new()
		add_child(animated_sprite)
		_setup_sprite_animations()
	
	# Create Animation Player
	animation_player = AnimationPlayer.new()
	add_child(animation_player)
	
	# Create Particles (optional)
	if particle_effects:
		particles = GPUParticles2D.new()
		particles.emitting = false
		add_child(particles)
		_setup_particles()
	
	# Create Audio Player
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Create cleanup timer
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = effect_duration
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(cleanup_timer)

func _setup_particles() -> void:
	# Simple particle setup for character effects
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 50.0
	particle_material.gravity = Vector3(0, 98, 0)
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.5
	
	particles.process_material = particle_material
	particles.texture = _load_particle_texture()
	particles.lifetime = 1.0
	particles.amount = 5

func _load_particle_texture() -> Texture2D:
	"""Load a random particle texture or create fallback"""
	var particle_textures = ["particle_dot.png", "particle_star.png", "particle_square.png"]
	
	for texture_name in particle_textures:
		var texture_path = "res://effects/sprites/particles/" + texture_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				return texture
	
	# Fallback: create simple texture if no sprites found
	return _create_particle_texture()

func _setup_sprite_animations() -> void:
	"""Setup sprite animations for enhanced visual effects"""
	if not animated_sprite:
		return
	
	# Create SpriteFrames resource for animations
	var sprite_frames = SpriteFrames.new()
	
	# Add sparkle animation
	if sparkle_textures.size() > 0:
		sprite_frames.add_animation("sparkle")
		sprite_frames.set_animation_speed("sparkle", 10.0)  # 10 FPS
		sprite_frames.set_animation_loop("sparkle", false)
		
		for texture in sparkle_textures:
			sprite_frames.add_frame("sparkle", texture)
	
	# Add glow animation  
	if glow_textures.size() > 0:
		sprite_frames.add_animation("glow")
		sprite_frames.set_animation_speed("glow", 8.0)  # 8 FPS
		sprite_frames.set_animation_loop("glow", false)
		
		for texture in glow_textures:
			sprite_frames.add_frame("glow", texture)
	
	# Assign to animated sprite
	animated_sprite.sprite_frames = sprite_frames
	
	# Set initial properties
	animated_sprite.scale = Vector2(0.5, 0.5)  # Start smaller
	animated_sprite.modulate.a = 0.8  # Slightly transparent

func _create_particle_texture() -> ImageTexture:
	# Create a simple 4x4 white pixel texture for particles
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _start_effect() -> void:
	# Set up label (still used for character display)
	label.text = character_typed
	
	# Set random color if enabled
	if color_randomization:
		var random_color = Color(
			randf_range(0.5, 1.0),
			randf_range(0.5, 1.0), 
			randf_range(0.5, 1.0),
			1.0
		)
		label.modulate = random_color
		
		# Apply color to sprite as well
		if animated_sprite:
			animated_sprite.modulate = random_color
	
	# Start sprite animation
	if animated_sprite and use_sprites:
		_play_random_sprite_effect()
	
	# Create and play bounce animation
	_create_bounce_animation()
	
	# Check if animation exists before playing
	if animation_player.has_animation_library("default"):
		var library = animation_player.get_animation_library("default")
		if library.has_animation("bounce_and_fade"):
			print("Debug: Playing bounce_and_fade animation")
			animation_player.play("default/bounce_and_fade")
		else:
			print("Warning: bounce_and_fade animation not found in default library")
			cleanup_timer.start()
	else:
		print("Warning: default animation library not found")
		print("Debug: Available animations: ", animation_player.get_animation_list())
		# Fallback - just start cleanup timer
		cleanup_timer.start()
	
	# Start particles if enabled
	if particles and particle_effects:
		particles.emitting = true
	
	# Start cleanup timer
	cleanup_timer.start()

func _play_random_sprite_effect() -> void:
	"""Play a random sprite effect (sparkle or glow)"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var available_animations = []
	if sparkle_textures.size() > 0:
		available_animations.append("sparkle")
	if glow_textures.size() > 0:
		available_animations.append("glow")
	
	if available_animations.size() > 0:
		var animation_name = available_animations[randi() % available_animations.size()]
		animated_sprite.play(animation_name)
		print("Playing sprite animation: ", animation_name)

func _create_bounce_animation() -> void:
	var animation = Animation.new()
	animation.length = effect_duration
	
	# Scale track for bounce effect
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath("Label:scale"))
	
	# Bounce animation: start small, scale up, then scale down
	animation.track_insert_key(scale_track, 0.0, Vector2(0.1, 0.1))
	animation.track_insert_key(scale_track, 0.2, Vector2(scale_bounce, scale_bounce))
	animation.track_insert_key(scale_track, 0.4, Vector2(1.0, 1.0))
	
	# Modulate track for fade effect
	var modulate_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, NodePath("Label:modulate"))
	
	# Fade animation: visible, then fade out
	var start_color = label.modulate
	var end_color = Color(start_color.r, start_color.g, start_color.b, 0.0)
	
	animation.track_insert_key(modulate_track, 0.0, start_color)
	animation.track_insert_key(modulate_track, effect_duration - fade_duration, start_color)
	animation.track_insert_key(modulate_track, effect_duration, end_color)
	
	# Add animation to player - Check if library exists first
	if not animation_player.has_animation_library("default"):
		var animation_library = AnimationLibrary.new()
		animation_player.add_animation_library("default", animation_library)
	
	var library = animation_player.get_animation_library("default")
	if library:
		library.add_animation("bounce_and_fade", animation)
		print("Debug: Added bounce_and_fade animation to typing_effect")
	else:
		print("Error: Could not get animation library in typing_effect")

func _on_cleanup_timer_timeout() -> void:
	if destroy_on_complete:
		queue_free()

# Static factory method to create typing effects
static func create_typing_effect(parent: Node, pos: Vector2, character: String) -> TypingEffect:
	var effect = TypingEffect.new()
	effect.character_typed = character
	effect.position = pos
	parent.add_child(effect)
	return effect