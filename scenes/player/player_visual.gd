extends Node2D
## Pure visual: a layered procedural beaver with cardinal poses and a compact
## walk cycle. Kept separate from Player so animation never moves the camera or
## collision shapes.

enum Facing { DOWN, LEFT, RIGHT, UP }

const WALK_CYCLE_SPEED := 10.0
const STRIDE_DISTANCE := 2.5
const BODY_LIFT := 1.25
const TAIL_SWAY := 1.5

var facing: Facing = Facing.DOWN
var moving := false
var walk_phase := 0.0

func _ready() -> void:
	GameState.energy_changed.connect(func(_e): queue_redraw())

## Updates the visual pose from Player's already-normalized input. Diagonal
## movement selects its dominant axis, producing four stable silhouettes while
## preserving the existing eight-way physical movement.
func set_movement(input_vector: Vector2, delta: float) -> void:
	if input_vector.is_zero_approx():
		moving = false
		walk_phase = 0.0
		queue_redraw()
		return

	moving = true
	if absf(input_vector.x) > absf(input_vector.y):
		facing = Facing.RIGHT if input_vector.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if input_vector.y > 0.0 else Facing.UP
	walk_phase = fmod(walk_phase + delta * WALK_CYCLE_SPEED, TAU)
	queue_redraw()

func get_stride_offset() -> float:
	return sin(walk_phase) * STRIDE_DISTANCE if moving else 0.0

func get_body_lift() -> float:
	return -absf(sin(walk_phase)) * BODY_LIFT if moving else 0.0

func get_tail_sway() -> float:
	return sin(walk_phase) * TAIL_SWAY if moving else 0.0

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 13), Vector2(10, 4))
	var stride := get_stride_offset()
	var body_lift := get_body_lift()
	var tail_sway := get_tail_sway()

	match facing:
		Facing.UP:
			_draw_back(stride, body_lift, tail_sway)
		Facing.LEFT:
			_draw_side(stride, body_lift, tail_sway, -1.0)
		Facing.RIGHT:
			_draw_side(stride, body_lift, tail_sway, 1.0)
		_:
			_draw_front(stride, body_lift, tail_sway)

func _draw_front(stride: float, body_lift: float, tail_sway: float) -> void:
	# The feet alternate independently instead of the entire cutout simply
	# bobbing. Their dark value also keeps the motion readable over grass.
	DrawUtil.outlined_circle(self, Vector2(-6, 11 + stride), 3.2, Palette.FUR_DARK, 1.3)
	DrawUtil.outlined_circle(self, Vector2(6, 11 - stride), 3.2, Palette.FUR_DARK, 1.3)

	# Tail: a paddle trailing behind, with a few scale-texture lines.
	var tail_points := PackedVector2Array([
		Vector2(-8, 2), Vector2(-17, -1 + tail_sway),
		Vector2(-19, 6 + tail_sway), Vector2(-15, 11), Vector2(-7, 9),
	])
	DrawUtil.outlined_polygon(self, tail_points, Palette.TAIL_COLOR, 1.5)
	draw_line(Vector2(-11, 4), Vector2(-16, 3 + tail_sway), Palette.TAIL_SCALE, 1.0)
	draw_line(Vector2(-11, 7), Vector2(-16, 7 + tail_sway), Palette.TAIL_SCALE, 1.0)

	var body := Vector2(0, body_lift)

	# Ears, peeking out behind the head.
	DrawUtil.outlined_circle(self, body + Vector2(-6, -11), 3.2, Palette.FUR_DARK, 1.5)
	DrawUtil.outlined_circle(self, body + Vector2(6, -11), 3.2, Palette.FUR_DARK, 1.5)

	# Body + belly.
	DrawUtil.shaded_circle(self, body, 13.0, Palette.FUR_MID, Palette.FUR_LIGHT, 2.0)
	draw_circle(body + Vector2(0, 4), 8.0, Palette.FUR_BELLY)

	# Cheeks.
	draw_circle(body + Vector2(-7, 0), 2.2, Color(0.85, 0.5, 0.45, 0.5))
	draw_circle(body + Vector2(7, 0), 2.2, Color(0.85, 0.5, 0.45, 0.5))

	# Eyes with a little life in them - or droopy, sleepy-lidded ones once
	# GameState.energy runs low, as a visual cue to go eat/rest.
	if GameState.is_tired():
		draw_line(body + Vector2(-6.3, -4), body + Vector2(-2.7, -4), Color(0.12, 0.09, 0.08), 1.4)
		draw_line(body + Vector2(2.7, -4), body + Vector2(6.3, -4), Color(0.12, 0.09, 0.08), 1.4)
	else:
		draw_circle(body + Vector2(-4.5, -4), 2.1, Color(0.12, 0.09, 0.08))
		draw_circle(body + Vector2(4.5, -4), 2.1, Color(0.12, 0.09, 0.08))
		draw_circle(body + Vector2(-5.1, -4.6), 0.7, Color(1, 1, 1, 0.9))
		draw_circle(body + Vector2(3.9, -4.6), 0.7, Color(1, 1, 1, 0.9))

	# Nose + buck teeth, the signature beaver look.
	draw_circle(body + Vector2(0, -1), 1.6, Color(0.15, 0.1, 0.08))
	draw_rect(Rect2(body + Vector2(-2.2, 0.5), Vector2(2, 3.5)), Color(0.97, 0.95, 0.85))
	draw_rect(Rect2(body + Vector2(0.2, 0.5), Vector2(2, 3.5)), Color(0.97, 0.95, 0.85))
	draw_line(body + Vector2(0, 0.5), body + Vector2(0, 4), Palette.OUTLINE, 0.6)

