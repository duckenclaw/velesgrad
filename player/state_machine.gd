extends Node
class_name StateMachine

## StateMachine handles the state transitions between the player states

@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	# Collect all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = get_parent()
			child.state_machine = self

	# Enter initial state
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.process_input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.process_frame(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.process_physics(delta)


func transition_to(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())

	if not new_state:
		push_error("State '%s' not found" % state_name)
		return

	if current_state == new_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()


func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
