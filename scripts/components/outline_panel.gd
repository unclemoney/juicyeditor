extends PanelContainer
class_name OutlinePanel

## Juicy Editor - Outline Panel Component
## Creates a collapsible side panel with markdown heading navigation
## Features: Tween animations, heading parsing, click-to-navigate

signal heading_clicked(line_number: int)
signal panel_toggled(is_visible: bool)

# Panel configuration
@export var panel_width: float = 250.0
@export var animation_duration: float = 0.3
@export var collapsed_width: float = 35.0  # Width of toggle button area

# Node references
var text_editor: TextEdit
var scroll_container: ScrollContainer
var heading_container: VBoxContainer
var toggle_button: Button
var title_label: Label

# State
var is_collapsed: bool = false
var headings: Array[Dictionary] = []  # {level: int, text: String, line: int}
var heading_buttons: Array[Button] = []

# Tween reference
var panel_tween: Tween

# Style colors for different heading levels - Pink gradient from light to dark
var heading_colors: Dictionary = {
	1: Color(1.0, 0.85, 0.9),   # H1 - Lightest Pink
	2: Color(1.0, 0.7, 0.82),   # H2 - Light Pink
	3: Color(0.95, 0.55, 0.7),  # H3 - Medium Pink
	4: Color(0.9, 0.4, 0.6),    # H4 - Rose Pink
	5: Color(0.8, 0.3, 0.5),    # H5 - Dark Rose
	6: Color(0.7, 0.2, 0.4),    # H6 - Darkest Pink
}

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	
	# Set initial size
	custom_minimum_size.x = panel_width
	size.x = panel_width

func _setup_ui() -> void:
	"""Create the panel UI structure"""
	# Main vertical container
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)
	
	# Header with title and toggle button
	var header_hbox = HBoxContainer.new()
	header_hbox.name = "HeaderHBox"
	main_vbox.add_child(header_hbox)
	
	# Title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "📑 Outline"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_label)
	
	# Toggle button
	toggle_button = Button.new()
	toggle_button.name = "ToggleButton"
	toggle_button.text = "▶"
	toggle_button.tooltip_text = "Collapse Outline Panel"
	toggle_button.custom_minimum_size = Vector2(30, 30)
	header_hbox.add_child(toggle_button)
	
	# Separator
	var separator = HSeparator.new()
	separator.name = "Separator"
	main_vbox.add_child(separator)
	
	# Scroll container for headings
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll_container)
	
	# Container for heading buttons
	heading_container = VBoxContainer.new()
	heading_container.name = "HeadingContainer"
	heading_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(heading_container)
	
	# Empty state label (shown when no headings)
	var empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.text = "No headings found.\nAdd # to create headings."
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	heading_container.add_child(empty_label)

func _connect_signals() -> void:
	"""Connect button signals"""
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_pressed)

func setup_text_editor(editor: TextEdit) -> void:
	"""Connect to the text editor for content updates"""
	text_editor = editor
	
	if text_editor:
		# Connect to text changes
		text_editor.text_changed.connect(_on_text_changed)
		
		# Connect to caret changes to highlight current section
		text_editor.caret_changed.connect(_on_caret_changed)
		
		# Initial parse
		_parse_headings()

func _on_toggle_pressed() -> void:
	"""Handle toggle button press with animation"""
	if is_collapsed:
		expand_panel()
	else:
		collapse_panel()

func collapse_panel() -> void:
	"""Collapse the panel with tween animation"""
	if is_collapsed:
		return
	
	is_collapsed = true
	toggle_button.text = "◀"
	toggle_button.tooltip_text = "Expand Outline Panel"
	
	# Kill any existing tween
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()
	
	# Create new tween for collapse animation
	panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_IN_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate width to collapsed state
	panel_tween.tween_property(self, "custom_minimum_size:x", collapsed_width, animation_duration)
	panel_tween.parallel().tween_property(self, "size:x", collapsed_width, animation_duration)
	
	# Hide content during animation
	panel_tween.parallel().tween_property(scroll_container, "modulate:a", 0.0, animation_duration * 0.5)
	panel_tween.parallel().tween_property(title_label, "modulate:a", 0.0, animation_duration * 0.5)
	
	panel_toggled.emit(false)

func expand_panel() -> void:
	"""Expand the panel with tween animation"""
	if not is_collapsed:
		return
	
	is_collapsed = false
	toggle_button.text = "▶"
	toggle_button.tooltip_text = "Collapse Outline Panel"
	
	# Kill any existing tween
	if panel_tween and panel_tween.is_valid():
		panel_tween.kill()
	
	# Create new tween for expand animation
	panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate width to expanded state
	panel_tween.tween_property(self, "custom_minimum_size:x", panel_width, animation_duration)
	panel_tween.parallel().tween_property(self, "size:x", panel_width, animation_duration)
	
	# Show content after width starts expanding
	panel_tween.tween_property(scroll_container, "modulate:a", 1.0, animation_duration * 0.5)
	panel_tween.parallel().tween_property(title_label, "modulate:a", 1.0, animation_duration * 0.5)
	
	panel_toggled.emit(true)

func _on_text_changed() -> void:
	"""Handle text changes - reparse headings"""
	_parse_headings()

func _on_caret_changed() -> void:
	"""Handle caret position changes - highlight current section"""
	highlight_current_heading()

func _parse_headings() -> void:
	"""Parse markdown headings from text editor content"""
	if not text_editor:
		return
	
	headings.clear()
	
	var lines = text_editor.text.split("\n")
	for i in range(lines.size()):
		var line = lines[i]
		var heading_data = _parse_heading_line(line, i)
		if heading_data:
			headings.append(heading_data)
	
	_update_heading_display()

