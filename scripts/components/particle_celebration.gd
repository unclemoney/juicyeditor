extends Node2D
class_name ParticleCelebration

## Reusable particle celebration effect for XP events
## Spawns confetti/stars with physics-based motion

signal celebration_finished

## Celebration type enum
enum CelebrationType {
	LEVEL_UP,      # Gold particles
	ACHIEVEMENT,   # Rainbow particles
	BOSS_VICTORY   # Cyan/white particles
}

## Configuration
@export var celebration_type: CelebrationType = CelebrationType.LEVEL_UP
@export var particle_count: int = 30
@export var lifetime: float = 2.0
@export var spread_radius: float = 200.0

## Particle sprites (will be created dynamically)
var particles: Array[Node2D] = []

## Color presets
var color_presets: Dictionary = {
	CelebrationType.LEVEL_UP: [
		Color(1.0, 0.84, 0.0, 1.0),  # Gold
		Color(1.0, 0.92, 0.23, 1.0), # Light gold
		Color(0.96, 0.76, 0.03, 1.0) # Dark gold
	],
	CelebrationType.ACHIEVEMENT: [
		Color(1.0, 0.0, 0.0, 1.0),    # Red
		Color(1.0, 0.5, 0.0, 1.0),    # Orange
		Color(1.0, 1.0, 0.0, 1.0),    # Yellow
		Color(0.0, 1.0, 0.0, 1.0),    # Green
		Color(0.0, 0.5, 1.0, 1.0),    # Blue
		Color(0.6, 0.0, 1.0, 1.0)     # Purple
	],
	CelebrationType.BOSS_VICTORY: [
		Color(0.0, 1.0, 1.0, 1.0),    # Cyan
		Color(1.0, 1.0, 1.0, 1.0),    # White
		Color(0.5, 0.8, 1.0, 1.0)     # Light blue
	]
}

## Physics parameters
var gravity: float = 400.0
var initial_velocity_range: Vector2 = Vector2(200, 400)
var drag: float = 0.98

func _ready() -> void:
	# Create particles
	_spawn_particles()
	
	# Auto-cleanup after lifetime
	await get_tree().create_timer(lifetime).timeout
	celebration_finished.emit()
	queue_free()

func _spawn_particles() -> void:
	## Create and configure particle sprites
	var colors = color_presets[celebration_type]
	
	for i in range(particle_count):
		var particle = _create_particle_sprite()
		
		# Random color from preset
		var color_idx = randi() % colors.size()
		particle.modulate = colors[color_idx]
		
		# Random starting position within small radius
		var start_offset = Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		particle.position = start_offset
		
		# Random initial velocity (upward and outward)
		var angle = randf_range(-PI, PI)
		var speed = randf_range(initial_velocity_range.x, initial_velocity_range.y)
		var velocity = Vector2(cos(angle), -abs(sin(angle))) * speed
		
		# Random rotation speed
		var rotation_speed = randf_range(-10.0, 10.0)
		
		# Store particle data
		particle.set_meta("velocity", velocity)
		particle.set_meta("rotation_speed", rotation_speed)
		particle.set_meta("birth_time", Time.get_ticks_msec() / 1000.0)
		
		add_child(particle)
		particles.append(particle)

func _create_particle_sprite() -> Node2D:
	## Create a simple colored rectangle as particle
	var particle = Node2D.new()
	
	# Create polygon for confetti shape
	var polygon = Polygon2D.new()
	
	# Random shape: star or rectangle
	if randf() < 0.5:
		# Star shape
		polygon.polygon = PackedVector2Array([
			Vector2(0, -6),
			Vector2(2, -2),
			Vector2(6, -2),
			Vector2(3, 1),
			Vector2(4, 5),
			Vector2(0, 3),
			Vector2(-4, 5),
			Vector2(-3, 1),
			Vector2(-6, -2),
			Vector2(-2, -2)
		])
	else:
		# Rectangle/diamond
		polygon.polygon = PackedVector2Array([
			Vector2(-4, -6),
			Vector2(4, -6),
			Vector2(4, 6),
			Vector2(-4, 6)
		])
	
	polygon.color = Color.WHITE
	particle.add_child(polygon)
	
	return particle

func _process(delta: float) -> void:
	## Update particle physics
	for particle in particles:
		if not is_instance_valid(particle):
			continue
		
		var velocity: Vector2 = particle.get_meta("velocity")
		var rotation_speed: float = particle.get_meta("rotation_speed")
		var birth_time: float = particle.get_meta("birth_time")
		
		# Apply gravity
		velocity.y += gravity * delta
		
		# Apply drag
		velocity *= drag
		
		# Update position
		particle.position += velocity * delta
		
		# Update rotation
		particle.rotation += rotation_speed * delta
		
		# Fade out near end of lifetime
		var age = (Time.get_ticks_msec() / 1000.0) - birth_time
		var fade_start = lifetime * 0.7
		if age > fade_start:
			var fade_progress = (age - fade_start) / (lifetime - fade_start)
			particle.modulate.a = 1.0 - fade_progress
		
		# Store updated velocity
		particle.set_meta("velocity", velocity)

## Trigger celebration at specific screen position
func trigger_at_position(pos: Vector2) -> void:
	global_position = pos
