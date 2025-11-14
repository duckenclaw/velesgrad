extends Node
class_name State

## Base class for all player states

var player: CharacterBody3D
var state_machine: Node


func enter() -> void:
	pass


func exit() -> void:
	pass


func process_input(_event: InputEvent) -> void:
	pass


func process_frame(_delta: float) -> void:
	pass


func process_physics(_delta: float) -> void:
	pass
