extends Control
class_name MainScene

# Juicy Editor - Main Scene Controller
# Manages the main UI and coordinates between components

# Preloads
const SettingsDialogScene = preload("res://scripts/ui/settings_dialog.gd")
const FindReplaceDialogScene = preload("res://scripts/ui/find_replace_dialog.gd")
const GotoLineDialogScene = preload("res://scripts/ui/goto_line_dialog.gd")

# Node references
@onready var text_editor: TextEdit = $VBoxContainer/MainArea/TextEditorContainer/TextEditor
@onready var background_panel: ColorRect = $VBoxContainer/MainArea/TextEditorContainer/BackgroundPanel
@onready var menu_bar: MenuBar = $VBoxContainer/MenuBar
@onready var file_menu: PopupMenu = $VBoxContainer/MenuBar/File
@onready var edit_menu: PopupMenu = $VBoxContainer/MenuBar/Edit
@onready var effects_menu: PopupMenu = $VBoxContainer/MenuBar/Effects
@onready var toolbar_buttons: HBoxContainer = $VBoxContainer/Toolbar
@onready var new_button: Button = $VBoxContainer/Toolbar/NewButton
@onready var open_button: Button = $VBoxContainer/Toolbar/OpenButton
@onready var save_button: Button = $VBoxContainer/Toolbar/SaveButton
@onready var undo_button: Button = $VBoxContainer/Toolbar/UndoButton
@onready var redo_button: Button = $VBoxContainer/Toolbar/RedoButton
@onready var line_label: Label = $VBoxContainer/StatusBar/LineLabel
@onready var column_label: Label = $VBoxContainer/StatusBar/ColumnLabel
@onready var filename_label: Label = $VBoxContainer/StatusBar/FilenameLabel
@onready var file_dialog: FileDialog = $FileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog

# Game controller instance
var game_controller: Node
var audio_manager: Node
var visual_effects_manager: Node
var animation_manager: Node

# Settings dialog
var settings_dialog: SettingsDialogScene
var find_replace_dialog: FindReplaceDialogScene
var goto_line_dialog: GotoLineDialogScene

# File state
var current_file_path: String = ""
var is_file_modified: bool = false

func _ready() -> void:
	print("Main scene initializing...")
	
	# Get audio manager
	audio_manager = get_node("/root/AudioManager")
	if audio_manager and audio_manager.has_method("load_audio_files"):
		audio_manager.load_audio_files()
		print("Audio system initialized: ", audio_manager.get_audio_info())
	
	# Get visual effects manager
	visual_effects_manager = get_node("/root/VisualEffectsManager")
	
	# Get animation manager
	animation_manager = get_node("/root/AnimationManager")
	if animation_manager:
		print("Animation system initialized: ", animation_manager.get_animation_info())
	
	# Create game controller
	var GameControllerScript = preload("res://scripts/controllers/game_controller.gd")
	game_controller = GameControllerScript.new()
	add_child(game_controller)
	
	# Setup node paths for game controller
	game_controller.text_editor_path = text_editor.get_path()
	game_controller.menu_bar_path = menu_bar.get_path()
	game_controller.status_bar_path = get_node("VBoxContainer/StatusBar").get_path()
	game_controller.file_dialog_path = file_dialog.get_path()
	
	# Initialize node references in game controller
	game_controller.initialize_node_references()
	
	_connect_signals()
	_setup_menus()
	_update_ui()
	_animate_ui_entrance()
	
	print("Juicy Editor ready!")

func _animate_ui_entrance() -> void:
	# Animate UI elements on startup
	if animation_manager:
		# Animate toolbar buttons
		var buttons = [new_button, open_button, save_button, undo_button, redo_button]
		for i in range(buttons.size()):
			var button = buttons[i]
			if button and animation_manager.has_method("animate_slide_in"):
				# Delay each button slightly for a cascade effect
				await get_tree().create_timer(i * 0.1).timeout
				animation_manager.animate_slide_in(button, Vector2.UP, 30.0)
		
		# Animate text editor with fade in
		if text_editor and animation_manager.has_method("animate_fade_in"):
			animation_manager.animate_fade_in(text_editor, 0.5)

