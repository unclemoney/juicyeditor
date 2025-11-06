extends Node
class_name ThemeManager

# Juicy Editor - Theme Manager
# Handles theme loading, application, and switching

signal theme_changed(theme: JuicyTheme)

@export var current_theme: JuicyTheme
@export var available_themes: Array[JuicyTheme] = []

var ui_elements: Dictionary = {}

func _ready() -> void:
	# Load available themes
	load_available_themes()
	
	# Set default theme if none is set
	if not current_theme and available_themes.size() > 0:
		current_theme = available_themes[0]

func load_available_themes() -> void:
	available_themes.clear()
	
	# Load theme files from themes directory
	var theme_files = [
		"res://themes/juicy_theme.tres",
		"res://themes/super_juicy_theme.tres",
		"res://themes/dark_theme.tres",
		"res://themes/light_theme.tres"
	]
	
	for theme_path in theme_files:
		if ResourceLoader.exists(theme_path):
			var theme = ResourceLoader.load(theme_path, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as JuicyTheme
			if theme:
				theme._validate_theme_data()  # Ensure theme data is properly initialized
				available_themes.append(theme)

func register_ui_element(element_name: String, element: Node) -> void:
	ui_elements[element_name] = element
	
	# Apply current theme to the new element
	if current_theme:
		apply_theme_to_element(element)

func unregister_ui_element(element_name: String) -> void:
	ui_elements.erase(element_name)

func set_theme(theme: JuicyTheme) -> void:
	if theme == current_theme:
		return
	
	print("DEBUG: ThemeManager.set_theme called with theme: ", theme.theme_name if theme else "null")
	if theme:
		print("DEBUG: Theme background_color: ", theme.background_color)
		print("DEBUG: Theme text_color: ", theme.text_color)
	
	current_theme = theme
	apply_current_theme()
	theme_changed.emit(theme)

func apply_current_theme() -> void:
	if not current_theme:
		return
	
	# Clear any existing materials from previous themes
	clear_existing_materials()
	
	# Apply theme to all registered UI elements
	for element in ui_elements.values():
		apply_theme_to_element(element)

func clear_existing_materials() -> void:
	# Clear materials from all registered UI elements to prevent gradient persistence
	for element in ui_elements.values():
		if element and element.has_method("set_material"):
			element.set_material(null)

func apply_theme_to_element(element: Node) -> void:
	if not element or not current_theme:
		return
	
	# Apply theme based on element type
	if element is TextEdit:
		current_theme.apply_to_text_edit(element as TextEdit)
	elif element is Button:
		current_theme.apply_to_button(element as Button)
		apply_button_animations(element as Button)
	elif element is MenuBar:
		current_theme.apply_to_menu_bar(element as MenuBar)
		apply_menu_animations(element as MenuBar)
	elif element is PopupMenu:
		current_theme.apply_to_popup_menu(element as PopupMenu)
	elif element is Label:
		current_theme.apply_to_label(element as Label)
	elif element is HBoxContainer or element is VBoxContainer:
		# Apply container styling to toolbars and similar containers
		if current_theme.has_method("apply_to_container"):
			current_theme.apply_to_container(element as Control)
	
	# Apply visual effects if the element supports them (DISABLED - gradient system causes text rendering issues)
	# if element is Control and element.has_method("set_material") and current_theme.enable_gradient_backgrounds:
	# 	# Don't apply gradient backgrounds to text-bearing elements as they interfere with text rendering
	# 	if not element is Button and not element is Label and not element is MenuBar and not element is PopupMenu:
	# 		apply_gradient_background(element as Control)

func apply_button_animations(button: Button) -> void:
	if not current_theme.enable_bounce_effects:
		return
	
	# Connect mouse enter/exit signals for animation
	if not button.mouse_entered.is_connected(_on_button_mouse_entered):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	if not button.mouse_exited.is_connected(_on_button_mouse_exited):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	if not button.button_down.is_connected(_on_button_pressed):
		button.button_down.connect(_on_button_pressed.bind(button))
	if not button.button_up.is_connected(_on_button_released):
		button.button_up.connect(_on_button_released.bind(button))

func apply_menu_animations(_menu_bar: MenuBar) -> void:
	# Disable pulse effects for now to avoid errors
	# TODO: Fix pulse menu animation in future update
	pass

func apply_gradient_background(element: Control) -> void:
	if not current_theme.enable_gradient_backgrounds:
		return
	
	# Create gradient shader material
	var shader_material = ShaderMaterial.new()
	var gradient_shader = preload("res://shaders/gradient.gdshader")
	
	if gradient_shader:
		shader_material.shader = gradient_shader
		shader_material.set_shader_parameter("start_color", current_theme.gradient_start_color)
		shader_material.set_shader_parameter("end_color", current_theme.gradient_end_color)
		shader_material.set_shader_parameter("direction", Vector2(0, 1))
		
		if element.has_method("set_material"):
			element.set_material(shader_material)

func get_theme_names() -> Array[String]:
	var names: Array[String] = []
	for theme in available_themes:
		names.append(theme.theme_name)
	return names

func get_theme_by_name(theme_name: String) -> JuicyTheme:
	for theme in available_themes:
		if theme.theme_name == theme_name:
			return theme
	return null

# Animation callbacks
func _on_button_mouse_entered(button: Button) -> void:
	if not current_theme.enable_bounce_effects:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * current_theme.button_scale_effect, current_theme.button_animation_speed)
	tween.tween_property(button, "rotation", deg_to_rad(-2), current_theme.button_animation_speed * 0.5)

func _on_button_mouse_exited(button: Button) -> void:
	if not current_theme.enable_bounce_effects:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, current_theme.button_animation_speed)
	tween.tween_property(button, "rotation", 0.0, current_theme.button_animation_speed * 0.5)

func _on_button_pressed(button: Button) -> void:
	if not current_theme.enable_bounce_effects:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 0.95, current_theme.button_animation_speed * 0.3)

func _on_button_released(button: Button) -> void:
	if not current_theme.enable_bounce_effects:
		return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * current_theme.button_scale_effect, current_theme.button_animation_speed * 0.3)

func _pulse_menu_item(menu_bar: MenuBar, progress: float) -> void:
	var pulse_strength = 0.05 * sin(progress * PI)
	var pulse_color = Color.WHITE
	pulse_color.a = pulse_strength
	
	if menu_bar.has_method("add_theme_color_override"):
		menu_bar.add_theme_color_override("font_hover_color", current_theme.text_color.lerp(pulse_color, pulse_strength))