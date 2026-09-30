extends Node2D
## One room. Owns who is in the fight, the waves, and the restart.
## Wires the player's health to the HUD. The HUD does not search for the player.

const HIT_PAUSE_SCALE := 0.08
const HIT_PAUSE_REAL_SECONDS := 0.055
const FIRST_GRUNT_POSITION := Vector2(1000, 800)
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(220, 220),
	Vector2(1980, 220),
	Vector2(220, 1380),
	Vector2(1980, 1380),
	Vector2(1100, 180),
	Vector2(1100, 1420),
]

@export var grunt_scene: PackedScene
@export_range(1, 20) var max_alive: int = 8
@export_range(2.0, 20.0, 0.5, "suffix:s") var wave_interval: float = 8.0

@onready var _player: Player = %Player as Player
@onready var _hud: Hud = %Hud as Hud
@onready var _actors: Node2D = %Actors as Node2D

var _defeated := false
var _restarting := false
var _wave := 0
var _alive := 0
var _seconds_until_wave := 0.0
var _hit_pause_left := 0.0
var _spawn_cursor := 0


func _ready() -> void:
	Engine.time_scale = 1.0
	var health := _player.health
	if health == null:
		push_error("Arena player is missing HealthComponent.")
		return
	if grunt_scene == null:
		push_error("Arena is missing grunt_scene.")
		return
	health.health_changed.connect(_hud.set_health)
	health.died.connect(_on_player_died)
	_player.attack_landed.connect(_on_swing_landed)
	_player.simple_attack_started.connect(_hud.start_simple_clock)
	_player.simple_attack_ended.connect(_hud.end_simple_clock)
	_player.heavy_attack_started.connect(_hud.start_heavy_clock)
	_hud.set_health(health.current_health, health.max_health)
	_spawn_wave()
	_seconds_until_wave = _next_interval()


func _unhandled_input(event: InputEvent) -> void:
	if not _defeated or _restarting:
		return
	if not event.is_action_pressed(&"attack") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	_restarting = true
	Engine.time_scale = 1.0
	var error := get_tree().reload_current_scene()
	if error != OK:
		_restarting = false
		push_error("Arena failed to restart: %s" % error_string(error))


func _physics_process(delta: float) -> void:
	if _hit_pause_left > 0.0:
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_hit_pause_left -= real_delta
		if _hit_pause_left <= 0.0:
			Engine.time_scale = 1.0
			_hit_pause_left = 0.0
	if _defeated or _restarting:
		return
	_seconds_until_wave -= delta
	if _seconds_until_wave > 0.0:
		return
	_spawn_wave()
	_seconds_until_wave = _next_interval()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _on_player_died() -> void:
	_defeated = true
	_hud.show_defeated()


func _on_swing_landed() -> void:
	_player.shake_camera()
	Engine.time_scale = HIT_PAUSE_SCALE
	_hit_pause_left = HIT_PAUSE_REAL_SECONDS


func _spawn_wave() -> void:
	var room := max_alive - _alive
	if room <= 0:
		return
	_wave += 1
	var count := mini(_wave + 1, 4)
	count = mini(count, room)
	for _index: int in count:
		_spawn_grunt()
	_hud.set_wave(_wave)


func _spawn_grunt() -> void:
	var grunt := grunt_scene.instantiate() as Grunt
	if grunt == null:
		push_error("Arena grunt_scene is not a Grunt.")
		return
	grunt.position = _next_spawn_position()
	_spawn_cursor += 1
	_actors.add_child(grunt)
	grunt.setup(_player)
	grunt.attack_landed.connect(_on_swing_landed)
	grunt.tree_exited.connect(_on_grunt_exited)
	_alive += 1


func _on_grunt_exited() -> void:
	_alive = maxi(_alive - 1, 0)


func _next_spawn_position() -> Vector2:
	if _wave == 1 and _spawn_cursor == 0:
		return FIRST_GRUNT_POSITION
	return SPAWN_POINTS[_spawn_cursor % SPAWN_POINTS.size()]


func _next_interval() -> float:
	return maxf(wave_interval - float(_wave - 1) * 0.6, 4.0)
