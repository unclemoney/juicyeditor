extends AcceptDialog
class_name SettingsDialog

# Juicy Editor - Settings Dialog
# Provides a comprehensive settings interface with tabs

signal settings_applied(settings: Dictionary)

@export var tab_container_path: NodePath
@export var apply_button_path: NodePath
@export var reset_button_path: NodePath

var tab_container: TabContainer
var apply_button: Button
var reset_button: Button

# Settings controls references
var text_settings: Dictionary = {}
var audio_settings: Dictionary = {}
var visual_settings: Dictionary = {}
var animation_settings: Dictionary = {}

var game_controller: GameController
var audio_manager: Node
var visual_effects_manager: Node
var animation_manager: Node
var typing_effects_manager: Node

func _ready() -> void:
	title = "Juicy Editor Settings"
	size = Vector2(600, 500)
	
	_initialize_node_references()
	_create_settings_tabs()
	_connect_signals()
	_load_current_settings()

func _initialize_node_references() -> void:
	# Get manager references
	game_controller = get_node("/root/GameController") if has_node("/root/GameController") else null
	audio_manager = get_node("/root/AudioManager") if has_node("/root/AudioManager") else null
	visual_effects_manager = get_node("/root/VisualEffectsManager") if has_node("/root/VisualEffectsManager") else null
	animation_manager = get_node("/root/AnimationManager") if has_node("/root/AnimationManager") else null
	typing_effects_manager = get_node("/root/TypingEffectsManager") if has_node("/root/TypingEffectsManager") else null
	
	# Initialize UI references
	tab_container = get_node_or_null(tab_container_path) if tab_container_path != NodePath() else null
	apply_button = get_node_or_null(apply_button_path) if apply_button_path != NodePath() else null
	reset_button = get_node_or_null(reset_button_path) if reset_button_path != NodePath() else null
	
	print("Settings Dialog - Node references initialized")

func _create_settings_tabs() -> void:
	if not tab_container:
		# Create tab container if not referenced
		tab_container = TabContainer.new()
		# Use the dialog's content area instead of adding directly
		var content_area = get_child(0)  # AcceptDialog's VBoxContainer
		if content_area:
			content_area.add_child(tab_container)
		else:
			add_child(tab_container)
		
		tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	_create_text_editor_tab()
	_create_audio_settings_tab()
	_create_visual_effects_tab()
	_create_animation_settings_tab()
	
	# Create buttons
	_create_dialog_buttons()

func _create_text_editor_tab() -> void:
	var text_tab = VBoxContainer.new()
	text_tab.name = "Text Editor"
	text_tab.mouse_filter = Control.MOUSE_FILTER_PASS
	tab_container.add_child(text_tab)
	
	# Font Size
	var font_size_group = HBoxContainer.new()
	font_size_group.mouse_filter = Control.MOUSE_FILTER_PASS
	text_tab.add_child(font_size_group)
	
	var font_size_label = Label.new()
	font_size_label.text = "Font Size:"
	font_size_label.custom_minimum_size.x = 120
	font_size_group.add_child(font_size_label)
	
	var font_size_spinbox = SpinBox.new()
	font_size_spinbox.min_value = 8
	font_size_spinbox.max_value = 72
	font_size_spinbox.value = 16
	font_size_spinbox.name = "font_size"
	font_size_group.add_child(font_size_spinbox)
	text_settings["font_size"] = font_size_spinbox
	
	# Theme Selection
	var theme_group = HBoxContainer.new()
	text_tab.add_child(theme_group)
	
	var theme_label = Label.new()
	theme_label.text = "Theme:"
	theme_label.custom_minimum_size.x = 120
	theme_group.add_child(theme_label)
	
	var theme_option = OptionButton.new()
	theme_option.add_item("Dark")
	theme_option.add_item("Light") 
	theme_option.add_item("Juicy")
	theme_option.name = "theme"
	theme_group.add_child(theme_option)
	text_settings["theme"] = theme_option
	
	# Line Numbers
	var line_numbers_check = CheckBox.new()
	line_numbers_check.text = "Show Line Numbers"
	line_numbers_check.name = "line_numbers"
	text_tab.add_child(line_numbers_check)
	text_settings["line_numbers"] = line_numbers_check
	
	# Word Wrap
	var word_wrap_check = CheckBox.new()
	word_wrap_check.text = "Enable Word Wrap"
	word_wrap_check.name = "word_wrap"
	text_tab.add_child(word_wrap_check)
	text_settings["word_wrap"] = word_wrap_check
	
	# Syntax Highlighting
	var syntax_check = CheckBox.new()
	syntax_check.text = "Enable Syntax Highlighting"
	syntax_check.name = "syntax_highlighting"
	text_tab.add_child(syntax_check)
	text_settings["syntax_highlighting"] = syntax_check

