extends RefCounted
class_name MarkdownParser

## MarkdownParser
## Parses raw markdown text into an array of typed block dictionaries.
## Each block has a "type" key and type-specific data.

# Pre-compiled regex patterns
var _regex_heading: RegEx
var _regex_hr: RegEx
var _regex_unordered_list: RegEx
var _regex_ordered_list: RegEx
var _regex_task_list: RegEx
var _regex_blockquote: RegEx
var _regex_code_fence: RegEx
var _regex_table_row: RegEx
var _regex_image: RegEx

# Inline regex patterns
var _regex_bold_italic: RegEx
var _regex_bold: RegEx
var _regex_italic: RegEx
var _regex_inline_code: RegEx
var _regex_link: RegEx


func _init() -> void:
	_compile_patterns()


func _compile_patterns() -> void:
	_regex_heading = RegEx.new()
	_regex_heading.compile("^(#{1,6})\\s+(.*)")

	_regex_hr = RegEx.new()
	_regex_hr.compile("^(---+|\\*\\*\\*+|___+)\\s*$")

	_regex_unordered_list = RegEx.new()
	_regex_unordered_list.compile("^(\\s*)[\\-\\*\\+]\\s+(.*)")

	_regex_ordered_list = RegEx.new()
	_regex_ordered_list.compile("^(\\s*)\\d+\\.\\s+(.*)")

	_regex_task_list = RegEx.new()
	_regex_task_list.compile("^(\\s*)[\\-\\*\\+]\\s+\\[([ xX])\\]\\s+(.*)")

	_regex_blockquote = RegEx.new()
	_regex_blockquote.compile("^>\\s?(.*)")

	_regex_code_fence = RegEx.new()
	_regex_code_fence.compile("^```(.*)")

	_regex_table_row = RegEx.new()
	_regex_table_row.compile("^\\|(.+)\\|\\s*$")

	_regex_image = RegEx.new()
	_regex_image.compile("^!\\[([^\\]]*)\\]\\(([^\\)]+)\\)")

	# Inline patterns
	_regex_bold_italic = RegEx.new()
	_regex_bold_italic.compile("\\*\\*\\*(.+?)\\*\\*\\*")

	_regex_bold = RegEx.new()
	_regex_bold.compile("\\*\\*(.+?)\\*\\*")

	_regex_italic = RegEx.new()
	_regex_italic.compile("(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)")

	_regex_inline_code = RegEx.new()
	_regex_inline_code.compile("`([^`]+)`")

	_regex_link = RegEx.new()
	_regex_link.compile("(?<!!)\\[([^\\]]+)\\]\\(([^\\)]+)\\)")


