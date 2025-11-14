extends State
class_name IdleState

## IdleState handles standing idle behavior


func enter() -> void:
	pass


func process_physics(delta: float) -> void:
	if not player:
		return

	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y -= player.config.gravity * delta
		state_machine.transition_to("FallingState")
		return

	# Check for movement input
	var input_dir = Input.get_vector("left", "right", "backward", "forward")
	if input_dir.length() > 0.1:
		state_machine.transition_to("MovingState")
		return

	# Check for jump input (can't jump while crouching)
	if Input.is_action_just_pressed("jump") and not player.is_crouching:
		state_machine.transition_to("JumpingState")
		return

	# Decelerate to stop with high deceleration for snappy stopping
	player.velocity.x = move_toward(player.velocity.x, 0, player.config.deceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.config.deceleration * delta)

	player.move_and_slide()
