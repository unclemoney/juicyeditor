# UI Builder Workflow Documentation

> A comprehensive guide for building polished UI systems in Godot 4.4+ using theme resources, PanelContainers, and AI-generated assets via Pixel Lab.

---

## Table of Contents

1. [Overview](#overview)
2. [CropTails UI Analysis](#croptails-ui-analysis)
3. [Pixel Lab Integration](#pixel-lab-integration)
4. [UI Architecture Patterns](#ui-architecture-patterns)
5. [Theme System](#theme-system)
6. [Building UI Components](#building-ui-components)
7. [Best Practices](#best-practices)
8. [Complete Workflow](#complete-workflow)

---

## Overview

This document outlines the proven patterns and workflows for creating professional-grade UI in Godot 4.4+, inspired by the CropTails farming simulator and enhanced with AI-assisted asset generation from Pixel Lab.

### Key Principles

- **Theme-based styling**: Centralized visual consistency through `.tres` theme resources
- **Signal-driven architecture**: UI components emit signals; logic handled by controllers
- **Component composition**: Build complex UIs from simple, reusable PanelContainers
- **AI-assisted assets**: Use Pixel Lab MCP for generating UI graphics on-demand
- **Separation of concerns**: UI scenes are presentation-only; business logic lives in Autoload managers

---

## CropTails UI Analysis

### UI File Structure

The CropTails project demonstrates clean UI organization:

```
scenes/ui/
├── game_ui_theme.tres          # Centralized theme resource
├── inventory_panel.tscn         # Component: inventory display
├── inventory_panel.gd           # Script: updates labels from InventoryManager
├── tools_panel.tscn             # Component: tool selection buttons
├── tools_panel.gd               # Script: emits signals to ToolManager
├── day_and_night_panel.tscn     # Component: time display + speed controls
└── day_and_night_panel.gd       # Script: listens to DayAndNightCycleManager
```

### Core UI Patterns Observed

#### 1. **PanelContainer-Based Layouts**

All UI panels extend `PanelContainer` for consistent backgrounds:

```gdscript
extends PanelContainer

@onready var label: Label = $MarginContainer/VBoxContainer/Label
```

**Structure**:
- Root: `PanelContainer` (provides styled background)
- Child: `MarginContainer` (adds padding)
- Inner: `VBoxContainer` or `HBoxContainer` (organizes content)
- Content: `Label`, `Button`, `TextureRect`, etc.

#### 2. **Signal-Driven Updates**

UI scripts never modify game state directly—they listen to Autoload signals:

```gdscript
# inventory_panel.gd
func _ready() -> void:
	InventoryManager.inventory_changed.connect(on_inventory_changed)

func on_inventory_changed() -> void:
	var inventory: Dictionary = InventoryManager.inventory
	
	if inventory.has("log"):
		log_label.text = str(inventory["log"])
```

#### 3. **Button Signal Emissions**

Buttons emit actions via Autoload managers:

```gdscript
# tools_panel.gd
func _on_tool_axe_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.AxeWood)
```

#### 4. **Node Path Organization**

Labels and buttons are referenced via `@onready` with full paths:

```gdscript
@onready var day_label: Label = $DayPanel/MarginContainer/DayLabel
@onready var time_label: Label = $TimePanel/MarginContainer/TimeLabel
```

---

## Pixel Lab Integration

### What is Pixel Lab?

Pixel Lab is an **MCP (Model Context Protocol) server** that generates pixel art assets directly from your AI coding assistant. It's designed for **non-blocking** operations—you submit requests instantly, get job IDs, and assets process in the background (2-5 minutes).

### Available Tools for UI Development

#### 1. **Isometric Tiles** (Best for UI Backgrounds)

```gdscript
# Example: Generate custom panel backgrounds
create_isometric_tile(
	description='wooden panel with decorative frame',
	size=32,
	tile_shape='block',  # Full-height cube
	outline='single color',
	detail='highly detailed'
)
```

**Use cases**:
- Custom panel backgrounds
- Button textures
- Icon backgrounds
- Decorative UI elements

#### 2. **Map Objects** (For UI Icons)

```gdscript
# Example: Generate UI icons
create_map_object(
	description='gold coin icon',
	width=24,
	height=24,
	view='high top-down',
	outline='single color outline'
)
```

**Use cases**:
- Currency/resource icons
- Tool icons
- Achievement badges
- Status indicators

#### 3. **Characters** (For Avatars/NPCs)

```gdscript
# Example: Generate character portraits
create_character(
	description='friendly merchant portrait',
	n_directions=4,
	size=64,
	proportions='{"type": "preset", "name": "cartoon"}'
)
```

**Use cases**:
- Player avatars
- NPC portraits in dialogue
- Character selection screens

### Pixel Lab Workflow Pattern

```gdscript
# 1. Submit creation request (returns immediately)
var result = create_map_object(
	description='inventory slot background',
	width=48,
	height=48
)
var object_id = result.object_id

# 2. Check status later (in a separate method)
func check_asset_status(object_id: String) -> void:
	var status = get_map_object(object_id)
	if status.status == 'completed':
		# Download and integrate asset
		var download_url = status.download_url
		# Use download_url to fetch the asset
```

### Integration with Godot UI

1. **Generate assets** via Pixel Lab MCP
2. **Download** to `res://ui/textures/` or `res://themes/assets/`
3. **Import** into Godot (auto-imports as `.import` files)
4. **Reference** in theme resources or directly in scenes
5. **Apply** to StyleBoxTexture, Button icons, or TextureRect nodes

---

## UI Architecture Patterns

### 1. Manager-Based Communication

**Autoload Managers** (no `class_name`, signals only):

```gdscript
# scripts/managers/ui_manager.gd
extends Node

signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)
signal notification_shown(message: String, type: String)

var active_panels: Array[String] = []

func open_panel(panel_name: String) -> void:
	if panel_name not in active_panels:
		active_panels.append(panel_name)
		panel_opened.emit(panel_name)

func close_panel(panel_name: String) -> void:
	active_panels.erase(panel_name)
	panel_closed.emit(panel_name)
```

### 2. UI Component Template

**Scene Structure**:
```
PanelContainer (Root)
└── MarginContainer
    └── VBoxContainer
        ├── Label (Title)
        ├── HSeparator
        └── HBoxContainer (Content)
            ├── Button
            └── Label
```

**Script Template**:

```gdscript
extends PanelContainer
class_name UIPanel

## The base class for all UI panels in Juicy Editor.
## Panels should be self-contained and communicate via signals.

## Emitted when the panel requests to be closed.
signal close_requested

@export var panel_title: String = "Panel"
@export var closeable: bool = true

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	_setup_ui()
	_connect_signals()

## Sets up initial UI state.
func _setup_ui() -> void:
	if title_label:
		title_label.text = panel_title
	
	if close_button:
		close_button.visible = closeable

## Connects internal signals.
func _connect_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	close_requested.emit()
```

### 3. Theme Resource Structure

**Theme File**: `themes/ui_theme.tres`

Key properties to customize:
- **Button**: Normal, Hover, Pressed, Focus styles
- **PanelContainer**: Background panel StyleBox
- **Label**: Font, font size, color
- **LineEdit**: Background, border, font
- **HSeparator/VSeparator**: Thickness, color

**StyleBox Types**:
- `StyleBoxFlat`: Solid colors, borders, corner radius
- `StyleBoxTexture`: Image-based (use Pixel Lab assets)
- `StyleBoxLine`: Simple lines for separators

---

## Theme System

### Creating a Theme Resource

1. **Create Theme File**:
   - Right-click in FileSystem → New Resource → Theme
   - Save as `themes/juicy_ui_theme.tres`

2. **Configure Base Styles**:
   - Click the theme resource in Inspector
   - Add Type → Select control type (Button, PanelContainer, etc.)
   - Override → Select property (styles, colors, fonts)

3. **Button Example**:

```
Theme
└── Button
    ├── Styles
    │   ├── normal → StyleBoxFlat (bg: #3a3a3a, border: 2px)
    │   ├── hover → StyleBoxFlat (bg: #4a4a4a)
    │   ├── pressed → StyleBoxFlat (bg: #2a2a2a)
    │   └── focus → StyleBoxFlat (border: #00aaff)
    ├── Colors
    │   ├── font_color → #ffffff
    │   └── font_hover_color → #ffff00
    └── Fonts
        └── font → res://fonts/National2Condensed-Medium.otf
```

### Applying Themes

#### Method 1: Scene-wide
```gdscript
# In main UI scene root
@export var ui_theme: Theme

func _ready() -> void:
	theme = ui_theme
```

#### Method 2: Per-component
```gdscript
# In individual panel
@export var panel_theme: Theme

func _ready() -> void:
	theme = panel_theme
```

### Dynamic Theme Switching

```gdscript
# theme_manager.gd (Autoload)
extends Node

const DARK_THEME = preload("res://themes/dark_theme.tres")
const LIGHT_THEME = preload("res://themes/light_theme.tres")

signal theme_changed(new_theme: Theme)

var current_theme: Theme = DARK_THEME

func set_theme(theme_name: String) -> void:
	match theme_name:
		"dark":
			current_theme = DARK_THEME
		"light":
			current_theme = LIGHT_THEME
	
	theme_changed.emit(current_theme)
```

**UI responds to theme changes**:

```gdscript
# In UI panels
func _ready() -> void:
	ThemeManager.theme_changed.connect(_on_theme_changed)
	theme = ThemeManager.current_theme

func _on_theme_changed(new_theme: Theme) -> void:
	theme = new_theme
```

---

## Building UI Components

### Example 1: Settings Panel

**Scene**: `scenes/ui/settings_panel.tscn`

```
PanelContainer (settings_panel)
└── MarginContainer
    └── VBoxContainer
        ├── Label ("Settings")
        ├── HSeparator
        ├── HBoxContainer (Theme Switcher)
        │   ├── Label ("Theme:")
        │   └── OptionButton (theme_options)
        ├── HBoxContainer (Volume)
        │   ├── Label ("Volume:")
        │   └── HSlider (volume_slider)
        └── Button ("Close")
```

**Script**: `scripts/ui/settings_panel.gd`

```gdscript
extends PanelContainer

signal closed

@onready var theme_options: OptionButton = $MarginContainer/VBoxContainer/ThemeSwitcher/ThemeOptions
@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/Volume/VolumeSlider
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	_populate_theme_options()
	_connect_signals()

func _populate_theme_options() -> void:
	theme_options.clear()
	theme_options.add_item("Dark")
	theme_options.add_item("Light")
	theme_options.add_item("Juicy")
	theme_options.add_item("Super Juicy")

func _connect_signals() -> void:
	theme_options.item_selected.connect(_on_theme_selected)
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(_on_close_pressed)

func _on_theme_selected(index: int) -> void:
	var theme_name = theme_options.get_item_text(index).to_lower().replace(" ", "_")
	ThemeManager.set_theme(theme_name)

func _on_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
```

### Example 2: Notification Toast

**Scene**: `scenes/ui/notification_toast.tscn`

```
PanelContainer (toast_panel)
└── MarginContainer
    └── HBoxContainer
        ├── TextureRect (icon)
        └── Label (message)
```

**Script**: `scripts/ui/notification_toast.gd`

```gdscript
extends PanelContainer

@export var display_duration: float = 3.0
@export var fade_duration: float = 0.5

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/Icon
@onready var message_label: Label = $MarginContainer/HBoxContainer/Message

var tween: Tween

func show_notification(text: String, icon_texture: Texture2D = null) -> void:
	message_label.text = text
	
	if icon_texture:
		icon.texture = icon_texture
		icon.visible = true
	else:
		icon.visible = false
	
	modulate.a = 0.0
	_fade_in()
	
	await get_tree().create_timer(display_duration).timeout
	_fade_out()

func _fade_in() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func _fade_out() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(queue_free)
```

### Example 3: Toolbar

**Scene**: `scenes/ui/toolbar.tscn`

```
HBoxContainer (toolbar)
├── Button (new_file)
├── Button (open_file)
├── Button (save_file)
├── VSeparator
├── Button (undo)
├── Button (redo)
└── Button (settings)
```

**Script**: `scripts/ui/toolbar.gd`

```gdscript
extends HBoxContainer

signal action_triggered(action_name: String)

@onready var new_file_btn: Button = $NewFile
@onready var open_file_btn: Button = $OpenFile
@onready var save_file_btn: Button = $SaveFile
@onready var undo_btn: Button = $Undo
@onready var redo_btn: Button = $Redo
@onready var settings_btn: Button = $Settings

func _ready() -> void:
	_connect_button_signals()
	_setup_tooltips()

func _connect_button_signals() -> void:
	new_file_btn.pressed.connect(func(): action_triggered.emit("new_file"))
	open_file_btn.pressed.connect(func(): action_triggered.emit("open_file"))
	save_file_btn.pressed.connect(func(): action_triggered.emit("save_file"))
	undo_btn.pressed.connect(func(): action_triggered.emit("undo"))
	redo_btn.pressed.connect(func(): action_triggered.emit("redo"))
	settings_btn.pressed.connect(func(): action_triggered.emit("settings"))

func _setup_tooltips() -> void:
	new_file_btn.tooltip_text = "New File (Ctrl+N)"
	open_file_btn.tooltip_text = "Open File (Ctrl+O)"
	save_file_btn.tooltip_text = "Save File (Ctrl+S)"
	undo_btn.tooltip_text = "Undo (Ctrl+Z)"
	redo_btn.tooltip_text = "Redo (Ctrl+Y)"
	settings_btn.tooltip_text = "Settings"

## Updates button states based on available actions.
func update_button_states(can_undo: bool, can_redo: bool) -> void:
	undo_btn.disabled = not can_undo
	redo_btn.disabled = not can_redo
```

---

## Best Practices

### 1. **Scene Organization**

```
scenes/ui/
├── panels/              # Full-screen or modal panels
│   ├── settings_panel.tscn
│   └── file_browser.tscn
├── components/          # Reusable UI widgets
│   ├── toolbar.tscn
│   └── notification_toast.tscn
└── dialogs/             # Popup confirmations
    ├── confirm_dialog.tscn
    └── error_dialog.tscn
```

### 2. **Naming Conventions**

- **Scenes**: `snake_case.tscn` (e.g., `settings_panel.tscn`)
- **Scripts**: Match scene name (e.g., `settings_panel.gd`)
- **Class Names**: `PascalCase` (e.g., `class_name SettingsPanel`)
- **Nodes**: `PascalCase` (e.g., `CloseButton`, `VolumeSlider`)
- **Variables**: `snake_case` (e.g., `@onready var close_button`)

### 3. **Signal Architecture**

**UI emits upward**:
```gdscript
signal close_requested
signal action_triggered(action: String)
signal value_changed(new_value: Variant)
```

**Managers broadcast downward**:
```gdscript
# In Autoload
signal state_updated(new_state: Dictionary)
signal theme_changed(theme: Theme)
```

**Never call UI methods directly from managers**—use signals.

### 4. **Exported Properties for Customization**

```gdscript
@export_group("Appearance")
@export var panel_title: String = "Panel"
@export var show_close_button: bool = true
@export var custom_theme: Theme

@export_group("Behavior")
@export var closeable_by_escape: bool = true
@export var auto_hide_delay: float = 0.0
```

### 5. **Responsive Layouts**

Use containers that adapt to screen size:
- `VBoxContainer` / `HBoxContainer`: Auto-arrange children
- `MarginContainer`: Consistent padding
- `CenterContainer`: Center content
- `SplitContainer`: Resizable panels
- `ScrollContainer`: Scrollable content

Anchor presets for full-screen UIs:
- Set Control → Layout → Anchors Preset → Full Rect

### 6. **Accessibility**

- **Tooltips**: Add `tooltip_text` to all buttons
- **Focus**: Test keyboard navigation with Tab
- **Contrast**: Ensure text is readable against backgrounds
- **Font sizes**: Use `@export` to allow customization

---

## Complete Workflow

### Step 1: Plan UI Component

1. Sketch or wireframe the layout
2. Identify reusable elements
3. Define signals and data flow
4. List required assets (icons, backgrounds)

### Step 2: Generate Assets with Pixel Lab

```gdscript
# Example: Generate button backgrounds
var button_bg = create_isometric_tile(
	description='glossy button background with slight bevel',
	size=32,
	tile_shape='thin',
	outline='lineless',
	detail='highly detailed'
)

# Example: Generate icons
var save_icon = create_map_object(
	description='floppy disk save icon',
	width=24,
	height=24,
	view='high top-down',
	outline='single color outline'
)
```

Wait 2-5 minutes, then download assets via `get_*` tools.

### Step 3: Create Theme Resource

1. Create `themes/custom_ui_theme.tres`
2. Add control types (Button, PanelContainer, Label)
3. Import Pixel Lab assets as textures
4. Create `StyleBoxTexture` resources using imported textures
5. Assign StyleBoxes to theme properties

### Step 4: Build Scene Hierarchy

```
PanelContainer (root)
└── MarginContainer (padding: 10px all sides)
    └── VBoxContainer (separation: 5px)
        ├── Label (title)
        ├── HSeparator
        └── [Your content nodes]
```

### Step 5: Write Script

```gdscript
extends PanelContainer

## Brief description of panel purpose.

## Signals for parent/manager communication.
signal action_performed(action_name: String)

@export var panel_config: Dictionary = {}

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_listen_to_managers()

func _setup_ui() -> void:
	# Initialize UI state
	pass

func _connect_signals() -> void:
	# Connect child node signals
	pass

func _listen_to_managers() -> void:
	# Connect to Autoload signals
	pass
```

### Step 6: Integrate into Main Scene

```gdscript
# In game_controller.gd or main.gd
@onready var ui_layer: CanvasLayer = $UILayer

var settings_panel_scene = preload("res://scenes/ui/settings_panel.tscn")

func open_settings() -> void:
	var panel = settings_panel_scene.instantiate()
	panel.closed.connect(_on_settings_closed)
	ui_layer.add_child(panel)

func _on_settings_closed() -> void:
	# Panel queues itself for deletion on close
	pass
```

### Step 7: Test and Iterate

1. **Visual**: Check theme consistency, alignment, spacing
2. **Functional**: Test all buttons, sliders, inputs
3. **Signals**: Verify communication with managers
4. **Responsive**: Test at different window sizes
5. **Accessibility**: Keyboard navigation, tooltips

---

## Advanced Patterns

### Dynamic Panel Spawning

```gdscript
# ui_manager.gd (Autoload)
extends Node

var panel_scenes: Dictionary = {
	"settings": preload("res://scenes/ui/panels/settings_panel.tscn"),
	"inventory": preload("res://scenes/ui/panels/inventory_panel.tscn"),
	"crafting": preload("res://scenes/ui/panels/crafting_panel.tscn"),
}

var active_panels: Dictionary = {}

signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)

func open_panel(panel_name: String, parent: Node) -> void:
	if active_panels.has(panel_name):
		return  # Already open
	
	var scene = panel_scenes.get(panel_name)
	if not scene:
		push_error("Panel not found: " + panel_name)
		return
	
	var panel = scene.instantiate()
	panel.name = panel_name
	active_panels[panel_name] = panel
	parent.add_child(panel)
	
	if panel.has_signal("close_requested"):
		panel.close_requested.connect(func(): close_panel(panel_name))
	
	panel_opened.emit(panel_name)

func close_panel(panel_name: String) -> void:
	var panel = active_panels.get(panel_name)
	if panel:
		panel.queue_free()
		active_panels.erase(panel_name)
		panel_closed.emit(panel_name)

func toggle_panel(panel_name: String, parent: Node) -> void:
	if active_panels.has(panel_name):
		close_panel(panel_name)
	else:
		open_panel(panel_name, parent)
```

### Modal Dialogs

```gdscript
# dialog_manager.gd (Autoload)
extends Node

signal dialog_confirmed(dialog_id: String)
signal dialog_cancelled(dialog_id: String)

var dialog_scene = preload("res://scenes/ui/dialogs/confirm_dialog.tscn")
var active_dialog: Control = null

func show_confirm_dialog(
	title: String,
	message: String,
	confirm_text: String = "OK",
	cancel_text: String = "Cancel",
	dialog_id: String = ""
) -> void:
	if active_dialog:
		return  # Only one dialog at a time
	
	var dialog = dialog_scene.instantiate()
	dialog.set_dialog_properties(title, message, confirm_text, cancel_text)
	dialog.confirmed.connect(func(): _on_dialog_confirmed(dialog_id))
	dialog.cancelled.connect(func(): _on_dialog_cancelled(dialog_id))
	
	get_tree().root.add_child(dialog)
	active_dialog = dialog

func _on_dialog_confirmed(dialog_id: String) -> void:
	dialog_confirmed.emit(dialog_id)
	_close_active_dialog()

func _on_dialog_cancelled(dialog_id: String) -> void:
	dialog_cancelled.emit(dialog_id)
	_close_active_dialog()

func _close_active_dialog() -> void:
	if active_dialog:
		active_dialog.queue_free()
		active_dialog = null
```

---

## Pixel Lab Asset Management

### Recommended Folder Structure

```
ui/
├── textures/
│   ├── buttons/
│   │   ├── button_normal.png
│   │   ├── button_hover.png
│   │   └── button_pressed.png
│   ├── panels/
│   │   ├── panel_bg.png
│   │   └── panel_border.png
│   └── icons/
│       ├── save_icon.png
│       ├── load_icon.png
│       └── settings_icon.png
└── generated_assets/
    └── [Pixel Lab downloads]
```

### Asset Generation Script Template

```gdscript
# scripts/tools/generate_ui_assets.gd
extends Node

## Automates UI asset generation via Pixel Lab MCP.
## Run this script to queue asset creation, then check status manually.

var pending_assets: Array[Dictionary] = []

func _ready() -> void:
	generate_all_ui_assets()

func generate_all_ui_assets() -> void:
	# Buttons
	pending_assets.append(_create_button_asset("normal", "flat button"))
	pending_assets.append(_create_button_asset("hover", "highlighted button"))
	pending_assets.append(_create_button_asset("pressed", "pressed button"))
	
	# Icons
	pending_assets.append(_create_icon("save", "floppy disk"))
	pending_assets.append(_create_icon("load", "folder opening"))
	pending_assets.append(_create_icon("settings", "gear icon"))
	
	print("Asset generation queued. IDs:")
	for asset in pending_assets:
		print("  - ", asset.name, ": ", asset.id)

func _create_button_asset(state: String, description: String) -> Dictionary:
	var result = create_isometric_tile(
		description=description + " background",
		size=32,
		tile_shape='thin',
		outline='lineless'
	)
	return {"name": "button_" + state, "id": result.tile_id, "type": "tile"}

func _create_icon(name: String, description: String) -> Dictionary:
	var result = create_map_object(
		description=description + " icon",
		width=24,
		height=24,
		view='high top-down'
	)
	return {"name": name + "_icon", "id": result.object_id, "type": "object"}
```

---

## Conclusion

This workflow combines:
1. **Proven UI patterns** from CropTails (PanelContainers, signal architecture)
2. **AI-assisted asset generation** via Pixel Lab (buttons, icons, backgrounds)
3. **Godot best practices** (themes, containers, separation of concerns)

### Quick Reference Checklist

- [ ] Plan component structure and signals
- [ ] Generate assets with Pixel Lab (if needed)
- [ ] Create/update theme resource
- [ ] Build scene hierarchy with containers
- [ ] Write script with signal handlers
- [ ] Test visual consistency and functionality
- [ ] Integrate with managers via signals
- [ ] Document exported properties

### Next Steps

1. **Create base UI theme**: `themes/juicy_ui_base.tres`
2. **Build toolbar component**: `scenes/ui/components/toolbar.tscn`
3. **Implement settings panel**: `scenes/ui/panels/settings_panel.tscn`
4. **Set up UIManager Autoload**: `scripts/managers/ui_manager.gd`
5. **Generate initial assets**: Use Pixel Lab for icons and panel backgrounds

---

**Last Updated**: November 11, 2025  
**Godot Version**: 4.4+  
**References**: CropTails UI (ifeasome/CropTails), Pixel Lab MCP Documentation
