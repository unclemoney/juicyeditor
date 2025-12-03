extends PanelContainer
class_name OutlinePanel

## Juicy Editor - Outline Panel Component
## Creates a collapsible side panel with markdown heading navigation
## Features: Tween animations, heading parsing, click-to-navigate, task list support

signal heading_clicked(line_number: int)
signal panel_toggled(is_visible: bool)
signal task_clicked(line_number: int, is_checked: bool)

# Panel configuration
@export var panel_width: float = 250.0
@export var animation_duration: float = 0.3
@export var collapsed_width: float = 35.0  # Width of toggle button area
@export var task_expand_duration: float = 0.25  # Animation duration for task list expand/collapse

# Node references
var text_editor: TextEdit
var scroll_container: ScrollContainer
var heading_container: VBoxContainer
var toggle_button: Button
var title_label: Label

# State
var is_collapsed: bool = false
var headings: Array[Dictionary] = []  # {level: int, text: String, line: int, tasks: Array}
var heading_buttons: Array[Button] = []
var heading_items: Array[VBoxContainer] = []  # Container items for each heading (includes tasks)
var task_containers: Dictionary = {}  # heading_line -> Control for tasks
var expanded_headings: Dictionary = {}  # heading_line -> bool (is expanded)

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

# Task styling
var task_color_unchecked: Color = Color(0.8, 0.8, 0.8)
var task_color_checked: Color = Color(0.5, 0.5, 0.5)
var star_indicator: String = "★"

# Pre-compiled regex patterns for task parsing
var _task_regex_standard: RegEx  # Matches: - [ ] task or * [ ] task or + [ ] task
var _task_regex_simple: RegEx    # Matches: [ ] task (no leading dash)

func _ready() -> void:
	# Compile task regex patterns
	_task_regex_standard = RegEx.new()
	_task_regex_standard.compile("^[-*+]\\s*\\[([ xX])\\]\\s+(.+)$")
	_task_regex_simple = RegEx.new()
	_task_regex_simple.compile("^\\[([ xX])\\]\\s+(.+)$")
	_setup_ui()
	_connect_signals()
	
	# Set initial size with proper flags for HSplitContainer
	custom_minimum_size.x = panel_width
	size.x = panel_width
	size_flags_horizontal = Control.SIZE_FILL  # Allow resizing in HSplitContainer

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
	
	# Store expanded width for later restore
	panel_width = size.x if size.x > collapsed_width else panel_width
	
	# Create new tween for collapse animation
	panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_IN_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Hide content completely so they don't take up space
	scroll_container.visible = false
	title_label.visible = false
	
	# Animate the custom_minimum_size to collapsed width
	panel_tween.tween_property(self, "custom_minimum_size:x", collapsed_width, animation_duration)
	
	# If we're in an HSplitContainer, animate the split_offset to push panel to the right edge
	var parent_node = get_parent()
	if parent_node is HSplitContainer:
		var target_offset = parent_node.size.x - collapsed_width
		panel_tween.parallel().tween_property(parent_node, "split_offset", int(target_offset), animation_duration)
	
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
	
	# Show content nodes
	scroll_container.visible = true
	title_label.visible = true
	scroll_container.modulate.a = 0.0
	title_label.modulate.a = 0.0
	
	# Create new tween for expand animation
	panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate width to expanded state
	panel_tween.tween_property(self, "custom_minimum_size:x", panel_width, animation_duration)
	
	# If we're in an HSplitContainer, animate the split_offset to show expanded panel
	var parent_node = get_parent()
	if parent_node is HSplitContainer:
		var target_offset = parent_node.size.x - panel_width
		panel_tween.parallel().tween_property(parent_node, "split_offset", int(target_offset), animation_duration)
	
	# Fade in content after width starts expanding
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
	"""Parse markdown headings and task lists from text editor content"""
	if not text_editor:
		return
	
	headings.clear()
	
	var lines = text_editor.text.split("\n")
	var current_heading_index = -1
	
	print("OutlinePanel: Parsing ", lines.size(), " lines")
	
	for i in range(lines.size()):
		var line = lines[i]
		
		# Check for heading first
		var heading_data = _parse_heading_line(line, i)
		if heading_data:
			heading_data["tasks"] = []  # Initialize tasks array
			headings.append(heading_data)
			current_heading_index = headings.size() - 1
			print("OutlinePanel: Found heading '", heading_data.text, "' at line ", i)
			continue
		
		# Check for task list item under current heading
		if current_heading_index >= 0:
			var task_data = _parse_task_line(line, i)
			if task_data:
				headings[current_heading_index]["tasks"].append(task_data)
				print("OutlinePanel: Added task to heading '", headings[current_heading_index].text, "', now has ", headings[current_heading_index]["tasks"].size(), " tasks")
	
	# Summary of headings with tasks
	print("OutlinePanel: Parsing complete. ", headings.size(), " headings found.")
	for heading in headings:
		var task_count = heading.get("tasks", []).size()
		if task_count > 0:
			print("OutlinePanel: Summary - '", heading.text, "' has ", task_count, " tasks")
	
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

