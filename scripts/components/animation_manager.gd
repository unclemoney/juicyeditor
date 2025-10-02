extends Node
#class_name AnimationManager

# Juicy Editor - Animation Manager
# Handles typing animations, cursor effects, and other smooth transitions

signal animation_started(animation_name: String)
signal animation_finished(animation_name: String)

@export var enable_typing_animations: bool = true
@export var enable_cursor_animations: bool = true
@export var enable_transition_animations: bool = true
@export var animation_speed_multiplier: float = 1.0

var active_animations: Dictionary = {}
var cursor_pulse_tween: Tween
var typing_effect_tween: Tween
var typing_pause_timer: Timer

# Track original scales to prevent cumulative scaling issues
var original_scales: Dictionary = {}

# Animation configurations
var typing_config: Dictionary = {
	"enabled": true,
	"character_scale_intensity": 1.2,
	"character_scale_duration": 0.15,
	"ripple_effect": true,
	"ripple_intensity": 0.05,
	"ripple_duration": 0.3
}

var cursor_config: Dictionary = {
	"enabled": true,
	"pulse_intensity": 1.1,
	"pulse_duration": 1.0,
	"blink_enabled": true,
	"blink_speed": 1.5
}

var transition_config: Dictionary = {
	"enabled": true,
	"fade_duration": 0.2,
	"slide_duration": 0.3,
	"bounce_intensity": 1.15,
	"elastic_strength": 0.8
}

func _ready() -> void:
	print("Animation Manager initialized")
	_setup_cursor_animations()
	_setup_typing_pause_timer()

func _setup_typing_pause_timer() -> void:
	# Create a timer to pause animations after typing stops
	typing_pause_timer = Timer.new()
	typing_pause_timer.wait_time = 0.5  # 500ms
	typing_pause_timer.one_shot = true
	add_child(typing_pause_timer)
	typing_pause_timer.timeout.connect(_on_typing_pause_timeout)

func _on_typing_pause_timeout() -> void:
	# Stop all typing-related animations when user pauses typing
	_pause_typing_animations()

func _pause_typing_animations() -> void:
	# Stop character animation and ensure scale is reset
	if active_animations.has("character_typed"):
		var existing_tween = active_animations["character_typed"]
		if existing_tween and existing_tween.is_valid():
			existing_tween.kill()
		active_animations.erase("character_typed")
	
	# Reset any controls that may be stuck in scaled state
	for control_id in original_scales:
		var control = instance_from_id(int(control_id))
		if control and is_instance_valid(control):
			control.scale = original_scales[control_id]

func _setup_cursor_animations() -> void:
	# Set up cursor pulse animation
	cursor_pulse_tween = create_tween()
	cursor_pulse_tween.set_loops()
	cursor_pulse_tween.finished.connect(_on_cursor_pulse_finished)

func _on_cursor_pulse_finished() -> void:
	animation_finished.emit("cursor_pulse")

func animate_character_typed(control: Control, character_position: Vector2) -> void:
	if not enable_typing_animations or not typing_config.enabled:
		return
	
	if not control:
		return
	
	animation_started.emit("character_typed")
	
	# Restart the pause timer on each character typed
	if typing_pause_timer:
		typing_pause_timer.stop()
		typing_pause_timer.start()
	
	# Store original scale if not already stored
	var control_id = str(control.get_instance_id())
	if not original_scales.has(control_id):
		original_scales[control_id] = control.scale
	
	# Kill any existing character animation to prevent overlap
	if active_animations.has("character_typed"):
		var existing_tween = active_animations["character_typed"]
		if existing_tween and existing_tween.is_valid():
			existing_tween.kill()
	
	# Create character scale animation
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_BACK)
	
	var original_scale = original_scales[control_id]
	var target_scale = original_scale * typing_config.character_scale_intensity
	var duration = typing_config.character_scale_duration * animation_speed_multiplier
	
	# Reset to original scale first, then animate
	control.scale = original_scale
	scale_tween.tween_property(control, "scale", target_scale, duration * 0.4)
	scale_tween.tween_property(control, "scale", original_scale, duration * 0.6)
	
	# Add ripple effect if enabled
	if typing_config.ripple_effect:
		_create_ripple_effect(control, character_position)
	
	# Store animation reference
	active_animations["character_typed"] = scale_tween
	scale_tween.finished.connect(_on_character_animation_finished)

func _create_ripple_effect(control: Control, _position: Vector2) -> void:
	if not control:
		return
	
	# Create a simple ripple effect by animating modulate
	var ripple_tween = create_tween()
	ripple_tween.set_ease(Tween.EASE_OUT)
	ripple_tween.set_trans(Tween.TRANS_CUBIC)
	
	var original_modulate = control.modulate
	var ripple_color = Color(
		original_modulate.r + 0.2,
		original_modulate.g + 0.2,
		original_modulate.b + 0.2,
		original_modulate.a
	)
	
	var duration = typing_config.ripple_duration * animation_speed_multiplier
	
	ripple_tween.tween_property(control, "modulate", ripple_color, duration * 0.3)
	ripple_tween.tween_property(control, "modulate", original_modulate, duration * 0.7)

