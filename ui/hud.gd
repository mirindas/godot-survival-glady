class_name Hud
extends CanvasLayer
## Reads health from whoever the level wires up. It does not find the player itself.

@onready var _health_label: Label = %HealthLabel


func set_health(current: int, maximum: int) -> void:
	_health_label.text = "HP %d / %d" % [current, maximum]


func show_defeated() -> void:
	_health_label.text = "Defeated"
