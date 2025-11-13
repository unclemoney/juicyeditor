extends Node

## Quick test script for spell checker
## Run this scene to test the dictionary loading

@onready var spell_checker: Node

func _ready() -> void:
	print("=== SPELL CHECKER TEST ===")
	
	# Load spell checker
	var SymSpellChecker: GDScript = load("res://scripts/components/symspell_checker.gd")
	spell_checker = SymSpellChecker.new()
	add_child(spell_checker)
	
	# Wait for dictionary to load
	await get_tree().create_timer(2.0).timeout
	
	print("\n=== TESTING WORDS ===")
	
	# Test correct words
	var correct_words: Array = ["the", "am", "is", "are", "what", "else", "interesting"]
	print("\nCorrect words:")
	for word in correct_words:
		var is_correct: bool = spell_checker.is_correct(word)
		print("  '%s': %s" % [word, "✓ CORRECT" if is_correct else "✗ INCORRECT"])
	
	# Test misspelled words
	var misspelled_words: Array = ["teh", "recieve", "wronng", "definately", "occured"]
	print("\nMisspelled words:")
	for word in misspelled_words:
		var is_correct: bool = spell_checker.is_correct(word)
		var suggestions: Array = spell_checker.get_suggestions(word, 3)
		print("  '%s': %s" % [word, "✓ CORRECT" if is_correct else "✗ INCORRECT"])
		if suggestions.size() > 0:
			print("    Suggestions: %s" % [", ".join(suggestions.map(func(s): return s.term))])
	
	# Test full text checking
	print("\n=== TESTING TEXT ===")
	var test_text: String = "This is a tst of the spel checker with wronng words."
	print("Text: '%s'" % test_text)
	var errors: Array = spell_checker.check_text(test_text)
	print("Errors found: %d" % errors.size())
	for error in errors:
		print("  - '%s' at pos %d-%d" % [error.word, error.start_pos, error.end_pos])
		if error.suggestions.size() > 0:
			print("    Suggestion: %s" % error.suggestions[0].term)
	
	print("\n=== TEST COMPLETE ===")
	
	# Exit after 1 second
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
