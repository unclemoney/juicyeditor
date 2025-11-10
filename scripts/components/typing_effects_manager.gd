extends Node
#class_name TypingEffectsManager

# Juicy Editor - Typing Effects Manager
# Manages fun typing animations and effects spawned during text editing
# Uses node-based approach inspired by ridiculous_coding plugin

signal effect_spawned(character: String, position: Vector2)

@export var enable_typing_effects: bool = true
@export var enable_deletion_effects: bool = true
@export var enable_newline_effects: bool = true
@export var enable_flying_letters: bool = true  # New: Enable flying letter deletion effects
@export var max_active_effects: int = 50  # Prevent memory issues

# Effect configuration
@export var typing_effect_scene: PackedScene
@export var deletion_effect_scene: PackedScene
@export var newline_effect_scene: PackedScene

# Runtime state
var active_effects: Array[Node] = []
var text_editor: TextEdit
var last_text_length: int = 0
var last_caret_line: int = 0
var previous_text: String = ""  # Store previous text to detect which character was deleted

# Deletion scaling reset timer
var deletion_reset_timer: Timer

# Object pooling for performance
var effect_pool: Node

func _ready() -> void:
	# Setup object pool for performance optimization
	_setup_effect_pool()
	
	# Setup deletion reset timer
	_setup_deletion_reset_timer()
	
	print("TypingEffectsManager ready with object pooling")

func _setup_deletion_reset_timer() -> void:
	"""Setup timer to reset deletion scaling when typing stops"""
	deletion_reset_timer = Timer.new()
	deletion_reset_timer.wait_time = 2.0  # Reset after 2 seconds of no typing
	deletion_reset_timer.one_shot = true
	deletion_reset_timer.timeout.connect(_on_deletion_reset_timeout)
	add_child(deletion_reset_timer)

func _on_deletion_reset_timeout() -> void:
	"""Reset deletion scale when typing stops"""
	# Call the static reset method directly
	var deletion_effect_script = preload("res://scripts/components/deletion_effect.gd")
	deletion_effect_script.reset_deletion_scale()
	print("Reset deletion scale due to typing inactivity")

func _setup_effect_pool() -> void:
	"""Initialize object pool for effect optimization"""
	var pool_script = preload("res://scripts/components/effect_pool.gd")
	effect_pool = Node.new()
	effect_pool.set_script(pool_script)
	effect_pool.name = "EffectPool"
	add_child(effect_pool)
	
	# Connect pool statistics for monitoring
	if effect_pool.has_signal("pool_stats_updated"):
		effect_pool.pool_stats_updated.connect(_on_pool_stats_updated)

func _on_pool_stats_updated(pool_name: String, active: int, _available: int) -> void:
	"""Monitor pool statistics for debugging"""
	if active > 50:  # Warn if we have too many active effects
		print("Warning: High effect count in ", pool_name, " pool: ", active, " active")

func setup_text_editor(editor: TextEdit) -> void:
	"""Connect this manager to a text editor"""
	if text_editor and text_editor.text_changed.is_connected(_on_text_changed):
		text_editor.text_changed.disconnect(_on_text_changed)
	if text_editor and text_editor.caret_changed.is_connected(_on_caret_changed):
		text_editor.caret_changed.disconnect(_on_caret_changed)
	
	text_editor = editor
	if text_editor:
		text_editor.text_changed.connect(_on_text_changed)
		text_editor.caret_changed.connect(_on_caret_changed)
		last_text_length = text_editor.text.length()
		last_caret_line = text_editor.get_caret_line()
		previous_text = text_editor.text  # Initialize previous text
		print("TypingEffectsManager connected to text editor")

func _on_text_changed() -> void:
	if not enable_typing_effects or not text_editor:
		return
	
	var current_length = text_editor.text.length()
	var caret_position = text_editor.get_caret_draw_pos()
	
	# Determine what type of change occurred
	if current_length > last_text_length:
		# Text was added (typing)
		var characters_added = current_length - last_text_length
		var last_char = ""
		
		# Get the last character typed
		if current_length > 0:
			var caret_column = text_editor.get_caret_column()
			var caret_line = text_editor.get_caret_line()
			var line_text = text_editor.get_line(caret_line)
			
			if caret_column > 0 and caret_column <= line_text.length():
				last_char = line_text[caret_column - 1]
			elif characters_added == 1:
				# Fallback: get last character from entire text
				last_char = text_editor.text[current_length - 1]
		
		_spawn_typing_effect(caret_position, last_char)
		
	elif current_length < last_text_length and enable_deletion_effects:
		# Text was deleted - get the deleted character if possible
		var deleted_char = _get_deleted_character()
		_spawn_deletion_effect(caret_position, deleted_char)
	
	last_text_length = current_length
	previous_text = text_editor.text  # Update previous text

func _on_caret_changed() -> void:
	if not enable_newline_effects or not text_editor:
		return
	
	var current_line = text_editor.get_caret_line()
	if current_line != last_caret_line:
		# Line changed (newline effect)
		var caret_position = text_editor.get_caret_draw_pos()
		_spawn_newline_effect(caret_position)
	
	last_caret_line = current_line

func _get_deleted_character() -> String:
	"""Attempt to determine what character was deleted by comparing text"""
	if not text_editor or previous_text.is_empty():
		return ""
	
	var current_text = text_editor.text
	var caret_pos = text_editor.get_caret_column()
	var caret_line = text_editor.get_caret_line()
	
	# Simple heuristic: if only one character difference, try to find it
	if abs(current_text.length() - previous_text.length()) == 1:
		# For now, return a generic character - could be enhanced
		# to do proper diff comparison
		if caret_pos > 0 and caret_line < previous_text.split("\n").size():
			var prev_lines = previous_text.split("\n")
			var prev_line = prev_lines[caret_line] if caret_line < prev_lines.size() else ""
			if caret_pos <= prev_line.length():
				return prev_line[caret_pos - 1] if caret_pos > 0 else prev_line[0]
	
	# Fallback to random letter for flying effect
	var fallback_chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
	return fallback_chars[randi() % fallback_chars.size()]