func _parse_heading_line(line: String, line_number: int) -> Dictionary:
	"""Parse a single line for markdown heading syntax"""
	var stripped = line.strip_edges()
	
	# Check for markdown heading syntax (# to ######)
	if not stripped.begins_with("#"):
		return {}
	
	# Count the number of # characters
	var level = 0
	for c in stripped:
		if c == "#":
			level += 1
		else:
			break
	
	# Valid heading levels are 1-6
	if level < 1 or level > 6:
		return {}
	
	# Check that there's a space after the #'s
	if stripped.length() <= level:
		return {}
	
	if stripped[level] != " ":
		return {}
	
	# Extract heading text
	var heading_text = stripped.substr(level + 1).strip_edges()
	
	if heading_text.is_empty():
		return {}
	
	return {
		"level": level,
		"text": heading_text,
		"line": line_number
	}

func _update_heading_display() -> void:
	"""Update the heading buttons display"""
	# Clear existing buttons
	for button in heading_buttons:
		if button and is_instance_valid(button):
			button.queue_free()
	heading_buttons.clear()
	
	# Get empty label
	var empty_label = heading_container.get_node_or_null("EmptyLabel")
	
	if headings.is_empty():
		# Show empty state
		if empty_label:
			empty_label.visible = true
		return
	
	# Hide empty state
	if empty_label:
		empty_label.visible = false
	
	# Create buttons for each heading
	for heading in headings:
		var button = _create_heading_button(heading)
		heading_container.add_child(button)
		heading_buttons.append(button)

func _create_heading_button(heading: Dictionary) -> Button:
	"""Create a styled button for a heading"""
	var button = Button.new()
	
	# Calculate indentation based on heading level
	var indent = "  ".repeat(heading.level - 1)
	var prefix = _get_heading_prefix(heading.level)
	
	button.text = indent + prefix + heading.text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Set consistent button height to prevent size changes on selection
	button.custom_minimum_size.y = 28
	
	# Style based on heading level
	var color = heading_colors.get(heading.level, Color.WHITE)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.2))
	button.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	
	# Adjust font size based on level
	var base_size = 16
	var font_size = base_size - (heading.level - 1) * 1
	button.add_theme_font_size_override("font_size", max(font_size, 11))
	
	# Apply consistent stylebox for all states to prevent height changes
	var normal_style = _create_button_stylebox(false)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", _create_button_stylebox(false))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(false))
	button.add_theme_stylebox_override("focus", _create_button_stylebox(false))
	
	# Connect click handler
	button.pressed.connect(_on_heading_button_pressed.bind(heading.line))
	
	# Add tooltip
	button.tooltip_text = "Go to line " + str(heading.line + 1)
	
	return button

func _get_heading_prefix(level: int) -> String:
	"""Get visual prefix for heading level"""
	match level:
		1: return "◆ "
		2: return "◇ "
		3: return "▸ "
		4: return "▹ "
		5: return "• "
		6: return "◦ "
		_: return "- "

func _on_heading_button_pressed(line_number: int) -> void:
	"""Handle heading button click - navigate to line"""
	if text_editor:
		# Set caret to the heading line
		text_editor.set_caret_line(line_number)
		text_editor.set_caret_column(0)
		
		# Center the viewport on the heading
		text_editor.center_viewport_to_caret()
		
		# Give focus back to text editor
		text_editor.grab_focus()
		
		# Emit signal for external handling
		heading_clicked.emit(line_number)
		
		# Play click sound if audio manager available
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_ui_sound"):
			audio_manager.play_ui_sound("button_click")

func refresh_outline() -> void:
	"""Force refresh of the outline"""
	_parse_headings()

func get_headings() -> Array[Dictionary]:
	"""Get the current list of headings"""
	return headings

func scroll_to_heading(index: int) -> void:
	"""Scroll the outline panel to show a specific heading"""
	if index < 0 or index >= heading_buttons.size():
		return
	
	var button = heading_buttons[index]
	if button and scroll_container:
		# Calculate scroll position to show button
		var button_pos = button.position.y
		scroll_container.scroll_vertical = int(button_pos)

func highlight_current_heading() -> void:
	"""Highlight the heading closest to current cursor position"""
	if not text_editor or headings.is_empty():
		return
	
	var current_line = text_editor.get_caret_line()
	
	# Find the heading that's closest (but not past) the current line
	var closest_index = -1
	for i in range(headings.size()):
		if headings[i].line <= current_line:
			closest_index = i
		else:
			break
	
	# Update button styles to highlight current section
	for i in range(heading_buttons.size()):
		var button = heading_buttons[i]
		if not button or not is_instance_valid(button):
			continue
		
		var heading = headings[i]
		var base_color = heading_colors.get(heading.level, Color.WHITE)
		
		if i == closest_index:
			# Highlight current heading with consistent stylebox
			button.add_theme_color_override("font_color", base_color.lightened(0.3))
			button.add_theme_stylebox_override("normal", _create_button_stylebox(true))
		else:
			# Normal style with consistent stylebox
			button.add_theme_color_override("font_color", base_color)
			button.add_theme_stylebox_override("normal", _create_button_stylebox(false))

func _create_button_stylebox(highlighted: bool) -> StyleBoxFlat:
	"""Create a consistent stylebox for heading buttons"""
	var style = StyleBoxFlat.new()
	if highlighted:
		style.bg_color = Color(1.0, 0.8, 0.9, 0.2)  # Light pink highlight
	else:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	# Consistent content margins to prevent height changes
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	return style