func _connect_signals() -> void:
	# Connect toolbar buttons
	new_button.pressed.connect(_on_new_pressed)
	open_button.pressed.connect(_on_open_pressed)
	save_button.pressed.connect(_on_save_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	redo_button.pressed.connect(_on_redo_pressed)
	
	# Connect menu items
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	
	# Connect file dialogs
	file_dialog.file_selected.connect(_on_file_selected)
	save_file_dialog.file_selected.connect(_on_save_file_selected)
	
	# Connect text editor signals
	text_editor.text_changed.connect(_on_text_changed)
	text_editor.caret_changed.connect(_update_status_bar)
	if text_editor.has_signal("text_typed"):
		text_editor.text_typed.connect(_on_text_typed)
	
	# Connect game controller signals
	game_controller.file_opened.connect(_on_file_opened)
	game_controller.file_saved.connect(_on_file_saved)
	
	# Connect button hover effects for audio feedback
	_connect_button_audio_feedback()

func _setup_menus() -> void:
	# Clear existing Edit menu items from tscn
	edit_menu.clear()
	
	# Setup Edit menu items
	edit_menu.add_item("Find & Replace...", 0)
	edit_menu.add_separator()
	edit_menu.add_item("Go to Line...", 2)
	edit_menu.add_separator()
	edit_menu.add_item("Word Wrap", 4)
	edit_menu.set_item_as_checkable(4, true)
	edit_menu.add_separator()
	edit_menu.add_item("Zoom In", 6)
	edit_menu.add_item("Zoom Out", 7)
	edit_menu.add_item("Reset Zoom", 8)
	edit_menu.add_separator()
	edit_menu.add_item("Text Statistics", 10)
	edit_menu.id_pressed.connect(_on_edit_menu_selected)
	
	# Create Settings menu
	var settings_menu = PopupMenu.new()
	settings_menu.name = "Settings"
	settings_menu.add_item("Preferences...", 0)
	settings_menu.id_pressed.connect(_on_settings_menu_selected)
	
	# Setup Effects menu
	if effects_menu:
		effects_menu.id_pressed.connect(_on_effects_menu_selected)
	
	# Setup menu bar (menus already exist in scene, just set titles)
	menu_bar.set_menu_title(0, "File")
	menu_bar.set_menu_title(1, "Edit")
	menu_bar.set_menu_title(2, "Effects")
	
	# Add the settings menu
	menu_bar.add_child(settings_menu)
	menu_bar.set_menu_title(3, "Settings")
	
	# Setup file dialogs with filters
	_setup_file_dialogs()

func _setup_file_dialogs() -> void:
	# Setup file filters
	file_dialog.add_filter("*.txt", "Text Files")
	file_dialog.add_filter("*.md", "Markdown Files")
	file_dialog.add_filter("*.gd", "GDScript Files")
	file_dialog.add_filter("*.py", "Python Files")
	file_dialog.add_filter("*.js", "JavaScript Files")
	file_dialog.add_filter("*.html", "HTML Files")
	file_dialog.add_filter("*.css", "CSS Files")
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.add_filter("*", "All Files")
	
	save_file_dialog.add_filter("*.txt", "Text Files")
	save_file_dialog.add_filter("*.md", "Markdown Files")
	save_file_dialog.add_filter("*.gd", "GDScript Files")
	save_file_dialog.add_filter("*.py", "Python Files")
	save_file_dialog.add_filter("*.js", "JavaScript Files")
	save_file_dialog.add_filter("*.html", "HTML Files")
	save_file_dialog.add_filter("*.css", "CSS Files")
	save_file_dialog.add_filter("*.json", "JSON Files")
	save_file_dialog.add_filter("*", "All Files")

func _connect_button_audio_feedback() -> void:
	# Connect all buttons for audio and visual feedback
	var buttons = [new_button, open_button, save_button, undo_button, redo_button]
	
	for button in buttons:
		if button:
			button.pressed.connect(_on_button_pressed.bind(button))
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_exit.bind(button))