func _on_character_animation_finished() -> void:
	active_animations.erase("character_typed")
	animation_finished.emit("character_typed")

func animate_cursor_pulse(control: Control) -> void:
	if not enable_cursor_animations or not cursor_config.enabled:
		return
	
	if not control:
		return
	
	# Don't animate TextEdit controls directly as this affects the entire text field
	if control is TextEdit:
		# For TextEdit, we could animate the caret color instead
		_animate_text_edit_cursor(control)
		return
	
	animation_started.emit("cursor_pulse")
	
	if cursor_pulse_tween:
		cursor_pulse_tween.kill()
	
	cursor_pulse_tween = create_tween()
	cursor_pulse_tween.set_loops()
	cursor_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	cursor_pulse_tween.set_trans(Tween.TRANS_SINE)
	
	var original_scale = control.scale
	var pulse_scale = original_scale * cursor_config.pulse_intensity
	var duration = cursor_config.pulse_duration * animation_speed_multiplier
	
	cursor_pulse_tween.tween_property(control, "scale", pulse_scale, duration * 0.5)
	cursor_pulse_tween.tween_property(control, "scale", original_scale, duration * 0.5)
	
	active_animations["cursor_pulse"] = cursor_pulse_tween

func _animate_text_edit_cursor(text_edit: TextEdit) -> void:
	# Animate the cursor color instead of scaling the entire control
	if not text_edit:
		return
	
	animation_started.emit("text_cursor_pulse")
	
	# Stop any existing cursor animation
	if active_animations.has("text_cursor_pulse"):
		var existing_tween = active_animations["text_cursor_pulse"]
		if existing_tween and existing_tween.is_valid():
			existing_tween.kill()
	
	var cursor_tween = create_tween()
	cursor_tween.set_loops()
	cursor_tween.set_ease(Tween.EASE_IN_OUT)
	cursor_tween.set_trans(Tween.TRANS_SINE)
	
	# Get the current caret color
	var theme_instance = text_edit.get_theme()
	if not theme_instance:
		theme_instance = Theme.new()
		text_edit.set_theme(theme_instance)
	
	var original_color = theme_instance.get_color("caret_color", "TextEdit")
	if original_color == Color.TRANSPARENT:
		original_color = Color.WHITE  # Default fallback
	
	var bright_color = Color(
		min(original_color.r + 0.3, 1.0),
		min(original_color.g + 0.3, 1.0), 
		min(original_color.b + 0.3, 1.0),
		original_color.a
	)
	
	var duration = cursor_config.pulse_duration * animation_speed_multiplier * 0.5
	
	# Animate between original and bright color
	cursor_tween.tween_method(_set_cursor_color.bind(text_edit), original_color, bright_color, duration)
	cursor_tween.tween_method(_set_cursor_color.bind(text_edit), bright_color, original_color, duration)
	
	active_animations["text_cursor_pulse"] = cursor_tween

func _set_cursor_color(text_edit: TextEdit, color: Color) -> void:
	if text_edit and is_instance_valid(text_edit):
		var theme_instance = text_edit.get_theme()
		if theme_instance:
			theme_instance.set_color("caret_color", "TextEdit", color)

func stop_cursor_pulse() -> void:
	if cursor_pulse_tween:
		cursor_pulse_tween.kill()
		active_animations.erase("cursor_pulse")
		animation_finished.emit("cursor_pulse")

func animate_fade_in(control: Control, duration: float = -1) -> void:
	if not enable_transition_animations or not transition_config.enabled:
		control.modulate.a = 1.0
		return
	
	if not control:
		return
	
	var fade_duration = duration if duration > 0 else transition_config.fade_duration * animation_speed_multiplier
	
	animation_started.emit("fade_in")
	
	control.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	fade_tween.tween_property(control, "modulate:a", 1.0, fade_duration)
	fade_tween.finished.connect(func(): animation_finished.emit("fade_in"))

func animate_fade_out(control: Control, duration: float = -1) -> void:
	if not enable_transition_animations or not transition_config.enabled:
		control.modulate.a = 0.0
		return
	
	if not control:
		return
	
	var fade_duration = duration if duration > 0 else transition_config.fade_duration * animation_speed_multiplier
	
	animation_started.emit("fade_out")
	
	var fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	
	fade_tween.tween_property(control, "modulate:a", 0.0, fade_duration)
	fade_tween.finished.connect(func(): animation_finished.emit("fade_out"))

func animate_slide_in(control: Control, direction: Vector2 = Vector2.UP, distance: float = 50.0) -> void:
	if not enable_transition_animations or not transition_config.enabled:
		return
	
	if not control:
		return
	
	animation_started.emit("slide_in")
	
	var original_position = control.position
	var start_position = original_position + (direction * distance)
	
	control.position = start_position
	
	var slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	slide_tween.set_trans(Tween.TRANS_BACK)
	
	var duration = transition_config.slide_duration * animation_speed_multiplier
	slide_tween.tween_property(control, "position", original_position, duration)
	slide_tween.finished.connect(func(): animation_finished.emit("slide_in"))

