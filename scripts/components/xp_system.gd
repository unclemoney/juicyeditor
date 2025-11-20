extends Node

## XP System - RPG-style progression tracking for Juicy Editor
## Manages player level, XP, achievements, and boss battle eligibility
## Autoload singleton - no class_name declaration

signal xp_gained(amount: int, reason: String)
signal level_up(new_level: int, xp_needed_for_next: int)
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal boss_battle_available(level: int)

## XP save file path
const XP_SAVE_FILE: String = "user://juicy_editor_xp.json"

## Current XP progress
var current_xp: int = 0

## Total lifetime XP earned
var total_xp: int = 0

## Current player level
var current_level: int = 1

## Achievements unlocked (Array of achievement IDs)
var unlocked_achievements: Array[String] = []

## Achievement metadata with unlock timestamps
var achievement_data: Dictionary = {}

## Boss battles completed (level numbers)
var completed_boss_battles: Array[int] = []

## Typing session statistics
var session_chars_typed: int = 0
var session_words_typed: int = 0
var session_errors_corrected: int = 0
var session_files_saved: int = 0
var lifetime_chars_typed: int = 0
var lifetime_words_typed: int = 0
var lifetime_errors_corrected: int = 0
var lifetime_files_saved: int = 0

## Last save timestamp for save discipline tracking
var last_save_time: int = 0

## Achievement definitions
var ACHIEVEMENTS: Dictionary = {
	"first_steps": {
		"name": "First Steps",
		"description": "Type your first 100 characters",
		"badge_file": "first_steps.png",
		"check": func(xp_sys): return xp_sys.lifetime_chars_typed >= 100
	},
	"typer": {
		"name": "Typer",
		"description": "Type 10,000 characters",
		"badge_file": "typer.png",
		"check": func(xp_sys): return xp_sys.lifetime_chars_typed >= 10000
	},
	"wordsmith": {
		"name": "Wordsmith",
		"description": "Write 5,000 words",
		"badge_file": "wordsmith.png",
		"check": func(xp_sys): return xp_sys.lifetime_words_typed >= 5000
	},
	"error_hunter": {
		"name": "Error Hunter",
		"description": "Correct 10 spelling errors",
		"badge_file": "error_hunter.png",
		"check": func(xp_sys): return xp_sys.lifetime_errors_corrected >= 10
	},
	"save_master": {
		"name": "Save Master",
		"description": "Save 50 files",
		"badge_file": "save_master.png",
		"check": func(xp_sys): return xp_sys.lifetime_files_saved >= 50
	},
	"speed_demon": {
		"name": "Speed Demon",
		"description": "Win a boss battle with 60+ WPM",
		"badge_file": "speed_demon.png",
		"check": func(xp_sys): return xp_sys.achievement_data.get("speed_demon_unlocked", false)
	},
	"level_10": {
		"name": "Rising Star",
		"description": "Reach level 10",
		"badge_file": "level_10.png",
		"check": func(xp_sys): return xp_sys.current_level >= 10
	},
	"level_25": {
		"name": "Master Wordsmith",
		"description": "Reach level 25",
		"badge_file": "level_25.png",
		"check": func(xp_sys): return xp_sys.current_level >= 25
	},
	"level_50": {
		"name": "Legendary Typist",
		"description": "Reach level 50",
		"badge_file": "level_50.png",
		"check": func(xp_sys): return xp_sys.current_level >= 50
	},
	"boss_slayer": {
		"name": "Boss Slayer",
		"description": "Complete 5 boss battles",
		"badge_file": "boss_slayer.png",
		"check": func(xp_sys): return xp_sys.completed_boss_battles.size() >= 5
	}
}

func _ready() -> void:
	print("XPSystem: _ready() started")
	print("XPSystem: current_level = ", current_level)
	print("XPSystem: current_xp = ", current_xp)
	print("XPSystem: ACHIEVEMENTS keys = ", ACHIEVEMENTS.keys())
	
	# Load XP data from dedicated JSON file
	_load_from_file()
	
	print("XPSystem: Initialized")

## Calculate XP needed for a given level using exponential curve
## Formula: XP_needed(n) = floor(100 * 1.5^(n-1))
func calculate_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(floor(100.0 * pow(1.5, level - 1)))

## Get XP needed to reach next level
func get_xp_for_next_level() -> int:
	return calculate_xp_for_level(current_level + 1)

## Get XP progress percentage for current level (0.0 to 1.0)
func get_level_progress() -> float:
	var xp_needed: int = get_xp_for_next_level()
	if xp_needed == 0:
		return 0.0
	return float(current_xp) / float(xp_needed)

