extends Node3D
class_name CameraPivot

## Camera handles camera movement, rotation, and tilting

@onready var camera: Camera3D = $Camera3D

var config: PlayerConfig
var rotation_x: float = 0.0
var tilt_target: float = 0.0
var current_tilt: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	if not config:
		return

	# Smooth tilt interpolation
	current_tilt = lerp(current_tilt, tilt_target, config.tilt_speed * delta)
	camera.rotation.z = deg_to_rad(current_tilt)


func rotate_camera(mouse_delta: Vector2) -> void:
	if not config:
		return

	# Rotate the pivot horizontally
	rotate_y(-mouse_delta.x * config.mouse_sensitivity)

	# Rotate vertically (with clamping)
	rotation_x -= mouse_delta.y * config.mouse_sensitivity
	rotation_x = clamp(rotation_x, -PI/2, PI/2)
	rotation.x = rotation_x


func handle_tilt_input(tilt_left: bool, tilt_right: bool) -> void:
	if not config:
		return

	if tilt_left:
		tilt_target = config.tilt_angle
	elif tilt_right:
		tilt_target = -config.tilt_angle
	else:
		tilt_target = 0.0


func set_config(new_config: PlayerConfig) -> void:
	config = new_config
