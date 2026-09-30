class_name Hud
extends CanvasLayer
## Reads health from whoever the level wires up. It does not find the player itself.

@onready var _health_label: Label = %HealthLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _hint_label: Label = %HintLabel


func set_health(current: int, maximum: int) -> void:
	_health_label.text = "HP %d / %d" % [current, maximum]


func set_wave(wave: int) -> void:
	_wave_label.text = "Wave %d" % wave


func show_defeated() -> void:
	_health_label.text = "Defeated"
	_hint_label.text = "Press attack to restart"
