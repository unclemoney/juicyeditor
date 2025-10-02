extends Resource
class_name JuicyTheme

# Juicy Editor - Theme Resource
# Defines colors, fonts, and visual styling

@export var theme_name: String = "Default"
@export var description: String = "Default Juicy Editor theme"

# Color scheme
@export_group("Colors")
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var text_color: Color = Color(0.9, 0.9, 0.9, 1.0)
@export var selection_color: Color = Color(0.3, 0.4, 0.8, 0.5)
@export var current_line_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var line_number_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var caret_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# UI Colors
@export_group("UI Colors")
@export var button_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var button_hover_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var button_pressed_color: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var menu_background_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var status_bar_color: Color = Color(0.12, 0.12, 0.12, 1.0)

# Syntax highlighting colors
@export_group("Syntax Colors")
@export var keyword_color: Color = Color(0.4, 0.8, 1.0, 1.0)
@export var string_color: Color = Color(1.0, 0.8, 0.4, 1.0)
@export var comment_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var number_color: Color = Color(0.8, 1.0, 0.6, 1.0)
@export var function_color: Color = Color(1.0, 0.6, 0.8, 1.0)
@export var variable_color: Color = Color(0.8, 0.8, 1.0, 1.0)

# Typography
@export_group("Typography")
@export var editor_font_size: int = 14
@export var ui_font_size: int = 12
@export var line_height_multiplier: float = 1.2

# Effects
@export_group("Effects")
@export var enable_text_shadows: bool = false
@export var text_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.3)
@export var text_shadow_offset: Vector2 = Vector2(1, 1)
@export var enable_gradient_backgrounds: bool = false
@export var gradient_start_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var gradient_end_color: Color = Color(0.05, 0.05, 0.05, 1.0)
@export var enable_outline_effects: bool = false
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var outline_width: float = 1.0
@export var enable_pulse_effects: bool = true
@export var enable_glow_effects: bool = true

func apply_to_text_edit(text_edit: TextEdit) -> void:
	if not text_edit:
		return
	
	# Create a theme for the text edit
	var theme = Theme.new()
	
	# Apply colors to text edit
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = background_color
	theme.set_stylebox("normal", "TextEdit", style_box)
	
	var style_box_focus = StyleBoxFlat.new()
	style_box_focus.bg_color = background_color
	style_box_focus.border_color = selection_color
	style_box_focus.border_width_left = 2
	style_box_focus.border_width_right = 2
	style_box_focus.border_width_top = 2
	style_box_focus.border_width_bottom = 2
	theme.set_stylebox("focus", "TextEdit", style_box_focus)
	
	# Apply theme
	text_edit.theme = theme
	
	# Apply additional properties if available
	if text_edit.has_method("add_theme_color_override"):
		text_edit.add_theme_color_override("font_color", text_color)
		text_edit.add_theme_color_override("font_selected_color", text_color)
		text_edit.add_theme_color_override("selection_color", selection_color)
		text_edit.add_theme_color_override("current_line_color", current_line_color)
		text_edit.add_theme_color_override("caret_color", caret_color)

func apply_to_button(button: Button) -> void:
	if not button:
		return
	
	var theme = Theme.new()
	
	# Normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = button_color
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	theme.set_stylebox("normal", "Button", style_normal)
	
	# Hover state
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = button_hover_color
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	theme.set_stylebox("hover", "Button", style_hover)
	
	# Pressed state
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = button_pressed_color
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	theme.set_stylebox("pressed", "Button", style_pressed)
	
	button.theme = theme

func get_syntax_highlighter() -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	
	# Set colors
	highlighter.symbol_color = text_color
	highlighter.function_color = function_color
	highlighter.number_color = number_color
	
	return highlighter

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
