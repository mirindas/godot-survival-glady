class_name Player
extends CharacterBody2D
## Top-down fighter. Owns movement, both swings, and the camera shake.
## Simple attack hits 45° to either side of the cursor and does not stop movement.
## Heavy attack is a longer frontal swing that plants the body until it ends.
## Using it starts a cooldown that ignores further heavy presses.
## Each swing locks the cursor direction from the moment it starts.
## Health and hit detection live on child nodes.

signal attack_landed
signal simple_attack_started(duration: float)
signal simple_attack_ended
signal heavy_attack_started(duration: float)

enum State { IDLE, MOVE, SIMPLE_ATTACK, HEAVY_ATTACK, DEAD }

const BODY_COLOR := Color("4c7dff")
const SIMPLE_COLOR := Color("9eb6ff")
const HEAVY_COLOR := Color("ffb45a")
const SHAKE_TIME := 0.12
const SIMPLE_AIM_RADIUS_DEGREES := 45.0

@export_group("Movement")
@export_range(1.0, 20.0, 0.05, "suffix:widths/s") var move_speed: float = Units.PLAYER_MOVE_SPEED

@export_group("Simple attack")
@export var simple_durations: Array[float] = [0.32, 0.26, 0.4]
@export var simple_active_starts: Array[float] = [0.08, 0.05, 0.12]
@export var simple_active_ends: Array[float] = [0.18, 0.14, 0.26]

@export_group("Heavy attack")
@export_range(0.05, 1.5, 0.01, "suffix:s") var heavy_duration: float = 0.5
@export_range(0.0, 1.5, 0.01, "suffix:s") var heavy_active_start: float = 0.16
@export_range(0.05, 1.5, 0.01, "suffix:s") var heavy_active_end: float = 0.32
@export_range(0.0, 5.0, 0.05, "suffix:s") var heavy_cooldown: float = 1.5

@onready var health: HealthComponent = %HealthComponent as HealthComponent
@onready var armor: ArmorComponent = %ArmorComponent as ArmorComponent
@onready var _simple_hitbox: Hitbox = %SimpleHitbox as Hitbox
@onready var _heavy_hitbox: Hitbox = %HeavyHitbox as Hitbox
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _knockback: Knockback = $Knockback as Knockback
@onready var _camera: Camera2D = $Camera2D
@onready var _body_shape: CollisionShape2D = $BodyShape

var _state: State = State.IDLE
var _facing := Vector2.RIGHT
var _simple_requested := false
var _heavy_requested := false
var _combo_queued := false
var _combo_step := 0
var _heavy_cooldown := 0.0
var _shake_left := 0.0


func _ready() -> void:
	set_process(false)
	assert(not simple_durations.is_empty())
	assert(simple_active_starts.size() == simple_durations.size())
	assert(simple_active_ends.size() == simple_durations.size())
	for step: int in simple_durations.size():
		assert(simple_active_ends[step] > simple_active_starts[step])
		assert(simple_durations[step] >= simple_active_ends[step])
	assert(heavy_active_end > heavy_active_start)
	assert(heavy_duration >= heavy_active_end)
	_simple_hitbox.setup_arc(Units.measure(&"simple_arc_radius"), SIMPLE_AIM_RADIUS_DEGREES * 2.0)
	_heavy_hitbox.apply_rectangle(
		Units.measure(&"heavy_swing_width"),
		Units.measure(&"heavy_swing_height")
	)
	health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_simple_hitbox.hit_landed.connect(_on_attack_landed)
	_heavy_hitbox.hit_landed.connect(_on_attack_landed)
	_simple_hitbox.finished.connect(_on_swing_finished)
	_heavy_hitbox.finished.connect(_on_swing_finished)
	_apply_facing()


func shake_camera() -> void:
	_shake_left = SHAKE_TIME
	set_process(true)


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_shake_left -= real_delta
	if _shake_left <= 0.0:
		_camera.offset = Vector2.ZERO
		set_process(false)
		return
	var shake := Units.measure(&"shake_amount")
	_camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.DEAD or event.is_echo():
		return
	if event.is_action_pressed(&"attack"):
		_request_simple()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"heavy_attack"):
		_request_heavy()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _heavy_cooldown > 0.0:
		_heavy_cooldown = maxf(_heavy_cooldown - delta, 0.0)
	if _state == State.IDLE or _state == State.MOVE:
		_aim_at_cursor()
	match _state:
		State.IDLE, State.MOVE:
			_update_locomotion(delta)
		State.SIMPLE_ATTACK:
			var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
			_move(delta, direction * Units.px(move_speed))
		State.HEAVY_ATTACK:
			_move(delta, Vector2.ZERO)
		State.DEAD:
			pass


