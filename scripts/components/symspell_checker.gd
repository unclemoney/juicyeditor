extends Node

## SymSpell Spell Checker
## A GDScript implementation of the SymSpell symmetric delete spelling correction algorithm
## Based on: https://github.com/wolfgarbe/SymSpell
## Uses frequency_bigramdictionary_en_243_342.txt for word frequency data

## Signal emitted when dictionary is loaded
signal dictionary_loaded(word_count: int)

## Signal emitted when a spelling error is found
signal spelling_error_found(word: String, suggestions: Array)

## Maximum edit distance for dictionary precalculation
@export var max_edit_distance: int = 2

## Maximum edit distance for lookup
@export var max_lookup_distance: int = 2

## Prefix length for optimization
@export var prefix_length: int = 7

## Dictionary storage: word -> frequency count
var dictionary: Dictionary = {}

## Delete suggestions storage: delete_variant -> [original_words]
var deletes: Dictionary = {}

## Maximum dictionary word length
var max_dictionary_word_length: int = 0

## Is the dictionary loaded?
var is_loaded: bool = false

## Loading progress
var load_progress: float = 0.0


func _ready() -> void:
	# Auto-load dictionary on ready
	call_deferred("load_dictionary", "res://assets/dictionary/frequency_bigramdictionary_en_243_342.txt")


## Load frequency dictionary from file
## Dictionary format: "word1 word2" <tab> frequency
func load_dictionary(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("SymSpell: Dictionary file not found at %s" % file_path)
		return false
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("SymSpell: Could not open dictionary file at %s" % file_path)
		return false
	
	print("SymSpell: Loading dictionary from %s..." % file_path)
	var line_count: int = 0
	var words_loaded: int = 0
	
	# For bigram dictionary, format is: "word1 word2 frequency" (space-separated)
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		
		line_count += 1
		
		# Split by space - last part is frequency, rest are words
		var parts: PackedStringArray = line.split(" ")
		if parts.size() < 2:
			continue
		
		# Last element is frequency, everything before is words
		var frequency: int = parts[parts.size() - 1].to_int()
		
		# Add each word individually (excluding the frequency)
		for i in range(parts.size() - 1):
			var word: String = parts[i].to_lower().strip_edges()
			if word.length() > 0 and word.length() < 100:
				if not dictionary.has(word):
					dictionary[word] = frequency
					words_loaded += 1
				else:
					# Keep highest frequency for each word
					dictionary[word] = max(dictionary[word], frequency)
				
				# Track max length
				if word.length() > max_dictionary_word_length:
					max_dictionary_word_length = word.length()
		
		# Update progress every 10000 lines
		if line_count % 10000 == 0:
			load_progress = float(file.get_position()) / float(file.get_length())
	
	file.close()
	
	print("SymSpell: Loaded %d unique words from %d lines" % [words_loaded, line_count])
	print("SymSpell: Generating delete variants...")
	
	# Generate all delete variants for precalculation
	var delete_count: int = 0
	for word in dictionary.keys():
		var delete_variants: Array = _get_deletes(word, 0, max_edit_distance)
		for delete_variant in delete_variants:
			if not deletes.has(delete_variant):
				deletes[delete_variant] = []
			deletes[delete_variant].append(word)
			delete_count += 1
	
	is_loaded = true
	load_progress = 1.0
	
	print("SymSpell: Generated %d delete variants for %d words" % [delete_count, dictionary.size()])
	
	# Debug: Print sample words from dictionary
	print("SymSpell: Sample words in dictionary:")
	var sample_words: Array = ["the", "am", "is", "are", "what", "how", "why", "where", "when", "who"]
	for word in sample_words:
		if dictionary.has(word):
			print("  ✓ '%s' - frequency: %d" % [word, dictionary[word]])
		else:
			print("  ✗ '%s' - NOT FOUND" % word)
	
	dictionary_loaded.emit(dictionary.size())
	
	return true


## Lookup spelling suggestions for a word
## Returns array of suggestion dictionaries: [{term: String, distance: int, frequency: int}]
func lookup(input_word: String, max_distance: int = -1) -> Array:
	if not is_loaded:
		push_warning("SymSpell: Dictionary not loaded yet")
		return []
	
	if max_distance < 0:
		max_distance = max_lookup_distance
	
	input_word = input_word.to_lower().strip_edges()
	
	if input_word.is_empty():
		return []
	
	# If word is in dictionary, it's correct
	if dictionary.has(input_word):
		return [{
			"term": input_word,
			"distance": 0,
			"frequency": dictionary[input_word]
		}]
	
	# If word is too long, it's likely not in dictionary
	if input_word.length() - max_distance > max_dictionary_word_length:
		return []
	
	var suggestions: Dictionary = {}
	var candidates: Array = []
	
	# Generate deletes of input word
	candidates.append(input_word)
	candidates.append_array(_get_deletes(input_word, 0, max_distance))
	
	# Look up each candidate
	for candidate in candidates:
		if deletes.has(candidate):
			# Found matching delete variants
			for suggestion in deletes[candidate]:
				if suggestions.has(suggestion):
					continue
				
				# Calculate actual edit distance
				var distance: int = _damerau_levenshtein_distance(input_word, suggestion)
				
				if distance <= max_distance:
					suggestions[suggestion] = {
						"term": suggestion,
						"distance": distance,
						"frequency": dictionary.get(suggestion, 0)
					}
	
	# Convert to array and sort by distance (ascending), then frequency (descending)
	var result: Array = suggestions.values()
	result.sort_custom(func(a, b):
		if a.distance != b.distance:
			return a.distance < b.distance
		return a.frequency > b.frequency
	)
	
	return result


## Check if a word is spelled correctly
func is_correct(word: String) -> bool:
	word = word.to_lower().strip_edges()
	return dictionary.has(word)


## Get spelling suggestions for a word (simplified lookup)
func get_suggestions(word: String, max_count: int = 5) -> Array:
	var results: Array = lookup(word, max_lookup_distance)
	
	# Filter out the exact match if it exists
	results = results.filter(func(s): return s.distance > 0)
	
	# Return top suggestions
	if results.size() > max_count:
		results = results.slice(0, max_count)
	
	return results


## Generate all delete variants up to max_distance
## Uses recursion with memoization
func _get_deletes(word: String, current_distance: int, max_distance: int) -> Array:
	var deletes_list: Array = []
	
	if word.length() <= 1 or current_distance >= max_distance:
		return deletes_list
	
	# Generate all single-character deletes
	for i in range(word.length()):
		var delete_variant: String = word.substr(0, i) + word.substr(i + 1)
		
		if not delete_variant in deletes_list:
			deletes_list.append(delete_variant)
			
			# Recursively generate further deletes
			if current_distance + 1 < max_distance:
				var sub_deletes: Array = _get_deletes(delete_variant, current_distance + 1, max_distance)
				for sub_delete in sub_deletes:
					if not sub_delete in deletes_list:
						deletes_list.append(sub_delete)
	
	return deletes_list


## Calculate Damerau-Levenshtein distance between two strings
## Supports: insertions, deletions, substitutions, and transpositions
func _damerau_levenshtein_distance(source: String, target: String) -> int:
	var len1: int = source.length()
	var len2: int = target.length()
	
	if len1 == 0:
		return len2
	if len2 == 0:
		return len1
	
	# Create distance matrix
	var matrix: Array = []
	for i in range(len1 + 1):
		var row: Array = []
		row.resize(len2 + 1)
		matrix.append(row)
	
	# Initialize first column and row
	for i in range(len1 + 1):
		matrix[i][0] = i
	for j in range(len2 + 1):
		matrix[0][j] = j
	
	# Calculate distances
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost: int = 0 if source[i - 1] == target[j - 1] else 1
			
			matrix[i][j] = min(
				matrix[i - 1][j] + 1,      # deletion
				min(
					matrix[i][j - 1] + 1,  # insertion
					matrix[i - 1][j - 1] + cost  # substitution
				)
			)
			
			# Transposition
			if i > 1 and j > 1 and source[i - 1] == target[j - 2] and source[i - 2] == target[j - 1]:
				matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + cost)
	
	return matrix[len1][len2]