func _on_button_pressed(button: Button) -> void:
	# Play sound
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound("button_click")
	
	# Add visual effect
	if visual_effects_manager and visual_effects_manager.has_method("create_pulse_effect"):
		visual_effects_manager.create_pulse_effect(button, 0.2, 1.1)
	
	# Add animation
	if animation_manager and animation_manager.has_method("animate_elastic_bounce"):
		animation_manager.animate_elastic_bounce(button, 0.3)

func _on_button_hover(button: Button) -> void:
	# Play hover sound
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound("button_hover")
	
	# Add glow effect
	if visual_effects_manager and visual_effects_manager.has_method("create_glow_effect"):
		visual_effects_manager.create_glow_effect(button, Color.CYAN, 0.5)
	
	# Add hover animation
	if animation_manager and animation_manager.has_method("animate_bounce_in"):
		animation_manager.animate_bounce_in(button)

func _on_button_exit(button: Button) -> void:
	# Stop glow effect
	if visual_effects_manager and visual_effects_manager.has_method("stop_glow_effect"):
		visual_effects_manager.stop_glow_effect(button)
	
	# Return button to original scale
	if animation_manager and animation_manager.has_method("animate_button_exit"):
		animation_manager.animate_button_exit(button)

func _on_new_pressed() -> void:
	if is_file_modified:
		# TODO: Show save dialog
		pass
	
	if game_controller:
		game_controller.new_file()

func _on_open_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered_ratio(0.8)

func _on_save_pressed() -> void:
	if current_file_path == "":
		save_file_dialog.popup_centered_ratio(0.8)
	else:
		if game_controller:
			game_controller.save_file()

func _on_undo_pressed() -> void:
	if text_editor:
		text_editor.undo()

func _on_redo_pressed() -> void:
	if text_editor:
		text_editor.redo()

func _on_file_menu_pressed(id: int) -> void:
	match id:
		0: # New
			_on_new_pressed()
		1: # Open
			_on_open_pressed()
		2: # Save
			_on_save_pressed()
		3: # Save As
			save_file_dialog.popup_centered_ratio(0.8)

func _on_file_selected(path: String) -> void:
	if game_controller:
		game_controller.open_file(path)

func _on_save_file_selected(path: String) -> void:
	if game_controller:
		game_controller.save_file(path)

func _on_text_changed() -> void:
	is_file_modified = true
	_update_window_title()

func _on_text_typed(character: String) -> void:
	# This signal comes from JuicyTextEdit when a character is typed
	print("Character typed: ", character)

func _on_file_opened(file_path: String) -> void:
	current_file_path = file_path
	is_file_modified = false
	_update_ui()
	
	# Set syntax highlighting based on file extension
	if text_editor:
		text_editor.set_syntax_highlighting_for_file(file_path)

func _on_file_saved(file_path: String) -> void:
	current_file_path = file_path
	is_file_modified = false
	_update_ui()

func _update_ui() -> void:
	_update_window_title()
	_update_status_bar()

func _update_window_title() -> void:
	var title = "Juicy Editor"
	if current_file_path != "":
		var file_name = current_file_path.get_file()
		title = file_name
		if is_file_modified:
			title += "*"
		title += " - Juicy Editor"
	
	get_window().title = title

func _update_status_bar() -> void:
	if text_editor:
		var line = text_editor.get_caret_line() + 1
		var column = text_editor.get_caret_column() + 1
		
		line_label.text = "Line: " + str(line)
		column_label.text = "Column: " + str(column)
	
	var filename = "Untitled"
	if current_file_path != "":
		filename = current_file_path.get_file()
		if is_file_modified:
			filename += "*"
	
	filename_label.text = filename

