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
			draw_circle(Vector2.ZERO, 7, Color(0.3, 0.55, 0.25))
			draw_circle(Vector2(-3, -4), 2, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(3, -4), 2, Color(0.1, 0.1, 0.1))
		Kind.DUCK:
			draw_circle(Vector2.ZERO, 8, Color(0.95, 0.9, 0.85))
			draw_circle(Vector2(6, -4), 4, Color(0.95, 0.9, 0.85))
			draw_rect(Rect2(9, -5, 4, 2), Color(0.9, 0.6, 0.1))
		Kind.FISH:
			draw_circle(Vector2.ZERO, 6, Color(0.4, 0.6, 0.8))
			draw_colored_polygon(PackedVector2Array([
				Vector2(-6, 0), Vector2(-12, -4), Vector2(-12, 4),
			]), Color(0.4, 0.6, 0.8))
