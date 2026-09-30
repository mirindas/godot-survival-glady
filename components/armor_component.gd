class_name ArmorComponent
extends Node
## Damage reduction for one actor. Caps at max_armor.
## Uses the League of Legends curve: taken = raw * 100 / (100 + armor).
## A hit can also strip a flat amount first, the way armor reduction does there.
## Each point adds 1% effective health. 50 armor blocks about one third of a hit.

signal armor_changed(current: int, maximum: int)

@export_range(1, 500) var max_armor: int = 50

var current_armor: int:
	get:
		return _current

var _current := 0


func gain(amount: int) -> void:
	if amount <= 0 or _current >= max_armor:
		return
	_current = mini(_current + amount, max_armor)
	armor_changed.emit(_current, max_armor)


func reduce(amount: int) -> void:
	if amount <= 0 or _current <= 0:
		return
	_current = maxi(_current - amount, 0)
	armor_changed.emit(_current, max_armor)


func mitigate(raw: int) -> int:
	if raw <= 0:
		return 0
	if _current <= 0:
		return raw
	var taken := roundi(float(raw) * 100.0 / (100.0 + float(_current)))
	return maxi(taken, 1)
