extends Node

## Haptic Feedback Controller for Android devices
## Manages device vibration patterns and intensity

@export var haptic_enabled: bool = true
@export var master_intensity: float = 1.0

# Haptic patterns for different game events
enum HapticPattern {
	LIGHT_TAP,      # Quick tap feedback
	MEDIUM_BUMP,    # Lane switch, button press
	HEAVY_IMPACT,   # Collision, damage taken
	SUCCESS_PULSE,  # Achievement, level up
	WARNING_BUZZ,   # Low health, danger
	ABILITY_CHARGE  # Ability activation
}

# Pattern definitions (intensity, duration in seconds)
var haptic_patterns = {
	HapticPattern.LIGHT_TAP: {"intensity": 0.2, "duration": 0.05},
	HapticPattern.MEDIUM_BUMP: {"intensity": 0.4, "duration": 0.1},
	HapticPattern.HEAVY_IMPACT: {"intensity": 0.8, "duration": 0.2},
	HapticPattern.SUCCESS_PULSE: {"intensity": 0.6, "duration": 0.15},
	HapticPattern.WARNING_BUZZ: {"intensity": 0.5, "duration": 0.3},
	HapticPattern.ABILITY_CHARGE: {"intensity": 0.7, "duration": 0.25}
}

func _ready():
	# Check if device supports haptic feedback
	if not OS.has_feature("mobile"):
		haptic_enabled = false
		print("Haptic feedback disabled - not on mobile platform")
	else:
		print("Haptic feedback system initialized")

func play_haptic_pattern(pattern: HapticPattern):
	if not haptic_enabled:
		return
	
	var pattern_data = haptic_patterns.get(pattern, haptic_patterns[HapticPattern.LIGHT_TAP])
	var intensity = pattern_data["intensity"] * master_intensity
	var duration = pattern_data["duration"]
	
	trigger_vibration(intensity, duration)

func trigger_vibration(intensity: float, duration: float):
	if not haptic_enabled or not OS.has_feature("mobile"):
		return
	
	# Clamp values to safe ranges
	intensity = clamp(intensity, 0.0, 1.0)
	duration = clamp(duration, 0.01, 1.0)
	
	# Convert duration to milliseconds for Android
	var duration_ms = int(duration * 1000)
	
	if OS.get_name() == "Android":
		Input.vibrate_handheld(duration_ms)
	
	# For debugging on desktop
	if OS.get_name() in ["Windows", "Linux", "macOS"]:
		print("Haptic feedback: intensity=", intensity, " duration=", duration, "s")

func play_custom_vibration(intensity: float, duration: float):
	trigger_vibration(intensity, duration)

func set_haptic_enabled(enabled: bool):
	haptic_enabled = enabled

func set_master_intensity(intensity: float):
	master_intensity = clamp(intensity, 0.0, 1.0)

func get_haptic_enabled() -> bool:
	return haptic_enabled

func get_master_intensity() -> float:
	return master_intensity

# Convenience methods for common game events
func on_lane_switch():
	play_haptic_pattern(HapticPattern.MEDIUM_BUMP)

func on_jump():
	play_haptic_pattern(HapticPattern.LIGHT_TAP)

func on_collision():
	play_haptic_pattern(HapticPattern.HEAVY_IMPACT)

func on_ability_use():
	play_haptic_pattern(HapticPattern.ABILITY_CHARGE)

func on_level_up():
	play_haptic_pattern(HapticPattern.SUCCESS_PULSE)

func on_low_health():
	play_haptic_pattern(HapticPattern.WARNING_BUZZ)