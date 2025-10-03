extends TextEdit
class_name JuicyTextEdit

# Juicy Editor - Enhanced Text Editor Component
# Extends TextEdit with RichTextLabel overlay for juicy effects and enhanced functionality

signal text_typed(character: String)
signal text_deleted(character: String)
signal line_changed(line_number: int)

@export var enable_typing_sounds: bool = true
@export var enable_typing_animations: bool = true
@export var enable_line_numbers: bool = true
@export var enable_deletion_explosions: bool = true

# RichTextLabel Enhancement Properties (DEPRECATED - DISABLED)
@export var enable_rich_effects: bool = false
@export var enable_text_shadows: bool = false
@export var enable_text_outlines: bool = false
@export var enable_gradient_backgrounds: bool = false
@export var rich_effects_performance_mode: bool = true

# Temporary Effects System (DEPRECATED - DISABLED)
@export var effects_fade_duration: float = 2.0  # How long effects stay visible
@export var effects_fade_delay: float = 1.0     # Delay before fading starts
@export var show_effects_on_file_open: bool = false  # Only show effects when typing

@onready var audio_manager: Node
@onready var animation_manager: Node
@onready var typing_effects_manager: Node

# New Juicy Typing Effects System (replaces complex RichTextLabel overlay)
var typing_effects: Node

# Temporary effects state
var effects_timer: Timer
var is_typing_active: bool = false
var last_typing_time: float = 0.0
var last_effects_text_length: int = 0  # Track text length when effects were last shown

var last_text_length: int = 0
var last_caret_line: int = 0
var previous_text: String = ""  # Store previous text to detect deletions

func _ready() -> void:
	print("DEBUG: JuicyTextEdit _ready() starting")
	
	# Find managers in the scene tree
	audio_manager = get_node("/root/AudioManager") if has_node("/root/AudioManager") else null
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	
	print("DEBUG: Managers found - Audio:", audio_manager != null, " Animation:", animation_manager != null)
	
	# Set up temporary effects timer (DISABLED)
	# _setup_effects_timer()
	
	# Set up initial configuration
	_configure_editor()
	
	# Setup new node-based typing effects system
	_setup_typing_effects()
	
	# Connect signals
	text_changed.connect(_on_text_changed_internal)
	caret_changed.connect(_on_caret_changed_internal)
	_connect_resize_signal()
	
	print("JuicyTextEdit initialized:")
	print("  Audio manager: ", audio_manager != null)
	print("  Animation manager: ", animation_manager != null)
	print("  Typing effects: ", typing_effects != null)

func _setup_effects_timer() -> void:
	"""Set up timer for temporary effects fade-out"""
	effects_timer = Timer.new()
	add_child(effects_timer)
	effects_timer.wait_time = effects_fade_delay
	effects_timer.one_shot = true
	effects_timer.timeout.connect(_on_effects_fade_timeout)
	print("DEBUG: Effects timer created with delay=", effects_fade_delay)

func _on_effects_fade_timeout() -> void:
	"""Called when effects should start fading out"""
	is_typing_active = false
	_fade_out_effects()
	print("DEBUG: Effects fade timeout - starting fade out")

func _fade_out_effects() -> void:
	"""Fade out the rich text overlay to show original markup"""
	if not rich_text_overlay:
		return
	
	# Create a tween to fade out the overlay
	var tween = create_tween()
	tween.tween_property(rich_text_overlay, "modulate:a", 0.0, effects_fade_duration)
	tween.tween_callback(_on_effects_fade_complete)
	print("DEBUG: Starting effects fade out over ", effects_fade_duration, " seconds")

func _on_effects_fade_complete() -> void:
	"""Called when fade out animation completes"""
	if rich_text_overlay:
		rich_text_overlay.visible = false
	
	# Reset the effects text length so next typing session will show effects for all new text
	last_effects_text_length = 0
	is_typing_active = false
	
	print("DEBUG: Effects fade complete - overlay hidden, effects text length reset")

func _start_typing_effects() -> void:
	"""Start or refresh temporary effects when user is typing"""
	if not enable_rich_effects or not rich_text_overlay:
		return
	
	# Make overlay visible and fully opaque
	rich_text_overlay.visible = true
	rich_text_overlay.modulate.a = 1.0
	is_typing_active = true
	last_typing_time = Time.get_unix_time_from_system()
	
	# Reset the fade timer
	if effects_timer:
		effects_timer.stop()
		effects_timer.start()
	
	print("DEBUG: Typing effects started - overlay visible")

