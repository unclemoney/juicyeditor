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

## How often Lucy might comment (in seconds)
@export var comment_interval_min: float = 15.0
@export var comment_interval_max: float = 45.0

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

func _ready() -> void:
	_setup_pupils()
	_setup_eyebrows()
	_setup_dialog_box()
	_start_comment_timer()
	_setup_click_detection()

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
	
	match random_action:
		0:
			_say_phrase(phrases["encouragement"].pick_random())
			_set_emotion("happy")
			_perform_body_animation("bounce")
		1:
			_say_phrase(phrases["idle"].pick_random())
			_set_emotion("curious")
			_perform_body_animation("squish")
		2:
			_say_phrase(phrases["typing"].pick_random())
			_set_emotion("skeptical")

func _perform_body_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

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

func _process(_delta: float) -> void:
	_update_pupil_tracking()

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
	
	if chars_since_last_comment > 50 and randf() < 0.05:
		_make_typing_comment()
		chars_since_last_comment = 0

## Called when user hasn't typed in a while
func on_idle() -> void:
	if randf() < 0.3:
		_say_phrase(phrases["idle"].pick_random())

## Called when file should be saved
func on_save_reminder() -> void:
	_say_phrase(phrases["saving"].pick_random())
	_set_emotion("concerned")

## Called when user deletes a lot of text
func on_delete_spree() -> void:
	_say_phrase(phrases["delete"].pick_random())
	_set_emotion("surprised")

## Show encouragement
func encourage() -> void:
	_say_phrase(phrases["encouragement"].pick_random())
	_set_emotion("happy")

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
		dialog_box.visible = true
		dialog_panel.visible = true
		phrase_displayed.emit(phrase)
		
		await get_tree().create_timer(5.0).timeout
		
		if dialog_box and dialog_panel:
			dialog_box.visible = false
			dialog_panel.visible = false

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

func _on_comment_timer_timeout() -> void:
	if randf() < 0.4:
		on_idle()
	
	comment_timer.wait_time = randf_range(comment_interval_min, comment_interval_max)
	comment_timer.start()
