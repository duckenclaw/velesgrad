extends Node3D
class_name Hand

## Hand handles item picking and attacking through the currently equipped item

signal attack_performed(hand_name: String)

@export var hand_name: String = "hand"

var equipped_item: Node3D = null
var is_attacking: bool = false


func attack() -> void:
	if is_attacking:
		return

	is_attacking = true

	if equipped_item and equipped_item.has_method("use"):
		equipped_item.use()

	attack_performed.emit(hand_name)

	# Simple attack cooldown
	await get_tree().create_timer(0.5).timeout
	is_attacking = false


func equip_item(item: Node3D) -> void:
	if equipped_item:
		unequip_item()

	equipped_item = item
	add_child(item)
	item.position = Vector3.ZERO


func unequip_item() -> void:
	if equipped_item:
		remove_child(equipped_item)
		equipped_item = null


func has_item() -> bool:
	return equipped_item != null
