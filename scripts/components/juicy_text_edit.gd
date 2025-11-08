extends TextEdit
class_name JuicyTextEdit

# Juicy Editor - Enhanced Text Editor Component (Simplified)
# Focuses on node-based typing effects instead of complex RichTextLabel overlay

signal text_typed(character: String)
signal text_deleted(character: String)
signal line_changed(line_number: int)

@export var enable_typing_sounds: bool = true
@export var enable_typing_animations: bool = true
@export var enable_line_numbers: bool = true
@export var enable_deletion_explosions: bool = true

@onready var audio_manager: Node
@onready var animation_manager: Node

# New Juicy Typing Effects System (replaces complex RichTextLabel overlay)
var typing_effects_manager: Node

var last_text_length: int = 0
var last_caret_line: int = 0
var previous_text: String = ""  # Store previous text to detect deletions
var current_file_path: String = ""  # Store current file path for syntax highlighting refresh

func _ready() -> void:
	print("DEBUG: JuicyTextEdit _ready() starting")
	
	# Find managers in the scene tree
	audio_manager = get_node("/root/AudioManager") if has_node("/root/AudioManager") else null
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	
	print("DEBUG: Managers found - Audio:", audio_manager != null, " Animation:", animation_manager != null)
	
	# Set up initial configuration
	_configure_editor()
	
	# Setup new node-based typing effects system
	_setup_typing_effects()
	
	# Connect signals
	text_changed.connect(_on_text_changed_internal)
	caret_changed.connect(_on_caret_changed_internal)
	
	print("JuicyTextEdit initialized:")
	print("  Audio manager: ", audio_manager != null)
	print("  Animation manager: ", animation_manager != null)
	print("  Typing effects: ", typing_effects_manager != null)

func _setup_typing_effects() -> void:
	"""Create and setup the new node-based typing effects manager"""
	var typing_effects_script = preload("res://scripts/components/typing_effects_manager.gd")
	typing_effects_manager = Node.new()
	typing_effects_manager.set_script(typing_effects_script)
	typing_effects_manager.name = "TypingEffectsManager"
	add_child(typing_effects_manager)
	
	# Setup the text editor connection
	typing_effects_manager.setup_text_editor(self)
	
	# Connect to audio manager for coordinated sound effects
	if typing_effects_manager.has_signal("effect_spawned") and audio_manager:
		typing_effects_manager.effect_spawned.connect(_on_typing_effect_spawned)
	
	print("TypingEffectsManager setup complete")

func _on_typing_effect_spawned(character: String, _pos: Vector2) -> void:
	"""Handle typing effect spawning for coordinated audio feedback"""
	if audio_manager and enable_typing_sounds:
		# Let the audio manager handle typing sound with character info
		audio_manager.play_typing_sound()
	
	# Emit our own signal for other systems
	text_typed.emit(character)

func _configure_editor() -> void:
	# Basic editor setup
	placeholder_text = "Start typing to create your document..."
	wrap_mode = TextEdit.LINE_WRAPPING_NONE
	scroll_smooth = true
	scroll_v_scroll_speed = 50
	
	# Note: Line numbers are now handled by the LineNumbers component
	# No need to setup gutters here anymore
	
	# Set up syntax highlighting (basic)
	syntax_highlighter = CodeHighlighter.new()

func _on_text_changed_internal() -> void:
	# Simple text change handling without RichTextLabel complexity
	var current_length = text.length()
	
	# Determine if text was added or deleted
	if current_length > last_text_length:
		# Text was added - effects handled by TypingEffectsManager
		pass
	elif current_length < last_text_length:
		# Text was deleted - emit deletion signal
		text_deleted.emit("")
	
	last_text_length = current_length
	previous_text = text

func _on_caret_changed_internal() -> void:
	var current_line = get_caret_line()
	if current_line != last_caret_line:
		line_changed.emit(current_line)
		last_caret_line = current_line