func _configure_editor() -> void:
	# Basic editor setup
	placeholder_text = "Start typing to create your document..."
	wrap_mode = TextEdit.LINE_WRAPPING_NONE
	scroll_smooth = true
	scroll_v_scroll_speed = 50
	
	# Enable basic features
	if enable_line_numbers:
		add_gutter()
		set_gutter_type(0, TextEdit.GUTTER_TYPE_ICON)
		set_gutter_draw(0, true)
		set_gutter_width(0, 50)
	
	# Set up syntax highlighting (basic)
	syntax_highlighter = CodeHighlighter.new()
	
	# Store initial state
	last_text_length = text.length()
	last_caret_line = get_caret_line()
	previous_text = text

func _setup_rich_text_overlay() -> void:
	"""Create and configure RichTextLabel overlay for visual effects"""
	print("DEBUG: _setup_rich_text_overlay called, enable_rich_effects=", enable_rich_effects)
	print("DEBUG: BEFORE overlay setup - position=", position, " size=", size)
	
	if not enable_rich_effects:
		print("DEBUG: Rich effects disabled, skipping overlay creation")
		return
	
	# Create RichTextLabel as overlay
	rich_text_overlay = RichTextLabel.new()
	add_child(rich_text_overlay)
	print("DEBUG: RichTextLabel overlay created and added as child")
	print("DEBUG: AFTER child added - position=", position, " size=", size)
	
	# Configure overlay properties
	rich_text_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	rich_text_overlay.clip_contents = true
	rich_text_overlay.fit_content = false
	rich_text_overlay.bbcode_enabled = true
	rich_text_overlay.selection_enabled = false
	rich_text_overlay.scroll_active = false
	
	# Additional BBCode properties to ensure proper parsing
	rich_text_overlay.threaded = false  # Disable threading for immediate rendering
	rich_text_overlay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Match TextEdit behavior
	
	# Force BBCode parsing by setting and clearing text
	rich_text_overlay.text = "[color=red]test[/color]"
	await get_tree().process_frame  # Wait one frame
	rich_text_overlay.text = ""
	
	print("DEBUG: BBCode enabled: ", rich_text_overlay.bbcode_enabled)
	print("DEBUG: Threaded: ", rich_text_overlay.threaded)
	print("DEBUG: Autowrap mode: ", rich_text_overlay.autowrap_mode)
	print("DEBUG: BBCode parsing test completed")
	
	# Position overlay above the TextEdit  
	rich_text_overlay.z_index = 1
	print("DEBUG: Overlay z_index set to: ", rich_text_overlay.z_index)
	print("DEBUG: AFTER z_index set - position=", position, " size=", size)
	
	# NEW APPROACH: Temporary effects system
	# Start with overlay hidden - only show during typing
	rich_text_overlay.visible = false
	rich_text_overlay.modulate.a = 0.0
	print("DEBUG: Overlay initialized as hidden for temporary effects system")
	
	# Keep TextEdit text visible for original markup
	print("DEBUG: TextEdit font kept visible for original markup")
	
	# Keep selection and caret visible
	add_theme_color_override("selection_color", Color(0.3, 0.6, 1.0, 0.3))
	add_theme_color_override("caret_color", Color.WHITE)
	# Keep background transparent so we can see the overlay effects
	add_theme_color_override("background_color", Color.TRANSPARENT)
	
	print("DEBUG: TextEdit theme overrides applied - text remains visible")
	print("DEBUG: AFTER theme overrides - position=", position, " size=", size)
	
	# Match size and position exactly
	_update_overlay_transform()
	print("DEBUG: AFTER overlay transform - position=", position, " size=", size)
	
	# Sync initial content
	_sync_text_to_overlay()
	print("DEBUG: AFTER sync - position=", position, " size=", size)
	
	print("DEBUG: RichTextLabel overlay created and configured")
	print("DEBUG: Overlay visible=", rich_text_overlay.visible)
	print("DEBUG: Overlay size=", rich_text_overlay.size)
	print("DEBUG: Overlay position=", rich_text_overlay.position)
	print("DEBUG: FINAL TextEdit position=", position, " size=", size)

