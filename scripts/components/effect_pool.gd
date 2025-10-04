extends Node
class_name EffectPool

# Juicy Editor - Effect Pool Manager
# Implements object pooling for typing effects to optimize performance
# Reuses effect objects instead of constantly creating/destroying them

signal pool_stats_updated(pool_name: String, active: int, available: int)

@export var max_pool_size: int = 100
@export var initial_pool_size: int = 20
@export var auto_expand_pool: bool = true

# Pools for different effect types
var typing_effect_pool: Array[Node] = []
var flying_letter_pool: Array[Node] = []
var deletion_effect_pool: Array[Node] = []

# Active effects tracking
var active_typing_effects: Array[Node] = []
var active_flying_letters: Array[Node] = []
var active_deletion_effects: Array[Node] = []

# Pool statistics
var pool_stats: Dictionary = {
	"typing_effects": {"active": 0, "available": 0, "total_created": 0},
	"flying_letters": {"active": 0, "available": 0, "total_created": 0},
	"deletion_effects": {"active": 0, "available": 0, "total_created": 0}
}

func _ready() -> void:
	_initialize_pools()
	print("EffectPool initialized with ", initial_pool_size, " objects per pool")

func _initialize_pools() -> void:
	"""Initialize pools with pre-created objects"""
	# Pre-create typing effects
	for i in range(initial_pool_size):
		var effect = _create_typing_effect()
		_deactivate_effect(effect)
		typing_effect_pool.append(effect)
	
	# Pre-create flying letters
	for i in range(initial_pool_size):
		var letter = _create_flying_letter()
		_deactivate_effect(letter)
		flying_letter_pool.append(letter)
	
	# Pre-create deletion effects
	for i in range(initial_pool_size):
		var effect = _create_deletion_effect()
		_deactivate_effect(effect)
		deletion_effect_pool.append(effect)
	
	_update_pool_stats()

func _create_typing_effect() -> Node:
	"""Create a new typing effect object"""
	var effect_script = preload("res://scripts/components/typing_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	effect.name = "PooledTypingEffect"
	add_child(effect)
	pool_stats["typing_effects"]["total_created"] += 1
	return effect

func _create_flying_letter() -> Node:
	"""Create a new flying letter object"""
	var letter_script = preload("res://scripts/components/flying_letter.gd")
	var letter = Node2D.new()
	letter.set_script(letter_script)
	letter.name = "PooledFlyingLetter"
	add_child(letter)
	pool_stats["flying_letters"]["total_created"] += 1
	return letter

func _create_deletion_effect() -> Node:
	"""Create a new deletion effect object"""
	var effect_script = preload("res://scripts/components/deletion_effect.gd")
	var effect = Node2D.new()
	effect.set_script(effect_script)
	effect.name = "PooledDeletionEffect"
	add_child(effect)
	pool_stats["deletion_effects"]["total_created"] += 1
	return effect

func _deactivate_effect(effect: Node) -> void:
	"""Deactivate an effect and prepare it for pooling"""
	effect.visible = false
	effect.process_mode = Node.PROCESS_MODE_DISABLED
	effect.position = Vector2.ZERO
	
	# Reset any effect-specific properties
	if effect.has_method("reset_for_pool"):
		effect.reset_for_pool()

func _activate_effect(effect: Node, target_parent: Node, pos: Vector2) -> void:
	"""Activate an effect from the pool"""
	effect.visible = true
	effect.process_mode = Node.PROCESS_MODE_INHERIT
	effect.position = pos
	
	# Reparent to target (text editor)
	if effect.get_parent() != target_parent:
		effect.reparent(target_parent)

# Public API for getting effects from pools

func get_typing_effect(parent: Node, pos: Vector2, character: String) -> Node:
	"""Get a typing effect from the pool"""
	var effect = null
	
	if typing_effect_pool.size() > 0:
		effect = typing_effect_pool.pop_back()
	elif auto_expand_pool and active_typing_effects.size() < max_pool_size:
		effect = _create_typing_effect()
		print("Pool expanded: created new typing effect")
	else:
		print("Warning: typing effect pool exhausted")
		return null
	
	# Configure and activate the effect
	_activate_effect(effect, parent, pos)
	effect.character_typed = character
	effect.destroy_on_complete = false  # Pool will handle cleanup
	
	# Track as active
	active_typing_effects.append(effect)
	
	# Connect cleanup signal
	if not effect.is_connected("finished", _on_typing_effect_finished):
		# If the effect doesn't have a finished signal, create a timer
		_setup_effect_cleanup_timer(effect, 1.5, _on_typing_effect_finished)
	
	_update_pool_stats()
	return effect

func get_flying_letter(parent: Node, pos: Vector2, character: String) -> Node:
	"""Get a flying letter from the pool"""
	var letter = null
	
	if flying_letter_pool.size() > 0:
		letter = flying_letter_pool.pop_back()
	elif auto_expand_pool and active_flying_letters.size() < max_pool_size:
		letter = _create_flying_letter()
		print("Pool expanded: created new flying letter")
	else:
		print("Warning: flying letter pool exhausted")
		return null
	
	# Configure and activate the letter
	_activate_effect(letter, parent, pos)
	letter.character_text = character
	letter.destroy_on_complete = false  # Pool will handle cleanup
	
	# Track as active
	active_flying_letters.append(letter)
	
	# Setup cleanup timer
	_setup_effect_cleanup_timer(letter, 3.0, _on_flying_letter_finished)
	
	_update_pool_stats()
	return letter

func get_deletion_effect(parent: Node, pos: Vector2) -> Node:
	"""Get a deletion effect from the pool"""
	var effect = null
	
	if deletion_effect_pool.size() > 0:
		effect = deletion_effect_pool.pop_back()
	elif auto_expand_pool and active_deletion_effects.size() < max_pool_size:
		effect = _create_deletion_effect()
		print("Pool expanded: created new deletion effect")
	else:
		print("Warning: deletion effect pool exhausted")
		return null
	
	# Configure and activate the effect
	_activate_effect(effect, parent, pos)
	effect.destroy_on_complete = false  # Pool will handle cleanup
	
	# Track as active
	active_deletion_effects.append(effect)
	
	# Setup cleanup timer
	_setup_effect_cleanup_timer(effect, 1.0, _on_deletion_effect_finished)
	
	_update_pool_stats()
	return effect

func _setup_effect_cleanup_timer(effect: Node, duration: float, callback: Callable) -> void:
	"""Setup a timer to return effect to pool after duration"""
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): callback.call(effect))
	effect.add_child(timer)
	timer.start()

