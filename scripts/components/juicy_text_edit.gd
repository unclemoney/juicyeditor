extends TextEdit
class_name JuicyTextEdit

# Juicy Editor - Enhanced Text Editor Component
# Extends TextEdit with juicy effects and enhanced functionality

signal text_typed(character: String)
signal text_deleted(character: String)
signal line_changed(line_number: int)

@export var enable_typing_sounds: bool = true
@export var enable_typing_animations: bool = true
@export var enable_line_numbers: bool = true
@export var enable_deletion_explosions: bool = true

@onready var audio_manager: Node
@onready var animation_manager: Node

var last_text_length: int = 0
var last_caret_line: int = 0
var previous_text: String = ""  # Store previous text to detect deletions

func _ready() -> void:
	# Find managers in the scene tree
	audio_manager = get_node("/root/AudioManager") if has_node("/root/AudioManager") else null
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	
	# Connect signals
	text_changed.connect(_on_text_changed_internal)
	caret_changed.connect(_on_caret_changed_internal)
	
	# Set up initial configuration
	_configure_editor()
	
	print("JuicyTextEdit initialized:")
	print("  Audio manager: ", audio_manager != null)
	print("  Animation manager: ", animation_manager != null)

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

func _on_text_changed_internal() -> void:
	var current_length = text.length()
	var current_text = text
	
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
	# Apply visual effects based on configuration
	if "typing_animations" in effects_config:
		enable_typing_animations = effects_config.typing_animations
	
	if "typing_sounds" in effects_config:
		enable_typing_sounds = effects_config.typing_sounds
	
	if "line_numbers" in effects_config:
		enable_line_numbers = effects_config.line_numbers
		if enable_line_numbers:
			add_gutter()
			set_gutter_type(0, TextEdit.GUTTER_TYPE_ICON)
			set_gutter_draw(0, true)
			set_gutter_width(0, 50)