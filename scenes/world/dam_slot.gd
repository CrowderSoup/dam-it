extends Area2D
## A marked spot along the riverbank where a dam piece can be built.

const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.6, 0.9)

var built: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("dam_slots")
	GameState.register_dam_slot()

func _draw() -> void:
	if built:
		return
	draw_circle(Vector2.ZERO, 10, Color(0.7, 0.7, 0.7, 0.4))
	var ring_width := 4.0 if highlighted else 2.0
	var ring_color := HIGHLIGHT_COLOR if highlighted else Color(0.95, 0.95, 0.95, 0.8)
	draw_arc(Vector2.ZERO, 10, 0, TAU, 24, ring_color, ring_width)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func can_build() -> bool:
	return not built

func build() -> void:
	if built:
		return
	built = true
	set_highlighted(false)
	queue_redraw()
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 12)
	var piece := preload("res://scenes/world/dam_piece.tscn").instantiate()
	add_child(piece)
