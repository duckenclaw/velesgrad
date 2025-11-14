extends CharacterBody3D

const MAX_HEALTH: int = 100
@onready var health: int = MAX_HEALTH

@export var dialogue_timeline: DialogicTimeline

# Status effects tracking
var active_status_effects: Dictionary = {}  # effect_name: {damage: int, timer: Timer}

# Physics settings
var gravity: float = 9.8
var friction: float = 5.0  # Deceleration when not being pushed


func _ready() -> void:
	# Add to enemy group so spells can target this
	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Apply friction to horizontal movement
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	velocity.z = move_toward(velocity.z, 0, friction * delta)

	# Actually move the character based on velocity
	move_and_slide()


func take_damage(damage: int, damage_type: String) -> void:
	health -= damage
	print("%s takes %d %s damage! Health: %d/%d" % [name, damage, damage_type, health, MAX_HEALTH])

	if health <= 0:
		_on_death()


func apply_status_effect(effect_name: String, damage: int, duration: float) -> void:
	# Remove existing effect if present
	if effect_name in active_status_effects:
		remove_status_effect(effect_name)

	print("%s is afflicted with %s!" % [name, effect_name])

	# Create effect data
	var effect_data = {
		"damage": damage,
		"timer": Timer.new()
	}

	active_status_effects[effect_name] = effect_data

	# Setup timer for periodic damage
	var timer = effect_data.timer
	add_child(timer)
	timer.wait_time = 1.0  # Tick every second
	timer.timeout.connect(func(): _on_status_tick(effect_name))
	timer.start()

	# Setup removal timer
	await get_tree().create_timer(duration).timeout
	remove_status_effect(effect_name)


func remove_status_effect(effect_name: String) -> void:
	if effect_name not in active_status_effects:
		return

	var effect_data = active_status_effects[effect_name]
	effect_data.timer.queue_free()
	active_status_effects.erase(effect_name)
	print("%s is no longer afflicted with %s" % [name, effect_name])


func _on_status_tick(effect_name: String) -> void:
	if effect_name not in active_status_effects:
		return

	var effect_data = active_status_effects[effect_name]
	var damage_type = effect_name  # Use effect name as damage type (e.g., "Burning")
	take_damage(effect_data.damage, damage_type)


func _on_death() -> void:
	print("%s has been defeated!" % name)
	# You can add death animation, loot drops, etc. here
	# For now, just disable
	# queue_free()


func interact():
	return dialogue_timeline
