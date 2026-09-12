extends Node2D
## Purely visual: a soft blob of a slightly different grass shade, to break
## up the flat background color. No collision, no interaction.

@export var patch_color: Color = Color(0.32, 0.58, 0.3, 0.5)
@export var patch_radius: float = 60.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, patch_radius, patch_color)
	draw_circle(Vector2(patch_radius * 0.5, patch_radius * 0.3), patch_radius * 0.6, patch_color)
	draw_circle(Vector2(-patch_radius * 0.4, patch_radius * 0.4), patch_radius * 0.5, patch_color)