func _parse_task_line(line: String, line_number: int) -> Dictionary:
	"""Parse a single line for markdown task list syntax - supports both formats:
	   - Standard markdown: '- [ ] Task' or '* [ ] Task' or '+ [ ] Task'
	   - Simple checkbox: '[ ] Task' (without leading dash)
	"""
	var stripped = line.strip_edges()
	
	# Skip empty lines
	if stripped.is_empty():
		return {}
	
	# Debug: Show what we're trying to parse (only lines with brackets)
	var has_bracket = stripped.find("[") != -1
	if has_bracket:
		print("OutlinePanel: Checking line for task: '", stripped, "'")
	
	# Try standard markdown task list first: - [ ] or * [ ] or + [ ]
	var result = _task_regex_standard.search(stripped)
	
	if result:
		print("OutlinePanel: Matched STANDARD format")
	else:
		# If standard format didn't match, try simple checkbox format: [ ] or [x]
		result = _task_regex_simple.search(stripped)
		if result:
			print("OutlinePanel: Matched SIMPLE format")
	
	if not result:
		if has_bracket:
			print("OutlinePanel: No match for line with brackets: '", stripped, "'")
		return {}
	
	var check_char = result.get_string(1)
	var is_checked = check_char.to_lower() == "x"
	var task_text = result.get_string(2).strip_edges()
	
	if task_text.is_empty():
		print("OutlinePanel: Task text is empty after extraction")
		return {}
	
	print("OutlinePanel: Found task '", task_text, "' checked=", is_checked, " at line ", line_number)
	
	return {
		"text": task_text,
		"line": line_number,
		"checked": is_checked
	}

func _update_heading_display() -> void:
	"""Update the heading buttons display"""
	# Clear existing heading items (VBoxContainers that contain buttons and task containers)
	for item in heading_items:
		if item and is_instance_valid(item):
			item.queue_free()
	heading_items.clear()
	heading_buttons.clear()
	task_containers.clear()
	
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
	
	# Debug: Print all headings and their task counts
	print("OutlinePanel: _update_heading_display - ", headings.size(), " headings")
	for heading in headings:
		var tasks = heading.get("tasks", [])
		print("OutlinePanel:   Heading '", heading.text, "' line=", heading.line, " tasks=", tasks.size(), " keys=", heading.keys())
	
	# Create buttons for each heading with optional task containers
	for heading in headings:
		var heading_item = _create_heading_item(heading)
		heading_container.add_child(heading_item)
		heading_items.append(heading_item)

func _create_heading_item(heading: Dictionary) -> VBoxContainer:
	"""Create a heading item with optional expandable task list"""
	var item_container = VBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var button = _create_heading_button(heading)
	item_container.add_child(button)
	heading_buttons.append(button)
	
	# If heading has tasks, create task container
	var tasks = heading.get("tasks", [])
	print("OutlinePanel: _create_heading_item for '", heading.text, "' - tasks.size() = ", tasks.size())
	
	if tasks.size() > 0:
		print("OutlinePanel: Creating task container for '", heading.text, "' with ", tasks.size(), " tasks")
		var task_wrapper = _create_task_container(heading, tasks)
		item_container.add_child(task_wrapper)
		task_containers[heading.line] = task_wrapper
	
	return item_container

func _create_heading_button(heading: Dictionary) -> Button:
	"""Create a styled button for a heading"""
	var button = Button.new()
	
	# Calculate indentation based on heading level
	var indent = "  ".repeat(heading.level - 1)
	var prefix = _get_heading_prefix(heading.level)
	
	# Add star indicator if heading has tasks
	var tasks = heading.get("tasks", [])
	var has_tasks = tasks.size() > 0
	var task_indicator = star_indicator if has_tasks else ""
	
	# Debug output
	if has_tasks:
		print("OutlinePanel: Adding star to heading '", heading.text, "' with ", tasks.size(), " tasks")
	
	button.text = indent + prefix + heading.text + task_indicator
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
	
	# Connect click handler - different behavior if heading has tasks
	if has_tasks:
		button.pressed.connect(_on_heading_with_tasks_pressed.bind(heading.line))
	else:
		button.pressed.connect(_on_heading_button_pressed.bind(heading.line))
	
	# Add tooltip
	var tooltip = "Go to line " + str(heading.line + 1)
	if has_tasks:
		tooltip += " (click to expand/collapse tasks)"
	button.tooltip_text = tooltip
	
	return button

