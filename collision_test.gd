extends Node

# Quick test to verify collision detection is working properly
# Add this as an autoload or run as a tool script

func test_lane_collision():
	print("=== COLLISION DETECTION TEST ===")
	
	# Test lane positions
	var LANE_POSITIONS = [-3.0, 0.0, 3.0]
	
	# Test hazard positions and which lane they should be in
	var test_positions = [
		Vector3(-3.1, 1, 0),  # Should be lane 0 (left)
		Vector3(-2.9, 1, 0),  # Should be lane 0 (left)
		Vector3(-0.1, 1, 0),  # Should be lane 1 (center)
		Vector3(0.1, 1, 0),   # Should be lane 1 (center)
		Vector3(2.9, 1, 0),   # Should be lane 2 (right)
		Vector3(3.1, 1, 0),   # Should be lane 2 (right)
	]
	
	for pos in test_positions:
		var detected_lane = get_lane_from_position(pos)
		print("Position ", pos.x, " detected as lane ", detected_lane)
	
	print("=== TEST COMPLETE ===")

func get_lane_from_position(world_pos: Vector3) -> int:
	var LANE_POSITIONS = [-3.0, 0.0, 3.0]
	var min_distance = 999.0
	var closest_lane = -1
	
	for i in range(LANE_POSITIONS.size()):
		var distance = abs(world_pos.x - LANE_POSITIONS[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i
	
	return closest_lane

func _ready():
	# Run test automatically
	call_deferred("test_lane_collision")
