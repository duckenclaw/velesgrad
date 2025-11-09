extends State
class_name JumpingState

## JumpingState handles the jumping behavior and air control


func enter() -> void:
	if player and player.is_on_floor():
		player.velocity.y = player.config.jump_velocity


func process_physics(delta: float) -> void:
	if not player:
		return

	# Apply gravity
	player.velocity.y -= player.config.gravity * delta

	# Transition to falling when moving downward
	if player.velocity.y <= 0:
		state_machine.transition_to("FallingState")
		return

	# Air control
	var input_dir = Input.get_vector("left", "right", "backward", "forward")

	if input_dir.length() > 0.1:
		# Get the camera's forward and right directions
		var camera_basis = player.camera_pivot.global_transform.basis
		var forward = -camera_basis.z
		var right = camera_basis.x

		# Project onto horizontal plane
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		# Calculate movement direction (fixed: removed negative sign from input_dir.y)
		var direction = (forward * input_dir.y + right * input_dir.x).normalized()

		# Apply air control with reduced acceleration for controllable air movement
		var target_velocity = direction * player.config.move_speed
		player.velocity.x = move_toward(
			player.velocity.x,
			target_velocity.x,
			player.config.air_acceleration * delta
		)
		player.velocity.z = move_toward(
			player.velocity.z,
			target_velocity.z,
			player.config.air_acceleration * delta
		)

	player.move_and_slide()