func _create_audio_settings_tab() -> void:
	var audio_tab = VBoxContainer.new()
	audio_tab.name = "Audio"
	tab_container.add_child(audio_tab)
	
	# Master Volume
	var master_volume_group = HBoxContainer.new()
	audio_tab.add_child(master_volume_group)
	
	var master_volume_label = Label.new()
	master_volume_label.text = "Master Volume:"
	master_volume_label.custom_minimum_size.x = 120
	master_volume_group.add_child(master_volume_label)
	
	var master_volume_slider = HSlider.new()
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.value = 0.8
	master_volume_slider.step = 0.1
	master_volume_slider.name = "master_volume"
	master_volume_group.add_child(master_volume_slider)
	
	var volume_value_label = Label.new()
	volume_value_label.text = "80%"
	volume_value_label.custom_minimum_size.x = 40
	master_volume_group.add_child(volume_value_label)
	master_volume_slider.value_changed.connect(_on_volume_changed.bind(volume_value_label))
	
	audio_settings["master_volume"] = master_volume_slider
	
	# UI Sounds
	var ui_sounds_check = CheckBox.new()
	ui_sounds_check.text = "Enable UI Sounds"
	ui_sounds_check.name = "ui_sounds"
	audio_tab.add_child(ui_sounds_check)
	audio_settings["ui_sounds"] = ui_sounds_check
	
	# Typing Sounds
	var typing_sounds_check = CheckBox.new()
	typing_sounds_check.text = "Enable Typing Sounds"
	typing_sounds_check.name = "typing_sounds"
	audio_tab.add_child(typing_sounds_check)
	audio_settings["typing_sounds"] = typing_sounds_check
	
	# Sound Volume
	var sound_volume_group = HBoxContainer.new()
	audio_tab.add_child(sound_volume_group)
	
	var sound_volume_label = Label.new()
	sound_volume_label.text = "Sound Effects Volume:"
	sound_volume_label.custom_minimum_size.x = 150
	sound_volume_group.add_child(sound_volume_label)
	
	var sound_volume_slider = HSlider.new()
	sound_volume_slider.min_value = 0.0
	sound_volume_slider.max_value = 1.0
	sound_volume_slider.value = 0.6
	sound_volume_slider.step = 0.1
	sound_volume_slider.name = "sound_volume"
	sound_volume_group.add_child(sound_volume_slider)
	
	var sound_value_label = Label.new()
	sound_value_label.text = "60%"
	sound_value_label.custom_minimum_size.x = 40
	sound_volume_group.add_child(sound_value_label)
	sound_volume_slider.value_changed.connect(_on_volume_changed.bind(sound_value_label))
	
	audio_settings["sound_volume"] = sound_volume_slider

