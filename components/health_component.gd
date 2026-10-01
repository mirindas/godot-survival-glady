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
var _base_max: int


func _ready() -> void:
	_base_max = max_health
	_current = max_health


## Raises max health from the starting value. Current health gains the new points.
func apply_bonus_percent(percent: int) -> void:
	var bonus := maxi(percent, 0)
	var next_max := maxi(roundi(float(_base_max) * (1.0 + float(bonus) / 100.0)), 1)
	if next_max == max_health:
		return
	var gained := next_max - max_health
	max_health = next_max
	if _current > 0:
		_current = clampi(_current + gained, 1, max_health)
	health_changed.emit(_current, max_health)


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