func _update_overlay_transform() -> void:
	"""Update overlay size and position to match TextEdit"""
	if not rich_text_overlay:
		return
	
	print("DEBUG: _update_overlay_transform called")
	print("DEBUG: TextEdit size=", size, " position=", position)
	
	# Account for gutter width when positioning overlay
	var gutter_width = 0
	if enable_line_numbers and get_gutter_count() > 0:
		gutter_width = get_gutter_width(0)
	
	# Position overlay to account for gutter and match text content area exactly
	var content_margin_left = get_theme_constant("content_margin_left", "TextEdit") if has_theme_constant("content_margin_left", "TextEdit") else 0
	var content_margin_top = get_theme_constant("content_margin_top", "TextEdit") if has_theme_constant("content_margin_top", "TextEdit") else 0
	
	# Add additional internal padding adjustments based on your manual calibration
	# TextEdit has internal spacing that's not exposed through theme constants
	var internal_padding_x = 31  # Your manually found horizontal offset
	var internal_padding_y = 6   # Your manually found vertical offset
	
	# Position overlay to match TextEdit's internal text positioning
	rich_text_overlay.position = Vector2(gutter_width + content_margin_left + internal_padding_x, content_margin_top + internal_padding_y)
	rich_text_overlay.size = Vector2(size.x - gutter_width - content_margin_left - internal_padding_x, size.y - content_margin_top - internal_padding_y)
	
	# Match font properties exactly
	var font = get_theme_font("font", "TextEdit")
	var font_size = get_theme_font_size("font_size", "TextEdit")
	
	print("DEBUG: Font=", font, " Font size=", font_size)
	
	if font:
		# Get the exact line height from TextEdit's font
		var text_edit_line_height = font.get_height(font_size)
		
		# Force RichTextLabel to use exact same font properties and remove extra spacing
		rich_text_overlay.add_theme_constant_override("line_separation", 0)  # Remove any extra spacing
		rich_text_overlay.add_theme_font_override("normal_font", font)
		rich_text_overlay.add_theme_font_size_override("normal_font_size", font_size)
		
		# CRITICAL: Force exact line height matching by overriding the line spacing
		# Calculate the difference and compensate with negative line separation
		var rich_text_line_height = font.get_height(font_size)
		var line_height_diff = text_edit_line_height - rich_text_line_height
		
		# Apply line height compensation - force RichTextLabel to match TextEdit exactly
		rich_text_overlay.add_theme_constant_override("line_separation", line_height_diff)
		
		print("DEBUG: TextEdit line height=", text_edit_line_height)
		print("DEBUG: RichTextLabel line height=", rich_text_line_height)
		print("DEBUG: Line height compensation=", line_height_diff)
		print("DEBUG: Font applied to overlay with exact line height matching")
	
	# Don't mess with margins - they cause positioning issues
	# var content_margin_left = get_theme_constant("content_margin_left", "TextEdit")
	# var content_margin_top = get_theme_constant("content_margin_top", "TextEdit")

func _sync_text_to_overlay() -> void:
	"""Synchronize TextEdit content to RichTextLabel with effects"""
	if not rich_text_overlay or is_synchronizing:
		print("DEBUG: Sync skipped - overlay=", rich_text_overlay != null, " is_synchronizing=", is_synchronizing)
		return
	
	# Only sync if effects are currently active (visible) or if we're showing effects on file open
	if not rich_text_overlay.visible and not show_effects_on_file_open:
		print("DEBUG: Sync skipped - overlay not visible and not showing on file open")
		return
	
	print("DEBUG: _sync_text_to_overlay starting")
	is_synchronizing = true
	
	var text_content = text
	print("DEBUG: Text content length=", text_content.length())
	
	# Performance optimization: limit processing for large files
	if rich_effects_performance_mode and text_content.length() > 10000:
		print("DEBUG: Using optimized sync for large file")
		_sync_text_to_overlay_optimized(text_content)
	else:
		print("DEBUG: Using incremental sync")
		var current_length = text_content.length()
		var formatted_text: String
		
		# Only show effects for newly typed text
		if current_length > last_effects_text_length:
			print("DEBUG: New text detected - showing effects for newly typed content")
			# Get only the newly typed portion
			var new_text_start = last_effects_text_length
			var new_text = text_content.substr(new_text_start)
			
			# Apply effects only to the new text - simple character formatting
			var formatted_new_text = _apply_simple_character_effects(new_text)
			
			print("DEBUG: Raw new text: '", new_text, "'")
			print("DEBUG: Formatted new text: '", formatted_new_text, "'")
			
			# Create padding to position the new text correctly in the overlay
			var lines_before = text_content.substr(0, new_text_start).count("\n")
			var padding = ""
			for i in range(lines_before):
				padding += "\n"
			
			# Get the column position of where new text starts on the current line
			var last_newline_pos = text_content.substr(0, new_text_start).rfind("\n")
			var column_start = new_text_start - last_newline_pos - 1 if last_newline_pos != -1 else new_text_start
			var column_padding = ""
			for i in range(column_start):
				column_padding += " "
			
			# Only show the formatted new text at the correct position
			formatted_text = padding + column_padding + formatted_new_text
			
			print("DEBUG: New text portion: '", new_text.substr(0, 50), "'")
			print("DEBUG: Lines before: ", lines_before, " Column start: ", column_start)
			print("DEBUG: Formatted overlay text preview: '", formatted_text.substr(0, 100).replace("\n", "\\n"), "'")
			
			# Update the text length we've shown effects for
			last_effects_text_length = current_length
		else:
			print("DEBUG: No new text - using plain text")
			# Show plain text when no new content
			formatted_text = text_content
		
		# Set BBCode text using text property for proper parsing
		rich_text_overlay.text = formatted_text
		print("DEBUG: BBCode text applied to overlay using text property")
		print("DEBUG: Overlay bbcode_enabled: ", rich_text_overlay.bbcode_enabled)
		print("DEBUG: Overlay scroll_active: ", rich_text_overlay.scroll_active)
		print("DEBUG: Overlay get_parsed_text() preview: ", rich_text_overlay.get_parsed_text().substr(0, 50))
		print("DEBUG: INCREMENTAL - Only showing newly typed text, length=", formatted_text.length())
	
	is_synchronizing = false
	print("DEBUG: _sync_text_to_overlay completed")