func _create_visual_effects_tab() -> void:
	var visual_tab = VBoxContainer.new()
	visual_tab.name = "Visual Effects"
	tab_container.add_child(visual_tab)
	
	# Enable Visual Effects
	var visual_effects_check = CheckBox.new()
	visual_effects_check.text = "Enable Visual Effects"
	visual_effects_check.name = "visual_effects"
	visual_tab.add_child(visual_effects_check)
	visual_settings["visual_effects"] = visual_effects_check
	
	# Glow Effects
	var glow_check = CheckBox.new()
	glow_check.text = "Enable Glow Effects"
	glow_check.name = "glow_effects"
	visual_tab.add_child(glow_check)
	visual_settings["glow_effects"] = glow_check
	
	# Pulse Effects
	var pulse_check = CheckBox.new()
	pulse_check.text = "Enable Pulse Effects"
	pulse_check.name = "pulse_effects"
	visual_tab.add_child(pulse_check)
	visual_settings["pulse_effects"] = pulse_check
	
	# Effect Intensity
	var intensity_group = HBoxContainer.new()
	visual_tab.add_child(intensity_group)
	
	var intensity_label = Label.new()
	intensity_label.text = "Effect Intensity:"
	intensity_label.custom_minimum_size.x = 120
	intensity_group.add_child(intensity_label)
	
	var intensity_slider = HSlider.new()
	intensity_slider.min_value = 0.1
	intensity_slider.max_value = 2.0
	intensity_slider.value = 1.0
	intensity_slider.step = 0.1
	intensity_slider.name = "effect_intensity"
	intensity_group.add_child(intensity_slider)
	
	var intensity_value_label = Label.new()
	intensity_value_label.text = "100%"
	intensity_value_label.custom_minimum_size.x = 50
	intensity_group.add_child(intensity_value_label)
	intensity_slider.value_changed.connect(_on_intensity_changed.bind(intensity_value_label))
	
	visual_settings["effect_intensity"] = intensity_slider

func _create_animation_settings_tab() -> void:
	var animation_tab = VBoxContainer.new()
	animation_tab.name = "Animations"
	tab_container.add_child(animation_tab)
	
	# Enable Animations
	var animations_check = CheckBox.new()
	animations_check.text = "Enable Animations"
	animations_check.name = "animations"
	animation_tab.add_child(animations_check)
	animation_settings["animations"] = animations_check
	
	# Create a separator
	var separator1 = HSeparator.new()
	animation_tab.add_child(separator1)
	
	# Typing Effects Section
	var typing_effects_label = Label.new()
	typing_effects_label.text = "Typing Effects"
	typing_effects_label.add_theme_font_size_override("font_size", 18)
	animation_tab.add_child(typing_effects_label)
	
	# Typing Animations
	var typing_animations_check = CheckBox.new()
	typing_animations_check.text = "Enable Typing Animations"
	typing_animations_check.name = "typing_animations"
	animation_tab.add_child(typing_animations_check)
	animation_settings["typing_animations"] = typing_animations_check
	
	# Flying Letters on Deletion
	var flying_letters_check = CheckBox.new()
	flying_letters_check.text = "Enable Flying Letters (Deletion)"
	flying_letters_check.name = "flying_letters"
	animation_tab.add_child(flying_letters_check)
	animation_settings["flying_letters"] = flying_letters_check
	
	# Deletion Explosions
	var deletion_explosions_check = CheckBox.new()
	deletion_explosions_check.text = "Enable Deletion Explosions"
	deletion_explosions_check.name = "deletion_explosions"
	animation_tab.add_child(deletion_explosions_check)
	animation_settings["deletion_explosions"] = deletion_explosions_check
	
	# Sparkle Effects on Typing
	var sparkle_effects_check = CheckBox.new()
	sparkle_effects_check.text = "Enable Sparkle Effects (Typing)"
	sparkle_effects_check.name = "sparkle_effects"
	animation_tab.add_child(sparkle_effects_check)
	animation_settings["sparkle_effects"] = sparkle_effects_check
	
	# Effect Intensity
	var intensity_group = HBoxContainer.new()
	animation_tab.add_child(intensity_group)
	
	var intensity_label = Label.new()
	intensity_label.text = "Effect Intensity:"
	intensity_label.custom_minimum_size.x = 120
	intensity_group.add_child(intensity_label)
	
	var intensity_slider = HSlider.new()
	intensity_slider.min_value = 0.1
	intensity_slider.max_value = 3.0
	intensity_slider.value = 1.0
	intensity_slider.step = 0.1
	intensity_slider.name = "effect_intensity"
	intensity_group.add_child(intensity_slider)
	
	var intensity_value_label = Label.new()
	intensity_value_label.text = "100%"
	intensity_value_label.custom_minimum_size.x = 50
	intensity_group.add_child(intensity_value_label)
	intensity_slider.value_changed.connect(_on_intensity_changed.bind(intensity_value_label))
	
	animation_settings["effect_intensity"] = intensity_slider
	
	# Add a separator
	var separator2 = HSeparator.new()
	animation_tab.add_child(separator2)
	
	# General Animation Settings Section
	var general_label = Label.new()
	general_label.text = "General Animation Settings"
	general_label.add_theme_font_size_override("font_size", 18)
	animation_tab.add_child(general_label)
	
	# Cursor Animations
	var cursor_animations_check = CheckBox.new()
	cursor_animations_check.text = "Enable Cursor Animations"
	cursor_animations_check.name = "cursor_animations"
	animation_tab.add_child(cursor_animations_check)
	animation_settings["cursor_animations"] = cursor_animations_check
	
	# Button Animations
	var button_animations_check = CheckBox.new()
	button_animations_check.text = "Enable Button Animations"
	button_animations_check.name = "button_animations"
	animation_tab.add_child(button_animations_check)
	animation_settings["button_animations"] = button_animations_check
	
	# Animation Speed
	var speed_group = HBoxContainer.new()
	animation_tab.add_child(speed_group)
	
	var speed_label = Label.new()
	speed_label.text = "Animation Speed:"
	speed_label.custom_minimum_size.x = 120
	speed_group.add_child(speed_label)
	
	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.25
	speed_slider.max_value = 3.0
	speed_slider.value = 1.0
	speed_slider.step = 0.25
	speed_slider.name = "animation_speed"
	speed_group.add_child(speed_slider)
	
	var speed_value_label = Label.new()
	speed_value_label.text = "100%"
	speed_value_label.custom_minimum_size.x = 50
	speed_group.add_child(speed_value_label)
	speed_slider.value_changed.connect(_on_speed_changed.bind(speed_value_label))
	
	animation_settings["animation_speed"] = speed_slider
	
	# Add real-time preview connection for typing effects
	if typing_animations_check:
		typing_animations_check.toggled.connect(_on_typing_effect_setting_changed)
	if flying_letters_check:
		flying_letters_check.toggled.connect(_on_typing_effect_setting_changed)
	if deletion_explosions_check:
		deletion_explosions_check.toggled.connect(_on_typing_effect_setting_changed)
	if sparkle_effects_check:
		sparkle_effects_check.toggled.connect(_on_typing_effect_setting_changed)
	if intensity_slider:
		intensity_slider.value_changed.connect(_on_typing_effect_intensity_changed)

