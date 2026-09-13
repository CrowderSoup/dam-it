extends Node2D
## Pure visual: the beaver's body. Kept separate from Player so flipping to
## face left/right doesn't also mirror the camera or collision shapes.
## Art is authored facing right; Player flips this node's scale.x to face
## left, which mirrors everything (including the tail side) correctly.

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 13), Vector2(10, 4))

	# Tail: a paddle trailing behind, with a few scale-texture lines.
	var tail_points := PackedVector2Array([
		Vector2(-8, 2), Vector2(-17, -1), Vector2(-19, 6),
		Vector2(-15, 11), Vector2(-7, 9),
	])
	DrawUtil.outlined_polygon(self, tail_points, Palette.TAIL_COLOR, 1.5)
	draw_line(Vector2(-11, 4), Vector2(-16, 3), Palette.TAIL_SCALE, 1.0)
	draw_line(Vector2(-11, 7), Vector2(-16, 7), Palette.TAIL_SCALE, 1.0)
	draw_line(Vector2(-10, 10), Vector2(-15, 10.5), Palette.TAIL_SCALE, 1.0)

	# Ears, peeking out behind the head.
	DrawUtil.outlined_circle(self, Vector2(-6, -11), 3.2, Palette.FUR_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(6, -11), 3.2, Palette.FUR_DARK, 1.5)

	# Body + belly.
	DrawUtil.shaded_circle(self, Vector2.ZERO, 13.0, Palette.FUR_MID, Palette.FUR_LIGHT, 2.0)
	draw_circle(Vector2(0, 4), 8.0, Palette.FUR_BELLY)

	# Cheeks.
	draw_circle(Vector2(-7, 0), 2.2, Color(0.85, 0.5, 0.45, 0.5))
	draw_circle(Vector2(7, 0), 2.2, Color(0.85, 0.5, 0.45, 0.5))

	# Eyes with a little life in them.
	draw_circle(Vector2(-4.5, -4), 2.1, Color(0.12, 0.09, 0.08))
	draw_circle(Vector2(4.5, -4), 2.1, Color(0.12, 0.09, 0.08))
	draw_circle(Vector2(-5.1, -4.6), 0.7, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(3.9, -4.6), 0.7, Color(1, 1, 1, 0.9))

	# Nose + buck teeth, the signature beaver look.
	draw_circle(Vector2(0, -1), 1.6, Color(0.15, 0.1, 0.08))
	draw_rect(Rect2(-2.2, 0.5, 2, 3.5), Color(0.97, 0.95, 0.85))
	draw_rect(Rect2(0.2, 0.5, 2, 3.5), Color(0.97, 0.95, 0.85))
	draw_line(Vector2(0, 0.5), Vector2(0, 4), Palette.OUTLINE, 0.6)
