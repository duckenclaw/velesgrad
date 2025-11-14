extends Node3D
class_name Hand

## Hand handles item picking and attacking through the currently equipped item
## Also handles magic charging and casting

signal attack_performed(hand_name: String)
signal magic_charge_started(hand_name: String)
signal magic_released(hand_name: String)

@export var hand_name: String = "hand"

var equipped_item: Node3D = null
var is_attacking: bool = false
var is_charging_magic: bool = false


func attack() -> void:
	if is_attacking or is_charging_magic:
		return

	is_attacking = true

	if equipped_item and equipped_item.has_method("use"):
		equipped_item.use()

	attack_performed.emit(hand_name)

	# Simple attack cooldown
	await get_tree().create_timer(0.5).timeout
	is_attacking = false


## Start charging magic if equipped item is Magic
func start_magic_charge() -> void:
	if is_attacking or is_charging_magic:
		return

	if equipped_item and equipped_item is Magic:
		is_charging_magic = true
		equipped_item.start_charge()
		magic_charge_started.emit(hand_name)


## Release magic cast with combo information
func release_magic_cast(combo_type: String) -> void:
	if not is_charging_magic:
		return
	
	is_charging_magic = false

	if equipped_item and equipped_item is Magic:
		equipped_item.release_charge(combo_type)
		magic_released.emit(hand_name)


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