func _create_dialog_buttons() -> void:
	# Use AcceptDialog's built-in button system
	get_ok_button().text = "Close"
	
	# Add custom buttons to the dialog
	reset_button = add_button("Reset to Defaults", false, "reset")
	apply_button = add_button("Apply", false, "apply")
	
	# Connect custom button signals
	custom_action.connect(_on_custom_button_pressed)

func _connect_signals() -> void:
	# AcceptDialog custom buttons are already connected in _create_dialog_buttons
	pass

func _on_custom_button_pressed(action: String) -> void:
	match action:
		"apply":
			_on_apply_pressed()
		"reset":
			_on_reset_pressed()

func _load_current_settings() -> void:
	if not game_controller:
		return
	
	# Load text editor settings
	if "font_size" in game_controller.editor_settings and text_settings.has("font_size"):
		text_settings["font_size"].value = game_controller.editor_settings.font_size
	
	if "theme" in game_controller.editor_settings and text_settings.has("theme"):
		var theme_name = game_controller.editor_settings.theme
		match theme_name:
			"dark": text_settings["theme"].selected = 0
			"light": text_settings["theme"].selected = 1
			"juicy": text_settings["theme"].selected = 2
	
	if "line_numbers" in game_controller.editor_settings and text_settings.has("line_numbers"):
		text_settings["line_numbers"].button_pressed = game_controller.editor_settings.line_numbers
	
	if "word_wrap" in game_controller.editor_settings and text_settings.has("word_wrap"):
		text_settings["word_wrap"].button_pressed = game_controller.editor_settings.word_wrap
	
	if "syntax_highlighting" in game_controller.editor_settings and text_settings.has("syntax_highlighting"):
		text_settings["syntax_highlighting"].button_pressed = game_controller.editor_settings.syntax_highlighting
	
	# Load audio settings
	if "master_volume" in game_controller.editor_settings and audio_settings.has("master_volume"):
		audio_settings["master_volume"].value = game_controller.editor_settings.master_volume
	
	if "ui_sounds" in game_controller.editor_settings and audio_settings.has("ui_sounds"):
		audio_settings["ui_sounds"].button_pressed = game_controller.editor_settings.ui_sounds
	
	if "typing_sounds" in game_controller.editor_settings and audio_settings.has("typing_sounds"):
		audio_settings["typing_sounds"].button_pressed = game_controller.editor_settings.typing_sounds
	
	if "sound_volume" in game_controller.editor_settings and audio_settings.has("sound_volume"):
		audio_settings["sound_volume"].value = game_controller.editor_settings.sound_volume
	
	# Load visual effects settings
	if "visual_effects" in game_controller.editor_settings and visual_settings.has("visual_effects"):
		visual_settings["visual_effects"].button_pressed = game_controller.editor_settings.visual_effects
	
	if "glow_effects" in game_controller.editor_settings and visual_settings.has("glow_effects"):
		visual_settings["glow_effects"].button_pressed = game_controller.editor_settings.glow_effects
	
	if "pulse_effects" in game_controller.editor_settings and visual_settings.has("pulse_effects"):
		visual_settings["pulse_effects"].button_pressed = game_controller.editor_settings.pulse_effects
	
	if "effect_intensity" in game_controller.editor_settings and visual_settings.has("effect_intensity"):
		visual_settings["effect_intensity"].value = game_controller.editor_settings.effect_intensity
	
	# Load animation settings
	if "animations" in game_controller.editor_settings and animation_settings.has("animations"):
		animation_settings["animations"].button_pressed = game_controller.editor_settings.animations
	
	if "typing_animations" in game_controller.editor_settings and animation_settings.has("typing_animations"):
		animation_settings["typing_animations"].button_pressed = game_controller.editor_settings.typing_animations
	
	if "flying_letters" in game_controller.editor_settings and animation_settings.has("flying_letters"):
		animation_settings["flying_letters"].button_pressed = game_controller.editor_settings.flying_letters
	
	if "deletion_explosions" in game_controller.editor_settings and animation_settings.has("deletion_explosions"):
		animation_settings["deletion_explosions"].button_pressed = game_controller.editor_settings.deletion_explosions
	
	if "sparkle_effects" in game_controller.editor_settings and animation_settings.has("sparkle_effects"):
		animation_settings["sparkle_effects"].button_pressed = game_controller.editor_settings.sparkle_effects
	
	if "effect_intensity" in game_controller.editor_settings and animation_settings.has("effect_intensity"):
		animation_settings["effect_intensity"].value = game_controller.editor_settings.effect_intensity
	
	if "cursor_animations" in game_controller.editor_settings and animation_settings.has("cursor_animations"):
		animation_settings["cursor_animations"].button_pressed = game_controller.editor_settings.cursor_animations
	
	if "button_animations" in game_controller.editor_settings and animation_settings.has("button_animations"):
		animation_settings["button_animations"].button_pressed = game_controller.editor_settings.button_animations
	
	if "animation_speed" in game_controller.editor_settings and animation_settings.has("animation_speed"):
		animation_settings["animation_speed"].value = game_controller.editor_settings.animation_speed

