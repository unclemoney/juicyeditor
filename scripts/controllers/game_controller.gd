extends Control
class_name GameController

# Juicy Editor - Main Game Controller
# Handles the overall application flow and coordinates between systems

signal file_opened(file_path: String)
signal file_saved(file_path: String)
signal settings_changed(settings: Dictionary)

@export var text_editor_path: NodePath
@export var menu_bar_path: NodePath
@export var status_bar_path: NodePath
@export var file_dialog_path: NodePath
@export var file_tab_container_path: NodePath

var text_editor: TextEdit
var menu_bar: Control
var status_bar: Control
var file_dialog: FileDialog
var file_tab_container: Control
var visual_effects_manager: Node
var animation_manager: Node

var current_file_path: String = ""
var is_file_modified: bool = false
var editor_settings: Dictionary = {}
var recent_files: Array[String] = []
var max_recent_files: int = 10
var processed_args: PackedStringArray = []  # Track which args we've processed
var check_interval: float = 0.5  # Check for new files every half second
var time_since_last_check: float = 0.0
var instance_lock_file: String = ""
var instance_command_file: String = ""
var is_primary_instance: bool = false

func _ready() -> void:
	print("Juicy Editor starting up...")
	
	# Check if another instance is running BEFORE initializing
	if not _try_become_primary_instance():
		# Another instance is running - send files to it and quit
		print("Another instance detected, sending files and exiting...")
		_send_files_to_primary_instance()
		get_tree().quit()
		return
	
	print("This is the primary instance")
	_initialize_systems()
	_connect_signals()
	_load_settings()
	
	# Process command line arguments after everything is set up
	call_deferred("_process_command_line_arguments")
	
	# Ensure at least one tab exists after command line processing
	call_deferred("_ensure_initial_tab")

func _process(delta: float) -> void:
	"""Check periodically for new files via command file"""
	if not is_primary_instance:
		return
	
	time_since_last_check += delta
	
	if time_since_last_check >= check_interval:
		time_since_last_check = 0.0
		_check_command_file()

func initialize_node_references() -> void:
	# Initialize node references from paths
	text_editor = get_node_or_null(text_editor_path) if text_editor_path != NodePath() else null
	menu_bar = get_node_or_null(menu_bar_path) if menu_bar_path != NodePath() else null
	status_bar = get_node_or_null(status_bar_path) if status_bar_path != NodePath() else null
	file_dialog = get_node_or_null(file_dialog_path) if file_dialog_path != NodePath() else null
	file_tab_container = get_node_or_null(file_tab_container_path) if file_tab_container_path != NodePath() else null
	
	# Get visual effects manager from main scene
	visual_effects_manager = get_node_or_null("/root/Main/VisualEffectsManager")
	
	# Get animation manager (if it exists)
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	
	print("Node references initialized:")
	print("  text_editor: ", text_editor)
	print("  menu_bar: ", menu_bar)
	print("  status_bar: ", status_bar)
	print("  file_dialog: ", file_dialog)
	print("  file_tab_container: ", file_tab_container)
	print("  visual_effects_manager: ", visual_effects_manager)
	print("  animation_manager: ", animation_manager)
	
	# Setup tab container with text editor reference
	if file_tab_container and text_editor and file_tab_container.has_method("setup_text_editor"):
		file_tab_container.setup_text_editor(text_editor)
	
	# Connect tab container signals
	_connect_tab_container_signals()
	
	# Connect signals after node references are set
	_connect_text_editor_signals()

