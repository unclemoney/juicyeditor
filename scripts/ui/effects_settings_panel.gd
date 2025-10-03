extends Control
class_name EffectsSettingsPanel

# Juicy Editor - Effects Settings Panel
# Provides UI controls for configuring visual effects

signal effect_setting_changed(effect_name: String, property: String, value)
signal apply_settings()
signal reset_settings()

# Shadow controls
@onready var shadow_enabled: CheckBox = $ScrollContainer/VBoxContainer/ShadowGroup/ShadowEnabled
@onready var shadow_color: ColorPicker = $ScrollContainer/VBoxContainer/ShadowGroup/ShadowContainer/ShadowColor
@onready var shadow_offset_x: SpinBox = $ScrollContainer/VBoxContainer/ShadowGroup/ShadowContainer/OffsetX
@onready var shadow_offset_y: SpinBox = $ScrollContainer/VBoxContainer/ShadowGroup/ShadowContainer/OffsetY
@onready var shadow_blur: SpinBox = $ScrollContainer/VBoxContainer/ShadowGroup/ShadowContainer/BlurRadius

# Outline controls
@onready var outline_enabled: CheckBox = $ScrollContainer/VBoxContainer/OutlineGroup/OutlineEnabled
@onready var outline_color: ColorPicker = $ScrollContainer/VBoxContainer/OutlineGroup/OutlineContainer/OutlineColor
@onready var outline_width: SpinBox = $ScrollContainer/VBoxContainer/OutlineGroup/OutlineContainer/OutlineWidth
@onready var outline_smoothness: SpinBox = $ScrollContainer/VBoxContainer/OutlineGroup/OutlineContainer/OutlineSmoothness

# Gradient controls
@onready var gradient_enabled: CheckBox = $ScrollContainer/VBoxContainer/GradientGroup/GradientEnabled
@onready var gradient_start_color: ColorPicker = $ScrollContainer/VBoxContainer/GradientGroup/GradientContainer/StartColor
@onready var gradient_end_color: ColorPicker = $ScrollContainer/VBoxContainer/GradientGroup/GradientContainer/EndColor
@onready var gradient_direction_x: SpinBox = $ScrollContainer/VBoxContainer/GradientGroup/GradientContainer/DirectionX
@onready var gradient_direction_y: SpinBox = $ScrollContainer/VBoxContainer/GradientGroup/GradientContainer/DirectionY

# Action buttons
@onready var apply_button: Button = $ScrollContainer/VBoxContainer/ButtonContainer/ApplyButton
@onready var reset_button: Button = $ScrollContainer/VBoxContainer/ButtonContainer/ResetButton

var visual_effects_manager: Node

func _ready() -> void:
	_connect_signals()
	visual_effects_manager = get_node("/root/Main/VisualEffectsManager")

func _connect_signals() -> void:
	# Shadow signals
	if shadow_enabled:
		shadow_enabled.toggled.connect(_on_shadow_enabled_toggled)
	if shadow_color:
		shadow_color.color_changed.connect(_on_shadow_color_changed)
	if shadow_offset_x:
		shadow_offset_x.value_changed.connect(_on_shadow_offset_x_changed)
	if shadow_offset_y:
		shadow_offset_y.value_changed.connect(_on_shadow_offset_y_changed)
	if shadow_blur:
		shadow_blur.value_changed.connect(_on_shadow_blur_changed)
	
	# Outline signals
	if outline_enabled:
		outline_enabled.toggled.connect(_on_outline_enabled_toggled)
	if outline_color:
		outline_color.color_changed.connect(_on_outline_color_changed)
	if outline_width:
		outline_width.value_changed.connect(_on_outline_width_changed)
	if outline_smoothness:
		outline_smoothness.value_changed.connect(_on_outline_smoothness_changed)
	
	# Gradient signals
	if gradient_enabled:
		gradient_enabled.toggled.connect(_on_gradient_enabled_toggled)
	if gradient_start_color:
		gradient_start_color.color_changed.connect(_on_gradient_start_color_changed)
	if gradient_end_color:
		gradient_end_color.color_changed.connect(_on_gradient_end_color_changed)
	if gradient_direction_x:
		gradient_direction_x.value_changed.connect(_on_gradient_direction_x_changed)
	if gradient_direction_y:
		gradient_direction_y.value_changed.connect(_on_gradient_direction_y_changed)
	
	# Button signals
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)

# Shadow signal handlers
func _on_shadow_enabled_toggled(enabled: bool) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		visual_effects_manager.enable_effect("text_shadow", enabled)
	effect_setting_changed.emit("text_shadow", "enabled", enabled)

func _on_shadow_color_changed(color: Color) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_text_shadow"):
		var offset = Vector2(shadow_offset_x.value, shadow_offset_y.value)
		var blur = shadow_blur.value
		visual_effects_manager.configure_text_shadow(color, offset, blur)
	effect_setting_changed.emit("text_shadow", "color", color)

func _on_shadow_offset_x_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_text_shadow"):
		var offset = Vector2(value, shadow_offset_y.value)
		var color = shadow_color.color
		var blur = shadow_blur.value
		visual_effects_manager.configure_text_shadow(color, offset, blur)
	effect_setting_changed.emit("text_shadow", "offset_x", value)

func _on_shadow_offset_y_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_text_shadow"):
		var offset = Vector2(shadow_offset_x.value, value)
		var color = shadow_color.color
		var blur = shadow_blur.value
		visual_effects_manager.configure_text_shadow(color, offset, blur)
	effect_setting_changed.emit("text_shadow", "offset_y", value)

func _on_shadow_blur_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_text_shadow"):
		var offset = Vector2(shadow_offset_x.value, shadow_offset_y.value)
		var color = shadow_color.color
		visual_effects_manager.configure_text_shadow(color, offset, value)
	effect_setting_changed.emit("text_shadow", "blur", value)

