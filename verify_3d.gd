extends Node

# Simple verification script to check if 3D conversion is working
# Run this as a tool script to verify the setup

func _ready():
	print("=== 3D ENDLESS RUNNER VERIFICATION ===")
	
	# Check if required files exist
	var required_files = [
		"res://Main3D.tscn",
		"res://GameManager3D.gd", 
		"res://Player3D.gd",
		"res://EnhancedObstacle3D.gd",
		"res://EnhancedObstacle3D.tscn",
		"res://HazardData.gd",
		"res://CombatGrid.gd",
		"res://background_music.mp3"
	]
	
	print("Checking required files:")
	for file in required_files:
		if ResourceLoader.exists(file):
			print("✅ ", file)
		else:
			print("❌ ", file, " - MISSING!")
	
	# Check if scenes can be loaded
	print("\nChecking scene loading:")
	var main_scene = load("res://Main3D.tscn")
	if main_scene:
		print("✅ Main3D.tscn loads successfully")
	else:
		print("❌ Main3D.tscn failed to load")
	
	var obstacle_scene = load("res://EnhancedObstacle3D.tscn")
	if obstacle_scene:
		print("✅ EnhancedObstacle3D.tscn loads successfully")
	else:
		print("❌ EnhancedObstacle3D.tscn failed to load")
	
	# Check if scripts compile
	print("\nChecking script compilation:")
	var scripts = [
		"res://GameManager3D.gd",
		"res://Player3D.gd", 
		"res://EnhancedObstacle3D.gd"
	]
	
	for script_path in scripts:
		var script = load(script_path)
		if script:
			print("✅ ", script_path, " compiles successfully")
		else:
			print("❌ ", script_path, " failed to compile")
	
	print("\n=== VERIFICATION COMPLETE ===")
	print("If all items show ✅, the 3D conversion should work!")
	print("Run Main3D.tscn to test the game.")
