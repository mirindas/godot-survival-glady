class_name AttackSlot
extends Control
## One attack square. The sword is drawn here, not imported.
## A canvas shader fades the pixels the clock hand has not reached yet,
## because _draw() cannot change the opacity of only part of the square.

enum Kind { SIMPLE, HEAVY }

const SLOT := Vector2(64, 64)
const FILL := Color("1a2230")
const SIMPLE_EDGE := Color("4c7dff")
const HEAVY_EDGE := Color("ffb45a")
const BLADE := Color("f4f7fb")
const GUARD := Color("d5dde8")
const GRIP := Color("8d6b45")
const POMMEL := Color("c5ccd6")
const SIMPLE_SWORD_SCALE := 0.66
const HEAVY_SWORD_SCALE := 1.0
const CLOCK_SHADER := "
shader_type canvas_item;

varying vec2 local_pos;

uniform float progress = 1.0;
uniform vec2 slot_size = vec2(64.0);

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 pixel = COLOR;
	if (progress < 1.0) {
		vec2 from_center = local_pos - slot_size * 0.5;
		float angle = atan(from_center.x, -from_center.y);
		if (angle < 0.0) {
			angle += TAU;
		}
		if (angle / TAU > progress) {
			pixel.a *= 0.5;
		}
	}
	COLOR = pixel;
}
"

@export var kind: Kind = Kind.SIMPLE

var _clock_left := 0.0
var _clock_duration := 0.0
var _clock_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SLOT
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var shader := Shader.new()
	shader.code = CLOCK_SHADER
	_clock_material = ShaderMaterial.new()
	_clock_material.shader = shader
	material = _clock_material
	_set_progress(1.0)
	set_process(false)
	resized.connect(_on_resized)


## Starts the clockwise restore. duration is the swing, or the heavy cooldown.
func start_clock(duration: float) -> void:
	_clock_duration = maxf(duration, 0.001)
	_clock_left = _clock_duration
	_set_progress(0.0)
	set_process(true)


## Snaps the square back to full opacity.
func end_clock() -> void:
	_clock_left = 0.0
	_set_progress(1.0)
	set_process(false)


func _process(delta: float) -> void:
	_clock_left = maxf(_clock_left - delta, 0.0)
	_set_progress(1.0 - _clock_left / _clock_duration)
	if _clock_left > 0.0:
		return
	set_process(false)


func _on_resized() -> void:
	if _clock_material == null:
		return
	_clock_material.set_shader_parameter("slot_size", size)
	queue_redraw()


func _set_progress(progress: float) -> void:
	var slot_size := size if size.x > 0.0 else SLOT
	_clock_material.set_shader_parameter("progress", clampf(progress, 0.0, 1.0))
	_clock_material.set_shader_parameter("slot_size", slot_size)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FILL)
	var edge := HEAVY_EDGE if kind == Kind.HEAVY else SIMPLE_EDGE
	var inset := 1.5
	draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0)), edge, false, 3.0)
	var scale := HEAVY_SWORD_SCALE if kind == Kind.HEAVY else SIMPLE_SWORD_SCALE
	draw_set_transform(size * 0.5, 0.0, Vector2(scale, scale))
	_draw_sword()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sword() -> void:
	var blade := PackedVector2Array([
		Vector2(-3.2, 10.0),
		Vector2(-3.4, -14.0),
		Vector2(0.0, -26.0),
		Vector2(3.4, -14.0),
		Vector2(3.2, 10.0),
	])
	draw_colored_polygon(blade, BLADE)
	draw_line(Vector2(0.0, 8.0), Vector2(0.0, -18.0), Color("c5d0dc"), 1.5)
	draw_rect(Rect2(Vector2(-12.0, 7.0), Vector2(24.0, 4.0)), GUARD)
	draw_rect(Rect2(Vector2(-2.4, 11.0), Vector2(4.8, 10.0)), GRIP)
	draw_circle(Vector2(0.0, 23.0), 3.4, POMMEL)
