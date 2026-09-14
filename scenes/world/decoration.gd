extends Node2D
## Purely visual scenery - no collision, no interaction. Adds variety to the
## grass without needing any art assets.

enum Kind { ROCK, BUSH }

@export var kind: Kind = Kind.ROCK

func _draw() -> void:
	match kind:
		Kind.ROCK:
			DrawUtil.shadow(self, Vector2(0, 7), Vector2(8, 3))
			DrawUtil.outlined_circle(self, Vector2.ZERO, 10.0, Palette.STONE_MID, 1.5)
			draw_circle(Vector2(-3, -3), 3.5, Palette.STONE_LIGHT)
		Kind.BUSH:
			DrawUtil.shadow(self, Vector2(0, 8), Vector2(11, 3))
			DrawUtil.outlined_circle(self, Vector2(-7, 2), 8.0, Palette.BUSH_DARK, 1.5)
			DrawUtil.outlined_circle(self, Vector2(7, 2), 8.0, Palette.BUSH_DARK, 1.5)
			DrawUtil.outlined_circle(self, Vector2(0, -5), 9.5, Palette.BUSH_LIGHT, 1.5)
			draw_circle(Vector2(-4, -3), 1.6, Palette.BERRY)
			draw_circle(Vector2(3, 1), 1.6, Palette.BERRY)
			draw_circle(Vector2(-1, -8), 1.6, Palette.BERRY)
