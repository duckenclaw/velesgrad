extends CharacterBody3D
class_name Player

## Player is the main controller for the player
## Handles all inputs and utilizes the StateMachine to transition between states

const MAX_HEALTH: int = 100
@onready var health: int = MAX_HEALTH

const MAX_MANA: int = 200
@onready var mana: int = MAX_MANA

@export var config: PlayerConfig

@onready var camera_pivot: CameraPivot = $CameraPivot
@onready var hands: Hands = $CameraPivot/Hands
@onready var state_machine: StateMachine = $StateMachine
@onready var input_buffer: InputBuffer = $InputBuffer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interact_ray_cast: RayCast3D = $CameraPivot/Camera3D/InteractRayCast
@onready var ui: MarginContainer = $CanvasLayer/UI

var is_crouching: bool = false
var original_capsule_height: float
var original_camera_height: float
var crouch_transition_speed: float = 10.0

signal status_changed(current_health: int, max_health: int, current_mana: int, max_mana: int)

func _ready() -> void:
	# Create default config if none assigned
#	if not config:
#		config = PlayerConfig.new()

	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# Store original heights
	var capsule = collision_shape.shape as CapsuleShape3D
	original_capsule_height = capsule.height

	original_camera_height = camera_pivot.position.y
	camera_pivot.set_config(config)

	input_buffer.set_config(config)
	input_buffer.combo_detected.connect(_on_combo_detected)
	
	print("Health: " + str(health) + "/" + str(MAX_HEALTH))
	status_changed.emit(health, MAX_HEALTH, mana, MAX_MANA)


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

	# Handle crouching
	_handle_crouch(delta)

	# Handle camera tilt input
	var tilt_left = Input.is_action_pressed("tilt_left")
	var tilt_right = Input.is_action_pressed("tilt_right")
	if camera_pivot:
		camera_pivot.handle_tilt_input(tilt_left, tilt_right)

	# Handle magic charging/casting for hands
	if hands:
		# Right hand (mouse button 2)
		if Input.is_action_just_pressed("right_hand"):
			# Clear input buffer when starting to charge
			if input_buffer:
				input_buffer.clear_buffer()
				print("=== INPUT BUFFER CLEARED (RIGHT HAND CHARGE) ===")
			hands.start_charge_right_hand()
		elif Input.is_action_just_released("right_hand"):
			var combo = _get_current_combo()
			print(combo)
			hands.release_right_hand(combo)

		# Left hand (mouse button 1)
		if Input.is_action_just_pressed("left_hand"):
			# Clear input buffer when starting to charge
			if input_buffer:
				input_buffer.clear_buffer()
				print("=== INPUT BUFFER CLEARED (LEFT HAND CHARGE) ===")
			hands.start_charge_left_hand()
		elif Input.is_action_just_released("left_hand"):
			var combo = _get_current_combo()
			hands.release_left_hand(combo)

	# Handle activate action (for interactions)
	if Input.is_action_just_pressed("activate"):
		_handle_activate()

	# Handle equip fire magic
	if Input.is_action_just_pressed("first"):
		_equip_fire_magic()


func _handle_crouch(delta: float) -> void:
	# Check crouch input
	var crouch_pressed = Input.is_action_pressed("crouch")
	is_crouching = crouch_pressed

	if not collision_shape or not collision_shape.shape is CapsuleShape3D:
		return

	var capsule = collision_shape.shape as CapsuleShape3D

	# Calculate target heights
	var target_capsule_height = original_capsule_height / 2.0 if is_crouching else original_capsule_height
	var height_difference = original_capsule_height - target_capsule_height
	var target_camera_height = original_camera_height - height_difference

	# Smoothly interpolate capsule height
	capsule.height = lerp(capsule.height, target_capsule_height, crouch_transition_speed * delta)

	# Adjust collision shape position to keep bottom at ground level
	var target_collision_y = target_capsule_height / 2.0
	collision_shape.position.y = lerp(collision_shape.position.y, target_collision_y, crouch_transition_speed * delta)

	# Smoothly interpolate camera height
	if camera_pivot:
		camera_pivot.position.y = lerp(camera_pivot.position.y, target_camera_height, crouch_transition_speed * delta)


func _handle_activate() -> void:
	var interactable_object = interact_ray_cast.get_collider()
	print(interactable_object)
	if interactable_object and interactable_object.has_method("interact"):
		print("interacting")
		var timeline_name = interactable_object.interact()
		print(timeline_name)
		Dialogic.start(timeline_name)


func take_damage(damage: int, damage_type: String):
	health -= damage
	status_changed.emit(health, MAX_HEALTH, mana, MAX_MANA)


func _get_current_combo() -> String:
	# Debug: print recent motion history
	var history = input_buffer.get_recent_motion_history(10)
	print("\n=== COMBO CHECK ===")
	print("Motion history (last 10): ", history)

	# Check for complex combo patterns first (circle, back_forth)
	var detected_combo = input_buffer.get_last_detected_combo()
	if detected_combo != "":
		print("Complex combo detected: ", detected_combo.to_upper())
		return detected_combo

	# Check for simple directional inputs using the last held direction
	var latest_motion = input_buffer.get_latest_non_neutral_motion()
	print("Latest non-neutral motion: ", InputBuffer.MotionType.keys()[latest_motion])

	match latest_motion:
		input_buffer.MotionType.FORWARD:
			print("Combo detected: FORWARD")
			return "forward"
		input_buffer.MotionType.BACKWARD:
			print("Combo detected: BACKWARD")
			return "backward"
		_:
			print("Combo detected: NEUTRAL (no direction held)")
			return "neutral"


func _equip_fire_magic() -> void:

	# Create fire magic instance
	var fire_magic = preload("res://magic/fire_magic.gd").new()

	# Load and add fire effect as child
	var fire_effect = preload("res://magic/fire_effect.tscn").instantiate()
	fire_magic.add_child(fire_effect)
	fire_effect.emitting = false  # Don't emit until casting

	# Equip to right hand
	hands.equip_to_right_hand(fire_magic)

	print("Fire magic equipped to right hand!")


func _on_combo_detected(combo_type: String) -> void:
	# Handle detected combos
	print("Combo detected: ", combo_type)
	# You can trigger special moves or attacks based on combo type

func _on_dialogic_signal(argument: String):
	match argument: 
		"dialogue_ended":
			print("dialogue ended")
		_:
			print("argument not recognized")
	
