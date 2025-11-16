extends Node3D

## Tutorial Arena Level
## Demonstrates modular component integration: enemies, combat, waves, and UI

# Preload enemy types
const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")
const RangedArcherEnemy = preload("res://scripts/enemies/RangedArcherEnemy.gd")
const HeavyBruiserEnemy = preload("res://scripts/enemies/HeavyBruiserEnemy.gd")
const BossEnemy = preload("res://scripts/enemies/BossEnemy.gd")

# Node references (optional - will create if not present)
@onready var player: Node3D = null
@onready var combat_controller = null
@onready var camera: Camera3D = null

# Wave management
var current_wave: int = 0
var enemies_in_wave: Array = []
var is_wave_active: bool = false

# Tutorial state
enum TutorialState {
	INTRO,
	WAVE_1_MELEE,
	WAVE_2_MIXED,
	WAVE_3_HEAVY,
	WAVE_4_BOSS,
	COMPLETE
}

var tutorial_state: TutorialState = TutorialState.INTRO

# Wave definitions - progressively introduces mechanics
var waves: Array = [
	{
		"name": "Basic Combat",
		"description": "Defeat 2 melee enemies to learn basic combat",
		"enemies": [
			{"type": "melee", "position": Vector3(-2, 0, 8), "health": 30},
			{"type": "melee", "position": Vector3(2, 0, 8), "health": 30}
		]
	},
	{
		"name": "Ranged Threat",
		"description": "Melee enemies guard a ranged archer - prioritize targets!",
		"enemies": [
			{"type": "melee", "position": Vector3(-2, 0, 6), "health": 40},
			{"type": "archer", "position": Vector3(0, 0, 10), "health": 25},
			{"type": "melee", "position": Vector3(2, 0, 6), "health": 40}
		]
	},
	{
		"name": "Heavy Opposition",
		"description": "A heavy bruiser supported by archers - use strategy!",
		"enemies": [
			{"type": "heavy", "position": Vector3(0, 0, 7), "health": 80},
			{"type": "archer", "position": Vector3(-3, 0, 9), "health": 30},
			{"type": "archer", "position": Vector3(3, 0, 9), "health": 30}
		]
	},
	{
		"name": "Boss Encounter",
		"description": "Face the final boss - use everything you've learned!",
		"enemies": [
			{"type": "boss", "position": Vector3(0, 0, 10), "health": 150}
		]
	}
]

# UI Labels (will be created if not in scene)
var wave_label: Label = null
var status_label: Label = null
var tutorial_label: Label = null

func _ready():
	print("=== Tutorial Arena Level ===")
	print("This demonstrates modular component integration")

	# Setup scene
	_setup_environment()
	_setup_player()
	_setup_camera()
	_setup_ui()
	_setup_combat_system()

	# Start tutorial
	await get_tree().create_timer(1.0).timeout
	_show_intro_message()

func _setup_environment():
	"""Create basic environment if not present"""
	# Add ground plane
	if not has_node("Ground"):
		var ground = MeshInstance3D.new()
		ground.name = "Ground"
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(30, 30)
		ground.mesh = plane_mesh

		# Ground material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.5, 0.3)  # Green grass
		ground.set_surface_override_material(0, material)

		# Add collision
		var static_body = StaticBody3D.new()
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(30, 0.1, 30)
		collision_shape.shape = box_shape
		collision_shape.position = Vector3(0, -0.05, 0)

		static_body.add_child(collision_shape)
		ground.add_child(static_body)
		add_child(ground)

	# Add lighting
	if not has_node("DirectionalLight3D"):
		var light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.rotation_degrees = Vector3(-45, 30, 0)
		light.light_energy = 1.0
		light.shadow_enabled = true
		add_child(light)

	# Add world environment
	if not has_node("WorldEnvironment"):
		var world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		var environment = Environment.new()
		environment.background_mode = Environment.BG_SKY
		environment.sky = Sky.new()
		var sky_material = ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color(0.4, 0.6, 1.0)
		sky_material.sky_horizon_color = Color(0.6, 0.7, 0.9)
		sky_material.ground_bottom_color = Color(0.2, 0.3, 0.2)
		sky_material.ground_horizon_color = Color(0.4, 0.5, 0.4)
		environment.sky.sky_material = sky_material
		world_env.environment = environment
		add_child(world_env)

func _setup_player():
	"""Create or find player"""
	player = get_node_or_null("Player3D")

	if not player:
		# Try to load player scene
		var player_scene = load("res://scenes/Player3D.tscn")
		if player_scene:
			player = player_scene.instantiate()
			player.name = "Player3D"
			add_child(player)
			player.global_position = Vector3(0, 0, 0)
		else:
			# Create basic player representation
			player = _create_basic_player()
			add_child(player)

	# Connect player signals if available
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if player.has_signal("coin_collected"):
		player.coin_collected.connect(_on_coin_collected)

	print("Player setup complete")

