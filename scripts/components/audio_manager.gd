extends Node
#class_name AudioManager

# Juicy Editor - Audio Manager
# Handles all audio feedback for typing, UI interactions, and file operations

signal audio_settings_changed

@export var typing_sounds: Array[AudioStream] = []
@export var ui_sounds: Dictionary = {}
@export var master_volume: float = 0.7
@export var typing_volume: float = 0.5
@export var ui_volume: float = 0.6

var audio_players: Array[AudioStreamPlayer] = []
var typing_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var delete_player: AudioStreamPlayer

var audio_enabled: bool = true
var typing_sounds_enabled: bool = true

# Delete sound effect system with pitch-down
var delete_sound: AudioStream
var delete_pitch_offset: float = 0.0  # Cents offset from original pitch
var delete_pitch_step: float = 1.0  # Lower by 1 cent each time
var pitch_reset_timer: Timer

func _ready() -> void:
	_setup_audio_players()
	_setup_pitch_reset_timer()
	_load_default_sounds()
	_load_delete_sound()

func _setup_audio_players() -> void:
	# Create audio players for different types of sounds
	typing_player = AudioStreamPlayer.new()
	typing_player.name = "TypingPlayer"
	add_child(typing_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	add_child(ui_player)
	
	delete_player = AudioStreamPlayer.new()
	delete_player.name = "DeletePlayer"
	delete_player.bus = "Master"
	add_child(delete_player)
	
	# Create a pool of audio players for overlapping sounds
	for i in range(5):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer" + str(i)
		add_child(player)
		audio_players.append(player)

func _load_default_sounds() -> void:
	# Create procedural audio streams as placeholders
	_create_procedural_typing_sounds()
	_create_procedural_ui_sounds()

func _setup_pitch_reset_timer() -> void:
	## Setup timer to reset pitch offset after 0.5 seconds
	pitch_reset_timer = Timer.new()
	pitch_reset_timer.name = "PitchResetTimer"
	pitch_reset_timer.wait_time = 0.5
	pitch_reset_timer.one_shot = true
	pitch_reset_timer.timeout.connect(_on_pitch_reset_timeout)
	add_child(pitch_reset_timer)

func _load_delete_sound() -> void:
	## Load the delete sound effect from the audio folder
	var delete_sound_path = "res://audio/sfx/delete.wav"
	if ResourceLoader.exists(delete_sound_path):
		delete_sound = load(delete_sound_path) as AudioStream
		if delete_sound:
			print("AudioManager: Delete sound loaded successfully")
		else:
			print("AudioManager: Failed to load delete sound")
	else:
		print("AudioManager: Delete sound file not found at ", delete_sound_path)

func _create_procedural_typing_sounds() -> void:
	# Create simple procedural typing sounds using AudioStreamGenerator
	for i in range(3):
		var typing_stream = _create_typing_sound_stream(0.3 + i * 0.1, 0.05)
		typing_sounds.append(typing_stream)

func _create_procedural_ui_sounds() -> void:
	# Create procedural UI sounds
	ui_sounds = {
		"button_click": _create_button_click_stream(),
		"button_hover": _create_button_hover_stream(),
		"file_open": _create_success_sound_stream(),
		"file_save": _create_save_sound_stream(),
		"menu_open": _create_menu_sound_stream(),
		"error": _create_error_sound_stream()
	}

func _create_typing_sound_stream(_pitch: float = 0.5, duration: float = 0.05) -> AudioStream:
	# Create a simple clicking sound using AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = duration
	return generator

func _create_button_click_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.1
	return generator

func _create_button_hover_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.05
	return generator

func _create_success_sound_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.15
	return generator

func _create_save_sound_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.2
	return generator

func _create_menu_sound_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.08
	return generator

func _create_error_sound_stream() -> AudioStream:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.3
	return generator

func play_typing_sound() -> void:
	if not audio_enabled or not typing_sounds_enabled:
		return
	
	if typing_sounds.is_empty():
		return
	
	var sound = typing_sounds[randi() % typing_sounds.size()]
	if sound and typing_player:
		typing_player.stream = sound
		typing_player.volume_db = linear_to_db(master_volume * typing_volume)
		typing_player.play()

func play_delete_sound() -> void:
	## Play delete/backspace/cut sound with pitch-down effect
	if not audio_enabled or not delete_sound or not delete_player:
		return
	
	# Set up the audio stream
	delete_player.stream = delete_sound
	delete_player.volume_db = linear_to_db(master_volume * ui_volume)
	
	# Apply pitch shift (convert cents to pitch scale)
	# 100 cents = 1 semitone, pitch_scale of 2.0 = 1 octave up
	# Formula: pitch_scale = 2^(cents/1200)
	var pitch_scale = pow(2.0, delete_pitch_offset / 1200.0)
	delete_player.pitch_scale = pitch_scale
	
	# Play the sound
	delete_player.play()
	
	# Decrease pitch by 1 cent for next time
	delete_pitch_offset -= delete_pitch_step
	
	# Restart the reset timer
	if pitch_reset_timer:
		pitch_reset_timer.stop()
		pitch_reset_timer.start()

func _on_pitch_reset_timeout() -> void:
	## Reset pitch offset back to 0 after 0.5 seconds of no deletions
	delete_pitch_offset = 0.0

func play_ui_sound(sound_name: String) -> void:
	if not audio_enabled:
		return
	
	if sound_name in ui_sounds and ui_sounds[sound_name]:
		var sound = ui_sounds[sound_name]
		if ui_player:
			ui_player.stream = sound
			ui_player.volume_db = linear_to_db(master_volume * ui_volume)
			ui_player.play()

func play_sound_oneshot(sound: AudioStream, volume: float = 1.0) -> void:
	if not audio_enabled or not sound:
		return
	
	# Find an available audio player
	var player = _get_available_player()
	if player:
		player.stream = sound
		player.volume_db = linear_to_db(master_volume * volume)
		player.play()

func _get_available_player() -> AudioStreamPlayer:
	for player in audio_players:
		if not player.playing:
			return player
	
	# If all players are busy, use the first one
	return audio_players[0] if not audio_players.is_empty() else null

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	audio_settings_changed.emit()

func set_typing_volume(volume: float) -> void:
	typing_volume = clamp(volume, 0.0, 1.0)
	audio_settings_changed.emit()

func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	audio_settings_changed.emit()

func set_audio_enabled(enabled: bool) -> void:
	audio_enabled = enabled
	if not enabled:
		_stop_all_sounds()
	audio_settings_changed.emit()

func set_typing_sounds_enabled(enabled: bool) -> void:
	typing_sounds_enabled = enabled
	audio_settings_changed.emit()

func set_ui_sounds_enabled(enabled: bool) -> void:
	audio_enabled = enabled
	audio_settings_changed.emit()

func set_sound_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	audio_settings_changed.emit()

func _stop_all_sounds() -> void:
	if typing_player:
		typing_player.stop()
	if ui_player:
		ui_player.stop()
	for player in audio_players:
		player.stop()

func add_typing_sound(sound: AudioStream) -> void:
	if sound and sound not in typing_sounds:
		typing_sounds.append(sound)

func set_ui_sound(sound_name: String, sound: AudioStream) -> void:
	ui_sounds[sound_name] = sound

func load_audio_files() -> void:
	# Attempt to load actual audio files if they exist
	_try_load_typing_sounds()
	_try_load_ui_sounds()

func _try_load_typing_sounds() -> void:
	var typing_files = [
		"res://audio/sfx/typing_01.mp3",
		"res://audio/sfx/typing_02.mp3",
		"res://audio/sfx/typing_03.mp3"
	]
	
	typing_sounds.clear()
	for file_path in typing_files:
		if ResourceLoader.exists(file_path):
			var sound = load(file_path) as AudioStream
			if sound:
				typing_sounds.append(sound)
	
	# If no audio files found, keep procedural sounds
	if typing_sounds.is_empty():
		_create_procedural_typing_sounds()

func _try_load_ui_sounds() -> void:
	var ui_sound_files = {
		"button_click": "res://audio/sfx/button_click.mp3",
		"button_hover": "res://audio/sfx/button_hover.ogg",
		"file_open": "res://audio/sfx/file_open.ogg",
		"file_save": "res://audio/sfx/file_save.ogg",
		"menu_open": "res://audio/sfx/menu_open.ogg",
		"error": "res://audio/sfx/error.ogg"
	}
	
	for sound_name in ui_sound_files:
		var file_path = ui_sound_files[sound_name]
		if ResourceLoader.exists(file_path):
			var sound = load(file_path) as AudioStream
			if sound:
				ui_sounds[sound_name] = sound
		# Keep procedural sound if file doesn't exist

func get_audio_info() -> Dictionary:
	return {
		"typing_sounds_count": typing_sounds.size(),
		"ui_sounds_loaded": ui_sounds.size(),
		"audio_enabled": audio_enabled,
		"master_volume": master_volume,
		"typing_volume": typing_volume,
		"ui_volume": ui_volume
	}
