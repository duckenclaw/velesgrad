extends Magic
class_name FireMagic

## Fire magic with 5 different spells based on combo inputs

const FIRE_DAMAGE = 10
const BURNING_DAMAGE = 5
const BURNING_DURATION = 5.0
const BLAST_IMPULSE = 10.0
const SUPERNOVA_DAMAGE = 15
const SUPERNOVA_IMPULSE = 15.0
const PHOENIX_DASH_DISTANCE = 5.0

var fire_effect_scene: PackedScene


func _ready() -> void:
	super._ready()
	# Load fire effect scene
	fire_effect_scene = preload("res://magic/fire_effect.tscn")
	mana_cost = 10


func cast_spell(combo_type: String) -> void:
	match combo_type:
		"neutral":
			print("casting ignite")
			cast_ignite()
		"forward":
			print("casting blast")
			cast_blast()
		"backward":
			print("casting firewall")
			cast_firewall()
		"circle":
			print("casting supernova")
			cast_supernova()
		"back_forth":
			print("casting phoenix")
			cast_phoenix()
		_:
			# Default to ignite if no combo detected
			cast_ignite()

	spell_cast.emit(combo_type)


## ⊙ Neutral: Ignite - apply burning to target in sight
func cast_ignite() -> void:

	var target = player.interact_ray_cast.get_collider()
	if target and target.is_in_group("enemy"):
		if target.has_method("take_damage"):
			target.take_damage(FIRE_DAMAGE, "Fire")
		if target.has_method("apply_status_effect"):
			target.apply_status_effect("Burning", BURNING_DAMAGE, BURNING_DURATION)

		# Spawn fire effect at target
		_spawn_fire_effect(target.global_position)
		print("Cast Ignite on ", target.name)


## ↑ Forward: Blast - AoE damage in front, knockback player and enemies
func cast_blast() -> void:

	# Create blast area in front of player
	var blast_position = player.global_position + player.camera_pivot.global_transform.basis.z * -2.0
	var blast_size = Vector3(3, 2, 2)

	# Get all bodies in blast area
	var space_state = player.get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = blast_size

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), blast_position)
	params.collision_mask = 1  # Adjust based on your collision layers

	var results = space_state.intersect_shape(params)

	# Apply damage and knockback to enemies
	for result in results:
		var body = result.collider
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(FIRE_DAMAGE, "Fire")
			if body.has_method("apply_status_effect"):
				body.apply_status_effect("Burning", BURNING_DAMAGE, BURNING_DURATION)

			# Apply impulse to enemy
			if body is RigidBody3D:
				var direction = (body.global_position - player.global_position).normalized()
				body.apply_central_impulse(direction * BLAST_IMPULSE)
			elif body is CharacterBody3D:
				print("APPLYING IMPULSE")
				var direction = (body.global_position - player.global_position).normalized()
				body.velocity += direction * BLAST_IMPULSE

	# Apply backward impulse to player
	var backward_direction = player.camera_pivot.global_transform.basis.z
	player.velocity += backward_direction * BLAST_IMPULSE * 0.5

	# Spawn fire effect
	_spawn_fire_effect(blast_position)
	print("Cast Blast")


## ↓ Backward: Firewall - create damaging area at raycast hit point
func cast_firewall() -> void:

	# Extend raycast temporarily
	var original_target = player.interact_ray_cast.target_position
	player.interact_ray_cast.target_position = Vector3(0, 0, -10.0)
	player.interact_ray_cast.force_raycast_update()

	if player.interact_ray_cast.is_colliding():
		var hit_position = player.interact_ray_cast.get_collision_point()

		# Create firewall node
		var firewall = Area3D.new()
		firewall.position = hit_position
		player.get_tree().root.add_child(firewall)

		# Add collision shape
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(3, 3, 1)
		collision.shape = shape
		firewall.add_child(collision)

		# Add fire effect
		var fire_particles = fire_effect_scene.instantiate()
		fire_particles.amount = 100
		fire_particles.lifetime = 2.0
		firewall.add_child(fire_particles)
		fire_particles.emitting = true

		# Connect body entered signal
		firewall.body_entered.connect(func(body):
			if body.is_in_group("enemy"):
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("Burning", BURNING_DAMAGE, BURNING_DURATION)
		)

		# Remove firewall after duration
		await player.get_tree().create_timer(BURNING_DURATION).timeout
		firewall.queue_free()

		print("Cast Firewall at ", hit_position)

	# Restore original raycast target
	player.interact_ray_cast.target_position = original_target


