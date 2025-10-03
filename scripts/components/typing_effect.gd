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

var character_typed: String = ""
var destroy_on_complete: bool = true

@onready var label: Label
@onready var animation_player: AnimationPlayer
@onready var particles: GPUParticles2D
@onready var audio_player: AudioStreamPlayer2D
@onready var cleanup_timer: Timer

func _ready() -> void:
	_setup_components()
	_start_effect()

func _setup_components() -> void:
	# Create Label for character display
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	
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
	particles.texture = _create_particle_texture()
	particles.lifetime = 1.0
	particles.amount = 5

func _create_particle_texture() -> ImageTexture:
	# Create a simple 4x4 white pixel texture for particles
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _start_effect() -> void:
	# Set up label
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
	
	# Create and play bounce animation
	_create_bounce_animation()
	animation_player.play("bounce_and_fade")
	
	# Start particles if enabled
	if particles and particle_effects:
		particles.emitting = true
	
	# Start cleanup timer
	cleanup_timer.start()

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
	
	# Add animation to player
	var animation_library = AnimationLibrary.new()
	animation_library.add_animation("bounce_and_fade", animation)
	animation_player.add_animation_library("default", animation_library)

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