func _on_apply_pressed() -> void:
	var new_settings = _collect_settings()
	settings_applied.emit(new_settings)
	
	# Apply settings immediately to managers
	_apply_settings_to_managers(new_settings)
	
	print("Settings applied: ", new_settings)

func _on_reset_pressed() -> void:
	_reset_to_defaults()

func _collect_settings() -> Dictionary:
	var settings = {}
	
	# Text editor settings
	if text_settings.has("font_size"):
		settings.font_size = text_settings["font_size"].value
	
	if text_settings.has("theme"):
		var themes = ["dark", "light", "juicy"]
		settings.theme = themes[text_settings["theme"].selected]
	
	if text_settings.has("line_numbers"):
		settings.line_numbers = text_settings["line_numbers"].button_pressed
	
	if text_settings.has("word_wrap"):
		settings.word_wrap = text_settings["word_wrap"].button_pressed
	
	if text_settings.has("syntax_highlighting"):
		settings.syntax_highlighting = text_settings["syntax_highlighting"].button_pressed
	
	# Audio settings
	if audio_settings.has("master_volume"):
		settings.master_volume = audio_settings["master_volume"].value
	
	if audio_settings.has("ui_sounds"):
		settings.ui_sounds = audio_settings["ui_sounds"].button_pressed
	
	if audio_settings.has("typing_sounds"):
		settings.typing_sounds = audio_settings["typing_sounds"].button_pressed
	
	if audio_settings.has("sound_volume"):
		settings.sound_volume = audio_settings["sound_volume"].value
	
	# Visual effects settings
	if visual_settings.has("visual_effects"):
		settings.visual_effects = visual_settings["visual_effects"].button_pressed
	
	if visual_settings.has("glow_effects"):
		settings.glow_effects = visual_settings["glow_effects"].button_pressed
	
	if visual_settings.has("pulse_effects"):
		settings.pulse_effects = visual_settings["pulse_effects"].button_pressed
	
	if visual_settings.has("effect_intensity"):
		settings.effect_intensity = visual_settings["effect_intensity"].value
	
	# Animation settings
	if animation_settings.has("animations"):
		settings.animations = animation_settings["animations"].button_pressed
	
	if animation_settings.has("typing_animations"):
		settings.typing_animations = animation_settings["typing_animations"].button_pressed
	
	if animation_settings.has("flying_letters"):
		settings.flying_letters = animation_settings["flying_letters"].button_pressed
	
	if animation_settings.has("deletion_explosions"):
		settings.deletion_explosions = animation_settings["deletion_explosions"].button_pressed
	
	if animation_settings.has("sparkle_effects"):
		settings.sparkle_effects = animation_settings["sparkle_effects"].button_pressed
	
	if animation_settings.has("effect_intensity"):
		settings.effect_intensity = animation_settings["effect_intensity"].value
	
	if animation_settings.has("cursor_animations"):
		settings.cursor_animations = animation_settings["cursor_animations"].button_pressed
	
	if animation_settings.has("button_animations"):
		settings.button_animations = animation_settings["button_animations"].button_pressed
	
	if animation_settings.has("animation_speed"):
		settings.animation_speed = animation_settings["animation_speed"].value
	
	return settings

