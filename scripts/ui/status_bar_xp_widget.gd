extends HBoxContainer
class_name StatusBarXPWidget

## Compact XP widget for status bar
## Shows when main XP panel is hidden

## Level label
@onready var level_label: Label = $LevelLabel

## Mini XP progress bar
@onready var xp_mini_bar: ProgressBar = $XPMiniBar

## Reference to XP System
var xp_system: Node = null

## Reference to main XP panel
var xp_panel: Control = null

func _ready() -> void:
	# Get XP System autoload
	xp_system = get_node("/root/XPSystem") if has_node("/root/XPSystem") else null
	
	if xp_system:
		# Connect XP system signals
		xp_system.xp_gained.connect(_on_xp_gained)
		xp_system.level_up.connect(_on_level_up)
		
		# Initialize display
		_update_display()
		print("StatusBarXPWidget: Initialized and connected")
	else:
		push_error("StatusBarXPWidget: XP System autoload not found")
	
	# Find main XP panel and connect to visibility signal
	call_deferred("_connect_to_xp_panel")

func _connect_to_xp_panel() -> void:
	## Connect to main XP panel visibility
	xp_panel = get_node_or_null("/root/Main/XPDisplayPanel")
	if xp_panel:
		# Set initial visibility based on panel state
		visible = not xp_panel.visible
		print("StatusBarXPWidget: Connected to XP panel, initial visibility=", visible)
		# Monitor panel visibility changes
		xp_panel.visibility_changed.connect(_sync_with_panel)

func _update_display() -> void:
	## Update level and XP display
	if not xp_system:
		return
	
	# Update level label
	if level_label:
		level_label.text = "Lvl: %d" % xp_system.current_level
	
	# Update mini XP bar
	if xp_mini_bar:
		var xp_needed: int = xp_system.get_xp_for_next_level()
		if xp_needed > 0:
			xp_mini_bar.max_value = xp_needed
			xp_mini_bar.value = xp_system.current_xp
		else:
			xp_mini_bar.max_value = 100
			xp_mini_bar.value = 100

func _on_xp_gained(_amount: int, _reason: String) -> void:
	## Called when XP is gained
	_update_display()
	
	# Animate XP bar
	if xp_mini_bar:
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(xp_mini_bar, "value", xp_system.current_xp, 0.3)

func _on_level_up(_new_level: int, _xp_needed_for_next: int) -> void:
	## Called when player levels up
	_update_display()
	
	# Brief flash animation
	if level_label:
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(level_label, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(level_label, "scale", Vector2.ONE, 0.2)

func _sync_with_panel() -> void:
	## Show widget when panel is hidden, hide when panel is visible
	if xp_panel:
		visible = not xp_panel.visible
		print("StatusBarXPWidget: Visibility synced to ", visible, " (panel is ", xp_panel.visible, ")")