# Settings management
func apply_settings(settings: Dictionary) -> void:
	"""Apply settings from the main controller"""
	if settings.has("enable_typing_sounds"):
		enable_typing_sounds = settings.get("enable_typing_sounds", true)
	if settings.has("enable_typing_animations"):
		enable_typing_animations = settings.get("enable_typing_animations", true)
	if settings.has("enable_line_numbers"):
		enable_line_numbers = settings.get("enable_line_numbers", true)
	
	# Apply to typing effects manager
	if typing_effects_manager:
		typing_effects_manager.apply_settings(settings)

func set_typing_effects_enabled(enabled: bool) -> void:
	"""Enable or disable typing effects"""
	if typing_effects_manager:
		typing_effects_manager.set_effects_enabled(enabled)

func clear_all_effects() -> void:
	"""Clear all active typing effects"""
	if typing_effects_manager:
		typing_effects_manager.clear_all_effects()

# Deprecated RichTextLabel methods (kept for compatibility)
func set_rich_effect_property(_property_name: String, _value) -> void:
	"""DEPRECATED: RichTextLabel overlay system disabled"""
	print("WARNING: set_rich_effect_property() is deprecated - RichTextLabel overlay disabled")

func sync_to_overlay() -> void:
	"""DEPRECATED: RichTextLabel overlay system disabled"""
	print("WARNING: sync_to_overlay() is deprecated - RichTextLabel overlay disabled")

# Syntax highlighting method (restored from original implementation)
func set_syntax_highlighting_for_file(file_path: String) -> void:
	"""Set syntax highlighting based on file extension using current theme"""
	current_file_path = file_path  # Store for theme refresh
	var extension = file_path.get_extension().to_lower()
	
	# Get theme-aware syntax highlighter from theme manager
	var theme_manager = get_theme_manager()
	if theme_manager and theme_manager.current_theme:
		syntax_highlighter = theme_manager.current_theme.get_syntax_highlighter_for_file(extension)
	else:
		# Fallback to basic highlighting if no theme manager
		if not syntax_highlighter:
			syntax_highlighter = CodeHighlighter.new()
		_setup_fallback_highlighting(extension)

func refresh_syntax_highlighting() -> void:
	"""Refresh syntax highlighting with current theme - called when theme changes"""
	if current_file_path != "":
		set_syntax_highlighting_for_file(current_file_path)

func get_theme_manager() -> ThemeManager:
	"""Get the theme manager from the scene tree"""
	# Look for theme manager in the scene tree
	var root = get_tree().current_scene
	if root:
		var theme_manager = root.find_child("ThemeManager", true, false)
		if theme_manager:
			return theme_manager
	
	# Fallback: look in common parent locations
	var current = get_parent()
	while current:
		var theme_manager = current.get_node_or_null("ThemeManager")
		if theme_manager:
			return theme_manager
		current = current.get_parent()
	
	return null

func _setup_fallback_highlighting(extension: String) -> void:
	"""Fallback highlighting when no theme manager is available"""
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
	highlighter.number_color = Color.LIGHT_GREEN

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
	
	highlighter.add_color_region("//", "", Color.GRAY, true)
	highlighter.add_color_region("/*", "*/", Color.GRAY)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)
	highlighter.number_color = Color.LIGHT_GREEN

func _setup_html_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("<", ">", Color.LIGHT_BLUE)
	highlighter.add_color_region("<!--", "-->", Color.GRAY)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)

func _setup_css_highlighting(highlighter: CodeHighlighter) -> void:
	var properties = ["color", "background", "margin", "padding", "border", "font"]
	for prop in properties:
		highlighter.add_keyword_color(prop, Color.CYAN)
	
	highlighter.add_color_region("/*", "*/", Color.GRAY)
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.add_color_region("'", "'", Color.YELLOW)

func _setup_markdown_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("#", "", Color.CYAN, true)
	highlighter.add_color_region("**", "**", Color.YELLOW)
	highlighter.add_color_region("*", "*", Color.LIGHT_BLUE)
	highlighter.add_color_region("`", "`", Color.LIGHT_GREEN)

func _setup_json_highlighting(highlighter: CodeHighlighter) -> void:
	highlighter.add_color_region("\"", "\"", Color.YELLOW)
	highlighter.number_color = Color.LIGHT_GREEN
