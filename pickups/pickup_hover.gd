class_name PickupHover
extends Node
## Lifts a pickup icon and lets it drift. The motion is a slow wave, not a bounce
## against the floor, and the Area2D stays where it was dropped.

signal expired

const LIFT := 14.0
const DRIFT := 4.0
const CYCLES_PER_SECOND := 0.75
const TIMER_CENTER := Vector2(0.0, -30.0)
const TIMER_RADIUS := 5.0

@export_range(1.0, 120.0, 1.0, "suffix:s") var lifetime: float = 25.0

var _time := 0.0
var _left := 0.0


func _ready() -> void:
	_time = randf() * TAU
	_left = lifetime


func _process(delta: float) -> void:
	_time += delta
	_left = maxf(_left - delta, 0.0)
	var icon := get_parent() as CanvasItem
	if icon == null:
		return
	icon.queue_redraw()
	if _left > 0.0:
		return
	set_process(false)
	expired.emit()


func offset() -> Vector2:
	var wave := sin(_time * TAU * CYCLES_PER_SECOND)
	return Vector2(0.0, -LIFT + wave * DRIFT)


func draw_timer(canvas: CanvasItem) -> void:
	var fraction := 0.0
	if lifetime > 0.0:
		fraction = clampf(_left / lifetime, 0.0, 1.0)
	canvas.draw_arc(TIMER_CENTER, TIMER_RADIUS, 0.0, TAU, 24, Color(0, 0, 0, 0.45), 2.5)
	if fraction <= 0.0:
		return
	var start := -PI * 0.5
	canvas.draw_arc(TIMER_CENTER, TIMER_RADIUS, start, start + TAU * fraction, 24, Color("fff4c2"), 2.0)


func draw_shadow(canvas: CanvasItem) -> void:
	var height := -offset().y
	var width := lerpf(1.15, 0.7, clampf((height - 10.0) / 8.0, 0.0, 1.0))
	canvas.draw_set_transform(Vector2(0.0, 12.0), 0.0, Vector2(width, 0.35))
	canvas.draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.28))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