func _create_basic_player() -> Node3D:
	"""Create a basic player if scene not available"""
	var player_node = CharacterBody3D.new()
	player_node.name = "Player3D"

	# Visual (blue capsule)
	var mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	mesh.mesh = capsule

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 1.0)  # Blue
	mesh.set_surface_override_material(0, material)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	collision.shape = shape

	player_node.add_child(mesh)
	player_node.add_child(collision)
	player_node.global_position = Vector3(0, 1, 0)

	return player_node

func _setup_camera():
	"""Setup camera to view the arena"""
	camera = get_node_or_null("Camera3D")

	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Position camera to view arena
	camera.global_position = Vector3(0, 8, -8)
	camera.look_at(Vector3(0, 0, 5), Vector3.UP)

func _setup_ui():
	"""Create UI overlay"""
	# Find or create CanvasLayer
	var canvas = get_node_or_null("UI")
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "UI"
		add_child(canvas)

	# Wave label (top center)
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.position = Vector2(10, 10)
	wave_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(wave_label)

	# Status label (top right)
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(10, 50)
	status_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(status_label)

	# Tutorial label (bottom center)
	tutorial_label = Label.new()
	tutorial_label.name = "TutorialLabel"
	tutorial_label.position = Vector2(10, 500)
	tutorial_label.add_theme_font_size_override("font_size", 20)
	tutorial_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	canvas.add_child(tutorial_label)

	_update_ui()

func _setup_combat_system():
	"""Initialize combat controller if available"""
	combat_controller = get_node_or_null("DaiCombatController")

	if not combat_controller:
		# Try to create one
		var combat_script = load("res://scripts/combat/DaiCombatController.gd")
		if combat_script:
			combat_controller = Node.new()
			combat_controller.set_script(combat_script)
			combat_controller.name = "DaiCombatController"
			add_child(combat_controller)

	if combat_controller and combat_controller.has_method("initialize"):
		combat_controller.initialize(player)

		# Connect combat signals if available
		if combat_controller.has_signal("skill_activated"):
			combat_controller.skill_activated.connect(_on_skill_activated)
		if combat_controller.has_signal("boss_staggered"):
			combat_controller.boss_staggered.connect(_on_boss_staggered)

func _show_intro_message():
	"""Display intro and start first wave"""
	tutorial_label.text = "Welcome to the Tutorial Arena! Press SPACE to start Wave 1"
	tutorial_state = TutorialState.INTRO

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space/Enter
		match tutorial_state:
			TutorialState.INTRO:
				_start_wave(0)
				tutorial_state = TutorialState.WAVE_1_MELEE

func _start_wave(wave_index: int):
	"""Start a specific wave"""
	if wave_index >= waves.size():
		_on_tutorial_complete()
		return

	current_wave = wave_index
	is_wave_active = true
	enemies_in_wave.clear()

	var wave_data = waves[wave_index]
	print("\n=== Starting Wave %d: %s ===" % [wave_index + 1, wave_data["name"]])
	print(wave_data["description"])

	# Update UI
	_update_ui()

	# Spawn enemies
	for enemy_config in wave_data["enemies"]:
		var enemy = _spawn_enemy(
			enemy_config["type"],
			enemy_config["position"],
			enemy_config.get("health", 50)
		)
		if enemy:
			enemies_in_wave.append(enemy)

func _spawn_enemy(type: String, spawn_position: Vector3, health: float) -> Node:
	"""Spawn an enemy of specified type"""
	# Create visual representation
	var enemy_root = _create_enemy_visual(type)
	add_child(enemy_root)
	enemy_root.global_position = spawn_position

	# Add AI component
	var enemy_ai = null
	match type:
		"melee":
			enemy_ai = BasicMeleeEnemy.new()
		"archer":
			enemy_ai = RangedArcherEnemy.new()
		"heavy":
			enemy_ai = HeavyBruiserEnemy.new()
		"boss":
			enemy_ai = BossEnemy.new()

	if enemy_ai:
		enemy_ai.name = "AI"
		enemy_ai.max_health = health
		enemy_ai.current_health = health
		enemy_ai.target_player = player
		enemy_root.add_child(enemy_ai)

		# Connect signals
		if enemy_ai.has_signal("enemy_died"):
			enemy_ai.enemy_died.connect(_on_enemy_died.bind(enemy_ai))
		if enemy_ai.has_signal("health_changed"):
			enemy_ai.health_changed.connect(_on_enemy_health_changed.bind(enemy_ai))

		# Register with combat system
		if combat_controller and combat_controller.has_method("register_enemy"):
			combat_controller.register_enemy(enemy_ai)

		print("Spawned %s enemy at %s (HP: %d)" % [type, spawn_position, health])
		return enemy_ai

	return null

