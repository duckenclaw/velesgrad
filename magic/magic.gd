extends Node3D
class_name Magic

## Base class for all magic types
## Handles charging, casting, and mana consumption

signal charge_started()
signal charge_released()
signal spell_cast(spell_name: String)

@export var mana_cost: int = 1
@export var charge_time: float = 0.0  # Minimum time to hold for cast

var is_charging: bool = false
var charge_timer: float = 0.0
var player: Player = null


func _ready() -> void:
	# Find player in the scene tree
	var current = get_parent()
	while current and not current is Player:
		current = current.get_parent()
	player = current


func _process(delta: float) -> void:
	if is_charging:
		charge_timer += delta


func start_charge() -> void:
	if not can_cast():
		return

	is_charging = true
	charge_timer = 0.0
	charge_started.emit()
	on_charge_start()


func release_charge(combo_type: String) -> void:
	if not is_charging:
		return

	if charge_timer < charge_time:
		is_charging = false
		return

	is_charging = false

	# Check mana
	if player and player.mana >= mana_cost:
		player.mana -= mana_cost
		player.status_changed.emit(player.health, player.MAX_HEALTH, player.mana, player.MAX_MANA)
		cast_spell(combo_type)
		charge_released.emit()
	else:
		on_insufficient_mana()


func can_cast() -> bool:
	return player and player.mana >= mana_cost


## Override in child classes
func cast_spell(combo_type: String) -> void:
	pass


## Override in child classes for visual feedback
func on_charge_start() -> void:
	pass


## Override in child classes
func on_insufficient_mana() -> void:
	print("Not enough mana!")
