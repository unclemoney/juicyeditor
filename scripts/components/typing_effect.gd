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

# Enhanced animation properties
@export var min_scale: float = 0.8
@export var max_scale: float = 1.7
@export var combo_threshold: int = 15  # Typing speed to trigger combo effects (lowered for easier testing)
@export var rhythm_detection: bool = true

var character_typed: String = ""
var destroy_on_complete: bool = true

# Animation state tracking - Made static to share across all typing effect instances
static var typing_combo_count: int = 0
static var last_char_time: float = 0.0
static var rhythm_intervals: Array[float] = []
var animation_type: String = "normal"  # normal, combo, rhythm, special

@onready var label: Label
@onready var animated_sprite: AnimatedSprite2D  # New sprite component
@onready var animation_player: AnimationPlayer
@onready var particles: GPUParticles2D
@onready var audio_player: AudioStreamPlayer2D
@onready var cleanup_timer: Timer

# Sprite resources
var sparkle_textures: Array[Texture2D] = []
var glow_textures: Array[Texture2D] = []
var combo_textures: Array[Texture2D] = []
var rhythm_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_sprite_resources()
	_setup_components()
	_start_effect()

func _load_sprite_resources() -> void:
	"""Load sprite textures from the effects folder"""
	# Load sparkle textures
	for i in range(1, 5):  # Assuming sparkle_01.png to sparkle_06.png
		var texture_path = "res://effects/sprites/typing/sparkle_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				sparkle_textures.append(texture)
	
	# Load glow textures
	for i in range(1, 9):  # Assuming glow_ring_01.png to glow_ring_04.png
		var texture_path = "res://effects/sprites/typing/glow_ring_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				glow_textures.append(texture)
	
	# Load combo special textures
	var combo_files = ["combo_2x.png", "combo_3x.png", "combo_text.png", "combo_boom.png"]
	for file_name in combo_files:
		var texture_path = "res://effects/sprites/special/" + file_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				combo_textures.append(texture)
	
	# Load rhythm special textures
	var rhythm_files = ["rythm_beat.png", "rythm_note.png"]
	for file_name in rhythm_files:
		var texture_path = "res://effects/sprites/special/" + file_name
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				rhythm_textures.append(texture)
	
	print("Loaded ", sparkle_textures.size(), " sparkle textures, ", glow_textures.size(), " glow textures, ", combo_textures.size(), " combo textures, and ", rhythm_textures.size(), " rhythm textures")

func _setup_components() -> void:
	# Create Label for character display (fallback or combined with sprites)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set("custom_fonts/font", "fonts/National2Condensed-Medium.otf")
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
	cleanup_timer.wait_time = 0.25 #effect_duration
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)
	add_child(cleanup_timer)

func _setup_particles() -> void:
	# Enhanced particle setup with random scaling
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 50.0
	particle_material.gravity = Vector3(0, 98, 0)
	
	# Random scale variation for particles
	particle_material.scale_min = randf_range(min_scale * 0.5, min_scale)
	particle_material.scale_max = randf_range(max_scale, max_scale * 1.5)
	
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
	
	# Add combo animation
	if combo_textures.size() > 0:
		sprite_frames.add_animation("combo")
		sprite_frames.set_animation_speed("combo", 12.0)  # 12 FPS for energetic effect
		sprite_frames.set_animation_loop("combo", false)
		
		for texture in combo_textures:
			sprite_frames.add_frame("combo", texture)
	
	# Add rhythm animation
	if rhythm_textures.size() > 0:
		sprite_frames.add_animation("rhythm")
		sprite_frames.set_animation_speed("rhythm", 6.0)  # 6 FPS for smooth rhythm
		sprite_frames.set_animation_loop("rhythm", false)
		
		for texture in rhythm_textures:
			sprite_frames.add_frame("rhythm", texture)
	
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
	# Detect animation type based on typing patterns
	_detect_animation_type()
	
	# Set up label (still used for character display)
	label.text = character_typed
	
	# Apply random scaling to the effect
	var random_scale = randf_range(min_scale, max_scale)
	scale = Vector2(random_scale, random_scale)
	
	# Set random color if enabled
	if color_randomization:
		var random_color = _get_animation_color()
		label.modulate = random_color
		
		# Apply color to sprite as well
		if animated_sprite:
			animated_sprite.modulate = random_color
	
	# Start sprite animation
	if animated_sprite and use_sprites:
		_play_special_sprite_effect()
	
	# Create and play bounce animation based on type
	_create_enhanced_animation()
	
	# Check if animation exists before playing
	if animation_player.has_animation_library("default"):
		var library = animation_player.get_animation_library("default")
		var animation_name = _get_animation_name()
		if library.has_animation(animation_name):
			print("Debug: Playing ", animation_name, " animation")
			animation_player.play("default/" + animation_name)
		else:
			print("Warning: ", animation_name, " animation not found in default library")
			cleanup_timer.start()
	else:
		print("Warning: default animation library not found")
		print("Debug: Available animations: ", animation_player.get_animation_list())
		# Fallback - just start cleanup timer
		cleanup_timer.start()
	
	# Start particles if enabled
	if particles and particle_effects:
		_configure_particles_for_animation()
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

