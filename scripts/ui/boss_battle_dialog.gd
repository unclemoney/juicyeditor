extends Window
class_name BossBattleDialog

## Boss Battle Dialog - Typing challenge with time limit
## Tests typing speed and accuracy for bonus XP rewards

signal battle_completed(wpm: float, accuracy: float, success: bool)
signal battle_cancelled

## UI Components
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel
@onready var prompt_label: RichTextLabel = $MarginContainer/VBoxContainer/PromptContainer/PromptLabel
@onready var input_edit: TextEdit = $MarginContainer/VBoxContainer/InputEdit
@onready var wpm_label: Label = $MarginContainer/VBoxContainer/StatsContainer/WPMLabel
@onready var accuracy_label: Label = $MarginContainer/VBoxContainer/StatsContainer/AccuracyLabel
@onready var result_label: RichTextLabel = $MarginContainer/VBoxContainer/ResultLabel

## Battle state
var battle_level: int = 1
var time_limit: float = 60.0
var time_remaining: float = 60.0
var is_active: bool = false
var start_time: float = 0.0

## Typing stats
var prompt_text: String = ""
var chars_typed: int = 0
var correct_chars: int = 0
var total_chars: int = 0

## Practice prompts for different levels
var practice_prompts: Dictionary = {
	1: "The quick brown fox jumps over the lazy dog.",
	2: "Pack my box with five dozen liquor jugs.",
	3: "How vexingly quick daft zebras jump!",
	4: "The five boxing wizards jump quickly.",
	5: "Sphinx of black quartz, judge my vow.",
	6: "Crazy Fredrick bought many very exquisite opal jewels.",
	7: "Jack quickly judged the prize-winning fox.",
	8: "Waltz, bad nymph, for quick jigs vex.",
	9: "Bright vixens jump; dozy fowl quack.",
	10: "Jived fox nymph grabs quick waltz.",
	11: "Glib jocks quiz nymph to vex dwarf.",
	12: "Quick zephyrs blow, vexing daft Jim.",
	13: "Two driven jocks help fax my big quiz.",
	14: "Five quacking zephyrs jolt my wax bed.",
	15: "Heavy boxes perform quick waltzes and jigs.",
	16: "Jumping jovial zebras quickly vex dwarf sphinx with bold quips and frozen liquor jugs.",
	17: "Exquisite waltzing nymphs vex bold jocks, quizzing dwarves with jumpy frozen liquor packs.",
	18: "Quick brown foxes and daft wizards juggle vexing sphinxes while jived nymphs quack boldly.",
	19: "Zany dwarves vex jocks with quirky boxing wizards, while nimble sphinxes juggle frozen liquor.",
	20: "Funky jived nymphs vex quick dwarves, boxing sphinxes with bold liquor jugs and waltzing quips.",
	21: "Jumping sphinxes vex dwarves quickly, while bold jocks quip and nymphs juggle frozen liquor packs.",
	22: "Quickly vexed jocks juggle frozen liquor while sphinxes waltz boldly and nimble nymphs quack.",
	23: "Exquisite dwarves juggle quick frozen liquor jugs while sphinxes vex bold jocks with waltzing quips.",
	24: "Jived sphinxes vex dwarves boldly, while quick nymphs juggle frozen liquor packs and boxing wizards.",
	25: "Quick waltzing jocks vex dwarves with bold sphinxes, juggling frozen liquor and jumpy quips."
}


func _ready() -> void:
	# Setup window properties
	title = "Boss Battle Challenge!"
	size = Vector2i(600, 400)
	popup_window = true
	exclusive = false
	transient = true
	
	# Center on screen
	position = Vector2i(100,100)

	# Connect input changes
	if input_edit:
		input_edit.text_changed.connect(_on_input_changed)
	
	# Hide result label initially
	if result_label:
		result_label.visible = false

