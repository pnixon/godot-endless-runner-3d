extends CanvasLayer
class_name RunnerUI

# UI for the endless runner game
# Displays score, health, coins, power-ups, and game over screen

# Label references
var score_label: Label
var coins_label: Label
var distance_label: Label
var health_bar: ProgressBar
var health_label: Label

# Power-up indicators
var shield_indicator: Panel
var speed_indicator: Panel
var magnet_indicator: Panel

# Game over screen
var game_over_panel: Panel
var final_score_label: Label
var high_score_label: Label
var restart_label: Label

# Title screen
var title_panel: Panel
var title_label: Label
var start_label: Label

var game_manager: EndlessRunnerManager
var player: CharacterBody3D

func _ready():
	create_ui()

	# Find game manager
	await get_tree().process_frame  # Wait for scene to be ready
	game_manager = get_node_or_null("../EndlessRunnerManager")
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")

	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.coins_changed.connect(_on_coins_changed)
		game_manager.game_over.connect(_on_game_over)
		game_manager.game_started.connect(_on_game_started)
		print("✓ UI connected to game manager")

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("✓ UI found player")

	show_title_screen()

func create_ui():
	"""Create all UI elements"""
	create_hud()
	create_power_up_indicators()
	create_game_over_screen()
	create_title_screen()

func create_hud():
	"""Create the main HUD elements"""
	# Score label (top center)
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Score: 0"
	score_label.position = Vector2(400, 20)
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(score_label)

	# Coins label (top right)
	coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.text = "Coins: 0"
	coins_label.position = Vector2(800, 20)
	coins_label.add_theme_font_size_override("font_size", 24)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	add_child(coins_label)

	# Health bar (top left)
	create_health_display()

func create_health_display():
	"""Create health bar and label"""
	# Health label
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "Health"
	health_label.position = Vector2(20, 20)
	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(health_label)

	# Health bar
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(20, 50)
	health_bar.size = Vector2(200, 30)
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false

	# Style the health bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2)
	style_bg.border_color = Color(0.5, 0.5, 0.5)
	style_bg.set_border_width_all(2)
	health_bar.add_theme_stylebox_override("background", style_bg)

	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.2, 0.8, 0.2)
	health_bar.add_theme_stylebox_override("fill", style_fg)

	add_child(health_bar)

func create_power_up_indicators():
	"""Create indicators for active power-ups"""
	var start_x = 20
	var start_y = 100
	var spacing = 60

	# Shield indicator
	shield_indicator = create_power_up_icon("Shield", Color(0.0, 0.8, 0.8), start_x, start_y)
	shield_indicator.visible = false
	add_child(shield_indicator)

	# Speed indicator
	speed_indicator = create_power_up_icon("Speed", Color(0.2, 0.6, 1.0), start_x, start_y + spacing)
	speed_indicator.visible = false
	add_child(speed_indicator)

	# Magnet indicator
	magnet_indicator = create_power_up_icon("Magnet", Color(0.8, 0.2, 0.8), start_x, start_y + spacing * 2)
	magnet_indicator.visible = false
	add_child(magnet_indicator)

func create_power_up_icon(text: String, color: Color, x: float, y: float) -> Panel:
	"""Create a power-up indicator icon"""
	var panel = Panel.new()
	panel.size = Vector2(50, 50)
	panel.position = Vector2(x, y)

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = text[0]  # First letter
	label.position = Vector2(15, 10)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)

	return panel

