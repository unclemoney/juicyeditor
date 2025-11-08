extends Control
class_name LineNumbers

# Simplified Juicy Editor - Line Numbers Component
# Focus on basic functionality first

signal line_numbers_ready()

@export var line_number_color: Color = Color(0.7, 0.7, 0.7, 1.0)
@export var active_line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.3)
@export var padding_left: float = 8.0
@export var padding_right: float = 8.0

# Font resources
var national2_font: FontFile
var font_size: int = 14
var line_height: float = 20.0

# Text editor reference
var text_editor: TextEdit
var current_line_count: int = 0
var active_line: int = 0

# Visual elements
var line_labels: Array[Label] = []
var background_rect: ColorRect

# Update tracking
var last_scroll_position: float = -1
var update_timer: Timer

func _ready() -> void:
	print("🔢 SIMPLIFIED LineNumbers component starting...")
	name = "LineNumbers"  # Ensure proper name
	
	# Basic setup first
	_setup_basic_properties()
	_load_font()
	_setup_background()
	_setup_update_timer()
	
	print("🔢 LineNumbers component ready!")
	line_numbers_ready.emit()

func _setup_basic_properties() -> void:
	"""Setup basic component properties"""
	custom_minimum_size.x = 60
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	print("📏 Basic properties set")

func _load_font() -> void:
	"""Load National2 font with fallback"""
	national2_font = load("res://fonts/National2Condensed-Regular.otf")
	if national2_font:
		print("✅ National2 font loaded successfully")
	else:
		print("⚠️ National2 font failed to load - using default")

func _setup_background() -> void:
	"""Setup background panel"""
	background_rect = ColorRect.new()
	background_rect.name = "Background"
	background_rect.color = background_color
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("🎨 Background setup complete")

func _setup_update_timer() -> void:
	"""Setup timer for regular updates"""
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # Update every 100ms
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()
	print("⏰ Update timer setup complete")

func _setup_layout() -> void:
	"""Setup initial layout properties"""
	# Set minimum width to accommodate 4-digit line numbers
	custom_minimum_size.x = 60
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Connect to resize for proper background sizing
	resized.connect(_on_resized)

func _on_resized() -> void:
	"""Handle component resize"""
	if background_rect:
		background_rect.size = size

func setup_text_editor(editor: TextEdit) -> void:
	"""Connect to a text editor instance - simplified version"""
	print("🔗 Setting up text editor connection...")
	
	if text_editor:
		# Disconnect from previous editor
		if text_editor.text_changed.is_connected(_on_text_changed):
			text_editor.text_changed.disconnect(_on_text_changed)
		if text_editor.caret_changed.is_connected(_on_caret_changed):
			text_editor.caret_changed.disconnect(_on_caret_changed)
	
	text_editor = editor
	
	if text_editor:
		# Sync line height with text editor
		_sync_line_height_with_editor()
		
		# Connect signals
		text_editor.text_changed.connect(_on_text_changed)
		text_editor.caret_changed.connect(_on_caret_changed)
		
		# Connect scroll signals for better tracking
		if text_editor.has_signal("gui_input"):
			text_editor.gui_input.connect(_on_text_editor_input)
		
		# Connect to scrollbar events for immediate scroll tracking
		_connect_scrollbar_events()
		
		# Initial update
		call_deferred("_update_line_numbers")
		call_deferred("_update_active_line")
		
		print("✅ LineNumbers connected to TextEdit - line height:", line_height)
	else:
		print("❌ Failed to connect to TextEdit")

func _connect_scrollbar_events() -> void:
	"""Connect to scrollbar events for more responsive scroll tracking"""
	if not text_editor:
		return
	
	print("🔗 Connecting scrollbar events...")
	
	# TextEdit in Godot 4.4 has internal scrollbars we can access
	# Look for VScrollBar child node
	for child in text_editor.get_children():
		if child is VScrollBar:
			var scrollbar = child as VScrollBar
			if not scrollbar.value_changed.is_connected(_on_scrollbar_value_changed):
				scrollbar.value_changed.connect(_on_scrollbar_value_changed)
				print("📜 Connected to VScrollBar value_changed")
			break
	
	# Also try connecting to TextEdit's scroll signals if available
	if text_editor.has_signal("scrolled"):
		if not text_editor.scrolled.is_connected(_on_text_editor_scrolled):
			text_editor.scrolled.connect(_on_text_editor_scrolled)
			print("📜 Connected to TextEdit scrolled signal")