func _sync_text_to_overlay_optimized(text_content: String) -> void:
	"""Optimized sync for large files - only process visible lines"""
	if not rich_text_overlay:
		return
	
	# Get visible line range
	var first_visible_line = get_first_visible_line()
	var visible_line_count = get_visible_line_count()
	var end_visible_line = min(first_visible_line + visible_line_count + 5, get_line_count() - 1)  # +5 buffer
	
	var lines = text_content.split("\n")
	var formatted_lines: Array[String] = []
	var current_line_num = get_caret_line()
	
	# Process all lines but only format visible ones with full effects
	for i in range(lines.size()):
		if i < lines.size():
			var line = lines[i]
			# Apply full effects to visible lines, minimal formatting to others
			if i >= first_visible_line - 5 and i <= end_visible_line + 5:
				var formatted_line = _apply_line_effects(line, i, current_line_num)
				formatted_lines.append(formatted_line)
			else:
				# Just add the line without heavy processing for performance
				formatted_lines.append(line)
		else:
			formatted_lines.append("")
	
	# Create the text with all lines (maintains scroll position)
	var full_text = "\n".join(formatted_lines)
	rich_text_overlay.text = full_text
	
	# Sync scroll position between TextEdit and RichTextLabel
	if rich_text_overlay.get_v_scroll_bar():
		rich_text_overlay.get_v_scroll_bar().value = scroll_vertical

func _apply_rich_effects_to_text(input_text: String) -> String:
	"""Apply BBCode formatting and effects to text"""
	if not enable_rich_effects or input_text.is_empty():
		return input_text
	
	var lines = input_text.split("\n")
	var formatted_lines: Array[String] = []
	var current_line_num = get_caret_line()
	
	for i in range(lines.size()):
		var line = lines[i]
		var formatted_line = _apply_line_effects(line, i, current_line_num)
		formatted_lines.append(formatted_line)
	
	return "\n".join(formatted_lines)

func _apply_simple_character_effects(input_text: String) -> String:
	"""Apply simple effects to newly typed characters only"""
	if not enable_rich_effects or input_text.is_empty():
		return input_text
	
	# Apply a simple highlight effect to the new text
	# Choose one primary effect to avoid complexity
	if enable_gradient_backgrounds:
		return "[bgcolor=#FFAA00]%s[/bgcolor]" % input_text  # Bright orange highlight for new text
	elif enable_text_outlines:
		return "[outline size=2 color=#00AAFF]%s[/outline]" % input_text
	elif enable_text_shadows:
		return "[color=#FFFF77]%s[/color]" % input_text  # Bright yellow
	else:
		return "[color=#00FF00]%s[/color]" % input_text  # Bright green fallback

