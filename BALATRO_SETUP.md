# Balatro UI Theme - Quick Setup Guide

## What We Created

### 🎨 UI Assets (Generated with PixelLab AI)

#### Buttons (128x128px)
- `assets/ui/buttons/button_normal.png` - Default state
- `assets/ui/buttons/button_hover.png` - Hover/focus state  
- `assets/ui/buttons/button_pressed.png` - Pressed state

#### Panels (48x48px)
- `assets/ui/panels/panel_background.png` - General panel background
- `assets/ui/panels/button_panel_block.png` - Chunky block-style panel

#### Icons (64x64px)
- `assets/ui/icons/juicy_lucy_south.png` - Juicy Lucy mascot (south-facing)

### 📦 Theme File
- `themes/balatro_ui_theme.tres` - Complete Godot Theme resource with:
  - StyleBoxTexture for buttons (normal, hover, pressed, disabled)
  - StyleBoxTexture for panels
  - StyleBoxFlat for UI containers, tabs, popups
  - National2 font configuration
  - Comprehensive color palette

### 📚 Documentation
- `BALATRO_THEME.md` - Full theme documentation
- Updated `README.md` with Balatro theme and Juicy Lucy sections

## How to Use in Godot

### Method 1: Apply to Entire Scene (Recommended)

1. Open your scene in Godot (e.g., `scenes/main.tscn`)
2. Select the root Control node
3. In the Inspector, find the **Theme** property
4. Drag `themes/balatro_ui_theme.tres` into the Theme slot
5. **All child nodes automatically inherit the theme!**

This is already done in `scenes/main.tscn`.

### Method 2: Apply to Individual Nodes

If you only want specific buttons to use the Balatro style:

1. Select a Button node
2. In Inspector → Theme Overrides → Styles
3. Manually assign the StyleBoxTexture resources
4. Or set the Theme property on that specific node

### Method 3: Code-Based Application

```gdscript
# In your script
@onready var balatro_theme = preload("res://themes/balatro_ui_theme.tres")

func _ready():
	# Apply to entire UI tree
	theme = balatro_theme
	
	# Or apply to specific control
	$MyButton.theme = balatro_theme
```

## Testing the Theme

### In Godot Editor

1. **Open the Project**: Launch `project.godot` in Godot 4.4+
2. **Run the Scene**: Press F5 to run the main scene
3. **Check Buttons**: You should see large, chunky buttons with:
   - Pink/purple gradient appearance
   - Glossy, beveled edges
   - Smooth hover transitions
   - Depressed look when clicked

### What to Look For

✅ **Buttons should be noticeably larger** than before
✅ **Buttons should have texture** (not flat colors)
✅ **Hover effect** should make buttons glow brighter
✅ **Pressed state** should look depressed/darker
✅ **Font should be National2Condensed** at larger sizes (20px for buttons)
✅ **Panels should have soft rounded corners** with texture

## Customizing the Theme

### Changing Button Size

Buttons use 9-slice scaling. To make them bigger/smaller:

**Option A: In the Scene**
1. Select button node
2. Set `Custom Minimum Size` in Inspector
3. Example: `Vector2(150, 60)` for wider buttons

**Option B: In Code**
```gdscript
$MyButton.custom_minimum_size = Vector2(150, 60)
```

### Changing Button Colors

Edit `themes/balatro_ui_theme.tres`:

```gdresource
[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_button_normal"]
texture = ExtResource("1_button_normal")
modulate_color = Color(1.2, 1.0, 1.0, 1)  # More red
```

Tint options:
- `Color(1, 1, 1, 1)` - No tint (default)
- `Color(1.5, 1.0, 1.0, 1)` - Reddish tint
- `Color(1.0, 1.5, 1.0, 1)` - Greenish tint  
- `Color(1.0, 1.0, 1.5, 1)` - Bluish tint
- `Color(0.8, 0.8, 0.8, 1)` - Darker

### Changing Fonts

Already using National2:
- **Buttons/Labels**: National2Condensed-Medium at 20px
- **Code Editor**: National2Condensed-Regular at 18px

To adjust sizes, edit `balatro_ui_theme.tres`:

```gdresource
Button/font_sizes/font_size = 24  # Bigger buttons
Label/font_sizes/font_size = 20   # Bigger labels
```

## Adding Juicy Lucy Icons

### As Button Icon

```gdscript
# In Godot Editor
1. Select button
2. Inspector → Icon → Load
3. Choose `assets/ui/icons/juicy_lucy_south.png`

# In Code
var lucy_icon = preload("res://assets/ui/icons/juicy_lucy_south.png")
$MyButton.icon = lucy_icon
```

