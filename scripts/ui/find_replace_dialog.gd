extends AcceptDialog
class_name FindReplaceDialog

# Juicy Editor - Find & Replace Dialog
# Provides search and replace functionality

signal find_next_requested(search_text: String, case_sensitive: bool, whole_words: bool)
signal find_previous_requested(search_text: String, case_sensitive: bool, whole_words: bool)
signal replace_requested(search_text: String, replace_text: String, case_sensitive: bool, whole_words: bool)
signal replace_all_requested(search_text: String, replace_text: String, case_sensitive: bool, whole_words: bool)

@export var container_path: NodePath

var main_container: VBoxContainer
var find_line_edit: LineEdit
var replace_line_edit: LineEdit
var case_sensitive_check: CheckBox
var whole_words_check: CheckBox
var find_next_button: Button
var find_previous_button: Button
var replace_button: Button
var replace_all_button: Button
var results_label: Label

var text_editor: TextEdit
var search_results: Array[Vector2i] = []
var current_result_index: int = -1

func _ready() -> void:
	title = "Find & Replace"
	size = Vector2(400, 200)
	set_flag(Window.FLAG_ALWAYS_ON_TOP, true)
	
	_create_ui()
	_connect_signals()

func _create_ui() -> void:
	# Main container
	main_container = VBoxContainer.new()
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.position.y = 30  # Leave space for title
	main_container.size.y -= 70     # Leave space for buttons
	
	# Find section
	var find_group = HBoxContainer.new()
	main_container.add_child(find_group)
	
	var find_label = Label.new()
	find_label.text = "Find:"
	find_label.custom_minimum_size.x = 60
	find_group.add_child(find_label)
	
	find_line_edit = LineEdit.new()
	find_line_edit.placeholder_text = "Enter search text..."
	find_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	find_group.add_child(find_line_edit)
	
	find_next_button = Button.new()
	find_next_button.text = "Next"
	find_next_button.custom_minimum_size.x = 60
	find_group.add_child(find_next_button)
	
	find_previous_button = Button.new()
	find_previous_button.text = "Previous"
	find_previous_button.custom_minimum_size.x = 70
	find_group.add_child(find_previous_button)
	
	# Replace section
	var replace_group = HBoxContainer.new()
	main_container.add_child(replace_group)
	
	var replace_label = Label.new()
	replace_label.text = "Replace:"
	replace_label.custom_minimum_size.x = 60
	replace_group.add_child(replace_label)
	
	replace_line_edit = LineEdit.new()
	replace_line_edit.placeholder_text = "Enter replacement text..."
	replace_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replace_group.add_child(replace_line_edit)
	
	replace_button = Button.new()
	replace_button.text = "Replace"
	replace_button.custom_minimum_size.x = 60
	replace_group.add_child(replace_button)
	
	replace_all_button = Button.new()
	replace_all_button.text = "Replace All"
	replace_all_button.custom_minimum_size.x = 80
	replace_group.add_child(replace_all_button)
	
	# Options section
	var options_group = HBoxContainer.new()
	main_container.add_child(options_group)
	
	case_sensitive_check = CheckBox.new()
	case_sensitive_check.text = "Case Sensitive"
	options_group.add_child(case_sensitive_check)
	
	whole_words_check = CheckBox.new()
	whole_words_check.text = "Whole Words"
	options_group.add_child(whole_words_check)
	
	# Results label
	results_label = Label.new()
	results_label.text = "Ready to search"
	results_label.add_theme_color_override("font_color", Color.GRAY)
	main_container.add_child(results_label)

func _connect_signals() -> void:
	find_line_edit.text_changed.connect(_on_search_text_changed)
	find_line_edit.text_submitted.connect(_on_find_next)
	
	find_next_button.pressed.connect(_on_find_next_pressed)
	find_previous_button.pressed.connect(_on_find_previous_pressed)
	replace_button.pressed.connect(_on_replace_pressed)
	replace_all_button.pressed.connect(_on_replace_all_pressed)
	
	case_sensitive_check.toggled.connect(_on_options_changed)
	whole_words_check.toggled.connect(_on_options_changed)

func set_text_editor(editor: TextEdit) -> void:
	text_editor = editor
	if text_editor:
		# If text is selected, use it as initial search text
		var selected_text = text_editor.get_selected_text()
		if selected_text.length() > 0:
			find_line_edit.text = selected_text

func _on_search_text_changed(new_text: String) -> void:
	if new_text.length() == 0:
		search_results.clear()
		current_result_index = -1
		results_label.text = "Ready to search"
		return
	
	_perform_search()