func create_game_over_screen():
	"""Create the game over screen"""
	game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.position = Vector2(312, 150)
	game_over_panel.size = Vector2(400, 300)
	game_over_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_corner_radius_all(10)
	style.border_color = Color(0.8, 0.2, 0.2)
	style.set_border_width_all(3)
	game_over_panel.add_theme_stylebox_override("panel", style)

	# Game Over title
	var title = Label.new()
	title.text = "GAME OVER"
	title.position = Vector2(100, 30)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	game_over_panel.add_child(title)

	# Final score
	final_score_label = Label.new()
	final_score_label.text = "Score: 0"
	final_score_label.position = Vector2(120, 110)
	final_score_label.add_theme_font_size_override("font_size", 32)
	final_score_label.add_theme_color_override("font_color", Color.WHITE)
	game_over_panel.add_child(final_score_label)

	# High score
	high_score_label = Label.new()
	high_score_label.text = "High Score: 0"
	high_score_label.position = Vector2(100, 160)
	high_score_label.add_theme_font_size_override("font_size", 28)
	high_score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	game_over_panel.add_child(high_score_label)

	# Restart instruction
	restart_label = Label.new()
	restart_label.text = "Press SPACE to restart"
	restart_label.position = Vector2(70, 230)
	restart_label.add_theme_font_size_override("font_size", 24)
	restart_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	game_over_panel.add_child(restart_label)

	add_child(game_over_panel)

func create_title_screen():
	"""Create the title/start screen"""
	title_panel = Panel.new()
	title_panel.name = "TitlePanel"
	title_panel.position = Vector2(262, 100)
	title_panel.size = Vector2(500, 400)
	title_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_corner_radius_all(15)
	style.border_color = Color(0.2, 0.6, 1.0)
	style.set_border_width_all(4)
	title_panel.add_theme_stylebox_override("panel", style)

	# Title
	title_label = Label.new()
	title_label.text = "ENDLESS RUNNER"
	title_label.position = Vector2(80, 40)
	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_panel.add_child(title_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "3D Prototype"
	subtitle.position = Vector2(170, 110)
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_panel.add_child(subtitle)

	# Controls
	var controls = Label.new()
	controls.text = "Controls:\nA/D - Switch Lanes\nW/S - Move Forward/Back\nSPACE - Jump\nSHIFT - Slide"
	controls.position = Vector2(120, 180)
	controls.add_theme_font_size_override("font_size", 22)
	controls.add_theme_color_override("font_color", Color.WHITE)
	title_panel.add_child(controls)

	# Start instruction
	start_label = Label.new()
	start_label.text = "Press SPACE to start"
	start_label.position = Vector2(110, 330)
	start_label.add_theme_font_size_override("font_size", 28)
	start_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	title_panel.add_child(start_label)

	add_child(title_panel)

func _process(_delta):
	"""Update UI elements"""
	# Update health bar
	if player and player.has_method("get") and health_bar:
		if "current_health" in player and "MAX_HEALTH" in player:
			health_bar.value = player.current_health
			health_bar.max_value = player.MAX_HEALTH

			# Update health bar color
			var health_ratio = player.current_health / player.MAX_HEALTH
			var style_fg = health_bar.get_theme_stylebox("fill")
			if style_fg is StyleBoxFlat:
				if health_ratio > 0.6:
					style_fg.bg_color = Color(0.2, 0.8, 0.2)  # Green
				elif health_ratio > 0.3:
					style_fg.bg_color = Color(0.9, 0.7, 0.1)  # Yellow
				else:
					style_fg.bg_color = Color(0.9, 0.2, 0.2)  # Red

	# Update power-up indicators
	if game_manager:
		shield_indicator.visible = game_manager.has_shield
		speed_indicator.visible = game_manager.has_speed_boost
		magnet_indicator.visible = game_manager.has_magnet

func _on_score_changed(new_score: int):
	"""Update score display"""
	score_label.text = "Score: " + str(new_score)

func _on_coins_changed(new_coins: int):
	"""Update coins display"""
	coins_label.text = "Coins: " + str(new_coins)

func _on_game_over():
	"""Show game over screen"""
	if game_manager:
		final_score_label.text = "Score: " + str(game_manager.get_score())
		high_score_label.text = "High Score: " + str(game_manager.get_high_score())

	game_over_panel.visible = true

	# Pulse the restart label
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(restart_label, "modulate:a", 0.3, 0.7)
	tween.tween_property(restart_label, "modulate:a", 1.0, 0.7)

func _on_game_started():
	"""Hide menu screens when game starts"""
	game_over_panel.visible = false
	title_panel.visible = false

func show_title_screen():
	"""Show the title screen"""
	title_panel.visible = true

	# Pulse the start label
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(start_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(start_label, "modulate:a", 1.0, 0.8)