func _initialize_systems() -> void:
	# Initialize default settings first
	editor_settings = {
		# Text Editor Settings
		"font_size": 16,
		"theme": "dark",
		"line_numbers": true,
		"word_wrap": false,
		"syntax_highlighting": true,
		
		# Audio Settings
		"master_volume": 0.8,
		"ui_sounds": true,
		"typing_sounds": true,
		"sound_volume": 0.6,
		
		# Visual Effects Settings (DEPRECATED - RichTextLabel overlay system disabled)
		"visual_effects": false,
		"glow_effects": false,
		"pulse_effects": false,
		"effect_intensity": 1.0,
		
		# Rich Text Effects (DEPRECATED - DISABLED)
		"rich_effects": false,
		"rich_text_shadows": false,
		"rich_text_outlines": false,
		"rich_gradient_backgrounds": false,
		"rich_effects_performance_mode": true,
		"rich_syntax_highlighting": true,
		
		# New Typing Effects Settings (Node-based system)
		"enable_typing_effects": true,
		"enable_deletion_effects": true,
		"enable_newline_effects": true,
		"enable_flying_letters": true,
		"typing_effects_max_count": 50,
		
		# Animation Settings
		"animations": true,
		"typing_animations": true,
		"flying_letters": true,
		"deletion_explosions": true,
		"sparkle_effects": true,
		"cursor_animations": true,
		"button_animations": true,
		"animation_speed": 1.0,
		
		# Legacy settings (for compatibility)
		"audio_enabled": true,
		"audio_volume": 0.7,
		"visual_effects_enabled": true,
		
		# File management
		"recent_files": []
	}
	
	# Setup visual effects after node initialization
	call_deferred("_setup_visual_effects")

func _setup_visual_effects() -> void:
	if visual_effects_manager:
		# Connect to effects updated signal
		if visual_effects_manager.has_signal("effects_updated"):
			visual_effects_manager.effects_updated.connect(_on_effects_updated)
		print("Visual effects manager connected")
	else:
		print("Visual effects manager not found")

func _on_effects_updated() -> void:
	# Refresh effects when settings change
	print("Visual effects updated")

func _connect_text_editor_signals() -> void:
	# Connect text editor signals (called after node references are set)
	if text_editor:
		text_editor.text_changed.connect(_on_text_changed)
		text_editor.caret_changed.connect(_on_caret_changed)
		
		# Apply initial settings to text editor
		call_deferred("_apply_rich_effects_settings")
		
		print("Text editor signals connected and settings applied")

func _connect_tab_container_signals() -> void:
	# Connect file tab container signals
	if file_tab_container:
		if file_tab_container.has_signal("tab_changed_to"):
			file_tab_container.tab_changed_to.connect(_on_tab_changed)
		print("Tab container signals connected")

func _connect_signals() -> void:
	# Connect UI signals when nodes are available
	pass

func _load_settings() -> void:
	# Load settings from file or use defaults
	var default_rich_effects = true  # Our intended default
	print("DEBUG: Loading settings, default rich_effects=", default_rich_effects)
	
	var config_file = FileAccess.open("user://juicy_editor_settings.cfg", FileAccess.READ)
	if config_file:
		var json_string = config_file.get_as_text()
		config_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var saved_settings = json.data
			if typeof(saved_settings) == TYPE_DICTIONARY:
				print("DEBUG: Loaded saved settings, rich_effects=", saved_settings.get("rich_effects", "NOT_FOUND"))
				
				# Merge saved settings, but FORCE rich_effects to true
				for key in saved_settings:
					if key in editor_settings:
						# Skip rich_effects from saved settings - always use true
						if key != "rich_effects":
							editor_settings[key] = saved_settings[key]
				
				# FORCE rich effects to be enabled regardless of saved settings
				editor_settings["rich_effects"] = true
				print("DEBUG: FORCED rich_effects=true (overriding saved settings)")
	else:
		print("DEBUG: No saved settings file, using all defaults")
	
	print("DEBUG: Final rich_effects setting: ", editor_settings.get("rich_effects"))
	
	# Load recent files
	if "recent_files" in editor_settings:
		var loaded_files = editor_settings.recent_files
		if loaded_files is Array:
			recent_files.clear()
			for file_path in loaded_files:
				if file_path is String:
					recent_files.append(file_path)

