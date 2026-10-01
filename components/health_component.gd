class_name HealthComponent
extends Node
## Hit points for one actor. Shared by the player and enemies.
## Current health lives here; the resource-style max is the starting value.

signal health_changed(current: int, maximum: int)
signal died

@export_range(1, 1000000) var max_health: int = 100

var current_health: int:
	get:
		return _current

var _current: int


func _ready() -> void:
	_current = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or _current <= 0:
		return
	_current = maxi(_current - amount, 0)
	health_changed.emit(_current, max_health)
	if _current == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or _current <= 0 or _current >= max_health:
		return
	_current = mini(_current + amount, max_health)
	health_changed.emit(_current, max_health)