func _apply_line_effects(line: String, line_number: int, current_line: int) -> String:
	"""Apply effects to a single line of text"""
	if line.is_empty():
		return ""
	
	var formatted_line = line
	var is_current_line = (line_number == current_line)
	
	# Only debug first few lines to avoid spam
	if line_number < 3:
		print("DEBUG: Applying effects to line ", line_number, " (current=", is_current_line, "): '", line.substr(0, 20), "...'")
	
	# Apply one primary effect based on priority and current line status
	if is_current_line:
		# Current line gets special highlighting - choose the best available effect
		if enable_gradient_backgrounds:
			# Background gradient - highest priority for current line
			formatted_line = "[bgcolor=#1A1A3A]%s[/bgcolor]" % formatted_line
			if line_number < 3:
				print("DEBUG: Current line background gradient applied")
		elif enable_text_outlines:
			# Outline effect - good fallback
			formatted_line = "[outline size=2 color=#00AAFF]%s[/outline]" % formatted_line
			if line_number < 3:
				print("DEBUG: Current line outline applied")
		elif enable_text_shadows:
			# Shadow effect - alternative
			formatted_line = "[color=#FFFF77]%s[/color]" % formatted_line  # Bright yellow for visibility
			if line_number < 3:
				print("DEBUG: Current line bright color applied (shadow alternative)")
		else:
			# Basic highlight
			formatted_line = "[color=#FFFFFF]%s[/color]" % formatted_line
			if line_number < 3:
				print("DEBUG: Current line basic highlight applied")
	else:
		# Non-current lines get subtle styling
		if enable_gradient_backgrounds:
			# Subtle background for non-current lines
			formatted_line = "[bgcolor=#0F0F1F]%s[/bgcolor]" % formatted_line
		else:
			# Dimmed text for non-current lines
			formatted_line = "[color=#888888]%s[/color]" % formatted_line
	
	if line_number < 3:
		print("DEBUG: Final formatted line: ", formatted_line)
	return formatted_line

func _apply_syntax_highlighting_effects(line: String) -> String:
	"""Apply basic syntax highlighting using BBCode"""
	var highlighted_line = line
	
	# Simple keyword highlighting (can be expanded)
	var keywords = ["func", "var", "if", "else", "for", "while", "class", "extends", "signal"]
	for keyword in keywords:
		# Note: Godot's String.replace doesn't support regex, so this is a simplified approach
		if keyword in highlighted_line:
			highlighted_line = highlighted_line.replace(keyword, "[color=#00AAFF]%s[/color]" % keyword)
	
	# Highlight strings (basic approach)
	if "\"" in highlighted_line:
		# This is a very basic string highlighting - could be improved with proper parsing
		var parts = highlighted_line.split("\"")
		var result = ""
		for i in range(parts.size()):
			if i % 2 == 0:
				result += parts[i]  # Outside quotes
			else:
				result += "[color=#FFAA00]\"%s\"[/color]" % parts[i]  # Inside quotes
		highlighted_line = result
	
	# Highlight comments
	if "#" in highlighted_line:
		var comment_pos = highlighted_line.find("#")
		if comment_pos != -1:
			var before_comment = highlighted_line.substr(0, comment_pos)
			var comment_part = highlighted_line.substr(comment_pos)
			highlighted_line = before_comment + "[color=#888888]%s[/color]" % comment_part
	
	return highlighted_line

func _on_text_changed_internal() -> void:
	var current_length = text.length()
	var current_text = text
	
	# Trigger temporary effects when text changes (user is typing)
	_start_typing_effects()
	
	# Sync with RichTextLabel overlay
	if enable_rich_effects and not is_synchronizing:
		_sync_text_to_overlay()
	
	# Detect if text was added or removed
	if current_length > last_text_length:
		# Text was added
		var diff = current_length - last_text_length
		if diff == 1:
			# Single character typed
			var caret_pos = get_caret_column()
			if caret_pos > 0 and caret_pos <= text.length():
				var line_text = get_line(get_caret_line())
				if caret_pos <= line_text.length():
					var typed_char = line_text[caret_pos - 1]
					_handle_character_typed(typed_char)
	elif current_length < last_text_length:
		# Text was deleted
		var diff = last_text_length - current_length
		if diff == 1:
			# Find the deleted character by comparing previous_text and current_text
			var deleted_char = _find_deleted_character(previous_text, current_text)
			_handle_character_deleted(deleted_char)
	
	# Update tracking variables
	last_text_length = current_length
	previous_text = current_text

func _find_deleted_character(old_text: String, new_text: String) -> String:
	"""Find which character was deleted by comparing old and new text"""
	# Simple approach: find the first difference
	var min_length = min(old_text.length(), new_text.length())
	
	for i in range(min_length):
		if old_text[i] != new_text[i]:
			return old_text[i]
	
	# If the difference is at the end, return the last character of old_text
	if old_text.length() > new_text.length():
		return old_text[old_text.length() - 1]
	
	return " "  # Fallback character