## Extract words from text for spell checking
## Returns array of {word: String, start_pos: int, end_pos: int}
func extract_words(text: String) -> Array:
	var words: Array = []
	var current_word: String = ""
	var start_pos: int = -1
	
	for i in range(text.length()):
		var c: String = text[i]
		
		# Check if character is alphabetic or apostrophe (for contractions)
		var is_alpha: bool = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')
		var is_apostrophe: bool = (c == "'" and current_word.length() > 0)
		
		if is_alpha or is_apostrophe:
			if current_word.is_empty():
				start_pos = i
			current_word += c
		else:
			# End of word
			if not current_word.is_empty():
				# Filter out single characters only
				if current_word.length() > 1:
					words.append({
						"word": current_word,
						"start_pos": start_pos,
						"end_pos": i - 1
					})
				current_word = ""
				start_pos = -1
	
	# Handle last word
	if not current_word.is_empty():
		if current_word.length() > 1:
			words.append({
				"word": current_word,
				"start_pos": start_pos,
				"end_pos": text.length() - 1
			})
	
	return words


## Check text for spelling errors
## Returns array of {word: String, start_pos: int, end_pos: int, suggestions: Array}
func check_text(text: String) -> Array:
	var errors: Array = []
	var words: Array = extract_words(text)
	
	print("SymSpell: Checking %d words..." % words.size())
	
	for word_info in words:
		var word: String = word_info.word
		var is_word_correct: bool = is_correct(word)
		
		print("  Checking '%s': %s (in dict: %s)" % [word, "CORRECT" if is_word_correct else "INCORRECT", "yes" if dictionary.has(word.to_lower()) else "no"])
		
		if not is_word_correct:
			var suggestions: Array = get_suggestions(word, 3)
			errors.append({
				"word": word,
				"start_pos": word_info.start_pos,
				"end_pos": word_info.end_pos,
				"suggestions": suggestions
			})
	
	print("SymSpell: Found %d errors" % errors.size())
	return errors
