class_name Interactable
extends CollisionObject2D
## Shared base for world objects the player can highlight and interact with.
## Trees, rocks, berry bushes, pond plants, and garden spots all build on
## this for consistent highlight-ring feedback and the hidden-until-unlocked
## reveal pop-in. Works whether the concrete scene root is a StaticBody2D or
## an Area2D, since both inherit CollisionObject2D.

var highlighted: bool = false

func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

## Shows a hidden node with a little pop-in scale tween. Used by things that
## stay hidden until some game milestone (dam/Lodge completion) reveals them.
## No-op if already visible. `monitorable` is Area2D-only, so it's poked
## dynamically - this base also has to work for the StaticBody2D-rooted
## Harvestables that never call reveal() at all.
func reveal() -> void:
	if visible:
		return
	if "monitorable" in self:
		set("monitorable", true)
	show()
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()
