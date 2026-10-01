class_name Hud
extends CanvasLayer
## Reads health and attack timing from whoever the level wires up.
## It does not find the player itself.

var _banner_id := 0
var _rest_banner := false

@onready var _health_bar: HealthBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _armor_bar: ArmorBar = %ArmorBar
@onready var _armor_label: Label = %ArmorLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _wave_banner: Label = %WaveBanner
@onready var _hint_label: Label = %HintLabel
@onready var _defeated_label: Label = %DefeatedLabel
@onready var _simple_slot: AttackSlot = %SimpleAttack
@onready var _heavy_slot: AttackSlot = %HeavyAttack
@onready var _rend_slot: AttackSlot = %RendAttack


func set_health(current: int, maximum: int) -> void:
	_health_bar.set_fraction(current, maximum)
	var percent := 0
	if maximum > 0:
		percent = roundi(float(current) / float(maximum) * 100.0)
	_health_label.text = "%d / %d | %d%%" % [current, maximum, percent]


func set_armor(current: int, maximum: int) -> void:
	_armor_bar.set_fraction(current, maximum)
	_armor_label.text = "%d / %d" % [current, maximum]


func set_stats(crit: float, dodge: float, speed: float) -> void:
	_stats_label.text = "Crit %s   Dodge %s   Speed %s" % [
		_percent(crit, false),
		_percent(dodge, false),
		_percent(speed, true),
	]


func _percent(value: float, signed: bool) -> String:
	var number := "%0.1f" % value
	if number.ends_with(".0"):
		number = number.trim_suffix(".0")
	if signed and value > 0.0:
		number = "+" + number
	return number + "%"


func set_wave(wave: int, boss: bool = false) -> void:
	if boss:
		_wave_label.text = "Wave %d  Boss" % wave
	else:
		_wave_label.text = "Wave %d" % wave


func show_wave_incoming(wave: int, boss: bool = false) -> void:
	_rest_banner = false
	_banner_id += 1
	var id := _banner_id
	if boss:
		_wave_banner.text = "Boss incoming"
	else:
		_wave_banner.text = "Wave %d incoming" % wave
	_wave_banner.visible = true
	var timer := get_tree().create_timer(2.4)
	timer.timeout.connect(_hide_wave_banner.bind(id))


func show_rest(seconds: int) -> void:
	if not _rest_banner:
		_banner_id += 1
		_rest_banner = true
	_wave_banner.text = "Next wave in %d" % seconds
	_wave_banner.visible = true


func _hide_wave_banner(id: int) -> void:
	if id != _banner_id or not is_inside_tree():
		return
	_wave_banner.visible = false


func start_simple_clock(duration: float) -> void:
	_simple_slot.start_clock(duration)


func end_simple_clock() -> void:
	_simple_slot.end_clock()


func start_heavy_clock(duration: float) -> void:
	_heavy_slot.start_clock(duration)


func start_rend_clock(duration: float) -> void:
	_rend_slot.start_clock(duration)


func end_rend_clock() -> void:
	_rend_slot.end_clock()


func show_defeated() -> void:
	_defeated_label.visible = true
	_rest_banner = false
	_banner_id += 1
	_wave_banner.visible = false
	_hint_label.text = "Press attack to restart"
	end_simple_clock()
	_heavy_slot.end_clock()
	end_rend_clock()
