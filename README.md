# Juicy Editor

A lightweight, standalone text editor built with Godot 4.4 that focuses on delightful user experience through visual and audio feedback.

## 🎯 Project Vision

Juicy Editor combines the functionality of a basic text editor with satisfying visual effects and audio feedback, creating an enjoyable writing experience. Unlike traditional text editors, every interaction provides feedback through carefully crafted sounds, animations, and visual effects.

## ✨ Key Features

### Core Functionality
- ✅ **Text Editing**: Full-featured text editing with cursor movement and text selection
- ✅ **File Operations**: Open, Save, Save As, and New file functionality
- ✅ **Syntax Highlighting**: Support for GDScript, Python, JavaScript, HTML, CSS, JSON, and Markdown
- ✅ **Find & Replace**: Comprehensive search and replace with case sensitivity and whole word options
- ✅ **Go to Line**: Quick navigation to specific line numbers
- ✅ **Line Numbers**: Configurable line number display
- ✅ **Word Wrap**: Toggle word wrapping on/off
- ✅ **Zoom Controls**: Zoom in/out and reset zoom functionality
- ✅ **Text Statistics**: Character, word, line, and paragraph counting

### Juicy Elements
- ✅ **Audio Feedback**: Typing sounds, button clicks, hover sounds with volume controls
- ✅ **Visual Effects**: Shader-based text shadows, outlines, gradient backgrounds with real-time configuration
- ✅ **Animations**: Character typing animations, cursor pulse, button interactions, smooth transitions
- ✅ **Themes**: Dark, Light, and Juicy themes with visual effect integration

### Quality of Life
- ✅ **Settings Persistence**: Comprehensive settings with tabbed interface for all preferences
- ✅ **Keyboard Shortcuts**: Standard shortcuts (Ctrl+N, Ctrl+O, Ctrl+S, Ctrl+F, Ctrl+G, etc.)
- ✅ **Recent Files**: Quick access to recently opened files (up to 10)
- ✅ **Error Handling**: Robust file operation error handling
- ✅ **Animation Controls**: Scale reset functionality and proper state management

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
│   │   └── juicy_text_edit.gd # Enhanced text editor
│   └── ui/                   # UI-specific scripts
├── scenes/
│   ├── components/           # Reusable scene components
│   └── ui/                   # UI layouts and screens
│       └── effects_settings_panel.tscn # Visual effects configuration
├── audio/
│   └── sfx/                  # Sound effects
├── effects/
│   ├── shaders/              # Visual effect shaders
│   └── animations/           # Animation resources
├── shaders/                  # GLSL shader files
│   ├── shadow.gdshader       # Text shadow effects
│   ├── outline.gdshader      # Text outline effects
│   └── gradient.gdshader     # Background gradient effects
└── themes/                   # UI and color themes
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

#### VisualEffectsManager
Handles shader-based visual effects:
- Text shadow effects with configurable color, offset, and blur
- Text outline effects with customizable color, width, and smoothness
- Background gradient effects with start/end colors and direction
- Real-time effect configuration through UI controls
- Shader material management and optimization

#### JuicyTextEdit
Enhanced TextEdit component:
- Built-in syntax highlighting
- Typing sound integration
- Animation hooks
- Line number management

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
- **Visual Effects**: Effects → Visual Effects Settings...
  - **Text Shadow**: Color, offset, blur radius configuration
  - **Outline**: Color, width, smoothness settings
  - **Background Gradient**: Start/end colors, gradient direction
  - **Quick Toggles**: Use Effects menu for instant on/off switching

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

### 🎯 Key Implementation Highlights
- **Signal-Driven Architecture**: Loose coupling between UI and logic for maintainable code
- **Manager Pattern**: Dedicated AudioManager, VisualEffectsManager, and AnimationManager for organized effects
- **Settings Persistence**: JSON-based configuration system with automatic save/load
- **Animation State Tracking**: Proper scale reset functionality prevents cumulative animation issues
- **Comprehensive Find/Replace**: Full-featured search with case sensitivity, whole words, and replace all
- **Accessibility Features**: Keyboard shortcuts, customizable UI, and user preference persistence

### � Ready for Use
Juicy Editor is feature-complete and ready for daily use as a lightweight text editor with unique visual and audio feedback. All core functionality has been implemented, tested, and polished.

## 🎵 Audio Credits

Audio system inspired by [Godot-Fancy-Editor-Sounds](https://github.com/Aventero/Godot-Fancy-Editor-Sounds) by Aventero.

## 📄 License

This project is open source. See individual files for specific licensing information.

---

**Made with ❤️ and Godot 4.4**