func _on_scrollbar_value_changed(value: float) -> void:
	"""Handle scrollbar value changes for immediate sync"""
	print("📜 Scrollbar value changed to:", value)
	_sync_scroll_position()

func _on_text_editor_scrolled() -> void:
	"""Handle TextEdit scroll events"""
	print("📜 TextEdit scrolled")
	_sync_scroll_position()

func _sync_line_height_with_editor() -> void:
	"""Synchronize line height with the text editor's actual line height"""
	if not text_editor:
		return
	
	print("🔄 Syncing line height with editor...")
	
	# Get the actual line height from the TextEdit
	var text_font = text_editor.get_theme_font("font")
	var text_font_size = text_editor.get_theme_font_size("font_size")
	
	if text_font and text_font_size > 0:
		# Calculate the actual line height including line spacing
		var font_height = text_font.get_height(text_font_size)
		var line_spacing = text_editor.get_theme_constant("line_spacing")
		line_height = font_height + line_spacing
		
		# Also sync our font size to match
		font_size = text_font_size
		print("📏 Calculated line height:", line_height, "from font size:", text_font_size)
	else:
		# Fallback: try to get line height directly from TextEdit
		if text_editor.has_method("get_line_height"):
			line_height = text_editor.get_line_height()
			print("📏 Got line height from TextEdit:", line_height)
		else:
			# Last resort: estimate based on font size
			line_height = font_size * 1.4
			print("📏 Estimated line height:", line_height)

func _on_text_changed() -> void:
	"""Handle text changes in the editor"""
	if not text_editor:
		return
	
	var new_line_count = text_editor.get_line_count()
	if new_line_count != current_line_count:
		print("📝 Text changed - lines:", current_line_count, "->", new_line_count)
		current_line_count = new_line_count
		call_deferred("_update_line_numbers")

func _on_caret_changed() -> void:
	"""Handle caret position changes"""
	if not text_editor:
		return
	
	var new_active_line = text_editor.get_caret_line()
	if new_active_line != active_line:
		active_line = new_active_line
		call_deferred("_update_active_line")

func _on_text_editor_input(event: InputEvent) -> void:
	"""Handle input events from text editor for scroll tracking"""
	var needs_scroll_update = false
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			print("🖱️ Mouse wheel scroll detected:", "UP" if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else "DOWN")
			needs_scroll_update = true
	
	elif event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			# Check for scroll-related keys
			if key_event.keycode == KEY_UP or key_event.keycode == KEY_DOWN or key_event.keycode == KEY_PAGEUP or key_event.keycode == KEY_PAGEDOWN or key_event.keycode == KEY_HOME or key_event.keycode == KEY_END:
				print("⌨️ Scroll key pressed:", key_event.keycode)
				needs_scroll_update = true
	
	if needs_scroll_update:
		# Use immediate sync for user input
		call_deferred("_sync_scroll_position")
		# Also force position refresh to prevent drift
		call_deferred("_force_refresh_all_positions")

func _on_update_timer_timeout() -> void:
	"""Regular update check for scroll position"""
	if text_editor:
		var current_scroll = text_editor.scroll_vertical
		if current_scroll != last_scroll_position:
			last_scroll_position = current_scroll
			_sync_scroll_position()

func _update_line_numbers() -> void:
	"""Update the line number display"""
	if not text_editor:
		return
	
	var line_count = text_editor.get_line_count()
	print("🔢 Updating line numbers for", line_count, "lines")
	
	# Remove excess labels
	while line_labels.size() > line_count:
		var label = line_labels.pop_back()
		if is_instance_valid(label):
			label.queue_free()
	
	# Add new labels if needed
	while line_labels.size() < line_count:
		_create_line_label(line_labels.size() + 1)
	
	# Update all labels
	for i in range(line_count):
		_update_line_label(i, i + 1)

