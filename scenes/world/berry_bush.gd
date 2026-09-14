class_name BerryBush
extends Harvestable
## A berry bush - interact to harvest a handful of berries, which don't feed
## the beaver directly anymore (see PondPlant for that). Berries are instead
## stockpiled to feed raccoons and shoo them off (see Raccoon.feed()). The
## bush regrows its berries after a short cooldown, the same way trees/rocks
## respawn.

## Bumped alongside Tree/Rock's yield increase (see issue #19's economy
## retune) so a berry-stocking trip needs fewer visits too, and respawn was
## trimmed to match.
const HARVEST_AMOUNT := 3

func _ready() -> void:
	respawn_time = 9.0
	add_to_group("berry_bushes")

## See interaction_option.gd. Null while regrowing.
func get_interaction() -> InteractionOption:
	if not can_harvest():
		return null
	return InteractionOption.new("Harvest Berries", harvest, true)

func harvest() -> void:
	if not can_harvest():
		return
	GameState.add_berries(HARVEST_AMOUNT)
	Sfx.play_harvest()
	Fx.burst(global_position, Palette.BERRY, 8)
	_deplete()

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 8), Vector2(11, 3))
	if highlighted and can_harvest():
		draw_arc(Vector2(0, -2), 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	DrawUtil.outlined_circle(self, Vector2(-7, 2), 8.0, Palette.BUSH_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(7, 2), 8.0, Palette.BUSH_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(0, -5), 9.5, Palette.BUSH_LIGHT, 1.5)
	if not depleted:
		draw_circle(Vector2(-4, -3), 1.6, Palette.BERRY)
		draw_circle(Vector2(3, 1), 1.6, Palette.BERRY)
		draw_circle(Vector2(-1, -8), 1.6, Palette.BERRY)
