class_name Hitbox
extends Area2D
## Melee volume. play() opens it for the active frames of one swing.
## One swing damages each overlapping hurtbox at most once.

signal hit_landed
signal finished

@export_range(1, 500) var damage: int = 25
@export_group("Damage number")
@export var damage_color: Color = Color("ffe14a")
@export_range(8, 72, 1) var damage_font_size: int = 28

var _already_hit: Array[Hurtbox] = []
var _playing := false
var _time := 0.0
var _duration := 0.0
var _active_start := 0.0
var _active_end := 0.0
var _window_open := false


func _ready() -> void:
	monitoring = false
	monitorable = false
	set_physics_process(false)
	area_entered.connect(_on_area_entered)
	_apply_swing_size()


func _apply_swing_size() -> void:
	var collision := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var rect := collision.shape as RectangleShape2D
	if rect == null:
		return
	rect.size = Vector2(Units.measure(&"swing_width"), Units.measure(&"swing_height"))


## Opens this hitbox during [active_start, active_end) of a swing that lasts duration.
## Emits finished when the swing time ends. cancel() does not emit finished.
func play(duration: float, active_start: float, active_end: float) -> void:
	assert(active_end > active_start)
	assert(duration >= active_end)
	cancel()
	_time = 0.0
	_duration = duration
	_active_start = active_start
	_active_end = active_end
	_window_open = false
	_playing = true
	set_physics_process(true)


func cancel() -> void:
	_playing = false
	set_physics_process(false)
	end()


func _physics_process(delta: float) -> void:
	if not _playing:
		return
	_time += delta
	var window_open := _time >= _active_start and _time < _active_end
	if window_open and not _window_open:
		begin()
		_window_open = true
	elif not window_open and _window_open:
		end()
		_window_open = false
	if _time < _duration:
		return
	end()
	_window_open = false
	_playing = false
	set_physics_process(false)
	finished.emit()


func begin() -> void:
	_already_hit.clear()
	monitoring = true
	queue_redraw()
	_scan_overlaps()


func end() -> void:
	if not monitoring:
		return
	monitoring = false
	_already_hit.clear()
	queue_redraw()


func _scan_overlaps() -> void:
	# Overlap lists update on the physics step, so a swing that starts
	# already touching a target still connects.
	await get_tree().physics_frame
	if not is_inside_tree() or not monitoring:
		return
	for area: Area2D in get_overlapping_areas():
		_try_hit(area)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


func _try_hit(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	if hurtbox.receive_hit(damage, _attacker_position()):
		_spawn_damage_number(hurtbox)
		hit_landed.emit()


func _spawn_damage_number(hurtbox: Hurtbox) -> void:
	var body := hurtbox.get_parent() as Node2D
	var host: Node = body.get_parent() if body != null else null
	if host == null:
		host = get_tree().current_scene
	if host == null:
		return
	var origin := body.global_position if body != null else hurtbox.global_position
	var number := DamageNumber.new()
	var spread := Units.measure(&"damage_number_spread")
	var lift := Units.measure(&"damage_number_lift")
	number.setup(damage, damage_color, damage_font_size, origin + Vector2(randf_range(-spread, spread), -lift))
	host.add_child.call_deferred(number)


func _attacker_position() -> Vector2:
	var body := get_parent() as Node2D
	if body == null:
		return global_position
	return body.global_position


func _draw() -> void:
	if not monitoring:
		return
	var collision := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var rect_shape := collision.shape as RectangleShape2D
	if rect_shape == null:
		return
	var size := rect_shape.size
	draw_rect(Rect2(-size * 0.5, size), Color(1, 1, 1, 0.35))
