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

var text_editor: TextEdit
var menu_bar: Control
var status_bar: Control
var file_dialog: FileDialog
var visual_effects_manager: Node
var animation_manager: Node

var current_file_path: String = ""
var is_file_modified: bool = false
var editor_settings: Dictionary = {}
var recent_files: Array[String] = []
var max_recent_files: int = 10

func _ready() -> void:
	print("Juicy Editor starting up...")
	_initialize_systems()
	_connect_signals()
	_load_settings()

func initialize_node_references() -> void:
	# Initialize node references from paths
	text_editor = get_node_or_null(text_editor_path) if text_editor_path != NodePath() else null
	menu_bar = get_node_or_null(menu_bar_path) if menu_bar_path != NodePath() else null
	status_bar = get_node_or_null(status_bar_path) if status_bar_path != NodePath() else null
	file_dialog = get_node_or_null(file_dialog_path) if file_dialog_path != NodePath() else null
	
	# Get visual effects manager from main scene
	visual_effects_manager = get_node_or_null("/root/Main/VisualEffectsManager")
	
	# Get animation manager (if it exists)
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	
	print("Node references initialized:")
	print("  text_editor: ", text_editor)
	print("  menu_bar: ", menu_bar)
	print("  status_bar: ", status_bar)
	print("  file_dialog: ", file_dialog)
	print("  visual_effects_manager: ", visual_effects_manager)
	print("  animation_manager: ", animation_manager)
	
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
		"cursor_animations": true,
		"button_animations": true,
		"deletion_explosions": true,
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
	_update_window_title()

func _on_caret_changed() -> void:
	# Update status bar with cursor position
	if text_editor and status_bar:
		var _line = text_editor.get_caret_line() + 1
		var _column = text_editor.get_caret_column() + 1
		# Status bar update will be implemented when status bar exists

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
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var error = file.get_error()
		file.close()
		
		if error != OK:
			print("Error reading file: ", file_path, " Error code: ", error)
			return
		
		if text_editor:
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
		path_to_save = current_file_path
	
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
	if text_editor:
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
