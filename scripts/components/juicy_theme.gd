extends Resource
class_name JuicyTheme

# Juicy Editor - Theme Resource
# Defines colors, fonts, and visual styling

@export var theme_name: String = "Default"
@export var description: String = "Default Juicy Editor theme"

# Color scheme
@export_group("Colors")
@export var background_color: Color
@export var text_color: Color
@export var selection_color: Color
@export var current_line_color: Color
@export var line_number_color: Color
@export var caret_color: Color

# UI Colors
@export_group("UI Colors")
@export var button_color: Color
@export var button_hover_color: Color
@export var button_pressed_color: Color
@export var menu_background_color: Color
@export var status_bar_color: Color

# Syntax highlighting colors
@export_group("Syntax Colors")
@export var keyword_color: Color
@export var string_color: Color
@export var comment_color: Color
@export var number_color: Color
@export var function_color: Color
@export var variable_color: Color
@export var symbol_color: Color  # For punctuation and operators

# File type specific syntax colors
@export_group("GDScript Colors")
@export var gdscript_func_color: Color
@export var gdscript_class_color: Color
@export var gdscript_signal_color: Color
@export var gdscript_builtin_color: Color

@export_group("Python Colors")
@export var python_def_color: Color
@export var python_class_color: Color
@export var python_import_color: Color
@export var python_decorator_color: Color

@export_group("Markdown Colors")
@export var markdown_header_color: Color
@export var markdown_bold_color: Color
@export var markdown_italic_color: Color
@export var markdown_code_color: Color
@export var markdown_link_color: Color
@export var markdown_checkbox_unchecked_color: Color
@export var markdown_checkbox_checked_color: Color

@export_group("JSON Colors")
@export var json_key_color: Color
@export var json_value_color: Color
@export var json_bracket_color: Color

# Typography
@export_group("Typography")
@export var editor_font: FontFile
@export var ui_font: FontFile
@export var editor_font_size: int
@export var ui_font_size: int
@export var line_height_multiplier: float
@export var font_bold_enabled: bool
@export var font_italic_enabled: bool

# Effects
@export_group("Effects")
@export var enable_text_shadows: bool
@export var text_shadow_color: Color
@export var text_shadow_offset: Vector2
@export var enable_gradient_backgrounds: bool
@export var gradient_start_color: Color
@export var gradient_end_color: Color
@export var enable_outline_effects: bool
@export var outline_color: Color
@export var outline_width: float
@export var enable_pulse_effects: bool
@export var enable_glow_effects: bool
@export var enable_rainbow_effects: bool
@export var enable_bounce_effects: bool
@export var button_animation_speed: float
@export var button_scale_effect: float

# Called after resource loading to ensure values are properly initialized
func _validate_theme_data():
	print("Theme validation for: ", theme_name)
	print("  - editor_font before validation: ", editor_font)
	print("  - ui_font before validation: ", ui_font)
	
	# Validate editor_font - copy from ui_font if null
	if not editor_font and ui_font:
		print("editor_font is null, copying from ui_font")
		editor_font = ui_font
	
	# Validate ui_font - use fallback if needed  
	if not ui_font:
		print("ui_font is null, attempting to load National2Condensed-Medium")
		ui_font = load("res://fonts/National2Condensed-Medium.otf")
	
	# Ensure font sizes are reasonable
	if editor_font_size <= 0:
		editor_font_size = 14
	if ui_font_size <= 0:
		ui_font_size = 12
	
	print("  - editor_font after validation: ", editor_font)
	print("  - ui_font after validation: ", ui_font)

func apply_to_text_edit(text_edit: TextEdit) -> void:
	if not text_edit:
		return
	
	print("Applying theme '", theme_name, "' to TextEdit")
	
	# Apply theme colors
	text_edit.add_theme_color_override("background_color", background_color)
	text_edit.add_theme_color_override("font_color", text_color)
	text_edit.add_theme_color_override("font_selected_color", text_color)
	text_edit.add_theme_color_override("selection_color", selection_color)
	text_edit.add_theme_color_override("current_line_color", current_line_color)
	text_edit.add_theme_color_override("caret_color", caret_color)
	
	# Apply fonts
	if editor_font:
		text_edit.add_theme_font_override("font", editor_font)
	text_edit.add_theme_font_size_override("font_size", editor_font_size)
	
	# Update syntax highlighting if this is a JuicyTextEdit with a file loaded
	if text_edit.has_method("refresh_syntax_highlighting"):
		text_edit.refresh_syntax_highlighting()
	
	print("Applied theme colors: bg=", background_color, " text=", text_color)

