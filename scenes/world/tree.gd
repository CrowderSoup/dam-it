extends Harvestable
## A choppable tree. Yields wood over a few hits, then respawns.

const WOOD_YIELD := 1
const HITS_TO_FELL := 3

var hits_taken: int = 0

func _ready() -> void:
	respawn_time = 8.0
	add_to_group("trees")
	# The InteractArea (not this StaticBody2D) is what Player's overlap
	# check actually finds, so it needs its own group to be resolved back
	# to this node. See Player._resolve_target().
	$InteractArea.add_to_group("tree_areas")

func _draw() -> void:
	if depleted:
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

## See interaction_option.gd. Null while felled - a respawning tree isn't a
## nearby interactable worth prompting for, the same way it draws without a
## highlight ring (see _draw()).
func get_interaction() -> InteractionOption:
	if depleted:
		return null
	var room := GameState.has_wood_room()
	return InteractionOption.new("Chop", chop, room, "" if room else GameState.pouch_full_message("wood"))

func chop() -> void:
	if depleted:
		return
	if not GameState.has_wood_room():
		GameState.pouch_full.emit("wood")
		return
	hits_taken += 1
	GameState.add_wood(WOOD_YIELD)
	# No pond, no upkeep: see the matching comment on Player - energy stays
	# untouched until the dam/pond exists, so gathering for the initial build
	# never runs the beaver out of steam before there's any way to refuel.
	if GameState.is_dam_complete():
		GameState.spend_energy(GameState.CHOP_ENERGY_COST)
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
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractArea/CollisionShape2D.set_deferred("disabled", true)
	_deplete()

func _on_respawn() -> void:
	hits_taken = 0
	$CollisionShape2D.disabled = false
	$InteractArea/CollisionShape2D.disabled = false
	super._on_respawn()
