# Juicy Editor

A lightweight, standalone text editor built with Godot 4.4 that focuses on delightful user experience through visual and audio feedback.

## 🎯 Project Vision

Juicy Editor combines the functionality of a basic text editor with satisfying visual effects and audio feedback, creating an enjoyable writing experience. Unlike traditional text editors, every interaction provides feedback through carefully crafted sounds, animations, and visual effects.

## ✨ Key Features

### Core Functionality
- ✅ **Text Editing**: Full-featured text editing with cursor movement and text selection
- ✅ **File Operations**: Open, Save, Save As, and New file functionality
- ✅ **Multi-File Tabs**: Open and switch between multiple files using a tab system with file name display
- ✅ **Tab Management**: Close individual tabs, create new tabs, and switch between open files seamlessly
- ✅ **File Association Support**: Open files directly from Windows file association and command line arguments
- ✅ **Multiple File Opening**: Support for opening multiple files simultaneously via command line or file association
- ✅ **Syntax Highlighting**: File type-specific syntax highlighting for GDScript, Python, Markdown, and JSON with theme-aware colors
- ✅ **Markdown Checklists**: Quick keyboard shortcuts to add `[ ]` or toggle to `[X]` with themed colors
- ✅ **Theme-Aware Highlighting**: Each theme provides unique color schemes for different programming languages and file types
- ✅ **Find & Replace**: Comprehensive search and replace with case sensitivity and whole word options
- ✅ **Go to Line**: Quick navigation to specific line numbers
- ✅ **Line Numbers**: Configurable line number display
- ✅ **Word Wrap**: Toggle word wrapping on/off
- ✅ **Zoom Controls**: Zoom in/out and reset zoom functionality with 10% increments (20%-300% range)
- ✅ **Dynamic Zoom Buttons**: Toolbar buttons for Zoom In, Zoom Out, and percentage reset (100%) with live percentage display
- ✅ **Synchronized Scaling**: Line numbers automatically scale with text editor zoom for perfect alignment
- ✅ **Text Statistics**: Character, word, line, and paragraph counting

### Juicy Elements
- ✅ **Audio Feedback**: Typing sounds, button clicks, hover sounds with volume controls
- ✅ **Visual Effects**: Shader-based text shadows, outlines, gradient backgrounds with real-time configuration
- ✅ **Animations**: Character typing animations, cursor pulse, button interactions, smooth transitions
- ✅ **Themes**: Dark, Light, Super Juicy, and Balatro UI themes with custom National2Condensed fonts and visual effect integration
- ✅ **Balatro UI Theme**: Cartoonishly large, juicy buttons with poker-game aesthetics featuring Juicy Lucy the hamburger mascot
- ✅ **Theme Switching**: Live theme switching through Settings menu with preview functionality
- ✅ **Custom Fonts**: Integration of National2Condensed Regular and Medium fonts for enhanced typography
- ✅ **Juicy Lucy Assistant**: Animated Clippy-style assistant with eye tracking, expressive eyebrows, and witty commentary to encourage and entertain

### Juicy Lucy Features
Inspired by Microsoft's Clippy from the 1990s and early 2000s, Juicy Lucy is your friendly text editor companion:
- **Eye Tracking**: Lucy's pupils procedurally follow your mouse cursor around the screen
- **Expressive Eyebrows**: Procedurally generated Line2D eyebrows that animate to show different emotions (happy, surprised, concerned, skeptical, curious, upset)
- **Witty Commentary**: Lucy occasionally comments on your typing with fun phrases like "Did you really mean to type that?" or "Maybe you should save the file, because I'm not going to do it for you."
- **Spell Checking**: Lucy watches for spelling mistakes as you type and calls you out after 2-3 seconds of inactivity with delightfully sassy messages like "You didn't spell '%s' correctly, you dumb bitch." She'll also suggest corrections!
- **Smart Detection**: Lucy uses the SymSpell algorithm with a comprehensive English frequency dictionary to detect misspellings quickly and accurately
- **Non-Intrusive Checking**: Spell checking only triggers after you stop typing for 2-3 seconds, so Lucy won't interrupt your flow
- **No Visual Clutter**: Lucy doesn't highlight misspelled words - she just tells you about them with her signature sass
- **Encouragement**: Lucy provides positive reinforcement when you save files and complete tasks
- **BBCode Animations**: Lucy's dialog box uses RichTextLabel with BBCode effects for juicy animated text
- **Context-Aware**: Lucy detects different situations (typing, idle, deleting, long lines, spelling errors) and responds appropriately
- **Non-Intrusive**: Lucy appears in the lower right corner and her commentary is timed to be helpful, not annoying

