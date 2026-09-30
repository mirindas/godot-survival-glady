class_name Hurtbox
extends Area2D
## Receives melee hits and forwards them to a HealthComponent.
## Layer is "what I am"; the attacker's hitbox mask is what finds this.

@export var health: HealthComponent


func receive_hit(amount: int) -> void:
	if health == null:
		push_error("Hurtbox '%s' has no HealthComponent." % name)
		return
	health.take_damage(amount)
