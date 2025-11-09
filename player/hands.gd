extends Node3D
class_name Hands

## Hands manages both left and right Hand nodes

@onready var right_hand: Hand = $RightHand
@onready var left_hand: Hand = $LeftHand


func _ready() -> void:
	if right_hand:
		right_hand.attack_performed.connect(_on_attack_performed)
	if left_hand:
		left_hand.attack_performed.connect(_on_attack_performed)


func attack_with_right_hand() -> void:
	if right_hand:
		right_hand.attack()


func attack_with_left_hand() -> void:
	if left_hand:
		left_hand.attack()


func _on_attack_performed(hand_name: String) -> void:
	# Handle combo system or attack effects here
	pass