### Quality of Life
- ✅ **Settings Persistence**: Comprehensive settings with tabbed interface for all preferences
- ✅ **Keyboard Shortcuts**: Standard shortcuts (Ctrl+N, Ctrl+O, Ctrl+S, Ctrl+F, Ctrl+G, etc.)
- ✅ **Recent Files**: Quick access to recently opened files (up to 10)
- ✅ **Error Handling**: Robust file operation error handling
- ✅ **Animation Controls**: Scale reset functionality and proper state management

## 🖥️ User Interface

### Layout Design
The Juicy Editor features a clean, efficient layout optimized for productivity:

- **Top Bar**: Menu bar and toolbar are combined in a single horizontal row to save vertical space
- **Tab System**: File tabs are prominently displayed below the top bar, showing the name of each open file
- **Main Area**: The text editor takes up the majority of the screen space with line numbers on the left
- **Status Bar**: Current cursor position and file information displayed at the bottom

### Tab System Features
- **Multiple Files**: Open and edit multiple files simultaneously
- **Visual Indicators**: Modified files are marked with an asterisk (*) in the tab title
- **Easy Navigation**: Click on tabs to switch between files instantly
- **Close Buttons**: Each tab has a close button (×) for easy tab management
- **File State Preservation**: Each tab remembers its cursor position, scroll location, and content

### File Association Features
- **Windows Integration**: Associate file types with Juicy Editor to open files directly from Windows Explorer
- **Command Line Support**: Open files by passing them as command line arguments
- **Multiple File Opening**: Select multiple files and open them all at once - each opens in its own tab
- **Automatic Tab Management**: When files are opened via file association, empty default tabs are automatically closed

## 🚀 Usage

### Opening Files
- **Menu/Toolbar**: Use File → Open or click the Open button
- **File Association**: Double-click associated file types in Windows Explorer
- **Command Line**: `juicyeditor.exe file1.txt file2.py file3.md` opens all files in separate tabs
- **Drag & Drop**: (Future enhancement)

## ⚙️ Setup & File Association

### Windows File Association
To associate file types with Juicy Editor on Windows:

1. **Right-click** on a file you want to associate (e.g., `.txt`, `.py`, `.md`)
2. Select **"Open with" → "Choose another app"**
3. Click **"More apps"** → **"Look for another app on this PC"**
4. Navigate to your Juicy Editor executable (`juicyeditor.exe`)
5. Check **"Always use this app"** to make it the default
6. Click **"OK"**

### Command Line Usage
```bash
# Open single file
juicyeditor.exe myfile.txt

# Open multiple files (each opens in a new tab)
juicyeditor.exe file1.txt file2.py notes.md

# Files can be relative or absolute paths
juicyeditor.exe C:\path\to\file.txt relative-file.md
```

### Supported File Types
Juicy Editor can open any text-based file, with enhanced support for:
- **Text Files**: `.txt`, `.log`, `.cfg`, `.ini`
- **Programming**: `.py`, `.js`, `.gd`, `.html`, `.css`
- **Documentation**: `.md`, `.json`, `.xml`, `.yml`, `.yaml`
- **And many more!**

## 🏗️ Architecture

