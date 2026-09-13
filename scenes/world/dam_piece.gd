extends Node2D
## The visual placed into a DamSlot once it's been built: a small stack of
## logs, with visible end-grain where they face the camera.

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 13), Vector2(16, 4))
	_draw_log(Vector2(0, -7))
	_draw_log(Vector2(0, 2))
	_draw_log(Vector2(0, 11))

func _draw_log(center: Vector2) -> void:
	var rect := Rect2(center + Vector2(-15, -4), Vector2(30, 8))
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_MID
	style.set_corner_radius_all(4)
	style.border_color = Palette.OUTLINE
	style.set_border_width_all(1)
	style.draw(get_canvas_item(), rect)

	for end_x in [-13.0, 13.0]:
		draw_circle(center + Vector2(end_x, 0), 3.2, Palette.WOOD_LIGHT)
		draw_arc(center + Vector2(end_x, 0), 3.2, 0, TAU, 12, Palette.WOOD_DARK, 1.0)