func _on_caret_changed_internal() -> void:
	var current_line = get_caret_line()
	if current_line != last_caret_line:
		line_changed.emit(current_line)
		last_caret_line = current_line
	
	# DISABLED: Don't update overlay on caret change - only update during typing
	# This was causing all text to show instead of just newly typed characters
	# if enable_rich_effects and rich_text_overlay:
	#	_highlight_current_line_in_overlay()

func _highlight_current_line_in_overlay() -> void:
	"""Highlight the current line in the RichTextLabel overlay"""
	if not rich_text_overlay or is_synchronizing:
		return
	
	# Performance optimization: only update if rich effects are enabled
	if not enable_rich_effects:
		return
	
	is_synchronizing = true
	
	var lines = text.split("\n")
	var current_line_num = get_caret_line()
	var formatted_lines: Array[String] = []
	
	for i in range(lines.size()):
		var line = lines[i]
		var formatted_line = _apply_line_effects(line, i, current_line_num)
		formatted_lines.append(formatted_line)
	
	rich_text_overlay.text = "\n".join(formatted_lines)
	
	is_synchronizing = false

func _handle_character_typed(character: String) -> void:
	text_typed.emit(character)
	
	if enable_typing_sounds and audio_manager and audio_manager.has_method("play_typing_sound"):
		audio_manager.play_typing_sound()
	
	if enable_typing_animations:
		_play_typing_animation(character)

func _handle_character_deleted(deleted_char: String = "") -> void:
	text_deleted.emit(deleted_char)
	
	if enable_typing_sounds and audio_manager and audio_manager.has_method("play_typing_sound"):
		# Could play a different sound for deletion
		audio_manager.play_typing_sound()
	
	# Create explosion effect for deleted character
	if deleted_char != "" and enable_deletion_explosions and animation_manager and animation_manager.has_method("create_text_explosion"):
		var caret_pos = get_caret_column()
		var line_num = get_caret_line()
		
		# Calculate approximate position of deleted character
		var char_position = _calculate_character_position(line_num, caret_pos)
		
		# Create the explosion effect
		animation_manager.create_text_explosion(deleted_char, char_position, self)

func _calculate_character_position(line: int, column: int) -> Vector2:
	"""Calculate approximate screen position for a character in the text editor"""
	# Get font metrics
	var font = get_theme_font("font", "TextEdit")
	var font_size = get_theme_font_size("font_size", "TextEdit")
	
	if not font:
		# Use default values if font not available
		return Vector2(column * 8, line * 16) + global_position
	
	# Calculate position based on font metrics
	var line_height = font.get_height(font_size)
	var char_width = font.get_string_size("W", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x  # Use 'W' as average width
	
	var local_pos = Vector2(column * char_width, line * line_height)
	return local_pos + global_position

func _play_typing_animation(_character: String) -> void:
	# Trigger typing animation
	if animation_manager and animation_manager.has_method("animate_character_typed"):
		animation_manager.animate_character_typed(self, Vector2.ZERO)
	
	# Don't animate the entire text field for cursor - just trigger a visual cursor effect
	# if animation_manager and animation_manager.has_method("animate_cursor_pulse"):
	#	animation_manager.animate_cursor_pulse(self)
	# Instead, we could add a cursor blink effect or other visual feedback here

func set_syntax_highlighting_for_file(file_path: String) -> void:
	var extension = file_path.get_extension().to_lower()
	
	if not syntax_highlighter:
		syntax_highlighter = CodeHighlighter.new()
	
	var highlighter = syntax_highlighter as CodeHighlighter
	if not highlighter:
		return
	
	# Clear existing highlighting
	highlighter.clear_color_regions()
	highlighter.clear_member_keyword_colors()
	highlighter.clear_keyword_colors()
	
	match extension:
		"gd":
			_setup_gdscript_highlighting(highlighter)
		"py":
			_setup_python_highlighting(highlighter)
		"js":
			_setup_javascript_highlighting(highlighter)
		"html", "htm":
			_setup_html_highlighting(highlighter)
		"css":
			_setup_css_highlighting(highlighter)
		"md":
			_setup_markdown_highlighting(highlighter)
		"json":
			_setup_json_highlighting(highlighter)
		_:
			# Default/plain text
			pass

func _setup_gdscript_highlighting(highlighter: CodeHighlighter) -> void:
	# GDScript keywords
	var keywords = [
		"and", "as", "assert", "await", "break", "breakpoint", "class", "class_name",
		"const", "continue", "elif", "else", "enum", "extends", "for", "func",
		"if", "in", "is", "match", "not", "or", "pass", "return", "signal",
		"static", "super", "var", "void", "while", "yield"
	]
	
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color.CYAN)
	
	# Built-in types
	var types = ["bool", "int", "float", "String", "Vector2", "Vector3", "Color", "Node", "PackedStringArray"]
	for type in types:
		highlighter.add_keyword_color(type, Color.LIGHT_BLUE)
	
	# Comments
	highlighter.add_color_region("#", "", Color.GRAY, true)
	
	# Strings
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)
	highlighter.add_color_region("\"\"\"", "\"\"\"", Color.YELLOW)
	
	# Numbers
	highlighter.number_color = Color.LIGHT_GREEN