func _create_enemy_visual(type: String) -> Node3D:
	"""Create geometric visual representation for enemy"""
	var root = CharacterBody3D.new()
	root.name = "Enemy_" + type
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()

	match type:
		"melee":
			# Red cube
			var box = BoxMesh.new()
			box.size = Vector3(1, 2, 1)
			mesh_instance.mesh = box
			material.albedo_color = Color(1, 0, 0)  # Red

		"archer":
			# Blue cone (pointing up like an arrow)
			var cone = CylinderMesh.new()
			cone.height = 2.0
			cone.top_radius = 0.3
			cone.bottom_radius = 0.6
			mesh_instance.mesh = cone
			material.albedo_color = Color(0, 0.5, 1)  # Blue

		"heavy":
			# Dark grey large cube
			var box = BoxMesh.new()
			box.size = Vector3(1.5, 2.5, 1.5)
			mesh_instance.mesh = box
			material.albedo_color = Color(0.3, 0.3, 0.3)  # Dark grey

		"boss":
			# Large purple sphere
			var sphere = SphereMesh.new()
			sphere.radius = 1.5
			sphere.height = 3.0
			mesh_instance.mesh = sphere
			material.albedo_color = Color(0.6, 0, 0.6)  # Purple

	mesh_instance.set_surface_override_material(0, material)
	mesh_instance.position.y = 1.0  # Lift off ground

	# Add collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	collision.shape = shape
	collision.position.y = 1.0

	root.add_child(mesh_instance)
	root.add_child(collision)

	return root

func _on_enemy_died(enemy_ai):
	"""Handle enemy death"""
	print("Enemy defeated!")

	# Remove from active list
	enemies_in_wave.erase(enemy_ai)

	# Award player (if methods exist)
	if player and player.has_method("add_experience"):
		player.add_experience(25)
	if player and player.has_method("add_currency"):
		player.add_currency(10)

	# Update UI
	_update_ui()

	# Check if wave complete
	if enemies_in_wave.is_empty() and is_wave_active:
		_on_wave_complete()

func _on_enemy_health_changed(new_health, max_health, enemy_ai):
	"""Visual feedback for enemy damage"""
	var health_percent = new_health / max_health
	# Could add health bar or visual indicator here

func _on_wave_complete():
	"""Wave completed successfully"""
	is_wave_active = false
	var wave_data = waves[current_wave]

	print("\n=== Wave %d Complete! ===" % [current_wave + 1])

	# Heal player between waves
	if player and player.has_method("heal"):
		player.heal(50)

	# Update tutorial state
	match current_wave:
		0:
			tutorial_state = TutorialState.WAVE_2_MIXED
			tutorial_label.text = "Wave 1 Complete! Press SPACE for Wave 2"
		1:
			tutorial_state = TutorialState.WAVE_3_HEAVY
			tutorial_label.text = "Wave 2 Complete! Press SPACE for Wave 3"
		2:
			tutorial_state = TutorialState.WAVE_4_BOSS
			tutorial_label.text = "Wave 3 Complete! Press SPACE for Boss Fight!"
		3:
			_on_tutorial_complete()

	_update_ui()

func _on_tutorial_complete():
	"""All waves completed"""
	tutorial_state = TutorialState.COMPLETE
	print("\n=== TUTORIAL COMPLETE! ===")
	print("You've mastered the modular combat system!")

	tutorial_label.text = "Tutorial Complete! You've mastered the basics!"
	wave_label.text = "VICTORY!"
	status_label.text = "All waves defeated. Great work!"

	# Could transition to main menu or next level here
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_player_died():
	"""Handle player death"""
	print("Player defeated!")
	tutorial_label.text = "Defeated! Restarting wave..."

	# Clear current enemies
	for enemy in enemies_in_wave:
		if enemy and enemy.get_parent():
			enemy.get_parent().queue_free()
	enemies_in_wave.clear()

	# Restart current wave after delay
	await get_tree().create_timer(2.0).timeout
	_start_wave(current_wave)

func _on_coin_collected(amount):
	"""Handle coin collection"""
	print("Collected %d coins" % amount)

func _on_skill_activated(skill_name, damage):
	"""Combat system skill feedback"""
	print("Skill used: %s (Damage: %d)" % [skill_name, damage])

func _on_boss_staggered():
	"""Boss stagger event"""
	print("Boss staggered! Attack now!")
	tutorial_label.text = "Boss staggered! Deal extra damage!"

func _update_ui():
	"""Update UI labels"""
	if not wave_label or not status_label:
		return

	if current_wave < waves.size():
		var wave_data = waves[current_wave]
		wave_label.text = "Wave %d/%d: %s" % [current_wave + 1, waves.size(), wave_data["name"]]
		status_label.text = "Enemies: %d remaining" % enemies_in_wave.size()
	else:
		wave_label.text = "All Waves Complete!"
		status_label.text = ""

func _process(_delta):
	"""Update logic each frame"""
	# Could add additional game loop logic here
	pass
