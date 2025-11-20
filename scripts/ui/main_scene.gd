extends Control
class_name MainScene

# Juicy Editor - Main Scene Controller
# Manages the main UI and coordinates between components

# Preloads
const SettingsDialogScene = preload("res://scripts/ui/settings_dialog.gd")
const FindReplaceDialogScene = preload("res://scripts/ui/find_replace_dialog.gd")
const GotoLineDialogScene = preload("res://scripts/ui/goto_line_dialog.gd")

# Node references
@onready var text_editor: TextEdit = $VBoxContainer/MainArea/TextEditorContainer/EditorHBox/TextEditorArea/TextEditor
@onready var background_panel: ColorRect = $VBoxContainer/MainArea/TextEditorContainer/EditorHBox/TextEditorArea/BackgroundPanel
@onready var line_numbers: Control = $VBoxContainer/MainArea/TextEditorContainer/EditorHBox/LineNumbers
@onready var main_area: HSplitContainer = $VBoxContainer/MainArea
@onready var menu_bar: MenuBar = $VBoxContainer/TopBar/MenuBar
@onready var file_menu: PopupMenu = $VBoxContainer/TopBar/MenuBar/File
@onready var edit_menu: PopupMenu = $VBoxContainer/TopBar/MenuBar/Edit
@onready var file_tab_container: Control = $VBoxContainer/FileTabContainer
@onready var toolbar_buttons: HBoxContainer = $VBoxContainer/TopBar/Toolbar
@onready var new_button: Button = $VBoxContainer/TopBar/Toolbar/NewButton
@onready var open_button: Button = $VBoxContainer/TopBar/Toolbar/OpenButton
@onready var save_button: Button = $VBoxContainer/TopBar/Toolbar/SaveButton
@onready var undo_button: Button = $VBoxContainer/TopBar/Toolbar/UndoButton
@onready var redo_button: Button = $VBoxContainer/TopBar/Toolbar/RedoButton
@onready var zoom_out_button: Button = $VBoxContainer/TopBar/Toolbar/ZoomOutButton
@onready var zoom_reset_button: Button = $VBoxContainer/TopBar/Toolbar/ZoomResetButton
@onready var zoom_in_button: Button = $VBoxContainer/TopBar/Toolbar/ZoomInButton
@onready var xp_toggle_button: Button = $VBoxContainer/TopBar/Toolbar/XPToggleButton
@onready var debug_boss_battle_button: Button = $VBoxContainer/TopBar/Toolbar/DebugBossBattleButton
@onready var line_label: Label = $VBoxContainer/StatusBar/LineLabel
@onready var column_label: Label = $VBoxContainer/StatusBar/ColumnLabel
@onready var filename_label: Label = $VBoxContainer/StatusBar/FilenameLabel
@onready var file_dialog: FileDialog = $FileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var juicy_lucy: Control = $JuicyLucy
@onready var xp_display_panel: Control = $XPDisplayPanel

# Game controller instance
var game_controller: Node
var audio_manager: Node
var visual_effects_manager: Node
var animation_manager: Node
var theme_manager: Node
var zoom_controller: Node

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
	
	# Initialize theme manager
	var ThemeManagerScript = preload("res://scripts/components/theme_manager.gd")
	theme_manager = ThemeManagerScript.new()
	theme_manager.name = "ThemeManager"
	add_child(theme_manager)
	
	# Load super juicy theme as default - use theme manager's validated themes
	var super_juicy_theme = theme_manager.get_theme_by_name("Super Juicy")
	if super_juicy_theme:
		theme_manager.set_theme(super_juicy_theme)
		print("Super Juicy theme loaded!")
	else:
		print("ERROR: Failed to find super juicy theme in theme manager!")
	
	# Position window on the side of the desktop (assuming 4000x2000 desktop)
	_position_window()
	
	# Create game controller
	var GameControllerScript = preload("res://scripts/controllers/game_controller.gd")
	game_controller = GameControllerScript.new()
	add_child(game_controller)
	
	# Setup node paths for game controller
	game_controller.text_editor_path = text_editor.get_path()
	game_controller.menu_bar_path = menu_bar.get_path()
	game_controller.status_bar_path = get_node("VBoxContainer/StatusBar").get_path()
	game_controller.file_dialog_path = file_dialog.get_path()
	game_controller.file_tab_container_path = file_tab_container.get_path()
	
	# Initialize node references in game controller
	game_controller.initialize_node_references()
	
	# Setup line numbers component
	_setup_line_numbers()
	
	# Setup zoom controller
	_setup_zoom_controller()
	
	# Setup Juicy Lucy
	_setup_lucy()
	
	_connect_signals()
	_setup_menus()
	_setup_theme_ui()
	_setup_xp_toggle()
	_setup_debug_buttons()
	_clean_up_scene_issues()
	_update_ui()
	_animate_ui_entrance()
	
	print("Juicy Editor ready!")