func _setup_python_highlighting(highlighter: CodeHighlighter) -> void:
	var keywords = [
		"and", "as", "assert", "break", "class", "continue", "def", "del",
		"elif", "else", "except", "exec", "finally", "for", "from", "global",
		"if", "import", "in", "is", "lambda", "not", "or", "pass", "print",
		"raise", "return", "try", "while", "with", "yield"
	]
	
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color.CYAN)
	
	highlighter.add_color_region("#", "", Color.GRAY, true)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)

func _setup_javascript_highlighting(highlighter: CodeHighlighter) -> void:
	var keywords = [
		"break", "case", "catch", "class", "const", "continue", "debugger",
		"default", "delete", "do", "else", "export", "extends", "finally",
		"for", "function", "if", "import", "in", "instanceof", "let", "new",
		"return", "super", "switch", "this", "throw", "try", "typeof", "var",
		"void", "while", "with", "yield"
	]
	
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color.CYAN)
	
	# Built-in objects
	var builtins = ["console", "window", "document", "Array", "Object", "String", "Number", "Boolean"]
	for builtin in builtins:
		highlighter.add_keyword_color(builtin, Color.LIGHT_BLUE)
	
	highlighter.add_color_region("//", "", Color.GRAY, true)
	highlighter.add_color_region("/*", "*/", Color.GRAY)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)
	highlighter.add_color_region("`", "`", Color.ORANGE)  # Template literals
	highlighter.number_color = Color.LIGHT_GREEN

func _setup_html_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("<", ">", Color.CYAN)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)
	highlighter.add_color_region("<!--", "-->", Color.GRAY)

func _setup_css_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("{", "}", Color.CYAN)
	highlighter.add_color_region("/*", "*/", Color.GRAY)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)

func _setup_markdown_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("#", "", Color.CYAN, true)
	highlighter.add_color_region("**", "**", Color.YELLOW)
	highlighter.add_color_region("*", "*", Color.GREEN)
	highlighter.add_color_region("`", "`", Color.ORANGE)

func _setup_json_highlighting(highlighter: CodeHighlighter) -> void:
	# JSON keywords
	var keywords = ["true", "false", "null"]
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color.CYAN)
	
	# Strings (keys and values)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	
	# Numbers
	highlighter.number_color = Color.LIGHT_GREEN

