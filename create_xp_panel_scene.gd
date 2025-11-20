@tool
extends EditorScript

## Helper script to create XP Display Panel scene programmatically
## Run this script from the Godot Editor: File → Run

func _run() -> void:
	print("Creating XP Display Panel scene...")
	
	# Create root PanelContainer
	var root: PanelContainer = PanelContainer.new()
	root.name = "XPDisplayPanel"
	root.custom_minimum_size = Vector2(250, 250)
	
	# Create MarginContainer
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	root.add_child(margin)
	margin.owner = root
	
	# Create main VBoxContainer
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	vbox.owner = root
	
	# Create Level Container
	var level_container: HBoxContainer = HBoxContainer.new()
	level_container.name = "LevelContainer"
	level_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(level_container)
	level_container.owner = root
	
	# Create Level Label
	var level_label: Label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Level 1"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color.from_string("#FFD700", Color.GOLD))
	level_container.add_child(level_label)
	level_label.owner = root
	
	# Create XP Container
	var xp_container: VBoxContainer = VBoxContainer.new()
	xp_container.name = "XPContainer"
	vbox.add_child(xp_container)
	xp_container.owner = root
	
	# Create XP ProgressBar
	var xp_progress: ProgressBar = ProgressBar.new()
	xp_progress.name = "XPProgressBar"
	xp_progress.min_value = 0
	xp_progress.max_value = 100
	xp_progress.value = 0
	xp_progress.show_percentage = false
	xp_progress.custom_minimum_size = Vector2(200, 20)
	xp_container.add_child(xp_progress)
	xp_progress.owner = root
	
	# Create XP Label
	var xp_label: Label = Label.new()
	xp_label.name = "XPLabel"
	xp_label.text = "0 / 100 XP"
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_container.add_child(xp_label)
	xp_label.owner = root
	
	# Create ScrollContainer
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	scroll.owner = root
	
	# Create Achievement Grid
	var grid: GridContainer = GridContainer.new()
	grid.name = "AchievementGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	grid.owner = root
	
	# Attach the script
	var script: GDScript = load("res://scripts/ui/xp_display_panel.gd")
	root.set_script(script)
	
	# Save as packed scene
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(root)
	
	var save_path: String = "res://scenes/ui/xp_display_panel.tscn"
	var error: Error = ResourceSaver.save(packed_scene, save_path)
	
	if error == OK:
		print("✅ XP Display Panel scene created successfully at: ", save_path)
		print("Next step: Add this scene to your main scene (res://scenes/main.tscn)")
	else:
		print("❌ Error saving scene: ", error)

	# Clean up
	root.queue_free()
