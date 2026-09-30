class_name Hud
extends CanvasLayer
## Reads health and attack timing from whoever the level wires up.
## It does not find the player itself.

@onready var _health_bar: HealthBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _armor_bar: ArmorBar = %ArmorBar
@onready var _armor_label: Label = %ArmorLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _hint_label: Label = %HintLabel
@onready var _defeated_label: Label = %DefeatedLabel
@onready var _simple_slot: AttackSlot = %SimpleAttack
@onready var _heavy_slot: AttackSlot = %HeavyAttack


func set_health(current: int, maximum: int) -> void:
	_health_bar.set_fraction(current, maximum)
	var percent := 0
	if maximum > 0:
		percent = roundi(float(current) / float(maximum) * 100.0)
	_health_label.text = "%d / %d | %d%%" % [current, maximum, percent]


func set_armor(current: int, maximum: int) -> void:
	_armor_bar.set_fraction(current, maximum)
	_armor_label.text = "%d / %d" % [current, maximum]


func set_wave(wave: int) -> void:
	_wave_label.text = "Wave %d" % wave


func start_simple_clock(duration: float) -> void:
	_simple_slot.start_clock(duration)


func end_simple_clock() -> void:
	_simple_slot.end_clock()


func start_heavy_clock(duration: float) -> void:
	_heavy_slot.start_clock(duration)


func show_defeated() -> void:
	_defeated_label.visible = true
	_hint_label.text = "Press attack to restart"
	end_simple_clock()
	_heavy_slot.end_clock()
