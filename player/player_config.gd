extends Resource
class_name PlayerConfig

## PlayerConfig stores all of the player settings such as movement speed,
## jump force, camera sensitivity, etc.

@export_group("Movement")
@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 1.5
@export var crouch_multiplier: float = 0.5
@export var acceleration: float = 50.0
@export var deceleration: float = 50.0
@export var air_acceleration: float = 8.0

@export_group("Jumping")
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var tilt_angle: float = 5.0
@export var tilt_speed: float = 10.0

@export_group("Input Buffer")
@export var buffer_time: float = 0.3
@export var motion_detection_threshold: float = 0.5