# Cleanup handlers - return effects to their pools

func _on_typing_effect_finished(effect: Node) -> void:
	"""Return typing effect to pool"""
	if effect in active_typing_effects:
		active_typing_effects.erase(effect)
		
		# Reparent back to pool
		if effect.get_parent() != self:
			effect.reparent(self)
		
		_deactivate_effect(effect)
		typing_effect_pool.append(effect)
		_update_pool_stats()

func _on_flying_letter_finished(effect: Node) -> void:
	"""Return flying letter to pool"""
	if effect in active_flying_letters:
		active_flying_letters.erase(effect)
		
		# Reparent back to pool
		if effect.get_parent() != self:
			effect.reparent(self)
		
		_deactivate_effect(effect)
		flying_letter_pool.append(effect)
		_update_pool_stats()

func _on_deletion_effect_finished(effect: Node) -> void:
	"""Return deletion effect to pool"""
	if effect in active_deletion_effects:
		active_deletion_effects.erase(effect)
		
		# Reparent back to pool
		if effect.get_parent() != self:
			effect.reparent(self)
		
		_deactivate_effect(effect)
		deletion_effect_pool.append(effect)
		_update_pool_stats()

func _update_pool_stats() -> void:
	"""Update pool statistics"""
	pool_stats["typing_effects"]["active"] = active_typing_effects.size()
	pool_stats["typing_effects"]["available"] = typing_effect_pool.size()
	
	pool_stats["flying_letters"]["active"] = active_flying_letters.size()
	pool_stats["flying_letters"]["available"] = flying_letter_pool.size()
	
	pool_stats["deletion_effects"]["active"] = active_deletion_effects.size()
	pool_stats["deletion_effects"]["available"] = deletion_effect_pool.size()
	
	# Emit signals for monitoring
	pool_stats_updated.emit("typing_effects", pool_stats["typing_effects"]["active"], pool_stats["typing_effects"]["available"])
	pool_stats_updated.emit("flying_letters", pool_stats["flying_letters"]["active"], pool_stats["flying_letters"]["available"])
	pool_stats_updated.emit("deletion_effects", pool_stats["deletion_effects"]["active"], pool_stats["deletion_effects"]["available"])

func get_pool_stats() -> Dictionary:
	"""Get current pool statistics"""
	return pool_stats.duplicate()

func clear_all_active_effects() -> void:
	"""Force return all active effects to pools"""
	for effect in active_typing_effects.duplicate():
		_on_typing_effect_finished(effect)
	
	for effect in active_flying_letters.duplicate():
		_on_flying_letter_finished(effect)
	
	for effect in active_deletion_effects.duplicate():
		_on_deletion_effect_finished(effect)

# Debug methods
func print_pool_stats() -> void:
	"""Print current pool statistics"""
	print("=== Effect Pool Statistics ===")
	for pool_name in pool_stats:
		var stats = pool_stats[pool_name]
		print("%s: Active=%d, Available=%d, Total Created=%d" % [
			pool_name, stats["active"], stats["available"], stats["total_created"]
		])