func animate_bounce_in(control: Control) -> void:
	if not enable_transition_animations or not transition_config.enabled:
		return
	
	if not control:
		return
	
	animation_started.emit("bounce_in")
	
	# Store original scale if not already stored
	var control_id = str(control.get_instance_id())
	if not original_scales.has(control_id):
		original_scales[control_id] = control.scale
	
	var original_scale = original_scales[control_id]
	control.scale = Vector2.ZERO
	
	var bounce_tween = create_tween()
	bounce_tween.set_ease(Tween.EASE_OUT)
	bounce_tween.set_trans(Tween.TRANS_BACK)
	
	var duration = 0.5 * animation_speed_multiplier
	var bounce_scale = original_scale * transition_config.bounce_intensity
	
	bounce_tween.tween_property(control, "scale", bounce_scale, duration * 0.6)
	bounce_tween.tween_property(control, "scale", original_scale, duration * 0.4)
	bounce_tween.finished.connect(func(): animation_finished.emit("bounce_in"))

func animate_elastic_bounce(control: Control, intensity: float = -1) -> void:
	if not enable_transition_animations:
		return
	
	if not control:
		return
	
	var bounce_intensity = intensity if intensity > 0 else transition_config.elastic_strength
	
	animation_started.emit("elastic_bounce")
	
	# Store original scale if not already stored
	var control_id = str(control.get_instance_id())
	if not original_scales.has(control_id):
		original_scales[control_id] = control.scale
	
	var original_scale = original_scales[control_id]
	var elastic_tween = create_tween()
	elastic_tween.set_ease(Tween.EASE_OUT)
	elastic_tween.set_trans(Tween.TRANS_ELASTIC)
	
	var target_scale = original_scale * (1.0 + bounce_intensity)
	var duration = 0.6 * animation_speed_multiplier
	
	elastic_tween.tween_property(control, "scale", target_scale, duration * 0.3)
	elastic_tween.tween_property(control, "scale", original_scale, duration * 0.7)
	elastic_tween.finished.connect(func(): animation_finished.emit("elastic_bounce"))

func animate_button_exit(control: Control) -> void:
	"""Smoothly return button to original scale when mouse exits"""
	if not enable_transition_animations:
		return
	
	if not control:
		return
	
	# Store original scale if not already stored
	var control_id = str(control.get_instance_id())
	if not original_scales.has(control_id):
		original_scales[control_id] = control.scale
		return  # If we just stored it, it's already at original scale
	
	var original_scale = original_scales[control_id]
	
	# Only animate if we're not already at original scale
	if control.scale.is_equal_approx(original_scale):
		return
	
	animation_started.emit("button_exit")
	
	var exit_tween = create_tween()
	exit_tween.set_ease(Tween.EASE_OUT)
	exit_tween.set_trans(Tween.TRANS_QUART)
	
	var duration = 0.2 * animation_speed_multiplier
	exit_tween.tween_property(control, "scale", original_scale, duration)
	exit_tween.finished.connect(func(): animation_finished.emit("button_exit"))

func configure_typing_animations(enabled: bool, scale_intensity: float = 1.2, duration: float = 0.15) -> void:
	typing_config.enabled = enabled
	typing_config.character_scale_intensity = scale_intensity
	typing_config.character_scale_duration = duration

func configure_cursor_animations(enabled: bool, pulse_intensity: float = 1.1, pulse_duration: float = 1.0) -> void:
	cursor_config.enabled = enabled
	cursor_config.pulse_intensity = pulse_intensity
	cursor_config.pulse_duration = pulse_duration

func configure_transitions(enabled: bool, fade_duration: float = 0.2, slide_duration: float = 0.3) -> void:
	transition_config.enabled = enabled
	transition_config.fade_duration = fade_duration
	transition_config.slide_duration = slide_duration

func stop_all_animations() -> void:
	for animation_name in active_animations:
		var tween = active_animations[animation_name]
		if tween and tween.is_valid():
			tween.kill()
	
	active_animations.clear()
	
	if cursor_pulse_tween and cursor_pulse_tween.is_valid():
		cursor_pulse_tween.kill()

func reset_control_scale(control: Control) -> void:
	"""Reset a control to its original scale"""
	if not control:
		return
	
	var control_id = str(control.get_instance_id())
	if original_scales.has(control_id):
		control.scale = original_scales[control_id]

func reset_all_scales() -> void:
	"""Reset all tracked controls to their original scales"""
	original_scales.clear()

func register_control_original_scale(control: Control) -> void:
	"""Manually register a control's original scale"""
	if not control:
		return
	
	var control_id = str(control.get_instance_id())
	if not original_scales.has(control_id):
		original_scales[control_id] = control.scale

func get_animation_info() -> Dictionary:
	return {
		"typing_animations": typing_config.enabled,
		"cursor_animations": cursor_config.enabled,
		"transition_animations": transition_config.enabled,
		"active_animations_count": active_animations.size(),
		"animation_speed": animation_speed_multiplier
	}