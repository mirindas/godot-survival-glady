class_name EnemyHealthBar
extends Node2D
## World-space health bar above an enemy. Same colors as the player's bar.

const BAR_SIZE := Vector2(50, 10)
const CORNER := 3
const BORDER_WIDTH := 1
const HEAD_GAP := 4.0

var _health: HealthComponent
var _fraction := 1.0
var _track: StyleBoxFlat
var _fill: StyleBoxFlat


static func attach(body: Node2D, health: HealthComponent) -> void:
	if body == null or health == null or body.get_node_or_null("HealthBar") != null:
		return
	var bar := EnemyHealthBar.new()
	bar.name = "HealthBar"
	body.add_child(bar)
	bar.bind(health)


func _ready() -> void:
	z_index = 5
	_track = _box(HealthBar.TRACK, CORNER, true)
	_fill = _box(HealthBar.GREEN, CORNER - BORDER_WIDTH, false)


func bind(health: HealthComponent) -> void:
	_health = health
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)
	place_above_body()


func place_above_body() -> void:
	var body := get_parent() as Node2D
	if body == null:
		return
	var shape_node := body.get_node_or_null("BodyShape") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D if shape_node != null else null
	var half_height := 24.0
	if rect != null:
		half_height = rect.size.y * 0.5
	position = Vector2(0.0, -half_height - HEAD_GAP - BAR_SIZE.y * 0.5)
	queue_redraw()


func _on_health_changed(current: int, maximum: int) -> void:
	if maximum <= 0:
		_fraction = 0.0
	else:
		_fraction = clampf(float(current) / float(maximum), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(-BAR_SIZE * 0.5, BAR_SIZE)
	draw_style_box(_track, outer)
	var inner := outer.grow(-float(BORDER_WIDTH))
	inner.size.x *= _fraction
	if inner.size.x < 1.0:
		return
	_fill.bg_color = HealthBar.fill_color(_fraction)
	draw_style_box(_fill, inner)


func _box(color: Color, radius: int, bordered: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	if bordered:
		box.set_border_width_all(BORDER_WIDTH)
		box.border_color = HealthBar.BORDER
	return box
