extends Control
class_name JuicyLucy

## Juicy Lucy - The Clippy-inspired text editor assistant
## Lucy watches the user type and offers witty commentary and encouragement
## with animated eyes that follow the cursor and expressive eyebrows.

signal phrase_displayed(phrase: String)
signal emotion_changed(emotion: String)

## The main body sprite
@onready var body_sprite: Sprite2D = $Body

## The eyes sprite layer
@onready var eyes_sprite: Sprite2D = $Eyes

## Left pupil marker
@onready var left_pupil: ColorRect = $Eyes/LeftPupil

## Right pupil marker
@onready var right_pupil: ColorRect = $Eyes/RightPupil

## Left eyebrow line
@onready var left_eyebrow: Line2D = $Eyebrows/LeftEyebrow

## Right eyebrow line
@onready var right_eyebrow: Line2D = $Eyebrows/RightEyebrow

## Dialog panel background
@onready var dialog_panel: NinePatchRect = $DialogPanel

## Dialog box for Lucy's commentary
@onready var dialog_box: RichTextLabel = $DialogBox

## Animation player for eyebrow and body animations
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Timer for random commentary
@onready var comment_timer: Timer = $CommentTimer

## Timer for random eye blinking
var blink_timer: Timer = null

## Blink animation variables
var blink_frames: Array[Texture2D] = []
var is_blinking: bool = false
var current_blink_frame: int = 0
var blink_frame_duration: float = 0.01  # Will be randomized per frame
var blink_frame_timer: float = 0.0
var blinks_remaining: int = 0  # Number of blinks left in current cycle
var blink_pause_timer: float = 0.0  # Pause between consecutive blinks
var blink_pause_duration: float = 0.1  # 100ms pause between blinks
var is_blink_pausing: bool = false

## Blink interval range (in seconds)
@export var blink_interval_min: float = 3.0
@export var blink_interval_max: float = 8.0

## Eye center positions relative to the Eyes node
@export var left_eye_center: Vector2 = Vector2(-12, -5)
@export var right_eye_center: Vector2 = Vector2(12, -5)

## Maximum pupil movement radius
@export var pupil_radius: float = 8.0

## Eyeball radius for collision bounds
@export var eyeball_radius: float = 3.0

## Pupil size
@export var pupil_size: Vector2 = Vector2(4, 4)

## Eyebrow length
@export var eyebrow_length: float = 10.0

## Eyebrow thickness
@export var eyebrow_thickness: float = 2.0

## How often Lucy might comment (in seconds) - increased frequency
@export var comment_interval_min: float = 8.0
@export var comment_interval_max: float = 25.0

## Witty phrases categorized by context
var phrases: Dictionary = {
	"typing": [
		"Did you really mean to type that? I mean I guess you can.",
		"Interesting choice of words there...",
		"Are you sure that's how you spell that?",
		"Bold move, let's see how that works out.",
		"I'm not judging, but... actually, I am judging a little.",
		"That's one way to do it, I suppose.",
		"Wow, creative syntax! Does it compile though?",
		"I've seen worse... not much worse, but worse.",
	],
	"idle": [
		"Hello? Anyone there?",
		"Don't mind me, just hanging out...",
		"You could be typing, you know.",
		"I'm watching you... 👁️",
		"This silence is deafening.",
		"Maybe take a break? Or keep typing. Your choice.",
		"I wonder what you're thinking about...",
	],
	"saving": [
		"Maybe you should save the file, because I'm not going to do it for you.",
		"When's the last time you saved? Just wondering...",
		"Save early, save often, they say.",
		"Your unsaved changes are giving me anxiety.",
		"CTRL+S is your friend. Use it.",
	],
	"encouragement": [
		"You're doing great!",
		"Keep it up!",
		"Nice work so far!",
		"I believe in you!",
		"You've got this!",
		"Looking good!",
		"Impressive!",
	],
	"long_line": [
		"That's quite a long line you've got there.",
		"Ever heard of word wrap?",
		"Maybe break that up a bit?",
		"Someone's being verbose today!",
	],
	"delete": [
		"Oops! Delete delete delete!",
		"Ctrl+Z is a wonderful thing.",
		"Everyone makes mistakes!",
		"Better to delete than to compile with errors.",
	]
}

