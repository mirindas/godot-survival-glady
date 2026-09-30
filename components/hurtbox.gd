class_name Hurtbox
extends Area2D
## Receives melee hits and forwards them to a HealthComponent.
## Layer is "what I am"; the attacker's hitbox mask is what finds this.

signal hit_received(from_position: Vector2)

@export var health: HealthComponent
@export var armor: ArmorComponent


## Returns the damage actually applied after armor. 0 means the hit did not land.
## armor_reduction is stripped from the pool before this hit is mitigated.
func receive_hit(amount: int, from_position: Vector2, armor_reduction: int = 0) -> int:
	if health == null:
		push_error("Hurtbox '%s' has no HealthComponent." % name)
		return 0
	if health.current_health <= 0 or amount <= 0:
		return 0
	if armor != null and armor_reduction > 0:
		armor.reduce(armor_reduction)
	var applied := amount
	if armor != null:
		applied = armor.mitigate(amount)
	health.take_damage(applied)
	hit_received.emit(from_position)
	return applied
