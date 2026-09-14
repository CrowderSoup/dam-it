class_name PondPlant
extends Area2D
## A patch of cattails or water lilies growing in the pond - what the beaver
## actually eats to restore energy now that there's a pond (see berry_bush.gd
## for berries, which are harvested for raccoons instead). Hidden entirely
## until the dam is finished and the pond appears, then pops into view the
## same way the Lodge does; interact to eat and restore energy, then regrows
## after a cooldown, the same way berry bushes respawn.

enum Kind { CATTAIL, WATER_LILY }

const ENERGY_RESTORE := 30.0
const RESPAWN_TIME := 14.0

@export var kind: Kind = Kind.CATTAIL

var picked: bool = false
var highlighted: bool = false

func _ready() -> void:
	add_to_group("pond_plants")
	monitorable = false
	hide()
	GameState.dam_completed.connect(reveal)

## Shows the plant with a little pop-in, if it isn't already visible. Called
## either by the dam_completed signal or directly on a save load where the
## dam was already complete.
func reveal() -> void:
	if visible:
		return
	monitorable = true
	show()
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()

func can_eat() -> bool:
	return visible and not picked

func eat() -> void:
	if not can_eat():
		return
	picked = true
	set_highlighted(false)
	GameState.restore_energy(ENERGY_RESTORE)
	Sfx.play_eat()
	var color: Color = Palette.CATTAIL if kind == Kind.CATTAIL else Palette.LILY_PETAL
	Fx.burst(global_position, color, 8)
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
	if highlighted and can_eat():
		draw_arc(Vector2(0, -4), 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	match kind:
		Kind.CATTAIL:
			_draw_cattail()
		Kind.WATER_LILY:
			_draw_water_lily()

func _draw_cattail() -> void:
	draw_line(Vector2(-4, 8), Vector2(-4, -8), Palette.LEAF_DARK, 2.0)
	draw_line(Vector2(3, 8), Vector2(3, -13), Palette.LEAF_DARK, 2.0)
	if not picked:
		for i in 3:
			draw_circle(Vector2(3, -18.0 + i * 3.2), 2.8, Palette.CATTAIL)

func _draw_water_lily() -> void:
	DrawUtil.outlined_circle(self, Vector2.ZERO, 11.0, Palette.LILY_PAD, 1.5)
	if not picked:
		var petal_count := 6
		for i in petal_count:
			var angle := TAU * i / petal_count
			draw_circle(Vector2(cos(angle), sin(angle)) * 5.0, 2.6, Palette.LILY_PETAL)
		draw_circle(Vector2.ZERO, 2.2, Palette.PETAL_YELLOW)