func _input(event: InputEvent) -> void:
	# Handle keyboard shortcuts
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_N: # Ctrl+N - New file
					_on_new_pressed()
					get_viewport().set_input_as_handled()
				KEY_O: # Ctrl+O - Open file
					_on_open_pressed()
					get_viewport().set_input_as_handled()
				KEY_S: # Ctrl+S - Save file
					_on_save_pressed()
					get_viewport().set_input_as_handled()
				KEY_Z: # Ctrl+Z - Undo
					if not event.shift_pressed:
						_on_undo_pressed()
						get_viewport().set_input_as_handled()
				KEY_Y: # Ctrl+Y - Redo
					_on_redo_pressed()
					get_viewport().set_input_as_handled()
				KEY_F: # Ctrl+F - Find & Replace
					_open_find_replace_dialog()
					get_viewport().set_input_as_handled()
				KEY_G: # Ctrl+G - Go to Line
					_open_goto_line_dialog()
					get_viewport().set_input_as_handled()
				KEY_EQUAL: # Ctrl+= - Zoom In
					_zoom_in()
					get_viewport().set_input_as_handled()
				KEY_MINUS: # Ctrl+- - Zoom Out
					_zoom_out()
					get_viewport().set_input_as_handled()
				KEY_0: # Ctrl+0 - Reset Zoom
					_reset_zoom()
					get_viewport().set_input_as_handled()

func _on_settings_menu_selected(id: int) -> void:
	match id:
		0:  # Preferences
			_open_settings_dialog()

func _on_effects_menu_selected(id: int) -> void:
	match id:
		0:  # Visual Effects Settings
			_open_effects_settings_dialog()
		2:  # Enable Text Shadow
			_toggle_text_shadow()
		3:  # Enable Outline
			_toggle_outline()
		4:  # Enable Background Gradient
			_toggle_background_gradient()

func _on_edit_menu_selected(id: int) -> void:
	match id:
		0:  # Find & Replace
			_open_find_replace_dialog()
		2:  # Go to Line
			_open_goto_line_dialog()
		4:  # Word Wrap
			_toggle_word_wrap()
		6:  # Zoom In
			_zoom_in()
		7:  # Zoom Out
			_zoom_out()
		8:  # Reset Zoom
			_reset_zoom()
		10: # Text Statistics
			_show_text_statistics()

func _open_settings_dialog() -> void:
	if not settings_dialog:
		settings_dialog = SettingsDialogScene.new()
		add_child(settings_dialog)
		settings_dialog.settings_applied.connect(_on_settings_applied)
	
	settings_dialog.popup_centered_ratio(0.8)

func _on_settings_applied(new_settings: Dictionary) -> void:
	# Pass settings to game controller
	if game_controller:
		for key in new_settings:
			game_controller.set_setting(key, new_settings[key])
	
	print("Settings updated: ", new_settings)

func _open_find_replace_dialog() -> void:
	if not find_replace_dialog:
		find_replace_dialog = FindReplaceDialogScene.new()
		add_child(find_replace_dialog)
		find_replace_dialog.find_next_requested.connect(_on_find_next_requested)
		find_replace_dialog.find_previous_requested.connect(_on_find_previous_requested)
		find_replace_dialog.replace_requested.connect(_on_replace_requested)
		find_replace_dialog.replace_all_requested.connect(_on_replace_all_requested)
	
	find_replace_dialog.set_text_editor(text_editor)
	find_replace_dialog.popup_centered_ratio(0.6)
	find_replace_dialog.focus_find_field()

func _open_goto_line_dialog() -> void:
	if not goto_line_dialog:
		goto_line_dialog = GotoLineDialogScene.new()
		add_child(goto_line_dialog)
		goto_line_dialog.goto_line_requested.connect(_on_goto_line_requested)
	
	goto_line_dialog.popup_centered_for_editor(text_editor)