func _position_window() -> void:
	## Position the window on the side of the desktop
	## For a 4000x2000 desktop, position the 800x2000 window on the left side
	await get_tree().process_frame
	
	var window = get_window()
	if window:
		var screen_size = DisplayServer.screen_get_size()
		var window_size = window.size
		
		var x_position = 0
		var y_position = 0
		
		window.position = Vector2i(x_position, y_position)
		print("Window positioned at: ", window.position)
		print("Screen size: ", screen_size)
		print("Window size: ", window_size)

func _animate_ui_entrance():
	pass

func _setup_line_numbers() -> void:
	"""Setup the line numbers component"""
	print("DEBUG: Setting up line numbers...")
	print("DEBUG: line_numbers is: ", line_numbers)
	print("DEBUG: text_editor is: ", text_editor)
	
	if line_numbers and text_editor:
		# Connect the line numbers to the text editor
		line_numbers.setup_text_editor(text_editor)
		
		# Connect line number signals for additional effects
		if line_numbers.has_signal("line_number_animation_requested"):
			line_numbers.line_number_animation_requested.connect(_on_line_number_animation_requested)
		if line_numbers.has_signal("racing_light_effect_triggered"):
			line_numbers.racing_light_effect_triggered.connect(_on_racing_light_effect_triggered)
		
		print("Line numbers component setup complete")
	else:
		print("ERROR: Could not setup line numbers - missing components")
		print("  line_numbers: ", line_numbers)
		print("  text_editor: ", text_editor)

func _on_line_number_animation_requested(line_number: int) -> void:
	"""Handle line number animation requests"""
	# Could trigger additional visual effects here
	if visual_effects_manager and visual_effects_manager.has_method("trigger_line_highlight_effect"):
		visual_effects_manager.trigger_line_highlight_effect(line_number)

func _on_racing_light_effect_triggered() -> void:
	"""Handle racing light effect from line numbers"""
	# Could trigger additional audio/visual feedback
	if audio_manager and audio_manager.has_method("play_racing_light_sound"):
		audio_manager.play_racing_light_sound()

func _setup_zoom_controller() -> void:
	"""Setup the zoom controller component"""
	print("DEBUG: Setting up zoom controller...")
	
	# Create zoom controller instance
	var ZoomControllerScript = preload("res://scripts/components/zoom_controller.gd")
	zoom_controller = ZoomControllerScript.new()
	zoom_controller.name = "ZoomController"
	add_child(zoom_controller)
	
	# Setup with references to components
	if text_editor and line_numbers and main_area:
		zoom_controller.setup(text_editor, line_numbers, main_area)
		
		# Connect zoom changed signal to update the 100% button text
		zoom_controller.zoom_changed.connect(_on_zoom_changed)
		
		print("Zoom controller setup complete")
	else:
		print("ERROR: Could not setup zoom controller - missing components")
		print("  text_editor: ", text_editor)
		print("  line_numbers: ", line_numbers)
		print("  main_area: ", main_area)

func _setup_lucy() -> void:
	"""Setup Juicy Lucy assistant"""
	print("DEBUG: Setting up Juicy Lucy...")
	
	if juicy_lucy:
		print("Juicy Lucy initialized!")
	else:
		print("ERROR: Could not find JuicyLucy node")

func _setup_xp_toggle() -> void:
	"""Setup XP panel toggle button"""
	print("DEBUG: Setting up XP toggle button...")
	
	if xp_toggle_button and xp_display_panel:
		# Connect button to toggle panel visibility
		xp_toggle_button.pressed.connect(_on_xp_toggle_pressed)
		
		# Load saved visibility state from game controller
		if game_controller and "editor_settings" in game_controller:
			var saved_visible = game_controller.editor_settings.get("xp_panel_visible", true)
			xp_display_panel.visible = saved_visible
			_update_xp_toggle_button_text()
			print("XP panel visibility loaded: ", saved_visible)
		
		print("XP toggle button setup complete")
	else:
		print("ERROR: Could not setup XP toggle - missing components")
		print("  xp_toggle_button: ", xp_toggle_button)
		print("  xp_display_panel: ", xp_display_panel)

