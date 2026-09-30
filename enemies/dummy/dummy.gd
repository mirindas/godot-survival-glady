extends StaticBody2D
## Standing target. Proves the swing connects. The arena fight spawns grunts instead.

@onready var _health: HealthComponent = %HealthComponent as HealthComponent
@onready var _body_shape: CollisionShape2D = $BodyShape

var _flash: Tween


func _ready() -> void:
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(queue_free)


func _on_health_changed(current: int, _maximum: int) -> void:
	if current <= 0:
		return
	if _flash != null and _flash.is_valid():
		_flash.kill()
	modulate = Color(1.0, 0.45, 0.45)
	_flash = create_tween()
	_flash.tween_property(self, "modulate", Color.WHITE, 0.12)


func _draw() -> void:
	var shape := _body_shape.shape as RectangleShape2D
	if shape == null:
		return
	var size := shape.size
	draw_rect(Rect2(-size * 0.5, size), Color("c4554a"))
