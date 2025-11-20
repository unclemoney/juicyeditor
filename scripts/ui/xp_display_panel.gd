extends PanelContainer
class_name XPDisplayPanel

## XP Display Panel - Shows player level, XP progress, and achievements
## Displays current level, XP bar, and achievement badge grid

signal achievement_clicked(achievement_id: String)

## Level display label
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelContainer/LevelLabel

## XP progress bar
@onready var xp_progress_bar: ProgressBar = $MarginContainer/VBoxContainer/XPContainer/XPProgressBar

## XP text label
@onready var xp_label: Label = $MarginContainer/VBoxContainer/XPContainer/XPLabel

## Achievement grid container
@onready var achievement_grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/AchievementGrid

## Reset button
@onready var reset_button: Button = $MarginContainer/VBoxContainer/ResetButton

## Reference to XP System
var xp_system: Node = null


## Achievement badge scene (preload)
var badge_scene: PackedScene = null

func _ready() -> void:
	print("XPDisplayPanel: _ready() started")
	
	# Connect reset button
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	
	# Verify all required nodes exist
	print("XPDisplayPanel: Checking level_label...")
	if not level_label:
		push_error("XPDisplayPanel: LevelLabel node not found!")
		return
	
	print("XPDisplayPanel: Checking xp_progress_bar...")
	if not xp_progress_bar:
		push_error("XPDisplayPanel: XPProgressBar node not found!")
		return
	
	print("XPDisplayPanel: Checking xp_label...")
	if not xp_label:
		push_error("XPDisplayPanel: XPLabel node not found!")
		return
	
	print("XPDisplayPanel: Checking achievement_grid...")
	if not achievement_grid:
		push_error("XPDisplayPanel: AchievementGrid node not found!")
		return
	
	print("XPDisplayPanel: All nodes found, getting XP System...")
	
	# Get XP System autoload
	xp_system = get_node("/root/XPSystem") if has_node("/root/XPSystem") else null
	
	if xp_system:
		print("XPDisplayPanel: XP System found, connecting signals...")
		
		# Connect XP system signals
		xp_system.xp_gained.connect(_on_xp_gained)
		print("XPDisplayPanel: xp_gained signal connected")
		
		xp_system.level_up.connect(_on_level_up)
		print("XPDisplayPanel: level_up signal connected")
		
		xp_system.achievement_unlocked.connect(_on_achievement_unlocked)
		print("XPDisplayPanel: achievement_unlocked signal connected")
		
		# Initialize display
		print("XPDisplayPanel: Calling _update_display()...")
		_update_display()
		print("XPDisplayPanel: _update_display() completed")
		
		print("XPDisplayPanel: Calling _populate_achievements()...")
		_populate_achievements()
		print("XPDisplayPanel: _populate_achievements() completed")
		
		print("XPDisplayPanel: Initialized and connected")
	else:
		push_error("XPDisplayPanel: XP System autoload not found - check Project Settings")

func _update_display() -> void:
	## Update level and XP display
	if not xp_system:
		return
	
	# Update level label
	if level_label:
		level_label.text = "Level %d" % xp_system.current_level
	
	# Update XP progress bar
	if xp_progress_bar:
		var xp_needed: int = xp_system.get_xp_for_next_level()
		if xp_needed > 0:
			xp_progress_bar.max_value = xp_needed
			xp_progress_bar.value = xp_system.current_xp
		else:
			xp_progress_bar.max_value = 100
			xp_progress_bar.value = 100
	
	# Update XP label
	if xp_label:
		var xp_needed: int = xp_system.get_xp_for_next_level()
		xp_label.text = "%d / %d XP" % [xp_system.current_xp, xp_needed]

func _populate_achievements() -> void:
	## Populate achievement badge grid
	if not achievement_grid or not xp_system:
		return
	
	# Clear existing badges
	for child in achievement_grid.get_children():
		child.queue_free()
	
	# Get all achievements
	var achievements: Array[Dictionary] = xp_system.get_all_achievements()
	
	# Create badge for each achievement
	for achievement in achievements:
		var badge: Control = _create_achievement_badge(achievement)
		achievement_grid.add_child(badge)

func _create_achievement_badge(achievement: Dictionary) -> Control:
	## Create achievement badge UI element
	var container: PanelContainer = PanelContainer.new()
	container.custom_minimum_size = Vector2(48, 48)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)
	
	# Badge icon
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(32, 32)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load badge texture
	var badge_path: String = "res://assets/ui/badges/%s" % achievement.badge_file
	if ResourceLoader.exists(badge_path):
		texture_rect.texture = load(badge_path)
	
	# Grayscale if not unlocked
	if not achievement.unlocked:
		texture_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)
	
	vbox.add_child(texture_rect)
	
	# Tooltip
	container.tooltip_text = "%s\n%s" % [achievement.name, achievement.description]
	if achievement.unlocked:
		container.tooltip_text += "\n✅ Unlocked!"
	
	# Store achievement ID for click handling
	container.set_meta("achievement_id", achievement.id)
	
	return container

func _on_xp_gained(_amount: int, _reason: String) -> void:
	## Called when XP is gained
	_update_display()
	
	# Animate XP bar (optional)
	if xp_progress_bar:
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(xp_progress_bar, "value", xp_system.current_xp, 0.3)

func _on_level_up(new_level: int, _xp_needed_for_next: int) -> void:
	## Called when player levels up
	print("XPDisplayPanel: Level up to %d!" % new_level)
	_update_display()
	
	# Play level-up animation
	if level_label:
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(level_label, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(level_label, "scale", Vector2.ONE, 0.3)

func _on_achievement_unlocked(_achievement_id: String, _achievement_data: Dictionary) -> void:
	## Called when achievement is unlocked
	print("XPDisplayPanel: Achievement unlocked!")
	_populate_achievements()

func _on_reset_button_pressed() -> void:
	
	## Reset all XP stats - shows confirmation dialog
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to reset ALL XP stats?\n\nThis will:\n• Reset level to 1\n• Clear all XP progress\n• Remove all achievements\n• Clear boss battle history\n• Reset all lifetime stats\n\nThis action cannot be undone!"
	confirm_dialog.title = "Reset All Stats?"
	confirm_dialog.ok_button_text = "Reset Everything"
	confirm_dialog.cancel_button_text = "Cancel"
	
	# Apply Balatro theme
	var balatro_theme = preload("res://themes/balatro_ui_theme.tres")
	confirm_dialog.theme = balatro_theme
	
	# Add to scene tree
	add_child(confirm_dialog)
	
	# Connect confirmation signal
	confirm_dialog.confirmed.connect(func():
		if xp_system and xp_system.has_method("reset_all_stats"):
			xp_system.reset_all_stats()
			print("XPDisplayPanel: All stats reset")
		confirm_dialog.queue_free()
	)
	
	# Connect cancel/close
	confirm_dialog.canceled.connect(func(): confirm_dialog.queue_free())
	confirm_dialog.close_requested.connect(func(): confirm_dialog.queue_free())
	
	# Show dialog
	confirm_dialog.popup_centered()
