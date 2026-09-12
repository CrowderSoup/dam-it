extends Area2D
## A marked spot along the riverbank where a dam piece can be built.

var built: bool = false

func _ready() -> void:
	add_to_group("dam_slots")
	GameState.register_dam_slot()

func _draw() -> void:
	if built:
		return
	draw_circle(Vector2.ZERO, 10, Color(0.7, 0.7, 0.7, 0.4))
	draw_arc(Vector2.ZERO, 10, 0, TAU, 24, Color(0.95, 0.95, 0.95, 0.8), 2.0)

func can_build() -> bool:
	return not built

func build() -> void:
	if built:
		return
	built = true
	queue_redraw()
	var piece := preload("res://scenes/world/dam_piece.tscn").instantiate()
	add_child(piece)