func _save_settings() -> void:
	# Update recent files in settings
	editor_settings.recent_files = recent_files
	
	var config_file = FileAccess.open("user://juicy_editor_settings.cfg", FileAccess.WRITE)
	if config_file:
		var json_string = JSON.stringify(editor_settings)
		config_file.store_string(json_string)
		config_file.close()

func _on_text_changed() -> void:
	is_file_modified = true
	
	# Update current tab as modified
	if file_tab_container and file_tab_container.has_method("set_current_file_modified"):
		file_tab_container.set_current_file_modified(true)
	
	_update_window_title()

func _on_caret_changed() -> void:
	# Update status bar with cursor position
	if text_editor and status_bar:
		var _line = text_editor.get_caret_line() + 1
		var _column = text_editor.get_caret_column() + 1
		# Status bar update will be implemented when status bar exists

func _on_tab_changed(_tab_index: int) -> void:
	# Handle tab change - update current file path and window title
	if file_tab_container and file_tab_container.has_method("get_current_file_data"):
		var file_data = file_tab_container.get_current_file_data()
		if file_data:
			current_file_path = file_data.file_path
			is_file_modified = file_data.is_modified
			_update_window_title()
			
			# Emit file opened signal if this is a valid file
			if current_file_path != "":
				file_opened.emit(current_file_path)

func _update_window_title() -> void:
	var title = "Juicy Editor"
	if current_file_path != "":
		var file_name = current_file_path.get_file()
		title = file_name
		if is_file_modified:
			title += "*"
		title += " - Juicy Editor"
	
	# Set window title (will need to be implemented when main scene is created)
	get_window().title = title

func open_file(file_path: String) -> void:
	# Check if file is already open in a tab
	if file_tab_container and file_tab_container.has_method("switch_to_file"):
		if file_tab_container.switch_to_file(file_path):
			print("File already open, switched to tab: ", file_path)
			return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var error = file.get_error()
		file.close()
		
		if error != OK:
			print("Error reading file: ", file_path, " Error code: ", error)
			return
		
		# Add new tab for this file
		if file_tab_container and file_tab_container.has_method("add_new_tab"):
			var tab_index = file_tab_container.add_new_tab(file_path, content)
			print("Added new tab for file: ", file_path, " at index: ", tab_index)
		elif text_editor:
			# Fallback if no tab container
			text_editor.text = content
		
		# Reset text editor scale when loading new content
		if animation_manager and animation_manager.has_method("reset_control_scale"):
			animation_manager.reset_control_scale(text_editor)
		
		current_file_path = file_path
		is_file_modified = false
		_update_window_title()
		_add_to_recent_files(file_path)
		file_opened.emit(file_path)
		
		# Add visual feedback for successful file open
		if visual_effects_manager and text_editor and visual_effects_manager.has_method("create_glow_effect"):
			visual_effects_manager.create_glow_effect(text_editor, Color.GREEN, 1.0)
		
		print("File opened: ", file_path)
	else:
		var error = FileAccess.get_open_error()
		print("Error: Could not open file: ", file_path, " Error code: ", error)

func save_file(file_path: String = "") -> bool:
	var path_to_save = file_path
	if path_to_save == "":
		# Get current file path from tab container
		if file_tab_container and file_tab_container.has_method("get_current_file_data"):
			var file_data = file_tab_container.get_current_file_data()
			if file_data:
				path_to_save = file_data.file_path
	
	if path_to_save == "":
		print("Error: No file path specified for saving")
		return false
	
	if not text_editor:
		print("Error: No text editor available")
		return false
	
	var file = FileAccess.open(path_to_save, FileAccess.WRITE)
	if file:
		file.store_string(text_editor.text)
		var error = file.get_error()
		file.close()
		
		if error != OK:
			print("Error writing file: ", path_to_save, " Error code: ", error)
			return false
		
		# Update tab container with saved file info
		if file_tab_container:
			if file_tab_container.has_method("set_current_file_path"):
				file_tab_container.set_current_file_path(path_to_save)
			if file_tab_container.has_method("set_current_file_modified"):
				file_tab_container.set_current_file_modified(false)
		
		current_file_path = path_to_save
		is_file_modified = false
		_update_window_title()
		_add_to_recent_files(path_to_save)
		file_saved.emit(path_to_save)
		
		# Add visual feedback for successful file save
		if visual_effects_manager and text_editor and visual_effects_manager.has_method("create_pulse_effect"):
			visual_effects_manager.create_pulse_effect(text_editor, 0.3, 1.05)
		
		print("File saved: ", path_to_save)
		return true
	else:
		var error = FileAccess.get_open_error()
		print("Error: Could not save file: ", path_to_save, " Error code: ", error)
		return false