func _detect_animation_type() -> void:
	"""Detect what type of animation to play based on typing patterns"""
	var current_time = Time.get_ticks_msec() / 1000.0
	
	print("Debug: Detecting animation type - current combo count: ", typing_combo_count, ", combo threshold: ", combo_threshold)
	
	# Check if too much time has passed since last keystroke (reset combo)
	if last_char_time > 0.0:
		var time_since_last_char = current_time - last_char_time
		print("Debug: Time since last character: ", time_since_last_char, " seconds")
		
		if time_since_last_char > 0.5:  # 500ms timeout
			print("Debug: Typing timeout detected, resetting combo count from ", typing_combo_count, " to 0")
			typing_combo_count = 0
			rhythm_intervals.clear()  # Also clear rhythm data
	
	# Track typing rhythm
	if rhythm_detection and last_char_time > 0.0:
		var interval = current_time - last_char_time
		rhythm_intervals.append(interval)
		
		print("Debug: Typing interval: ", interval, " seconds")
		
		# Keep only recent intervals
		if rhythm_intervals.size() > 10:
			rhythm_intervals.pop_front()
		
		# Check for rhythm patterns
		if _is_rhythmic_typing():
			animation_type = "rhythm"
			typing_combo_count += 2  # Bonus for rhythm
			print("Debug: Detected rhythmic typing, combo count now: ", typing_combo_count)
		elif interval < 0.15:  # Fast typing
			typing_combo_count += 1
			print("Debug: Fast typing detected, combo count now: ", typing_combo_count)
		else:
			typing_combo_count = max(0, typing_combo_count - 1)
			print("Debug: Slow typing, combo count decreased to: ", typing_combo_count)
	
	# Determine animation type
	if typing_combo_count >= combo_threshold * 2:
		animation_type = "special"
		print("Debug: Set animation type to SPECIAL")
	elif typing_combo_count >= combo_threshold:
		animation_type = "combo"
		print("Debug: Set animation type to COMBO")
	elif animation_type != "rhythm":
		animation_type = "normal"
		print("Debug: Set animation type to NORMAL")
	
	print("Debug: Final animation type: ", animation_type)
	last_char_time = current_time

func _is_rhythmic_typing() -> bool:
	"""Check if recent typing follows a rhythm pattern"""
	if rhythm_intervals.size() < 3:
		return false
	
	var avg_interval = 0.0
	for interval in rhythm_intervals:
		avg_interval += interval
	avg_interval /= rhythm_intervals.size()
	
	# Check if recent intervals are close to average (rhythmic)
	var consistent_count = 0
	for interval in rhythm_intervals:
		if abs(interval - avg_interval) < avg_interval * 0.3:
			consistent_count += 1
	
	return consistent_count >= rhythm_intervals.size() * 0.7

func _get_animation_color() -> Color:
	"""Get color based on animation type"""
	match animation_type:
		"special":
			return Color(1.0, 0.8, 0.2, 1.0)  # Golden
		"combo":
			return Color(0.8, 0.2, 1.0, 1.0)  # Purple
		"rhythm":
			return Color(0.2, 1.0, 0.8, 1.0)  # Cyan
		_:
			return Color(
				randf_range(0.5, 1.0),
				randf_range(0.5, 1.0), 
				randf_range(0.5, 1.0),
				1.0
			)

