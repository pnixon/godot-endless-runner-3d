extends Node

## Mobile UI Manager for Android RPG
## Handles UI scaling, screen adaptation, and mobile-optimized layouts

signal screen_size_changed(new_size: Vector2)
signal orientation_changed(is_landscape: bool)

@export var base_resolution: Vector2 = Vector2(1024, 600)
@export var min_ui_scale: float = 0.5
@export var max_ui_scale: float = 2.0
@export var touch_button_min_size: float = 64.0

var current_screen_size: Vector2
var ui_scale_factor: float = 1.0
var is_landscape: bool = true
var safe_area: Rect2

# UI element references
var ui_canvas_layer: CanvasLayer
var touch_controls_container: Control

func _ready():
	setup_mobile_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func setup_mobile_ui():
	current_screen_size = get_viewport().get_visible_rect().size
	calculate_ui_scale()
	setup_safe_area()
	
	print("Mobile UI initialized - Screen: ", current_screen_size, " Scale: ", ui_scale_factor)

func calculate_ui_scale():
	# Calculate scale factor based on screen size
	var scale_x = current_screen_size.x / base_resolution.x
	var scale_y = current_screen_size.y / base_resolution.y
	
	# Use the smaller scale to ensure UI fits on screen
	ui_scale_factor = min(scale_x, scale_y)
	ui_scale_factor = clamp(ui_scale_factor, min_ui_scale, max_ui_scale)
	
	# Adjust for high DPI displays
	if OS.has_feature("mobile"):
		var dpi_scale = DisplayServer.screen_get_dpi() / 160.0  # Android baseline DPI
		ui_scale_factor *= clamp(dpi_scale, 0.8, 1.5)

func setup_safe_area():
	# Get safe area for devices with notches/rounded corners
	if OS.has_feature("mobile"):
		var safe_rect = DisplayServer.get_display_safe_area()
		safe_area = Rect2(safe_rect.position, safe_rect.size)
	else:
		safe_area = Rect2(Vector2.ZERO, current_screen_size)

func _on_viewport_size_changed():
	var new_size = get_viewport().get_visible_rect().size
	if new_size != current_screen_size:
		current_screen_size = new_size
		var was_landscape = is_landscape
		is_landscape = current_screen_size.x > current_screen_size.y
		
		calculate_ui_scale()
		setup_safe_area()
		
		emit_signal("screen_size_changed", current_screen_size)
		
		if was_landscape != is_landscape:
			emit_signal("orientation_changed", is_landscape)
		
		adapt_ui_layout()

func adapt_ui_layout():
	# Adapt UI elements to new screen size/orientation
	if ui_canvas_layer:
		scale_ui_elements()
	
	# Adjust touch controls for new layout
	if touch_controls_container:
		position_touch_controls()

func scale_ui_elements():
	# Apply scaling to UI elements
	var ui_nodes = get_tree().get_nodes_in_group("mobile_ui")
	for node in ui_nodes:
		if node is Control:
			apply_mobile_scaling(node)
		elif node is TouchScreenButton:
			apply_touch_button_scaling(node)

func apply_mobile_scaling(control: Control):
	# Apply appropriate scaling based on control type
	if control is Button:
		# Ensure touch targets are large enough
		var min_size = Vector2(touch_button_min_size, touch_button_min_size) * ui_scale_factor
		control.custom_minimum_size = control.custom_minimum_size.max(min_size)
	
	# Apply general UI scaling
	if control.has_method("set_scale"):
		control.scale = Vector2.ONE * ui_scale_factor

func apply_touch_button_scaling(touch_button: TouchScreenButton):
	# Apply appropriate scaling for TouchScreenButton
	var min_size = Vector2(touch_button_min_size, touch_button_min_size) * ui_scale_factor
	touch_button.scale = Vector2.ONE * ui_scale_factor

func position_touch_controls():
	# Position touch controls within safe area
	if not touch_controls_container:
		return
	
	var safe_margin = 20 * ui_scale_factor
	touch_controls_container.position = safe_area.position + Vector2(safe_margin, safe_margin)
	touch_controls_container.size = safe_area.size - Vector2(safe_margin * 2, safe_margin * 2)

func create_touch_controls_overlay() -> Control:
	# Create overlay for touch controls
	var overlay = Control.new()
	overlay.name = "TouchControlsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to mobile UI group for scaling
	overlay.add_to_group("mobile_ui")
	
	return overlay

func add_touch_button(button_name: String, position: Vector2, size: Vector2, texture: Texture2D = null):
	if not touch_controls_container:
		touch_controls_container = create_touch_controls_overlay()
		get_tree().current_scene.add_child(touch_controls_container)
	
	var button = TouchScreenButton.new()
	button.name = button_name
	button.position = position * ui_scale_factor
	button.scale = Vector2.ONE * ui_scale_factor
	
	if texture:
		button.texture_normal = texture
	
	# Ensure minimum touch target size
	var min_size = Vector2(touch_button_min_size, touch_button_min_size)
	if size.length() < min_size.length():
		size = min_size
	
	var shape = RectangleShape2D.new()
	shape.size = size
	button.shape = shape
	
	touch_controls_container.add_child(button)
	return button

func get_ui_scale_factor() -> float:
	return ui_scale_factor

func get_safe_area() -> Rect2:
	return safe_area

func is_mobile_device() -> bool:
	return OS.has_feature("mobile")

func get_screen_orientation() -> String:
	return "landscape" if is_landscape else "portrait"

func adapt_font_sizes():
	# Adapt font sizes for mobile readability
	var labels = get_tree().get_nodes_in_group("mobile_ui_text")
	for label in labels:
		if label is Label:
			adapt_label_font_size(label)

func adapt_label_font_size(label: Label):
	# Ensure text is readable on mobile
	var base_font_size = 16
	var scaled_font_size = int(base_font_size * ui_scale_factor)
	scaled_font_size = max(scaled_font_size, 12)  # Minimum readable size
	
	if label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", scaled_font_size)

# Utility functions for common mobile UI patterns
func show_mobile_keyboard():
	if OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_show("", Rect2())

func hide_mobile_keyboard():
	if OS.has_feature("mobile"):
		DisplayServer.virtual_keyboard_hide()

func get_device_info() -> Dictionary:
	return {
		"screen_size": current_screen_size,
		"ui_scale": ui_scale_factor,
		"safe_area": safe_area,
		"orientation": get_screen_orientation(),
		"dpi": DisplayServer.screen_get_dpi(),
		"is_mobile": is_mobile_device()
	}
