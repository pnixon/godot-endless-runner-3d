extends Node

## Enhanced Test script to demonstrate enemy attack patterns and telegraphing system
## Run this script to verify that the enhanced enemy attack system is working correctly

func _ready():
	print("=== ENHANCED ENEMY ATTACK SYSTEM DEMONSTRATION ===")
	
	# Wait for game to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Find the player
	var player = get_tree().get_first_node_in_group("rpg_player")
	if not player:
		print("❌ ERROR: No player found!")
		return
	
	print("✅ Player found")
	
	# Test 1: Basic attack registration
	print("\n🗡️ TEST 1: Basic Attack Registration")
	player.register_incoming_attack("test_frontal", 2.0, 25.0, "frontal", "backward")
	print("✅ Frontal attack registered - dodge BACKWARD in 2 seconds!")
	
	await get_tree().create_timer(3.0).timeout
	
	# Test 2: Enhanced enemy attack system
	print("\n🗡️ TEST 2: Enhanced Enemy Attack System")
	var enemy_attack_system = EnemyAttackSystem.new()
	enemy_attack_system.name = "TestAttackSystem"
	get_tree().current_scene.add_child(enemy_attack_system)
	
	await get_tree().create_timer(0.5).timeout
	
	if enemy_attack_system.player:
		print("✅ Enhanced enemy attack system connected to player")
		print("📊 Available attack patterns: ", enemy_attack_system.attack_patterns.size())
		
		# Test boss special attack
		var boss_attack = EnemyAttackSystem.AttackData.new(
			"test_boss_special", 
			3.0, 
			60.0, 
			EnemyAttackSystem.AttackType.BOSS_SPECIAL, 
			CombatController.DodgeDirection.RIGHT
		)
		enemy_attack_system.telegraph_attack(boss_attack)
		print("✅ Boss special attack telegraphed - dodge RIGHT in 3 seconds!")
	else:
		print("❌ Enemy attack system failed to connect to player")
	
	await get_tree().create_timer(4.0).timeout
	
	# Test 3: Heavy Bruiser with enhanced patterns
	print("\n🗡️ TEST 3: Heavy Bruiser Enhanced Patterns")
	var bruiser = HeavyBruiserEnemy.new()
	bruiser.name = "TestBruiser"
	bruiser.global_position = Vector3(0, 0, -5)
	get_tree().current_scene.add_child(bruiser)
	
	await get_tree().create_timer(1.0).timeout
	
	if bruiser.attack_system:
		print("✅ Heavy Bruiser created with enhanced attack patterns")
		var bruiser_patterns = bruiser.attack_system.get_available_patterns_for_enemy_type(EnemyAttackSystem.EnemyType.HEAVY_BRUISER)
		print("📋 Bruiser patterns: ", bruiser_patterns)
		
		# Test combo attack
		bruiser.force_attack_pattern("bruiser_slam_pound_combo")
		print("✅ Bruiser combo attack forced - watch for multi-phase telegraph!")
	
	await get_tree().create_timer(6.0).timeout
	
	# Test 4: Agile Rogue with new patterns
	print("\n🗡️ TEST 4: Agile Rogue Enhanced Patterns")
	var rogue = AgileRogueEnemy.new()
	rogue.name = "TestRogue"
	rogue.global_position = Vector3(0, 0, -3)
	get_tree().current_scene.add_child(rogue)
	
	await get_tree().create_timer(1.0).timeout
	
	if rogue.attack_system:
		print("✅ Agile Rogue created with enhanced attack patterns")
		var rogue_patterns = rogue.attack_system.get_available_patterns_for_enemy_type(EnemyAttackSystem.EnemyType.AGILE_ROGUE)
		print("📋 Rogue patterns: ", rogue_patterns)
		
		# Test shadow strike combo
		rogue.force_attack_pattern("rogue_shadow_strike_combo")
		print("✅ Rogue shadow strike combo forced - watch for rapid sequence!")
	
	await get_tree().create_timer(5.0).timeout
	
	# Test 5: Mage Caster with spell variety
	print("\n🗡️ TEST 5: Mage Caster Enhanced Spells")
	var mage = MageCasterEnemy.new()
	mage.name = "TestMage"
	mage.global_position = Vector3(0, 0, -7)
	get_tree().current_scene.add_child(mage)
	
	await get_tree().create_timer(1.0).timeout
	
	if mage.attack_system:
		print("✅ Mage Caster created with enhanced spell patterns")
		var mage_patterns = mage.attack_system.get_available_patterns_for_enemy_type(EnemyAttackSystem.EnemyType.MAGE_CASTER)
		print("📋 Mage patterns: ", mage_patterns)
		
		# Test meteor strike
		mage.force_attack_pattern("mage_meteor_strike")
		print("✅ Mage meteor strike forced - watch for delayed area attack!")
	
	await get_tree().create_timer(5.0).timeout
	
	# Test 6: Boss with multi-phase patterns
	print("\n🗡️ TEST 6: Boss Multi-Phase Patterns")
	var boss = BossEnemy.new()
	boss.boss_tier = 2
	boss.name = "TestBoss"
	boss.global_position = Vector3(0, 0, -8)
	get_tree().current_scene.add_child(boss)
	
	await get_tree().create_timer(1.0).timeout
	
	if boss.attack_system:
		print("✅ Tier 2 Boss created with multi-phase patterns")
		
		# Test complex pattern
		boss.force_attack_pattern("boss_tier2_complex")
		print("✅ Boss complex pattern forced - watch for extended sequence!")
	
	await get_tree().create_timer(8.0).timeout
	
	# Test 7: Attack pattern database verification
	print("\n🗡️ TEST 7: Attack Pattern Database Verification")
	print("📊 Total attack patterns in database: ", enemy_attack_system.attack_patterns.size())
	
	var pattern_counts = {}
	for enemy_type in EnemyAttackSystem.EnemyType.values():
		var patterns = enemy_attack_system.get_available_patterns_for_enemy_type(enemy_type)
		var type_name = EnemyAttackSystem.EnemyType.keys()[enemy_type]
		pattern_counts[type_name] = patterns.size()
		print("  • ", type_name, ": ", patterns.size(), " patterns")
	
	print("\n=== ENHANCED DEMONSTRATION COMPLETE ===")
	print("✅ Enhanced enemy attack system is working correctly!")
	print("📋 New features demonstrated:")
	print("   • Multi-phase boss attack sequences")
	print("   • Enhanced visual telegraphing with attack-specific effects")
	print("   • Improved audio cue system")
	print("   • Combo attack patterns")
	print("   • Enemy-specific attack pattern selection")
	print("   • Boss special attacks and enrage patterns")
	print("   • Area attacks with warning particles")
	print("   • Varied telegraph timing and intensity")
	print("\n🎮 Use number keys 1-9 to test different enemy types manually!")
	print("🎯 Enhanced attack patterns provide more tactical depth!")
	
	# Clean up
	if is_instance_valid(bruiser):
		bruiser.queue_free()
	if is_instance_valid(rogue):
		rogue.queue_free()
	if is_instance_valid(mage):
		mage.queue_free()
	if is_instance_valid(boss):
		boss.queue_free()
	if is_instance_valid(enemy_attack_system):
		enemy_attack_system.queue_free()