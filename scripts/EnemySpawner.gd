extends Node3D
class_name EnemySpawner

## Enemy Spawner - Manages spawning of different enemy types with attack patterns
## Integrates with existing game systems and provides enemy encounters

signal enemy_spawned(enemy: EnemyAI)
signal enemy_defeated(enemy: EnemyAI)
signal encounter_started(encounter_type: String)
signal encounter_completed(success: bool)

# Enemy scene references
var enemy_scenes: Dictionary = {}
var active_enemies: Array[EnemyAI] = []

# Spawning settings
@export var max_active_enemies: int = 3
@export var spawn_distance: float = 15.0
@export var despawn_distance: float = 25.0

# Encounter management
var current_encounter: String = ""
var encounter_enemies: Array[EnemyAI] = []
var encounter_active: bool = false

# References
var player: RPGPlayer3D
var game_manager: Node

func _ready():
	# Find references
	player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Load enemy scenes
	load_enemy_scenes()
	
	print("EnemySpawner initialized with ", enemy_scenes.size(), " enemy types")

func load_enemy_scenes():
	"""Load all enemy scene files"""
	# For now, we'll create the scenes programmatically
	# In a full implementation, these would be loaded from .tscn files
	
	enemy_scenes["basic_melee"] = preload("res://scripts/enemies/BasicMeleeEnemy.gd")
	enemy_scenes["ranged_archer"] = preload("res://scripts/enemies/RangedArcherEnemy.gd")
	enemy_scenes["heavy_bruiser"] = preload("res://scripts/enemies/HeavyBruiserEnemy.gd")
	enemy_scenes["agile_rogue"] = preload("res://scripts/enemies/AgileRogueEnemy.gd")
	enemy_scenes["mage_caster"] = preload("res://scripts/enemies/MageCasterEnemy.gd")
	enemy_scenes["boss_tier1"] = preload("res://scripts/enemies/BossEnemy.gd")
	enemy_scenes["boss_tier2"] = preload("res://scripts/enemies/BossEnemy.gd")
	enemy_scenes["boss_final"] = preload("res://scripts/enemies/BossEnemy.gd")

func _process(delta):
	# Clean up defeated enemies
	cleanup_defeated_enemies()
	
	# Check encounter completion
	if encounter_active:
		check_encounter_completion()
	
	# Despawn enemies that are too far away
	despawn_distant_enemies()

func spawn_enemy(enemy_type: String, position: Vector3 = Vector3.ZERO) -> EnemyAI:
	"""Spawn a single enemy of the specified type"""
	if not enemy_scenes.has(enemy_type):
		print("EnemySpawner: Unknown enemy type: ", enemy_type)
		return null
	
	if active_enemies.size() >= max_active_enemies:
		print("EnemySpawner: Max active enemies reached")
		return null
	
	# Create enemy instance
	var enemy: EnemyAI = null
	
	match enemy_type:
		"basic_melee":
			enemy = BasicMeleeEnemy.new()
		"ranged_archer":
			enemy = RangedArcherEnemy.new()
		"heavy_bruiser":
			enemy = HeavyBruiserEnemy.new()
		"agile_rogue":
			enemy = AgileRogueEnemy.new()
		"mage_caster":
			enemy = MageCasterEnemy.new()
		"boss_tier1":
			enemy = BossEnemy.new()
			(enemy as BossEnemy).boss_tier = 1
		"boss_tier2":
			enemy = BossEnemy.new()
			(enemy as BossEnemy).boss_tier = 2
		"boss_final":
			enemy = BossEnemy.new()
			(enemy as BossEnemy).boss_tier = 3
		_:
			print("EnemySpawner: Failed to create enemy type: ", enemy_type)
			return null
	
	if not enemy:
		return null
	
	# Set position
	if position == Vector3.ZERO:
		position = get_spawn_position()
	enemy.global_position = position
	
	# Connect signals
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	# Emit signal
	enemy_spawned.emit(enemy)
	
	print("EnemySpawner: Spawned ", enemy_type, " at ", position)
	return enemy