# Outline signal handlers
func _on_outline_enabled_toggled(enabled: bool) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		visual_effects_manager.enable_effect("outline", enabled)
	effect_setting_changed.emit("outline", "enabled", enabled)

func _on_outline_color_changed(color: Color) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_outline"):
		visual_effects_manager.configure_outline(color, outline_width.value, outline_smoothness.value)
	effect_setting_changed.emit("outline", "color", color)

func _on_outline_width_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_outline"):
		visual_effects_manager.configure_outline(outline_color.color, value, outline_smoothness.value)
	effect_setting_changed.emit("outline", "width", value)

func _on_outline_smoothness_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_outline"):
		visual_effects_manager.configure_outline(outline_color.color, outline_width.value, value)
	effect_setting_changed.emit("outline", "smoothness", value)

# Gradient signal handlers
func _on_gradient_enabled_toggled(enabled: bool) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("enable_effect"):
		visual_effects_manager.enable_effect("gradient", enabled)
	effect_setting_changed.emit("gradient", "enabled", enabled)

func _on_gradient_start_color_changed(color: Color) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_gradient"):
		var direction = Vector2(gradient_direction_x.value, gradient_direction_y.value)
		visual_effects_manager.configure_gradient(color, gradient_end_color.color, direction)
	effect_setting_changed.emit("gradient", "start_color", color)

func _on_gradient_end_color_changed(color: Color) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_gradient"):
		var direction = Vector2(gradient_direction_x.value, gradient_direction_y.value)
		visual_effects_manager.configure_gradient(gradient_start_color.color, color, direction)
	effect_setting_changed.emit("gradient", "end_color", color)

func _on_gradient_direction_x_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_gradient"):
		var direction = Vector2(value, gradient_direction_y.value)
		visual_effects_manager.configure_gradient(gradient_start_color.color, gradient_end_color.color, direction)
	effect_setting_changed.emit("gradient", "direction_x", value)

func _on_gradient_direction_y_changed(value: float) -> void:
	if visual_effects_manager and visual_effects_manager.has_method("configure_gradient"):
		var direction = Vector2(gradient_direction_x.value, value)
		visual_effects_manager.configure_gradient(gradient_start_color.color, gradient_end_color.color, direction)
	effect_setting_changed.emit("gradient", "direction_y", value)

# Button signal handlers
func _on_apply_pressed() -> void:
	apply_settings.emit()
	# Close the panel after applying settings
	queue_free()

func _on_reset_pressed() -> void:
	reset_to_defaults()
	reset_settings.emit()

func reset_to_defaults() -> void:
	# Reset shadow settings
	if shadow_enabled:
		shadow_enabled.button_pressed = true
	if shadow_color:
		shadow_color.color = Color(0, 0, 0, 0.5)
	if shadow_offset_x:
		shadow_offset_x.value = 2.0
	if shadow_offset_y:
		shadow_offset_y.value = 2.0
	if shadow_blur:
		shadow_blur.value = 1.0
	
	# Reset outline settings
	if outline_enabled:
		outline_enabled.button_pressed = true
	if outline_color:
		outline_color.color = Color(1, 1, 1, 0.8)
	if outline_width:
		outline_width.value = 1.0
	if outline_smoothness:
		outline_smoothness.value = 0.1
	
	# Reset gradient settings
	if gradient_enabled:
		gradient_enabled.button_pressed = false
	if gradient_start_color:
		gradient_start_color.color = Color(0.1, 0.1, 0.1, 1.0)
	if gradient_end_color:
		gradient_end_color.color = Color(0.05, 0.05, 0.05, 1.0)
	if gradient_direction_x:
		gradient_direction_x.value = 0.0
	if gradient_direction_y:
		gradient_direction_y.value = 1.0

func load_settings_from_manager() -> void:
	if not visual_effects_manager:
		return
	
	# Load shadow settings
	if visual_effects_manager.has_method("get_effect_config"):
		var shadow_config = visual_effects_manager.get_effect_config("text_shadow")
		if shadow_config:
			if shadow_enabled:
				shadow_enabled.button_pressed = shadow_config.get("enabled", true)
			if shadow_color:
				shadow_color.color = shadow_config.get("color", Color.BLACK)
			if shadow_offset_x and shadow_offset_y:
				var offset = shadow_config.get("offset", Vector2(2, 2))
				shadow_offset_x.value = offset.x
				shadow_offset_y.value = offset.y
			if shadow_blur:
				shadow_blur.value = shadow_config.get("blur_radius", 1.0)
		
		# Load outline settings
		var outline_config = visual_effects_manager.get_effect_config("outline")
		if outline_config:
			if outline_enabled:
				outline_enabled.button_pressed = outline_config.get("enabled", true)
			if outline_color:
				outline_color.color = outline_config.get("color", Color.WHITE)
			if outline_width:
				outline_width.value = outline_config.get("width", 1.0)
			if outline_smoothness:
				outline_smoothness.value = outline_config.get("smoothness", 0.1)
		
		# Load gradient settings
		var gradient_config = visual_effects_manager.get_effect_config("gradient")
		if gradient_config:
			if gradient_enabled:
				gradient_enabled.button_pressed = gradient_config.get("enabled", false)
			if gradient_start_color:
				gradient_start_color.color = gradient_config.get("start_color", Color(0.1, 0.1, 0.1))
			if gradient_end_color:
				gradient_end_color.color = gradient_config.get("end_color", Color(0.05, 0.05, 0.05))
			if gradient_direction_x and gradient_direction_y:
				var direction = gradient_config.get("direction", Vector2(0, 1))
				gradient_direction_x.value = direction.x
				gradient_direction_y.value = direction.y