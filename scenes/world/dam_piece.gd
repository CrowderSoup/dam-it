extends Node2D
## The visual placed into a DamSlot once it's been built.

func _draw() -> void:
	draw_rect(Rect2(-14, -10, 28, 20), Color(0.45, 0.32, 0.18))
	draw_rect(Rect2(-14, -10, 28, 20), Color(0.3, 0.2, 0.1), false, 2.0)
