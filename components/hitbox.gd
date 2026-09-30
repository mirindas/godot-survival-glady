class_name Hitbox
extends Area2D
## Melee volume. The owner enables it for the active frames of a swing.
## One swing damages each overlapping hurtbox at most once.

@export_range(1, 500) var damage: int = 25

var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


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
	hurtbox.receive_hit(damage)


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
