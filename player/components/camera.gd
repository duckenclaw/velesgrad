extends Node3D
class_name CameraPivot

## Camera handles camera movement, rotation, and tilting

@onready var camera: Camera3D = $Camera3D

var config: PlayerConfig
var rotation_x: float = 0.0
var tilt_target: float = 0.0
var current_tilt: float = 0.0
var tilt_offset_target: float = 0.0
var current_tilt_offset: float = 0.0
var initial_camera_position: Vector3


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Store the initial camera position
	initial_camera_position = camera.position


func _process(delta: float) -> void:
	if not config:
		return

	# Smooth tilt interpolation for both rotation and position
	current_tilt = lerp(current_tilt, tilt_target, config.tilt_speed * delta)
	current_tilt_offset = lerp(current_tilt_offset, tilt_offset_target, config.tilt_speed * delta)

	# Apply tilt rotation
	camera.rotation.z = deg_to_rad(current_tilt)

	# Apply lateral position offset (left is positive X in local space)
	camera.position.x = initial_camera_position.x + current_tilt_offset


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
		tilt_offset_target = config.tilt_offset  # Move camera left
	elif tilt_right:
		tilt_target = -config.tilt_angle
		tilt_offset_target = -config.tilt_offset  # Move camera right
	else:
		tilt_target = 0.0
		tilt_offset_target = 0.0  # Return to center


func set_config(new_config: PlayerConfig) -> void:
	config = new_config
