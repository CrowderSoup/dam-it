extends Node2D
## A purely decorative critter that appears (with a little pop-in) once the
## Lodge reaches a given stage, then bobs gently in place. No collision, no
## interaction - just a visible reward for progress.

enum Kind { FROG, DUCK, FISH }

@export var kind: Kind = Kind.FROG
@export var required_stage: int = 1
@export var bob_height: float = 2.0
@export var bob_speed: float = 2.5

var _time := 0.0
var _base_position: Vector2

func _ready() -> void:
	_base_position = position
	GameState.lodge_stage_changed.connect(_on_stage_changed)
	visible = GameState.lodge_stage >= required_stage

func _on_stage_changed(stage: int) -> void:
	if stage >= required_stage and not visible:
		visible = true
		scale = Vector2.ZERO
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	position = _base_position + Vector2(0, sin(_time * bob_speed) * bob_height)

func _draw() -> void:
	match kind:
		Kind.FROG:
			_draw_frog()
		Kind.DUCK:
			_draw_duck()
		Kind.FISH:
			_draw_fish()

func _draw_frog() -> void:
	DrawUtil.shadow(self, Vector2(0, 6), Vector2(7, 2))
	draw_circle(Vector2(-4, -3), 3.0, Palette.FROG_BODY)
	draw_circle(Vector2(4, -3), 3.0, Palette.FROG_BODY)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 7.0, Palette.FROG_BODY, 1.5)
	draw_circle(Vector2(0, 2), 3.5, Palette.FROG_BELLY)
	draw_circle(Vector2(-4, -3), 1.2, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(4, -3), 1.2, Color(0.1, 0.1, 0.1))

func _draw_duck() -> void:
	DrawUtil.shadow(self, Vector2(0, 8), Vector2(9, 2.5))
	DrawUtil.outlined_circle(self, Vector2.ZERO, 8.0, Palette.DUCK_BODY, 1.5)
	DrawUtil.outlined_circle(self, Vector2(6, -5), 4.5, Palette.DUCK_BODY, 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(9, -6), Vector2(14, -5), Vector2(9, -3.5),
	]), Palette.DUCK_BILL)
	draw_circle(Vector2(6.5, -6), 0.9, Color(0.1, 0.1, 0.1))
	draw_arc(Vector2(-2, 0), 5.0, PI * 0.15, PI * 0.85, 8, Color(0.85, 0.8, 0.72), 1.2)

func _draw_fish() -> void:
	draw_circle(Vector2(0, 3), 8.0, Color(1, 1, 1, 0.15))
	var tail := PackedVector2Array([
		Vector2(-6, 0), Vector2(-13, -4.5), Vector2(-13, 4.5),
	])
	DrawUtil.outlined_polygon(self, tail, Palette.FISH_BODY, 1.2)
	DrawUtil.outlined_circle(self, Vector2.ZERO, 6.5, Palette.FISH_BODY, 1.5)
	draw_circle(Vector2(1, 2), 3.2, Palette.FISH_BELLY)
	var dorsal := PackedVector2Array([
		Vector2(-1, -6), Vector2(2, -10), Vector2(4, -6),
	])
	DrawUtil.outlined_polygon(self, dorsal, Palette.FISH_BODY, 1.0)
	draw_circle(Vector2(3.5, -1), 1.0, Color(0.1, 0.1, 0.1))