func new_file() -> void:
	# Create new tab for untitled file
	if file_tab_container and file_tab_container.has_method("add_new_tab"):
		var tab_index = file_tab_container.add_new_tab("", "")
		print("Created new untitled tab at index: ", tab_index)
	elif text_editor:
		# Fallback if no tab container
		text_editor.text = ""
	
	# Reset text editor scale when creating new file
	if animation_manager and animation_manager.has_method("reset_control_scale"):
		animation_manager.reset_control_scale(text_editor)
	
	current_file_path = ""
	is_file_modified = false
	_update_window_title()
	print("New file created")

func get_setting(key: String) -> Variant:
	return editor_settings.get(key, null)

func set_setting(key: String, value: Variant) -> void:
	editor_settings[key] = value
	
	# Apply rich effects settings immediately
	_apply_rich_effects_settings()
	
	settings_changed.emit(editor_settings)
	_save_settings()

func _apply_rich_effects_settings() -> void:
	"""Apply rich effects settings to the text editor"""
	print("DEBUG: _apply_rich_effects_settings called")
	print("DEBUG: text_editor exists: ", text_editor != null)
	print("DEBUG: text_editor has apply_juicy_effects: ", text_editor != null and text_editor.has_method("apply_juicy_effects"))
	
	if not text_editor or not text_editor.has_method("apply_juicy_effects"):
		print("DEBUG: Skipping rich effects - no text editor or missing method")
		return
	
	var effects_config = {
		"typing_animations": editor_settings.get("typing_animations", true),
		"typing_sounds": editor_settings.get("typing_sounds", true),
		"line_numbers": editor_settings.get("line_numbers", true),
		"rich_effects": editor_settings.get("rich_effects", true),  # Changed default to true
		"text_shadows": editor_settings.get("rich_text_shadows", true),
		"text_outlines": editor_settings.get("rich_text_outlines", true),
		"gradient_backgrounds": editor_settings.get("rich_gradient_backgrounds", false)
	}
	
	print("DEBUG: Rich effects config: ", effects_config)
	print("DEBUG: Current editor_settings rich_effects: ", editor_settings.get("rich_effects", "NOT_FOUND"))
	
	text_editor.apply_juicy_effects(effects_config)
	
	# Set individual rich effect properties if the text editor supports it
	if text_editor.has_method("set_rich_effect_property"):
		text_editor.set_rich_effect_property("shadows", editor_settings.get("rich_text_shadows", true))
		text_editor.set_rich_effect_property("outlines", editor_settings.get("rich_text_outlines", true))
		text_editor.set_rich_effect_property("gradients", editor_settings.get("rich_gradient_backgrounds", false))
	
	# Toggle rich effects on/off
	if text_editor.has_method("toggle_rich_effects"):
		var rich_enabled = editor_settings.get("rich_effects", true)  # Changed default to true
		print("DEBUG: Calling toggle_rich_effects with: ", rich_enabled)
		text_editor.toggle_rich_effects(rich_enabled)

func toggle_rich_effects(enabled: bool) -> void:
	"""Public method to toggle rich effects"""
	set_setting("rich_effects", enabled)

