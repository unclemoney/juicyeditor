Dearest Copilot,

We are making a simple text editor for Godot called Juicy Editor. It is a simple text editor much like Windows Notepad, but it is made in Godot. It has a few extra features like syntax highlighting and line numbers.  What makes it juicy is all the RichTextLabel effects we can add to the text, like shadows, outlines, gradients, and more.  We want to make it as user-friendly and fun to use as possible.

## Coding Standards
- Always target Godot 4.4 GDScript syntax.
- Use tabs for indentation—never spaces.
- Prefix every script with its extends and class_name.
- Follow snake_case for methods/vars, PascalCase for classes/nodes.
- Wrap exported properties in @export var and onready lookups in @onready var.
- Never emit inline parsing hacks—break declarations into separate var + assignment.
- Provide detailed steps for setting up complex scenes or systems in the Godot editor, when applicable.
- Godot does not support ternary operator syntax with the question mark ?: use if/else statements instead.
- GDScript doesn't support multi-line boolean expressions with and/or operators split across lines. Use single line if statements or nested if statements instead.
- Review the code base to ensure consistency with existing variables, methods, and class names, and to follow proper syntax to ensure we do not introduce any parsing errors.
- Remember to add activation code for new features in game_controller.gd.
- Do not add class_name to scripts that are only used as Autoloads.
- Use signals to decouple UI actions from logic. For example, emit signals for toolbar button presses and handle them in the main controller script.
- Ensure all visual effects are configurable via exported properties or settings menus.
- Document all new features in the `README.md` file, including setup instructions and usage examples.
- Godot installation folder: "C:\Users\danie\OneDrive\Documents\GODOT\Godot_v4.4.1-stable_win64.exe".
- Update the README.md file to reflect any new features or changes made to the project structure.
- Autoload scripts should not have class_name declarations.

## Scene & Node Organization
- Single responsibility: each scene owns exactly one domain (UI, gameplay logic, effects).
- If at all possible, you should design scenes to have no dependencies.
- Reusable scenes should be self-contained and not rely on external nodes.
- Root Logic Node: keep your GameController at the scene root.
- Typed Paths: export NodePaths for everything you need from another scene, assign them in the inspector, and guard with get_node_or_null() in _ready().
- Avoid Global State when possible and use node trees and signals.