extends Area2D

const SPEED = 300.0
const LANE_POSITIONS = [256, 512, 768]

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Create a simple colored rectangle for obstacles
	var texture = ImageTexture.new()
	var image = Image.create(48, 64, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	texture.set_image(image)
	sprite.texture = texture
	
	# Set up collision shape
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 64)
	collision_shape.shape = shape
	
	# Connect body entered signal for collision detection
	body_entered.connect(_on_body_entered)
	
	# Randomly choose a lane
	var lane = randi() % 3
	position.x = LANE_POSITIONS[lane]

func _physics_process(delta):
	# Move obstacle downward
	position.y += SPEED * delta
	
	# Remove obstacle when it goes off screen
	if position.y > 700:
		cleanup()
		queue_free()

func cleanup():
	# Clear collision shape reference to prevent memory leak
	if collision_shape and collision_shape.shape:
		collision_shape.shape = null

func _exit_tree():
	# Ensure cleanup when node is removed from tree
	cleanup()

func _on_body_entered(body):
	if body.name == "Player":
		# Handle collision with player
		get_tree().call_group("game_manager", "game_over")
