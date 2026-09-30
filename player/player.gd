class_name Player
extends CharacterBody2D
## Top-down fighter. Owns movement, the swing combo, and the camera shake.
## Health and hit detection live on child nodes.

signal attack_landed

enum State { IDLE, MOVE, ATTACK, DEAD }

const HITBOX_DISTANCE := 46.0
const BODY_COLOR := Color("4c7dff")
const ATTACK_COLOR := Color("9eb6ff")
const SHAKE_TIME := 0.12
const SHAKE_AMOUNT := 5.0

@export_group("Movement")
@export_range(50.0, 800.0, 10.0, "suffix:px/s") var move_speed: float = 260.0

@export_group("Attack")
@export var attack_durations: Array[float] = [0.32, 0.26, 0.4]
@export var hit_active_starts: Array[float] = [0.08, 0.05, 0.12]
@export var hit_active_ends: Array[float] = [0.18, 0.14, 0.26]

@onready var health: HealthComponent = %HealthComponent as HealthComponent
@onready var _hitbox: Hitbox = %Hitbox as Hitbox
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _knockback: Knockback = $Knockback as Knockback
@onready var _camera: Camera2D = $Camera2D
@onready var _body_shape: CollisionShape2D = $BodyShape

var _state: State = State.IDLE
var _facing := Vector2.RIGHT
var _attack_requested := false
var _combo_queued := false
var _combo_step := 0
var _shake_left := 0.0


func _ready() -> void:
	set_process(false)
	assert(not attack_durations.is_empty())
	assert(hit_active_starts.size() == attack_durations.size())
	assert(hit_active_ends.size() == attack_durations.size())
	for step: int in attack_durations.size():
		assert(hit_active_ends[step] > hit_active_starts[step])
		assert(attack_durations[step] >= hit_active_ends[step])
	health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_hitbox.hit_landed.connect(_on_attack_landed)
	_hitbox.finished.connect(_on_swing_finished)
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
	_camera.offset = Vector2(
		randf_range(-SHAKE_AMOUNT, SHAKE_AMOUNT),
		randf_range(-SHAKE_AMOUNT, SHAKE_AMOUNT)
	)


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.DEAD or event.is_echo() or not event.is_action_pressed(&"attack"):
		return
	if _state == State.ATTACK:
		_combo_queued = true
	else:
		_attack_requested = true
	get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE, State.MOVE:
			_update_locomotion(delta)
		State.ATTACK:
			_move(delta, Vector2.ZERO)
		State.DEAD:
			pass


func _update_locomotion(delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction != Vector2.ZERO and not _knockback.is_active():
		_set_facing(direction)
		_change_state(State.MOVE)
	else:
		_change_state(State.IDLE)
	_move(delta, direction * move_speed)
	if _attack_requested:
		_attack_requested = false
		_combo_step = 0
		_start_attack()


func _start_attack() -> void:
	_change_state(State.ATTACK)
	var step := mini(_combo_step, attack_durations.size() - 1)
	_hitbox.play(attack_durations[step], hit_active_starts[step], hit_active_ends[step])


func _on_swing_finished() -> void:
	if _state != State.ATTACK:
		return
	var last_step := attack_durations.size() - 1
	if _combo_queued and _combo_step < last_step:
		_combo_queued = false
		_combo_step += 1
		_start_attack()
		return
	_combo_queued = false
	_combo_step = 0
	_change_state(State.IDLE)


func _on_attack_landed() -> void:
	attack_landed.emit()


func _on_hit_received(from_position: Vector2) -> void:
	if _state == State.DEAD:
		return
	_knockback.apply(from_position, global_position, -_facing)
	if _state != State.ATTACK:
		return
	_combo_queued = false
	_combo_step = 0
	_hitbox.cancel()
	_change_state(State.IDLE)


func _move(delta: float, desired: Vector2) -> void:
	if _knockback.is_active():
		velocity = _knockback.consume(delta)
	else:
		velocity = desired
	move_and_slide()


func _set_facing(direction: Vector2) -> void:
	var next := direction.normalized()
	if next.is_equal_approx(_facing):
		return
	_facing = next
	_apply_facing()


func _apply_facing() -> void:
	_hitbox.position = _facing * HITBOX_DISTANCE
	_hitbox.rotation = _facing.angle()
	queue_redraw()


func _change_state(next: State) -> void:
	if next == _state:
		return
	_state = next
	queue_redraw()


func _on_died() -> void:
	_combo_queued = false
	_hitbox.cancel()
	_change_state(State.DEAD)
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
	if _state == State.ATTACK:
		var blend := float(_combo_step) / float(maxi(attack_durations.size() - 1, 1))
		color = ATTACK_COLOR.lerp(Color.WHITE, blend * 0.45)
	elif _state == State.DEAD:
		color = Color(0.35, 0.38, 0.45)
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_line(Vector2.ZERO, _facing * 22.0, Color.WHITE, 3.0)
