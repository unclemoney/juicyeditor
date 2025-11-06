extends Control
class_name EmergencyTest

@onready var test_label = $VBoxContainer/TestLabel
@onready var test_button = $VBoxContainer/TestButton
@onready var test_text_edit = $VBoxContainer/TestTextEdit
@onready var test_rich_text = $VBoxContainer/TestRichTextLabel

func _ready():
	print("EMERGENCY TEST: Scene loaded")
	
	# Force EXTREME colors on all elements
	modulate = Color.WHITE  # Ensure scene visibility
	
	# Test Label - BRIGHT COLORS
	if test_label:
		test_label.add_theme_color_override("font_color", Color.RED)
		test_label.add_theme_font_size_override("font_size", 48)
		print("EMERGENCY: Label color set to RED, size 48")
	
	# Test Button - EXTREME CONTRAST  
	if test_button:
		test_button.add_theme_color_override("font_color", Color.MAGENTA)
		test_button.add_theme_font_size_override("font_size", 32)
		test_button.modulate = Color.YELLOW  # Background tint
		print("EMERGENCY: Button color set to MAGENTA on YELLOW, size 32")
		
		test_button.pressed.connect(_on_button_pressed)
	
	# Test TextEdit - MAXIMUM CONTRAST
	if test_text_edit:
		test_text_edit.add_theme_color_override("background_color", Color.CYAN)
		test_text_edit.add_theme_color_override("font_color", Color.BLACK)
		test_text_edit.add_theme_font_size_override("font_size", 24)
		print("EMERGENCY: TextEdit - CYAN background, BLACK text, size 24")
	
	# Test RichTextLabel
	if test_rich_text:
		test_rich_text.add_theme_color_override("default_color", Color.WHITE)
		test_rich_text.add_theme_color_override("background_color", Color.BLACK)
		test_rich_text.add_theme_font_size_override("normal_font_size", 20)
		print("EMERGENCY: RichTextLabel - WHITE on BLACK, size 20")
	
	print("EMERGENCY TEST: All colors applied - if you can't see ANYTHING, there's a system-level issue")

func _on_button_pressed():
	print("EMERGENCY: Button was clicked!")
	test_label.text = "BUTTON CLICKED - SUCCESS!"
	test_label.add_theme_color_override("font_color", Color.GREEN)