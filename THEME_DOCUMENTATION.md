# Theme System Documentation

## Overview

Juicy Editor now features an advanced theme system with live switching capabilities, custom fonts, and extensive visual effects. The system includes a new **Super Juicy Theme** that showcases the full potential of the editor's visual capabilities.

## Available Themes

### 🌈 Super Juicy Theme (NEW!)
- **Typography**: Custom National2Condensed fonts (Regular & Medium)
- **Colors**: Vibrant purple and pink color scheme with high contrast
- **Effects**: Enhanced shadows, outlines, gradients, and animations
- **Features**: Button scaling, hover effects, bounce animations, and pulse effects
- **Best For**: Fun creative writing and showcasing visual effects

### 🎨 Classic Juicy Theme
- **Typography**: Standard system fonts
- **Colors**: Balanced blue and purple tones
- **Effects**: Moderate visual effects and animations
- **Best For**: General use with visual flair

### 🌙 Dark Theme
- **Typography**: Clean system fonts
- **Colors**: Dark background with light text
- **Effects**: Minimal visual effects for focus
- **Best For**: Night-time coding and reading

### ☀️ Light Theme
- **Typography**: Standard readable fonts
- **Colors**: Light background with dark text
- **Effects**: Subtle visual enhancements
- **Best For**: Daytime use and professional writing

## How to Switch Themes

### Method 1: Settings Menu
1. Click **Settings** in the menu bar
2. Select **Switch Theme...**
3. Choose your desired theme from the dropdown
4. Click **Apply Theme**

### Method 2: Visual Preview
- The theme switcher dialog shows a live preview of each theme
- Font and color changes are visible immediately
- Preview shows the theme description and visual styling

## Theme Features Explained

### 🎯 Typography System
- **Editor Font**: Used for the main text editing area
- **UI Font**: Used for menus, buttons, and interface elements
- **Font Sizes**: Configurable editor and UI font sizes
- **Custom Fonts**: National2Condensed provides enhanced readability

### 🎨 Visual Effects
Each theme can enable/disable:
- **Text Shadows**: Adds depth to text with configurable color and offset
- **Outline Effects**: Creates text borders with customizable width and color
- **Gradient Backgrounds**: Multi-color background transitions
- **Button Animations**: Hover, press, and bounce effects
- **Pulse Effects**: Subtle animated highlights on UI elements

### 🎮 Animation System
- **Button Scale Effects**: Buttons grow slightly on hover (configurable)
- **Bounce Animations**: Interactive feedback on button presses
- **Animation Speed**: Customizable timing for all animations
- **Smooth Transitions**: Professional-quality easing and interpolation

## Custom Theme Creation

### Creating Your Own Theme
1. Copy an existing theme file from `/themes/` folder
2. Modify the color values, fonts, and effect settings
3. Save with a new filename (e.g., `my_theme.tres`)
4. The theme will automatically appear in the theme switcher

### Theme Properties Reference
```gdscript
# Basic Information
theme_name: String          # Display name in theme switcher
description: String         # Description shown in preview

# Color Scheme
background_color: Color     # Main editor background
text_color: Color          # Primary text color
selection_color: Color     # Text selection highlight
button_color: Color        # Default button background
menu_background_color: Color # Menu and dialog backgrounds

# Typography
editor_font: FontFile      # Font for text editor
ui_font: FontFile         # Font for UI elements
editor_font_size: int     # Size for editor text
ui_font_size: int        # Size for UI text

# Visual Effects
enable_text_shadows: bool     # Enable/disable shadows
enable_outline_effects: bool  # Enable/disable outlines
enable_gradient_backgrounds: bool # Enable/disable gradients
enable_pulse_effects: bool    # Enable/disable pulse animations
enable_bounce_effects: bool   # Enable/disable button bouncing
```

## Troubleshooting

### Theme Not Loading
- Ensure the theme file is properly formatted
- Check that font files exist and are correctly referenced
- Verify theme is saved in the `/themes/` directory

### Performance Issues
- Disable visual effects if experiencing lag
- Reduce animation speeds in theme settings
- Use simpler themes on lower-end hardware

### Font Issues
- Ensure font files are imported correctly in Godot
- Check that font UIDs match in theme resource files
- Verify font files exist in `/fonts/` directory

## Technical Implementation

### Theme Manager System
- **ThemeManager**: Central coordinator for theme application
- **JuicyTheme**: Resource definition for theme properties
- **UI Registration**: Elements register with theme manager for updates
- **Live Switching**: Themes apply instantly without restart

### File Structure
```
themes/
├── super_juicy_theme.tres    # Enhanced theme with custom fonts
├── juicy_theme.tres          # Original theme
├── dark_theme.tres           # Minimal dark theme
└── light_theme.tres          # Clean light theme

fonts/
├── National2Condensed-Regular.otf
└── National2Condensed-Medium.otf

scripts/components/
├── theme_manager.gd          # Theme system coordinator
└── juicy_theme.gd           # Theme resource definition
```

---

**Enjoy your new juicy theming experience!** 🎨✨