func set_rich_effect_setting(effect_name: String, enabled: bool) -> void:
	"""Set individual rich effect settings"""
	match effect_name:
		"shadows":
			set_setting("rich_text_shadows", enabled)
		"outlines":
			set_setting("rich_text_outlines", enabled)
		"gradients":
			set_setting("rich_gradient_backgrounds", enabled)
		"performance_mode":
			set_setting("rich_effects_performance_mode", enabled)
		"syntax_highlighting":
			set_setting("rich_syntax_highlighting", enabled)
		_:
			print("Unknown rich effect setting: ", effect_name)
	_save_settings()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_file_modified:
			# TODO: Show save dialog before closing
			pass
		_save_settings()
		
		# Clean up lock file when exiting
		if is_primary_instance and instance_lock_file != "":
			if FileAccess.file_exists(instance_lock_file):
				DirAccess.remove_absolute(instance_lock_file)
				print("Removed lock file on exit")
		
		get_tree().quit()

func _add_to_recent_files(file_path: String) -> void:
	# Remove if already exists
	if file_path in recent_files:
		recent_files.erase(file_path)
	
	# Add to front
	recent_files.push_front(file_path)
	
	# Limit to max recent files
	if recent_files.size() > max_recent_files:
		recent_files.resize(max_recent_files)

func get_recent_files() -> Array[String]:
	return recent_files

func clear_recent_files() -> void:
	recent_files.clear()
	_save_settings()

func _on_settings_applied(new_settings: Dictionary) -> void:
	"""Handle settings being applied from the settings dialog"""
	print("Settings applied from dialog: ", new_settings)
	
	# Update our editor_settings with the new values
	for key in new_settings:
		editor_settings[key] = new_settings[key]
	
	# Apply the settings to the appropriate managers and components
	_apply_settings_to_components(new_settings)
	
	# Save the updated settings
	_save_settings()
	
	# Emit our settings changed signal
	settings_changed.emit(editor_settings)

func _apply_settings_to_components(settings: Dictionary) -> void:
	"""Apply settings to all relevant components"""
	# Apply to text editor
	if text_editor:
		if "font_size" in settings:
			text_editor.add_theme_font_size_override("font_size", int(settings.font_size))
		# Note: Line numbers and word wrap settings will be handled by the text editor component directly
	
	# Apply to audio manager
	if AudioManager:
		if "master_volume" in settings:
			AudioManager.set_master_volume(settings.master_volume)
		if "ui_sounds" in settings:
			AudioManager.set_ui_sounds_enabled(settings.ui_sounds)
		if "typing_sounds" in settings:
			AudioManager.set_typing_sounds_enabled(settings.typing_sounds)
		if "sound_volume" in settings:
			AudioManager.set_sound_volume(settings.sound_volume)
	
	# Apply to animation manager
	if AnimationManager:
		if "animations" in settings:
			AnimationManager.enable_transition_animations = settings.animations
		if "animation_speed" in settings:
			AnimationManager.animation_speed_multiplier = settings.animation_speed
	
	# Apply to typing effects manager
	var typing_effects_mgr = get_node("/root/TypingEffectsManager") if has_node("/root/TypingEffectsManager") else null
	if typing_effects_mgr:
		if "typing_animations" in settings:
			typing_effects_mgr.set_typing_effects_enabled(settings.typing_animations)
		if "flying_letters" in settings:
			typing_effects_mgr.set_flying_letters_enabled(settings.flying_letters)
		if "deletion_explosions" in settings:
			typing_effects_mgr.set_deletion_explosions_enabled(settings.deletion_explosions)
		if "sparkle_effects" in settings:
			typing_effects_mgr.set_sparkle_effects_enabled(settings.sparkle_effects)
		if "effect_intensity" in settings:
			typing_effects_mgr.set_effect_intensity(settings.effect_intensity)

func is_file_writable(file_path: String) -> bool:
	# Check if we can write to the file location
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.close()
		return true
	return false

func get_file_info(file_path: String) -> Dictionary:
	var file_info = {}
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			file_info["size"] = file.get_length()
			file_info["exists"] = true
			file.close()
		else:
			file_info["exists"] = false
	else:
		file_info["exists"] = false
	
	file_info["extension"] = file_path.get_extension()
	file_info["basename"] = file_path.get_file()
	
	return file_info