func _on_options_changed(_toggled: bool) -> void:
	if find_line_edit.text.length() > 0:
		_perform_search()

func _perform_search() -> void:
	if not text_editor or find_line_edit.text.length() == 0:
		return
	
	search_results.clear()
	current_result_index = -1
	
	var search_text = find_line_edit.text
	var editor_text = text_editor.text
	var case_sensitive = case_sensitive_check.button_pressed
	var whole_words = whole_words_check.button_pressed
	
	if not case_sensitive:
		search_text = search_text.to_lower()
		editor_text = editor_text.to_lower()
	
	var search_pos = 0
	while true:
		var found_pos = editor_text.find(search_text, search_pos)
		if found_pos == -1:
			break
		
		# Check for whole words if option is enabled
		if whole_words:
			var is_whole_word = true
			
			# Check character before
			if found_pos > 0:
				var char_before = editor_text[found_pos - 1]
				if char_before.is_valid_identifier() or char_before.is_valid_int():
					is_whole_word = false
			
			# Check character after
			if found_pos + search_text.length() < editor_text.length():
				var char_after = editor_text[found_pos + search_text.length()]
				if char_after.is_valid_identifier() or char_after.is_valid_int():
					is_whole_word = false
			
			if not is_whole_word:
				search_pos = found_pos + 1
				continue
		
		# Convert position to line/column
		var line_col = _position_to_line_column(found_pos)
		search_results.append(line_col)
		
		search_pos = found_pos + 1
	
	_update_results_display()

func _position_to_line_column(pos: int) -> Vector2i:
	if not text_editor:
		return Vector2i.ZERO
	
	var text = text_editor.text
	var line = 0
	var column = 0
	
	for i in range(pos):
		if i < text.length() and text[i] == '\n':
			line += 1
			column = 0
		else:
			column += 1
	
	return Vector2i(line, column)

func _update_results_display() -> void:
	if search_results.size() == 0:
		results_label.text = "No matches found"
		results_label.add_theme_color_override("font_color", Color.RED)
	else:
		var current_text = ""
		if current_result_index >= 0:
			current_text = " (Current: " + str(current_result_index + 1) + ")"
		results_label.text = str(search_results.size()) + " matches found" + current_text
		results_label.add_theme_color_override("font_color", Color.GREEN)

func _on_find_next(_text: String = "") -> void:
	_on_find_next_pressed()

func _on_find_next_pressed() -> void:
	if search_results.size() == 0:
		return
	
	current_result_index = (current_result_index + 1) % search_results.size()
	_highlight_current_result()
	find_next_requested.emit(find_line_edit.text, case_sensitive_check.button_pressed, whole_words_check.button_pressed)

func _on_find_previous_pressed() -> void:
	if search_results.size() == 0:
		return
	
	current_result_index -= 1
	if current_result_index < 0:
		current_result_index = search_results.size() - 1
	
	_highlight_current_result()
	find_previous_requested.emit(find_line_edit.text, case_sensitive_check.button_pressed, whole_words_check.button_pressed)

func _highlight_current_result() -> void:
	if not text_editor or current_result_index < 0 or current_result_index >= search_results.size():
		return
	
	var result_pos = search_results[current_result_index]
	text_editor.set_caret_line(result_pos.x)
	text_editor.set_caret_column(result_pos.y)
	
	# Select the found text
	text_editor.select(result_pos.x, result_pos.y, result_pos.x, result_pos.y + find_line_edit.text.length())
	
	# Scroll to show the selection
	text_editor.center_viewport_to_caret()
	
	_update_results_display()

func _on_replace_pressed() -> void:
	if current_result_index < 0 or search_results.size() == 0:
		return
	
	replace_requested.emit(find_line_edit.text, replace_line_edit.text, case_sensitive_check.button_pressed, whole_words_check.button_pressed)
	
	# Refresh search after replace
	call_deferred("_perform_search")

func _on_replace_all_pressed() -> void:
	if search_results.size() == 0:
		return
	
	replace_all_requested.emit(find_line_edit.text, replace_line_edit.text, case_sensitive_check.button_pressed, whole_words_check.button_pressed)
	
	# Refresh search after replace all
	call_deferred("_perform_search")

func focus_find_field() -> void:
	find_line_edit.grab_focus()
	find_line_edit.select_all()

func get_search_text() -> String:
	return find_line_edit.text

func set_search_text(text: String) -> void:
	find_line_edit.text = text
	_perform_search()