func _toggle_word_wrap() -> void:
	if text_editor:
		text_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY if text_editor.wrap_mode == TextEdit.LINE_WRAPPING_NONE else TextEdit.LINE_WRAPPING_NONE
		
		# Update menu checkmark
		var is_wrapped = text_editor.wrap_mode != TextEdit.LINE_WRAPPING_NONE
		edit_menu.set_item_checked(4, is_wrapped)
		
		# Update setting
		if game_controller:
			game_controller.set_setting("word_wrap", is_wrapped)

# Find & Replace handlers
func _on_find_next_requested(_search_text: String, _case_sensitive: bool, _whole_words: bool) -> void:
	# The find dialog handles highlighting, we just need to provide feedback
	pass

func _on_find_previous_requested(_search_text: String, _case_sensitive: bool, _whole_words: bool) -> void:
	# The find dialog handles highlighting, we just need to provide feedback
	pass

func _on_replace_requested(search_text: String, replace_text: String, case_sensitive: bool, _whole_words: bool) -> void:
	if not text_editor:
		return
	
	var selected_text = text_editor.get_selected_text()
	var search_match = search_text
	var selected_match = selected_text
	
	if not case_sensitive:
		search_match = search_match.to_lower()
		selected_match = selected_match.to_lower()
	
	# Only replace if the currently selected text matches the search text
	if selected_match == search_match:
		text_editor.delete_selection()
		text_editor.insert_text_at_caret(replace_text)

func _on_replace_all_requested(search_text: String, replace_text: String, case_sensitive: bool, whole_words: bool) -> void:
	if not text_editor:
		return
	
	var editor_text = text_editor.text
	var original_caret_line = text_editor.get_caret_line()
	var original_caret_column = text_editor.get_caret_column()
	
	# Perform case-insensitive search if needed
	if case_sensitive:
		editor_text = editor_text.replace(search_text, replace_text)
	else:
		# For case-insensitive replace, we need to be more careful
		var search_lower = search_text.to_lower()
		var result_text = ""
		var pos = 0
		
		while pos < editor_text.length():
			var remaining = editor_text.substr(pos)
			var remaining_lower = remaining.to_lower()
			var found_pos = remaining_lower.find(search_lower)
			
			if found_pos == -1:
				result_text += remaining
				break
			
			# Add text before match
			result_text += remaining.substr(0, found_pos)
			
			# Check for whole words if needed
			var should_replace = true
			if whole_words:
				# Check character before
				if pos + found_pos > 0:
					var char_before = editor_text[pos + found_pos - 1]
					if char_before.is_valid_identifier() or char_before.is_valid_int():
						should_replace = false
				
				# Check character after
				if pos + found_pos + search_text.length() < editor_text.length():
					var char_after = editor_text[pos + found_pos + search_text.length()]
					if char_after.is_valid_identifier() or char_after.is_valid_int():
						should_replace = false
			
			if should_replace:
				result_text += replace_text
				pos += found_pos + search_text.length()
			else:
				result_text += remaining.substr(found_pos, 1)
				pos += found_pos + 1
		
		editor_text = result_text
	
	text_editor.text = editor_text
	text_editor.set_caret_line(original_caret_line)
	text_editor.set_caret_column(original_caret_column)

func _on_goto_line_requested(line_number: int) -> void:
	if text_editor:
		# Convert to 0-based indexing
		var target_line = line_number - 1
		target_line = max(0, min(target_line, text_editor.get_line_count() - 1))
		
		text_editor.set_caret_line(target_line)
		text_editor.set_caret_column(0)
		text_editor.center_viewport_to_caret()
		text_editor.grab_focus()

# Zoom functionality
func _zoom_in() -> void:
	if text_editor:
		var theme_resource = text_editor.get_theme()
		if not theme_resource:
			theme_resource = Theme.new()
			text_editor.set_theme(theme_resource)
		
		var current_size = theme_resource.get_font_size("font_size", "TextEdit")
		if current_size == 0:
			current_size = 16  # Default size
		
		var new_size = min(current_size + 2, 72)  # Max size 72
		theme_resource.set_font_size("font_size", "TextEdit", new_size)
		
		if game_controller:
			game_controller.set_setting("font_size", new_size)