func _process_command_line_arguments() -> void:
	"""Process command line arguments to open files passed to the application"""
	var args = OS.get_cmdline_args()
	
	# Store processed args to detect new ones in single instance mode
	if processed_args.is_empty():
		processed_args = args
	
	print("DEBUG: Command line arguments: ", args)
	print("DEBUG: Executable path: ", OS.get_executable_path())
	print("DEBUG: Working directory: ", OS.get_environment("PWD"))
	
	# Filter out Godot-specific arguments and find file paths
	var files_to_open: Array[String] = []
	
	for arg in args:
		# Skip Godot engine arguments
		if arg.begins_with("--") or arg.begins_with("-"):
			print("DEBUG: Skipping engine argument: ", arg)
			continue
		
		# Skip the executable path (first argument is usually the executable)
		if arg.ends_with(".exe") or arg.ends_with("juicyeditor"):
			print("DEBUG: Skipping executable path: ", arg)
			continue
		
		# Check if the argument is a valid file path and get absolute path
		var absolute_path = _get_absolute_file_path(arg)
		if absolute_path != "":
			files_to_open.append(absolute_path)
			print("DEBUG: Found file argument: ", absolute_path)
	
	# Open all the files found in command line arguments
	if files_to_open.size() > 0:
		print("Opening ", files_to_open.size(), " file(s) from command line...")
		
		# Open each file in a new tab
		for file_path in files_to_open:
			print("DEBUG: Opening file: ", file_path)
			open_file(file_path)
	else:
		print("No valid file arguments found in command line")

func _get_absolute_file_path(arg: String) -> String:
	"""Convert argument to absolute file path if it's a valid file, return empty string if not"""
	var file_path = arg
	
	# If already absolute, check if it exists
	if file_path.is_absolute_path():
		if FileAccess.file_exists(file_path):
			return file_path
		else:
			return ""
	
	# Try relative to working directory first
	var working_dir = OS.get_environment("PWD") if OS.get_environment("PWD") != "" else OS.get_executable_path().get_base_dir()
	var absolute_path = working_dir.path_join(arg)
	
	if FileAccess.file_exists(absolute_path):
		return absolute_path
	
	# Try relative to executable directory
	absolute_path = OS.get_executable_path().get_base_dir().path_join(arg)
	if FileAccess.file_exists(absolute_path):
		return absolute_path
	
	# File not found
	print("DEBUG: File does not exist: ", arg)
	return ""

func _is_valid_file_argument(arg: String) -> bool:
	"""Check if a command line argument is a valid file to open"""
	# This method is now replaced by _get_absolute_file_path
	return _get_absolute_file_path(arg) != ""

func _clear_default_empty_tab() -> void:
	"""Clear the default empty tab if it exists and is truly empty"""
	if not file_tab_container or not file_tab_container.has_method("get_current_file_data"):
		return
	
	var file_data = file_tab_container.get_current_file_data()
	if file_data and file_data.file_path == "" and file_data.content == "" and not file_data.is_modified:
		# This is the default empty tab, we can close it
		if file_tab_container.has_method("close_tab"):
			var current_tab = file_tab_container.current_tab_index
			file_tab_container.close_tab(current_tab)
			print("DEBUG: Cleared default empty tab")

func _ensure_initial_tab() -> void:
	"""Ensure at least one tab exists after startup - only if no files were opened"""
	if file_tab_container and file_tab_container.has_method("ensure_tab_exists"):
		file_tab_container.ensure_tab_exists()
		print("DEBUG: Ensured initial tab exists")

