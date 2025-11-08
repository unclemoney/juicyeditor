extends HBoxContainer
class_name CustomTabBar

# Custom tab bar with close buttons
# Replicates TabContainer functionality but with close buttons

signal tab_selected(tab_index: int)
signal tab_close_requested(tab_index: int)

# Tab button data
class TabData:
	var title: String = ""
	var is_modified: bool = false
	var button: Button
	var close_button: Button
	
	func _init(tab_title: String = ""):
		title = tab_title

var tabs: Array[TabData] = []
var current_tab_index: int = -1

func _ready() -> void:
	# Set up container properties
	add_theme_constant_override("separation", 0)

func add_tab(title: String) -> int:
	"""Add a new tab and return its index"""
	var tab_data = TabData.new(title)
	
	# Create main tab button
	var tab_button = Button.new()
	tab_button.text = title
	tab_button.toggle_mode = true
	tab_button.button_group = _get_or_create_button_group()
	tab_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create close button
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(20, 0)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create container for this tab (button + close button)
	var tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 2)
	tab_container.add_child(tab_button)
	tab_container.add_child(close_button)
	
	# Store references
	tab_data.button = tab_button
	tab_data.close_button = close_button
	tabs.append(tab_data)
	
	# Add to UI
	add_child(tab_container)
	
	# Connect signals
	var tab_index = tabs.size() - 1
	tab_button.pressed.connect(_on_tab_pressed.bind(tab_index))
	close_button.pressed.connect(_on_close_pressed.bind(tab_index))
	
	# Select the new tab
	set_current_tab(tab_index)
	
	return tab_index

func remove_tab(tab_index: int) -> void:
	"""Remove a tab at the given index"""
	if tab_index < 0 or tab_index >= tabs.size():
		return
	
	# Remove from UI
	var tab_container = get_child(tab_index)
	remove_child(tab_container)
	tab_container.queue_free()
	
	# Remove from data
	tabs.remove_at(tab_index)
	
	# Update current tab if necessary
	if current_tab_index == tab_index:
		if tabs.size() > 0:
			var new_index = min(tab_index, tabs.size() - 1)
			set_current_tab(new_index)
		else:
			current_tab_index = -1
	elif current_tab_index > tab_index:
		current_tab_index -= 1
	
	# Reconnect signals with updated indices
	_reconnect_signals()

func set_tab_title(tab_index: int, title: String) -> void:
	"""Set the title of a specific tab"""
	if tab_index < 0 or tab_index >= tabs.size():
		return
	
	var tab_data = tabs[tab_index]
	tab_data.title = title
	_update_tab_display(tab_index)

func set_tab_modified(tab_index: int, is_modified: bool) -> void:
	"""Set the modified state of a specific tab"""
	if tab_index < 0 or tab_index >= tabs.size():
		return
	
	var tab_data = tabs[tab_index]
	tab_data.is_modified = is_modified
	_update_tab_display(tab_index)

func set_current_tab(tab_index: int) -> void:
	"""Set the current active tab"""
	if tab_index < 0 or tab_index >= tabs.size():
		return
	
	current_tab_index = tab_index
	
	# Update button states
	for i in range(tabs.size()):
		tabs[i].button.button_pressed = (i == tab_index)

func get_current_tab() -> int:
	"""Get the current active tab index"""
	return current_tab_index

func get_tab_count() -> int:
	"""Get the total number of tabs"""
	return tabs.size()

func _update_tab_display(tab_index: int) -> void:
	"""Update the visual display of a tab"""
	if tab_index < 0 or tab_index >= tabs.size():
		return
	
	var tab_data = tabs[tab_index]
	var display_title = tab_data.title
	
	if tab_data.is_modified:
		display_title += "*"
	
	tab_data.button.text = display_title

func _get_or_create_button_group() -> ButtonGroup:
	"""Get or create a button group for tab buttons"""
	if not has_meta("tab_button_group"):
		var group = ButtonGroup.new()
		set_meta("tab_button_group", group)
		return group
	return get_meta("tab_button_group")

func _on_tab_pressed(tab_index: int) -> void:
	"""Handle tab button press"""
	set_current_tab(tab_index)
	tab_selected.emit(tab_index)

func _on_close_pressed(tab_index: int) -> void:
	"""Handle close button press"""
	tab_close_requested.emit(tab_index)

func _reconnect_signals() -> void:
	"""Reconnect all tab signals with correct indices"""
	for i in range(tabs.size()):
		var tab_data = tabs[i]
		
		# Disconnect old signals
		if tab_data.button.pressed.is_connected(_on_tab_pressed):
			tab_data.button.pressed.disconnect(_on_tab_pressed)
		if tab_data.close_button.pressed.is_connected(_on_close_pressed):
			tab_data.close_button.pressed.disconnect(_on_close_pressed)
		
		# Reconnect with correct index
		tab_data.button.pressed.connect(_on_tab_pressed.bind(i))
		tab_data.close_button.pressed.connect(_on_close_pressed.bind(i))