extends Window
class_name MarkdownViewWindow

## MarkdownViewWindow
## Renders parsed markdown blocks in a themed, animated preview window.
## Supports live update, scroll memory, and juicy hover effects.

const MarkdownParserScript = preload("res://scripts/components/markdown_parser.gd")

signal live_update_toggled(enabled: bool)
signal link_clicked(url: String)
signal navigate_to(file_path: String)
signal morph_requested()

# Theme reference
var current_theme: JuicyTheme

# Internal state
var _parser: RefCounted
var _current_text: String = ""
var _current_filename: String = ""
var _current_file_path: String = ""
var _saved_scroll: int = 0
var _block_nodes: Array[Control] = []
var _h1_pulse_nodes: Array[RichTextLabel] = []
var _active_tweens: Array[Tween] = []

# Navigation history
var _history_back: Array[String] = []  # stack of file paths
var _history_forward: Array[String] = []

# Debounce timer
var _debounce_timer: Timer

# UI references (built in _ready)
var _panel: Panel
var _vbox: VBoxContainer
var _title_bar: HBoxContainer
var _filename_label: Label
var _live_toggle: CheckButton
var _refresh_button: Button
var _close_button: Button
var _back_button: Button
var _forward_button: Button
var _morph_button: Button
var _separator: HSeparator
var _scroll_container: ScrollContainer
var _content_container: VBoxContainer
var _background_rect: ColorRect


func _ready() -> void:
	_parser = MarkdownParserScript.new()
	title = "Markdown Preview"
	close_requested.connect(_on_close_requested)

	_build_ui()

	# Debounce timer for live updates
	_debounce_timer = Timer.new()
	_debounce_timer.wait_time = 0.3
	_debounce_timer.one_shot = true
	_debounce_timer.timeout.connect(_on_debounce_timeout)
	add_child(_debounce_timer)


func _process(_delta: float) -> void:
	if not current_theme:
		return
	if not current_theme.enable_pulse_effects:
		return
	# H1 pulse effect
	var t: float = Time.get_ticks_msec() * 0.001
	var pulse: float = 0.05 * sin(t * 2.0)
	for node in _h1_pulse_nodes:
		if is_instance_valid(node):
			node.modulate = Color(1.0 + pulse, 1.0, 1.0 + pulse * 0.5, 1.0)


# ---- Public API ----

## open_with
## Opens the window with the given markdown text, filename, and theme.
## Pushes the previous file onto the back-history stack.
func open_with(text: String, filename: String, p_theme: JuicyTheme, file_path: String = "") -> void:
	# Push current page onto back stack (if we already have a page loaded)
	if _current_file_path != "" and file_path != "" and _current_file_path != file_path:
		_history_back.append(_current_file_path)
		_history_forward.clear()
	_current_text = text
	_current_filename = filename
	_current_file_path = file_path
	current_theme = p_theme
	_apply_theme_to_ui()
	_filename_label.text = "📖 " + filename
	_update_nav_buttons()
	if not visible:
		show()
	# Defer render so the window has completed its layout pass
	call_deferred("_deferred_render")


func _deferred_render() -> void:
	_render(_current_text)


## refresh
## Re-renders with new text, preserving scroll position.
func refresh(text: String) -> void:
	_current_text = text
	_saved_scroll = _scroll_container.scroll_vertical
	_render(text)
	# Restore scroll after layout pass
	call_deferred("_restore_scroll")


## set_juicy_theme
## Updates theme and re-renders.
func set_juicy_theme(p_theme: JuicyTheme) -> void:
	current_theme = p_theme
	_apply_theme_to_ui()
	_render(_current_text)


## queue_live_refresh
## Called externally when text changes. Starts debounce timer.
func queue_live_refresh(text: String) -> void:
	_current_text = text
	if _debounce_timer:
		_debounce_timer.start()


## is_live_update_enabled
func is_live_update_enabled() -> bool:
	if _live_toggle:
		return _live_toggle.button_pressed
	return true