func get_spawn_position() -> Vector3:
	"""Get a valid spawn position around the player"""
	if not player:
		return Vector3(0, 0, -spawn_distance)
	
	# Spawn in a circle around the player
	var angle = randf() * TAU
	var distance = spawn_distance + randf() * 5.0  # Some variation
	
	var spawn_pos = player.global_position + Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)
	
	return spawn_pos

func start_encounter(formation_id: String, spawn_position: Vector3 = Vector3.ZERO) -> bool:
	"""Start a specific enemy encounter"""
	if encounter_active:
		print("EnemySpawner: Encounter already active")
		return false
	
	var formation = get_encounter_formation(formation_id)
	if formation.is_empty():
		print("EnemySpawner: Unknown formation: ", formation_id)
		return false
	
	current_encounter = formation_id
	encounter_active = true
	encounter_enemies.clear()
	
	# Spawn all enemies in the formation
	for i in range(formation.size()):
		var enemy_type = formation[i]
		var enemy_position = spawn_position + get_formation_offset(i, formation.size())
		var enemy = spawn_enemy(enemy_type, enemy_position)
		
		if enemy:
			encounter_enemies.append(enemy)
	
	encounter_started.emit(formation_id)
	print("EnemySpawner: Started encounter '", formation_id, "' with ", encounter_enemies.size(), " enemies")
	
	return true

func get_encounter_formation(formation_id: String) -> Array[String]:
	"""Get the enemy types for a specific formation"""
	match formation_id:
		# Tutorial formations
		"single_goblin":
			return ["basic_melee"]
		"weak_slime":
			return ["basic_melee"]
		
		# City formations
		"city_guard":
			return ["basic_melee", "ranged_archer"]
		"street_thug":
			return ["agile_rogue"]
		"dual_bandits":
			return ["basic_melee", "agile_rogue"]
		
		# Industrial formations
		"factory_bot":
			return ["heavy_bruiser"]
		"steam_golem":
			return ["heavy_bruiser", "mage_caster"]
		"gear_squad":
			return ["basic_melee", "ranged_archer", "heavy_bruiser"]
		
		# Boss encounters
		"boss_encounter_1":
			return ["boss_tier1"]
		"boss_encounter_2":
			return ["boss_tier2"]
		"final_boss":
			return ["boss_final"]
		
		# Mixed encounters
		"balanced_squad":
			return ["basic_melee", "ranged_archer", "mage_caster"]
		"heavy_assault":
			return ["heavy_bruiser", "heavy_bruiser"]
		"agile_strike":
			return ["agile_rogue", "agile_rogue", "ranged_archer"]
		
		_:
			return []

func get_formation_offset(index: int, total_count: int) -> Vector3:
	"""Get position offset for enemy in formation"""
	if total_count == 1:
		return Vector3.ZERO
	
	# Arrange enemies in a line or arc
	var spacing = 3.0
	var start_offset = -(total_count - 1) * spacing * 0.5
	
	return Vector3(start_offset + index * spacing, 0, 0)

func cleanup_defeated_enemies():
	"""Remove defeated enemies from active list"""
	for i in range(active_enemies.size() - 1, -1, -1):
		var enemy = active_enemies[i]
		if not is_instance_valid(enemy) or not enemy.is_alive():
			active_enemies.remove_at(i)

func check_encounter_completion():
	"""Check if current encounter is complete"""
	if not encounter_active:
		return
	
	# Check if all encounter enemies are defeated
	var alive_encounter_enemies = 0
	for enemy in encounter_enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			alive_encounter_enemies += 1
	
	if alive_encounter_enemies == 0:
		complete_encounter(true)

func complete_encounter(success: bool):
	"""Complete the current encounter"""
	if not encounter_active:
		return
	
	encounter_active = false
	var completed_encounter = current_encounter
	current_encounter = ""
	encounter_enemies.clear()
	
	encounter_completed.emit(success)
	print("EnemySpawner: Encounter '", completed_encounter, "' completed - Success: ", success)
	
	# Notify game manager if available
	if game_manager and game_manager.has_method("_on_encounter_completed"):
		game_manager._on_encounter_completed(completed_encounter, success)

