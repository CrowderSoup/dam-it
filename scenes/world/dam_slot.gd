extends Area2D
## A marked spot along the riverbank where a dam piece can be built. Once
## built, a storm can weaken it into a leaking state (see Main's storm
## timer) that needs a repair - same interact action, same cost - before it
## goes back to just sitting there quietly.

var built: bool = false
var leaking: bool = false
var highlighted: bool = false
var _piece: Node2D = null

func _ready() -> void:
	add_to_group("dam_slots")
	GameState.register_dam_slot()

func _draw() -> void:
	if built and not leaking:
		return
	if built and leaking:
		if highlighted:
			draw_arc(Vector2.ZERO, 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
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

func can_repair() -> bool:
	return built and leaking

func build() -> void:
	if not can_build():
		return
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 12)
	_place_piece()

## Called by Main's storm timer on a random already-built, non-leaking slot.
func start_leaking() -> void:
	if not built or leaking:
		return
	leaking = true
	if _piece:
		_piece.set_leaking(true)
	queue_redraw()

func repair() -> void:
	if not can_repair():
		return
	leaking = false
	if _piece:
		_piece.set_leaking(false)
	Sfx.play_build()
	Fx.burst(global_position, Color(0.6, 0.6, 0.65), 10)
	queue_redraw()

## Restores a built slot from a save file - same end state as build(), but
## silent (no sound/particles) since nothing just happened live.
func set_built_silently(value: bool) -> void:
	if not value or built:
		return
	_place_piece()

## Restores a leaking slot from a save file - silent, same reasoning as
## set_built_silently().
func set_leaking_silently(value: bool) -> void:
	if not value or not built or leaking:
		return
	leaking = true
	if _piece:
		_piece.set_leaking(true)
	queue_redraw()

func _place_piece() -> void:
	built = true
	set_highlighted(false)
	queue_redraw()
	var piece := preload("res://scenes/world/dam_piece.tscn").instantiate()
	_piece = piece
	add_child(piece)
