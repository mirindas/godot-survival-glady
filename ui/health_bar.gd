class_name HealthBar
extends Control
## Filled bar for the HUD. Green until health drops below 30%, then orange, then red below 10%.

const BAR_SIZE := Vector2(220, 32)
const TRACK := Color("14181f")
const BORDER := Color("c5ccd6")
const GREEN := Color("3dcc6e")
const ORANGE := Color("f0a03c")
const RED := Color("d83b3b")

var _fraction := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = BAR_SIZE
	size = BAR_SIZE


func set_fraction(current: int, maximum: int) -> void:
	if maximum <= 0:
		_fraction = 0.0
	else:
		_fraction = clampf(float(current) / float(maximum), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size)
	draw_rect(outer, TRACK)
	var inset := 3.0
	var inner := Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
	var fill := inner
	fill.size.x *= _fraction
	if fill.size.x > 0.0:
		draw_rect(fill, fill_color(_fraction))
	draw_rect(outer.grow(-1.0), BORDER, false, 2.0)


static func fill_color(fraction: float) -> Color:
	if fraction < 0.10:
		return RED
	if fraction < 0.30:
		return ORANGE
	return GREEN
