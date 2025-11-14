extends State
class_name FallingState

## FallingState handles falling behavior and air control while descending


func enter() -> void:
	pass


func process_physics(delta: float) -> void:
	if not player:
		return

	# Check if landed
	if player.is_on_floor():
		# Transition based on movement input
		var input_dir = Input.get_vector("left", "right", "backward", "forward")
		if input_dir.length() > 0.1:
			state_machine.transition_to("MovingState")
		else:
			state_machine.transition_to("IdleState")
		return

	# Apply gravity
	player.velocity.y -= player.config.gravity * delta

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
