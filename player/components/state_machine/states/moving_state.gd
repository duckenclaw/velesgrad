extends State
class_name MovingState

## MovingState handles regular movement, sprint handling (only when moving forward),
## and crouch movement


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

	# Get input direction
	var input_dir = Input.get_vector("left", "right", "backward", "forward")

	# Check for idle transition
	if input_dir.length() < 0.1:
		state_machine.transition_to("IdleState")
		return

	# Check for jump input (can't jump while crouching)
	if Input.is_action_just_pressed("jump") and not player.is_crouching:
		state_machine.transition_to("JumpingState")
		return

	# Calculate movement speed based on modifiers
	var speed = player.config.move_speed

	# Sprint only when moving forward
	var is_sprinting = Input.is_action_pressed("sprint") and input_dir.y > 0.5
	if is_sprinting:
		speed *= player.config.sprint_multiplier

	# Crouch movement
	var is_crouching = Input.is_action_pressed("crouch")
	if is_crouching:
		speed *= player.config.crouch_multiplier

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

	# Calculate target velocity
	var target_velocity = direction * speed

	# Accelerate towards target velocity with high acceleration for snappy movement
	player.velocity.x = move_toward(
		player.velocity.x,
		target_velocity.x,
		player.config.acceleration * delta
	)
	player.velocity.z = move_toward(
		player.velocity.z,
		target_velocity.z,
		player.config.acceleration * delta
	)

	player.move_and_slide()