func _spawn_typing_effect(pos: Vector2, character: String) -> void:
	"""Create a typing effect at the specified position"""
	if not text_editor or character.is_empty():
		return
	
	# Clean up old effects if we have too many
	_cleanup_excess_effects()
	
	# Create typing effect using script
	var effect_script = preload("res://scripts/components/typing_effect.gd")
	var effect = Node2D.new()
	var typing_effect_offset: Vector2 = Vector2(10, 8)
	effect.set_script(effect_script)
	effect.character_typed = character
	effect.position = pos + typing_effect_offset
	effect.destroy_on_complete = true
	
	# Add to text editor as overlay
	text_editor.add_child(effect)
	active_effects.append(effect)
	
	# Emit signal for audio/other systems
	effect_spawned.emit(character, pos)
	
	print("Spawned typing effect for '", character, "' at ", pos)

func _spawn_deletion_effect(pos: Vector2, deleted_char: String = "") -> void:
	"""Create a deletion effect (explosion + flying letters) at the specified position"""
	if not text_editor:
		return
	
	_cleanup_excess_effects()
	
	# Restart the deletion reset timer (keep scaling active while deleting)
	if deletion_reset_timer:
		deletion_reset_timer.start()
	
	# Create enhanced explosion effect using new DeletionEffect component
	var deletion_script = preload("res://scripts/components/deletion_effect.gd")
	var explosion = Node2D.new()
	var typing_effect_offset: Vector2 = Vector2(0, -8)
	explosion.set_script(deletion_script)
	explosion.position = pos + typing_effect_offset
	explosion.destroy_on_complete = true
	
	text_editor.add_child(explosion)
	active_effects.append(explosion)
	
	# Create flying letter effect if enabled and we have a character
	if enable_flying_letters and not deleted_char.is_empty():
		var flying_letter_script = preload("res://scripts/components/flying_letter.gd")
		var flying_letter = Node2D.new()
		flying_letter.set_script(flying_letter_script)
		flying_letter.character_text = deleted_char
		flying_letter.position = pos
		
		text_editor.add_child(flying_letter)
		active_effects.append(flying_letter)
		
		print("Spawned flying letter '", deleted_char, "' at ", pos)
	
	print("Spawned enhanced deletion effect at ", pos)

func _spawn_newline_effect(pos: Vector2) -> void:
	"""Create a newline effect at the specified position"""
	if not text_editor:
		return
	
	_cleanup_excess_effects()
	
	# Create newline effect
	var effect_script = preload("res://scripts/components/typing_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	effect.character_typed = "⏎"  # Use return symbol for newlines
	effect.position = pos
	effect.destroy_on_complete = true
	effect.effect_duration = 1.0  # Shorter duration for newlines
	effect.particle_effects = false  # No particles for newlines
	
	text_editor.add_child(effect)
	active_effects.append(effect)
	
	print("Spawned newline effect at ", pos)

func _cleanup_excess_effects() -> void:
	"""Remove old effects if we have too many active"""
	# Remove null references
	active_effects = active_effects.filter(func(effect): return is_instance_valid(effect))
	
	# Remove oldest effects if we have too many
	while active_effects.size() >= max_active_effects:
		var oldest_effect = active_effects[0]
		if is_instance_valid(oldest_effect):
			oldest_effect.queue_free()
		active_effects.remove_at(0)

func clear_all_effects() -> void:
	"""Remove all active effects"""
	for effect in active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()

func set_effects_enabled(enabled: bool) -> void:
	"""Enable or disable all typing effects"""
	enable_typing_effects = enabled
	enable_deletion_effects = enabled
	enable_newline_effects = enabled
	enable_flying_letters = enabled  # Include flying letters
	
	if not enabled:
		clear_all_effects()

# Individual effect control methods for settings integration
func set_typing_effects_enabled(enabled: bool) -> void:
	"""Enable or disable typing sparkle effects"""
	enable_typing_effects = enabled

func set_flying_letters_enabled(enabled: bool) -> void:
	"""Enable or disable flying letter deletion effects"""
	enable_flying_letters = enabled

func set_deletion_explosions_enabled(enabled: bool) -> void:
	"""Enable or disable deletion explosion effects"""
	enable_deletion_effects = enabled

func set_sparkle_effects_enabled(enabled: bool) -> void:
	"""Enable or disable sparkle typing effects (alias for typing effects)"""
	enable_typing_effects = enabled

func set_effect_intensity(intensity: float) -> void:
	"""Set the intensity/scale of all effects"""
	# We'll store intensity and apply it to newly created effects
	# For now, just implement the method signature for settings integration
	print("Effect intensity set to: ", intensity)
	# TODO: Apply intensity to effect scaling in spawn methods

# Settings integration
func apply_settings(settings: Dictionary) -> void:
	"""Apply typing effects settings from game controller"""
	if settings.has("enable_typing_effects"):
		enable_typing_effects = settings.get("enable_typing_effects", true)
	if settings.has("enable_deletion_effects"):
		enable_deletion_effects = settings.get("enable_deletion_effects", true)
	if settings.has("enable_newline_effects"):
		enable_newline_effects = settings.get("enable_newline_effects", true)
	if settings.has("enable_flying_letters"):
		enable_flying_letters = settings.get("enable_flying_letters", true)
	
	print("TypingEffectsManager settings applied:", settings)