# ---- UI Construction ----

func _build_ui() -> void:
	# Background ColorRect (for shader later)
	_background_rect = ColorRect.new()
	_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_rect.color = Color(0.12, 0.12, 0.15, 1.0)
	add_child(_background_rect)

	# Main panel
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	# Root VBox
	_vbox = VBoxContainer.new()
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vbox.add_theme_constant_override("separation", 0)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)
	margin.add_child(_vbox)

	# Title bar
	_title_bar = HBoxContainer.new()
	_title_bar.add_theme_constant_override("separation", 8)
	_vbox.add_child(_title_bar)

	_filename_label = Label.new()
	_filename_label.text = "📖 Preview"
	_filename_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filename_label.add_theme_font_size_override("font_size", 16)
	_title_bar.add_child(_filename_label)

	_back_button = Button.new()
	_back_button.text = "◀"
	_back_button.tooltip_text = "Go back"
	_back_button.disabled = true
	_back_button.pressed.connect(_on_back_pressed)
	_title_bar.add_child(_back_button)

	_forward_button = Button.new()
	_forward_button.text = "▶"
	_forward_button.tooltip_text = "Go forward"
	_forward_button.disabled = true
	_forward_button.pressed.connect(_on_forward_pressed)
	_title_bar.add_child(_forward_button)

	_morph_button = Button.new()
	_morph_button.text = "⛶"
	_morph_button.tooltip_text = "Morph to fit editor window"
	_morph_button.pressed.connect(func(): morph_requested.emit())
	_title_bar.add_child(_morph_button)

	_live_toggle = CheckButton.new()
	_live_toggle.text = "🔄 Live"
	_live_toggle.button_pressed = true
	_live_toggle.toggled.connect(_on_live_toggled)
	_title_bar.add_child(_live_toggle)

	_refresh_button = Button.new()
	_refresh_button.text = "↺"
	_refresh_button.tooltip_text = "Refresh preview"
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_title_bar.add_child(_refresh_button)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.tooltip_text = "Close preview"
	_close_button.pressed.connect(_on_close_requested)
	_title_bar.add_child(_close_button)

	# Separator
	_separator = HSeparator.new()
	_vbox.add_child(_separator)

	# Scroll + content
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vbox.add_child(_scroll_container)

	_content_container = VBoxContainer.new()
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_container.add_theme_constant_override("separation", 12)
	_scroll_container.add_child(_content_container)


# ---- Theme Application ----

func _apply_theme_to_ui() -> void:
	if not current_theme:
		return

	var bg: Color = current_theme.background_color
	_background_rect.color = bg

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(bg.r, bg.g, bg.b, 0.95)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var text_col: Color = current_theme.text_color
	_filename_label.add_theme_color_override("font_color", text_col)

	if current_theme.editor_font:
		_filename_label.add_theme_font_override("font", current_theme.editor_font)

	var font_size: int = current_theme.editor_font_size if current_theme.editor_font_size > 0 else 16
	_filename_label.add_theme_font_size_override("font_size", font_size + 2)


# ---- Rendering ----

func _render(text: String) -> void:
	_kill_active_tweens()
	_h1_pulse_nodes.clear()
	_block_nodes.clear()

	# Clear existing content immediately to avoid layout conflicts with new nodes
	var old_children: Array[Node] = []
	for child in _content_container.get_children():
		old_children.append(child)
	for child in old_children:
		_content_container.remove_child(child)
		child.free()

	# Parse markdown
	var blocks: Array = _parser.parse(text)

	# Build nodes
	for block in blocks:
		var node: Control = _build_block_node(block)
		if node:
			_content_container.add_child(node)
			_block_nodes.append(node)

	# Entrance animation (deferred so layout is computed)
	call_deferred("_animate_entrance")


