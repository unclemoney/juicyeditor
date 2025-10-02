# Changelog

## 0.2.6

- New implementation for `get_running_scene_screenshot` which supports more MCP clients

## 0.2.5

- Added support for Linux arm64
- Added `webp` image format for getting editor/running scene screenshots
- Fixed `get_running_scene_screenshot` freezing editor on some Windows devices

## 0.2.4

- Updated to latest MCP specification version 2025-06-18
- Added support for Godot 4.5
- Added `duplicate_node` tool to duplicate a node in a scene
- Added `move_node` tool to move a node to a different parent

## 0.2.3

- Added `uid_to_project_path` tool to convert uid:// to res://
- Added `project_path_to_uid` tool to convert res:// to uid://

## 0.2.2

- Added `get_running_scene_screenshot` tool that lets AI visually see your running game
- Added `set_anchor_values` tool to set individual anchor side values
- Added `set_anchor_preset` tool to set anchors using presets
- Added `stop_running_scene` tool that stops the running scene

## 0.2.1

- Fixed issue caused by newer dependency versions by pinning all dependencies to exact versions.
- Added `get_editor_screenshot` that lets AI visually see the entire Godot editor

## 0.2.0

- Improved GDAI MCP error logging
- Added `clear_output_logs` tool to clear output logs in the editor.
- Fixed `edit_file` tool in some cases would not be able to edit end of file correctly.
- Both `edit_file` and `view_script` tools also open the script in the editor.
- Updated `play_scene` tool description to inform the user to test the game and confirm its as expected before continuing.
- Added `view_script` tool for viewing GDScript files and useful to check for errors in script.
- Added `gdai-mcp-default-prompt` a custom MCP prompt for with Godot Best practices and GDAI MCP best practices.


## 0.1.0

- Initial early access version