func _on_xp_toggle_pressed() -> void:
	"""Toggle XP panel visibility"""
	if xp_display_panel:
		xp_display_panel.visible = !xp_display_panel.visible
		_update_xp_toggle_button_text()
		
		# Save state to game controller
		if game_controller and game_controller.has_method("_save_settings"):
			game_controller.editor_settings["xp_panel_visible"] = xp_display_panel.visible
			game_controller._save_settings()
		
		print("XP panel visibility toggled to: ", xp_display_panel.visible)

func _update_xp_toggle_button_text() -> void:
	"""Update toggle button text based on panel visibility"""
	if xp_toggle_button and xp_display_panel:
		xp_toggle_button.text = "👁 XP" if xp_display_panel.visible else "👁 XP"

func _setup_debug_buttons() -> void:
	"""Setup debug buttons (temporary for testing)"""
	print("DEBUG: Setting up debug buttons...")
	
	if debug_boss_battle_button:
		debug_boss_battle_button.pressed.connect(_on_debug_boss_battle_pressed)
		print("Debug boss battle button connected")

func _on_debug_boss_battle_pressed() -> void:
	"""[DEBUG] Manually trigger a boss battle"""
	var xp_system = get_node_or_null("/root/XPSystem")
	if xp_system:
		var current_level = xp_system.current_level
		print("[DEBUG] Manually triggering boss battle at level ", current_level)
		# Trigger boss battle available signal
		if game_controller:
			game_controller._on_boss_battle_available(current_level)
		else:
			print("[DEBUG] ERROR: game_controller not found")
	else:
		print("[DEBUG] ERROR: XPSystem not found")

func _clean_up_scene_issues():
	print("Cleaning up scene issues that could interfere with themes")
	
	# Remove the problematic BackgroundPanel that was covering the text editor
	var bg_panel = get_node_or_null("VBoxContainer/MainArea/TextEditorContainer/EditorHBox/TextEditorArea/BackgroundPanel")
	if bg_panel:
		bg_panel.queue_free()
		print("Removed problematic BackgroundPanel")
	
	# Remove shader materials that might interfere with theming
	if text_editor and text_editor.material:
		text_editor.material = null
		print("Removed TextEditor shader material")
	
	print("Scene cleanup complete")

func _find_all_buttons(node: Node, buttons: Array):
	if node is Button:
		buttons.append(node)
	
	for child in node.get_children():
		_find_all_buttons(child, buttons)
	# Animate UI elements on startup
	if animation_manager:
		# Animate toolbar buttons
		var anim_buttons = [new_button, open_button, save_button, undo_button, redo_button]
		for i in range(anim_buttons.size()):
			var button = anim_buttons[i]
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
	zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	zoom_reset_button.pressed.connect(_on_zoom_reset_pressed)
	zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	
	# Connect menu items
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	
	# Connect file dialogs
	file_dialog.file_selected.connect(_on_file_selected)
	save_file_dialog.file_selected.connect(_on_save_file_selected)
	
	# Connect tab container signals
	if file_tab_container:
		if file_tab_container.has_signal("tab_changed_to"):
			file_tab_container.tab_changed_to.connect(_on_tab_changed)
	
	# Connect text editor signals
	text_editor.text_changed.connect(_on_text_changed)
	text_editor.caret_changed.connect(_update_status_bar)
	if text_editor.has_signal("text_typed"):
		text_editor.text_typed.connect(_on_text_typed)
	if text_editor.has_signal("text_deleted"):
		text_editor.text_deleted.connect(_on_text_deleted)
	
	# Connect game controller signals
	game_controller.file_opened.connect(_on_file_opened)
	game_controller.file_saved.connect(_on_file_saved)
	
	# Connect theme manager signals
	if theme_manager:
		theme_manager.theme_changed.connect(_on_theme_changed)
	
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
	settings_menu.add_item("Switch Theme...", 1)
	settings_menu.id_pressed.connect(_on_settings_menu_selected)
	
	# Setup menu bar (menus already exist in scene, just set titles)
	menu_bar.set_menu_title(0, "File")
	menu_bar.set_menu_title(1, "Edit")
	
	# Remove the original Effects menu if it exists (now deprecated, we use Settings instead)
	if menu_bar.get_menu_count() > 2:
		print("Removing deprecated Effects menu (menu count: ", menu_bar.get_menu_count(), ")")
		# Remove the third menu (index 2) which should be the old Effects menu
		var effects_popup = menu_bar.get_menu_popup(2)
		if effects_popup:
			menu_bar.remove_child(effects_popup)
			effects_popup.queue_free()
			print("Successfully removed deprecated Effects menu")
	
	# Add the settings menu
	menu_bar.add_child(settings_menu)
	menu_bar.set_menu_title(menu_bar.get_menu_count() - 1, "Settings")
	
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