func _build_block_node(block: Dictionary) -> Control:
	var block_type: String = block.get("type", "")
	match block_type:
		"heading":
			return _build_heading_node(block)
		"paragraph":
			return _build_paragraph_node(block)
		"code_block":
			return _build_code_block_node(block)
		"unordered_list":
			return _build_list_node(block, false)
		"ordered_list":
			return _build_list_node(block, true)
		"task_list":
			return _build_task_list_node(block)
		"blockquote":
			return _build_blockquote_node(block)
		"horizontal_rule":
			return _build_hr_node()
		"table":
			return _build_table_node(block)
		"image":
			return _build_image_placeholder_node(block)
	return null


# ---- Block Builders ----

func _build_heading_node(block: Dictionary) -> Control:
	var level: int = block.get("level", 1)
	var spans: Array = block.get("spans", [])

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.mouse_filter = Control.MOUSE_FILTER_PASS
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Scale font size by heading level
	var base_size: int = _get_font_size()
	var scale_map: Dictionary = {1: 2.2, 2: 1.8, 3: 1.5, 4: 1.3, 5: 1.1, 6: 1.0}
	var scale: float = scale_map.get(level, 1.0)
	var heading_size: int = int(base_size * scale)
	rtl.add_theme_font_size_override("bold_font_size", heading_size)
	rtl.add_theme_font_size_override("normal_font_size", heading_size)

	if current_theme and current_theme.editor_font:
		rtl.add_theme_font_override("normal_font", current_theme.editor_font)
		rtl.add_theme_font_override("bold_font", current_theme.editor_font)

	var header_color: Color = _get_color("markdown_header_color", Color.WHITE)
	var bbcode: String = "[b][color=#" + header_color.to_html(false) + "]" + _spans_to_bbcode(spans) + "[/color][/b]"
	rtl.text = bbcode
	_setup_link_handling(rtl)

	container.add_child(rtl)

	# H1 gets a bottom rule
	if level == 1:
		var rule = ColorRect.new()
		rule.custom_minimum_size = Vector2(0, 3)
		rule.color = Color(header_color.r, header_color.g, header_color.b, 0.6)
		container.add_child(rule)
		_h1_pulse_nodes.append(rtl)

	# H2 gets a left accent bar via an HBoxContainer wrapper
	if level == 2:
		var wrapper = HBoxContainer.new()
		wrapper.add_theme_constant_override("separation", 8)
		var accent = ColorRect.new()
		accent.custom_minimum_size = Vector2(4, 0)
		accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
		accent.color = Color(header_color.r, header_color.g, header_color.b, 0.5)
		# Re-parent the container into the wrapper
		container.remove_child(rtl)
		if level == 1:
			pass  # Already handled above; but level here is 2
		wrapper.add_child(accent)
		var inner_vbox = VBoxContainer.new()
		inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner_vbox.add_child(rtl)
		wrapper.add_child(inner_vbox)
		# Remove the empty container and return wrapper instead
		container.queue_free()
		_setup_hover_effect(wrapper, 6.0)
		return wrapper

	_setup_hover_effect(container, 6.0)
	return container


func _build_paragraph_node(block: Dictionary) -> Control:
	var spans: Array = block.get("spans", [])
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.mouse_filter = Control.MOUSE_FILTER_PASS
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var font_size: int = _get_font_size()
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_font_size_override("bold_font_size", font_size)
	rtl.add_theme_font_size_override("italics_font_size", font_size)
	rtl.add_theme_font_size_override("bold_italics_font_size", font_size)
	rtl.add_theme_font_size_override("mono_font_size", max(font_size - 2, 10))

	if current_theme and current_theme.editor_font:
		rtl.add_theme_font_override("normal_font", current_theme.editor_font)
		rtl.add_theme_font_override("bold_font", current_theme.editor_font)
		rtl.add_theme_font_override("italics_font", current_theme.editor_font)

	var text_col: Color = _get_color("text_color", Color.WHITE)
	rtl.add_theme_color_override("default_color", text_col)
	rtl.text = _spans_to_bbcode(spans)

	# Connect link signals
	_setup_link_handling(rtl)

	return rtl


