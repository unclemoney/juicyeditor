extends Control
class_name ThemeSwitcher

# Juicy Editor - Theme Switcher UI Component
# Provides a UI for switching between available themes

signal theme_selected(theme: JuicyTheme)

@export var theme_manager: Node
@onready var theme_option_button: OptionButton = $VBoxContainer/ThemeOptionButton
@onready var preview_label: Label = $VBoxContainer/PreviewLabel
@onready var apply_button: Button = $VBoxContainer/ApplyButton

func _ready() -> void:
	if not theme_manager:
		# Try to find theme manager in scene
		theme_manager = get_node("/root/Main/ThemeManager")
	
	if theme_manager:
		setup_theme_options()
		if theme_manager.has_signal("theme_changed"):
			theme_manager.theme_changed.connect(_on_theme_changed)
	
	if apply_button:
		apply_button.pressed.connect(_on_apply_button_pressed)
	if theme_option_button:
		theme_option_button.item_selected.connect(_on_theme_option_selected)

func setup_theme_options() -> void:
	if not theme_option_button or not theme_manager:
		return
	
	theme_option_button.clear()
	
	var theme_names = theme_manager.get_theme_names()
	for theme_name in theme_names:
		theme_option_button.add_item(theme_name)
	
	# Set current selection
	if theme_manager.current_theme:
		var current_index = theme_names.find(theme_manager.current_theme.theme_name)
		if current_index >= 0:
			theme_option_button.selected = current_index
			update_preview()

func update_preview() -> void:
	if not preview_label or not theme_option_button or not theme_manager:
		return
	
	var selected_index = theme_option_button.selected
	if selected_index < 0:
		return
	
	var selected_theme_name = theme_option_button.get_item_text(selected_index)
	var selected_theme = theme_manager.get_theme_by_name(selected_theme_name)
	
	if selected_theme:
		preview_label.text = "Preview: " + selected_theme.description
		
		# Apply preview styling
		var ui_theme = Theme.new()
		if selected_theme.ui_font:
			ui_theme.set_font("font", "Label", selected_theme.ui_font)
			ui_theme.set_font_size("font_size", "Label", selected_theme.ui_font_size)
		ui_theme.set_color("font_color", "Label", selected_theme.text_color)
		preview_label.theme = ui_theme

func _on_theme_option_selected(_index: int) -> void:
	update_preview()

func _on_apply_button_pressed() -> void:
	if not theme_option_button or not theme_manager:
		return
	
	var selected_index = theme_option_button.selected
	if selected_index < 0:
		return
	
	var selected_theme_name = theme_option_button.get_item_text(selected_index)
	var selected_theme = theme_manager.get_theme_by_name(selected_theme_name)
	
	if selected_theme:
		theme_manager.set_theme(selected_theme)
		theme_selected.emit(selected_theme)

func _on_theme_changed(juicy_theme: JuicyTheme) -> void:
	# Update selection to match current theme
	if theme_option_button and juicy_theme:
		var theme_names = theme_manager.get_theme_names()
		var index = theme_names.find(juicy_theme.theme_name)
		if index >= 0:
			theme_option_button.selected = index
			update_preview()