func apply_to_button(button: Button) -> void:
	if not button:
		return
	
	print("Applying theme '", theme_name, "' to Button: ", button.name)
	
	# SAFETY: Clear any existing material that might interfere with text rendering
	if button.material:
		print("WARNING: Button ", button.name, " had existing material: ", button.material, " - clearing it")
		button.material = null
	
	# Calculate appropriate text color based on button background
	var font_color = _get_appropriate_button_font_color()
	
	# Create a complete theme for the button instead of using overrides
	var button_theme = Theme.new()
	
	# Create StyleBoxFlat for button backgrounds
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = button_color
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	button_theme.set_stylebox("normal", "Button", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = button_hover_color
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	button_theme.set_stylebox("hover", "Button", style_hover)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = button_pressed_color
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	button_theme.set_stylebox("pressed", "Button", style_pressed)
	
	# Set font colors in the theme
	button_theme.set_color("font_color", "Button", font_color)
	button_theme.set_color("font_hover_color", "Button", font_color.lightened(0.2))
	button_theme.set_color("font_pressed_color", "Button", font_color.darkened(0.2))
	
	# Set fonts in the theme
	if ui_font:
		button_theme.set_font("font", "Button", ui_font)
	button_theme.set_font_size("font_size", "Button", ui_font_size)
	
	# Apply the complete theme to the button
	button.theme = button_theme
	
	print("Applied button theme: bg=", button_color, " font_color=", font_color)

# Helper function to determine appropriate font color based on background brightness
func _get_appropriate_font_color() -> Color:
	# Calculate background brightness (luminance)
	var luminance = 0.299 * background_color.r + 0.587 * background_color.g + 0.114 * background_color.b
	
	# If background is light (luminance > 0.5), use dark text
	if luminance > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

func _get_appropriate_menu_font_color() -> Color:
	# Calculate menu background brightness
	var luminance = 0.299 * menu_background_color.r + 0.587 * menu_background_color.g + 0.114 * menu_background_color.b
	
	# If background is light (luminance > 0.5), use dark text
	if luminance > 0.5:
		return Color.BLACK
	else:
		return Color.WHITE

func _get_appropriate_button_font_color() -> Color:
	# Calculate button background brightness
	var luminance = 0.299 * button_color.r + 0.587 * button_color.g + 0.114 * button_color.b
	
	# If button background is light, use dark text
	if luminance > 0.4:  # Slightly lower threshold for buttons
		return Color.BLACK
	else:
		return Color.WHITE

func apply_to_menu_bar(menu_bar: MenuBar) -> void:
	if not menu_bar:
		return
	
	print("Applying theme '", theme_name, "' to MenuBar")
	
	var theme = Theme.new()
	
	# Apply fonts if available
	if ui_font:
		theme.set_font("font", "MenuBar", ui_font)
		theme.set_font_size("font_size", "MenuBar", ui_font_size)
		print("Applied National2 font to MenuBar")
	
	# Style for menu bar
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = menu_background_color
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	theme.set_stylebox("normal", "MenuBar", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = button_hover_color
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	theme.set_stylebox("hover", "MenuBar", style_hover)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = button_pressed_color
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	theme.set_stylebox("pressed", "MenuBar", style_pressed)
	
	# Font colors - Use smart color based on background brightness
	var menu_font_color = _get_appropriate_menu_font_color()
	theme.set_color("font_color", "MenuBar", menu_font_color)
	theme.set_color("font_hover_color", "MenuBar", menu_font_color.lightened(0.2))
	theme.set_color("font_pressed_color", "MenuBar", menu_font_color.darkened(0.2))
	
	print("Applied MenuBar font color: ", menu_font_color)
	menu_bar.theme = theme

func apply_to_popup_menu(popup_menu: PopupMenu) -> void:
	if not popup_menu:
		return
	
	print("Applying theme '", theme_name, "' to PopupMenu")
	
	var theme = Theme.new()
	
	# Apply fonts if available
	if ui_font:
		theme.set_font("font", "PopupMenu", ui_font)
		theme.set_font_size("font_size", "PopupMenu", ui_font_size)
		print("Applied National2 font to PopupMenu")
	
	# Background panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = menu_background_color
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	if enable_outline_effects:
		panel_style.border_color = outline_color
		panel_style.border_width_left = int(outline_width)
		panel_style.border_width_right = int(outline_width)
		panel_style.border_width_top = int(outline_width)
		panel_style.border_width_bottom = int(outline_width)
	if enable_text_shadows:
		panel_style.shadow_color = text_shadow_color
		panel_style.shadow_offset = text_shadow_offset
		panel_style.shadow_size = 4
	theme.set_stylebox("panel", "PopupMenu", panel_style)
	
	# Hover state for menu items
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = button_hover_color
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	theme.set_stylebox("hover", "PopupMenu", hover_style)
	
	# Font colors - Use smart color based on background brightness
	var popup_font_color = _get_appropriate_menu_font_color()
	theme.set_color("font_color", "PopupMenu", popup_font_color)
	theme.set_color("font_hover_color", "PopupMenu", popup_font_color.lightened(0.2))
	theme.set_color("font_accelerator_color", "PopupMenu", Color(popup_font_color.r, popup_font_color.g, popup_font_color.b, 0.7))
	
	print("Applied PopupMenu font color: ", popup_font_color)
	popup_menu.theme = theme

func apply_to_label(label: Label) -> void:
	if not label:
		return
	
	print("Applying theme '", theme_name, "' to Label: ", label.name)
	
	# Apply fonts and colors with proper contrast
	if ui_font:
		label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", ui_font_size)
	
	# Use appropriate text color based on background
	label.add_theme_color_override("font_color", text_color)
	
	print("Applied Label font color: ", text_color)

func apply_to_container(container: Control) -> void:
	if not container:
		return
	
	print("Applying theme '", theme_name, "' to Container: ", container.name)
	
	# Create a background StyleBox for containers like Toolbar
	var style_background = StyleBoxFlat.new()
	style_background.bg_color = status_bar_color  # Use status bar color for toolbars
	style_background.corner_radius_bottom_left = 0
	style_background.corner_radius_bottom_right = 0
	style_background.corner_radius_top_left = 0
	style_background.corner_radius_top_right = 0
	
	# Apply the background style
	container.add_theme_stylebox_override("panel", style_background)
	
	print("Applied Container background: ", status_bar_color)

func get_syntax_highlighter() -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	
	# Set colors
	highlighter.symbol_color = symbol_color
	highlighter.function_color = function_color
	highlighter.number_color = number_color
	
	return highlighter

func get_syntax_highlighter_for_file(file_extension: String) -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	var extension = file_extension.to_lower()
	
	# Clear any existing highlighting
	highlighter.clear_color_regions()
	highlighter.clear_member_keyword_colors()
	highlighter.clear_keyword_colors()
	
	match extension:
		"gd":
			_setup_gdscript_highlighting_themed(highlighter)
		"py":
			_setup_python_highlighting_themed(highlighter)
		"md":
			_setup_markdown_highlighting_themed(highlighter)
		"json":
			_setup_json_highlighting_themed(highlighter)
		_:
			# Default highlighting
			highlighter.symbol_color = symbol_color
			highlighter.function_color = function_color
			highlighter.number_color = number_color
	
	return highlighter

func _setup_gdscript_highlighting_themed(highlighter: CodeHighlighter) -> void:
	# Core GDScript keywords - using traditional keyword color but theme-aware
	var core_keywords = ["and", "as", "assert", "await", "break", "breakpoint", "class_name", 
						"const", "continue", "elif", "else", "enum", "extends", "for", 
						"if", "in", "is", "match", "not", "or", "pass", "return", 
						"static", "super", "var", "void", "while", "yield"]
	
	for keyword in core_keywords:
		highlighter.add_keyword_color(keyword, keyword_color)
	
	# Function and class specific colors
	highlighter.add_keyword_color("func", gdscript_func_color)
	highlighter.add_keyword_color("class", gdscript_class_color)
	highlighter.add_keyword_color("signal", gdscript_signal_color)
	
	# Built-in types and functions
	var builtins = ["bool", "int", "float", "String", "Vector2", "Vector3", "Color", 
					"Node", "PackedStringArray", "Array", "Dictionary", "NodePath", "Resource"]
	for builtin in builtins:
		highlighter.add_keyword_color(builtin, gdscript_builtin_color)
	
	# Comments
	highlighter.add_color_region("#", "", comment_color, true)
	
	# Strings
	highlighter.add_color_region("\"", "\"", string_color)
	highlighter.add_color_region("'", "'", string_color)
	highlighter.add_color_region("\"\"\"", "\"\"\"", string_color)
	
	# Numbers and symbols
	highlighter.number_color = number_color
	highlighter.symbol_color = symbol_color

func _setup_python_highlighting_themed(highlighter: CodeHighlighter) -> void:
	# Core Python keywords
	var core_keywords = ["and", "as", "assert", "break", "continue", "del", "elif", "else", 
						"except", "exec", "finally", "for", "from", "global", "if", "in", 
						"is", "lambda", "not", "or", "pass", "print", "raise", "return", 
						"try", "while", "with", "yield"]
	
	for keyword in core_keywords:
		highlighter.add_keyword_color(keyword, keyword_color)
	
	# Python specific colors
	highlighter.add_keyword_color("def", python_def_color)
	highlighter.add_keyword_color("class", python_class_color)
	highlighter.add_keyword_color("import", python_import_color)
	highlighter.add_keyword_color("from", python_import_color)
	
	# Decorators (basic pattern matching)
	highlighter.add_color_region("@", " ", python_decorator_color, true)
	highlighter.add_color_region("@", "\n", python_decorator_color, true)
	highlighter.add_color_region("@", "(", python_decorator_color, false)
	
	# Comments
	highlighter.add_color_region("#", "", comment_color, true)
	
	# Strings
	highlighter.add_color_region("\"", "\"", string_color)
	highlighter.add_color_region("'", "'", string_color)
	highlighter.add_color_region("\"\"\"", "\"\"\"", string_color)
	highlighter.add_color_region("'''", "'''", string_color)
	
	# Numbers and symbols
	highlighter.number_color = number_color
	highlighter.symbol_color = symbol_color

func _setup_markdown_highlighting_themed(highlighter: CodeHighlighter) -> void:
	# Headers
	highlighter.add_color_region("#", "", markdown_header_color, true)
	highlighter.add_color_region("##", "", markdown_header_color, true)
	highlighter.add_color_region("###", "", markdown_header_color, true)
	
	# Bold text
	highlighter.add_color_region("**", "**", markdown_bold_color)
	highlighter.add_color_region("__", "__", markdown_bold_color)
	
	# Italic text
	highlighter.add_color_region("*", "*", markdown_italic_color)
	highlighter.add_color_region("_", "_", markdown_italic_color)
	
	# Inline code
	highlighter.add_color_region("`", "`", markdown_code_color)
	
	# Links (basic pattern)
	highlighter.add_color_region("[", "]", markdown_link_color)
	
	# Code blocks
	highlighter.add_color_region("```", "```", markdown_code_color)
	
	# Checkboxes - unchecked and checked
	highlighter.add_color_region("[ ]", " ", markdown_checkbox_unchecked_color, false)
	highlighter.add_color_region("[X]", " ", markdown_checkbox_checked_color, false)
	
	# Symbols
	highlighter.symbol_color = symbol_color

func _setup_json_highlighting_themed(highlighter: CodeHighlighter) -> void:
	# JSON strings (keys and values)
	highlighter.add_color_region("\"", "\"", json_key_color)
	
	# Numbers
	highlighter.number_color = number_color
	
	# Brackets and braces
	highlighter.symbol_color = json_bracket_color
	
	# Boolean values
	highlighter.add_keyword_color("true", json_value_color)
	highlighter.add_keyword_color("false", json_value_color)
	highlighter.add_keyword_color("null", json_value_color)

func apply_visual_effects(effects_manager: Node) -> void:
	# Apply visual effects using the provided VisualEffectsManager
	if effects_manager and effects_manager.has_method("apply_theme_effects"):
		var effects_config = {
			"text_shadow": {
				"enabled": enable_text_shadows,
				"color": text_shadow_color,
				"offset": text_shadow_offset,
				"blur": 1.0
			},
			"outline": {
				"enabled": enable_outline_effects,
				"color": outline_color,
				"width": outline_width,
				"smoothness": 0.1
			},
			"gradient": {
				"enabled": enable_gradient_backgrounds,
				"start_color": gradient_start_color,
				"end_color": gradient_end_color,
				"direction": Vector2(0, 1)
			}
		}
		
		effects_manager.apply_theme_effects(effects_config)

func get_effects_config() -> Dictionary:
	return {
		"pulse_effects": enable_pulse_effects,
		"glow_effects": enable_glow_effects,
		"text_shadows": enable_text_shadows,
		"outline_effects": enable_outline_effects,
		"gradient_backgrounds": enable_gradient_backgrounds
	}
