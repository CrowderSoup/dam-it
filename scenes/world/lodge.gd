extends Area2D
## The Lodge build site. Locked until the dam is finished; once unlocked,
## interact repeatedly (with enough wood + stone) to advance it through
## foundation -> walls -> roof.

const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.6, 0.9)
const LOCKED_COLOR := Color(0.5, 0.5, 0.5, 0.6)

var unlocked: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("lodge")
	GameState.dam_completed.connect(_on_unlocked)
	GameState.lodge_stage_changed.connect(_on_stage_changed)

func _on_unlocked() -> void:
	unlocked = true
	queue_redraw()

func _on_stage_changed(_stage: int) -> void:
	queue_redraw()

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func can_advance() -> bool:
	return unlocked and GameState.lodge_stage < GameState.LODGE_MAX_STAGE

func advance() -> void:
	if not can_advance():
		return
	GameState.advance_lodge_stage()
	Sfx.play_build()
	Fx.burst(global_position, Color(0.7, 0.55, 0.35), 14)
	queue_redraw()

func _draw() -> void:
	if not unlocked:
		_draw_locked()
		return
	if highlighted and can_advance():
		draw_arc(Vector2(0, -8), 32, 0, TAU, 28, HIGHLIGHT_COLOR, 2.0)

	var stage := GameState.lodge_stage
	if stage >= 1:
		draw_rect(Rect2(-20, -4, 40, 18), Color(0.42, 0.3, 0.18))
	else:
		draw_rect(Rect2(-20, -4, 40, 18), Color(0.6, 0.5, 0.4), false, 2.0)
	if stage >= 2:
		draw_rect(Rect2(-18, -22, 36, 20), Color(0.55, 0.42, 0.26))
		draw_rect(Rect2(-4, -8, 8, 4), Color(0.25, 0.16, 0.08))
	if stage >= 3:
		var roof_points := PackedVector2Array([
			Vector2(-22, -22), Vector2(22, -22), Vector2(0, -38),
		])
		draw_colored_polygon(roof_points, Color(0.5, 0.2, 0.15))
		draw_rect(Rect2(10, -34, 5, 10), Color(0.4, 0.4, 0.4))

func _draw_locked() -> void:
	draw_rect(Rect2(-20, -4, 40, 18), LOCKED_COLOR, false, 2.0)
	draw_rect(Rect2(-6, -2, 12, 10), Color(0.3, 0.3, 0.3, 0.85))
	draw_arc(Vector2(0, -2), 6, PI, TAU, 12, Color(0.3, 0.3, 0.3, 0.85), 2.0)
