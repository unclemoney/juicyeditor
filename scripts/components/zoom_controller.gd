extends Node

## Zoom Controller - Manages zoom level for MainArea content
## Scales text editor and line numbers proportionally with limits

signal zoom_changed(zoom_level: float)

const MIN_ZOOM: float = 0.2  # 20%
const MAX_ZOOM: float = 3.0  # 300%
const ZOOM_STEP: float = 0.1  # 10%
const DEFAULT_ZOOM: float = 1.0  # 100%

var current_zoom: float = DEFAULT_ZOOM
var text_editor: TextEdit
var line_numbers: Control
var main_area: Control

# Store original font sizes to calculate scaled sizes
var original_editor_font_size: int = 0
var original_line_numbers_font_size: int = 0

func _ready() -> void:
	print("ZoomController initialized")

func setup(editor: TextEdit, line_nums: Control, area: Control) -> void:
	"""Setup the zoom controller with references to the components to scale"""
	text_editor = editor
	line_numbers = line_nums
	main_area = area
	
	if text_editor:
		# Store original font size from text editor
		original_editor_font_size = text_editor.get_theme_font_size("font_size")
		if original_editor_font_size <= 0:
			original_editor_font_size = 16  # Fallback default
		print("Stored original editor font size: ", original_editor_font_size)
	
	if line_numbers and line_numbers.has_method("get_font_size"):
		# Store original font size from line numbers if available
		original_line_numbers_font_size = line_numbers.font_size
		print("Stored original line numbers font size: ", original_line_numbers_font_size)
	elif line_numbers:
		# Default fallback
		original_line_numbers_font_size = 14
		print("Using default line numbers font size: ", original_line_numbers_font_size)
	
	print("ZoomController setup complete - Editor:", text_editor != null, " LineNumbers:", line_numbers != null, " MainArea:", main_area != null)
	
	# Emit initial zoom level to update UI
	zoom_changed.emit(current_zoom)

func zoom_in() -> void:
	"""Increase zoom level by 10%"""
	var new_zoom = current_zoom + ZOOM_STEP
	if new_zoom <= MAX_ZOOM:
		set_zoom(new_zoom)
		print("Zoomed in to: ", current_zoom * 100, "%")
	else:
		print("Maximum zoom reached: ", MAX_ZOOM * 100, "%")

func zoom_out() -> void:
	"""Decrease zoom level by 10%"""
	var new_zoom = current_zoom - ZOOM_STEP
	if new_zoom >= MIN_ZOOM:
		set_zoom(new_zoom)
		print("Zoomed out to: ", current_zoom * 100, "%")
	else:
		print("Minimum zoom reached: ", MIN_ZOOM * 100, "%")

func reset_zoom() -> void:
	"""Reset zoom to 100%"""
	set_zoom(DEFAULT_ZOOM)
	print("Zoom reset to 100%")

func set_zoom(zoom_level: float) -> void:
	"""Set zoom to a specific level"""
	zoom_level = clamp(zoom_level, MIN_ZOOM, MAX_ZOOM)
	
	if zoom_level == current_zoom:
		return
	
	current_zoom = zoom_level
	_apply_zoom()
	zoom_changed.emit(current_zoom)

func _apply_zoom() -> void:
	"""Apply the current zoom level to all components"""
	if not text_editor or not line_numbers:
		print("WARNING: Cannot apply zoom - missing components")
		return
	
	# Calculate new font sizes
	var new_editor_font_size = int(original_editor_font_size * current_zoom)
	var new_line_numbers_font_size = int(original_line_numbers_font_size * current_zoom)
	
	# Ensure minimum readable size
	new_editor_font_size = max(new_editor_font_size, 6)
	new_line_numbers_font_size = max(new_line_numbers_font_size, 6)
	
	print("Applying zoom: ", current_zoom * 100, "% - Editor font:", new_editor_font_size, " LineNumbers font:", new_line_numbers_font_size)
	
	# Apply to text editor via theme override
	text_editor.add_theme_font_size_override("font_size", new_editor_font_size)
	
	# Apply to line numbers
	if line_numbers.has_method("set_font_size"):
		line_numbers.set_font_size(new_line_numbers_font_size)
	else:
		# Fallback: directly set the font_size property if the method doesn't exist
		line_numbers.font_size = new_line_numbers_font_size
		
		# Force line numbers to recalculate line height
		if line_numbers.has_method("_sync_line_height_with_editor"):
			line_numbers._sync_line_height_with_editor()
		
		# Force line numbers to refresh
		if line_numbers.has_method("_update_line_numbers"):
			line_numbers.call_deferred("_update_line_numbers")

func get_zoom_percentage() -> int:
	"""Get current zoom level as a percentage (e.g., 100 for 100%)"""
	return int(current_zoom * 100)