func _build_code_block_node(block: Dictionary) -> Control:
	var language: String = block.get("language", "")
	var code_text: String = block.get("text", "")

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_color: Color = _get_color("background_color", Color(0.1, 0.1, 0.12))
	# Darken slightly for code blocks
	var code_bg = Color(bg_color.r * 0.7, bg_color.g * 0.7, bg_color.b * 0.7, 1.0)
	var accent_color: Color = _get_color("markdown_code_color", Color(0.6, 0.8, 1.0))

	var style = StyleBoxFlat.new()
	style.bg_color = code_bg
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.3)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	panel.add_child(inner_vbox)

	# Language badge
	if language != "":
		var lang_label = Label.new()
		lang_label.text = language
		lang_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var lang_size: int = max(_get_font_size() - 4, 10)
		lang_label.add_theme_font_size_override("font_size", lang_size)
		lang_label.add_theme_color_override("font_color", Color(accent_color.r, accent_color.g, accent_color.b, 0.6))
		inner_vbox.add_child(lang_label)

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var code_size: int = max(_get_font_size() - 2, 10)
	rtl.add_theme_font_size_override("normal_font_size", code_size)
	rtl.add_theme_font_size_override("mono_font_size", code_size)

	var code_color: Color = _get_color("markdown_code_color", Color(0.8, 0.9, 1.0))
	rtl.add_theme_color_override("default_color", code_color)
	rtl.text = "[code]" + _escape_bbcode(code_text) + "[/code]"
	inner_vbox.add_child(rtl)

	_setup_code_block_hover(panel)
	return panel


func _build_list_node(block: Dictionary, ordered: bool) -> Control:
	var items: Array = block.get("items", [])
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(items.size()):
		var item: Dictionary = items[i]
		var indent: int = item.get("indent", 0)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# Indent spacer
		if indent > 0:
			var spacer = Control.new()
			@warning_ignore("integer_division")
			spacer.custom_minimum_size = Vector2(20 * (indent / 2 + 1), 0)
			hbox.add_child(spacer)

		# Bullet / number
		var bullet_label = Label.new()
		if ordered:
			bullet_label.text = str(item.get("number", i + 1)) + "."
		else:
			bullet_label.text = "•"
		bullet_label.add_theme_font_size_override("font_size", _get_font_size())
		var text_col: Color = _get_color("text_color", Color.WHITE)
		bullet_label.add_theme_color_override("font_color", text_col)
		if current_theme and current_theme.editor_font:
			bullet_label.add_theme_font_override("font", current_theme.editor_font)
		hbox.add_child(bullet_label)

		# Item text
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.add_theme_font_size_override("normal_font_size", _get_font_size())
		rtl.add_theme_font_size_override("bold_font_size", _get_font_size())
		rtl.add_theme_font_size_override("italics_font_size", _get_font_size())
		rtl.add_theme_font_size_override("mono_font_size", max(_get_font_size() - 2, 10))
		rtl.add_theme_color_override("default_color", text_col)
		if current_theme and current_theme.editor_font:
			rtl.add_theme_font_override("normal_font", current_theme.editor_font)
		rtl.text = _spans_to_bbcode(item.get("spans", []))
		_setup_link_handling(rtl)
		hbox.add_child(rtl)

		vbox.add_child(hbox)

	return vbox


