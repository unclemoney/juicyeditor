# XP Display Panel Scene Setup Instructions

## Quick Setup in Godot Editor

### Step 1: Create the Scene

1. In Godot, click **Scene → New Scene**
2. Choose **Other Node** and select **PanelContainer** as root
3. Rename root node to `XPDisplayPanel`
4. Attach script: `res://scripts/ui/xp_display_panel.gd`

### Step 2: Build the Node Structure

Add nodes in this exact hierarchy:

```
PanelContainer (XPDisplayPanel) ← Root
└─ MarginContainer
   └─ VBoxContainer
      ├─ HBoxContainer (Name: "LevelContainer")
      │  └─ Label (Name: "LevelLabel")
      ├─ VBoxContainer (Name: "XPContainer")
      │  ├─ ProgressBar (Name: "XPProgressBar")
      │  └─ Label (Name: "XPLabel")
      └─ ScrollContainer
         └─ GridContainer (Name: "AchievementGrid")
```

### Step 3: Configure Node Properties

**MarginContainer:**
- Theme Overrides → Constants → Margin Left: 8
- Theme Overrides → Constants → Margin Right: 8
- Theme Overrides → Constants → Margin Top: 8
- Theme Overrides → Constants → Margin Bottom: 8

**VBoxContainer (main):**
- Theme Overrides → Constants → Separation: 4

**LevelLabel:**
- Text: "Level 1"
- Horizontal Alignment: Center
- Theme Overrides → Font Sizes → Font Size: 18
- Theme Overrides → Colors → Font Color: #FFD700 (gold)

**XPProgressBar:**
- Min Value: 0
- Max Value: 100
- Value: 0
- Show Percentage: false
- Custom Minimum Size: (200, 20)

**XPLabel:**
- Text: "0 / 100 XP"
- Horizontal Alignment: Center
- Theme Overrides → Font Sizes → Font Size: 12

**ScrollContainer:**
- Custom Minimum Size: (0, 150)
- Vertical Scroll Mode: Auto
- Horizontal Scroll Mode: Disabled

**AchievementGrid:**
- Columns: 5
- Theme Overrides → Constants → H Separation: 4
- Theme Overrides → Constants → V Separation: 4

### Step 4: Save the Scene

Save as: `res://scenes/ui/xp_display_panel.tscn`

### Step 5: Add to Main Scene

1. Open `res://scenes/main.tscn`
2. Find a suitable parent (e.g., UI container or HUD)
3. Right-click → **Instance Child Scene**
4. Select `xp_display_panel.tscn`
5. Position in top-right corner or desired location
6. Set anchor preset to "Top Right" or as needed

## Quick Alternative: Script-Based Scene Creation

If you prefer, you can use the helper script to create the scene programmatically:

1. Create a new GDScript file: `res://setup_xp_panel_scene.gd`
2. Copy the content from the helper script below
3. Attach it to any node in your scene
4. Run the scene - it will create the XP panel scene file
5. Delete the helper script after creation

## Visual Styling (Optional)

To make the panel look more "juicy":

**PanelContainer:**
- Add a StyleBox panel with rounded corners
- Background color: Semi-transparent dark (#000000AA)
- Border color: Gold (#FFD700)

**XPProgressBar:**
- Add custom StyleBox for fill (gold/yellow gradient)
- Add custom StyleBox for background (dark gray)

## Testing

After setup, the panel should:
- Display current level
- Show XP progress bar
- Display achievement badges (grayscale when locked)
- Update automatically when you type, save files, or gain XP

## Troubleshooting

**Panel not updating?**
- Check that XPSystem is in Autoload (Project Settings → Autoload)
- Verify script is attached to PanelContainer root node
- Check console for "XPDisplayPanel: Initialized and connected" message

**Badges not showing?**
- Verify badges exist in `res://assets/ui/badges/`
- Check badge filenames match achievement definitions in `xp_system.gd`
- Import settings: Check that .png files are imported as Texture2D

**Script errors?**
- Ensure all node names match exactly (case-sensitive)
- Use NodePaths like `$MarginContainer/VBoxContainer/LevelContainer/LevelLabel`
- Check that xp_display_panel.gd has no parsing errors