## parse
## Main public method. Converts raw markdown text into an Array of block Dictionaries.
func parse(text: String) -> Array:
	var blocks: Array = []
	var lines: PackedStringArray = text.split("\n")
	var i: int = 0
	var total: int = lines.size()

	while i < total:
		var line: String = lines[i]

		# --- Code fence ---
		var code_match = _regex_code_fence.search(line)
		if code_match:
			var language: String = code_match.get_string(1).strip_edges()
			var code_lines: PackedStringArray = []
			i += 1
			while i < total:
				var end_match = _regex_code_fence.search(lines[i])
				if end_match and lines[i].strip_edges() == "```":
					break
				code_lines.append(lines[i])
				i += 1
			blocks.append({
				"type": "code_block",
				"language": language,
				"text": "\n".join(code_lines)
			})
			i += 1
			continue

		# --- Blank line (paragraph separator) ---
		if line.strip_edges() == "":
			i += 1
			continue

		# --- Horizontal rule ---
		var hr_match = _regex_hr.search(line)
		if hr_match:
			blocks.append({"type": "horizontal_rule"})
			i += 1
			continue

		# --- Image (standalone line) ---
		var img_match = _regex_image.search(line.strip_edges())
		if img_match:
			blocks.append({
				"type": "image",
				"alt": img_match.get_string(1),
				"src": img_match.get_string(2)
			})
			i += 1
			continue

		# --- Heading ---
		var heading_match = _regex_heading.search(line)
		if heading_match:
			var level: int = heading_match.get_string(1).length()
			var heading_text: String = heading_match.get_string(2).strip_edges()
			blocks.append({
				"type": "heading",
				"level": level,
				"spans": parse_inline(heading_text)
			})
			i += 1
			continue

		# --- Task list (must check before unordered list) ---
		var task_match = _regex_task_list.search(line)
		if task_match:
			var items: Array = []
			while i < total:
				var tm = _regex_task_list.search(lines[i])
				if not tm:
					break
				var checked: bool = tm.get_string(2).to_lower() == "x"
				var indent: int = tm.get_string(1).length()
				items.append({
					"checked": checked,
					"spans": parse_inline(tm.get_string(3)),
					"indent": indent
				})
				i += 1
			blocks.append({
				"type": "task_list",
				"items": items
			})
			continue

		# --- Ordered list ---
		var ol_match = _regex_ordered_list.search(line)
		if ol_match:
			var items: Array = []
			var number: int = 1
			while i < total:
				var om = _regex_ordered_list.search(lines[i])
				if not om:
					break
				var indent: int = om.get_string(1).length()
				items.append({
					"spans": parse_inline(om.get_string(2)),
					"indent": indent,
					"number": number
				})
				number += 1
				i += 1
			blocks.append({
				"type": "ordered_list",
				"items": items
			})
			continue

		# --- Unordered list ---
		var ul_match = _regex_unordered_list.search(line)
		if ul_match:
			var items: Array = []
			while i < total:
				# Check task list first to avoid matching task items as plain list items
				var tm = _regex_task_list.search(lines[i])
				if tm:
					break
				var um = _regex_unordered_list.search(lines[i])
				if not um:
					break
				var indent: int = um.get_string(1).length()
				items.append({
					"spans": parse_inline(um.get_string(2)),
					"indent": indent
				})
				i += 1
			blocks.append({
				"type": "unordered_list",
				"items": items
			})
			continue

		# --- Blockquote ---
		var bq_match = _regex_blockquote.search(line)
		if bq_match:
			var bq_lines: PackedStringArray = []
			while i < total:
				var bm = _regex_blockquote.search(lines[i])
				if not bm:
					break
				bq_lines.append(bm.get_string(1))
				i += 1
			blocks.append({
				"type": "blockquote",
				"spans": parse_inline("\n".join(bq_lines))
			})
			continue

		# --- Table ---
		var table_match = _regex_table_row.search(line)
		if table_match:
			var headers: Array = []
			var rows: Array = []
			# First row = headers
			var header_cells: PackedStringArray = table_match.get_string(1).split("|")
			for cell in header_cells:
				headers.append(cell.strip_edges())
			i += 1
			# Skip separator row (e.g. |---|---|)
			if i < total:
				var sep_line: String = lines[i].strip_edges()
				if sep_line.contains("---"):
					i += 1
			# Data rows
			while i < total:
				var row_match = _regex_table_row.search(lines[i])
				if not row_match:
					break
				var cells: Array = []
				var raw_cells: PackedStringArray = row_match.get_string(1).split("|")
				for cell in raw_cells:
					cells.append(cell.strip_edges())
				rows.append(cells)
				i += 1
			blocks.append({
				"type": "table",
				"headers": headers,
				"rows": rows
			})
			continue

		# --- Paragraph (default) ---
		var para_lines: PackedStringArray = []
		while i < total:
			var current: String = lines[i]
			if current.strip_edges() == "":
				break
			# Stop if next line is a block-level element
			if _regex_heading.search(current):
				break
			if _regex_hr.search(current):
				break
			if _regex_code_fence.search(current):
				break
			if _regex_unordered_list.search(current):
				break
			if _regex_ordered_list.search(current):
				break
			if _regex_task_list.search(current):
				break
			if _regex_blockquote.search(current):
				break
			if _regex_table_row.search(current):
				break
			if _regex_image.search(current.strip_edges()):
				break
			para_lines.append(current)
			i += 1
		if para_lines.size() > 0:
			var para_text: String = " ".join(para_lines)
			blocks.append({
				"type": "paragraph",
				"spans": parse_inline(para_text)
			})
		continue

	return blocks


## parse_inline
## Parses inline markdown elements into an Array of span dictionaries.
## Each span has: { kind: String, text: String, url: String (for links) }
func parse_inline(text: String) -> Array:
	var spans: Array = []
	var remaining: String = text
	
	while remaining.length() > 0:
		var earliest_pos: int = remaining.length()
		var earliest_type: String = ""
		var earliest_match: RegExMatch = null

		# Find the earliest inline match
		var bold_italic_m = _regex_bold_italic.search(remaining)
		if bold_italic_m and bold_italic_m.get_start() < earliest_pos:
			earliest_pos = bold_italic_m.get_start()
			earliest_type = "bold_italic"
			earliest_match = bold_italic_m

		var bold_m = _regex_bold.search(remaining)
		if bold_m and bold_m.get_start() < earliest_pos:
			earliest_pos = bold_m.get_start()
			earliest_type = "bold"
			earliest_match = bold_m

		var italic_m = _regex_italic.search(remaining)
		if italic_m and italic_m.get_start() < earliest_pos:
			earliest_pos = italic_m.get_start()
			earliest_type = "italic"
			earliest_match = italic_m

		var code_m = _regex_inline_code.search(remaining)
		if code_m and code_m.get_start() < earliest_pos:
			earliest_pos = code_m.get_start()
			earliest_type = "code"
			earliest_match = code_m

		var link_m = _regex_link.search(remaining)
		if link_m and link_m.get_start() < earliest_pos:
			earliest_pos = link_m.get_start()
			earliest_type = "link"
			earliest_match = link_m

		# No inline elements found — rest is plain text
		if earliest_type == "":
			if remaining.length() > 0:
				spans.append({"kind": "text", "text": remaining})
			break

		# Add any text before the match as plain text
		if earliest_pos > 0:
			spans.append({"kind": "text", "text": remaining.substr(0, earliest_pos)})

		# Add the matched inline element
		match earliest_type:
			"bold_italic":
				spans.append({"kind": "bold_italic", "text": earliest_match.get_string(1)})
			"bold":
				spans.append({"kind": "bold", "text": earliest_match.get_string(1)})
			"italic":
				spans.append({"kind": "italic", "text": earliest_match.get_string(1)})
			"code":
				spans.append({"kind": "code", "text": earliest_match.get_string(1)})
			"link":
				spans.append({
					"kind": "link",
					"text": earliest_match.get_string(1),
					"url": earliest_match.get_string(2)
				})

		# Advance past the matched text
		var match_end: int = earliest_match.get_start() + earliest_match.get_string().length()
		remaining = remaining.substr(match_end)

	return spans
