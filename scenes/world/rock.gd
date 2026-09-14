extends Harvestable
## A mineable rock. Yields stone over a couple hits, then respawns.

const STONE_YIELD := 1
const HITS_TO_BREAK := 2

var hits_taken: int = 0

func _ready() -> void:
	respawn_time = 10.0
	add_to_group("rocks")
	# The InteractArea (not this StaticBody2D) is what Player's overlap
	# check actually finds - see Player._resolve_target().
	$InteractArea.add_to_group("rock_areas")

func _draw() -> void:
	if depleted:
		DrawUtil.shadow(self, Vector2(0, 6), Vector2(6, 2))
		var rubble := PackedVector2Array([
			Vector2(-5, 3), Vector2(-2, -2), Vector2(3, -3), Vector2(5, 2), Vector2(0, 4),
		])
		DrawUtil.outlined_polygon(self, rubble, Palette.STONE_DARK, 1.2)
		return

	DrawUtil.shadow(self, Vector2(0, 9), Vector2(9, 3))
	if highlighted:
		draw_arc(Vector2.ZERO, 17, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)

	# A small companion rock behind, so the cluster reads as rocky terrain
	# rather than a single perfect blob.
	var small_rock := PackedVector2Array([
		Vector2(6, 6), Vector2(10, 2), Vector2(13, 6), Vector2(10, 9),
	])
	DrawUtil.outlined_polygon(self, small_rock, Palette.STONE_MID, 1.2)

	var main_rock := PackedVector2Array([
		Vector2(-10, 4), Vector2(-8, -6), Vector2(-2, -10),
		Vector2(6, -8), Vector2(10, 0), Vector2(6, 8), Vector2(-4, 9),
	])
	DrawUtil.outlined_polygon(self, main_rock, Palette.STONE_MID, 1.6)
	draw_circle(Vector2(-3, -4), 3.2, Palette.STONE_LIGHT)

	draw_line(Vector2(0, -3), Vector2(3, 4), Palette.STONE_DARK, 1.0)
	draw_circle(Vector2(4, -2), 2.2, Color(0.4, 0.55, 0.3, 0.8))

## See interaction_option.gd. Null while broken - see the matching comment
## on Tree.get_interaction().
func get_interaction() -> InteractionOption:
	if depleted:
		return null
	var room := GameState.has_stone_room()
	return InteractionOption.new("Mine", mine, room, "" if room else GameState.pouch_full_message("stone"))

func mine() -> void:
	if depleted:
		return
	if not GameState.has_stone_room():
		GameState.pouch_full.emit("stone")
		return
	hits_taken += 1
	GameState.add_stone(STONE_YIELD)
	# No pond, no upkeep: see the matching comment on Player - energy stays
	# untouched until the dam/pond exists, so gathering for the initial build
	# never runs the beaver out of steam before there's any way to refuel.
	if GameState.is_dam_complete():
		GameState.spend_energy(GameState.MINE_ENERGY_COST)
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
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)
	_deplete()

func _on_respawn() -> void:
	hits_taken = 0
	$CollisionShape2D.disabled = false
	$InteractArea/CollisionShape2D.disabled = false
	super._on_respawn()