func _build_task_list_node(block: Dictionary) -> Control:
	var items: Array = block.get("items", [])
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var checked_col: Color = _get_color("markdown_checkbox_checked_color", Color(0.4, 0.9, 0.4))
	var unchecked_col: Color = _get_color("markdown_checkbox_unchecked_color", Color(0.7, 0.7, 0.7))

	for item in items:
		var checked: bool = item.get("checked", false)
		var indent: int = item.get("indent", 0)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		if indent > 0:
			var spacer = Control.new()
			@warning_ignore("integer_division")
			spacer.custom_minimum_size = Vector2(20 * (indent / 2 + 1), 0)
			hbox.add_child(spacer)

		var checkbox = CheckBox.new()
		checkbox.button_pressed = checked
		checkbox.disabled = true
		checkbox.add_theme_color_override("font_color", checked_col if checked else unchecked_col)
		hbox.add_child(checkbox)

		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.add_theme_font_size_override("normal_font_size", _get_font_size())
		rtl.add_theme_font_size_override("bold_font_size", _get_font_size())
		rtl.add_theme_font_size_override("mono_font_size", max(_get_font_size() - 2, 10))
		var text_col: Color = checked_col if checked else _get_color("text_color", Color.WHITE)
		rtl.add_theme_color_override("default_color", text_col)
		if current_theme and current_theme.editor_font:
			rtl.add_theme_font_override("normal_font", current_theme.editor_font)

		var bbcode: String = _spans_to_bbcode(item.get("spans", []))
		if checked:
			bbcode = "[s]" + bbcode + "[/s]"
		rtl.text = bbcode
		_setup_link_handling(rtl)
		hbox.add_child(rtl)

		vbox.add_child(hbox)

	return vbox


