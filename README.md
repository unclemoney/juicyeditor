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
- [ ] **Visual Polish** - Add sprite-based animations, improved particle effects, and visual variety
- [ ] **Audio Integration** - Coordinate typing effects with existing AudioManager for enhanced feedback
- [ ] **Performance Optimization** - Implement object pooling for effects to prevent memory issues
- [ ] **Settings Integration** - Add typing effects controls to Settings dialog
- [ ] **Effect Customization** - Allow users to configure effect styles, colors, and intensity
- [ ] **Advanced Animations** - Character-specific effects, typing rhythm detection, combo effects
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

## 📄 License

This project is open source. See individual files for specific licensing information.

---

**Made with ❤️ and Godot 4.4**