## Current emotional state
var current_emotion: String = "neutral"

## Track recent characters typed for context-aware comments
var recent_text: String = ""
var chars_since_last_comment: int = 0

## Spell checker reference
var spell_checker: Node = null

## Spell check timer (2-3 second delay)
var spell_check_timer: Timer = null

## Last text that was spell checked
var last_checked_text: String = ""

## Sassy spelling error phrases
var spelling_error_phrases: Array = [
	"You didn't spell '%s' correctly, you dumb bitch.",
	"Really? '%s'? That's not even close to a real word.",
	"I'm pretty sure '%s' isn't how you spell that, genius.",
	"'%s'? Did you even try to spell that correctly?",
	"Oh honey, '%s' is not a word. Not even a little bit.",
	"'%s'... Are you having a stroke or just can't spell?",
	"The word is '%s', not whatever the hell you just typed.",
	"'%s'? Maybe try using a dictionary sometime.",
	"I've seen toddlers spell better than '%s'. Come on.",
	"'%s' is giving me a headache. Please fix it.",
]

func _ready() -> void:
	_setup_pupils()
	_setup_eyebrows()
	_setup_dialog_box()
	_start_comment_timer()
	_setup_click_detection()
	_setup_spell_checker()
	_load_blink_frames()
	_setup_blink_timer()

func _setup_click_detection() -> void:
	if body_sprite:
		body_sprite.set_meta("clickable", true)
	
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_lucy_clicked()

func _on_lucy_clicked() -> void:
	var random_action: int = randi() % 3
	
	# Always play a body animation when clicked
	_play_random_body_animation()
	
	match random_action:
		0:
			_say_phrase(phrases["encouragement"].pick_random())
			_set_emotion("happy")
		1:
			_say_phrase(phrases["idle"].pick_random())
			_set_emotion("curious")
		2:
			_say_phrase(phrases["typing"].pick_random())
			_set_emotion("skeptical")

func _setup_pupils() -> void:
	if left_pupil:
		left_pupil.size = pupil_size
		left_pupil.color = Color.BLACK
		left_pupil.position = left_eye_center - pupil_size / 2
	
	if right_pupil:
		right_pupil.size = pupil_size
		right_pupil.color = Color.BLACK
		right_pupil.position = right_eye_center - pupil_size / 2

func _setup_eyebrows() -> void:
	if left_eyebrow:
		left_eyebrow.width = eyebrow_thickness
		left_eyebrow.default_color = Color.BLACK
		left_eyebrow.clear_points()
		left_eyebrow.add_point(Vector2(-eyebrow_length / 2, 0))
		left_eyebrow.add_point(Vector2(eyebrow_length / 2, 0))
		left_eyebrow.position = left_eye_center + Vector2(2, -15)
	
	if right_eyebrow:
		right_eyebrow.width = eyebrow_thickness
		right_eyebrow.default_color = Color.BLACK
		right_eyebrow.clear_points()
		right_eyebrow.add_point(Vector2(-eyebrow_length / 2, 0))
		right_eyebrow.add_point(Vector2(eyebrow_length / 2, 0))
		right_eyebrow.position = right_eye_center + Vector2(-2, -15)

func _setup_dialog_box() -> void:
	if dialog_box:
		dialog_box.visible = false
		dialog_box.bbcode_enabled = true
		dialog_box.fit_content = true

func _start_comment_timer() -> void:
	if comment_timer:
		comment_timer.wait_time = randf_range(comment_interval_min, comment_interval_max)
		comment_timer.timeout.connect(_on_comment_timer_timeout)
		comment_timer.start()

