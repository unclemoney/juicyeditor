extends Node

@onready var visual_effects_manager: VisualEffectsManager = $VisualEffectsManager
@onready var text_editor: TextEdit = $UI/TextEditor  # Adjust path as needed
@onready var background_panel: Panel = $UI/BackgroundPanel  # Adjust path as needed

func _ready() -> void:
    # ...existing code...
    _setup_visual_effects()

func _setup_visual_effects() -> void:
    if visual_effects_manager:
        # Connect to effects updated signal
        visual_effects_manager.effects_updated.connect(_on_effects_updated)
        
        # Apply initial effects
        visual_effects_manager.apply_text_shadow(text_editor, true)
        visual_effects_manager.apply_gradient_background(background_panel, true)

func _on_effects_updated() -> void:
    # Refresh effects when settings change
    if visual_effects_manager and text_editor:
        visual_effects_manager.apply_text_shadow(text_editor, true)
        visual_effects_manager.apply_gradient_background(background_panel, true)