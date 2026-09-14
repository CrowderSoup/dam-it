class_name RiverGauge
extends Area2D
## A reed-marked gauge post on the bank near the dam site - the first dam's
## observation step (see issue #19). Interact once to "read the water": it
## flags GameState.water_read, which is what unblocks the keystone dam slot
## (see DamSlot.is_keystone/_needs_reading()) sitting in the river's main
## channel. A plain Area2D duck-typing the shared interaction contract, the
## same way DamSlot/GardenSpot do (see interactable.gd's class comment) -
## it's a landmark, not a depletable resource, so there's nothing here that
## needs Harvestable's respawn behavior.
##
## Free and instant, and never blocks anything else - reading the water
## can't fail or be missed for long, so the observation step stays cozy
## rather than turning into its own chore.

var highlighted: bool = false

func _ready() -> void:
	add_to_group("river_gauges")

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 10), Vector2(7, 3))
	if highlighted and not GameState.water_read:
		draw_arc(Vector2(0, -2), 15.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)

	# A driftwood post with painted water-level notches.
	draw_line(Vector2(-1, 10), Vector2(-1, -14), Palette.WOOD_DARK, 3.0)
	draw_line(Vector2(2, 10), Vector2(2, -12), Palette.WOOD_MID, 2.5)
	for i in 3:
		var y := 4.0 - i * 6.0
		draw_line(Vector2(-4, y), Vector2(0, y), Palette.STONE_LIGHT, 1.5)

	if GameState.water_read:
		# A small tied reed marker shows the post has already been read.
		draw_line(Vector2(-6, -10), Vector2(4, -6), Palette.LEAF_MID, 2.0)
	else:
		# Gentle ripples at the waterline hint there's something to read here.
		draw_arc(Vector2(0, 12), 9.0, 0.3, PI - 0.3, 8, Palette.WATER_SHALLOW, 1.5)
		draw_arc(Vector2(0, 12), 13.0, 0.5, PI - 0.5, 8, Palette.WATER_SHALLOW, 1.0)

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

## See interaction_option.gd. Null once already read - there's nothing more
## to learn from the same spot, the same way a built garden spot has
## nothing left to interact with.
func get_interaction() -> InteractionOption:
	if GameState.water_read:
		return null
	return InteractionOption.new("Read the Water", read_water, true)

func read_water() -> void:
	if GameState.water_read:
		return
	GameState.read_water()
	Sfx.play_harvest()
	Fx.burst(global_position, Palette.WATER_SHALLOW, 8)
	set_highlighted(false)
	queue_redraw()
