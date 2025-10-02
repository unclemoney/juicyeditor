extends Control
# Main scene entry point

# Load the GameController script
const GameController = preload("res://scripts/controllers/game_controller.gd")

# Instance variables that GameController would normally handle
var game_controller: GameController

func _ready() -> void:
	# Create and setup game controller
	game_controller = GameController.new()
	add_child(game_controller)
	
	print("Juicy Editor main scene initialized")
