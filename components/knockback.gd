class_name Knockback
extends Node
## Short push shared by any body that owns its own velocity.
## The body asks for the velocity each physics frame; this node does not move it.

@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var speed: float = 340.0
@export_range(0.0, 1.0, 0.01, "suffix:s") var duration: float = 0.12

var _time_left := 0.0
var _direction := Vector2.RIGHT


func is_active() -> bool:
	return _time_left > 0.0


func apply(from_position: Vector2, body_position: Vector2, fallback_direction: Vector2) -> void:
	var away := body_position - from_position
	if away.length_squared() < 1.0:
		away = fallback_direction
	if away.length_squared() < 0.001:
		away = Vector2.RIGHT
	_direction = away.normalized()
	_time_left = duration


func consume(delta: float) -> Vector2:
	if _time_left <= 0.0:
		return Vector2.ZERO
	_time_left = maxf(_time_left - delta, 0.0)
	return _direction * speed