func _apply_settings_to_managers(settings: Dictionary) -> void:
	# Apply audio settings
	if audio_manager:
		if "master_volume" in settings:
			audio_manager.set_master_volume(settings.master_volume)
		if "ui_sounds" in settings:
			audio_manager.set_ui_sounds_enabled(settings.ui_sounds)
		if "typing_sounds" in settings:
			audio_manager.set_typing_sounds_enabled(settings.typing_sounds)
		if "sound_volume" in settings:
			audio_manager.set_sound_volume(settings.sound_volume)
	
	# Apply animation settings
	if animation_manager:
		if "animations" in settings:
			animation_manager.enable_transition_animations = settings.animations
		if "typing_animations" in settings:
			animation_manager.enable_typing_animations = settings.typing_animations
		if "cursor_animations" in settings:
			animation_manager.enable_cursor_animations = settings.cursor_animations
		if "deletion_explosions" in settings:
			animation_manager.explosion_config.enabled = settings.deletion_explosions
		if "animation_speed" in settings:
			animation_manager.animation_speed_multiplier = settings.animation_speed
	
	# Apply typing effects settings
	if typing_effects_manager:
		if "typing_animations" in settings:
			typing_effects_manager.set_typing_effects_enabled(settings.typing_animations)
		if "flying_letters" in settings:
			typing_effects_manager.set_flying_letters_enabled(settings.flying_letters)
		if "deletion_explosions" in settings:
			typing_effects_manager.set_deletion_explosions_enabled(settings.deletion_explosions)
		if "sparkle_effects" in settings:
			typing_effects_manager.set_sparkle_effects_enabled(settings.sparkle_effects)
		if "effect_intensity" in settings:
			typing_effects_manager.set_effect_intensity(settings.effect_intensity)

