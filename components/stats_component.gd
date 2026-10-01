class_name StatsComponent
extends Node
## Crit and dodge are chances, never below zero. Speed is a percent change
## to movement: above zero is faster, below zero is slower.

signal stats_changed(crit: float, dodge: float, speed: float)

@export_range(0.0, 100.0, 0.1, "suffix:%") var crit_chance: float = 5.0:
	set(value):
		crit_chance = maxf(value, 0.0)
		_notify()

@export_range(0.0, 100.0, 0.1, "suffix:%") var dodge_chance: float = 5.0:
	set(value):
		dodge_chance = maxf(value, 0.0)
		_notify()

@export_range(-100.0, 300.0, 0.1, "suffix:%") var speed: float = 0.0:
	set(value):
		speed = value
		_notify()


func _ready() -> void:
	_notify()


func roll_crit() -> bool:
	return _roll(crit_chance)


func roll_dodge() -> bool:
	return _roll(dodge_chance)


## 0% leaves movement unchanged. The result never goes below zero.
func speed_scale() -> float:
	return maxf(1.0 + speed / 100.0, 0.0)


func _roll(chance: float) -> bool:
	if chance <= 0.0:
		return false
	return randf() * 100.0 < chance


func _notify() -> void:
	if not is_node_ready():
		return
	stats_changed.emit(crit_chance, dodge_chance, speed)
