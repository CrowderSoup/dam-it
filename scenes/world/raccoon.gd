class_name Raccoon
extends Area2D
## A mischievous scavenger, not a threat: it periodically shows up near your
## resources (see Main's raccoon timer), and if you don't walk up and shoo
## it away within LINGER_TIME, it swipes a little wood/stone and scurries
## off. No combat, no permanent loss - just a nuisance to keep an eye on.

signal despawned

const LINGER_TIME := 18.0
const STEAL_WOOD := 3
const STEAL_STONE := 1

var highlighted: bool = false
var _active: bool = false
var _time_left := 0.0

func _ready() -> void:
	add_to_group("raccoons")
	monitorable = false
	hide()
	set_process(false)

func spawn_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	_time_left = LINGER_TIME
	_active = true
	highlighted = false
	monitorable = true
	show()
	set_process(true)
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_steal_and_flee()

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func can_shoo() -> bool:
	return _active

func shoo() -> void:
	if not _active:
		return
	Sfx.play_shoo()
	Fx.burst(global_position, Color(0.6, 0.55, 0.5), 8)
	_despawn()

func _steal_and_flee() -> void:
	GameState.remove_wood(STEAL_WOOD)
	GameState.remove_stone(STEAL_STONE)
	Sfx.play_steal()
	Fx.burst(global_position, Color(0.5, 0.42, 0.3), 10)
	_despawn()

func _despawn() -> void:
	_active = false
	monitorable = false
	set_process(false)
	hide()
	despawned.emit()

func _draw() -> void:
	if not _active:
		return
	if highlighted:
		draw_arc(Vector2(0, -4), 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	DrawUtil.shadow(self, Vector2(0, 9), Vector2(9, 3))

	# Ringed tail, trailing behind.
	for i in 3:
		var tail_color := Palette.RACCOON_MASK if i % 2 == 0 else Palette.RACCOON_TAIL_LIGHT
		draw_circle(Vector2(9.0 + i * 4.0, 4.0), 2.4, tail_color)

	draw_circle(Vector2(-6, -10), 2.4, Palette.RACCOON_FUR)
	draw_circle(Vector2(6, -10), 2.4, Palette.RACCOON_FUR)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 8.0, Palette.RACCOON_FUR, 1.5)
	draw_rect(Rect2(-7, -6, 14, 5), Palette.RACCOON_MASK)
	draw_circle(Vector2(-3.2, -4), 1.3, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(3.2, -4), 1.3, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(0, 0.5), 1.0, Color(0.1, 0.1, 0.1))