func _check_for_new_command_line_files() -> void:
	"""Check if new command line arguments have been added (single instance mode)"""
	var current_args = OS.get_cmdline_args()
	
	# Check if args have changed (new files passed from second instance)
	if current_args.size() > processed_args.size():
		print("DEBUG: New command line arguments detected!")
		
		# Find the new arguments
		var new_files: Array[String] = []
		for arg in current_args:
			if arg not in processed_args:
				# Skip Godot engine arguments
				if arg.begins_with("--") or arg.begins_with("-"):
					continue
				
				# Skip the executable path
				if arg.ends_with(".exe") or arg.ends_with("juicyeditor"):
					continue
				
				# Check if it's a valid file
				var absolute_path = _get_absolute_file_path(arg)
				if absolute_path != "":
					new_files.append(absolute_path)
					print("DEBUG: New file to open: ", absolute_path)
		
		# Update processed args
		processed_args = current_args
		
		# Open the new files
		for file_path in new_files:
			open_file(file_path)
		
		# Bring window to front
		if new_files.size() > 0:
			get_window().grab_focus()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_move_to_foreground()

## IPC Methods for Single Instance Support

func _try_become_primary_instance() -> bool:
	"""Try to become the primary instance. Returns true if successful, false if another instance exists"""
	# Use user:// directory for lock files
	instance_lock_file = "user://juicy_editor.lock"
	instance_command_file = "user://juicy_editor_commands.txt"
	
	# Check if lock file exists
	if FileAccess.file_exists(instance_lock_file):
		# Check if the process is still alive by trying to read it
		var lock_read = FileAccess.open(instance_lock_file, FileAccess.READ)
		if lock_read:
			var pid = lock_read.get_as_text().strip_edges()
			lock_read.close()
			
			# If lock file exists, assume another instance is running
			# (In a production app, you'd verify the PID is still running)
			print("Lock file exists with PID: ", pid)
			is_primary_instance = false
			return false
	
	# Create lock file with our PID
	var lock_write = FileAccess.open(instance_lock_file, FileAccess.WRITE)
	if lock_write:
		lock_write.store_string(str(OS.get_process_id()))
		lock_write.close()
		is_primary_instance = true
		print("Created lock file, we are primary instance")
		
		# Clear any old command file
		if FileAccess.file_exists(instance_command_file):
			DirAccess.remove_absolute(instance_command_file)
		
		return true
	
	# If we can't create lock file, assume we're primary anyway
	is_primary_instance = true
	return true
	return true

func _send_files_to_primary_instance() -> void:
	"""Send our command line files to the primary instance via command file"""
	var args = OS.get_cmdline_args()
	var files_to_send: Array[String] = []
	
	# Extract file arguments
	for arg in args:
		if arg.begins_with("--") or arg.begins_with("-"):
			continue
		if arg.ends_with(".exe") or arg.ends_with("juicyeditor"):
			continue
		
		var absolute_path = _get_absolute_file_path(arg)
		if absolute_path != "":
			files_to_send.append(absolute_path)
	
	# Write files to command file
	if files_to_send.size() > 0:
		var cmd_file = FileAccess.open(instance_command_file, FileAccess.WRITE)
		if cmd_file:
			for file_path in files_to_send:
				cmd_file.store_line(file_path)
			cmd_file.close()
			print("Sent ", files_to_send.size(), " files to primary instance")

func _check_command_file() -> void:
	"""Check if there are new files to open from command file"""
	if not FileAccess.file_exists(instance_command_file):
		return
	
	# Read command file
	var cmd_file = FileAccess.open(instance_command_file, FileAccess.READ)
	if not cmd_file:
		return
	
	var files_to_open: Array[String] = []
	while not cmd_file.eof_reached():
		var line = cmd_file.get_line().strip_edges()
		if line != "" and FileAccess.file_exists(line):
			files_to_open.append(line)
	
	cmd_file.close()
	
	# Delete command file after reading
	DirAccess.remove_absolute(instance_command_file)
	
	# Open the files
	if files_to_open.size() > 0:
		print("Received ", files_to_open.size(), " files from secondary instance")
		for file_path in files_to_open:
			open_file(file_path)
		
		# Bring window to front
		get_window().grab_focus()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_move_to_foreground()
