extends StaticBody2D
## A mineable rock. Yields stone over a couple hits, then respawns.

const STONE_YIELD := 1
const HITS_TO_BREAK := 2
const RESPAWN_TIME := 10.0

const ROCK_COLOR := Color(0.55, 0.55, 0.58)
const ROCK_HIGHLIGHT_SPOT := Color(0.68, 0.68, 0.7)
const RUBBLE_COLOR := Color(0.45, 0.45, 0.48)
const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.6, 0.9)

var hits_taken: int = 0
var broken: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("rocks")
	# The InteractArea (not this StaticBody2D) is what Player's overlap
	# check actually finds - see Player._resolve_target().
	$InteractArea.add_to_group("rock_areas")

func _draw() -> void:
	if broken:
		draw_circle(Vector2.ZERO, 5, RUBBLE_COLOR)
		return
	if highlighted:
		draw_arc(Vector2.ZERO, 16, 0, TAU, 24, HIGHLIGHT_COLOR, 2.0)
	draw_circle(Vector2.ZERO, 10, ROCK_COLOR)
	draw_circle(Vector2(-3, -3), 4, ROCK_HIGHLIGHT_SPOT)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func mine() -> void:
	if broken:
		return
	hits_taken += 1
	GameState.add_stone(STONE_YIELD)
	Sfx.play_mine()
	Fx.burst(global_position, Color(0.6, 0.6, 0.62), 6)
	_shake()
	queue_redraw()
	if hits_taken >= HITS_TO_BREAK:
		_break()

func _shake() -> void:
	scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _break() -> void:
	broken = true
	set_highlighted(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()
	await get_tree().create_timer(RESPAWN_TIME).timeout
	_respawn()

func _respawn() -> void:
	broken = false
	hits_taken = 0
	$CollisionShape2D.disabled = false
	$InteractArea/CollisionShape2D.disabled = false
	queue_redraw()
