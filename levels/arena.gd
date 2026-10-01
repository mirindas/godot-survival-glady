extends Node2D
## One room. Owns who is in the fight, the waves, and the restart.
## Wires the player's health to the HUD. The HUD does not search for the player.
## Every 5th wave spawns one boss. Killing it waits 10 seconds, then the next wave starts.
## Other waves wait 5 seconds, then spawn in batches inside a ring around the player.

const HIT_PAUSE_SCALE := 0.08
const HIT_PAUSE_REAL_SECONDS := 0.055
const SPAWN_MIN := Vector2(160, 160)
const SPAWN_MAX := Vector2(2040, 1440)
const SPAWN_ATTEMPTS := 8

@export var grunt_scene: PackedScene
@export var boss_scene: PackedScene
@export_range(1, 40) var first_wave_count: int = 5
@export_range(1.0, 3.0, 0.01) var wave_growth: float = 1.22
@export_group("Spawning")
@export_range(0.0, 30.0, 0.5, "suffix:s") var wave_spawn_delay: float = 5.0
@export_range(0.05, 2.0, 0.05, "suffix:s") var min_spawn_gap: float = 0.15
@export_range(0.05, 2.0, 0.05, "suffix:s") var max_spawn_gap: float = 0.4
@export_range(1.0, 40.0, 0.5, "suffix:widths") var spawn_min_radius: float = 5.0
@export_range(1.0, 40.0, 0.5, "suffix:widths") var spawn_max_radius: float = 15.0
@export_range(1, 20) var spawn_batch: int = 5
@export_range(1, 200) var max_active: int = 50
@export_range(1, 50) var boss_every_waves: int = 5
@export_range(0.0, 60.0, 0.5, "suffix:s") var boss_rest_seconds: float = 10.0

@onready var _player: Player = %Player as Player
@onready var _hud: Hud = %Hud as Hud
@onready var _actors: Node2D = %Actors as Node2D

var _defeated := false
var _restarting := false
var _wave := 0
var _grunt_quota := 0
var _wave_size := 0
var _kills := 0
var _active := 0
var _left_to_spawn := 0
var _spawn_wait := 0.0
var _boss_wave := false
var _rest_left := 0.0
var _rest_shown := -1
var _hit_pause_left := 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	var health := _player.health
	if health == null:
		push_error("Arena player is missing HealthComponent.")
		return
	if grunt_scene == null:
		push_error("Arena is missing grunt_scene.")
		return
	if boss_scene == null:
		push_error("Arena is missing boss_scene.")
		return
	health.health_changed.connect(_hud.set_health)
	health.died.connect(_on_player_died)
	if _player.armor == null:
		push_error("Arena player is missing ArmorComponent.")
		return
	_player.armor.armor_changed.connect(_hud.set_armor)
	if _player.stats == null:
		push_error("Arena player is missing StatsComponent.")
		return
	_player.stats.stats_changed.connect(_hud.set_stats)
	_player.attack_landed.connect(_on_swing_landed)
	_player.simple_attack_started.connect(_hud.start_simple_clock)
	_player.simple_attack_ended.connect(_hud.end_simple_clock)
	_player.heavy_attack_started.connect(_hud.start_heavy_clock)
	_hud.set_health(health.current_health, health.max_health)
	_hud.set_armor(_player.armor.current_armor, _player.armor.max_armor)
	_hud.set_stats(_player.stats.crit_chance, _player.stats.dodge_chance, _player.stats.speed)
	_begin_wave()


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
	if _rest_left > 0.0:
		_tick_rest(delta)
		return
	if _left_to_spawn <= 0:
		return
	_spawn_wait -= delta
	if _spawn_wait > 0.0:
		return
	_spawn_batch()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _on_player_died() -> void:
	_defeated = true
	_hud.show_defeated()


func _on_swing_landed() -> void:
	_player.shake_camera()
	Engine.time_scale = HIT_PAUSE_SCALE
	_hit_pause_left = HIT_PAUSE_REAL_SECONDS


