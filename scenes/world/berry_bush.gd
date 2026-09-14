class_name BerryBush
extends Area2D
## A berry bush - what a beaver eats besides bark. Interact to eat a
## handful of berries and restore some energy; the bush regrows its
## berries after a short cooldown, the same way trees/rocks respawn.

const ENERGY_RESTORE := 30.0
const RESPAWN_TIME := 12.0

var picked: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("berry_bushes")

func can_eat() -> bool:
	return not picked

func eat() -> void:
	if not can_eat():
		return
	picked = true
	set_highlighted(false)
	GameState.restore_energy(ENERGY_RESTORE)
	Sfx.play_eat()
	Fx.burst(global_position, Palette.BERRY, 8)
	queue_redraw()
	await get_tree().create_timer(RESPAWN_TIME).timeout
	picked = false
	queue_redraw()

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func _draw() -> void:
	DrawUtil.shadow(self, Vector2(0, 8), Vector2(11, 3))
	if highlighted and can_eat():
		draw_arc(Vector2(0, -2), 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	DrawUtil.outlined_circle(self, Vector2(-7, 2), 8.0, Palette.BUSH_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(7, 2), 8.0, Palette.BUSH_DARK, 1.5)
	DrawUtil.outlined_circle(self, Vector2(0, -5), 9.5, Palette.BUSH_LIGHT, 1.5)
	if not picked:
		draw_circle(Vector2(-4, -3), 1.6, Palette.BERRY)
		draw_circle(Vector2(3, 1), 1.6, Palette.BERRY)
		draw_circle(Vector2(-1, -8), 1.6, Palette.BERRY)
