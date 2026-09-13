extends StaticBody2D
## A choppable tree. Yields wood over a few hits, then respawns.

const WOOD_YIELD := 1
const HITS_TO_FELL := 3
const RESPAWN_TIME := 8.0

var hits_taken: int = 0
var felled: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("trees")
	# The InteractArea (not this StaticBody2D) is what Player's overlap
	# check actually finds, so it needs its own group to be resolved back
	# to this node. See Player._resolve_target().
	$InteractArea.add_to_group("tree_areas")

func _draw() -> void:
	if felled:
		DrawUtil.shadow(self, Vector2(0, 11), Vector2(7, 3))
		DrawUtil.outlined_circle(self, Vector2(0, 8), 6.0, Palette.BARK, 1.5)
		draw_arc(Vector2(0, 8), 3.0, 0, TAU, 16, Palette.BARK_DARK, 1.0)
		return

	DrawUtil.shadow(self, Vector2(0, 18), Vector2(11, 4))
	if highlighted:
		draw_arc(Vector2(0, -8), 25, 0, TAU, 32, Palette.HIGHLIGHT_RING, 2.5)

	DrawUtil.outlined_rect(self, Rect2(-4, 2, 8, 16), Palette.BARK, 1.5)
	draw_line(Vector2(-1, 4), Vector2(-1, 16), Palette.BARK_DARK, 1.0)
	draw_line(Vector2(2, 5), Vector2(2, 15), Palette.BARK_DARK, 1.0)

	# Layered canopy lobes, back-to-front, for a fluffy silhouette.
	DrawUtil.outlined_circle(self, Vector2(-10, -6), 12.0, Palette.LEAF_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(10, -6), 12.0, Palette.LEAF_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(0, -18), 15.0, Palette.LEAF_MID, 1.5)
	draw_circle(Vector2(-5, -22), 5.0, Palette.LEAF_LIGHT)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func chop() -> void:
	if felled:
		return
	hits_taken += 1
	GameState.add_wood(WOOD_YIELD)
	Sfx.play_chop()
	Fx.burst(global_position, Color(0.55, 0.4, 0.22), 8)
	_shake()
	queue_redraw()
	if hits_taken >= HITS_TO_FELL:
		_fell()

func _shake() -> void:
	scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 0.85), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _fell() -> void:
	felled = true
	set_highlighted(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()
	await get_tree().create_timer(RESPAWN_TIME).timeout
	_respawn()

func _respawn() -> void:
	felled = false
	hits_taken = 0
	$CollisionShape2D.disabled = false
	$InteractArea/CollisionShape2D.disabled = false
	queue_redraw()
