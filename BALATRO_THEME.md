# Balatro UI Theme Documentation

## Overview

The Balatro UI Theme brings cartoonishly large, juicy buttons with a poker-game aesthetic to Juicy Editor. Inspired by the card game Balatro, this theme features chunky, beveled buttons with glossy surfaces and vibrant colors.

## Theme Components

### 1. **Button Assets**
Located in `assets/ui/buttons/`:
- `button_normal.png` - Default button state (128x128px)
- `button_hover.png` - Bright, glowing hover state
- `button_pressed.png` - Depressed, darker pressed state

All buttons use **9-slice scaling** with 16px margins on all sides, allowing them to stretch to any size while maintaining crisp edges.

### 2. **Panel Assets**
Located in `assets/ui/panels/`:
- `panel_background.png` - Soft rounded panel background (48x48px)
- `button_panel_block.png` - Chunky block-style panel (48x48px)

Panels use 12px texture margins for 9-slice scaling.

### 3. **Icons & Mascot**
Located in `assets/ui/icons/`:
- `juicy_lucy_south.png` - Juicy Lucy, the hamburger mascot (64x64px)

**About Juicy Lucy:**
Lucy is an anthropomorphic hamburger character with:
- Sesame seed bun for a head
- Lettuce "hair"
- Cheese eyes with ketchup pupils
- A friendly smile
- Editor's visor cap

Future additions will include Lucy in different poses and animations.

## Typography

The theme uses the **National2 Condensed** font family:
- **UI Elements**: National2Condensed-Medium at 20px (buttons), 18px (labels)
- **Code Editor**: National2Condensed-Regular at 18px
- All fonts use increased spacing for better readability

## Color Palette

### Primary Colors
- **Background**: Deep purple `#261A33` (0.15, 0.1, 0.2)
- **Text**: Off-white `#F2E5FF` (0.95, 0.9, 1.0)
- **Accent**: Vibrant purple `#6640CC` (0.4, 0.25, 0.6)

### Button States
- **Normal**: Light purple `#40335A` (0.25, 0.2, 0.35)
- **Hover**: Bright purple `#6640CC` (0.4, 0.25, 0.6)
- **Pressed**: Deep purple `#9958CC` (0.6, 0.35, 0.8)
- **Disabled**: Grayed out at 60% opacity

### Syntax Highlighting
Maintains the vibrant Super Juicy color scheme with purples, pinks, and golds.

## Usage

### Applying the Theme

The theme is automatically applied to the Main scene:

```gdscript
# In scenes/main.tscn
[node name="Main" type="Control"]
theme = ExtResource("7_balatro_theme")
```

### Creating Custom Buttons

To create buttons that use the Balatro style:

1. **In the Scene Tree**: Add a `Button` node
2. **Theme Override**: The button will automatically inherit the theme
3. **Sizing**: Set minimum size to at least 100x40 for optimal appearance
4. **Text**: Use short, punchy labels (1-2 words)

Example in code:
```gdscript
var button = Button.new()
button.text = "Save"
button.custom_minimum_size = Vector2(120, 50)
add_child(button)
```

### Creating Custom Panels

For panel containers:

```gdscript
var panel = PanelContainer.new()
# Panel will use the textured background automatically
var label = Label.new()
label.text = "Panel Content"
panel.add_child(label)
```

## Asset Generation with PixelLab

All UI assets were generated using **PixelLab AI** via the MCP server:

### Button Generation
```python
# Normal state
create_map_object(
	description='large chunky button in normal state, rounded rectangular with thick beveled border',
	width=128, height=64,
	view='high top-down',
	outline='single color outline',
	shading='detailed shading'
)

# Hover state
create_map_object(
	description='large chunky button in hover state, glowing brighter with enhanced highlights',
	width=128, height=64,
	# ... same parameters
)

# Pressed state
create_map_object(
	description='large chunky button in pressed state, slightly depressed with darker shadows',
	width=128, height=64,
	# ... same parameters
)
```

### Panel Generation
```python
create_isometric_tile(
	description='juicy panel background with soft rounded corners',
	size=48,
	tile_shape='thick tile',
	outline='single color outline',
	shading='highly detailed shading'
)
```

### Character Generation
```python
create_character(
	description='cute anthropomorphic hamburger named Lucy with buns for head, lettuce hair, cheese eyes',
	n_directions=4,
	size=64,
	view='high top-down',
	outline='single color black outline'
)
```

## Customization

### Changing Button Colors

To modify button tint:

1. Open `themes/balatro_ui_theme.tres`
2. Find the `StyleBoxTexture` resources
3. Adjust the `modulate_color` property:

```gdresource
[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_button_normal"]
texture = ExtResource("1_button_normal")
modulate_color = Color(1.2, 1.0, 1.0, 1)  # Redder tint
```

### Adjusting Font Sizes

In `balatro_ui_theme.tres`:

```gdresource
Button/font_sizes/font_size = 22  # Increase from 20
Label/font_sizes/font_size = 20   # Increase from 18
```

### Custom Panel Backgrounds

To use different panel styles:

1. Generate new panel asset with PixelLab
2. Save to `assets/ui/panels/`
3. Update theme resource:

```gdresource
[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_panel"]
texture = ExtResource("new_panel_texture")
```

## Technical Details

### 9-Slice Scaling

All buttons and panels use **StyleBoxTexture** with texture margins:

- **Corners**: Never stretched (16px on each corner)
- **Edges**: Stretched horizontally or vertically
- **Center**: Stretched in both directions

This ensures crisp edges regardless of button size.

### Import Settings

All assets use these import settings:
- **Compression**: Lossless (mode 0)
- **Mipmaps**: Disabled
- **Alpha Processing**: Fix alpha border enabled
- **Filter**: Default (for sharp pixel art)

### Performance

- Theme resources are loaded once at startup
- Texture atlasing handled by Godot automatically
- No runtime shader compilation for buttons/panels
- Minimal draw calls due to batching

## Future Enhancements

### Planned Features
- [ ] Animated Lucy mascot for splash screen
- [ ] Icon variations for different file types
- [ ] Additional panel styles (warning, error, success)
- [ ] Themed scrollbars and sliders
- [ ] Custom checkbox and radio button sprites
- [ ] Lucy idle animations for status bar

### Additional Characters
- Lucy waving (greeting animation)
- Lucy thinking (processing indicator)
- Lucy celebrating (save success)
- Lucy sleeping (idle state)

## Troubleshooting

### Buttons Appear Stretched
- Check that `texture_margin_*` values are set correctly
- Ensure source images are power-of-2 dimensions or have proper margins

### Theme Not Applying
- Verify theme is set on root Control node
- Check that `.import` files exist for all assets
- Reimport assets in Godot if needed

### Blurry Buttons
- Disable mipmaps in import settings
- Use lossless compression (mode 0)
- Ensure `filter` is set to `false` for pixel art

## Credits

- **Theme Design**: Inspired by Balatro card game aesthetics
- **Asset Generation**: PixelLab AI (MCP Server)
- **Typography**: National2 Condensed font family
- **Mascot**: Juicy Lucy, the hamburger character

## References

- [Godot Theme Documentation](https://docs.godotengine.org/en/stable/classes/class_theme.html)
- [StyleBoxTexture Reference](https://docs.godotengine.org/en/stable/classes/class_styleboxfakture.html)
- [UI_BUILDER.md](../UI_BUILDER.md) - General UI building patterns
- [CropTails Reference](https://github.com/example/croptails) - Panel container patterns