## Award XP to the player
func add_xp(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	
	current_xp += amount
	total_xp += amount
	
	xp_gained.emit(amount, reason)
	
	print("XPSystem: Gained %d XP (%s). Current: %d/%d" % [amount, reason, current_xp, get_xp_for_next_level()])
	
	_check_level_up()
	_check_achievements()
	_auto_save_to_file()
	_auto_save_to_file()

## Check if player should level up
func _check_level_up() -> void:
	var xp_needed: int = get_xp_for_next_level()
	
	while current_xp >= xp_needed and xp_needed > 0:
		current_xp -= xp_needed
		current_level += 1
		
		print("XPSystem: LEVEL UP! Now level %d" % current_level)
		level_up.emit(current_level, get_xp_for_next_level())
		
		_check_boss_battle_unlock()
		_check_achievements()
		_auto_save_to_file()
		
		xp_needed = get_xp_for_next_level()

## Check if boss battle should be unlocked (every 5 levels)
func _check_boss_battle_unlock() -> void:
	if current_level % 5 == 0 and not completed_boss_battles.has(current_level):
		print("XPSystem: Boss battle available at level %d!" % current_level)
		boss_battle_available.emit(current_level)

## Check if boss battle is available for current level
func is_boss_battle_available() -> bool:
	return current_level % 5 == 0 and not completed_boss_battles.has(current_level)

## Get the next boss battle level
func get_next_boss_battle_level() -> int:
	var milestones_passed: int = int(float(current_level) / 5.0)
	var next_milestone: int = (milestones_passed + 1) * 5
	return next_milestone

## Complete a boss battle
func complete_boss_battle(level: int, wpm: float, accuracy: float) -> int:
	if completed_boss_battles.has(level):
		print("XPSystem: Boss battle at level %d already completed" % level)
		return 0
	
	completed_boss_battles.append(level)
	
	var base_xp: int = 100
	var speed_bonus: int = int(max(0, (wpm - 40) * 2))
	var accuracy_bonus: int = int(accuracy * 100)
	var total_bonus: int = base_xp + speed_bonus + accuracy_bonus
	
	print("XPSystem: Boss battle completed! WPM: %.1f, Accuracy: %.1f%%, XP: %d" % [wpm, accuracy * 100, total_bonus])
	
	if wpm >= 60:
		achievement_data["speed_demon_unlocked"] = true
		_check_achievements()
	
	add_xp(total_bonus, "Boss Battle Victory")
	
	return total_bonus

## Check and unlock achievements
func _check_achievements() -> void:
	for achievement_id in ACHIEVEMENTS.keys():
		if unlocked_achievements.has(achievement_id):
			continue
		
		var achievement: Dictionary = ACHIEVEMENTS[achievement_id]
		var check_func: Callable = achievement.check
		
		if check_func.call(self):
			_unlock_achievement(achievement_id)

## Unlock an achievement
func _unlock_achievement(achievement_id: String) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	
	unlocked_achievements.append(achievement_id)
	
	var achievement: Dictionary = ACHIEVEMENTS[achievement_id]
	var unlock_data: Dictionary = {
		"id": achievement_id,
		"name": achievement.name,
		"description": achievement.description,
		"badge_file": achievement.badge_file,
		"unlock_time": Time.get_unix_time_from_system()
	}
	
	achievement_data[achievement_id] = unlock_data
	
	print("XPSystem: Achievement unlocked! %s - %s" % [achievement.name, achievement.description])
	achievement_unlocked.emit(achievement_id, unlock_data)
	_auto_save_to_file()

## Track typing activity
func on_text_typed(char_count: int) -> void:
	session_chars_typed += char_count
	lifetime_chars_typed += char_count
	
	if char_count >= 100:
		add_xp(5, "Typing Streak")

## Track word milestones
func on_word_count_updated(word_count: int) -> void:
	var milestone_xp: Dictionary = {
		500: 50,
		1000: 100,
		5000: 200
	}
	
	for milestone in milestone_xp.keys():
		if lifetime_words_typed < milestone and word_count >= milestone:
			add_xp(milestone_xp[milestone], "%d Word Milestone" % milestone)
	
	var word_diff: int = word_count - lifetime_words_typed
	if word_diff > 0:
		lifetime_words_typed = word_count
		session_words_typed += word_diff

## Track error corrections
func on_error_corrected() -> void:
	session_errors_corrected += 1
	lifetime_errors_corrected += 1
	add_xp(25, "Error Correction")
	_check_achievements()

## Track file saves
func on_file_saved() -> void:
	session_files_saved += 1
	lifetime_files_saved += 1
	
	var current_time: int = int(Time.get_unix_time_from_system())
	
	if last_save_time > 0:
		var time_diff: int = current_time - last_save_time
		if time_diff < 300:
			add_xp(10, "Save Discipline")
	
	last_save_time = current_time
	_check_achievements()

## Get save data for persistence
func get_save_data() -> Dictionary:
	return {
		"current_xp": current_xp,
		"total_xp": total_xp,
		"current_level": current_level,
		"unlocked_achievements": unlocked_achievements,
		"achievement_data": achievement_data,
		"completed_boss_battles": completed_boss_battles,
		"lifetime_chars_typed": lifetime_chars_typed,
		"lifetime_words_typed": lifetime_words_typed,
		"lifetime_errors_corrected": lifetime_errors_corrected,
		"lifetime_files_saved": lifetime_files_saved,
		"last_save_time": last_save_time
	}

## Load save data from persistence
func load_save_data(data: Dictionary) -> void:
	print("XPSystem: load_save_data() started")
	print("XPSystem: data keys = ", data.keys())
	
	current_xp = data.get("current_xp", 0)
	print("XPSystem: current_xp = ", current_xp)
	
	total_xp = data.get("total_xp", 0)
	print("XPSystem: total_xp = ", total_xp)
	
	current_level = data.get("current_level", 1)
	print("XPSystem: current_level = ", current_level)
	
	# Load arrays with proper type conversion
	print("XPSystem: Loading unlocked_achievements...")
	var loaded_achievements = data.get("unlocked_achievements", [])
	print("XPSystem: loaded_achievements = ", loaded_achievements, " (type: ", typeof(loaded_achievements), ")")
	unlocked_achievements.clear()
	for achievement in loaded_achievements:
		if achievement is String:
			unlocked_achievements.append(achievement)
	print("XPSystem: unlocked_achievements loaded, count = ", unlocked_achievements.size())
	
	achievement_data = data.get("achievement_data", {})
	print("XPSystem: achievement_data loaded")
	
	print("XPSystem: Loading completed_boss_battles...")
	var loaded_boss_battles = data.get("completed_boss_battles", [])
	print("XPSystem: loaded_boss_battles = ", loaded_boss_battles, " (type: ", typeof(loaded_boss_battles), ")")
	completed_boss_battles.clear()
	for level in loaded_boss_battles:
		if level is int or level is float:
			completed_boss_battles.append(int(level))
	print("XPSystem: completed_boss_battles loaded, count = ", completed_boss_battles.size())
	
	lifetime_chars_typed = data.get("lifetime_chars_typed", 0)
	lifetime_words_typed = data.get("lifetime_words_typed", 0)
	lifetime_errors_corrected = data.get("lifetime_errors_corrected", 0)
	lifetime_files_saved = data.get("lifetime_files_saved", 0)
	last_save_time = data.get("last_save_time", 0)
	
	print("XPSystem: Loaded save data - Level %d, XP: %d/%d, Achievements: %d" % [
		current_level, current_xp, get_xp_for_next_level(), unlocked_achievements.size()
	])
	print("XPSystem: load_save_data() completed")

## Get all achievement info (for UI display)
func get_all_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	for achievement_id in ACHIEVEMENTS.keys():
		var achievement: Dictionary = ACHIEVEMENTS[achievement_id]
		var is_unlocked: bool = unlocked_achievements.has(achievement_id)
		
		result.append({
			"id": achievement_id,
			"name": achievement.name,
			"description": achievement.description,
			"badge_file": achievement.badge_file,
			"unlocked": is_unlocked,
			"unlock_data": achievement_data.get(achievement_id, {})
		})
	
	return result

## Load XP data from dedicated JSON file
func _load_from_file() -> void:
	if not FileAccess.file_exists(XP_SAVE_FILE):
		print("XPSystem: No save file found at ", XP_SAVE_FILE, ", starting fresh")
		return
	
	var file = FileAccess.open(XP_SAVE_FILE, FileAccess.READ)
	if not file:
		push_error("XPSystem: Failed to open save file for reading")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("XPSystem: Failed to parse save file JSON: ", json.get_error_message())
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("XPSystem: Save file does not contain a Dictionary")
		return
	
	# Load data using existing method
	load_save_data(data)
	print("XPSystem: Successfully loaded XP data from file")

## Save XP data to dedicated JSON file
func _auto_save_to_file() -> void:
	var data = get_save_data()
	
	var file = FileAccess.open(XP_SAVE_FILE, FileAccess.WRITE)
	if not file:
		push_error("XPSystem: Failed to open save file for writing")
		return
	
	var json_string = JSON.stringify(data, "\t")  # Pretty print with tabs
	file.store_string(json_string)
	file.close()
	
	print("XPSystem: Auto-saved XP data to file")

## Reset all XP stats to initial state
func reset_all_stats() -> void:
	print("XPSystem: Resetting all stats to initial state...")
	
	# Reset XP and level
	current_xp = 0
	total_xp = 0
	current_level = 1
	
	# Clear achievements
	unlocked_achievements.clear()
	achievement_data.clear()
	
	# Clear boss battles
	completed_boss_battles.clear()
	
	# Reset all stats
	session_chars_typed = 0
	session_words_typed = 0
	session_errors_corrected = 0
	session_files_saved = 0
	lifetime_chars_typed = 0
	lifetime_words_typed = 0
	lifetime_errors_corrected = 0
	lifetime_files_saved = 0
	last_save_time = 0
	
	# Emit signals to update UI
	level_up.emit(1, get_xp_for_next_level())
	
	# Save to file and settings
	_auto_save_to_file()
	
	print("XPSystem: All stats reset complete")