## ↻ Circle: Supernova - expanding sphere AoE
func cast_supernova() -> void:

	var supernova_radius = 5.0
	var expansion_time = 1.0

	# Create expanding sphere
	var supernova = Area3D.new()
	supernova.global_position = player.global_position
	player.get_tree().root.add_child(supernova)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape
	supernova.add_child(collision)

	# Add fire effect
	var fire_particles = fire_effect_scene.instantiate()
	fire_particles.amount = 200
	fire_particles.spread = 180.0
	supernova.add_child(fire_particles)
	fire_particles.emitting = true

	var damaged_bodies = []

	# Connect body entered signal
	supernova.body_entered.connect(func(body):
		if body.is_in_group("enemy") and body not in damaged_bodies:
			damaged_bodies.append(body)
			if body.has_method("take_damage"):
				body.take_damage(SUPERNOVA_DAMAGE, "Fire")

			# Apply impulse
			var direction = (body.global_position - player.global_position).normalized()
			if body is RigidBody3D:
				body.apply_central_impulse(direction * SUPERNOVA_IMPULSE)
			elif body is CharacterBody3D:
				body.velocity += direction * SUPERNOVA_IMPULSE
	)

	# Expand the sphere
	var tween = player.get_tree().create_tween()
	tween.tween_property(shape, "radius", supernova_radius, expansion_time)

	await tween.finished
	await player.get_tree().create_timer(0.5).timeout
	supernova.queue_free()

	print("Cast Supernova")


## ⇅ Back and forth: Phoenix - dash forward leaving damaging trail
func cast_phoenix() -> void:

	var dash_direction = -player.camera_pivot.global_transform.basis.z
#	dash_direction.y = 0  # Keep on horizontal plane
	dash_direction = dash_direction.normalized()

	var start_position = player.global_position
	var end_position = start_position + dash_direction * PHOENIX_DASH_DISTANCE

	# Apply dash impulse to player
	player.velocity = dash_direction * 20.0  # Fast dash

	# Create damage trail
	var trail = Area3D.new()
	trail.global_position = start_position
	player.get_tree().root.add_child(trail)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 2, PHOENIX_DASH_DISTANCE)
	collision.shape = shape
	trail.add_child(collision)

	# Rotate trail to match dash direction
	trail.look_at(end_position, Vector3.UP)

	# Add fire effect along trail
	var fire_particles = fire_effect_scene.instantiate()
	fire_particles.amount = 150
	fire_particles.lifetime = 1.0
	trail.add_child(fire_particles)
	fire_particles.emitting = true

	var damaged_bodies = []

	# Connect body entered signal
	trail.body_entered.connect(func(body):
		if body.is_in_group("enemy") and body not in damaged_bodies:
			damaged_bodies.append(body)
			if body.has_method("take_damage"):
				body.take_damage(FIRE_DAMAGE, "Fire")

			# Apply impulse away from trail
			var direction = (body.global_position - trail.global_position).normalized()
			if body is RigidBody3D:
				body.apply_central_impulse(direction * BLAST_IMPULSE)
			elif body is CharacterBody3D:
				body.velocity += direction * BLAST_IMPULSE
	)

	# Remove trail after duration
	await player.get_tree().create_timer(1.0).timeout
	trail.queue_free()

	print("Cast Phoenix")


func _spawn_fire_effect(position: Vector3) -> void:

	var effect = fire_effect_scene.instantiate()
	player.get_tree().root.add_child(effect)
	effect.global_position = position
	effect.emitting = true

	# Remove after lifetime
	await player.get_tree().create_timer(effect.lifetime + 1.0).timeout
	effect.queue_free()


func on_charge_start() -> void:
	# Could add visual charging effect here
	pass