func _setup_spell_checker() -> void:
	# Create and add spell checker as child
	var SymSpellChecker: GDScript = load("res://scripts/components/symspell_checker.gd")
	if SymSpellChecker:
		spell_checker = SymSpellChecker.new()
		add_child(spell_checker)
		print("JuicyLucy: Spell checker initialized")
	
	# Create spell check timer (2-3 second delay)
	spell_check_timer = Timer.new()
	spell_check_timer.one_shot = true
	spell_check_timer.timeout.connect(_on_spell_check_timer_timeout)
	add_child(spell_check_timer)

func _load_blink_frames() -> void:
	## Load all 8 blink animation frames
	for i in range(1, 9):
		var frame_path = "res://assets/ui/icons/juicy_lucy_south_eyes%d.png" % i
		if ResourceLoader.exists(frame_path):
			var texture = load(frame_path) as Texture2D
			if texture:
				blink_frames.append(texture)
			else:
				print("JuicyLucy: Failed to load blink frame: ", frame_path)
		else:
			print("JuicyLucy: Blink frame not found: ", frame_path)
	
	if blink_frames.size() == 8:
		print("JuicyLucy: Successfully loaded all 8 blink frames")
	else:
		print("JuicyLucy: Warning - Only loaded ", blink_frames.size(), " blink frames")

func _setup_blink_timer() -> void:
	## Setup timer for random eye blinking
	blink_timer = Timer.new()
	blink_timer.name = "BlinkTimer"
	blink_timer.one_shot = true
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	add_child(blink_timer)
	
	# Start the first blink cycle
	_start_next_blink_cycle()

func _start_next_blink_cycle() -> void:
	## Schedule the next random blink
	if blink_timer:
		var wait_time = randf_range(blink_interval_min, blink_interval_max)
		blink_timer.wait_time = wait_time
		blink_timer.start()

func _on_blink_timer_timeout() -> void:
	## Start a blink animation when timer expires
	if not is_blinking and blink_frames.size() == 8:
		# Random number of blinks (1-3)
		blinks_remaining = randi_range(1, 3)
		_start_blink_animation()
	
	# Schedule next blink
	_start_next_blink_cycle()

func _start_blink_animation() -> void:
	## Begin the 8-frame blink animation
	is_blinking = true
	current_blink_frame = 0
	blink_frame_timer = 0.0
	is_blink_pausing = false
	
	# Hide pupils during blink
	if left_pupil:
		left_pupil.visible = false
	if right_pupil:
		right_pupil.visible = false
	
	# Randomize frame duration for this blink (between 10ms and 50ms)
	blink_frame_duration = randf_range(0.01, 0.05)

func _process(_delta: float) -> void:
	_update_pupil_tracking()
	_update_blink_animation(_delta)

func _update_blink_animation(delta: float) -> void:
	## Update blink animation frame by frame
	if not is_blinking or blink_frames.is_empty():
		return
	
	# Handle pause between consecutive blinks
	if is_blink_pausing:
		blink_pause_timer += delta
		if blink_pause_timer >= blink_pause_duration:
			# Pause complete, start next blink
			is_blink_pausing = false
			blink_pause_timer = 0.0
			current_blink_frame = 0
			blink_frame_timer = 0.0
			# Randomize frame duration for next blink
			blink_frame_duration = randf_range(0.01, 0.05)
		return
	
	blink_frame_timer += delta
	
	if blink_frame_timer >= blink_frame_duration:
		blink_frame_timer = 0.0
		
		# Apply current frame texture
		if eyes_sprite and current_blink_frame < blink_frames.size():
			eyes_sprite.texture = blink_frames[current_blink_frame]
		
		current_blink_frame += 1
		
		# Check if single blink animation is complete
		if current_blink_frame >= blink_frames.size():
			blinks_remaining -= 1
			
			if blinks_remaining > 0:
				# More blinks to do, enter pause state
				is_blink_pausing = true
			else:
				# All blinks complete
				_end_blink_animation()