func _play_special_sprite_effect() -> void:
	"""Play sprite effect based on animation type"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var animation_name = ""
	
	# Choose animation based on type
	match animation_type:
		"special":
			# Use combo animations for special effects
			if combo_textures.size() > 0:
				animation_name = "combo"
			elif sparkle_textures.size() > 0:
				animation_name = "sparkle"
		"combo":
			# Use combo animations
			if combo_textures.size() > 0:
				animation_name = "combo"
			elif glow_textures.size() > 0:
				animation_name = "glow"
		"rhythm":
			# Use rhythm animations
			if rhythm_textures.size() > 0:
				animation_name = "rhythm"
			elif glow_textures.size() > 0:
				animation_name = "glow"
		_:  # normal
			# Use regular sparkle/glow animations
			var available_animations = []
			if sparkle_textures.size() > 0:
				available_animations.append("sparkle")
			if glow_textures.size() > 0:
				available_animations.append("glow")
			
			if available_animations.size() > 0:
				animation_name = available_animations[randi() % available_animations.size()]
	
	if not animation_name.is_empty() and animated_sprite.sprite_frames.has_animation(animation_name):
		# Apply random scale to sprite
		var sprite_scale = randf_range(min_scale, max_scale)
		animated_sprite.scale = Vector2(sprite_scale, sprite_scale)
		
		animated_sprite.play(animation_name)
		print("Playing ", animation_type, " sprite animation: ", animation_name, " at scale: ", sprite_scale)
	else:
		print("Warning: No suitable sprite animation found for ", animation_type)

func _get_animation_name() -> String:
	"""Get animation name based on type"""
	match animation_type:
		"special":
			return "special_burst"
		"combo":
			return "combo_bounce"
		"rhythm":
			return "rhythm_pulse"
		_:
			return "bounce_and_fade"

func _configure_particles_for_animation() -> void:
	"""Configure particle effects based on animation type"""
	if not particles or not particles.process_material:
		return
	
	var particle_material = particles.process_material as ParticleProcessMaterial
	
	match animation_type:
		"special":
			particles.amount = 15
			particle_material.initial_velocity_max = 80.0
			particle_material.scale_max = max_scale * 2.0
		"combo":
			particles.amount = 10
			particle_material.initial_velocity_max = 60.0
			particle_material.scale_max = max_scale * 7.5
		"rhythm":
			particles.amount = 8
			particle_material.initial_velocity_max = 45.0
			particle_material.scale_max = max_scale * 1.2
		_:
			particles.amount = 5
			particle_material.initial_velocity_max = 50.0
			particle_material.scale_max = max_scale

func _create_enhanced_animation() -> void:
	"""Create animations for different types"""
	_create_bounce_animation()  # Create basic animation first
	
	match animation_type:
		"special":
			print("Debug: Creating special burst animation")
			_create_special_burst_animation()
		"combo":
			print("Debug: Creating combo bounce animation")
			_create_combo_bounce_animation()
		"rhythm":
			print("Debug: Creating rhythm pulse animation")
			_create_rhythm_pulse_animation()

func _create_special_burst_animation() -> void:
	"""Create special burst animation"""
	var animation = Animation.new()
	animation.length = effect_duration * 1.5
	
	# Get label path relative to animation player root
	var label_path = _get_label_path()
	
	# Enhanced scale track for burst effect
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath(label_path + ":scale"))
	
	animation.track_insert_key(scale_track, 0.0, Vector2(0.1, 0.1))
	animation.track_insert_key(scale_track, 0.15, Vector2(scale_bounce * 2.0, scale_bounce * 2.0))
	animation.track_insert_key(scale_track, 0.3, Vector2(1.2, 1.2))
	animation.track_insert_key(scale_track, 0.6, Vector2(1.0, 1.0))
	
	# Enhanced rotation
	var rotation_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_track, NodePath(label_path + ":rotation"))
	animation.track_insert_key(rotation_track, 0.0, 0.0)
	animation.track_insert_key(rotation_track, 0.3, PI * 0.25)
	animation.track_insert_key(rotation_track, animation.length, 0.0)
	
	# Modulate track
	var modulate_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, NodePath(label_path + ":modulate"))
	
	var start_color = label.modulate
	var end_color = Color(start_color.r, start_color.g, start_color.b, 0.0)
	
	animation.track_insert_key(modulate_track, 0.0, start_color)
	animation.track_insert_key(modulate_track, animation.length - fade_duration, start_color)
	animation.track_insert_key(modulate_track, animation.length, end_color)
	
	# Add to library
	var library = animation_player.get_animation_library("default")
	if library:
		library.add_animation("special_burst", animation)

func _create_combo_bounce_animation() -> void:
	"""Create combo bounce animation"""
	var animation = Animation.new()
	animation.length = effect_duration * 1.2
	
	# Get label path relative to animation player root
	var label_path = _get_label_path()
	
	# Multi-bounce scale track
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath(label_path + ":scale"))
	
	animation.track_insert_key(scale_track, 0.0, Vector2(0.1, 0.1))
	animation.track_insert_key(scale_track, 0.1, Vector2(scale_bounce * 1.5, scale_bounce * 1.5))
	animation.track_insert_key(scale_track, 0.2, Vector2(0.8, 0.8))
	animation.track_insert_key(scale_track, 0.3, Vector2(scale_bounce, scale_bounce))
	animation.track_insert_key(scale_track, 0.5, Vector2(1.0, 1.0))
	
	# Modulate track
	var modulate_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, NodePath(label_path + ":modulate"))
	
	var start_color = label.modulate
	var end_color = Color(start_color.r, start_color.g, start_color.b, 0.0)
	
	animation.track_insert_key(modulate_track, 0.0, start_color)
	animation.track_insert_key(modulate_track, animation.length - fade_duration, start_color)
	animation.track_insert_key(modulate_track, animation.length, end_color)
	
	# Add to library
	var library = animation_player.get_animation_library("default")
	if library:
		library.add_animation("combo_bounce", animation)

func _create_rhythm_pulse_animation() -> void:
	"""Create rhythm pulse animation"""
	var animation = Animation.new()
	animation.length = effect_duration
	
	# Get label path relative to animation player root
	var label_path = _get_label_path()
	
	# Pulsing scale track
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath(label_path + ":scale"))
	
	animation.track_insert_key(scale_track, 0.0, Vector2(0.8, 0.8))
	animation.track_insert_key(scale_track, 0.2, Vector2(1.3, 1.3))
	animation.track_insert_key(scale_track, 0.4, Vector2(0.9, 0.9))
	animation.track_insert_key(scale_track, 0.6, Vector2(1.1, 1.1))
	animation.track_insert_key(scale_track, 0.8, Vector2(1.0, 1.0))
	
	# Modulate track
	var modulate_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, NodePath(label_path + ":modulate"))
	
	var start_color = label.modulate
	var end_color = Color(start_color.r, start_color.g, start_color.b, 0.0)
	
	animation.track_insert_key(modulate_track, 0.0, start_color)
	animation.track_insert_key(modulate_track, animation.length - fade_duration, start_color)
	animation.track_insert_key(modulate_track, animation.length, end_color)
	
	# Add to library
	var library = animation_player.get_animation_library("default")
	if library:
		library.add_animation("rhythm_pulse", animation)

func _create_bounce_animation() -> void:
	var animation = Animation.new()
	animation.length = effect_duration
	
	# Get label path relative to animation player root
	var label_path = _get_label_path()
	
	# Scale track for bounce effect
	var scale_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath(label_path + ":scale"))
	
	# Bounce animation: start small, scale up, then scale down
	animation.track_insert_key(scale_track, 0.0, Vector2(0.1, 0.1))
	animation.track_insert_key(scale_track, 0.2, Vector2(scale_bounce, scale_bounce))
	animation.track_insert_key(scale_track, 0.4, Vector2(1.0, 1.0))
	
	# Modulate track for fade effect
	var modulate_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, NodePath(label_path + ":modulate"))
	
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


## _get_label_path
## Returns the path to the label node relative to animation player root
func _get_label_path() -> String:
	if label and animation_player:
		var root = animation_player.get_node(animation_player.root_node) if animation_player.root_node else animation_player.get_parent()
		if root and label.is_inside_tree():
			return str(root.get_path_to(label))
	return "Label"


# Static method to reset typing combo state (can be called from TypingEffectsManager)
static func reset_typing_combo() -> void:
	typing_combo_count = 0
	last_char_time = 0.0
	rhythm_intervals.clear()
	print("Debug: Typing combo state reset")

# Static factory method to create typing effects
static func create_typing_effect(parent: Node, pos: Vector2, character: String) -> TypingEffect:
	var effect = TypingEffect.new()
	var typing_effect_offset: Vector2 = Vector2(888, -88)
	effect.character_typed = character
	effect.position = pos + typing_effect_offset
	parent.add_child(effect)
	print("Debug: Created TypingEffect for character '", character, "' at position ", effect.position)
	return effect