func _begin_wave() -> void:
	_wave += 1
	_kills = 0
	_rest_left = 0.0
	_rest_shown = -1
	_boss_wave = _wave % boss_every_waves == 0
	if _boss_wave:
		_wave_size = 1
		_left_to_spawn = 1
	else:
		if _grunt_quota == 0:
			_grunt_quota = first_wave_count
		else:
			_grunt_quota = maxi(roundi(float(_grunt_quota) * wave_growth), _grunt_quota + 1)
		_wave_size = _grunt_quota
		_left_to_spawn = _wave_size
	_spawn_wait = _next_spawn_gap()
	_hud.set_wave(_wave, _boss_wave)
	_hud.show_wave_incoming(_wave, _boss_wave)


func _tick_rest(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_rest_left -= real_delta
	var seconds := ceili(_rest_left) if _rest_left > 0.0 else 0
	if seconds > 0 and seconds != _rest_shown:
		_rest_shown = seconds
		_hud.show_rest(seconds)
	if _rest_left > 0.0:
		return
	_rest_left = 0.0
	_begin_wave()


func _spawn_batch() -> void:
	var room := max_active - _active
	if room <= 0:
		_spawn_wait = _next_spawn_gap()
		return
	var count := mini(spawn_batch, mini(_left_to_spawn, room))
	if _boss_wave:
		count = mini(count, 1)
	var spawned := 0
	for _i in count:
		var ok := _spawn_boss() if _boss_wave else _spawn_grunt()
		if not ok:
			break
		spawned += 1
		_active += 1
		_left_to_spawn -= 1
	if spawned == 0:
		_spawn_wait = 0.25
		return
	if _left_to_spawn > 0:
		_spawn_wait = _next_spawn_gap()


func _next_spawn_gap() -> float:
	return randf_range(minf(min_spawn_gap, max_spawn_gap), maxf(min_spawn_gap, max_spawn_gap))


func _spawn_grunt() -> bool:
	var grunt := grunt_scene.instantiate() as Grunt
	if grunt == null:
		push_error("Arena grunt_scene is not a Grunt.")
		return false
	grunt.position = _random_spawn_position()
	_actors.add_child(grunt)
	grunt.setup(_player)
	grunt.attack_landed.connect(_on_swing_landed)
	grunt.tree_exited.connect(_on_enemy_exited)
	return true


func _spawn_boss() -> bool:
	var boss := boss_scene.instantiate() as Boss
	if boss == null:
		push_error("Arena boss_scene is not a Boss.")
		return false
	var margin := Vector2(Units.PLAYER_WIDTH, Units.PLAYER_HEIGHT) * Units.BOSS_SCALE * 0.5
	boss.prepare(maxi(_wave / boss_every_waves - 1, 0))
	boss.position = _random_spawn_position(margin)
	_actors.add_child(boss)
	boss.setup(_player)
	boss.attack_landed.connect(_on_swing_landed)
	boss.tree_exited.connect(_on_enemy_exited)
	return true


func _on_enemy_exited() -> void:
	if _defeated or _restarting or not is_inside_tree():
		return
	_active = maxi(_active - 1, 0)
	_kills += 1
	if _kills < _wave_size or _left_to_spawn > 0:
		return
	_start_rest(boss_rest_seconds if _boss_wave else wave_spawn_delay)


func _start_rest(seconds: float) -> void:
	if seconds <= 0.0:
		_begin_wave()
		return
	_rest_left = seconds
	_rest_shown = ceili(seconds)
	_hud.show_rest(_rest_shown)


func _random_spawn_position(margin: Vector2 = Vector2.ZERO) -> Vector2:
	var origin := _player.global_position
	var inner := Units.px(spawn_min_radius)
	var outer := Units.px(maxf(spawn_max_radius, spawn_min_radius))
	var bounds_min := SPAWN_MIN + margin
	var bounds_max := SPAWN_MAX - margin
	var point := origin
	for _attempt in SPAWN_ATTEMPTS:
		var angle := randf() * TAU
		var distance := sqrt(lerpf(inner * inner, outer * outer, randf()))
		point = (origin + Vector2.from_angle(angle) * distance).clamp(bounds_min, bounds_max)
		if point.distance_to(origin) >= inner:
			return point
	return point
