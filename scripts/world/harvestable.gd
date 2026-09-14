class_name Harvestable
extends Interactable
## Shared base for gatherable resource nodes that deplete on interaction and
## respawn after a cooldown: trees, rocks, berry bushes, and pond plants.
## Subclasses set `respawn_time` in _ready() and call _deplete() once
## they've granted their yield; override _on_respawn() to reset any extra
## state (like a hit counter) alongside the base depleted/redraw reset.

@export var respawn_time: float = 10.0

var depleted: bool = false

func can_harvest() -> bool:
	return not depleted

func _deplete() -> void:
	depleted = true
	set_highlighted(false)
	queue_redraw()
	await get_tree().create_timer(respawn_time).timeout
	_on_respawn()

func _on_respawn() -> void:
	depleted = false
	queue_redraw()