func _setup_theme_ui() -> void:
	if not theme_manager:
		return
	
	# Register text editor with theme manager for syntax highlighting themes
	theme_manager.register_ui_element("text_editor", text_editor)
	
	# NOTE: MenuBar, PopupMenus, and Toolbar buttons are NOT registered with theme manager
	# They will always use the Balatro UI theme from the root Control node
	# This keeps the juicy button textures and consistent menu styling
	# regardless of which text editor theme is selected
	
	# Register status bar container and labels
	theme_manager.register_ui_element("status_bar", get_node("VBoxContainer/StatusBar"))
	theme_manager.register_ui_element("line_label", line_label)
	theme_manager.register_ui_element("column_label", column_label)
	theme_manager.register_ui_element("filename_label", filename_label)
	
	# Apply the current theme to all registered elements
	theme_manager.apply_current_theme()
	
	# Refresh line numbers synchronization after theme is applied
	if line_numbers and line_numbers.has_method("refresh_line_height_sync"):
		line_numbers.refresh_line_height_sync()
	
	print("Theme UI setup complete!")

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

func _on_zoom_out_pressed() -> void:
	if zoom_controller:
		zoom_controller.zoom_out()

func _on_zoom_reset_pressed() -> void:
	if zoom_controller:
		zoom_controller.reset_zoom()

func _on_zoom_in_pressed() -> void:
	if zoom_controller:
		zoom_controller.zoom_in()

func _on_zoom_changed(zoom_level: float) -> void:
	"""Update zoom reset button text to show current zoom percentage"""
	if zoom_reset_button:
		var zoom_percent = int(zoom_level * 100)
		zoom_reset_button.text = str(zoom_percent) + "%"

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

func _on_tab_changed(_tab_index: int) -> void:
	"""Handle tab change - update file information"""
	if file_tab_container and file_tab_container.has_method("get_current_file_data"):
		var file_data = file_tab_container.get_current_file_data()
		if file_data:
			current_file_path = file_data.file_path
			is_file_modified = file_data.is_modified
			_update_ui()
			
			# Set syntax highlighting for the new file
			if text_editor and file_data.file_path != "":
				text_editor.set_syntax_highlighting_for_file(file_data.file_path)
			
			# Force update line numbers for the new content
			if line_numbers and line_numbers.has_method("force_update"):
				line_numbers.force_update()

func _on_text_changed() -> void:
	is_file_modified = true
	_update_window_title()
	
	if juicy_lucy and juicy_lucy.has_method("on_text_changed"):
		juicy_lucy.on_text_changed(text_editor.text)

func _on_text_typed(character: String) -> void:
	# This signal comes from JuicyTextEdit when a character is typed
	print("Character typed: ", character)

func _on_text_deleted(_character: String) -> void:
	## Handle text deletion (backspace, delete, cut)
	## Play delete sound effect with pitch-down
	if audio_manager and audio_manager.has_method("play_delete_sound"):
		audio_manager.play_delete_sound()

func _on_file_opened(file_path: String) -> void:
	current_file_path = file_path
	is_file_modified = false
	_update_ui()
	
	# Set syntax highlighting based on file extension
	if text_editor:
		text_editor.set_syntax_highlighting_for_file(file_path)
	
	# Force update line numbers for the new file content
	if line_numbers and line_numbers.has_method("force_update"):
		print("🔄 Forcing line numbers update after file load")
		line_numbers.force_update()

