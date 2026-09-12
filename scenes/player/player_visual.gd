extends Node2D
## Pure visual: the beaver's body. Kept separate from Player so flipping to
## face left/right doesn't also mirror the camera or collision shapes.

const BODY_COLOR := Color(0.42, 0.28, 0.15)
const BELLY_COLOR := Color(0.62, 0.46, 0.28)
const TAIL_COLOR := Color(0.2, 0.12, 0.08)

func _draw() -> void:
	draw_rect(Rect2(-6, 4, 12, 10), TAIL_COLOR)
	draw_circle(Vector2.ZERO, 12, BODY_COLOR)
	draw_circle(Vector2(0, 3), 7, BELLY_COLOR)
	draw_circle(Vector2(-4, -4), 2, Color.BLACK)
	draw_circle(Vector2(4, -4), 2, Color.BLACK)
