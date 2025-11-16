extends Node3D
class_name CombatLevelManager

## Combat Level Manager
## Manages waves of enemies in a combat arena

# UI references
@onready var wave_label: Label = $UI/WaveLabel
@onready var enemy_count_label: Label = $UI/EnemyCountLabel
@onready var victory_panel: Panel = $UI/VictoryPanel
@onready var player: CharacterBody3D = $Player

# Wave management
var current_wave = 1
var total_waves = 3
var enemies_remaining = 0
var enemies_defeated = 0
var all_waves_cleared = false

# Enemy wave groups
var wave_groups: Array[Node3D] = []

func _ready():
	print("=== Combat Level Starting ===")

	# Collect wave groups
	wave_groups = [
		$EnemyWave1,
		$EnemyWave2,
		$EnemyWave3
	]

	# Hide all waves except the first
	for i in range(wave_groups.size()):
		if i > 0:
			hide_wave(wave_groups[i])

	# Connect enemy signals
	setup_enemy_connections()

	# Count initial enemies
	count_enemies()

	# Update UI
	update_ui()

	print("Combat level ready. Wave 1 starting with ", enemies_remaining, " enemies")

func setup_enemy_connections():
	"""Connect to all enemy death signals"""
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

func hide_wave(wave: Node3D):
	"""Hide all enemies in a wave"""
	for enemy in wave.get_children():
		if enemy is CharacterBody3D:
			enemy.visible = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED

func show_wave(wave: Node3D):
	"""Show all enemies in a wave"""
	for enemy in wave.get_children():
		if enemy is CharacterBody3D:
			enemy.visible = true
			enemy.process_mode = Node.PROCESS_MODE_INHERIT

func count_enemies():
	"""Count remaining active enemies"""
	enemies_remaining = 0
	var current_wave_group = wave_groups[current_wave - 1]

	for enemy in current_wave_group.get_children():
		if enemy is CharacterBody3D and enemy.visible:
			enemies_remaining += 1

func _on_enemy_died(enemy: EnemyAI):
	"""Handle enemy death"""
	enemies_defeated += 1
	enemies_remaining -= 1

	print("Enemy defeated! Remaining: ", enemies_remaining)

	update_ui()

	# Check if wave is cleared
	if enemies_remaining <= 0:
		wave_cleared()

func wave_cleared():
	"""Handle wave completion"""
	print("Wave ", current_wave, " cleared!")

	# Check if there are more waves
	if current_wave < total_waves:
		# Start next wave
		await get_tree().create_timer(2.0).timeout
		start_next_wave()
	else:
		# All waves complete!
		level_complete()

func start_next_wave():
	"""Start the next wave of enemies"""
	current_wave += 1
	print("Starting wave ", current_wave)

	# Show the next wave
	if current_wave <= wave_groups.size():
		show_wave(wave_groups[current_wave - 1])

	# Count new enemies
	count_enemies()

	# Update UI
	update_ui()

	# Flash wave label
	if wave_label:
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(wave_label, "modulate:a", 0.3, 0.3)
		tween.tween_property(wave_label, "modulate:a", 1.0, 0.3)

func level_complete():
	"""Handle level completion"""
	print("=== LEVEL COMPLETE! ===")
	all_waves_cleared = true

	# Show victory screen
	if victory_panel:
		victory_panel.visible = true

		# Pulse the victory panel
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(victory_panel, "modulate:a", 0.7, 0.8)
		tween.tween_property(victory_panel, "modulate:a", 1.0, 0.8)

func update_ui():
	"""Update UI labels"""
	if wave_label:
		wave_label.text = "Combat Level - Wave " + str(current_wave) + "/" + str(total_waves)

	if enemy_count_label:
		enemy_count_label.text = "Enemies: " + str(enemies_remaining) + " | Defeated: " + str(enemies_defeated)

func _process(_delta):
	# Check for restart/continue
	if all_waves_cleared and Input.is_action_just_pressed("jump"):
		# Return to main menu or next level
		get_tree().change_scene_to_file("res://scenes/DemoLauncher.tscn")