func _end_blink_animation() -> void:
	## End blink and reset to normal eyes
	is_blinking = false
	current_blink_frame = 0
	blinks_remaining = 0
	is_blink_pausing = false
	
	# Show pupils again
	if left_pupil:
		left_pupil.visible = true
	if right_pupil:
		right_pupil.visible = true
	
	# Reset to normal eyes texture
	if eyes_sprite:
		var normal_eyes_path = "res://assets/ui/icons/juicy_lucy_south_eyes.png"
		if ResourceLoader.exists(normal_eyes_path):
			eyes_sprite.texture = load(normal_eyes_path) as Texture2D

## Update pupils to look at mouse cursor
func _update_pupil_tracking() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	if eyes_sprite and left_pupil and right_pupil:
		var eyes_global_pos: Vector2 = eyes_sprite.global_position
		
		var left_eye_global: Vector2 = eyes_global_pos + left_eye_center
		var left_direction: Vector2 = (mouse_pos - left_eye_global).normalized()
		var left_distance: float = (mouse_pos - left_eye_global).length() * 0.1
		var left_offset: Vector2 = left_direction * min(pupil_radius, left_distance)
		
		if left_offset.length() > eyeball_radius:
			left_offset = left_offset.normalized() * eyeball_radius
		
		left_pupil.position = left_eye_center + left_offset - pupil_size / 2
		
		var right_eye_global: Vector2 = eyes_global_pos + right_eye_center
		var right_direction: Vector2 = (mouse_pos - right_eye_global).normalized()
		var right_distance: float = (mouse_pos - right_eye_global).length() * 0.1
		var right_offset: Vector2 = right_direction * min(pupil_radius, right_distance)
		
		if right_offset.length() > eyeball_radius:
			right_offset = right_offset.normalized() * eyeball_radius
		
		right_pupil.position = right_eye_center + right_offset - pupil_size / 2

## Called when user types something
func on_text_changed(new_text: String) -> void:
	recent_text = new_text
	chars_since_last_comment += 1
	
	# Restart spell check timer (2-3 second delay)
	if spell_check_timer:
		spell_check_timer.stop()
		spell_check_timer.wait_time = randf_range(2.0, 3.0)
		spell_check_timer.start()
	
	# Occasionally do a quick animation while user is typing (5% chance)
	if randf() < 0.05:
		_play_random_body_animation()
	
	if chars_since_last_comment > 50 and randf() < 0.05:
		_make_typing_comment()
		chars_since_last_comment = 0

## Called when user hasn't typed in a while
func on_idle() -> void:
	if randf() < 0.5:  # Increased from 0.3 to 0.5
		_say_phrase(phrases["idle"].pick_random())

## Called when file should be saved
func on_save_reminder() -> void:
	_say_phrase(phrases["saving"].pick_random())
	_set_emotion("concerned")
	_play_random_body_animation()

## Called when user deletes a lot of text
func on_delete_spree() -> void:
	_say_phrase(phrases["delete"].pick_random())
	_set_emotion("surprised")
	_play_random_body_animation()

## Show encouragement
func encourage() -> void:
	_say_phrase(phrases["encouragement"].pick_random())
	_set_emotion("happy")
	_play_random_body_animation()

func _make_typing_comment() -> void:
	if recent_text.length() > 100:
		_say_phrase(phrases["long_line"].pick_random())
		_set_emotion("skeptical")
	else:
		_say_phrase(phrases["typing"].pick_random())
		_set_emotion("curious")

