extends Node2D

const SCROLL_SPEED = 150.0

@onready var road_lines = []
@onready var background_sprite: Sprite2D
@onready var platform_sprite: Sprite2D

var current_biome = 0
var water_colors = [
	Color(0.2, 0.4, 0.8, 1.0),      # Biome 0: Deep blue water
	Color(0.1, 0.3, 0.6, 1.0),      # Biome 1: Darker water
	Color(0.3, 0.5, 0.7, 1.0)       # Biome 2: Storm water
]

var wood_colors = [
	Color(0.6, 0.4, 0.2, 1.0),      # Biome 0: Light brown wood
	Color(0.5, 0.3, 0.15, 1.0),     # Biome 1: Darker wood
	Color(0.4, 0.25, 0.1, 1.0)      # Biome 2: Dark weathered wood
]

func _ready():
	add_to_group("background")
	
	# Set background Z-index to be behind everything else
	z_index = -10
	
	create_water_background()
	create_wooden_platform()

func create_water_background():
	# Create water background
	background_sprite = Sprite2D.new()
	background_sprite.z_index = -2  # Behind platform
	var texture = ImageTexture.new()
	var image = Image.create(1024, 600, false, Image.FORMAT_RGB8)
	image.fill(water_colors[current_biome])
	texture.set_image(image)
	background_sprite.texture = texture
	background_sprite.position = Vector2(512, 300)
	add_child(background_sprite)

func create_wooden_platform():
	# Create wooden platform in the center (covering the 3 lanes)
	platform_sprite = Sprite2D.new()
	platform_sprite.z_index = -1  # Above water, below everything else
	
	# Platform covers from lane 0 to lane 2 with some padding
	var platform_width = 320  # Wide enough to cover all 3 lanes (384 to 640 = 256px + padding)
	var platform_height = 600  # Full screen height
	
	var texture = create_wooden_texture(platform_width, platform_height)
	platform_sprite.texture = texture
	platform_sprite.position = Vector2(512, 300)  # Center of screen
	add_child(platform_sprite)
	
	# Create wooden planks pattern
	create_wooden_planks()

func create_wooden_texture(width: int, height: int) -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	# Fill with base wood color
	var base_wood = wood_colors[current_biome]
	image.fill(base_wood)
	
	# Add wood grain pattern (horizontal lines)
	for y in range(0, height, 8):  # Every 8 pixels
		var grain_color = base_wood * 0.9  # Slightly darker
		for x in range(width):
			if y < height:
				image.set_pixel(x, y, grain_color)
	
	# Add some vertical plank separators
	for x in range(0, width, 64):  # Every 64 pixels
		var separator_color = base_wood * 0.7  # Much darker
		for y in range(height):
			if x < width:
				image.set_pixel(x, y, separator_color)
				if x + 1 < width:
					image.set_pixel(x + 1, y, separator_color)
	
	texture.set_image(image)
	return texture

func create_wooden_planks():
	# Create scrolling plank lines to show movement
	for i in range(-1, 8):  # Create multiple plank segments
		var plank = Sprite2D.new()
		plank.z_index = 0  # Above platform, below hazards
		
		# Create a thin plank texture
		var plank_texture = ImageTexture.new()
		var plank_image = Image.create(280, 12, false, Image.FORMAT_RGB8)
		var plank_color = wood_colors[current_biome] * 0.8  # Darker than base
		plank_image.fill(plank_color)
		
		# Add plank edges
		for x in range(280):
			plank_image.set_pixel(x, 0, plank_color * 0.6)  # Top edge
			plank_image.set_pixel(x, 11, plank_color * 0.6)  # Bottom edge
		
		plank_texture.set_image(plank_image)
		plank.texture = plank_texture
		plank.position = Vector2(512, i * 80)  # Center horizontally, spaced vertically
		add_child(plank)
		road_lines.append(plank)

func change_biome(biome_index: int):
	current_biome = biome_index % water_colors.size()
	
	# Update water background color
	var texture = ImageTexture.new()
	var image = Image.create(1024, 600, false, Image.FORMAT_RGB8)
	image.fill(water_colors[current_biome])
	texture.set_image(image)
	background_sprite.texture = texture
	
	# Update wooden platform
	var platform_width = 320
	var platform_height = 600
	platform_sprite.texture = create_wooden_texture(platform_width, platform_height)
	
	# Update plank colors
	for plank in road_lines:
		if plank and is_instance_valid(plank):
			var plank_texture = ImageTexture.new()
			var plank_image = Image.create(280, 12, false, Image.FORMAT_RGB8)
			var plank_color = wood_colors[current_biome] * 0.8
			plank_image.fill(plank_color)
			
			# Add plank edges
			for x in range(280):
				plank_image.set_pixel(x, 0, plank_color * 0.6)
				plank_image.set_pixel(x, 11, plank_color * 0.6)
			
			plank_texture.set_image(plank_image)
			plank.texture = plank_texture
	
	# Add biome transition effect
	var tween = create_tween()
	background_sprite.modulate = Color.WHITE * 1.3
	tween.tween_property(background_sprite, "modulate", Color.WHITE, 0.5)

func _process(delta):
	# Move wooden planks down to show movement
	for plank in road_lines:
		if plank and is_instance_valid(plank):
			plank.position.y += SCROLL_SPEED * delta
			
			# Reset plank position when it goes off screen
			if plank.position.y > 650:
				plank.position.y = -50