func _on_file_saved(file_path: String) -> void:
	current_file_path = file_path
	is_file_modified = false
	_update_ui()
	
	if juicy_lucy and juicy_lucy.has_method("encourage"):
		juicy_lucy.encourage()
	
	# Update line numbers after save (in case of any formatting changes)
	if line_numbers and line_numbers.has_method("force_update"):
		line_numbers.force_update()

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
		
		if event.ctrl_pressed and event.alt_pressed:
			match event.keycode:
				KEY_8: # Ctrl+Alt+8 - Organize selected markdown lines
					_organize_markdown_selection()
					get_viewport().set_input_as_handled()
				KEY_9: # Ctrl+Alt+9 - Add [ ] to line beginning
					_add_checkbox_to_line()
					get_viewport().set_input_as_handled()
				KEY_0: # Ctrl+Alt+0 - Toggle [ ] to [X]
					_toggle_checkbox()
					get_viewport().set_input_as_handled()

func _on_settings_menu_selected(id: int) -> void:
	match id:
		0:  # Preferences
			_open_settings_dialog()
		1:  # Switch Theme
			_open_theme_switcher()

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
	# Pass settings to game controller using the comprehensive handler
	if game_controller and game_controller.has_method("_on_settings_applied"):
		game_controller._on_settings_applied(new_settings)
	else:
		# Fallback to individual setting method
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

func _open_theme_switcher() -> void:
	# Create and show theme switcher dialog
	var ThemeSwitcherScene = preload("res://scenes/ui/theme_switcher.tscn")
	var theme_switcher = ThemeSwitcherScene.instantiate()
	
	# Set the theme manager reference
	theme_switcher.theme_manager = theme_manager
	
	# Create a dialog to contain the theme switcher
	var dialog = AcceptDialog.new()
	dialog.title = "Theme Selection"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dialog.size = Vector2i(400, 300)
	dialog.add_child(theme_switcher)
	
	# Connect theme selection signal
	theme_switcher.theme_selected.connect(_on_theme_selected)
	
	# Show the dialog
	add_child(dialog)
	dialog.popup_centered()
	
	# Clean up when dialog closes
	dialog.close_requested.connect(func(): dialog.queue_free())

func _on_theme_selected(selected_theme: JuicyTheme) -> void:
	print("Theme selected: ", selected_theme.theme_name)
	if theme_manager:
		theme_manager.set_theme(selected_theme)

func _on_theme_changed(new_theme: JuicyTheme) -> void:
	print("Theme changed to: ", new_theme.theme_name if new_theme else "null")
	# Refresh syntax highlighting for the current file
	if text_editor and text_editor.has_method("refresh_syntax_highlighting"):
		text_editor.refresh_syntax_highlighting()
	
	# Refresh line numbers for theme change
	if line_numbers and line_numbers.has_method("refresh_for_theme_change"):
		print("🎨 Refreshing line numbers for theme change")
		line_numbers.refresh_for_theme_change()
	
	# Note: Theme manager will automatically apply theme to all registered UI elements

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
	if zoom_controller:
		zoom_controller.zoom_in()

func _zoom_out() -> void:
	if zoom_controller:
		zoom_controller.zoom_out()

func _reset_zoom() -> void:
	if zoom_controller:
		zoom_controller.reset_zoom()

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

# Markdown checklist functionality
func _add_checkbox_to_line() -> void:
	## Add unchecked checkbox [ ] to the beginning of the current line
	if not text_editor:
		return
	
	var current_line = text_editor.get_caret_line()
	var line_text = text_editor.get_line(current_line)
	
	# Don't add if checkbox already exists
	if line_text.strip_edges().begins_with("[ ]") or line_text.strip_edges().begins_with("[X]"):
		return
	
	# Add checkbox at the beginning of the line (preserving indentation)
	var leading_whitespace = ""
	for i in range(line_text.length()):
		if line_text[i] in [" ", "\t"]:
			leading_whitespace += line_text[i]
		else:
			break
	
	var new_line = leading_whitespace + "[ ] " + line_text.strip_edges()
	text_editor.set_line(current_line, new_line)
	
	# Move caret to end of line
	text_editor.set_caret_column(new_line.length())

func _toggle_checkbox() -> void:
	## Toggle checkbox from [ ] to [X] or [X] to [ ] on the current line
	if not text_editor:
		return
	
	var current_line = text_editor.get_caret_line()
	var line_text = text_editor.get_line(current_line)
	var stripped = line_text.strip_edges()
	
	# Check if line has a checkbox
	if stripped.begins_with("[ ]"):
		# Convert [ ] to [X]
		var new_line = line_text.replace("[ ]", "[X]")
		text_editor.set_line(current_line, new_line)
	elif stripped.begins_with("[X]"):
		# Convert [X] to [ ]
		var new_line = line_text.replace("[X]", "[ ]")
		text_editor.set_line(current_line, new_line)