func _reset_to_defaults() -> void:
	# Reset text editor settings
	if text_settings.has("font_size"):
		text_settings["font_size"].value = 16
	if text_settings.has("theme"):
		text_settings["theme"].selected = 0  # Dark theme
	if text_settings.has("line_numbers"):
		text_settings["line_numbers"].button_pressed = true
	if text_settings.has("word_wrap"):
		text_settings["word_wrap"].button_pressed = false
	if text_settings.has("syntax_highlighting"):
		text_settings["syntax_highlighting"].button_pressed = true
	
	# Reset audio settings
	if audio_settings.has("master_volume"):
		audio_settings["master_volume"].value = 0.8
	if audio_settings.has("ui_sounds"):
		audio_settings["ui_sounds"].button_pressed = true
	if audio_settings.has("typing_sounds"):
		audio_settings["typing_sounds"].button_pressed = true
	if audio_settings.has("sound_volume"):
		audio_settings["sound_volume"].value = 0.6
	
	# Reset visual effects settings
	if visual_settings.has("visual_effects"):
		visual_settings["visual_effects"].button_pressed = true
	if visual_settings.has("glow_effects"):
		visual_settings["glow_effects"].button_pressed = true
	if visual_settings.has("pulse_effects"):
		visual_settings["pulse_effects"].button_pressed = true
	if visual_settings.has("effect_intensity"):
		visual_settings["effect_intensity"].value = 1.0
	
	# Reset animation settings
	if animation_settings.has("animations"):
		animation_settings["animations"].button_pressed = true
	if animation_settings.has("typing_animations"):
		animation_settings["typing_animations"].button_pressed = true
	if animation_settings.has("flying_letters"):
		animation_settings["flying_letters"].button_pressed = true
	if animation_settings.has("deletion_explosions"):
		animation_settings["deletion_explosions"].button_pressed = true
	if animation_settings.has("sparkle_effects"):
		animation_settings["sparkle_effects"].button_pressed = true
	if animation_settings.has("effect_intensity"):
		animation_settings["effect_intensity"].value = 1.0
	if animation_settings.has("cursor_animations"):
		animation_settings["cursor_animations"].button_pressed = true
	if animation_settings.has("button_animations"):
		animation_settings["button_animations"].button_pressed = true
	if animation_settings.has("animation_speed"):
		animation_settings["animation_speed"].value = 1.0

func _on_volume_changed(value: float, label: Label) -> void:
	label.text = str(int(value * 100)) + "%"

func _on_intensity_changed(value: float, label: Label) -> void:
	label.text = str(int(value * 100)) + "%"

func _on_speed_changed(value: float, label: Label) -> void:
	label.text = str(int(value * 100)) + "%"

# Real-time preview functions for typing effects
func _on_typing_effect_setting_changed(_enabled: bool) -> void:
	"""Handle real-time preview of typing effect setting changes"""
	if typing_effects_manager:
		# Apply current settings immediately for preview
		_apply_typing_effects_settings()

func _on_typing_effect_intensity_changed(value: float) -> void:
	"""Handle real-time preview of effect intensity changes"""
	if typing_effects_manager:
		typing_effects_manager.set_effect_intensity(value)

func _apply_typing_effects_settings() -> void:
	"""Apply current typing effects settings to the manager for real-time preview"""
	if not typing_effects_manager:
		return
	
	# Get current checkbox states safely
	var typing_enabled = true
	var flying_enabled = true
	var explosions_enabled = true
	var sparkles_enabled = true
	var intensity = 1.0
	
	if animation_settings.has("typing_animations") and animation_settings["typing_animations"]:
		typing_enabled = animation_settings["typing_animations"].button_pressed
	
	if animation_settings.has("flying_letters") and animation_settings["flying_letters"]:
		flying_enabled = animation_settings["flying_letters"].button_pressed
		
	if animation_settings.has("deletion_explosions") and animation_settings["deletion_explosions"]:
		explosions_enabled = animation_settings["deletion_explosions"].button_pressed
		
	if animation_settings.has("sparkle_effects") and animation_settings["sparkle_effects"]:
		sparkles_enabled = animation_settings["sparkle_effects"].button_pressed
		
	if animation_settings.has("effect_intensity") and animation_settings["effect_intensity"]:
		intensity = animation_settings["effect_intensity"].value
	
	# Apply settings to typing effects manager
	typing_effects_manager.set_typing_effects_enabled(typing_enabled)
	typing_effects_manager.set_flying_letters_enabled(flying_enabled)
	typing_effects_manager.set_deletion_explosions_enabled(explosions_enabled)
	typing_effects_manager.set_sparkle_effects_enabled(sparkles_enabled)
	typing_effects_manager.set_effect_intensity(intensity)
