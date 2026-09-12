extends StaticBody2D
## A choppable tree. Yields wood over a few hits, then respawns.

const WOOD_YIELD := 1
const HITS_TO_FELL := 3
const RESPAWN_TIME := 8.0

const CANOPY_COLOR := Color(0.18, 0.45, 0.2)
const TRUNK_COLOR := Color(0.36, 0.24, 0.14)
const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.6, 0.9)

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
		draw_rect(Rect2(-4, 4, 8, 10), TRUNK_COLOR)
		return
	if highlighted:
		draw_arc(Vector2(0, 2), 20, 0, TAU, 28, HIGHLIGHT_COLOR, 2.0)
	draw_rect(Rect2(-4, 4, 8, 14), TRUNK_COLOR)
	draw_circle(Vector2(0, -6), 16, CANOPY_COLOR)

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
