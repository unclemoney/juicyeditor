# Juicy Editor - Spell Checker Documentation

## Overview

Juicy Editor includes a local spell checker based on the **SymSpell** algorithm, integrated with the **Juicy Lucy** assistant for delightfully sassy feedback on spelling errors.

## Architecture

### Components

1. **SymSpellChecker** (`scripts/components/symspell_checker.gd`)
   - Pure GDScript implementation of the SymSpell algorithm
   - Loads and manages the frequency dictionary
   - Provides spell checking functionality
   - Generates spelling suggestions

2. **JuicyLucy Integration** (`scripts/components/juicy_lucy.gd`)
   - Monitors text changes from the editor
   - Triggers spell checking after 2-3 second delay
   - Displays sassy error messages with suggestions
   - Shows upset eyebrows when errors are found

3. **Frequency Dictionary** (`assets/dictionary/frequency_bigramdictionary_en_243_342.txt`)
   - 242,343 lines of English word frequency data
   - Format: "word1 word2 \t frequency"
   - Extracts individual words for single-word checking
   - Provides frequency-based suggestion ranking

## SymSpell Algorithm

### What is SymSpell?

SymSpell is a spelling correction algorithm that is **1 million times faster** than traditional approaches (like Peter Norvig's algorithm). It achieves this speed through:

1. **Symmetric Delete**: Only generates delete edits (not inserts, replaces, transposes)
2. **Pre-calculation**: All delete variants are computed once during dictionary loading
3. **Fast Lookup**: At query time, only deletes of the input word are generated and looked up

### How It Works

**Dictionary Pre-calculation:**
```
Original word: "example" (frequency: 1000)

Generate deletes (edit distance 1):
- "xample", "eample", "exmple", "exaple", "examle", "exampe", "exampl"

Generate deletes (edit distance 2):
- "ample", "xmple", "xamle", ... (all 2-char deletes)

Store mapping: delete_variant -> [original_words]
```

**Spell Checking:**
```
Input: "exampl" (missing 'e')

Generate deletes of input:
- "xampl", "eampl", "exmpl", "examl", "examp"

Look up each delete in pre-calculated dictionary
Find "exampl" maps to "example"
Calculate edit distance: 1
Return suggestion: "example" (distance: 1, frequency: 1000)
```

### Edit Distance

The checker uses **Damerau-Levenshtein distance**, which counts:
- Insertions: "exmple" → "example" (insert 'a')
- Deletions: "examplle" → "example" (delete 'l')
- Substitutions: "wxample" → "example" (replace 'w' with 'e')
- Transpositions: "examlpe" → "example" (swap 'l' and 'p')

Maximum edit distance is configurable (default: 2).

## Usage

### Automatic Spell Checking

Spell checking happens automatically:
1. User types in the text editor
2. After 2-3 seconds of no typing, Lucy checks for errors
3. If errors are found, Lucy picks one randomly
4. Lucy displays upset eyebrows and a sassy message
5. Lucy provides the best spelling suggestion

### No Visual Clutter

Unlike traditional spell checkers:
- Words are **NOT** underlined in red
- No squiggly lines or highlighting
- Lucy just tells you about errors verbally

This keeps the editing experience clean while still providing helpful feedback.

### Sassy Feedback

Lucy has 10 different sassy phrases for spelling errors:
- "You didn't spell '%s' correctly, you dumb bitch."
- "Really? '%s'? That's not even close to a real word."
- "I'm pretty sure '%s' isn't how you spell that, genius."
- "Oh honey, '%s' is not a word. Not even a little bit."
- "'%s'? Did you even try to spell that correctly?"
- And 5 more...

Each message includes the misspelled word and, when available, the best suggestion:
> "You didn't spell 'recieve' correctly, you dumb bitch. Did you mean 'receive'?"

## Configuration

### Dictionary Settings

Located in `symspell_checker.gd`:

```gdscript
@export var max_edit_distance: int = 2        # Maximum edit distance for dictionary
@export var max_lookup_distance: int = 2      # Maximum edit distance for lookups
@export var prefix_length: int = 7            # Prefix length for optimization
```

**max_edit_distance**: Higher values find more suggestions but use more memory
**max_lookup_distance**: Higher values find more distant corrections but take longer
**prefix_length**: Longer prefixes use less memory but may miss some suggestions

### Timing Settings

Located in `juicy_lucy.gd`:

```gdscript
# Spell check timer is set in on_text_changed():
spell_check_timer.wait_time = randf_range(2.0, 3.0)
```

You can adjust the 2.0 and 3.0 values to change the delay before spell checking.

## Performance

### Dictionary Loading
- **242,343 lines** processed
- **~80,000 unique words** extracted
- **~500,000 delete variants** generated
- **Loading time**: 5-10 seconds on startup
- **Memory usage**: ~50-100 MB (depending on dictionary size)

### Spell Checking
- **Check speed**: < 1ms for short documents
- **Suggestion generation**: < 5ms per word
- **Edit distance calculation**: O(n*m) where n,m are word lengths
- **Lookup complexity**: O(1) dictionary access

## Word Extraction

The spell checker intelligently extracts words from text:

```gdscript
func extract_words(text: String) -> Array:
    # Filters:
    # - Must be 2+ characters
    # - Cannot be a pure number
    # - Can contain apostrophes for contractions
    # - Extracts word boundaries
```

**Recognized as words:**
- "don't" (apostrophe for contraction)
- "example" (standard word)
- "GDScript" (capitalized word, lowercased for checking)

**Ignored:**
- "123" (pure number)
- "a" (single character)
- "I" (single character)

## API Reference

### SymSpellChecker Class

#### Methods

**load_dictionary(file_path: String) -> bool**
- Loads the frequency dictionary from file
- Generates all delete variants
- Returns true on success
- Emits `dictionary_loaded(word_count)` signal

**lookup(input_word: String, max_distance: int = -1) -> Array**
- Finds spelling suggestions for a word
- Returns array of dictionaries: `{term: String, distance: int, frequency: int}`
- Suggestions sorted by distance (ascending) then frequency (descending)

**is_correct(word: String) -> bool**
- Checks if a word is spelled correctly
- Returns true if word exists in dictionary
- Case-insensitive

**get_suggestions(word: String, max_count: int = 5) -> Array**
- Simplified lookup that returns top suggestions
- Filters out exact matches
- Limits results to max_count

**check_text(text: String) -> Array**
- Checks entire text for spelling errors
- Returns array of error dictionaries: `{word: String, start_pos: int, end_pos: int, suggestions: Array}`
- Automatically extracts and checks all words

**extract_words(text: String) -> Array**
- Extracts individual words from text
- Returns array of word info: `{word: String, start_pos: int, end_pos: int}`
- Handles contractions and filters numbers

#### Signals

**dictionary_loaded(word_count: int)**
- Emitted when dictionary loading completes
- Provides count of loaded words

**spelling_error_found(word: String, suggestions: Array)**
- Reserved for future use
- Can be connected for custom error handling

### JuicyLucy Integration

#### Spell Check Methods

**on_text_changed(new_text: String) -> void**
- Called when text editor content changes
- Restarts the 2-3 second spell check timer
- Automatically triggers spell checking after delay

**check_spelling_now() -> void**
- Manually triggers spell check immediately
- Bypasses the timer delay
- Useful for testing or custom integrations

## Testing

### Test File

A test file is included: `SPELL_CHECK_TEST.md`

This file contains:
- Simple misspellings (teh, recieve, occured)
- Common typos (adn, thet, waht)
- Transposition errors (hte, taht)
- Correctly spelled sections
- Instructions for testing

### How to Test

1. Open Juicy Editor
2. Open `SPELL_CHECK_TEST.md`
3. Wait 2-3 seconds
4. Lucy should detect errors and comment
5. Type new misspellings
6. Wait 2-3 seconds
7. Lucy should catch the new errors

### Expected Behavior

When errors are found:
1. Lucy's eyebrows change to "upset" animation
2. Lucy's dialog box appears with sassy message
3. Message includes the misspelled word
4. Message includes best suggestion (if available)
5. Dialog displays for 5 seconds
6. Lucy returns to normal state

## Customization

### Adding New Phrases

Edit `juicy_lucy.gd` and add to the `spelling_error_phrases` array:

```gdscript
var spelling_error_phrases: Array = [
    "Your custom phrase with '%s' placeholder",
    # ... more phrases
]
```

The `%s` is replaced with the misspelled word.

### Changing Emotions

The spell checker triggers the "upset" emotion. You can change this in `_on_spell_check_timer_timeout()`:

```gdscript
_set_emotion("upset")  # Change to "angry", "sad", "shocked", etc.
```

Make sure to add corresponding eyebrow animations in the AnimationPlayer.

### Custom Dictionary

To use a different dictionary:
1. Format: "word \t frequency" (one per line)
2. Update the path in `symspell_checker.gd`:
   ```gdscript
   call_deferred("load_dictionary", "res://path/to/your/dictionary.txt")
   ```

## Troubleshooting

### Dictionary Not Loading
**Problem**: Spell checker doesn't find any errors
**Solution**: Check console for "SymSpell: Dictionary file not found" errors
**Fix**: Verify `frequency_bigramdictionary_en_243_342.txt` exists in `assets/dictionary/`

### Lucy Not Commenting on Errors
**Problem**: Errors exist but Lucy doesn't say anything
**Solution**: 
1. Ensure 2-3 seconds pass after typing stops
2. Check that `spell_checker.is_loaded` is true
3. Verify Lucy's spell check timer is running

### Too Many/Few Suggestions
**Problem**: Suggestions aren't helpful
**Solution**: Adjust `max_edit_distance` in `symspell_checker.gd`
- Lower value (1): Fewer, more accurate suggestions
- Higher value (3): More suggestions, potentially less accurate

### Performance Issues
**Problem**: Spell checking is slow
**Solution**:
1. Reduce `max_edit_distance` to 1
2. Increase `prefix_length` to 10
3. Limit checking to shorter documents

## Future Enhancements

Possible improvements:
- [ ] Multi-language support
- [ ] Custom dictionary additions
- [ ] Grammar checking
- [ ] Context-aware suggestions
- [ ] Ignore list for technical terms
- [ ] User dictionary persistence
- [ ] Real-time suggestions as you type
- [ ] Keyboard shortcut to trigger checking

## Credits

- **SymSpell Algorithm**: Wolf Garbe (https://github.com/wolfgarbe/SymSpell)
- **Dictionary**: Derived from Google Books Ngram and SCOWL
- **Implementation**: Custom GDScript port for Godot 4.4
- **Integration**: Juicy Editor Team

## License

The SymSpell algorithm is MIT licensed. The frequency dictionary is Creative Commons licensed. Our GDScript implementation follows the project's license.
