extends VBoxContainer
class_name FileTabContainer

# Juicy Editor - File Tab Container with Custom Tab Bar
# Manages multiple open files with tab functionality and close buttons

signal tab_changed_to(tab_index: int)

# Import the custom tab bar
const CustomTabBar = preload("res://scripts/components/custom_tab_bar.gd")

# File data structure
class FileData:
	var file_path: String = ""
	var content: String = ""
	var is_modified: bool = false
	var cursor_line: int = 0
	var cursor_column: int = 0
	var scroll_position: float = 0.0
	
	func _init(path: String = "", text: String = ""):
		file_path = path
		content = text

# Storage for file data for each tab
var tab_files: Array[FileData] = []
var current_tab_index: int = -1

# Reference to the main text editor
var text_editor: TextEdit

# Custom tab bar
var tab_bar: CustomTabBar

func _ready() -> void:
	# Create custom tab bar
	tab_bar = CustomTabBar.new()
	tab_bar.custom_minimum_size = Vector2(0, 35)
	add_child(tab_bar)
	
	# Connect tab bar signals
	tab_bar.tab_selected.connect(_on_tab_selected)
	tab_bar.tab_close_requested.connect(_on_tab_close_requested)
	
	# Don't create initial tab here - wait for setup_text_editor

func setup_text_editor(editor: TextEdit) -> void:
	"""Setup reference to the main text editor"""
	text_editor = editor
	
	# Don't create initial tab automatically - let the game controller decide
	# based on whether files are being opened from command line

func add_new_tab(file_path: String = "", content: String = "") -> int:
	"""Add a new tab with the given file"""
	var file_data = FileData.new(file_path, content)
	tab_files.append(file_data)
	
	# Add tab to tab bar
	var title = "Untitled"
	if file_path != "":
		title = file_path.get_file()
	
	var tab_index = tab_bar.add_tab(title)
	current_tab_index = tab_index
	
	# Update tab title with modification indicator
	update_tab_title(tab_index)
	
	# Load the content into the text editor
	_load_tab_to_editor(tab_index)
	
	return tab_index

func update_tab_title(tab_index: int) -> void:
	"""Update the title of a specific tab"""
	if tab_index < 0 or tab_index >= tab_files.size():
		return
	
	var file_data = tab_files[tab_index]
	var title = "Untitled"
	
	if file_data.file_path != "":
		title = file_data.file_path.get_file()
	
	# Update tab bar
	tab_bar.set_tab_title(tab_index, title)
	tab_bar.set_tab_modified(tab_index, file_data.is_modified)

func close_tab(tab_index: int) -> bool:
	"""Close a specific tab. Returns true if closed, false if cancelled"""
	if tab_index < 0 or tab_index >= tab_files.size():
		return false
	
	var file_data = tab_files[tab_index]
	
	# If file is modified, we might want to ask for confirmation
	# For now, just close it directly
	if file_data.is_modified:
		# TODO: Add confirmation dialog
		print("Warning: Closing modified file: ", file_data.file_path)
	
	# Save current editor state before switching
	if current_tab_index == tab_index:
		_save_current_editor_state()
	
	# Remove the tab data
	tab_files.remove_at(tab_index)
	
	# Remove the tab from tab bar
	tab_bar.remove_tab(tab_index)
	
	# Update current tab index
	current_tab_index = tab_bar.get_current_tab()
	
	# If no tabs left, create a new empty one
	if tab_files.size() == 0:
		add_new_tab("", "")
	else:
		# Load the current tab content
		_load_tab_to_editor(current_tab_index)
	
	return true

func get_current_file_data() -> FileData:
	"""Get the file data for the current tab"""
	if current_tab_index >= 0 and current_tab_index < tab_files.size():
		return tab_files[current_tab_index]
	return null

func set_current_file_path(file_path: String) -> void:
	"""Set the file path for the current tab"""
	var file_data = get_current_file_data()
	if file_data:
		file_data.file_path = file_path
		update_tab_title(current_tab_index)

func set_current_file_modified(is_modified: bool) -> void:
	"""Set the modified state for the current tab"""
	var file_data = get_current_file_data()
	if file_data:
		file_data.is_modified = is_modified
		update_tab_title(current_tab_index)

func get_tab_by_file_path(file_path: String) -> int:
	"""Find a tab with the given file path. Returns -1 if not found"""
	for i in range(tab_files.size()):
		if tab_files[i].file_path == file_path:
			return i
	return -1

func switch_to_file(file_path: String) -> bool:
	"""Switch to a tab with the given file path. Returns true if found"""
	var tab_index = get_tab_by_file_path(file_path)
	if tab_index >= 0:
		tab_bar.set_current_tab(tab_index)
		current_tab_index = tab_index
		_load_tab_to_editor(tab_index)
		return true
	return false

func _on_tab_selected(tab_index: int) -> void:
	"""Handle tab selection from tab bar"""
	print("DEBUG: Tab selected: ", tab_index)
	
	# Save current editor state before switching
	_save_current_editor_state()
	
	# Update current tab
	current_tab_index = tab_index
	
	# Load the new tab's content to editor
	_load_tab_to_editor(tab_index)
	
	# Emit signal for external handlers
	tab_changed_to.emit(tab_index)

func _on_tab_close_requested(tab_index: int) -> void:
	"""Handle tab close request from tab bar"""
	close_tab(tab_index)

func _save_current_editor_state() -> void:
	"""Save the current editor state to the current tab's file data"""
	if not text_editor:
		return
	
	var file_data = get_current_file_data()
	if file_data:
		file_data.content = text_editor.text
		file_data.cursor_line = text_editor.get_caret_line()
		file_data.cursor_column = text_editor.get_caret_column()
		file_data.scroll_position = text_editor.scroll_vertical

func _load_tab_to_editor(tab_index: int) -> void:
	"""Load a tab's content to the text editor"""
	print("DEBUG: Loading tab ", tab_index, " to editor")
	
	if not text_editor or tab_index < 0 or tab_index >= tab_files.size():
		print("DEBUG: Cannot load tab - missing text_editor or invalid index")
		print("DEBUG: text_editor exists: ", text_editor != null)
		print("DEBUG: tab_index: ", tab_index, ", tab_files size: ", tab_files.size())
		return
	
	var file_data = tab_files[tab_index]
	print("DEBUG: Loading content: '", file_data.content.substr(0, 50), "...'")
	
	# Set content
	text_editor.text = file_data.content
	
	# Restore cursor position
	text_editor.set_caret_line(file_data.cursor_line)
	text_editor.set_caret_column(file_data.cursor_column)
	
	# Restore scroll position
	text_editor.scroll_vertical = file_data.scroll_position
	
	# Set syntax highlighting if file has a path
	if file_data.file_path != "" and text_editor.has_method("set_syntax_highlighting_for_file"):
		text_editor.set_syntax_highlighting_for_file(file_data.file_path)
	
	print("DEBUG: Tab loaded successfully")

func get_all_modified_files() -> Array[String]:
	"""Get a list of all modified file paths"""
	var modified_files: Array[String] = []
	for file_data in tab_files:
		if file_data.is_modified and file_data.file_path != "":
			modified_files.append(file_data.file_path)
	return modified_files

func save_all_tabs() -> bool:
	"""Save all modified tabs. Returns true if all saved successfully"""
	# This will need to be implemented in coordination with the game controller
	# For now, just return true
	return true

func ensure_tab_exists() -> void:
	"""Ensure at least one tab exists - creates empty tab if none exist"""
	if tab_files.size() == 0:
		add_new_tab("", "")