### Project Structure
```
juicyeditor/
├── scripts/
│   ├── controllers/           # Main game logic and coordination
│   │   └── game_controller.gd # Central application controller
│   ├── components/           # Reusable UI and logic components
│   │   ├── audio_manager.gd  # Audio feedback system
│   │   ├── visual_effects_manager.gd # Shader-based visual effects
│   │   ├── theme_manager.gd  # Theme loading and application system
│   │   ├── file_tab_container.gd # Multi-file tab management
│   │   ├── juicy_theme.gd    # Theme resource definition
│   │   ├── juicy_text_edit.gd # Enhanced text editor
│   │   └── juicy_lucy.gd     # Animated assistant with eye tracking
│   └── ui/                   # UI-specific scripts
│       └── theme_switcher.gd # Theme selection UI component
├── scenes/
│   ├── components/           # Reusable scene components
│   │   └── juicy_lucy.tscn   # Juicy Lucy assistant scene
│   └── ui/                   # UI layouts and screens
│       ├── effects_settings_panel.tscn # Visual effects configuration
│       └── theme_switcher.tscn # Theme selection dialog
├── audio/
│   └── sfx/                  # Sound effects
├── effects/
│   ├── shaders/              # Visual effect shaders
│   └── animations/           # Animation resources
├── fonts/                    # Custom typography
│   ├── National2Condensed-Regular.otf
│   └── National2Condensed-Medium.otf
├── shaders/                  # GLSL shader files
│   ├── shadow.gdshader       # Text shadow effects
│   ├── outline.gdshader      # Text outline effects
│   └── gradient.gdshader     # Background gradient effects
└── themes/                   # UI and color themes
	├── super_juicy_theme.tres # Enhanced theme with custom fonts
	├── juicy_theme.tres       # Original juicy theme
	├── dark_theme.tres        # Dark mode
	└── light_theme.tres       # Light mode
```

### Core Systems

#### GameController
The central hub that coordinates all systems:
- File operations (open, save, new)
- Settings management and persistence
- Window title updates
- Signal coordination between components

#### AudioManager
Handles all audio feedback:
- Typing sounds with randomization
- UI interaction sounds
- File operation audio cues
- Volume and preference management

#### ThemeManager
Advanced theme system with live switching:
- Dynamic theme loading and application
- UI element registration and management
- Font integration with National2Condensed typography
- Button and menu animations with theme-specific effects
- Live preview functionality with instant application
- Support for custom colors, fonts, shadows, outlines, and gradients

#### VisualEffectsManager
Handles shader-based visual effects:
- Text shadow effects with configurable color, offset, and blur
- Text outline effects with customizable color, width, and smoothness
- Background gradient effects with start/end colors and direction
- Real-time effect configuration through UI controls
- Shader material management and optimization

#### JuicyTextEdit
Enhanced TextEdit component:
- Built-in syntax highlighting with theme integration
- File type-specific color schemes
- Typing sound integration
- Animation hooks
- Line number management

#### JuicyLucy
Animated text editor assistant inspired by Microsoft Clippy:
- **Eye Tracking**: Procedurally generated pupils that follow the mouse cursor in real-time
- **Eyebrow Animation**: Procedural Line2D eyebrows that express emotions through 7 different animation states (including upset for spelling errors)
- **Context-Aware Commentary**: Witty phrases triggered by user actions (typing, idle, saving, deleting, spelling errors)
- **Phrase Dictionary**: Categorized phrases for different situations with randomized selection
- **BBCode Dialog**: RichTextLabel with wave effects for juicy animated text display
- **Emotion System**: Seven emotional states (neutral, happy, surprised, concerned, skeptical, curious, upset) with matching eyebrow animations
- **Spell Checking Integration**: Real-time spelling error detection with sassy feedback
- **Non-Blocking**: All commentary is timed to be helpful without interrupting workflow
- **Signal-Based**: Emits signals for phrase displays and emotion changes for extensibility

