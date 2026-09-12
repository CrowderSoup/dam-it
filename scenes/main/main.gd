extends Node2D
## Wires up the "pond rises behind the finished dam" celebration and lets
## the player restart the level at any time.

@onready var river: ColorRect = $River

func _ready() -> void:
	GameState.dam_completed.connect(_on_dam_completed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameState.reset()
		get_tree().reload_current_scene()

func _on_dam_completed() -> void:
	var tween := create_tween()
	tween.tween_property(river, "color", Color(0.2, 0.35, 0.75, 1), 2.0)
	tween.parallel().tween_property(river, "offset_top", 250.0, 2.0)
