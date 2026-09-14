class_name GardenSpot
extends Interactable
## A cosmetic garden decoration, buildable once the Lodge is complete. No
## further stages once built - the payoff is purely a prettier pond and a
## critter moving in, giving leftover wood/stone somewhere to go after the
## Lodge itself is finished. Hidden entirely until then.

enum Kind { FLOWER_BED, BENCH }

const WOOD_COST := 3
const STONE_COST := 2

@export var kind: Kind = Kind.FLOWER_BED
## Relative path to the critter this decoration reveals when built.
@export var critter_path: NodePath

var built: bool = false

func _ready() -> void:
	add_to_group("garden_spots")
	set("monitorable", false)
	hide()
	GameState.lodge_completed.connect(reveal)

func can_build() -> bool:
	return visible and not built

## See interaction_option.gd. Null before the spot is revealed or after it's
## already built - nothing left to do here either way.
func get_interaction() -> InteractionOption:
	if not can_build():
		return null
	var available := GameState.can_afford(WOOD_COST, STONE_COST)
	var reason := "" if available else "Not enough wood or stone"
	return InteractionOption.new("Build " + _kind_label(), build, available, reason, {"wood": WOOD_COST, "stone": STONE_COST})

func _kind_label() -> String:
	return "Flower Bed" if kind == Kind.FLOWER_BED else "Bench"

## The affordability check used to live only in Player (the group-based
## dispatch that get_interaction() replaces) - now build() guards its own
## cost the same way chop()/mine() always have.
func build() -> void:
	if not can_build() or not GameState.can_afford(WOOD_COST, STONE_COST):
		return
	GameState.spend(WOOD_COST, STONE_COST)
	Sfx.play_build()
	Fx.burst(global_position, Color(0.85, 0.6, 0.7), 10)
	_place()

## Restores a built spot from a save file - same end state as build(), but
## silent (no sound/particles) since nothing just happened live.
func set_built_silently(value: bool) -> void:
	if not value or built:
		return
	_place()

func _place() -> void:
	built = true
	set_highlighted(false)
	queue_redraw()
	if critter_path != NodePath():
		var critter := get_node_or_null(critter_path)
		if critter and critter.has_method("reveal"):
			critter.reveal()

func _draw() -> void:
	if built:
		match kind:
			Kind.FLOWER_BED:
				_draw_flower_bed()
			Kind.BENCH:
				_draw_bench()
		return
	if highlighted and can_build():
		draw_arc(Vector2(0, -2), 16.0, 0, TAU, 24, Palette.HIGHLIGHT_RING, 2.5)
	var marker := PackedVector2Array([
		Vector2(-10, -6), Vector2(10, -6), Vector2(10, 8), Vector2(-10, 8),
	])
	var closed := marker.duplicate()
	closed.append(marker[0])
	draw_polyline(closed, Color(1, 1, 1, 0.6), 2.0, true)

func _draw_flower_bed() -> void:
	DrawUtil.shadow(self, Vector2(0, 7), Vector2(12, 3))
	DrawUtil.outlined_rect(self, Rect2(-12, -2, 24, 8), Palette.BARK_DARK, 1.5)
	var petal_colors := [Palette.PETAL_PINK, Palette.PETAL_YELLOW, Palette.PETAL_PURPLE, Palette.PETAL_ORANGE]
	for i in petal_colors.size():
		var x := -9.0 + i * 6.0
		draw_circle(Vector2(x, -4), 2.2, petal_colors[i])
		draw_circle(Vector2(x, -4), 0.9, Palette.PETAL_CENTER)

func _draw_bench() -> void:
	DrawUtil.shadow(self, Vector2(0, 9), Vector2(13, 3))
	draw_rect(Rect2(-12, -2, 24, 3), Palette.WOOD_MID)
	draw_rect(Rect2(-12, -9, 24, 3), Palette.WOOD_MID)
	draw_rect(Rect2(-11, 1, 2, 7), Palette.WOOD_DARK)
	draw_rect(Rect2(9, 1, 2, 7), Palette.WOOD_DARK)