func _organize_markdown_selection() -> void:
	## Organize selected markdown lines: no checkbox, then [ ], then [X]
	if not text_editor:
		return
	
	# Check if there's a selection
	if not text_editor.has_selection():
		return
	
	var selection_from_line = text_editor.get_selection_from_line()
	var selection_to_line = text_editor.get_selection_to_line()
	
	# Collect all lines in the selection
	var lines = []
	for line_num in range(selection_from_line, selection_to_line + 1):
		lines.append(text_editor.get_line(line_num))
	
	# Categorize lines into three groups
	var no_checkbox_lines = []
	var unchecked_lines = []
	var checked_lines = []
	
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("[X]"):
			checked_lines.append(line)
		elif stripped.begins_with("[ ]"):
			unchecked_lines.append(line)
		else:
			no_checkbox_lines.append(line)
	
	# Combine in order: no checkbox, unchecked, checked
	var organized_lines = []
	organized_lines.append_array(no_checkbox_lines)
	organized_lines.append_array(unchecked_lines)
	organized_lines.append_array(checked_lines)
	
	# Replace the selected lines with organized lines
	for i in range(organized_lines.size()):
		var line_num = selection_from_line + i
		text_editor.set_line(line_num, organized_lines[i])
	
	# Restore selection
	text_editor.select(selection_from_line, 0, selection_to_line, text_editor.get_line(selection_to_line).length())

# Effects menu methods
func _open_effects_settings_dialog() -> void:
	# Create and show effects settings dialog
	var effects_panel = preload("res://scenes/ui/effects_settings_panel.tscn").instantiate()
	add_child(effects_panel)
	
	# Center the dialog
	effects_panel.position = (Vector2(get_viewport().size) - effects_panel.size) / 2
	
	# Connect signals for real-time updates
	if effects_panel.has_signal("effect_setting_changed"):
		effects_panel.effect_setting_changed.connect(_on_effect_setting_changed)
	if effects_panel.has_signal("apply_settings"):
		effects_panel.apply_settings.connect(_on_effects_apply_settings)
	if effects_panel.has_signal("reset_settings"):
		effects_panel.reset_settings.connect(_on_effects_reset_settings)
	
	# Load current settings if visual effects manager exists
	if visual_effects_manager and effects_panel.has_method("load_settings_from_manager"):
		effects_panel.load_settings_from_manager()

func _on_effect_setting_changed(effect_name: String, property: String, value) -> void:
	"""Handle real-time effect setting changes"""
	if game_controller:
		# Apply the setting immediately for live preview
		var setting_key = "rich_" + effect_name + "_" + property
		if effect_name == "text_shadow":
			setting_key = "rich_text_shadows" if property == "enabled" else setting_key
		elif effect_name == "outline":
			setting_key = "rich_text_outlines" if property == "enabled" else setting_key
		elif effect_name == "gradient":
			setting_key = "rich_gradient_backgrounds" if property == "enabled" else setting_key
		
		game_controller.set_setting(setting_key, value)

func _on_effects_apply_settings() -> void:
	"""Handle effects apply button press"""
	print("Effects settings applied")

func _on_effects_reset_settings() -> void:
	"""Handle effects reset button press"""
	if game_controller:
		# Reset rich effects settings to defaults
		game_controller.set_setting("rich_text_shadows", true)
		game_controller.set_setting("rich_text_outlines", true)
		game_controller.set_setting("rich_gradient_backgrounds", false)
		game_controller.set_setting("rich_effects", true)
	print("Effects settings reset to defaults")

# Theme testing function for debugging
func test_cycle_themes() -> void:
	"""Cycle through all available themes for testing purposes"""
	if not theme_manager:
		print("No theme manager available")
		return
	
	var theme_names = ["Super Juicy", "Dark", "Light", "Juicy"]
	for theme_name in theme_names:
		var juicy_theme = theme_manager.get_theme_by_name(theme_name)
		if juicy_theme:
			theme_manager.set_theme(juicy_theme)
			print("Switched to theme: ", theme_name)
			await get_tree().create_timer(2.0).timeout  # Wait 2 seconds between theme changes

# Input handler for theme testing
func _unhandled_input(event: InputEvent) -> void:
	# Press F1 to cycle through themes for testing
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			test_cycle_themes()

# End of MainScene class
