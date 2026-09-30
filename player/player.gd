class_name Player
extends CharacterBody2D
## Top-down fighter. Owns movement and the swing.
## Health and hit detection live on child nodes.

enum State { IDLE, MOVE, ATTACK, DEAD }

const HITBOX_DISTANCE := 46.0
const BODY_COLOR := Color("4c7dff")
const ATTACK_COLOR := Color("9eb6ff")

@export_group("Movement")
@export_range(50.0, 800.0, 10.0, "suffix:px/s") var move_speed: float = 260.0

@export_group("Attack")
@export_range(0.05, 1.0, 0.01, "suffix:s") var attack_duration: float = 0.32
@export_range(0.0, 1.0, 0.01, "suffix:s") var hit_active_start: float = 0.08
@export_range(0.0, 1.0, 0.01, "suffix:s") var hit_active_end: float = 0.2

@onready var health: HealthComponent = %HealthComponent as HealthComponent
@onready var _hitbox: Hitbox = %Hitbox as Hitbox
@onready var _body_shape: CollisionShape2D = $BodyShape

var _state: State = State.IDLE
var _facing := Vector2.RIGHT
var _attack_time := 0.0
var _hit_window_open := false
var _attack_requested := false


func _ready() -> void:
	assert(hit_active_end > hit_active_start)
	assert(attack_duration >= hit_active_end)
	health.died.connect(_on_died)
	_apply_facing()


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.DEAD:
		return
	if event.is_action_pressed(&"attack"):
		_attack_requested = true
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE, State.MOVE:
			_update_locomotion()
		State.ATTACK:
			_update_attack(delta)
		State.DEAD:
			pass


func _update_locomotion() -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction != Vector2.ZERO:
		_set_facing(direction)
		_change_state(State.MOVE)
	else:
		_change_state(State.IDLE)
	velocity = direction * move_speed
	move_and_slide()
	if _attack_requested:
		_attack_requested = false
		_start_attack()


func _start_attack() -> void:
	_attack_time = 0.0
	_hit_window_open = false
	_change_state(State.ATTACK)
	velocity = Vector2.ZERO


func _update_attack(delta: float) -> void:
	_attack_time += delta
	var window_open := _attack_time >= hit_active_start and _attack_time < hit_active_end
	if window_open and not _hit_window_open:
		_hitbox.begin()
		_hit_window_open = true
	elif not window_open and _hit_window_open:
		_hitbox.end()
		_hit_window_open = false
	velocity = Vector2.ZERO
	move_and_slide()
	if _attack_time >= attack_duration:
		_hitbox.end()
		_hit_window_open = false
		_change_state(State.IDLE)


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
	_hitbox.end()
	_change_state(State.DEAD)
	set_physics_process(false)
	velocity = Vector2.ZERO


func _draw() -> void:
	var shape := _body_shape.shape as RectangleShape2D
	if shape == null:
		return
	var size := shape.size
	var color := BODY_COLOR
	if _state == State.ATTACK:
		color = ATTACK_COLOR
	elif _state == State.DEAD:
		color = Color(0.35, 0.38, 0.45)
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_line(Vector2.ZERO, _facing * 22.0, Color.WHITE, 3.0)
