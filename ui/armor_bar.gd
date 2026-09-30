class_name ArmorBar
extends Control
## Blue armor bar. The fill is current armor over the cap.

const BAR_SIZE := Vector2(220, 32)
const TRACK := Color("121a28")
const BORDER := Color("8eb4e8")
const FILL := Color("3b82f6")

var _fraction := 0.0


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
		draw_rect(fill, FILL)
	draw_rect(outer.grow(-1.0), BORDER, false, 2.0)
