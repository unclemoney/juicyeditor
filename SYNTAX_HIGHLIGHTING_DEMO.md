# Juicy Editor - File Type Syntax Highlighting Demo

## How to Test the New Feature

1. **Open Juicy Editor** by running the project in Godot
2. **Switch between themes** using the Settings → Switch Theme menu
3. **Open the test files** in different formats:
   - `Test_GDScript.gd` - Shows GDScript-specific highlighting
   - `Test_Python.py` - Shows Python-specific highlighting  
   - `Test_Markdown.md` - Shows Markdown-specific highlighting
   - `Test_JSON.json` - Shows JSON-specific highlighting

## What to Look For

### GDScript Files (.gd)
- **func** keyword highlighted in theme-specific function color (dark red in dark theme, bright red in juicy themes)
- **class** and **signal** keywords with distinct colors
- Built-in types (Vector2, Color, Node) in specialized colors
- Traditional syntax highlighting for keywords, strings, comments

### Python Files (.py)
- **def** keyword highlighted in Python-specific function color
- **class** keyword with distinct class color
- **import** and **from** statements in import-specific color
- **@decorators** highlighted in decorator color

### Markdown Files (.md)
- **Headers** (#, ##, ###) in header-specific colors
- **Bold text** (**text**) and *italic text* with distinct formatting
- `Inline code` in code-specific color
- [Links](url) highlighted differently

### JSON Files (.json)
- **Keys** and **values** with distinct colors
- **Brackets** and **braces** with structural highlighting
- **Boolean values** (true, false, null) specially colored

## Theme Variations

### Dark Theme
- Professional dark colors with high contrast
- Traditional programming color scheme adapted for dark backgrounds

### Light Theme  
- Clean bright colors optimized for daylight use
- Subdued but clear color differentiation

### Juicy Theme
- Vibrant and playful colors
- Enhanced contrast and visual appeal

### Super Juicy Theme
- Ultra-vibrant maximum visual impact
- Extreme color saturation for bold aesthetics

## Live Theme Switching

The new system automatically updates syntax highlighting when you switch themes:
1. Open any of the test files
2. Go to Settings → Switch Theme
3. Select a different theme
4. Notice how the syntax colors immediately update to match the new theme

This creates a cohesive visual experience where syntax highlighting is perfectly integrated with your chosen theme!