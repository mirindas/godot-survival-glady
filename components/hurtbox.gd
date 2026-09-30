class_name Hurtbox
extends Area2D
## Receives melee hits and forwards them to a HealthComponent.
## Layer is "what I am"; the attacker's hitbox mask is what finds this.

signal hit_received(from_position: Vector2)

@export var health: HealthComponent


func receive_hit(amount: int, from_position: Vector2) -> bool:
	if health == null:
		push_error("Hurtbox '%s' has no HealthComponent." % name)
		return false
	if health.current_health <= 0:
		return false
	health.take_damage(amount)
	hit_received.emit(from_position)
	return true
