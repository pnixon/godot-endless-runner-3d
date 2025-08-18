extends Control
class_name TouchZoneIndicator

## Visual indicators for touch zones and gesture recognition feedback
## Shows players where to touch for different combat actions

signal zone_touched(zone_type: String)

enum ZoneType {
	DODGE_LEFT,
	DODGE_RIGHT,
	DODGE_BACK,
	DASH_FORWARD,
	BLOCK_HOLD,
	GENERAL_TOUCH
}

# Zone settings
@export var show_zones: bool = true
@export var zone_opacity: float = 0.3
@export var feedback_duration: float = 0.2
@export var zone_colors: Dictionary = {
	ZoneType.DODGE_LEFT: Color.ORANGE,
	ZoneType.DODGE_RIGHT: Color.ORANGE,
	ZoneType.DODGE_BACK: Color.YELLOW,
	ZoneType.DASH_FORWARD: Color.CYAN,
	ZoneType.BLOCK_HOLD: Color.BLUE,
	ZoneType.GENERAL_TOUCH: Color.WHITE
}

# Zone areas (as percentages of screen)
var zone_areas: Dictionary = {}
var zone_indicators: Dictionary = {}
var feedback_effects: Array = []

# References
var mobile_input_manager: MobileInputManager

func _ready():
	# Set up full screen coverage
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Find mobile input manager
	mobile_input_manager = get_node("/root/MobileInputManager")
	if mobile_input_manager:
		mobile_input_manager.combat_gesture_detected.connect(_on_combat_gesture_detected)
		mobile_input_manager.gesture_detected.connect(_on_gesture_detected)
	
	# Initialize touch zones
	setup_touch_zones()
	
	# Create zone indicators
	create_zone_indicators()
	
	print("Touch zone indicators initialized")

func setup_touch_zones():
	"""Define touch zone areas as screen percentages"""
	var screen_size = get_viewport().get_visible_rect().size
	
	# Define zones (x, y, width, height as percentages)
	zone_areas = {
		ZoneType.DODGE_LEFT: {"x": 0.0, "y": 0.3, "w": 0.25, "h": 0.4},
		ZoneType.DODGE_RIGHT: {"x": 0.75, "y": 0.3, "w": 0.25, "h": 0.4},
		ZoneType.DODGE_BACK: {"x": 0.25, "y": 0.7, "w": 0.5, "h": 0.3},
		ZoneType.DASH_FORWARD: {"x": 0.25, "y": 0.0, "w": 0.5, "h": 0.3},
		ZoneType.BLOCK_HOLD: {"x": 0.3, "y": 0.3, "w": 0.4, "h": 0.4},
		ZoneType.GENERAL_TOUCH: {"x": 0.0, "y": 0.0, "w": 1.0, "h": 1.0}
	}

func create_zone_indicators():
	"""Create visual indicators for touch zones"""
	if not show_zones:
		return
	
	var screen_size = get_viewport().get_visible_rect().size
	
	for zone_type in zone_areas.keys():
		if zone_type == ZoneType.GENERAL_TOUCH:
			continue  # Skip general touch zone
		
		var zone_data = zone_areas[zone_type]
		var indicator = ColorRect.new()
		
		# Calculate position and size
		var x = zone_data.x * screen_size.x
		var y = zone_data.y * screen_size.y
		var w = zone_data.w * screen_size.x
		var h = zone_data.h * screen_size.y
		
		indicator.position = Vector2(x, y)
		indicator.size = Vector2(w, h)
		indicator.color = zone_colors.get(zone_type, Color.WHITE)
		indicator.color.a = zone_opacity
		
		# Add border
		var border = ReferenceRect.new()
		border.border_color = indicator.color
		border.border_width = 2.0
		border.position = Vector2.ZERO
		border.size = indicator.size
		indicator.add_child(border)
		
		# Add label
		var label = Label.new()
		label.text = get_zone_label(zone_type)
		label.position = Vector2(10, 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		indicator.add_child(label)
		
		add_child(indicator)
		zone_indicators[zone_type] = indicator
		
		print("Created zone indicator for: ", get_zone_label(zone_type))

func get_zone_label(zone_type: ZoneType) -> String:
	"""Get display label for zone type"""
	match zone_type:
		ZoneType.DODGE_LEFT:
			return "◀ Dodge Left"
		ZoneType.DODGE_RIGHT:
			return "Dodge Right ▶"
		ZoneType.DODGE_BACK:
			return "▼ Dodge Back"
		ZoneType.DASH_FORWARD:
			return "▲ Dash Forward"
		ZoneType.BLOCK_HOLD:
			return "🛡 Hold to Block"
		_:
			return "Touch Zone"

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	"""Handle general gesture detection for visual feedback"""
	create_gesture_feedback(gesture_type, position)

func _on_combat_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	"""Handle combat gesture detection for enhanced visual feedback"""
	create_combat_gesture_feedback(gesture_type, position)

func create_gesture_feedback(gesture_type: MobileInputManager.GestureType, position: Vector2):
	"""Create visual feedback for gesture recognition"""
	var feedback_color = Color.WHITE
	var feedback_text = ""
	
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			feedback_color = Color.ORANGE
			feedback_text = "◀"
		MobileInputManager.GestureType.SWIPE_RIGHT:
			feedback_color = Color.ORANGE
			feedback_text = "▶"
		MobileInputManager.GestureType.SWIPE_DOWN:
			feedback_color = Color.YELLOW
			feedback_text = "▼"
		MobileInputManager.GestureType.SWIPE_UP:
			feedback_color = Color.CYAN
			feedback_text = "▲"
		MobileInputManager.GestureType.TAP:
			feedback_color = Color.GREEN
			feedback_text = "●"
		MobileInputManager.GestureType.LONG_PRESS:
			feedback_color = Color.BLUE
			feedback_text = "◉"
		MobileInputManager.GestureType.TWO_FINGER_TAP:
			feedback_color = Color.PURPLE
			feedback_text = "◉◉"
	
	create_feedback_effect(position, feedback_color, feedback_text)

func create_combat_gesture_feedback(gesture_type: MobileInputManager.GestureType, position: Vector2):
	"""Create enhanced visual feedback for combat gestures"""
	var feedback_color = Color.WHITE
	var feedback_text = ""
	var enhanced = true
	
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			feedback_color = Color.ORANGE
			feedback_text = "DODGE LEFT"
		MobileInputManager.GestureType.SWIPE_RIGHT:
			feedback_color = Color.ORANGE
			feedback_text = "DODGE RIGHT"
		MobileInputManager.GestureType.SWIPE_DOWN:
			feedback_color = Color.YELLOW
			feedback_text = "DODGE BACK"
		MobileInputManager.GestureType.SWIPE_UP:
			feedback_color = Color.CYAN
			feedback_text = "DASH FORWARD"
	
	create_feedback_effect(position, feedback_color, feedback_text, enhanced)

func create_feedback_effect(position: Vector2, color: Color, text: String, enhanced: bool = false):
	"""Create visual feedback effect at position"""
	var effect = Label.new()
	effect.text = text
	effect.position = position - Vector2(50, 25)  # Center the text
	effect.add_theme_color_override("font_color", color)
	effect.add_theme_color_override("font_shadow_color", Color.BLACK)
	effect.add_theme_constant_override("shadow_offset_x", 2)
	effect.add_theme_constant_override("shadow_offset_y", 2)
	
	if enhanced:
		effect.add_theme_font_size_override("font_size", 24)
	else:
		effect.add_theme_font_size_override("font_size", 18)
	
	add_child(effect)
	feedback_effects.append(effect)
	
	# Animate feedback effect
	var tween = create_tween()
	tween.parallel().tween_property(effect, "position:y", effect.position.y - 50, feedback_duration)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, feedback_duration)
	tween.tween_callback(func(): remove_feedback_effect(effect))