func start_battle(level: int) -> void:
	## Start a boss battle at the given level
	battle_level = level
	time_limit = 60.0
	time_remaining = time_limit
	is_active = true
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Reset stats
	chars_typed = 0
	correct_chars = 0
	total_chars = 0
	
	# Get prompt for this level
	prompt_text = practice_prompts.get(level, practice_prompts[1])
	total_chars = prompt_text.length()
	
	# Setup UI
	if title_label:
		title_label.text = "Boss Battle - Level %d" % level
	
	if prompt_label:
		prompt_label.text = "[center][b]Type this text:[/b][/center]\n\n" + prompt_text
	
	if input_edit:
		input_edit.text = ""
		input_edit.editable = true
		input_edit.grab_focus()
	
	if result_label:
		result_label.visible = false
	
	# Update initial display
	_update_stats_display()
	
	print("Boss Battle started at level %d" % level)

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Update timer
	time_remaining -= delta
	
	if timer_label:
		var time_int: int = floori(time_remaining)
		var minutes: int = time_int / 60
		var seconds: int = time_int % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]
		
		# Change color based on remaining time
		if time_remaining < 10.0:
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif time_remaining < 30.0:
			timer_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Check if time's up
	if time_remaining <= 0.0:
		_end_battle(false)

func _on_input_changed() -> void:
	## Called when user types in the input field
	if not is_active or not input_edit:
		return
	
	var typed_text: String = input_edit.text
	chars_typed = typed_text.length()
	
	# Calculate correct characters
	correct_chars = 0
	for i in range(min(chars_typed, total_chars)):
		if i < typed_text.length() and typed_text[i] == prompt_text[i]:
			correct_chars += 1
	
	# Update stats display
	_update_stats_display()
	
	# Check if completed
	if typed_text == prompt_text:
		_end_battle(true)

func _update_stats_display() -> void:
	## Update WPM and accuracy labels
	var elapsed_time: float = (Time.get_ticks_msec() / 1000.0) - start_time
	
	# Calculate WPM (words = chars / 5)
	var wpm: float = 0.0
	if elapsed_time > 0.0:
		var words: float = float(chars_typed) / 5.0
		var minutes: float = elapsed_time / 60.0
		wpm = words / minutes if minutes > 0.0 else 0.0
	
	# Calculate accuracy
	var accuracy: float = 0.0
	if chars_typed > 0:
		accuracy = (float(correct_chars) / float(chars_typed)) * 100.0
	else:
		accuracy = 100.0
	
	# Update labels
	if wpm_label:
		wpm_label.text = "WPM: %.1f" % wpm
	
	if accuracy_label:
		accuracy_label.text = "Accuracy: %.1f%%" % accuracy

func _end_battle(success: bool) -> void:
	## End the battle and calculate final results
	if not is_active:
		return
	
	is_active = false
	
	var elapsed_time: float = (Time.get_ticks_msec() / 1000.0) - start_time
	
	# Calculate final WPM
	var final_wpm: float = 0.0
	if elapsed_time > 0.0:
		var words: float = float(chars_typed) / 5.0
		var minutes: float = elapsed_time / 60.0
		final_wpm = words / minutes if minutes > 0.0 else 0.0
	
	# Calculate final accuracy
	var final_accuracy: float = 0.0
	if chars_typed > 0:
		final_accuracy = (float(correct_chars) / float(chars_typed)) * 100.0
	else:
		final_accuracy = 0.0
	
	# Disable input
	if input_edit:
		input_edit.editable = false
	
	# Show result
	if result_label:
		result_label.visible = true
		if success:
			result_label.text = "[center][color=green][b]VICTORY![/b][/color]\n\nWPM: %.1f | Accuracy: %.1f%%[/center]" % [final_wpm, final_accuracy]
		else:
			result_label.text = "[center][color=red][b]TIME'S UP![/b][/color]\n\nWPM: %.1f | Accuracy: %.1f%%[/center]" % [final_wpm, final_accuracy]
	
	# Emit completion signal
	battle_completed.emit(final_wpm, final_accuracy, success)
	
	# Call XP System
	var xp_system = get_node_or_null("/root/XPSystem")
	if xp_system and xp_system.has_method("complete_boss_battle"):
		xp_system.complete_boss_battle(battle_level, final_wpm, final_accuracy)
	
	# Close dialog after delay
	await get_tree().create_timer(3.0).timeout
	hide()
	
	print("Boss Battle ended - Success: %s, WPM: %.1f, Accuracy: %.1f%%" % [success, final_wpm, final_accuracy])

func _on_close_requested() -> void:
	## Handle window close button
	if is_active:
		is_active = false
		battle_cancelled.emit()
	hide()