func _build_blockquote_node(block: Dictionary) -> Control:
	var spans: Array = block.get("spans", [])

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var accent = ColorRect.new()
	var accent_color: Color = _get_color("markdown_header_color", Color(0.6, 0.6, 1.0))
	accent.custom_minimum_size = Vector2(4, 0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
	hbox.add_child(accent)

	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var font_size: int = _get_font_size()
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_font_size_override("italics_font_size", font_size)
	if current_theme and current_theme.editor_font:
		rtl.add_theme_font_override("italics_font", current_theme.editor_font)

	var text_col: Color = _get_color("text_color", Color.WHITE)
	rtl.add_theme_color_override("default_color", Color(text_col.r, text_col.g, text_col.b, 0.8))
	rtl.text = "[i]" + _spans_to_bbcode(spans) + "[/i]"
	_setup_link_handling(rtl)
	hbox.add_child(rtl)

	return hbox


func _build_hr_node() -> Control:
	var rule = ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_color: Color = _get_color("markdown_header_color", Color(0.6, 0.6, 1.0))
	rule.color = Color(header_color.r, header_color.g, header_color.b, 0.5)
	return rule


func _build_table_node(block: Dictionary) -> Control:
	var headers: Array = block.get("headers", [])
	var rows: Array = block.get("rows", [])
	var col_count: int = headers.size()
	if col_count == 0:
		return Control.new()

	var outer_panel = PanelContainer.new()
	outer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg_color: Color = _get_color("background_color", Color(0.1, 0.1, 0.12))
	var table_bg = Color(bg_color.r * 0.85, bg_color.g * 0.85, bg_color.b * 0.85, 1.0)
	var style = StyleBoxFlat.new()
	style.bg_color = table_bg
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	outer_panel.add_theme_stylebox_override("panel", style)

	var grid = GridContainer.new()
	grid.columns = col_count
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	outer_panel.add_child(grid)

	var font_size: int = _get_font_size()
	var header_color: Color = _get_color("markdown_header_color", Color.WHITE)
	var text_col: Color = _get_color("text_color", Color.WHITE)

	# Header row
	for header_text in headers:
		var lbl = Label.new()
		lbl.text = str(header_text)
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.add_theme_color_override("font_color", header_color)
		if current_theme and current_theme.editor_font:
			lbl.add_theme_font_override("font", current_theme.editor_font)
		grid.add_child(lbl)

	# Data rows
	for row in rows:
		for ci in range(col_count):
			var cell_text: String = str(row[ci]) if ci < row.size() else ""
			var lbl = Label.new()
			lbl.text = cell_text
			lbl.add_theme_font_size_override("font_size", font_size)
			lbl.add_theme_color_override("font_color", text_col)
			if current_theme and current_theme.editor_font:
				lbl.add_theme_font_override("font", current_theme.editor_font)
			grid.add_child(lbl)

	return outer_panel


func _build_image_placeholder_node(block: Dictionary) -> Control:
	var alt_text: String = block.get("alt", "image")
	var src: String = block.get("src", "")

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	var bg_color: Color = _get_color("background_color", Color(0.1, 0.1, 0.12))
	style.bg_color = Color(bg_color.r * 0.8, bg_color.g * 0.8, bg_color.b * 0.8, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = "🖼"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon_label)

	var alt_label = Label.new()
	alt_label.text = alt_text
	alt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alt_label.add_theme_font_size_override("font_size", _get_font_size())
	var text_col: Color = _get_color("text_color", Color.WHITE)
	alt_label.add_theme_color_override("font_color", Color(text_col.r, text_col.g, text_col.b, 0.7))
	if current_theme and current_theme.editor_font:
		alt_label.add_theme_font_override("font", current_theme.editor_font)
	vbox.add_child(alt_label)

	if src != "":
		var src_label = Label.new()
		src_label.text = src
		src_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var small_size: int = max(_get_font_size() - 4, 10)
		src_label.add_theme_font_size_override("font_size", small_size)
		src_label.add_theme_color_override("font_color", Color(text_col.r, text_col.g, text_col.b, 0.4))
		vbox.add_child(src_label)

	return panel


# ---- Inline to BBCode conversion ----

func _spans_to_bbcode(spans: Array) -> String:
	var result: String = ""
	for span in spans:
		var kind: String = span.get("kind", "text")
		var text: String = _escape_bbcode(span.get("text", ""))
		match kind:
			"text":
				result += text
			"bold":
				var col: Color = _get_color("markdown_bold_color", Color.WHITE)
				result += "[b][color=#" + col.to_html(false) + "]" + text + "[/color][/b]"
			"italic":
				var col: Color = _get_color("markdown_italic_color", Color.WHITE)
				result += "[i][color=#" + col.to_html(false) + "]" + text + "[/color][/i]"
			"bold_italic":
				var col: Color = _get_color("markdown_bold_color", Color.WHITE)
				result += "[b][i][color=#" + col.to_html(false) + "]" + text + "[/color][/i][/b]"
			"code":
				var col: Color = _get_color("markdown_code_color", Color(0.8, 0.9, 1.0))
				result += "[code][color=#" + col.to_html(false) + "]" + text + "[/color][/code]"
			"link":
				var col: Color = _get_color("markdown_link_color", Color(0.4, 0.6, 1.0))
				var url: String = span.get("url", "")
				result += "[url=" + url + "][color=#" + col.to_html(false) + "]" + text + "[/color][/url]"
	return result


func _escape_bbcode(text: String) -> String:
	# Escape BBCode-special characters
	text = text.replace("[", "[lb]")
	return text


# ---- Helpers ----

func _get_font_size() -> int:
	if current_theme and current_theme.editor_font_size > 0:
		return current_theme.editor_font_size
	return 16


func _get_color(property_name: String, fallback: Color) -> Color:
	if current_theme and property_name in current_theme:
		return current_theme.get(property_name)
	return fallback


# ---- Animations ----

func _animate_entrance() -> void:
	for i in range(_block_nodes.size()):
		var node: Control = _block_nodes[i]
		if not is_instance_valid(node):
			continue
		node.modulate.a = 0.0

		var delay: float = 0.03 * i
		var tween: Tween = create_tween()
		tween.tween_property(node, "modulate:a", 1.0, 0.22).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_active_tweens.append(tween)


func _setup_hover_effect(node: Control, shift_px: float) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_PASS

	node.mouse_entered.connect(func():
		if not is_instance_valid(node):
			return
		var old_tween: Tween = node.get_meta("hover_tween", null)
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		node.set_meta("base_x", node.position.x)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(node, "position:x", node.position.x + shift_px, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(node, "modulate", Color(1.12, 1.12, 1.18, 1.0), 0.12).set_ease(Tween.EASE_OUT)
		node.set_meta("hover_tween", tween)
		_active_tweens.append(tween)
	)

	node.mouse_exited.connect(func():
		if not is_instance_valid(node):
			return
		var old_tween: Tween = node.get_meta("hover_tween", null)
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		var base_x: float = node.get_meta("base_x", node.position.x)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(node, "position:x", base_x, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(node, "modulate", Color.WHITE, 0.2).set_ease(Tween.EASE_IN)
		node.set_meta("hover_tween", tween)
		_active_tweens.append(tween)
	)


func _setup_code_block_hover(panel: PanelContainer) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var original_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

	panel.mouse_entered.connect(func():
		if not is_instance_valid(panel):
			return
		var tween: Tween = create_tween()
		tween.tween_property(panel, "modulate", Color(1.1, 1.1, 1.15, 1.0), 0.15).set_ease(Tween.EASE_OUT)
		_active_tweens.append(tween)
	)

	panel.mouse_exited.connect(func():
		if not is_instance_valid(panel):
			return
		var tween: Tween = create_tween()
		tween.tween_property(panel, "modulate", original_modulate, 0.2).set_ease(Tween.EASE_IN)
		_active_tweens.append(tween)
	)


func _setup_link_handling(rtl: RichTextLabel) -> void:
	rtl.meta_clicked.connect(_on_meta_clicked)
	rtl.meta_hover_started.connect(_on_meta_hover_started.bind(rtl))
	rtl.meta_hover_ended.connect(_on_meta_hover_ended.bind(rtl))


func _on_meta_clicked(meta) -> void:
	var url: String = str(meta)
	if url.begins_with("http://") or url.begins_with("https://"):
		OS.shell_open(url)
	else:
		# Treat as local file link (e.g. other .md files)
		link_clicked.emit(url)


func _on_meta_hover_started(_meta, rtl: RichTextLabel) -> void:
	if not is_instance_valid(rtl):
		return
	var tween: Tween = create_tween()
	tween.tween_property(rtl, "modulate", Color(1.15, 1.15, 1.25, 1.0), 0.1).set_ease(Tween.EASE_OUT)
	_active_tweens.append(tween)


func _on_meta_hover_ended(_meta, rtl: RichTextLabel) -> void:
	if not is_instance_valid(rtl):
		return
	var tween: Tween = create_tween()
	tween.tween_property(rtl, "modulate", Color.WHITE, 0.15).set_ease(Tween.EASE_IN)
	_active_tweens.append(tween)


func _kill_active_tweens() -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()


# ---- Signals / Callbacks ----

func _on_close_requested() -> void:
	hide()


func _on_refresh_pressed() -> void:
	refresh(_current_text)


func _on_back_pressed() -> void:
	if _history_back.is_empty():
		return
	# Push current onto forward stack
	if _current_file_path != "":
		_history_forward.append(_current_file_path)
	var target_path: String = _history_back.pop_back()
	_update_nav_buttons()
	navigate_to.emit(target_path)


func _on_forward_pressed() -> void:
	if _history_forward.is_empty():
		return
	# Push current onto back stack
	if _current_file_path != "":
		_history_back.append(_current_file_path)
	var target_path: String = _history_forward.pop_back()
	_update_nav_buttons()
	navigate_to.emit(target_path)


func _update_nav_buttons() -> void:
	if _back_button:
		_back_button.disabled = _history_back.is_empty()
	if _forward_button:
		_forward_button.disabled = _history_forward.is_empty()


func _on_live_toggled(enabled: bool) -> void:
	live_update_toggled.emit(enabled)


func _on_debounce_timeout() -> void:
	_saved_scroll = _scroll_container.scroll_vertical
	_render(_current_text)
	call_deferred("_restore_scroll")


func _restore_scroll() -> void:
	_scroll_container.scroll_vertical = _saved_scroll