func _zoom_out() -> void:
	if text_editor:
		var theme_resource = text_editor.get_theme()
		if not theme_resource:
			theme_resource = Theme.new()
			text_editor.set_theme(theme_resource)
		
		var current_size = theme_resource.get_font_size("font_size", "TextEdit")
		if current_size == 0:
			current_size = 16  # Default size
		
		var new_size = max(current_size - 2, 8)  # Min size 8
		theme_resource.set_font_size("font_size", "TextEdit", new_size)
		
		if game_controller:
			game_controller.set_setting("font_size", new_size)

func _reset_zoom() -> void:
	if text_editor:
		var theme_resource = text_editor.get_theme()
		if not theme_resource:
			theme_resource = Theme.new()
			text_editor.set_theme(theme_resource)
		
		var default_size = 16
		theme_resource.set_font_size("font_size", "TextEdit", default_size)
		
		if game_controller:
			game_controller.set_setting("font_size", default_size)

# Text statistics
func get_text_statistics() -> Dictionary:
	if not text_editor:
		return {}
	
	var text = text_editor.text
	var stats = {
		"characters": text.length(),
		"characters_no_spaces": text.replace(" ", "").replace("\t", "").replace("\n", "").length(),
		"words": 0,
		"lines": text_editor.get_line_count(),
		"paragraphs": 0
	}
	
	# Count words
	var words = text.split(" ", false)
	for word in words:
		if word.strip_edges().length() > 0:
			stats.words += 1
	
	# Count paragraphs (separated by double newlines or at line breaks)
	var paragraphs = text.split("\n\n", false)
	stats.paragraphs = max(1, paragraphs.size())
	
	return stats

func _show_text_statistics() -> void:
	var stats = get_text_statistics()
	var message = "Text Statistics:\n\n"
	message += "Characters: " + str(stats.characters) + "\n"
	message += "Characters (no spaces): " + str(stats.characters_no_spaces) + "\n"
	message += "Words: " + str(stats.words) + "\n"
	message += "Lines: " + str(stats.lines) + "\n"
	message += "Paragraphs: " + str(stats.paragraphs)
	
	# Show statistics in a dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Text Statistics"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

# Effects menu methods
func _open_effects_settings_dialog() -> void:
	# Create and show effects settings dialog
	var effects_panel = preload("res://scenes/ui/effects_settings_panel.tscn").instantiate()
	add_child(effects_panel)
	
	# Center the dialog
	effects_panel.position = (get_viewport().size - effects_panel.size) / 2
	
	# Load current settings if visual effects manager exists
	if visual_effects_manager and effects_panel.has_method("load_settings_from_manager"):
		effects_panel.load_settings_from_manager()

func _toggle_text_shadow() -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		var current_enabled = effects_menu.is_item_checked(2)
		var new_enabled = not current_enabled
		effects_menu.set_item_checked(2, new_enabled)
		visual_effects_manager.enable_effect("text_shadow", new_enabled)
		
		# Apply to text editor
		if visual_effects_manager.has_method("apply_text_shadow"):
			visual_effects_manager.apply_text_shadow(text_editor, new_enabled)

func _toggle_outline() -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		var current_enabled = effects_menu.is_item_checked(3)
		var new_enabled = not current_enabled
		effects_menu.set_item_checked(3, new_enabled)
		visual_effects_manager.enable_effect("outline", new_enabled)
		
		# Apply to text editor
		if visual_effects_manager.has_method("apply_outline"):
			visual_effects_manager.apply_outline(text_editor, new_enabled)

func _toggle_background_gradient() -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		var current_enabled = effects_menu.is_item_checked(4)
		var new_enabled = not current_enabled
		effects_menu.set_item_checked(4, new_enabled)
		visual_effects_manager.enable_effect("gradient", new_enabled)
		
		# Apply to background panel
		if visual_effects_manager.has_method("apply_gradient_background"):
			visual_effects_manager.apply_gradient_background(background_panel, new_enabled)
