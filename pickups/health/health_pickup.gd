extends Area2D
## Restores health when the player walks over it. No inventory.

@export_range(1, 500) var amount: int = 30

var _collected := false

@onready var _hover: PickupHover = $Hover as PickupHover


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_hover.expired.connect(queue_free)
	_collect_overlaps()


func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)


func _collect_overlaps() -> void:
	await get_tree().physics_frame
	if not is_inside_tree() or _collected:
		return
	for body: Node2D in get_overlapping_bodies():
		_try_collect(body)


func _try_collect(body: Node2D) -> void:
	if _collected:
		return
	var player := body as Player
	if player == null or player.health == null:
		return
	if player.health.current_health <= 0 or player.health.current_health >= player.health.max_health:
		return
	_collected = true
	player.health.heal(amount)
	queue_free()


func _draw() -> void:
	_hover.draw_shadow(self)
	draw_set_transform(_hover.offset(), 0.0, Vector2.ONE)
	var points := PackedVector2Array([
		Vector2(0, -14),
		Vector2(12, 0),
		Vector2(0, 14),
		Vector2(-12, 0),
	])
	draw_colored_polygon(points, Color("6dce7a"))
	_hover.draw_timer(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
