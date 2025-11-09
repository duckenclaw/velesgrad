extends CharacterBody3D
class_name Player

## Player is the main controller for the player
## Handles all inputs and utilizes the StateMachine to transition between states

@export var config: PlayerConfig

@onready var camera_pivot: CameraPivot = $CameraPivot
@onready var hands: Hands = $CameraPivot/Hands
@onready var state_machine: StateMachine = $StateMachine
@onready var input_buffer: InputBuffer = $InputBuffer


func _ready() -> void:
	# Create default config if none assigned
	if not config:
		config = PlayerConfig.new()

	# Set config for subsystems
	if camera_pivot:
		camera_pivot.set_config(config)

	if input_buffer:
		input_buffer.set_config(config)
		input_buffer.combo_detected.connect(_on_combo_detected)


func _input(event: InputEvent) -> void:
	# Handle mouse motion for camera
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_camera(event.relative)

	# Toggle mouse capture with ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	# Update input buffer for combo detection
	if input_buffer:
		input_buffer.update(delta)

	# Handle camera tilt input
	var tilt_left = Input.is_action_pressed("tilt_left")
	var tilt_right = Input.is_action_pressed("tilt_right")
	if camera_pivot:
		camera_pivot.handle_tilt_input(tilt_left, tilt_right)

	# Handle hand attacks
	if Input.is_action_just_pressed("left_hand") and hands:
		hands.attack_with_left_hand()

	if Input.is_action_just_pressed("right_hand") and hands:
		hands.attack_with_right_hand()

	# Handle activate action (for interactions)
	if Input.is_action_just_pressed("activate"):
		_handle_activate()


func _handle_activate() -> void:
	# Placeholder for activation/interaction logic
	pass


func _on_combo_detected(combo_type: String) -> void:
	# Handle detected combos
	print("Combo detected: ", combo_type)
	# You can trigger special moves or attacks based on combo type
