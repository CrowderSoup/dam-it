extends Control
## A small hand-drawn icon for the bottom HUD bar, echoing the look of the
## matching world object (wood = log end-grain, stone = rock cluster, dam
## piece = tiny log stack, lodge = tiny house) so the icon reads at a glance
## without needing a text label to explain it.

enum Kind { WOOD, STONE, DAM, LODGE, ENERGY }

@export var kind: Kind = Kind.WOOD

func _draw() -> void:
	var c := size / 2.0
	match kind:
		Kind.WOOD:
			_draw_wood(c)
		Kind.STONE:
			_draw_stone(c)
		Kind.DAM:
			_draw_dam(c)
		Kind.LODGE:
			_draw_lodge(c)
		Kind.ENERGY:
			_draw_energy(c)

func _draw_wood(c: Vector2) -> void:
	draw_circle(c, 11.0, Palette.WOOD_MID)
	draw_arc(c, 10.0, 0, TAU, 20, Palette.OUTLINE, 2.0)
	draw_circle(c, 6.0, Palette.WOOD_LIGHT)
	draw_arc(c, 6.0, 0, TAU, 16, Palette.WOOD_DARK, 1.2)

func _draw_stone(c: Vector2) -> void:
	var main_rock := PackedVector2Array([
		c + Vector2(-9, 3), c + Vector2(-6, -7), c + Vector2(2, -9),
		c + Vector2(9, -2), c + Vector2(6, 7), c + Vector2(-3, 8),
	])
	DrawUtil.outlined_polygon(self, main_rock, Palette.STONE_MID, 1.5)
	draw_circle(c + Vector2(-3, -3), 3.0, Palette.STONE_LIGHT)

func _draw_dam(c: Vector2) -> void:
	for i in 2:
		var rect := Rect2(c.x - 11.0, c.y - 7.0 + i * 9.0, 22.0, 7.0)
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.WOOD_MID
		style.set_corner_radius_all(3)
		style.border_color = Palette.OUTLINE
		style.set_border_width_all(1)
		style.draw(get_canvas_item(), rect)
		for end_x in [rect.position.x + 3.0, rect.end.x - 3.0]:
			draw_circle(Vector2(end_x, rect.position.y + 3.5), 2.2, Palette.WOOD_LIGHT)

func _draw_lodge(c: Vector2) -> void:
	draw_rect(Rect2(c.x - 8.0, c.y - 1.0, 16.0, 10.0), Palette.WOOD_MID)
	var roof := PackedVector2Array([
		c + Vector2(-10, -1), c + Vector2(10, -1), c + Vector2(0, -11),
	])
	DrawUtil.outlined_polygon(self, roof, Palette.ROOF, 1.5)

func _draw_energy(c: Vector2) -> void:
	# A leaf, echoing what the beaver actually eats (bark + greens).
	var leaf := PackedVector2Array([
		c + Vector2(0, -10), c + Vector2(8, -2), c + Vector2(0, 10), c + Vector2(-8, -2),
	])
	DrawUtil.outlined_polygon(self, leaf, Palette.LEAF_MID, 1.5)
	draw_line(c + Vector2(0, -8), c + Vector2(0, 9), Palette.LEAF_DARK, 1.2)
