# Juicy Editor — Required SFX Assets

This document lists the `.wav` sound effects needed for the typing effects juice refactor.
Place all files in this folder (`res://audio/sfx/`). The AudioManager will auto-load them at runtime.

## Typing Sounds

| Filename | Description | Trigger |
|----------|-------------|---------|
| `typing_normal_01.wav` | Light mechanical key pop (neutral) | Normal keystrokes |
| `typing_normal_02.wav` | Slightly brighter pop variant | Normal keystrokes |
| `typing_normal_03.wav` | Soft thock variant | Normal keystrokes |
| `typing_normal_04.wav` | Crisp tick variant | Normal keystrokes |
| `typing_combo_01.wav` | Sharp, satisfying snap | Combo-tier typing (fast streak) |
| `typing_combo_02.wav` | Bright metallic ping | Combo-tier typing |
| `typing_combo_03.wav` | Punchy clack | Combo-tier typing |
| `typing_special_01.wav` | Big celebratory punch / cartoon impact | Special-tier typing (huge streak) |
| `typing_rhythm_01.wav` | Percussive wood block tick | Rhythmic typing detected |
| `typing_rhythm_02.wav` | Light shaker / hi-hat tick | Rhythmic typing detected |

## Deletion Sounds

| Filename | Description | Trigger |
|----------|-------------|---------|
| `delete_01.wav` | Sharp break / crunch / glass crack | Single deletion |
| `delete_heavy_01.wav` | Bigger explosion-like break / bassy thud | Heavy consecutive deletion (scale > 3) |

> **Fallback:** `delete.wav` is already present and will be used if the above are missing.

## Misc Sounds

| Filename | Description | Trigger |
|----------|-------------|---------|
| `newline_01.wav` | Soft thud / mechanical return | Enter / newline |
| `whoosh_01.wav` | Air whoosh / fast swipe | Flying letter launch |
| `impact_01.wav` | Dull thud / landing puff | Flying letter landing (optional) |

## Design Notes

- **Keep them short.** Most typing sounds should be < 0.1 s. Combo/special can be up to 0.2 s.
- **Transient-heavy.** Sharp attacks work better than long sustains for rapid-fire keystrokes.
- **Consistent timbre.** All "typing" sounds should feel like they come from the same "instrument family" (e.g., all mechanical keyboard-ish, or all cartoon pops).
- **Pitch variation.** The engine will apply ±5% pitch randomization per keystroke, so you don’t need 20 variants — 4 normal + 3 combo + 1 special is plenty.
- **Looping = no.** These are all one-shot SFX.