func despawn_distant_enemies():
	"""Despawn enemies that are too far from the player"""
	if not player:
		return
	
	for i in range(active_enemies.size() - 1, -1, -1):
		var enemy = active_enemies[i]
		if not is_instance_valid(enemy):
			active_enemies.remove_at(i)
			continue
		
		var distance = enemy.global_position.distance_to(player.global_position)
		if distance > despawn_distance:
			# Don't despawn encounter enemies
			if enemy in encounter_enemies:
				continue
			
			print("EnemySpawner: Despawning distant enemy at distance ", distance)
			enemy.queue_free()
			active_enemies.remove_at(i)

func _on_enemy_died(enemy: EnemyAI):
	"""Handle enemy death"""
	enemy_defeated.emit(enemy)
	
	# Award experience and loot
	award_enemy_rewards(enemy)
	
	print("EnemySpawner: Enemy defeated - ", enemy.get_enemy_type())

func award_enemy_rewards(enemy: EnemyAI):
	"""Award rewards for defeating an enemy"""
	if not player:
		return
	
	# Calculate rewards based on enemy type
	var xp_reward = 0
	var coin_reward = 0
	
	match enemy.get_enemy_type():
		EnemyAttackSystem.EnemyType.BASIC_MELEE:
			xp_reward = 15
			coin_reward = 5
		EnemyAttackSystem.EnemyType.RANGED_ARCHER:
			xp_reward = 18
			coin_reward = 7
		EnemyAttackSystem.EnemyType.HEAVY_BRUISER:
			xp_reward = 25
			coin_reward = 10
		EnemyAttackSystem.EnemyType.AGILE_ROGUE:
			xp_reward = 20
			coin_reward = 8
		EnemyAttackSystem.EnemyType.MAGE_CASTER:
			xp_reward = 30
			coin_reward = 12
		EnemyAttackSystem.EnemyType.BOSS_TIER_1:
			xp_reward = 100
			coin_reward = 50
		EnemyAttackSystem.EnemyType.BOSS_TIER_2:
			xp_reward = 200
			coin_reward = 100
		EnemyAttackSystem.EnemyType.BOSS_FINAL:
			xp_reward = 500
			coin_reward = 250
	
	# Award rewards through game manager
	if game_manager:
		if game_manager.has_method("collect_pickup"):
			game_manager.collect_pickup("xp", xp_reward)
			game_manager.collect_pickup("coin", coin_reward)

# Public API methods

func get_active_enemy_count() -> int:
	"""Get number of active enemies"""
	return active_enemies.size()

func get_encounter_status() -> bool:
	"""Check if an encounter is currently active"""
	return encounter_active

func get_current_encounter() -> String:
	"""Get current encounter ID"""
	return current_encounter

func force_complete_encounter():
	"""Force complete current encounter (for testing)"""
	if encounter_active:
		complete_encounter(true)

func clear_all_enemies():
	"""Clear all active enemies"""
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.clear()
	encounter_enemies.clear()
	encounter_active = false
	current_encounter = ""

# Debug methods

func debug_spawner():
	"""Print debug information about the spawner"""
	print("=== ENEMY SPAWNER DEBUG ===")
	print("Active Enemies: ", active_enemies.size(), "/", max_active_enemies)
	print("Encounter Active: ", encounter_active)
	print("Current Encounter: ", current_encounter)
	print("Encounter Enemies: ", encounter_enemies.size())
	print("Available Enemy Types: ", enemy_scenes.keys())
	print("===========================")

func test_spawn_enemy(enemy_type: String):
	"""Test method to spawn a specific enemy type"""
	var enemy = spawn_enemy(enemy_type)
	if enemy:
		print("EnemySpawner: Test spawned ", enemy_type)
	else:
		print("EnemySpawner: Failed to spawn ", enemy_type)

func test_encounter(formation_id: String):
	"""Test method to start a specific encounter"""
	if start_encounter(formation_id):
		print("EnemySpawner: Test started encounter ", formation_id)
	else:
		print("EnemySpawner: Failed to start encounter ", formation_id)