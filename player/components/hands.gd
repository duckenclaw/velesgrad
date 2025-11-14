extends Node3D
class_name Hands

## Hands manages both left and right Hand nodes

@onready var right_hand: Hand = $RightHand
@onready var left_hand: Hand = $LeftHand


func _ready() -> void:
	if right_hand:
		right_hand.attack_performed.connect(_on_attack_performed)
		right_hand.magic_charge_started.connect(_on_magic_charge_started)
		right_hand.magic_released.connect(_on_magic_released)
	if left_hand:
		left_hand.attack_performed.connect(_on_attack_performed)
		left_hand.magic_charge_started.connect(_on_magic_charge_started)
		left_hand.magic_released.connect(_on_magic_released)


func attack_with_right_hand() -> void:
	if right_hand:
		right_hand.attack()


func attack_with_left_hand() -> void:
	if left_hand:
		left_hand.attack()


func start_charge_right_hand() -> void:
	if right_hand:
		right_hand.start_magic_charge()


func start_charge_left_hand() -> void:
	if left_hand:
		left_hand.start_magic_charge()


func release_right_hand(combo_type: String) -> void:
	if right_hand:
		right_hand.release_magic_cast(combo_type)


func release_left_hand(combo_type: String) -> void:
	if left_hand:
		left_hand.release_magic_cast(combo_type)


func equip_to_right_hand(item: Node3D) -> void:
	if right_hand:
		right_hand.equip_item(item)


func equip_to_left_hand(item: Node3D) -> void:
	if left_hand:
		left_hand.equip_item(item)


func _on_attack_performed(hand_name: String) -> void:
	# Handle combo system or attack effects here
	pass


func _on_magic_charge_started(hand_name: String) -> void:
	print("Magic charging in %s" % hand_name)


func _on_magic_released(hand_name: String) -> void:
	print("Magic released from %s" % hand_name)
