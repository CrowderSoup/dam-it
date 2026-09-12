extends Node2D
## Wires up the small "pond rises behind the finished dam" celebration.

@onready var river: ColorRect = $River

func _ready() -> void:
	GameState.dam_completed.connect(_on_dam_completed)

func _on_dam_completed() -> void:
	var tween := create_tween()
	tween.tween_property(river, "color", Color(0.2, 0.35, 0.75, 1), 2.0)
	tween.parallel().tween_property(river, "offset_top", 250.0, 2.0)
