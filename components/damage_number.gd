class_name DamageNumber
extends Node2D
## World-space damage text. Lives in the room, not on the body that was hit,
## so a killing blow does not delete the number.

const LIFE_SECONDS := 0.7
const RISE_SPEED_ID: StringName = &"damage_number_rise_speed"

const ITALIC_SHEAR := 0.28

var _text := ""
var _color := Color.WHITE
var _font_size := 28
var _italic := false
var _spawn_at := Vector2.ZERO
var _age := 0.0


func show_text(text: String, color: Color, font_size: int, world_position: Vector2, italic: bool = false) -> void:
	_text = text
	_color = color
	_font_size = font_size
	_italic = italic
	_spawn_at = world_position
	z_index = 20


func _ready() -> void:
	global_position = _spawn_at


func _process(delta: float) -> void:
	_age += delta
	position.y -= Units.measure(RISE_SPEED_ID) * delta
	modulate.a = clampf(1.0 - _age / LIFE_SECONDS, 0.0, 1.0)
	queue_redraw()
	if _age >= LIFE_SECONDS:
		queue_free()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
	var origin := Vector2(-text_size.x * 0.5, 0.0)
	if _italic:
		origin.x -= ITALIC_SHEAR * float(_font_size) * 0.35
		draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(-ITALIC_SHEAR, 1), origin))
		_draw_text(font, Vector2.ZERO)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	_draw_text(font, origin)


func _draw_text(font: Font, origin: Vector2) -> void:
	draw_string(font, origin + Vector2(1, 1), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color(0, 0, 0, 0.9))
	draw_string(font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _color)
