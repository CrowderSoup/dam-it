extends Node2D
## Purely visual scenery - no collision, no interaction. Adds variety to the
## grass without needing any art assets.

enum Kind { ROCK, BUSH }

@export var kind: Kind = Kind.ROCK

func _draw() -> void:
	match kind:
		Kind.ROCK:
			draw_circle(Vector2.ZERO, 10, Color(0.55, 0.55, 0.58))
			draw_circle(Vector2(-3, -3), 4, Color(0.68, 0.68, 0.7))
		Kind.BUSH:
			draw_circle(Vector2(-7, 2), 8, Color(0.2, 0.48, 0.24))
			draw_circle(Vector2(7, 2), 8, Color(0.22, 0.5, 0.26))
			draw_circle(Vector2(0, -5), 9, Color(0.24, 0.52, 0.28))