func _draw_back(stride: float, body_lift: float, tail_sway: float) -> void:
	# The broad centered tail and absent face make the away-facing pose distinct
	# from the front pose even at the 640x360 target viewport.
	var tail_points := PackedVector2Array([
		Vector2(-5, 7), Vector2(-8 + tail_sway, 13), Vector2(-5 + tail_sway, 21),
		Vector2(5 + tail_sway, 21), Vector2(8 + tail_sway, 13), Vector2(5, 7),
	])
	DrawUtil.outlined_polygon(self, tail_points, Palette.TAIL_COLOR, 1.5)
	draw_line(Vector2(-5 + tail_sway, 15), Vector2(5 + tail_sway, 15), Palette.TAIL_SCALE, 1.0)
	draw_line(Vector2(-4 + tail_sway, 18), Vector2(4 + tail_sway, 18), Palette.TAIL_SCALE, 1.0)
	DrawUtil.outlined_circle(self, Vector2(-6, 10 + stride), 3.2, Palette.FUR_DARK, 1.3)
	DrawUtil.outlined_circle(self, Vector2(6, 10 - stride), 3.2, Palette.FUR_DARK, 1.3)

	var body := Vector2(0, body_lift)
	DrawUtil.outlined_circle(self, body + Vector2(-6, -10), 3.2, Palette.FUR_DARK, 1.5)
	DrawUtil.outlined_circle(self, body + Vector2(6, -10), 3.2, Palette.FUR_DARK, 1.5)
	DrawUtil.shaded_circle(self, body, 13.0, Palette.FUR_MID, Palette.FUR_LIGHT, 2.0)
	# A dark crown/shoulder patch supplies a second value layer without turning
	# the back pose into a face.
	draw_arc(body + Vector2(0, -3), 7.0, PI, TAU, 18, Palette.FUR_DARK, 2.4)
	draw_arc(body + Vector2(0, 3), 8.0, 0.15, PI - 0.15, 18, Palette.FUR_BELLY, 2.0)

func _draw_side(stride: float, body_lift: float, tail_sway: float, direction: float) -> void:
	# Author one side silhouette and mirror only these draw calls. The visual
	# node itself stays unscaled, so animation state remains direction-agnostic.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1.0))
	var tail_points := PackedVector2Array([
		Vector2(-9, 2), Vector2(-18, -1 + tail_sway), Vector2(-21, 5 + tail_sway),
		Vector2(-17, 10), Vector2(-8, 8),
	])
	DrawUtil.outlined_polygon(self, tail_points, Palette.TAIL_COLOR, 1.5)
	draw_line(Vector2(-12, 4), Vector2(-18, 3 + tail_sway), Palette.TAIL_SCALE, 1.0)
	draw_line(Vector2(-12, 7), Vector2(-17, 7 + tail_sway), Palette.TAIL_SCALE, 1.0)
	DrawUtil.outlined_circle(self, Vector2(-5, 11 + stride), 3.2, Palette.FUR_DARK, 1.3)
	DrawUtil.outlined_circle(self, Vector2(6, 11 - stride), 3.2, Palette.FUR_DARK, 1.3)

	var body := Vector2(-2, 2 + body_lift)
	var head := Vector2(7, -5 + body_lift - absf(stride) * 0.08)
	DrawUtil.shaded_circle(self, body, 11.5, Palette.FUR_MID, Palette.FUR_LIGHT, 2.0)
	draw_circle(body + Vector2(1, 4), 6.5, Palette.FUR_BELLY)
	DrawUtil.outlined_circle(self, head + Vector2(-2, -7), 3.0, Palette.FUR_DARK, 1.4)
	DrawUtil.shaded_circle(self, head, 9.0, Palette.FUR_MID, Palette.FUR_LIGHT, 1.8)
	if GameState.is_tired():
		draw_line(head + Vector2(2, -2), head + Vector2(6, -2), Color(0.12, 0.09, 0.08), 1.4)
	else:
		draw_circle(head + Vector2(4.5, -2.5), 1.8, Color(0.12, 0.09, 0.08))
		draw_circle(head + Vector2(4.1, -3.0), 0.6, Color(1, 1, 1, 0.9))
	draw_circle(head + Vector2(8.0, 0), 1.6, Color(0.15, 0.1, 0.08))
	draw_rect(Rect2(head + Vector2(7, 1.5), Vector2(2.2, 3.5)), Color(0.97, 0.95, 0.85))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