### As TextureRect

```gdscript
var lucy_texture = preload("res://assets/ui/icons/juicy_lucy_south.png")
var texture_rect = TextureRect.new()
texture_rect.texture = lucy_texture
add_child(texture_rect)
```

## Generating More Assets

### Using PixelLab MCP

All assets were created using the PixelLab AI service. To generate more:

#### More Buttons
```python
create_map_object(
	description='large chunky button for [specific purpose]',
	width=128,
	height=64,
	view='high top-down',
	outline='single color outline',
	shading='detailed shading'
)
```

#### More Panels
```python
create_isometric_tile(
	description='[your panel description]',
	size=48,
	tile_shape='thick tile',  # or 'block'
	outline='single color outline',
	shading='highly detailed shading'
)
```

#### More Lucy Variations
```python
create_character(
	description='anthropomorphic hamburger [doing specific action]',
	n_directions=4,  # or 8
	size=64,
	view='high top-down'
)
```

Then add animations:
```python
animate_character(
	character_id='[character_id_from_above]',
	template_animation_id='walk'  # or 'jumping', 'running', etc.
)
```

## Troubleshooting

### Theme Not Applying

**Issue**: Buttons still look flat/small
**Solution**: 
1. Verify theme is set on root Control node
2. Check that `.import` files exist in `assets/ui/` folders
3. Try reimporting: Right-click asset → Reimport

### Blurry/Pixelated Buttons

**Issue**: Assets look low quality
**Solution**:
1. Check import settings for button PNGs
2. Ensure `compress/mode=0` (lossless)
3. Ensure `mipmaps/generate=false`
4. Disable filtering for pixel-perfect look

### Buttons Too Small

**Issue**: Buttons haven't increased in size
**Solution**:
1. Theme only provides textures, not sizes
2. Set `custom_minimum_size` on buttons
3. Recommended: `Vector2(120, 50)` minimum

### Import Errors

**Issue**: Godot can't find assets
**Solution**:
1. Verify files exist in correct folders
2. Delete `.godot/imported/` folder
3. Restart Godot to force reimport
4. Check that UIDs in `.import` files match theme `.tres`

## File Checklist

Before running, ensure these files exist:

### Assets
- [ ] `assets/ui/buttons/button_normal.png`
- [ ] `assets/ui/buttons/button_normal.png.import`
- [ ] `assets/ui/buttons/button_hover.png`
- [ ] `assets/ui/buttons/button_hover.png.import`
- [ ] `assets/ui/buttons/button_pressed.png`
- [ ] `assets/ui/buttons/button_pressed.png.import`
- [ ] `assets/ui/panels/panel_background.png`
- [ ] `assets/ui/panels/panel_background.png.import`
- [ ] `assets/ui/icons/juicy_lucy_south.png`
- [ ] `assets/ui/icons/juicy_lucy_south.png.import`

### Theme
- [ ] `themes/balatro_ui_theme.tres`

### Scene
- [ ] `scenes/main.tscn` (updated with theme reference)

### Documentation
- [ ] `BALATRO_THEME.md`
- [ ] `README.md` (updated)

## Next Steps

1. **Test in Editor**: Run the project and verify buttons look chunky and juicy
2. **Adjust Sizes**: Set `custom_minimum_size` on buttons for desired appearance
3. **Generate More Lucy**: Create different poses/expressions with PixelLab
4. **Add Animations**: Use PixelLab to animate Lucy for splash screens
5. **Create Icons**: Generate file type icons featuring Lucy
6. **Expand Panels**: Create themed panels for dialogs, popups, tooltips

## Example Button Configuration

For toolbar buttons in `scenes/main.tscn`:

```gdscript
[node name="NewButton" type="Button" parent="VBoxContainer/TopBar/Toolbar"]
custom_minimum_size = Vector2(100, 45)
layout_mode = 2
text = "New"
icon = preload("res://assets/ui/icons/juicy_lucy_south.png")
```

This gives you:
- Large, chunky button (100x45 minimum)
- Balatro texture from theme
- National2 font from theme
- Lucy icon

## Resources

- **Full Documentation**: See `BALATRO_THEME.md`
- **UI Patterns**: See `UI_BUILDER.md`
- **PixelLab Docs**: Check PixelLab MCP server documentation
- **Godot Theme Docs**: https://docs.godotengine.org/en/stable/classes/class_theme.html
- **StyleBoxTexture Docs**: https://docs.godotengine.org/en/stable/classes/class_styleboxfakture.html

---

**Ready to make your UI JUICY!** 🍔✨
