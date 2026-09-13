extends Area2D
## A marked spot along the riverbank where a dam piece can be built.

var built: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("dam_slots")
	GameState.register_dam_slot()

func _draw() -> void:
	if built:
		return
	draw_circle(Vector2.ZERO, 11.0, Color(1, 1, 1, 0.18))
	var ring_width := 3.5 if highlighted else 2.0
	var ring_color := Palette.HIGHLIGHT_RING if highlighted else Color(1, 1, 1, 0.75)
	# A dashed ring reads as a "build marker" rather than a solid object.
	var dash_count := 10
	for i in dash_count:
		var start_angle := TAU * i / dash_count
		var end_angle := start_angle + TAU / dash_count * 0.6
		draw_arc(Vector2.ZERO, 10.0, start_angle, end_angle, 4, ring_color, ring_width)

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
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 12)
	_place_piece()

## Restores a built slot from a save file - same end state as build(), but
## silent (no sound/particles) since nothing just happened live.
func set_built_silently(value: bool) -> void:
	if not value or built:
		return
	_place_piece()

func _place_piece() -> void:
	built = true
	set_highlighted(false)
	queue_redraw()
	var piece := preload("res://scenes/world/dam_piece.tscn").instantiate()
	add_child(piece)
