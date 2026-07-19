extends Node2D
class_name FlyingLetter

# Juicy Editor - Flying Letter Deletion Effect (Juiced Up)
# Uses TweenFX for stylized trajectories instead of manual physics

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
@export var use_debris_sprites: bool = true

# Juice controls
@export var effect_intensity: float = 1.0

var character_text: String = ""
var start_pos: Vector2

## Font size for the letter label (0 = theme default). Set by the spawner to
## match the editor's current zoomed font size.
var font_size: int = 0

@onready var label: Label
@onready var debris_sprite: AnimatedSprite2D
@onready var cleanup_timer: Timer
@onready var visibility_notifier: VisibleOnScreenNotifier2D

# Debris sprite resources
var debris_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_debris_sprites()
	_setup_components()
	_start_flight()

func reset_for_pool() -> void:
	"""Reset all state for object pool reuse"""
	TweenFX.stop_all(self)
	if label:
		label.scale = Vector2.ONE
		label.modulate = Color.WHITE
		label.rotation = 0.0
		label.visible = true
	if debris_sprite:
		debris_sprite.visible = false
		debris_sprite.scale = Vector2.ONE
		debris_sprite.modulate = Color.WHITE
		debris_sprite.rotation = 0.0
	character_text = ""

func _load_debris_sprites() -> void:
	for i in range(1, 9):
		var texture_path = "res://effects/sprites/deletion/debris_%02d.png" % i
		if ResourceLoader.exists(texture_path):
			var texture = load(texture_path) as Texture2D
			if texture:
				debris_textures.append(texture)

func _setup_components() -> void:
	# Create Label for character display
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = character_text
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	
	# Create debris sprite for enhanced visual effects
	if use_debris_sprites and debris_textures.size() > 0:
		debris_sprite = AnimatedSprite2D.new()
		debris_sprite.visible = false
		add_child(debris_sprite)
		_setup_debris_sprite()
	
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
	
	if label:
		visibility_notifier.rect = Rect2(-10, -10, 20, 20)

func _setup_debris_sprite() -> void:
	if not debris_sprite or debris_textures.size() == 0:
		return
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("debris")
	sprite_frames.set_animation_speed("debris", 1.0)
	sprite_frames.set_animation_loop("debris", false)
	
	var random_texture = debris_textures[randi() % debris_textures.size()]
	sprite_frames.add_frame("debris", random_texture)
	
	debris_sprite.sprite_frames = sprite_frames
	debris_sprite.play("debris")
	debris_sprite.scale = Vector2(0.8, 0.8)

func _start_flight() -> void:
	start_pos = position
	
	# Randomize initial color
	if label:
		label.modulate = Color(
			randf_range(0.7, 1.0),
			randf_range(0.7, 1.0),
			randf_range(0.7, 1.0),
			1.0
		)
	
	# Calculate flight parameters scaled by intensity
	var launch_x = randf_range(x_speed_min, x_speed_max) * effect_intensity
	var launch_y = randf_range(y_speed_min, y_speed_max) * effect_intensity
	var rot_speed = randf_range(rotations_per_s_min, rotations_per_s_max) * effect_intensity
	
	# End position (fallen down and drifted horizontally)
	# launch_x is px/s, so multiply by duration (seconds) for total travel
	var end_x = start_pos.x + launch_x * effect_duration
	var end_y = start_pos.y + 200.0 * effect_intensity
	var arc_height = abs(launch_y) * effect_intensity
	
	# Parabolic arc trajectory via tween_method (tracked by TweenFX)
	var pos_tween = TweenFX.tween_method(self, func(t: float):
		var x = lerpf(start_pos.x, end_x, t)
		# Parabola peak: 4 * h * t * (1 - t) gives peak at t = 0.5
		var y = lerpf(start_pos.y, end_y, t) - 4.0 * arc_height * t * (1.0 - t)
		position = Vector2(x, y)
	, 0.0, 1.0, effect_duration)
	if pos_tween:
		pos_tween.set_trans(Tween.TRANS_LINEAR)
	
	# Spin
	TweenFX.spin(self, effect_duration, rot_speed * effect_duration / 360.0)
	
	# Fade out near end of life
	var fade_delay = max(0.0, fade_start_time)
	var fade_dur = effect_duration - fade_delay
	if fade_dur > 0:
		TweenFX.delayed_callback(self, fade_delay, func():
			TweenFX.fade_out(label, fade_dur)
			if debris_sprite:
				TweenFX.fade_out(debris_sprite, fade_dur)
		)
	
	# Debris sprite tumbling chaos
	if debris_sprite and debris_sprite.visible:
		if randf() < 0.1:
			# 10% chance of glitch corruption
			TweenFX.glitch(debris_sprite, 0.5, 8.0)
		else:
			TweenFX.fidget(debris_sprite, 0.8, 6)
	
	# Start cleanup timer
	cleanup_timer.start()

func _on_screen_exited() -> void:
	queue_free()

func _on_cleanup_timeout() -> void:
	queue_free()

static func create_flying_letter(parent: Node, pos: Vector2, character: String) -> FlyingLetter:
	var letter = FlyingLetter.new()
	letter.character_text = character
	letter.position = pos
	parent.add_child(letter)
	return letter

static func create_flying_letter_custom(parent: Node, pos: Vector2, character: String, direction: Vector2 = Vector2.LEFT) -> FlyingLetter:
	var letter = FlyingLetter.new()
	letter.character_text = character
	letter.position = pos
	
	if direction.x > 0:
		letter.x_speed_min = 100.0
		letter.x_speed_max = 300.0
	else:
		letter.x_speed_min = -300.0
		letter.x_speed_max = -100.0
	
	parent.add_child(letter)
	return letter