#### SymSpell Spell Checker
Local spell checking system based on the SymSpell algorithm:
- **Algorithm**: Symmetric Delete spelling correction (https://github.com/wolfgarbe/SymSpell)
- **Dictionary**: Uses frequency_bigramdictionary_en_243_342.txt with 240,000+ bigrams
- **Performance**: 1 million times faster than traditional spell checkers
- **Edit Distance**: Supports Damerau-Levenshtein distance (insertions, deletions, substitutions, transpositions)
- **Smart Detection**: Only checks words 2+ characters, ignores numbers and single letters
- **Frequency-Based Ranking**: Suggestions ranked by edit distance and word frequency
- **GDScript Implementation**: Pure GDScript implementation optimized for Godot
- **Automatic Loading**: Dictionary loads on startup with progress tracking
- **Word Extraction**: Intelligent word boundary detection with apostrophe support for contractions
- **Max Edit Distance**: Configurable (default: 2) for balance between speed and accuracy
- **Prefix Optimization**: Uses prefix length of 7 for memory efficiency

#### Spell Checking Features
How the spell checker integrates with Juicy Lucy:
- **Delayed Checking**: 2-3 second delay after typing stops to avoid interrupting flow
- **No Visual Clutter**: Words are NOT highlighted or underlined - Lucy just tells you about errors
- **Sassy Feedback**: Lucy displays upset eyebrows and phrases like "You didn't spell '%s' correctly, you dumb bitch."
- **Suggestions Included**: Lucy provides the best spelling suggestion when available
- **Random Selection**: If multiple errors exist, Lucy randomly picks one to comment on
- **Context Preservation**: Spell checking respects your typing session without breaking concentration
- **Performance**: Fast enough to check entire documents without lag

## 🎨 Syntax Highlighting System

### File Type Support
Juicy Editor provides specialized syntax highlighting for:

- **GDScript (.gd)**: Complete GDScript syntax with theme-aware colors
  - Functions (`func`) highlighted in theme-specific function colors
  - Classes (`class`) and signals (`signal`) with distinct colors
  - Built-in types (Vector2, Color, Node, etc.) in specialized colors
  - Keywords, strings, comments, and numbers with traditional highlighting

- **Python (.py)**: Full Python syntax support
  - Function definitions (`def`) and classes (`class`) with unique colors
  - Import statements (`import`, `from`) highlighted distinctly
  - Decorators (`@property`, `@staticmethod`) with special coloring
  - Standard keywords, strings, and comments

- **Markdown (.md)**: Rich markdown formatting
  - Headers (`#`, `##`, `###`) with header-specific colors
  - Bold (`**text**`) and italic (`*text*`) formatting
  - Inline code (`` `code` ``) and code blocks with distinct highlighting
  - Links (`[text](url)`) with link-specific colors
  - Checkboxes (`[ ]` unchecked, `[X]` checked) with distinct colors

- **JSON (.json)**: Structured JSON highlighting
  - Keys and values with distinct colors
  - Brackets and braces with structural highlighting
  - Boolean values (`true`, `false`, `null`) with special colors
  - Numbers with numeric highlighting

### Theme-Aware Colors
Each theme provides unique color schemes:

- **Dark Theme**: Professional dark colors with high contrast
  - GDScript `func` in dark red, `class` in green, `signal` in pink
  - Python `def` in muted red, decorators in lime green
  - Markdown headers in blue, bold in yellow, code in light green

- **Light Theme**: Clean bright colors optimized for daylight
  - Traditional programming colors adapted for light backgrounds
  - Subdued but clear color differentiation
  - Professional appearance for office environments

- **Juicy Theme**: Vibrant and playful colors
  - Bright, saturated colors for an energetic coding experience
  - Enhanced contrast and visual appeal
  - Perfect for creative projects and fun coding sessions

- **Super Juicy Theme**: Ultra-vibrant maximum visual impact
  - Extreme color saturation and contrast
  - Rainbow-like color palette
  - Maximum visual excitement for those who love bold aesthetics

### Automatic Detection
- File type detection based on file extension
- Automatic syntax highlighter switching when opening files
- Live theme switching updates syntax colors instantly
- Fallback to basic highlighting for unsupported file types

## 🎨 Design Philosophy

### Single Responsibility
Each scene and script has one clear purpose, avoiding monolithic components.

### Signal-Driven Architecture
UI actions emit signals that are handled by appropriate controllers, maintaining loose coupling.

### Configurable Effects
All visual and audio effects can be customized or disabled via settings.

### Self-Contained Components
Scenes are designed to work independently with minimal external dependencies.

## 🚀 Getting Started

### Prerequisites
- Godot 4.4 or later

### Setup
1. Clone or download the project
2. Open `project.godot` in Godot
3. Run the project to start Juicy Editor

## 💻 Usage Guide

### Basic Operations
- **New File**: Ctrl+N or File → New
- **Open File**: Ctrl+O or File → Open  
- **Save File**: Ctrl+S or File → Save
- **Save As**: File → Save As

### Text Editing Features
- **Find & Replace**: Ctrl+F or Edit → Find & Replace...
  - Search with case sensitivity and whole word options
  - Replace single instances or all occurrences
- **Go to Line**: Ctrl+G or Edit → Go to Line...
- **Word Wrap**: Edit → Word Wrap (toggleable)
- **Text Statistics**: Edit → Text Statistics
- **Zoom**: Ctrl+= (in), Ctrl+- (out), Ctrl+0 (reset)

### Customization
- **Settings**: Settings → Preferences...
  - **Text Editor**: Font size, theme selection, line numbers, syntax highlighting
  - **Audio**: Master volume, UI sounds, typing sounds, effect volume
  - **Visual Effects**: Enable/disable effects, glow, pulse, intensity control
  - **Animations**: Typing animations, cursor pulse, button animations, speed control
- **Theme Switching**: Settings → Switch Theme...
  - **Balatro UI Theme**: NEW! Cartoonishly large buttons with poker-game aesthetics, featuring Juicy Lucy the hamburger mascot
  - **Super Juicy Theme**: Vibrant colors with National2Condensed fonts, enhanced shadows, outlines, and animations
  - **Classic Juicy**: Original theme with standard fonts and moderate effects
  - **Dark Theme**: Minimal dark interface for focused writing
  - **Light Theme**: Clean, bright interface for daytime use
  - **Live Preview**: See theme changes immediately with font and color previews
- **Visual Effects**: Effects → Visual Effects Settings...
  - **Text Shadow**: Color, offset, blur radius configuration
  - **Outline**: Color, width, smoothness settings
  - **Background Gradient**: Start/end colors, gradient direction
  - **Quick Toggles**: Use Effects menu for instant on/off switching

### Zoom Controls
Juicy Editor features a powerful zoom system that scales the entire text editing area:

- **Toolbar Buttons**: 
  - **Zoom Out**: Decrease view size by 10%
  - **Percentage Button**: Shows current zoom level (e.g., "100%") and resets to 100% when clicked
  - **Zoom In**: Increase view size by 10%
- **Range**: 20% minimum to 300% maximum zoom
- **Synchronized Scaling**: Line numbers automatically scale and align perfectly with text
- **Menu Access**: Edit → Zoom In/Out/Reset
- **Keyboard Shortcuts**: Ctrl+= (zoom in), Ctrl+- (zoom out), Ctrl+0 (reset)
- **Use Cases**: 
  - Make text larger when window is resized to smaller dimensions
  - Zoom out for overview of long documents
  - Accessibility support for users who need larger text

### Keyboard Shortcuts
| Action | Shortcut |
|--------|----------|
| New File | Ctrl+N |
| Open File | Ctrl+O |
| Save File | Ctrl+S |
| Find & Replace | Ctrl+F |
| Go to Line | Ctrl+G |
| Zoom In | Ctrl+= |
| Zoom Out | Ctrl+- |
| Reset Zoom | Ctrl+0 |
| Undo | Ctrl+Z |
| Redo | Ctrl+Y |
| Add Checkbox (Markdown) | Ctrl+Alt+9 |
| Toggle Checkbox (Markdown) | Ctrl+Alt+0 |

### Adding Audio
Place audio files in `audio/sfx/` and configure them in the AudioManager.

### Customizing Effects
Modify the settings in GameController or create new visual effects in the `effects/` folder.

## 📝 Development Status

### ✅ Completed Features
- [x] **Project Setup & Architecture** - Clean, organized codebase with proper separation of concerns and Godot 4.4 best practices
- [x] **Core Text Editor** - Full-featured text editing with cursor movement, selection, and comprehensive file operations
- [x] **File Operations** - Complete open, save, save-as, and new file functionality with error handling and recent files management
- [x] **UI Design & Layout** - Responsive interface with menu bar, toolbar, status bar, and intuitive navigation
- [x] **Syntax Highlighting** - Support for GDScript, Python, JavaScript, HTML, CSS, Markdown, JSON with proper color coding
- [x] **Visual Effects Framework** - Shader-based text shadows, outlines, gradients, pulse effects, and customizable glow effects
- [x] **Audio Feedback System** - Procedural typing sounds, button clicks, hover effects, and file operation audio cues with volume controls
- [x] **Animation & Juice Effects** - Character typing animations, cursor pulse, button interactions, smooth transitions with proper scale management
- [x] **Settings & Configuration** - Comprehensive tabbed settings dialog with Text Editor, Audio, Visual Effects, and Animation preferences
- [x] **Advanced Text Editor Features** - Find & Replace with options, Go to Line dialog, word wrap toggle, zoom controls, and text statistics
- [x] **Theme System** - Dark, Light, and Juicy themes with visual effects integration and user customization
- [x] **Keyboard Shortcuts** - Standard shortcuts (Ctrl+N/O/S/F/G, zoom controls) with intuitive key combinations
- [x] **Error Handling & Polish** - Robust file operation error handling, animation state management, and performance optimization

### 🚀 Next Phase: Node-Based Juicy Typing Effects (NEW APPROACH)

#### 🔄 **DEPRECATED: RichTextLabel Enhancement Plan**
**⚠️ The hybrid TextEdit + RichTextLabel architecture has been deprecated due to complexity issues in our lightweight editor.**
- The RichTextLabel overlay system proved too complex for reliable maintenance
- BBCode effects, text shadows, outlines, and gradient backgrounds have been disabled
- Visual Effects menu items have been deactivated
- Code remains in project but is disabled for future reference

#### ✨ **NEW: Simplified Node-Based Typing Effects**
Inspired by the [ridiculous_coding](https://github.com/jotson/ridiculous_coding) plugin, we're implementing a much simpler but more fun approach:

**Core Concept: Animated Node Effects**
- **TypingEffect Node2D**: Individual animated characters that spawn when typing
- **TypingEffectsManager**: Coordinates effect spawning and cleanup
- **Simple Label-Based Animations**: Character bounce, fade, color randomization
- **Particle Effects**: Optional particles for extra juiciness
- **Audio Coordination**: Synchronized sound effects with visual feedback

#### 🎯 New Juicy Typing System Features

##### ✅ Completed
- [x] **TypingEffect Component** - Node2D-based character effects with bounce animations, color randomization, and particle systems
- [x] **TypingEffectsManager** - Centralized management of typing effects with text editor integration
- [x] **JuicyTextEdit Simplification** - Removed complex RichTextLabel overlay, replaced with lightweight node-based system
- [x] **RichTextLabel System Deprecation** - Disabled BBCode effects, shadows, outlines, and related menu items
- [x] **Syntax Highlighting Restoration** - Fixed missing syntax highlighting method for proper file opening support
- [x] **Flying Letter Deletion Effects** - Physics-based flying letters inspired by TEXTREME when text is deleted
- [x] **Combined Deletion Effects** - Explosion + flying letter effects for maximum visual feedback

##### 🚧 Implementation Todos
- [x] **Effect Scenes Creation** - Create dedicated .tscn files for typing, deletion, and newline effects
- [x] **Flying Letter Physics** - Implement TEXTREME-inspired physics-based flying letters for deletions
- [x] **Visual Polish** - Add sprite-based animations, improved particle effects, and visual variety
- [x] **Audio Integration** - Coordinate typing effects with existing AudioManager for enhanced feedback
- [ ] **Performance Optimization** - Implement object pooling for effects to prevent memory issues
- [ ] **Settings Integration** - Add typing effects controls to Settings dialog
- [ ] **Effect Customization** - Allow users to configure effect styles, colors, and intensity
- [x] **Advanced Animations** - Character-specific effects, typing rhythm detection, combo effects
- [ ] **Screen Shake Integration** - Add subtle screen shake for impactful typing moments
- [ ] **Effect Themes** - Multiple visual themes (minimal, explosive, magical, retro)
- [ ] **Testing & Polish** - Comprehensive testing and performance validation

#### Technical Architecture (Simplified)
```
JuicyTextEdit (Simplified)
├── TextEdit (Core Editor)
│   ├── Text input/editing
│   ├── Cursor management
│   ├── Syntax highlighting
│   └── Keyboard shortcuts
└── TypingEffectsManager
	├── Effect spawning coordination
	├── Node2D-based visual effects
	├── Audio feedback integration
	└── Performance management

TypingEffect (Node2D)
├── Label (Character display)
├── AnimationPlayer (Bounce/fade animations)
├── GPUParticles2D (Optional particles)
├── AudioStreamPlayer2D (Sound effects)
└── Timer (Cleanup management)

FlyingLetter (Node2D) - NEW!
├── Label (Deleted character display)
├── VisibleOnScreenNotifier2D (Off-screen cleanup)
├── Timer (Backup cleanup)
└── Physics System (Gravity, velocity, rotation)
```

#### Key Benefits of New Approach
- **Simplicity**: No complex RichTextLabel synchronization
- **Performance**: Lightweight Node2D effects with automatic cleanup
- **Maintainability**: Clear separation of concerns and simpler architecture
- **Extensibility**: Easy to add new effect types and animations
- **Fun Factor**: More dynamic and playful than static text effects, including physics-based flying letters
- **User Control**: Can be completely disabled or customized per user preference
- **TEXTREME Inspiration**: Flying letter deletion effects add satisfying visual feedback for text removal

### 🎯 Key Implementation Highlights
- **Signal-Driven Architecture**: Loose coupling between UI and logic for maintainable code
- **Manager Pattern**: Dedicated AudioManager, VisualEffectsManager, and AnimationManager for organized effects
- **Node-Based Typing Effects**: Revolutionary simple approach using Node2D effects instead of complex overlays
- **Real-time Character Animations**: Fun typing effects with bounce, fade, particles, and color randomization
- **Performance Optimization**: Lightweight effect system with automatic cleanup and memory management
- **Settings Persistence**: JSON-based configuration system with automatic save/load
- **Animation State Tracking**: Proper scale reset functionality prevents cumulative animation issues
- **Comprehensive Find/Replace**: Full-featured search with case sensitivity, whole words, and replace all
- **Accessibility Features**: Keyboard shortcuts, customizable UI, and user preference persistence
- **RichTextLabel Deprecation**: Simplified architecture by removing complex overlay system

### ✨ Development Status
Juicy Editor is transitioning to a simplified node-based typing effects system. The complex RichTextLabel overlay has been deprecated in favor of a more maintainable and fun approach inspired by the ridiculous_coding plugin. The new system uses lightweight Node2D effects that spawn character animations when typing, providing delightful visual feedback without the complexity of BBCode synchronization. Core text editing functionality remains robust and feature-complete.

## 🎵 Audio Credits

Audio system inspired by [Godot-Fancy-Editor-Sounds](https://github.com/Aventero/Godot-Fancy-Editor-Sounds) by Aventero.

## 🍔 Meet Juicy Lucy - The Official Mascot

**Juicy Lucy** is the adorable anthropomorphic hamburger mascot of Juicy Editor! 

### About Lucy
- **Species**: Anthropomorphic Hamburger
- **Appearance**: 
  - Sesame seed bun for a head
  - Lettuce "hair" 
  - Cheese eyes with ketchup pupils
  - Friendly, welcoming smile
  - Editor's visor cap (because she's professional!)
- **Role**: UI icon and branding element for the Balatro UI Theme

### Where to Find Lucy
- Featured prominently in the **Balatro UI Theme**
- Icon assets in `assets/ui/icons/`
- Future appearances in splash screens, about dialogs, and status indicators

### Future Plans for Lucy
- Animated idle states for the status bar
- Different expressions for various editor states (saving, errors, success)
- Seasonal costume variations
- Mascot animations for the splash screen

Lucy represents the fun, juicy spirit of the editor - making text editing delightful!

## 📄 License

This project is open source. See individual files for specific licensing information.

---

**Made with ❤️ and Godot 4.4**
