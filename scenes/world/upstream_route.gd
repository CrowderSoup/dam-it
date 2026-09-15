extends Node2D
## Durable world-space proof that Act I has opened the route upstream.

func _draw() -> void:
	draw_line(Vector2(-46, 34), Vector2(42, -28), Color(0.70, 0.58, 0.34), 8.0)
	draw_line(Vector2(-8, 0), Vector2(28, -4), Color(0.94, 0.82, 0.48), 5.0)
	draw_line(Vector2(28, -4), Vector2(15, -16), Color(0.94, 0.82, 0.48), 5.0)
	draw_line(Vector2(28, -4), Vector2(16, 9), Color(0.94, 0.82, 0.48), 5.0)
	draw_circle(Vector2(-45, 35), 6.0, Color(0.30, 0.22, 0.15))