func remove_feedback_effect(effect: Label):
	"""Remove feedback effect from scene"""
	if effect in feedback_effects:
		feedback_effects.erase(effect)
	if effect.get_parent():
		effect.queue_free()

func highlight_zone(zone_type: ZoneType, duration: float = 0.5):
	"""Highlight a specific touch zone"""
	if zone_type not in zone_indicators:
		return
	
	var indicator = zone_indicators[zone_type]
	var original_color = indicator.color
	
	# Flash the zone
	var tween = create_tween()
	tween.tween_property(indicator, "color:a", zone_opacity * 2, 0.1)
	tween.tween_property(indicator, "color:a", zone_opacity, 0.1)
	tween.tween_property(indicator, "color:a", zone_opacity * 2, 0.1)
	tween.tween_property(indicator, "color:a", zone_opacity, 0.1)

func set_zones_visible(visible: bool):
	"""Show or hide touch zone indicators"""
	show_zones = visible
	for indicator in zone_indicators.values():
		indicator.visible = visible

func set_zone_opacity(opacity: float):
	"""Set opacity of touch zone indicators"""
	zone_opacity = clamp(opacity, 0.0, 1.0)
	for indicator in zone_indicators.values():
		var color = indicator.color
		color.a = zone_opacity
		indicator.color = color

func get_zone_at_position(position: Vector2) -> ZoneType:
	"""Get the zone type at a given screen position"""
	var screen_size = get_viewport().get_visible_rect().size
	var normalized_pos = Vector2(position.x / screen_size.x, position.y / screen_size.y)
	
	# Check zones in priority order (most specific first)
	for zone_type in [ZoneType.DODGE_LEFT, ZoneType.DODGE_RIGHT, ZoneType.DODGE_BACK, 
					  ZoneType.DASH_FORWARD, ZoneType.BLOCK_HOLD]:
		var zone_data = zone_areas[zone_type]
		if (normalized_pos.x >= zone_data.x and normalized_pos.x <= zone_data.x + zone_data.w and
			normalized_pos.y >= zone_data.y and normalized_pos.y <= zone_data.y + zone_data.h):
			return zone_type
	
	return ZoneType.GENERAL_TOUCH

func show_tutorial_hint(zone_type: ZoneType, hint_text: String, duration: float = 3.0):
	"""Show a tutorial hint for a specific zone"""
	if zone_type not in zone_indicators:
		return
	
	var indicator = zone_indicators[zone_type]
	var hint_label = Label.new()
	hint_label.text = hint_text
	hint_label.position = Vector2(10, indicator.size.y - 30)
	hint_label.add_theme_color_override("font_color", Color.YELLOW)
	hint_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint_label.add_theme_constant_override("shadow_offset_x", 1)
	hint_label.add_theme_constant_override("shadow_offset_y", 1)
	hint_label.add_theme_font_size_override("font_size", 14)
	
	indicator.add_child(hint_label)
	
	# Remove hint after duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): hint_label.queue_free())
	add_child(timer)
	timer.start()

# Debug methods

func debug_zones():
	"""Print debug information about touch zones"""
	print("=== TOUCH ZONE DEBUG ===")
	print("Zones visible: ", show_zones)
	print("Zone opacity: ", zone_opacity)
	print("Active feedback effects: ", feedback_effects.size())
	for zone_type in zone_indicators.keys():
		print("Zone ", get_zone_label(zone_type), ": ", zone_areas[zone_type])
	print("========================")