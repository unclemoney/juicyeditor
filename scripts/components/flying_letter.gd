extends Node2D
class_name FlyingLetter

# Juicy Editor - Flying Letter Deletion Effect
# Inspired by TEXTREME's flying letter effect for text deletion
# Creates physics-based letter animations that fly off when text is deleted

@export var rotations_per_s_min: float = 7.0
@export var rotations_per_s_max: float = 13.0

@export var x_speed_min: float = -300.0
@export var x_speed_max: float = -100.0

@export var y_speed_min: float = -220.0
@export var y_speed_max: float = -108.0

@export var gravity_min: float = 300.0
@export var gravity_max: float = 400.0

@export var effect_duration: float = 3.0
@export var fade_start_time: float = 2.0

var linear_velocity: Vector2
var angular_velocity: float = 0.0
var gravity: float = 0.0
var character_text: String = ""
var start_time: float = 0.0

@onready var label: Label
@onready var cleanup_timer: Timer
@onready var visibility_notifier: VisibleOnScreenNotifier2D

func _ready() -> void:
	_setup_components()
	_setup_physics()
	start_time = Time.get_unix_time_from_system()

func _setup_components() -> void:
	# Create Label for character display
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = character_text
	add_child(label)
	
	# Create visibility notifier to clean up when off-screen
	visibility_notifier = VisibleOnScreenNotifier2D.new()
	add_child(visibility_notifier)
	visibility_notifier.screen_exited.connect(_on_screen_exited)
	
	# Create cleanup timer as backup
	cleanup_timer = Timer.new()
	cleanup_timer.wait_time = effect_duration
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(_on_cleanup_timeout)
	add_child(cleanup_timer)
	cleanup_timer.start()
	
	# Set up visibility notifier rect based on label
	if label:
		# Use a reasonable default rect size for the notifier
		visibility_notifier.rect = Rect2(-10, -10, 20, 20)

func _setup_physics() -> void:
	# Calculate effect scale based on font size (default to reasonable values)
	var effect_scale = 1.0
	# Note: Using default font size since we don't have a specific font theme name
	# Could be enhanced later to use actual font metrics
	
	# Randomize horizontal speed
	var temp_x = randf_range(x_speed_min / effect_scale, x_speed_max / effect_scale)
	var temp_y = randf_range(y_speed_min, y_speed_max)
	
	linear_velocity = Vector2(temp_x, temp_y)
	gravity = randf_range(gravity_min * effect_scale, gravity_max * effect_scale)
	angular_velocity = randf_range(rotations_per_s_min / effect_scale, rotations_per_s_max / effect_scale)
	
	# Randomize initial color for variety
	if label:
		label.modulate = Color(
			randf_range(0.7, 1.0),
			randf_range(0.7, 1.0),
			randf_range(0.7, 1.0),
			1.0
		)

func _process(delta: float) -> void:
	# Apply physics
	position += linear_velocity * delta
	rotation += angular_velocity * delta
	linear_velocity += Vector2(0, gravity * delta)
	
	# Apply fade effect near end of life
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - start_time
	
	if elapsed > fade_start_time:
		var fade_progress = (elapsed - fade_start_time) / (effect_duration - fade_start_time)
		var alpha = 1.0 - fade_progress
		if label:
			label.modulate.a = max(0.0, alpha)

func _on_screen_exited() -> void:
	"""Clean up when letter flies off screen"""
	queue_free()

func _on_cleanup_timeout() -> void:
	"""Clean up after maximum duration"""
	queue_free()

# Static factory method to create flying letters
static func create_flying_letter(parent: Node, pos: Vector2, character: String) -> FlyingLetter:
	var letter = FlyingLetter.new()
	letter.character_text = character
	letter.position = pos
	parent.add_child(letter)
	return letter

# Enhanced factory method with customizable physics
static func create_flying_letter_custom(parent: Node, pos: Vector2, character: String, direction: Vector2 = Vector2.LEFT) -> FlyingLetter:
	var letter = FlyingLetter.new()
	letter.character_text = character
	letter.position = pos
	
	# Customize physics based on direction
	if direction.x > 0:  # Flying right
		letter.x_speed_min = 100.0
		letter.x_speed_max = 300.0
	else:  # Flying left (default)
		letter.x_speed_min = -300.0
		letter.x_speed_max = -100.0
	
	parent.add_child(letter)
	return letter