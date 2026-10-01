class_name Grunt
extends CharacterBody2D
## Melee enemy. Chases the target it was given and swings on its own hitbox.
## The arena chooses the target. This scene does not search the tree for the player.

signal attack_landed

enum State { CHASE, ATTACK, RECOVER, DEAD }

const BODY_COLOR := Color("d9782d")
const ATTACK_COLOR := Color("ffd29a")

@export_group("Movement")
@export_range(1.0, 12.0, 0.05, "suffix:widths/s") var move_speed: float = Units.GRUNT_MOVE_SPEED
@export_range(0.5, 20.0, 0.05, "suffix:widths") var attack_range: float = Units.GRUNT_ATTACK_RANGE
@export_range(0.0, 8.0, 0.05, "suffix:widths/s") var lunge_speed: float = Units.GRUNT_LUNGE_SPEED

@export_group("Attack")
@export_range(0.05, 1.5, 0.01, "suffix:s") var attack_duration: float = 0.46
@export_range(0.0, 1.0, 0.01, "suffix:s") var hit_active_start: float = 0.16
@export_range(0.0, 1.0, 0.01, "suffix:s") var hit_active_end: float = 0.28
@export_range(0.0, 2.0, 0.01, "suffix:s") var recover_duration: float = 0.4

@export_group("Drop")
@export var health_drop_scene: PackedScene
@export_range(0.0, 1.0, 0.05) var drop_chance: float = 0.05
@export var armor_drop_scene: PackedScene
@export_range(0.0, 1.0, 0.05) var armor_drop_chance: float = 0.1

@onready var _health: HealthComponent = %HealthComponent as HealthComponent
@onready var _hitbox: Hitbox = %Hitbox as Hitbox
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _knockback: Knockback = $Knockback as Knockback
@onready var _body_shape: CollisionShape2D = $BodyShape

var _target: Player
var _state: State = State.CHASE
var _facing := Vector2.LEFT
var _recover_left := 0.0
var _flash: Tween


func setup(target: Player) -> void:
	_target = target


func _ready() -> void:
	assert(hit_active_end > hit_active_start)
	assert(attack_duration >= hit_active_end)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_hitbox.hit_landed.connect(_on_attack_landed)
	_hitbox.finished.connect(_on_swing_finished)
	_apply_facing()


func _physics_process(delta: float) -> void:
	match _state:
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_move(delta, _facing * Units.px(lunge_speed))
		State.RECOVER:
			_recover(delta)
		State.DEAD:
			pass


func _chase(delta: float) -> void:
	if not _target_alive():
		_move(delta, Vector2.ZERO)
		return
	var to_target := _target.global_position - global_position
	_set_facing(to_target)
	if _in_attack_range(to_target):
		_start_attack()
		return
	_move(delta, to_target.normalized() * Units.px(move_speed))


func _in_attack_range(to_target: Vector2) -> bool:
	return to_target.length() <= Units.px(attack_range)


func _start_attack() -> void:
	_state = State.ATTACK
	_hitbox.play(attack_duration, hit_active_start, hit_active_end)
	queue_redraw()


func _on_swing_finished() -> void:
	if _state != State.ATTACK:
		return
	_recover_left = recover_duration
	_state = State.RECOVER
	queue_redraw()


func _recover(delta: float) -> void:
	_recover_left -= delta
	_move(delta, Vector2.ZERO)
	if _recover_left > 0.0:
		return
	_state = State.CHASE
	queue_redraw()


func _on_attack_landed() -> void:
	attack_landed.emit()


func _on_hit_received(from_position: Vector2) -> void:
	if _state == State.DEAD:
		return
	_knockback.apply(from_position, global_position, -_facing)
	if _state != State.ATTACK:
		return
	_hitbox.cancel()
	_recover_left = recover_duration
	_state = State.RECOVER
	queue_redraw()


func _on_health_changed(current: int, _maximum: int) -> void:
	if current <= 0:
		return
	if _flash != null and _flash.is_valid():
		_flash.kill()
	modulate = Color(1.0, 0.45, 0.45)
	_flash = create_tween()
	_flash.tween_property(self, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	_state = State.DEAD
	_hitbox.cancel()
	set_physics_process(false)
	_drop(health_drop_scene, drop_chance, Vector2.ZERO)
	_drop(armor_drop_scene, armor_drop_chance, Vector2(28, 0))
	queue_free()


func _drop(scene: PackedScene, chance: float, offset: Vector2) -> void:
	if scene == null or randf() > chance:
		return
	var drop := scene.instantiate() as Node2D
	var actors := get_parent()
	if drop == null or actors == null:
		return
	drop.position = position + offset
	actors.add_child.call_deferred(drop)


func _target_alive() -> bool:
	return _target != null and is_instance_valid(_target) and _target.health.current_health > 0


func _move(delta: float, desired: Vector2) -> void:
	if _knockback.is_active():
		velocity = _knockback.consume(delta)
	else:
		velocity = desired
	move_and_slide()


func _set_facing(direction: Vector2) -> void:
	if direction.length_squared() < 0.001:
		return
	var next := direction.normalized()
	if next.is_equal_approx(_facing):
		return
	_facing = next
	_apply_facing()


func _apply_facing() -> void:
	var edge := _body_edge(_facing)
	_hitbox.position = _facing * (edge + Units.measure(&"swing_width") * 0.5)
	_hitbox.rotation = _facing.angle()
	queue_redraw()


func _body_edge(direction: Vector2) -> float:
	return Units.body_edge(_body_shape.shape as RectangleShape2D, direction)


func _draw() -> void:
	var shape := _body_shape.shape as RectangleShape2D
	if shape == null:
		return
	var size := shape.size
	var color := BODY_COLOR
	if _state == State.ATTACK:
		color = ATTACK_COLOR
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_line(Vector2.ZERO, _facing * 22.0, Color.WHITE, 3.0)
