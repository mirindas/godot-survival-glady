class_name Boss
extends Grunt
## One large melee enemy. The arena spawns it alone on every 5th wave.
## Body is 5 times the player. The first boss has 350 health and 36 damage.
## Each later boss is 13% tougher and hits 2% harder than the one before, rounded.
## Speed is 60% of the grunt. The swing starts 1.5 units out from the body.

const BOSS_BODY_COLOR := Color("6e1430")
const BOSS_ATTACK_COLOR := Color("ff5a3c")
const BASE_HEALTH := 350
const DAMAGE := 36
const HEALTH_GROWTH := 1.13
const DAMAGE_GROWTH := 1.02
const OUTLINE_COLOR := Color("ffd0a1")

var _damage := DAMAGE


## steps is how many bosses have already been fought. Call this before the boss enters the tree.
func prepare(steps: int) -> void:
	var health_points := BASE_HEALTH
	var damage := DAMAGE
	for _step in maxi(steps, 0):
		health_points = roundi(float(health_points) * HEALTH_GROWTH)
		damage = roundi(float(damage) * DAMAGE_GROWTH)
	var health_node := get_node(^"HealthComponent") as HealthComponent
	if health_node == null:
		push_error("Boss is missing HealthComponent.")
		return
	health_node.max_health = health_points
	_damage = damage


func _ready() -> void:
	move_speed = Units.BOSS_MOVE_SPEED
	lunge_speed = Units.BOSS_LUNGE_SPEED
	attack_range = Units.BOSS_ATTACK_RANGE
	super()
	_apply_body_size()
	_hitbox.damage = _damage
	_hitbox.apply_rectangle(Units.measure(&"boss_swing_width"), Units.measure(&"boss_swing_height"))
	_apply_facing()


func _in_attack_range(to_target: Vector2) -> bool:
	if to_target.length_squared() < 0.001:
		return true
	var shape := _body_shape.shape as RectangleShape2D
	return to_target.length() <= Units.body_edge(shape, to_target) + Units.px(attack_range)


func _apply_facing() -> void:
	var edge := _body_edge(_facing)
	_hitbox.position = _facing * (edge + Units.measure(&"boss_swing_width") * 0.5)
	_hitbox.rotation = _facing.angle()
	queue_redraw()


func _apply_body_size() -> void:
	var size := Vector2(
		Units.PLAYER_WIDTH * Units.BOSS_SCALE,
		Units.PLAYER_HEIGHT * Units.BOSS_SCALE
	)
	_resize(_body_shape, size)
	var hurt_collision := _hurtbox.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if hurt_collision == null:
		push_error("Boss is missing Hurtbox/CollisionShape2D.")
		return
	_resize(hurt_collision, size)


func _resize(collision: CollisionShape2D, size: Vector2) -> void:
	var rect := collision.shape as RectangleShape2D
	if rect == null:
		push_error("Boss shape on '%s' is not a rectangle." % collision.name)
		return
	rect.size = size


func _draw() -> void:
	var shape := _body_shape.shape as RectangleShape2D
	if shape == null:
		return
	var size := shape.size
	var color := BOSS_BODY_COLOR
	if _state == State.ATTACK:
		color = BOSS_ATTACK_COLOR
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, color)
	draw_rect(rect, OUTLINE_COLOR, false, 8.0)
	draw_line(Vector2.ZERO, _facing * size.x * 0.35, Color.WHITE, 8.0)
