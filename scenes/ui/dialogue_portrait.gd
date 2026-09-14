extends Control
## A small hand-drawn portrait for the dialogue box, echoing each cast
## member's species (see docs/design/cast.md) so speaker identity reads at
## a glance the way visual-direction.md asks for ("exaggerating pose and
## facial expression for dialogue-scale readability"), without needing new
## sprite assets - same procedural-cutout approach as hud_icon.gd/critter.gd.
##
## Static per speaker rather than mood-driven: DialogueLine/DialogueChoice
## have no expression field in the schema (see dialogue_line.gd), and adding
## one is a content/schema decision outside this issue's presentation-layer
## scope.

var _speaker_id: String = ""

func set_speaker(speaker_id: String) -> void:
	if _speaker_id == speaker_id:
		return
	_speaker_id = speaker_id
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	match _speaker_id:
		"moss":
			_draw_moss(c)
		"marnie":
			_draw_marnie(c)
		"eddy":
			_draw_eddy(c)
		"clover":
			_draw_clover(c)
		"saffron":
			_draw_saffron(c)
		"bramble":
			_draw_bramble(c)
		"reed":
			_draw_beaver(c, false)
		"hazel":
			_draw_beaver(c, true)
		_:
			DrawUtil.outlined_circle(self, c, 17.0, Palette.STONE_MID, 2.0)

## Dry-witted and guarded (see cast.md) - half-lidded brows over the frog's
## usual big eyes, rather than a bright wide-open look.
func _draw_moss(c: Vector2) -> void:
	DrawUtil.outlined_circle(self, c + Vector2(0, 3), 16.0, Palette.FROG_BODY, 2.0)
	draw_circle(c + Vector2(0, 11), 7.5, Palette.FROG_BELLY)
	DrawUtil.outlined_circle(self, c + Vector2(-9, -9), 6.0, Palette.FROG_BODY, 1.5)
	DrawUtil.outlined_circle(self, c + Vector2(9, -9), 6.0, Palette.FROG_BODY, 1.5)
	draw_circle(c + Vector2(-9, -8), 2.4, Color(0.1, 0.1, 0.1))
	draw_circle(c + Vector2(9, -8), 2.4, Color(0.1, 0.1, 0.1))
	draw_line(c + Vector2(-13, -13), c + Vector2(-5, -12), Palette.OUTLINE, 1.6)
	draw_line(c + Vector2(5, -12), c + Vector2(13, -13), Palette.OUTLINE, 1.6)

## Energetic and decisive (see cast.md) - a brighter, forward-tilted bill.
func _draw_marnie(c: Vector2) -> void:
	DrawUtil.outlined_circle(self, c + Vector2(-2, 2), 15.0, Palette.DUCK_BODY, 1.5)
	DrawUtil.outlined_circle(self, c + Vector2(8, -6), 8.5, Palette.DUCK_BODY, 1.5)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(15, -7), c + Vector2(25, -5), c + Vector2(15, -2),
	]), Palette.DUCK_BILL)
	draw_circle(c + Vector2(9, -8), 1.4, Color(0.1, 0.1, 0.1))

## Calm and precise (see cast.md) - a steady, level gaze.
func _draw_eddy(c: Vector2) -> void:
	var tail := PackedVector2Array([
		c + Vector2(-13, 2), c + Vector2(-25, -7), c + Vector2(-25, 11),
	])
	DrawUtil.outlined_polygon(self, tail, Palette.FISH_BODY, 1.3)
	DrawUtil.outlined_circle(self, c + Vector2(2, 2), 14.0, Palette.FISH_BODY, 1.8)
	draw_circle(c + Vector2(4, 6), 6.5, Palette.FISH_BELLY)
	draw_circle(c + Vector2(8, -3), 1.8, Color(0.1, 0.1, 0.1))

## Practical and prepared (see cast.md) - tall, attentive ears.
func _draw_clover(c: Vector2) -> void:
	DrawUtil.shadow(self, c + Vector2(0, 18), Vector2(13, 3))
	draw_circle(c + Vector2(-6, -14), 3.0, Palette.RABBIT_FUR)
	draw_circle(c + Vector2(6, -14), 3.0, Palette.RABBIT_FUR)
	DrawUtil.outlined_circle(self, c + Vector2(0, 3), 13.0, Palette.RABBIT_FUR, 1.5)
	draw_circle(c + Vector2(-4, 1), 1.7, Color(0.1, 0.1, 0.1))
	draw_circle(c + Vector2(4, 1), 1.7, Color(0.1, 0.1, 0.1))
	draw_circle(c + Vector2(0, 5), 1.4, Color(0.85, 0.55, 0.55))

## Curious and direct (see cast.md) - wings framing a small, alert body.
func _draw_saffron(c: Vector2) -> void:
	var wing := Palette.BUTTERFLY_WING
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(-15, -13), c + Vector2(-8, 2)]), wing)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(15, -13), c + Vector2(8, 2)]), wing)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, 0), c + Vector2(-10, 9), c + Vector2(-4, 13)]), wing)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, 0), c + Vector2(10, 9), c + Vector2(4, 13)]), wing)
	draw_line(c + Vector2(0, -9), c + Vector2(0, 11), Color(0.2, 0.15, 0.1), 1.5)

## Resourceful, proud, quietly funny (see cast.md) - the signature mask.
func _draw_bramble(c: Vector2) -> void:
	DrawUtil.outlined_circle(self, c + Vector2(0, 2), 16.0, Palette.RACCOON_FUR, 2.0)
	draw_circle(c + Vector2(0, 7), 8.5, Palette.RACCOON_TAIL_LIGHT)
	var mask := PackedVector2Array([
		c + Vector2(-14, -6), c + Vector2(14, -6), c + Vector2(11, 2), c + Vector2(-11, 2),
	])
	draw_colored_polygon(mask, Palette.RACCOON_MASK)
	draw_circle(c + Vector2(-6, -2), 2.0, Color(0.9, 0.9, 0.9))
	draw_circle(c + Vector2(6, -2), 2.0, Color(0.9, 0.9, 0.9))

## Reed (the protagonist) and Grandma Hazel - both beavers; Hazel reads
## slightly lighter/greyer to suggest age, since she never appears as a
## resident herself (see cast.md) but her letters still need a legible
## portrait if a future scene shows one.
func _draw_beaver(c: Vector2, elder: bool) -> void:
	var fur := Palette.FUR_LIGHT if not elder else Palette.FUR_LIGHT.lerp(Color.WHITE, 0.35)
	DrawUtil.outlined_circle(self, c + Vector2(0, 1), 16.0, fur, 2.0)
	draw_circle(c + Vector2(0, 9), 7.5, Palette.FUR_BELLY)
	draw_circle(c + Vector2(-6, -3), 2.0, Color(0.1, 0.1, 0.1))
	draw_circle(c + Vector2(6, -3), 2.0, Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(c.x - 3.5, c.y + 3, 3.0, 4.0), Color(0.98, 0.96, 0.9))
	draw_rect(Rect2(c.x + 0.5, c.y + 3, 3.0, 4.0), Color(0.98, 0.96, 0.9))