func apply_juicy_effects(effects_config: Dictionary) -> void:
	print("DEBUG: apply_juicy_effects called with config: ", effects_config)
	print("DEBUG: BEFORE apply_juicy_effects - position=", position, " size=", size)
	
	# Apply visual effects based on configuration
	if "typing_animations" in effects_config:
		enable_typing_animations = effects_config.typing_animations
		print("DEBUG: Set typing_animations=", enable_typing_animations)
	
	if "typing_sounds" in effects_config:
		enable_typing_sounds = effects_config.typing_sounds
		print("DEBUG: Set typing_sounds=", enable_typing_sounds)
	
	if "line_numbers" in effects_config:
		enable_line_numbers = effects_config.line_numbers
		print("DEBUG: Set line_numbers=", enable_line_numbers)
		if enable_line_numbers:
			add_gutter()
			set_gutter_type(0, TextEdit.GUTTER_TYPE_ICON)
			set_gutter_draw(0, true)
			set_gutter_width(0, 50)
			print("DEBUG: AFTER adding gutter - position=", position, " size=", size)
	
	# Apply rich effects configuration
	if "rich_effects" in effects_config:
		var new_rich_effects = effects_config.rich_effects
		print("DEBUG: Rich effects in config=", new_rich_effects, " current=", enable_rich_effects)
		
		if new_rich_effects != enable_rich_effects:
			enable_rich_effects = new_rich_effects
			if enable_rich_effects and not rich_text_overlay:
				print("DEBUG: Creating rich text overlay via apply_juicy_effects")
				_setup_rich_text_overlay()
			elif not enable_rich_effects and rich_text_overlay:
				print("DEBUG: Disabling rich effects via apply_juicy_effects")
				_disable_rich_effects()
	
	if "text_shadows" in effects_config:
		enable_text_shadows = effects_config.text_shadows
		print("DEBUG: Set text_shadows=", enable_text_shadows)
		if rich_text_overlay:
			_sync_text_to_overlay()
	
	if "text_outlines" in effects_config:
		enable_text_outlines = effects_config.text_outlines
		print("DEBUG: Set text_outlines=", enable_text_outlines)
		if rich_text_overlay:
			_sync_text_to_overlay()
	
	if "gradient_backgrounds" in effects_config:
		enable_gradient_backgrounds = effects_config.gradient_backgrounds
		print("DEBUG: Set gradient_backgrounds=", enable_gradient_backgrounds)
		if rich_text_overlay:
			_sync_text_to_overlay()
	
	print("DEBUG: AFTER apply_juicy_effects - position=", position, " size=", size)
	
	# Check position after all operations complete
	call_deferred("_check_final_position")

func _disable_rich_effects() -> void:
	"""Disable and clean up rich text overlay"""
	print("DEBUG: _disable_rich_effects called")
	print("DEBUG: BEFORE disable - position=", position, " size=", size)
	
	if rich_text_overlay:
		print("DEBUG: Removing rich text overlay")
		rich_text_overlay.queue_free()
		rich_text_overlay = null
		print("DEBUG: AFTER overlay removal - position=", position, " size=", size)
	
	# Restore normal TextEdit appearance without affecting position
	print("DEBUG: Removing theme overrides")
	remove_theme_color_override("font_color")
	print("DEBUG: AFTER removing font_color - position=", position, " size=", size)
	remove_theme_color_override("selection_color")
	print("DEBUG: AFTER removing selection_color - position=", position, " size=", size)
	remove_theme_color_override("caret_color")
	print("DEBUG: AFTER removing caret_color - position=", position, " size=", size)
	remove_theme_color_override("background_color")
	print("DEBUG: AFTER removing background_color - position=", position, " size=", size)
	
	# Don't modify margins or positioning properties that could shift the editor
	# remove_theme_constant_override("margin_left")
	# remove_theme_constant_override("margin_top")
	
	enable_rich_effects = false
	print("DEBUG: Rich effects disabled")
	print("DEBUG: FINAL disable - position=", position, " size=", size)

func _on_resized() -> void:
	"""Handle resize events to keep overlay in sync"""
	if rich_text_overlay:
		_update_overlay_transform()

func toggle_rich_effects(enabled: bool) -> void:
	"""Public method to toggle rich effects on/off"""
	print("DEBUG: toggle_rich_effects called with enabled=", enabled)
	print("DEBUG: Current enable_rich_effects=", enable_rich_effects)
	print("DEBUG: Before - position=", position, " size=", size)
	
	if enabled and not enable_rich_effects:
		enable_rich_effects = true
		_setup_rich_text_overlay()
		print("DEBUG: Rich effects enabled and overlay created")
	elif not enabled and enable_rich_effects:
		_disable_rich_effects()
		print("DEBUG: Rich effects disabled and overlay removed")
	
	print("DEBUG: After - position=", position, " size=", size)

func set_rich_effect_property(property_name: String, value: bool) -> void:
	"""Set individual rich effect properties"""
	match property_name:
		"shadows":
			enable_text_shadows = value
		"outlines":
			enable_text_outlines = value
		"gradients":
			enable_gradient_backgrounds = value
		_:
			print("Unknown rich effect property: ", property_name)
			return
	
	# Update overlay if it exists
	if rich_text_overlay:
		_sync_text_to_overlay()

# Connect resize signal in _ready()
func _connect_resize_signal() -> void:
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)

func _check_final_position() -> void:
	"""Check position after all deferred operations complete"""
	print("DEBUG: _check_final_position - position=", position, " size=", size)
	print("DEBUG: Rich effects enabled=", enable_rich_effects)
	print("DEBUG: Rich text overlay exists=", rich_text_overlay != null)
	if rich_text_overlay:
		print("DEBUG: Overlay position=", rich_text_overlay.position, " size=", rich_text_overlay.size)
