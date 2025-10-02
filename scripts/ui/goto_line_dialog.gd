extends AcceptDialog
class_name GotoLineDialog

# Juicy Editor - Go to Line Dialog
# Allows jumping to a specific line number

signal goto_line_requested(line_number: int)

@export var container_path: NodePath

var main_container: VBoxContainer
var line_spinbox: SpinBox
var current_line_label: Label
var total_lines_label: Label
var go_button: Button

var text_editor: TextEdit

func _ready() -> void:
	title = "Go to Line"
	size = Vector2(300, 150)
	
	_create_ui()
	_connect_signals()

func _create_ui() -> void:
	# Main container
	main_container = VBoxContainer.new()
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.position.y = 30  # Leave space for title
	main_container.size.y -= 70     # Leave space for buttons
	
	# Info section
	var info_container = VBoxContainer.new()
	main_container.add_child(info_container)
	
	current_line_label = Label.new()
	current_line_label.text = "Current line: 1"
	current_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(current_line_label)
	
	total_lines_label = Label.new()
	total_lines_label.text = "Total lines: 1"
	total_lines_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(total_lines_label)
	
	# Line input section
	var line_group = HBoxContainer.new()
	main_container.add_child(line_group)
	
	var line_label = Label.new()
	line_label.text = "Go to line:"
	line_label.custom_minimum_size.x = 80
	line_group.add_child(line_label)
	
	line_spinbox = SpinBox.new()
	line_spinbox.min_value = 1
	line_spinbox.max_value = 1
	line_spinbox.value = 1
	line_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_group.add_child(line_spinbox)
	
	# Go button
	go_button = Button.new()
	go_button.text = "Go"
	go_button.custom_minimum_size.x = 60
	line_group.add_child(go_button)

func _connect_signals() -> void:
	go_button.pressed.connect(_on_go_pressed)
	line_spinbox.value_changed.connect(_on_line_value_changed)
	
	# Allow Enter key to trigger Go
	line_spinbox.gui_input.connect(_on_spinbox_input)

func _on_spinbox_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_go_pressed()
			get_viewport().set_input_as_handled()

func set_text_editor(editor: TextEdit) -> void:
	text_editor = editor
	if text_editor:
		_update_editor_info()

func _update_editor_info() -> void:
	if not text_editor:
		return
	
	var current_line = text_editor.get_caret_line() + 1
	var total_lines = text_editor.get_line_count()
	
	current_line_label.text = "Current line: " + str(current_line)
	total_lines_label.text = "Total lines: " + str(total_lines)
	
	line_spinbox.max_value = total_lines
	line_spinbox.value = current_line

func _on_line_value_changed(_value: float) -> void:
	# Optional: Could provide live preview by highlighting the target line
	pass

func _on_go_pressed() -> void:
	var target_line = int(line_spinbox.value)
	goto_line_requested.emit(target_line)
	hide()

func focus_line_input() -> void:
	line_spinbox.grab_focus()
	line_spinbox.get_line_edit().select_all()

func popup_centered_for_editor(editor: TextEdit) -> void:
	set_text_editor(editor)
	popup_centered()
	focus_line_input()