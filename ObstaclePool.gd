extends Node

# Object pool for EnhancedObstacles to reduce memory allocation/deallocation
var obstacle_pool: Array[Node] = []
var max_pool_size = 20  # Reasonable limit to prevent excessive memory usage

@onready var enhanced_obstacle_scene = preload("res://EnhancedObstacle.tscn")

func get_obstacle() -> Node:
	if obstacle_pool.size() > 0:
		var obstacle = obstacle_pool.pop_back()
		# Reset the obstacle state
		if obstacle.has_method("reset_state"):
			obstacle.reset_state()
		return obstacle
	else:
		# Create new obstacle if pool is empty
		return enhanced_obstacle_scene.instantiate()

func return_obstacle(obstacle: Node):
	if obstacle == null or not is_instance_valid(obstacle):
		return
	
	# Clean up the obstacle before returning to pool
	if obstacle.has_method("cleanup"):
		obstacle.cleanup()
	
	# Remove from parent if it has one
	if obstacle.get_parent():
		obstacle.get_parent().remove_child(obstacle)
	
	# Add back to pool if we haven't exceeded max size
	if obstacle_pool.size() < max_pool_size:
		obstacle_pool.push_back(obstacle)
	else:
		# Pool is full, just free the obstacle
		obstacle.queue_free()

func clear_pool():
	# Clean up all pooled obstacles
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle):
			if obstacle.has_method("cleanup"):
				obstacle.cleanup()
			obstacle.queue_free()
	obstacle_pool.clear()

func _exit_tree():
	# Ensure all pooled objects are cleaned up
	clear_pool()
