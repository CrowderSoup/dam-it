extends StaticBody2D
## A choppable tree. Yields wood over a few hits, then respawns.

const WOOD_YIELD := 1
const HITS_TO_FELL := 3
const RESPAWN_TIME := 8.0

const CANOPY_COLOR := Color(0.18, 0.45, 0.2)
const TRUNK_COLOR := Color(0.36, 0.24, 0.14)

var hits_taken: int = 0
var felled: bool = false

func _ready() -> void:
	$InteractArea.add_to_group("trees")

func _draw() -> void:
	if felled:
		draw_rect(Rect2(-4, 4, 8, 10), TRUNK_COLOR)
		return
	draw_rect(Rect2(-4, 4, 8, 14), TRUNK_COLOR)
	draw_circle(Vector2(0, -6), 16, CANOPY_COLOR)

func chop() -> void:
	if felled:
		return
	hits_taken += 1
	GameState.add_wood(WOOD_YIELD)
	queue_redraw()
	if hits_taken >= HITS_TO_FELL:
		_fell()

func _fell() -> void:
	felled = true
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
