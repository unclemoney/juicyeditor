# Sample GDScript file for testing syntax highlighting
extends Node
class_name TestScript

# This is a comment
signal my_signal(data: String)

@export var my_variable: int = 42
@export var my_string: String = "Hello World"

func _ready() -> void:
	print("Ready function called")
	my_signal.emit("test data")

func calculate_something(input: float) -> float:
	# Another comment
	var result = input * 2.5
	if result > 100.0:
		return 100.0
	else:
		return result

class InnerClass:
	var inner_var: bool = true
	
	func inner_function() -> void:
		print("Inner function")