func _create_line_label(line_number: int) -> void:
	"""Create a new line number label"""
	var label = Label.new()
	label.name = "LineNumber_" + str(line_number)
	
	# Setup font
	if national2_font:
		label.add_theme_font_override("font", national2_font)
	label.add_theme_font_size_override("font_size", font_size)
	
	# Setup appearance
	label.add_theme_color_override("font_color", line_number_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Setup layout using synchronized line height
	label.size.y = line_height
	label.position.x = padding_left
	label.size.x = size.x - padding_left - padding_right
	
	add_child(label)
	line_labels.append(label)

func _update_line_label(index: int, line_number: int) -> void:
	"""Update a specific line label"""
	if index >= line_labels.size():
		return
	
	var label = line_labels[index]
	if not is_instance_valid(label):
		return
	
	label.text = str(line_number)
	
	# Position the label using precise calculations
	_reset_label_position(label, index)
	
	# Update color based on active line
	if line_number - 1 == active_line:
		label.add_theme_color_override("font_color", active_line_color)
	else:
		label.add_theme_color_override("font_color", line_number_color)

func _reset_label_position(label: Label, index: int) -> void:
	"""Reset label to its proper position"""
	if not text_editor or not is_instance_valid(label):
		return
	
	# Calculate position using TextEdit's coordinate system
	var scroll_offset = text_editor.scroll_vertical
	var editor_top_padding = _get_editor_top_padding()
	
	var proper_y = editor_top_padding + (index * line_height) - (scroll_offset * line_height)
	
	# Set position and size explicitly
	label.position.x = padding_left
	label.position.y = proper_y
	label.size.x = size.x - padding_left - padding_right
	label.size.y = line_height
	
	# Reset transformations
	label.scale = Vector2.ONE
	label.pivot_offset = Vector2.ZERO

func _get_editor_top_padding() -> float:
	"""Get the top padding used by the TextEdit"""
	if not text_editor:
		return 0.0
	
	var style_box = text_editor.get_theme_stylebox("normal")
	if style_box:
		return style_box.get_margin(SIDE_TOP)
	
	return 2.0

func _update_active_line() -> void:
	"""Update the active line highlighting"""
	for i in range(line_labels.size()):
		_update_line_label(i, i + 1)

func _sync_scroll_position() -> void:
	"""Synchronize scroll position with text editor"""
	if not text_editor:
		return
	
	# Update all label positions
	for i in range(line_labels.size()):
		if i < line_labels.size():
			var label = line_labels[i]
			if is_instance_valid(label):
				_reset_label_position(label, i)

# Theme and settings management
func refresh_for_theme_change() -> void:
	"""Refresh line numbers after theme change"""
	print("🎨 Refreshing line numbers for theme change...")
	
	if text_editor:
		_sync_line_height_with_editor()
		
		# Update all existing labels
		for i in range(line_labels.size()):
			var label = line_labels[i]
			if is_instance_valid(label):
				# Update font size
				label.add_theme_font_size_override("font_size", font_size)
				label.size.y = line_height
				_reset_label_position(label, i)
		
		print("✅ Theme refresh complete")

func force_update() -> void:
	"""Force a complete update of line numbers"""
	print("🔄 Force updating line numbers...")
	if text_editor:
		current_line_count = 0  # Force refresh
		_update_line_numbers()
		_update_active_line()
		print("✅ Force update complete")

func _force_refresh_all_positions() -> void:
	"""Force refresh all line number positions to their correct locations"""
	print("🔄 Force refreshing all line positions...")
	for i in range(line_labels.size()):
		var label = line_labels[i]
		if is_instance_valid(label):
			# Reset all transformation properties
			label.scale = Vector2.ONE
			label.pivot_offset = Vector2.ZERO
			label.rotation = 0.0
			
			# Reset position
			_reset_label_position(label, i)
			
			# Reset color to proper value
			if i == active_line:
				label.add_theme_color_override("font_color", active_line_color)
			else:
				label.add_theme_color_override("font_color", line_number_color)
	print("✅ Position refresh complete")