func _say_phrase(phrase: String) -> void:
	if dialog_box and dialog_panel:
		dialog_box.text = "[wave][center]" + phrase + "[/center][/wave]"
		
		# Set a reasonable width for the dialog box (200 pixels)
		var dialog_width: float = 200.0
		dialog_box.custom_minimum_size.x = dialog_width
		
		# Make visible to calculate size
		dialog_box.visible = true
		
		# Wait a frame for the RichTextLabel to calculate its content height
		await get_tree().process_frame
		
		# Get the content height and add padding
		var content_height: float = dialog_box.get_content_height()
		var padding: Vector2 = Vector2(10, 10)  # 5px padding on each side
		
		# Calculate final sizes
		var dialog_box_size: Vector2 = Vector2(dialog_width, content_height)
		var panel_size: Vector2 = dialog_box_size + padding
		
		# Update dialog box position and size
		dialog_box.size = dialog_box_size
		dialog_box.position = Vector2(-dialog_box_size.x / 2, 32)
		
		# Update dialog panel position and size to match
		dialog_panel.size = panel_size
		dialog_panel.position = Vector2(-panel_size.x / 2, 27)
		
		# Bouncy tween animation for opening
		dialog_panel.visible = true
		dialog_panel.scale = Vector2.ZERO
		
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.4)
		
		phrase_displayed.emit(phrase)
		
		# Play a random body animation
		_play_random_body_animation()
		
		await get_tree().create_timer(5.0).timeout
		
		# Bouncy tween animation for closing
		if dialog_box and dialog_panel:
			var close_tween: Tween = create_tween()
			close_tween.set_ease(Tween.EASE_IN)
			close_tween.set_trans(Tween.TRANS_BACK)
			close_tween.tween_property(dialog_panel, "scale", Vector2.ZERO, 0.3)
			
			await close_tween.finished
			
			dialog_box.visible = false
			dialog_panel.visible = false
			dialog_panel.scale = Vector2.ONE  # Reset scale for next time

func _set_emotion(emotion: String) -> void:
	current_emotion = emotion
	emotion_changed.emit(emotion)
	
	match emotion:
		"happy":
			_animate_eyebrows("raise")
		"surprised":
			_animate_eyebrows("raise_high")
		"concerned":
			_animate_eyebrows("furrow")
		"skeptical":
			_animate_eyebrows("skeptical")
		"curious":
			_animate_eyebrows("raise_slight")
		"excited":
			_animate_eyebrows("excited")
		"upset":
			_animate_eyebrows("upset")
		_:
			_animate_eyebrows("neutral")

func _animate_eyebrows(style: String) -> void:
	if not animation_player:
		return
	
	if animation_player.has_animation(style):
		animation_player.play(style)

## Play a random body animation to make Lucy more lively
func _play_random_body_animation() -> void:
	if not animation_player:
		return
	
	var body_animations: Array = ["bounce", "squish"]
	var random_animation: String = body_animations.pick_random()
	
	if animation_player.has_animation(random_animation):
		animation_player.play(random_animation)

func _on_comment_timer_timeout() -> void:
	# Increased frequency - 70% chance of commenting instead of 40%
	if randf() < 0.7:
		on_idle()
		# Also do a random animation when commenting
		_play_random_body_animation()
	
	comment_timer.wait_time = randf_range(comment_interval_min, comment_interval_max)
	comment_timer.start()

## Called when spell check timer times out (after 2-3 seconds of no typing)
func _on_spell_check_timer_timeout() -> void:
	if not spell_checker or recent_text == last_checked_text:
		return
	
	# Only check if spell checker is loaded
	if not spell_checker.is_loaded:
		return
	
	last_checked_text = recent_text
	
	# Check for spelling errors
	var errors: Array = spell_checker.check_text(recent_text)
	
	if errors.size() > 0:
		# Pick a random error to complain about
		var error: Dictionary = errors.pick_random()
		var misspelled_word: String = error.word
		
		# Get suggestions (if any)
		var suggestions: Array = error.suggestions
		var suggestion_text: String = ""
		if suggestions.size() > 0:
			suggestion_text = "Did you mean '%s'?" % suggestions[0].term
		
		# Show upset eyebrows and sassy message
		_set_emotion("upset")
		var phrase: String = spelling_error_phrases.pick_random() % misspelled_word
		
		if suggestion_text:
			phrase += " " + suggestion_text
		
		_say_phrase(phrase)
		
		print("JuicyLucy: Found spelling error: %s" % misspelled_word)

## Public method to manually trigger spell check
func check_spelling_now() -> void:
	if spell_check_timer:
		spell_check_timer.stop()
		_on_spell_check_timer_timeout()
