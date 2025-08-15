extends Sprite2D

func _ready():
	print("TestSprite _ready() called")
	
	# Create the simplest possible visible sprite
	var texture = ImageTexture.new()
	var image = Image.create(100, 100, false, Image.FORMAT_RGB8)
	image.fill(Color.MAGENTA)  # Bright magenta should be impossible to miss
	texture.set_image(image)
	
	self.texture = texture
	self.position = Vector2(400, 300)  # Center of screen
	self.z_index = 1000  # Way above everything
	self.modulate = Color.WHITE
	self.visible = true
	
	print("Created test sprite:")
	print("  - Position: ", position)
	print("  - Size: 100x100")
	print("  - Color: MAGENTA")
	print("  - Z-index: ", z_index)
	print("  - Visible: ", visible)
	print("  - Modulate: ", modulate)
	print("  - Texture: ", texture != null)
	
	# Also create a simple ColorRect as backup
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(50, 50)
	color_rect.position = Vector2(500, 300)
	color_rect.color = Color.CYAN
	color_rect.z_index = 1001
	get_parent().add_child(color_rect)
	print("Also created cyan ColorRect at (500, 300)")
