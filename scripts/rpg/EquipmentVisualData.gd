class_name EquipmentVisualData
extends Resource

@export var model_scale: Vector3 = Vector3.ONE
@export var model_offset: Vector3 = Vector3.ZERO
@export var model_rotation: Vector3 = Vector3.ZERO
@export var attachment_point: String = ""  # Bone name for attachment
@export var material_overrides: Dictionary = {}
@export var particle_effects: Array[String] = []
@export var glow_color: Color = Color.TRANSPARENT
@export var glow_intensity: float = 0.0