func _update_locomotion(delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction != Vector2.ZERO and not _knockback.is_active():
		_change_state(State.MOVE)
	else:
		_change_state(State.IDLE)
	_move(delta, direction * Units.px(move_speed))
	if _heavy_requested:
		_heavy_requested = false
		_simple_requested = false
		_combo_step = 0
		_start_heavy()
	elif _simple_requested:
		_simple_requested = false
		_combo_step = 0
		_start_simple()


func _request_simple() -> void:
	if _state == State.SIMPLE_ATTACK:
		_combo_queued = true
	elif _state != State.HEAVY_ATTACK:
		_simple_requested = true


func _request_heavy() -> void:
	if _heavy_cooldown > 0.0:
		return
	if _state == State.IDLE or _state == State.MOVE:
		_heavy_requested = true


func _start_simple() -> void:
	_aim_at_cursor()
	_heavy_hitbox.cancel()
	_change_state(State.SIMPLE_ATTACK)
	var step := mini(_combo_step, simple_durations.size() - 1)
	var duration := simple_durations[step]
	_simple_hitbox.play(duration, simple_active_starts[step], simple_active_ends[step])
	simple_attack_started.emit(duration)
	queue_redraw()


func _start_heavy() -> void:
	_aim_at_cursor()
	_simple_hitbox.cancel()
	_combo_queued = false
	_heavy_cooldown = heavy_cooldown
	_change_state(State.HEAVY_ATTACK)
	_heavy_hitbox.play(heavy_duration, heavy_active_start, heavy_active_end)
	heavy_attack_started.emit(heavy_cooldown)
	queue_redraw()


func _on_swing_finished() -> void:
	if _state == State.SIMPLE_ATTACK:
		var last_step := simple_durations.size() - 1
		if _combo_queued and _combo_step < last_step:
			_combo_queued = false
			_combo_step += 1
			_start_simple()
			return
		_combo_queued = false
		_combo_step = 0
		_change_state(State.IDLE)
		simple_attack_ended.emit()
	elif _state == State.HEAVY_ATTACK:
		_change_state(State.IDLE)


func _on_attack_landed() -> void:
	attack_landed.emit()


func _on_hit_received(from_position: Vector2) -> void:
	if _state == State.DEAD:
		return
	_knockback.apply(from_position, global_position, -_facing)
	var ended_simple := _state == State.SIMPLE_ATTACK
	if _state != State.SIMPLE_ATTACK and _state != State.HEAVY_ATTACK:
		return
	_cancel_attacks()
	_change_state(State.IDLE)
	if ended_simple:
		simple_attack_ended.emit()


func _cancel_attacks() -> void:
	_combo_queued = false
	_combo_step = 0
	_simple_requested = false
	_heavy_requested = false
	_simple_hitbox.cancel()
	_heavy_hitbox.cancel()


func _move(delta: float, desired: Vector2) -> void:
	if _knockback.is_active():
		velocity = _knockback.consume(delta)
	else:
		velocity = desired
	move_and_slide()


func _aim_at_cursor() -> void:
	var to_cursor := get_global_mouse_position() - global_position
	if to_cursor.length_squared() < 1.0:
		return
	_set_facing(to_cursor)


func _set_facing(direction: Vector2) -> void:
	var next := direction.normalized()
	if next.is_equal_approx(_facing):
		return
	_facing = next
	_apply_facing()


func _apply_facing() -> void:
	var angle := _facing.angle()
	var edge := _body_edge(_facing)
	_simple_hitbox.position = _facing * edge
	_simple_hitbox.rotation = angle
	_heavy_hitbox.rotation = angle
	_heavy_hitbox.position = _facing * (edge + Units.measure(&"heavy_swing_width") * 0.5)
	queue_redraw()


func _body_edge(direction: Vector2) -> float:
	return Units.body_edge(_body_shape.shape as RectangleShape2D, direction)


func _change_state(next: State) -> void:
	if next == _state:
		return
	_state = next
	queue_redraw()


func _on_died() -> void:
	var ended_simple := _state == State.SIMPLE_ATTACK
	_cancel_attacks()
	_change_state(State.DEAD)
	if ended_simple:
		simple_attack_ended.emit()
	set_physics_process(false)
	set_process(false)
	velocity = Vector2.ZERO
	_camera.offset = Vector2.ZERO


func _draw() -> void:
	var shape := _body_shape.shape as RectangleShape2D
	if shape == null:
		return
	var size := shape.size
	var color := BODY_COLOR
	if _state == State.SIMPLE_ATTACK:
		var blend := float(_combo_step) / float(maxi(simple_durations.size() - 1, 1))
		color = SIMPLE_COLOR.lerp(Color.WHITE, blend * 0.45)
	elif _state == State.HEAVY_ATTACK:
		color = HEAVY_COLOR
	elif _state == State.DEAD:
		color = Color(0.35, 0.38, 0.45)
	draw_rect(Rect2(-size * 0.5, size), color)
	if _state == State.DEAD:
		return
	var edge := _body_edge(_facing)
	var origin := _facing * edge
	if _state == State.HEAVY_ATTACK:
		var length := Units.measure(&"heavy_swing_width")
		draw_line(origin, origin + _facing * length, Color("ffe0b0"), 8.0)
		return
	var radius := Units.measure(&"simple_arc_radius")
	var half := deg_to_rad(SIMPLE_AIM_RADIUS_DEGREES)
	draw_line(origin, origin + _facing.rotated(-half) * radius, Color(1, 1, 1, 0.45), 2.0)
	draw_line(origin, origin + _facing.rotated(half) * radius, Color(1, 1, 1, 0.45), 2.0)
	if _state == State.SIMPLE_ATTACK:
		draw_line(origin, origin + _facing * radius, Color("fff4c2"), 5.0)
