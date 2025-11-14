extends Control

@onready var health_bar: ProgressBar = $StatusContainer/HealthBar
@onready var health_value_label: Label = $StatusContainer/HealthBar/HealthValue

@onready var mana_bar: ProgressBar = $StatusContainer/ManaBar
@onready var mana_value_label: Label = $StatusContainer/ManaBar/ManaValue


func _on_status_changed(current_health: int, max_health: int, current_mana: int, max_mana: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_value_label.text = str(current_health)
	
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
	mana_value_label.text = str(current_mana)
