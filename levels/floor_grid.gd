extends Node2D
## Drawn on top of the flat floor so camera-follow movement is visible.


func _draw() -> void:
	var line := Color(0.0, 0.0, 0.0, 0.18)
	var x := 128.0
	while x < 2136.0:
		draw_line(Vector2(x, 64.0), Vector2(x, 1536.0), line, 2.0)
		x += 128.0
	var y := 128.0
	while y < 1536.0:
		draw_line(Vector2(64.0, y), Vector2(2136.0, y), line, 2.0)
		y += 128.0