func _create_task_container(heading: Dictionary, tasks: Array) -> Control:
	"""Create an expandable container for task items"""
	# Wrapper to clip content during animation
	var clip_container = Control.new()
	clip_container.name = "TaskClipContainer_" + str(heading.line)
	clip_container.clip_contents = true
	clip_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# VBox for task items
	var task_vbox = VBoxContainer.new()
	task_vbox.name = "TaskVBox"
	task_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_container.add_child(task_vbox)
	
	# Create task buttons
	for task in tasks:
		var task_button = _create_task_button(task, heading.level)
		task_vbox.add_child(task_button)
	
	# Calculate required height for all tasks
	var task_height = 24.0  # Approximate height per task
	var total_height = tasks.size() * task_height
	
	# Store height for animation
	clip_container.set_meta("full_height", total_height)
	clip_container.set_meta("heading_line", heading.line)
	
	# Start collapsed
	var is_expanded = expanded_headings.get(heading.line, false)
	if is_expanded:
		clip_container.custom_minimum_size.y = total_height
	else:
		clip_container.custom_minimum_size.y = 0
		task_vbox.modulate.a = 0.0
	
	return clip_container

func _create_task_button(task: Dictionary, heading_level: int) -> Button:
	"""Create a styled button for a task item"""
	var button = Button.new()
	
	# Indent based on heading level + task indent
	var indent = "    " + "  ".repeat(heading_level)
	
	# Checkbox indicator
	var checkbox = "☑ " if task.checked else "☐ "
	
	# Task text with strikethrough if checked
	var task_text = task.text
	if task.checked:
		# Use strikethrough unicode combining character approach
		task_text = _apply_strikethrough(task_text)
	
	button.text = indent + checkbox + task_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Smaller height for tasks
	button.custom_minimum_size.y = 24
	
	# Style based on checked state
	var color = task_color_checked if task.checked else task_color_unchecked
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.2))
	button.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	
	# Smaller font for tasks
	button.add_theme_font_size_override("font_size", 12)
	
	# Apply transparent stylebox
	var style = _create_button_stylebox(false)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", _create_button_stylebox(false))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(false))
	button.add_theme_stylebox_override("focus", _create_button_stylebox(false))
	
	# Connect click handler
	button.pressed.connect(_on_task_button_pressed.bind(task.line))
	
	# Tooltip
	button.tooltip_text = "Go to task on line " + str(task.line + 1)
	
	return button

func _apply_strikethrough(text: String) -> String:
	"""Apply a visual strikethrough effect to text using dashes"""
	# Simple approach: add strikethrough indicator
	return "~" + text + "~"

func _on_heading_with_tasks_pressed(line_number: int) -> void:
	"""Handle heading click when it has tasks - toggle task list expansion"""
	var is_expanded = expanded_headings.get(line_number, false)
	
	if is_expanded:
		_collapse_task_list(line_number)
	else:
		_expand_task_list(line_number)
	
	# Also navigate to the heading
	_navigate_to_line(line_number)

func _expand_task_list(heading_line: int) -> void:
	"""Expand a task list with smooth animation"""
	var container = task_containers.get(heading_line)
	if not container or not is_instance_valid(container):
		return
	
	expanded_headings[heading_line] = true
	
	var full_height = container.get_meta("full_height", 0.0)
	var task_vbox = container.get_node_or_null("TaskVBox")
	
	# Create tween animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate height expansion
	tween.tween_property(container, "custom_minimum_size:y", full_height, task_expand_duration)
	
	# Fade in content
	if task_vbox:
		tween.parallel().tween_property(task_vbox, "modulate:a", 1.0, task_expand_duration * 0.8)
	
	# Play expand sound
	_play_ui_sound("button_click")

func _collapse_task_list(heading_line: int) -> void:
	"""Collapse a task list with smooth animation"""
	var container = task_containers.get(heading_line)
	if not container or not is_instance_valid(container):
		return
	
	expanded_headings[heading_line] = false
	
	var task_vbox = container.get_node_or_null("TaskVBox")
	
	# Create tween animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade out content first
	if task_vbox:
		tween.tween_property(task_vbox, "modulate:a", 0.0, task_expand_duration * 0.5)
	
	# Then collapse height
	tween.tween_property(container, "custom_minimum_size:y", 0.0, task_expand_duration)
	
	# Play collapse sound
	_play_ui_sound("button_click")

func _on_task_button_pressed(line_number: int) -> void:
	"""Handle task button click - navigate to task line"""
	_navigate_to_line(line_number)
	task_clicked.emit(line_number, false)

func _navigate_to_line(line_number: int) -> void:
	"""Navigate the text editor to a specific line"""
	if text_editor:
		text_editor.set_caret_line(line_number)
		text_editor.set_caret_column(0)
		text_editor.center_viewport_to_caret()
		text_editor.grab_focus()

func _play_ui_sound(sound_name: String) -> void:
	"""Play a UI sound if audio manager is available"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

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
	_navigate_to_line(line_number)
	heading_clicked.emit(line_number)

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
